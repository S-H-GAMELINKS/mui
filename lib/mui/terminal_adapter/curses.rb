# frozen_string_literal: true

require "curses"

module Mui
  module TerminalAdapter
    # Curses-based terminal adapter for production use
    class Curses < Base
      def init
        ::Curses.init_screen
        ::Curses.raw
        ::Curses.noecho
        ::Curses.curs_set(1)
        ::Curses.stdscr.keypad(true)
        init_colors
      end

      def init_colors
        ::Curses.start_color
        ::Curses.use_default_colors
      end

      def init_color_pair(pair_index, fg, bg)
        fg_code = color_code(fg)
        bg_code = color_code(bg)
        ::Curses.init_pair(pair_index, fg_code, bg_code)
      end

      def with_color(pair_index, bold: false, underline: false)
        attrs = ::Curses.color_pair(pair_index)
        attrs |= ::Curses::A_BOLD if bold
        attrs |= ::Curses::A_UNDERLINE if underline
        ::Curses.attron(attrs)
        result = yield
        ::Curses.attroff(attrs)
        result
      end

      private

      def color_code(color)
        return -1 if color.nil?
        return color if color.is_a?(Integer)

        case color
        when :black then ::Curses::COLOR_BLACK
        when :red then ::Curses::COLOR_RED
        when :green then ::Curses::COLOR_GREEN
        when :yellow then ::Curses::COLOR_YELLOW
        when :blue then ::Curses::COLOR_BLUE
        when :magenta then ::Curses::COLOR_MAGENTA
        when :cyan then ::Curses::COLOR_CYAN
        when :white then ::Curses::COLOR_WHITE
        else
          # Check extended colors from ColorManager
          ColorManager::COLOR_MAP[color] ||
            ColorManager::EXTENDED_COLOR_MAP[color] ||
            -1
        end
      end

      public

      def close
        ::Curses.close_screen
      end

      def clear
        ::Curses.clear
      end

      def refresh
        ::Curses.refresh
      end

      def width
        ::Curses.cols
      end

      def height
        ::Curses.lines
      end

      def setpos(y, x)
        ::Curses.setpos(y, x)
      end

      def addstr(str)
        ::Curses.addstr(str)
      end

      def with_highlight
        ::Curses.attron(::Curses::A_REVERSE)
        result = yield
        ::Curses.attroff(::Curses::A_REVERSE)
        result
      end

      def getch
        key = ::Curses.getch
        return key unless key.is_a?(Integer)
        return key if key.negative? || key > 255 # Special keys (arrows, etc.)

        # Handle UTF-8 multibyte sequences
        if key >= 0x80
          read_utf8_char(key)
        else
          key
        end
      end

      private

      def read_utf8_char(first_byte)
        bytes = [first_byte]

        # Determine expected byte count from first byte
        if (first_byte & 0xE0) == 0xC0
          # 2-byte sequence (110xxxxx)
          expected = 2
        elsif (first_byte & 0xF0) == 0xE0
          # 3-byte sequence (1110xxxx) - CJK characters
          expected = 3
        elsif (first_byte & 0xF8) == 0xF0
          # 4-byte sequence (11110xxx) - emoji, etc.
          expected = 4
        else
          # Invalid or continuation byte, return as-is
          return first_byte
        end

        # Read remaining bytes
        (expected - 1).times do
          next_byte = ::Curses.getch
          break unless next_byte.is_a?(Integer) && (next_byte & 0xC0) == 0x80

          bytes << next_byte
        end

        # Convert to UTF-8 string
        bytes.pack("C*").force_encoding(Encoding::UTF_8)
      end

      public

      def getch_nonblock
        ::Curses.stdscr.nodelay = true
        key = ::Curses.getch
        return key.tap { ::Curses.stdscr.nodelay = false } unless key.is_a?(Integer)
        return key.tap { ::Curses.stdscr.nodelay = false } if key.negative? || key > 255

        result = if key >= 0x80
                   read_utf8_char(key)
                 else
                   key
                 end
        ::Curses.stdscr.nodelay = false
        result
      end
    end
  end
end
