# frozen_string_literal: true

require "io/console"
require "io/wait"

module Mui
  module TerminalAdapter
    # Terminal adapter that speaks ANSI escape sequences directly, for places
    # where curses is not available.
    #
    # Drawing goes into a back buffer of cells, and refresh sends only the rows
    # that differ from what is already on the terminal -- the editor redraws
    # every frame, and curses would only send the difference too. Input is
    # read as bytes and decoded here: escape sequences become the same key
    # codes curses returns (see KeyCode), multibyte UTF-8 becomes a String.
    class Ansi < Base
      # How long a lone ESC waits for the rest of a sequence before it is
      # taken to be the Escape key. curses' ESCDELAY is set to the same.
      ESCAPE_TIMEOUT = 0.01

      # How often the terminal is asked for its size. width and height are
      # read every frame; asking every frame would be a system call each time.
      WINSIZE_INTERVAL = 0.5

      SEQUENCES = {
        "[A" => KeyCode::KEY_UP,
        "[B" => KeyCode::KEY_DOWN,
        "[C" => KeyCode::KEY_RIGHT,
        "[D" => KeyCode::KEY_LEFT,
        "OA" => KeyCode::KEY_UP,
        "OB" => KeyCode::KEY_DOWN,
        "OC" => KeyCode::KEY_RIGHT,
        "OD" => KeyCode::KEY_LEFT,
        "[H" => KeyCode::KEY_HOME,
        "[F" => KeyCode::KEY_END,
        "OH" => KeyCode::KEY_HOME,
        "OF" => KeyCode::KEY_END,
        "[1~" => KeyCode::KEY_HOME,
        "[7~" => KeyCode::KEY_HOME,
        "[4~" => KeyCode::KEY_END,
        "[8~" => KeyCode::KEY_END,
        "[3~" => KeyCode::KEY_DC,
        "[5~" => KeyCode::KEY_PPAGE,
        "[6~" => KeyCode::KEY_NPAGE,
        "[Z" => KeyCode::KEY_BTAB,
        "[1;2C" => KeyCode::SHIFT_RIGHT,
        "[1;2D" => KeyCode::SHIFT_LEFT
      }.freeze

      BLANK = " "
      PLAIN = [-1, -1, false, false, false].freeze # fg, bg, bold, underline, reverse
      WIDE = :wide # the cell covered by the right half of a wide character
      # Shared by every blank cell: cells are replaced, never changed in place,
      # so clearing the screen each frame allocates rows and not cells.
      BLANK_CELL = [BLANK, PLAIN].freeze

      def initialize(input: $stdin, output: $stdout)
        super()
        @input = input
        @output = output
        @pairs = {}
        @pending = "".b
        @attr = PLAIN
        @cursor_y = 0
        @cursor_x = 0
        @height, @width = 24, 80
        @size_checked_at = nil
      end

      def init
        @input.raw! if @input.respond_to?(:raw!) && @input.tty?
        update_size(force: true)
        write("\e[?1049h\e[H\e[2J\e[?25h")
        reset_buffers
      end

      def close
        write("\e[0m\e[?1049l\e[?25h")
        @input.cooked! if @input.respond_to?(:cooked!) && @input.tty?
      end

      def init_colors
        # Nothing to set up: colours are sent with each change of attribute.
      end

      def has_colors?
        true
      end

      def colors
        256
      end

      def color_pairs
        256
      end

      def init_color_pair(pair_index, fg, bg)
        @pairs[pair_index] = [color_code(fg), color_code(bg)]
      end

      def with_color(pair_index, bold: false, underline: false)
        fg, bg = @pairs.fetch(pair_index, [-1, -1])
        with_attr([fg, bg, bold || false, underline || false, @attr[4]]) { yield }
      end

      def with_highlight(&)
        with_attr([@attr[0], @attr[1], @attr[2], @attr[3], true], &)
      end

      def clear
        update_size
        @back = blank_screen
      end

      def refresh
        out = +""
        @height.times do |y|
          row = @back[y]
          next if @front && @front[y] == row

          out << "\e[#{y + 1};1H" << render_row(row)
        end
        out << "\e[#{@cursor_y + 1};#{@cursor_x + 1}H"
        write(out)
        @front = @back.map(&:dup)
      end

      def touchwin
        @front = nil
        refresh
      end

      def width
        update_size
        @width
      end

      def height
        update_size
        @height
      end

      def setpos(y, x)
        @cursor_y = y
        @cursor_x = x
      end

      def addstr(str)
        row = @back[@cursor_y]
        return unless row

        str.each_char do |char|
          char_width = UnicodeWidth.char_width(char)
          break if @cursor_x + char_width > @width

          row[@cursor_x] = [char, @attr]
          row[@cursor_x + 1] = [WIDE, @attr] if char_width == 2
          @cursor_x += char_width
        end
      end

      def getch
        loop do
          key = getch_nonblock
          return key if key

          @input.wait_readable
        end
      end

      def getch_nonblock
        fill_pending
        return nil if @pending.empty?

        first = @pending.getbyte(0)
        return take_escape if first == KeyCode::ESCAPE
        return take_utf8(first) if first >= 0x80

        @pending = @pending.byteslice(1..)
        first
      end

      def suspend
        write("\e[0m\e[?1049l")
        @input.cooked! if @input.respond_to?(:cooked!) && @input.tty?
      end

      def resume
        @input.raw! if @input.respond_to?(:raw!) && @input.tty?
        write("\e[?1049h")
        touchwin
      end

      private

      def write(str)
        @output.write(str)
        @output.flush
      end

      def with_attr(attr)
        saved = @attr
        @attr = attr
        yield
      ensure
        @attr = saved
      end

      def blank_screen
        Array.new(@height) { Array.new(@width, BLANK_CELL) }
      end

      def reset_buffers
        @back = blank_screen
        @front = nil
      end

      def update_size(force: false)
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        return if !force && @size_checked_at && now - @size_checked_at < WINSIZE_INTERVAL

        @size_checked_at = now
        rows, cols = winsize
        return if rows == @height && cols == @width && @back

        @height = rows
        @width = cols
        reset_buffers
      end

      def winsize
        size = @output.winsize if @output.respond_to?(:winsize)
        size && size[0].positive? && size[1].positive? ? size : [24, 80]
      rescue SystemCallError, IOError
        [24, 80]
      end

      # One row, with attributes changed only where they change.
      def render_row(row)
        out = +"\e[0m"
        current = PLAIN
        row.each do |char, attr|
          next if char == WIDE

          if attr != current
            out << sgr(attr)
            current = attr
          end
          out << char
        end
        out << "\e[0m"
      end

      def sgr(attr)
        fg, bg, bold, underline, reverse = attr
        codes = ["0"]
        codes << "1" if bold
        codes << "4" if underline
        codes << "7" if reverse
        codes << "38;5;#{fg}" if fg >= 0
        codes << "48;5;#{bg}" if bg >= 0
        "\e[#{codes.join(";")}m"
      end

      def color_code(color)
        return -1 if color.nil?
        return color if color.is_a?(Integer)
        return @color_resolver.resolve(color) if @color_resolver

        -1
      end

      def fill_pending
        loop do
          @pending << @input.read_nonblock(256).b
        end
      rescue IO::WaitReadable, EOFError
        nil
      end

      # Waits up to ESCAPE_TIMEOUT for more input to arrive.
      def more_input?
        return true if @input.wait_readable(ESCAPE_TIMEOUT)

        false
      end

      # ESC alone, or the start of a sequence: CSI (ESC [ ... final byte) or
      # SS3 (ESC O x). A sequence not in SEQUENCES is dropped whole rather
      # than delivered as ESC followed by stray characters.
      def take_escape
        if @pending.bytesize == 1
          fill_pending if more_input?
          if @pending.bytesize == 1
            @pending = "".b
            return KeyCode::ESCAPE
          end
        end

        body = sequence_body
        if body.nil?
          # ESC followed by something that does not start a sequence: deliver
          # the ESC and leave the rest for the next read.
          @pending = @pending.byteslice(1..)
          return KeyCode::ESCAPE
        end

        @pending = @pending.byteslice((1 + body.bytesize)..)
        SEQUENCES[body] || getch_nonblock
      end

      def sequence_body
        rest = @pending.byteslice(1..)
        case rest.getbyte(0)
        when 0x4F # "O"
          fill_pending if rest.bytesize < 2 && more_input?
          rest = @pending.byteslice(1..)
          rest.bytesize >= 2 ? rest.byteslice(0, 2) : nil
        when 0x5B # "["
          finish = rest.index(/[\x40-\x7E]/n, 1)
          if finish.nil? && more_input?
            fill_pending
            rest = @pending.byteslice(1..)
            finish = rest.index(/[\x40-\x7E]/n, 1)
          end
          finish ? rest.byteslice(0, finish + 1) : nil
        end
      end

      def take_utf8(first)
        expected =
          if (first & 0xE0) == 0xC0 then 2
          elsif (first & 0xF0) == 0xE0 then 3
          elsif (first & 0xF8) == 0xF0 then 4
          end
        unless expected
          @pending = @pending.byteslice(1..)
          return first
        end

        fill_pending if @pending.bytesize < expected && more_input?
        return nil if @pending.bytesize < expected

        char = @pending.byteslice(0, expected).force_encoding(Encoding::UTF_8)
        @pending = @pending.byteslice(expected..)
        char
      end
    end
  end
end
