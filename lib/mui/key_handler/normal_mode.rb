# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handles key inputs in Normal mode
    class NormalMode < Base
      def initialize(mode_manager, buffer, register = nil, undo_manager: nil, search_state: nil)
        super(mode_manager, buffer)
        @register = register || Register.new
        @undo_manager = undo_manager
        @search_state = search_state
        @pending_motion = nil
        @pending_register = nil
      end

      def handle(key)
        # Check plugin keymaps first (only when no pending motion)
        unless @pending_motion
          plugin_result = check_plugin_keymap(key, :normal)
          return plugin_result if plugin_result
        end

        if @pending_motion
          handle_pending_motion(key)
        else
          handle_normal_key(key)
        end
      end

      def check_plugin_keymap(key, mode_symbol)
        return nil unless @mode_manager&.editor

        key_str = begin
          key.is_a?(String) ? key : key.chr
        rescue StandardError
          nil
        end
        return nil unless key_str

        plugin_handler = Mui.config.keymaps[mode_symbol]&.[](key_str)
        return nil unless plugin_handler

        context = CommandContext.new(
          editor: @mode_manager.editor,
          buffer: @buffer,
          window:
        )
        plugin_handler.call(context)
        result
      end

      private

      def handle_normal_key(key)
        case key
        when "h", Curses::KEY_LEFT
          handle_move_left
        when "j", Curses::KEY_DOWN
          handle_move_down
        when "k", Curses::KEY_UP
          handle_move_up
        when "l", Curses::KEY_RIGHT
          handle_move_right
        when "w"
          handle_word_forward
        when "b"
          handle_word_backward
        when "e"
          handle_word_end
        when "0"
          handle_line_start
        when "^"
          handle_first_non_blank
        when "$"
          handle_line_end
        when "g"
          @pending_motion = :g
          result
        when "G"
          handle_file_end
        when "f"
          @pending_motion = :f
          result
        when "F"
          @pending_motion = :F
          result
        when "t"
          @pending_motion = :t
          result
        when "T"
          @pending_motion = :T
          result
        when "i"
          result(mode: Mode::INSERT)
        when "a"
          handle_append
        when "o"
          handle_open_below
        when "O"
          handle_open_above
        when "x"
          handle_delete_char
        when "d"
          @pending_motion = :d
          result
        when "c"
          @pending_motion = :c
          result
        when "y"
          @pending_motion = :y
          result
        when "p"
          handle_paste_after
        when "P"
          handle_paste_before
        when ":"
          result(mode: Mode::COMMAND)
        when "v"
          result(mode: Mode::VISUAL, start_selection: true)
        when "V"
          result(mode: Mode::VISUAL_LINE, start_selection: true, line_mode: true)
        when '"'
          @pending_motion = :register_select
          result
        when "u"
          handle_undo
        when 18 # Ctrl-r
          handle_redo
        when "/"
          result(mode: Mode::SEARCH_FORWARD)
        when "?"
          result(mode: Mode::SEARCH_BACKWARD)
        when "n"
          handle_search_next
        when "N"
          handle_search_previous
        else
          result
        end
      end

      def handle_pending_motion(key)
        char = key_to_char(key)
        return clear_pending unless char

        case @pending_motion
        when :register_select
          handle_register_select(char)
        when :d
          handle_delete_pending(char)
        when :dg
          handle_delete_to_file_start(char)
        when :df, :dF, :dt, :dT
          handle_delete_find_char(char)
        when :c
          handle_change_pending(char)
        when :cg
          handle_change_to_file_start(char)
        when :cf, :cF, :ct, :cT
          handle_change_find_char(char)
        when :y
          handle_yank_pending(char)
        when :yg
          handle_yank_to_file_start(char)
        when :yf, :yF, :yt, :yT
          handle_yank_find_char(char)
        else
          motion_result = execute_pending_motion(char)
          apply_motion(motion_result) if motion_result
          clear_pending
        end
      end

      def key_to_char(key)
        key.is_a?(String) ? key : key.chr
      rescue RangeError
        nil
      end

      def execute_pending_motion(char)
        case @pending_motion
        when :g
          char == "g" ? Motion.file_start(@buffer, cursor_row, cursor_col) : nil
        when :f
          Motion.find_char_forward(@buffer, cursor_row, cursor_col, char)
        when :F
          Motion.find_char_backward(@buffer, cursor_row, cursor_col, char)
        when :t
          Motion.till_char_forward(@buffer, cursor_row, cursor_col, char)
        when :T
          Motion.till_char_backward(@buffer, cursor_row, cursor_col, char)
        end
      end

      def clear_pending
        @pending_motion = nil
        @pending_register = nil
        result
      end

      def handle_register_select(char)
        if valid_register_name?(char)
          @pending_register = char
          @pending_motion = nil
          result
        else
          clear_pending
        end
      end

      def valid_register_name?(char)
        Register::NAMED_REGISTERS.include?(char) ||
          Register::DELETE_HISTORY_REGISTERS.include?(char) ||
          [Register::YANK_REGISTER, Register::BLACK_HOLE_REGISTER, Register::UNNAMED_REGISTER].include?(char)
      end

      # Movement handlers
      def handle_move_left
        window.move_left
        result
      end

      def handle_move_down
        window.move_down
        result
      end

      def handle_move_up
        window.move_up
        result
      end

      def handle_move_right
        window.move_right
        result
      end

      def handle_word_forward
        apply_motion(Motion.word_forward(@buffer, cursor_row, cursor_col))
        result
      end

      def handle_word_backward
        apply_motion(Motion.word_backward(@buffer, cursor_row, cursor_col))
        result
      end

      def handle_word_end
        apply_motion(Motion.word_end(@buffer, cursor_row, cursor_col))
        result
      end

      def handle_line_start
        apply_motion(Motion.line_start(@buffer, cursor_row, cursor_col))
        result
      end

      def handle_first_non_blank
        apply_motion(Motion.first_non_blank(@buffer, cursor_row, cursor_col))
        result
      end

      def handle_line_end
        apply_motion(Motion.line_end(@buffer, cursor_row, cursor_col))
        result
      end

      def handle_file_end
        apply_motion(Motion.file_end(@buffer, cursor_row, cursor_col))
        result
      end

      # Edit handlers
      def handle_append
        self.cursor_col = cursor_col + 1 if current_line_length.positive?
        result(mode: Mode::INSERT)
      end

      def handle_open_below
        @undo_manager&.begin_group
        @buffer.insert_line(cursor_row + 1)
        self.cursor_row = cursor_row + 1
        self.cursor_col = 0
        result(mode: Mode::INSERT, group_started: true)
      end

      def handle_open_above
        @undo_manager&.begin_group
        @buffer.insert_line(cursor_row)
        self.cursor_col = 0
        result(mode: Mode::INSERT, group_started: true)
      end

      def handle_delete_char
        @buffer.delete_char(cursor_row, cursor_col)
        result
      end

      # Delete operator handlers
      def handle_delete_pending(char)
        case char
        when "d"
          handle_delete_line
        when "w"
          handle_delete_motion(:word_forward)
        when "e"
          handle_delete_motion(:word_end)
        when "b"
          handle_delete_motion(:word_backward)
        when "0"
          handle_delete_to_line_start
        when "$"
          handle_delete_to_line_end
        when "g"
          @pending_motion = :dg
          result
        when "G"
          handle_delete_to_file_end
        when "f"
          @pending_motion = :df
          result
        when "F"
          @pending_motion = :dF
          result
        when "t"
          @pending_motion = :dt
          result
        when "T"
          @pending_motion = :dT
          result
        else
          clear_pending
        end
      end

      def handle_delete_line
        text = @buffer.line(cursor_row)
        @register.delete(text, linewise: true, name: @pending_register)
        @buffer.delete_line(cursor_row)
        self.cursor_row = [cursor_row, @buffer.line_count - 1].min
        window.clamp_cursor_to_line(@buffer)
        clear_pending
      end

      def handle_delete_motion(motion_type)
        start_pos = { row: cursor_row, col: cursor_col }
        end_pos = calculate_motion_end(motion_type)
        return clear_pending unless end_pos

        inclusive = motion_type == :word_end
        text = extract_text(start_pos, end_pos, inclusive:)
        @register.delete(text, linewise: false, name: @pending_register)
        execute_delete(start_pos, end_pos, inclusive:)
        clear_pending
      end

      def handle_delete_to_line_start
        return clear_pending if cursor_col.zero?

        text = @buffer.line(cursor_row)[0...cursor_col]
        @register.delete(text, linewise: false, name: @pending_register)
        @buffer.delete_range(cursor_row, 0, cursor_row, cursor_col - 1)
        self.cursor_col = 0
        clear_pending
      end

      def handle_delete_to_line_end
        line = @buffer.line(cursor_row)
        return clear_pending if line.empty?

        text = line[cursor_col..]
        @register.delete(text, linewise: false, name: @pending_register)
        end_col = line.length - 1
        @buffer.delete_range(cursor_row, cursor_col, cursor_row, end_col)
        window.clamp_cursor_to_line(@buffer)
        clear_pending
      end

      def handle_delete_to_file_end
        last_row = @buffer.line_count - 1
        if cursor_row == last_row
          handle_delete_line
        else
          lines = (cursor_row..last_row).map { |r| @buffer.line(r) }
          @register.delete(lines.join("\n"), linewise: true, name: @pending_register)
          @undo_manager&.begin_group
          (last_row - cursor_row + 1).times { @buffer.delete_line(cursor_row) }
          @undo_manager&.end_group
          self.cursor_row = [cursor_row, @buffer.line_count - 1].min
          window.clamp_cursor_to_line(@buffer)
          clear_pending
        end
      end

      def handle_delete_to_file_start(char)
        return clear_pending unless char == "g"

        if cursor_row.zero?
          handle_delete_to_line_start
        else
          lines = (0..cursor_row).map { |r| @buffer.line(r) }
          @register.delete(lines.join("\n"), linewise: true, name: @pending_register)
          @undo_manager&.begin_group
          cursor_row.times { @buffer.delete_line(0) }
          @buffer.delete_range(0, 0, 0, cursor_col - 1) if cursor_col.positive?
          @undo_manager&.end_group
          self.cursor_row = 0
          self.cursor_col = 0
          clear_pending
        end
      end

      def handle_delete_find_char(char)
        motion_result = case @pending_motion
                        when :df
                          Motion.find_char_forward(@buffer, cursor_row, cursor_col, char)
                        when :dF
                          Motion.find_char_backward(@buffer, cursor_row, cursor_col, char)
                        when :dt
                          Motion.till_char_forward(@buffer, cursor_row, cursor_col, char)
                        when :dT
                          Motion.till_char_backward(@buffer, cursor_row, cursor_col, char)
                        end
        return clear_pending unless motion_result

        execute_delete_find_char(motion_result)
        clear_pending
      end

      def execute_delete_find_char(motion_result)
        line = @buffer.line(cursor_row)
        text = case @pending_motion
               when :df, :dt
                 line[cursor_col..motion_result[:col]]
               when :dF, :dT
                 line[motion_result[:col]...cursor_col]
               end
        @register.delete(text, linewise: false, name: @pending_register) if text

        case @pending_motion
        when :df, :dt
          @buffer.delete_range(cursor_row, cursor_col, cursor_row, motion_result[:col])
        when :dF, :dT
          @buffer.delete_range(cursor_row, motion_result[:col], cursor_row, cursor_col - 1)
          self.cursor_col = motion_result[:col]
        end
        window.clamp_cursor_to_line(@buffer)
      end

      # Change operator handlers
      def handle_change_pending(char)
        case char
        when "c"
          handle_change_line
        when "w"
          handle_change_motion(:word_forward)
        when "e"
          handle_change_motion(:word_end)
        when "b"
          handle_change_motion(:word_backward)
        when "0"
          handle_change_to_line_start
        when "$"
          handle_change_to_line_end
        when "g"
          @pending_motion = :cg
          result
        when "G"
          handle_change_to_file_end
        when "f"
          @pending_motion = :cf
          result
        when "F"
          @pending_motion = :cF
          result
        when "t"
          @pending_motion = :ct
          result
        when "T"
          @pending_motion = :cT
          result
        else
          clear_pending
        end
      end

      def handle_change_line
        text = @buffer.line(cursor_row)
        @register.delete(text, linewise: true, name: @pending_register)
        @buffer.lines[cursor_row] = +""
        self.cursor_col = 0
        @pending_motion = nil
        @pending_register = nil
        result(mode: Mode::INSERT)
      end

      def handle_change_motion(motion_type)
        start_pos = { row: cursor_row, col: cursor_col }
        # cw behaves like ce in Vim (changes to end of word, not to start of next word)
        effective_motion = motion_type == :word_forward ? :word_end : motion_type
        end_pos = calculate_motion_end(effective_motion)
        return clear_pending unless end_pos

        inclusive = effective_motion == :word_end
        text = extract_text(start_pos, end_pos, inclusive:)
        @register.delete(text, linewise: false, name: @pending_register)
        execute_delete(start_pos, end_pos, inclusive:, clamp: false)
        @pending_motion = nil
        @pending_register = nil
        result(mode: Mode::INSERT)
      end

      def handle_change_to_line_start
        if cursor_col.zero?
          @pending_motion = nil
          @pending_register = nil
          return result(mode: Mode::INSERT)
        end

        text = @buffer.line(cursor_row)[0...cursor_col]
        @register.delete(text, linewise: false, name: @pending_register)
        @buffer.delete_range(cursor_row, 0, cursor_row, cursor_col - 1)
        self.cursor_col = 0
        @pending_motion = nil
        @pending_register = nil
        result(mode: Mode::INSERT)
      end

      def handle_change_to_line_end
        line = @buffer.line(cursor_row)
        if line.empty?
          @pending_motion = nil
          @pending_register = nil
          return result(mode: Mode::INSERT)
        end

        text = line[cursor_col..]
        @register.delete(text, linewise: false, name: @pending_register)
        end_col = line.length - 1
        @buffer.delete_range(cursor_row, cursor_col, cursor_row, end_col)
        # Don't clamp cursor - keep it at original position for insert mode
        @pending_motion = nil
        @pending_register = nil
        result(mode: Mode::INSERT)
      end

      def handle_change_to_file_end
        last_row = @buffer.line_count - 1
        if cursor_row == last_row
          handle_change_line
        else
          lines = (cursor_row..last_row).map { |r| @buffer.line(r) }
          @register.delete(lines.join("\n"), linewise: true, name: @pending_register)
          (last_row - cursor_row + 1).times { @buffer.delete_line(cursor_row) }
          @buffer.insert_line(cursor_row) if @buffer.line_count == cursor_row
          self.cursor_row = [cursor_row, @buffer.line_count - 1].min
          self.cursor_col = 0
          @pending_motion = nil
          @pending_register = nil
          result(mode: Mode::INSERT)
        end
      end

      def handle_change_to_file_start(char)
        return clear_pending unless char == "g"

        if cursor_row.zero?
          handle_change_to_line_start
        else
          lines = (0..cursor_row).map { |r| @buffer.line(r) }
          @register.delete(lines.join("\n"), linewise: true, name: @pending_register)
          cursor_row.times { @buffer.delete_line(0) }
          @buffer.delete_range(0, 0, 0, cursor_col - 1) if cursor_col.positive?
          self.cursor_row = 0
          self.cursor_col = 0
          @pending_motion = nil
          @pending_register = nil
          result(mode: Mode::INSERT)
        end
      end

      def handle_change_find_char(char)
        motion_result = case @pending_motion
                        when :cf
                          Motion.find_char_forward(@buffer, cursor_row, cursor_col, char)
                        when :cF
                          Motion.find_char_backward(@buffer, cursor_row, cursor_col, char)
                        when :ct
                          Motion.till_char_forward(@buffer, cursor_row, cursor_col, char)
                        when :cT
                          Motion.till_char_backward(@buffer, cursor_row, cursor_col, char)
                        end
        return clear_pending unless motion_result

        execute_change_find_char(motion_result)
        @pending_motion = nil
        @pending_register = nil
        result(mode: Mode::INSERT)
      end

      def execute_change_find_char(motion_result)
        line = @buffer.line(cursor_row)
        text = case @pending_motion
               when :cf, :ct
                 line[cursor_col..motion_result[:col]]
               when :cF, :cT
                 line[motion_result[:col]...cursor_col]
               end
        @register.delete(text, linewise: false, name: @pending_register) if text

        case @pending_motion
        when :cf, :ct
          @buffer.delete_range(cursor_row, cursor_col, cursor_row, motion_result[:col])
        when :cF, :cT
          @buffer.delete_range(cursor_row, motion_result[:col], cursor_row, cursor_col - 1)
          self.cursor_col = motion_result[:col]
        end
        # Don't clamp cursor - keep it at original position for insert mode
      end

      # Yank operator handlers
      def handle_yank_pending(char)
        case char
        when "y"
          handle_yank_line
        when "w"
          handle_yank_motion(:word_forward)
        when "e"
          handle_yank_motion(:word_end)
        when "b"
          handle_yank_motion(:word_backward)
        when "0"
          handle_yank_to_line_start
        when "$"
          handle_yank_to_line_end
        when "g"
          @pending_motion = :yg
          result
        when "G"
          handle_yank_to_file_end
        when "f"
          @pending_motion = :yf
          result
        when "F"
          @pending_motion = :yF
          result
        when "t"
          @pending_motion = :yt
          result
        when "T"
          @pending_motion = :yT
          result
        else
          clear_pending
        end
      end

      def handle_yank_line
        text = @buffer.line(cursor_row)
        @register.yank(text, linewise: true, name: @pending_register)
        clear_pending
      end

      def handle_yank_motion(motion_type)
        start_pos = { row: cursor_row, col: cursor_col }
        effective_motion = motion_type == :word_forward ? :word_end : motion_type
        end_pos = calculate_motion_end(effective_motion)
        return clear_pending unless end_pos

        inclusive = effective_motion == :word_end
        text = extract_text(start_pos, end_pos, inclusive:)
        @register.yank(text, linewise: false, name: @pending_register)
        clear_pending
      end

      def handle_yank_to_line_start
        return clear_pending if cursor_col.zero?

        text = @buffer.line(cursor_row)[0...cursor_col]
        @register.yank(text, linewise: false, name: @pending_register)
        clear_pending
      end

      def handle_yank_to_line_end
        line = @buffer.line(cursor_row)
        return clear_pending if line.empty?

        text = line[cursor_col..]
        @register.yank(text, linewise: false, name: @pending_register)
        clear_pending
      end

      def handle_yank_to_file_end
        lines = (cursor_row...@buffer.line_count).map { |r| @buffer.line(r) }
        text = lines.join("\n")
        @register.yank(text, linewise: true, name: @pending_register)
        clear_pending
      end

      def handle_yank_to_file_start(char)
        return clear_pending unless char == "g"

        lines = (0..cursor_row).map { |r| @buffer.line(r) }
        text = lines.join("\n")
        @register.yank(text, linewise: true, name: @pending_register)
        clear_pending
      end

      def handle_yank_find_char(char)
        motion_result = case @pending_motion
                        when :yf
                          Motion.find_char_forward(@buffer, cursor_row, cursor_col, char)
                        when :yF
                          Motion.find_char_backward(@buffer, cursor_row, cursor_col, char)
                        when :yt
                          Motion.till_char_forward(@buffer, cursor_row, cursor_col, char)
                        when :yT
                          Motion.till_char_backward(@buffer, cursor_row, cursor_col, char)
                        end
        return clear_pending unless motion_result

        execute_yank_find_char(motion_result)
        clear_pending
      end

      def execute_yank_find_char(motion_result)
        line = @buffer.line(cursor_row)
        text = case @pending_motion
               when :yf, :yt
                 line[cursor_col..motion_result[:col]]
               when :yF, :yT
                 line[motion_result[:col]...cursor_col]
               end
        @register.yank(text, linewise: false, name: @pending_register)
      end

      # Paste handlers
      def handle_paste_after
        name = @pending_register
        @pending_register = nil
        return result if @register.empty?(name:)

        if @register.linewise?(name:)
          paste_line_after(name:)
        else
          paste_char_after(name:)
        end
        result
      end

      def handle_paste_before
        name = @pending_register
        @pending_register = nil
        return result if @register.empty?(name:)

        if @register.linewise?(name:)
          paste_line_before(name:)
        else
          paste_char_before(name:)
        end
        result
      end

      def paste_line_after(name: nil)
        text = @register.get(name:)
        lines = text.split("\n", -1)
        lines.reverse_each do |line|
          @buffer.insert_line(cursor_row + 1, line)
        end
        self.cursor_row = cursor_row + 1
        self.cursor_col = 0
      end

      def paste_line_before(name: nil)
        text = @register.get(name:)
        lines = text.split("\n", -1)
        lines.reverse_each do |line|
          @buffer.insert_line(cursor_row, line)
        end
        self.cursor_col = 0
      end

      def paste_char_after(name: nil)
        text = @register.get(name:)
        line = @buffer.line(cursor_row)
        insert_col = line.empty? ? 0 : cursor_col + 1

        if text.include?("\n")
          paste_multiline_char(text, line, insert_col)
        else
          @buffer.lines[cursor_row] = line[0...insert_col].to_s + text + line[insert_col..].to_s
          self.cursor_col = insert_col + text.length - 1
          window.clamp_cursor_to_line(@buffer)
        end
      end

      def paste_char_before(name: nil)
        text = @register.get(name:)
        line = @buffer.line(cursor_row)

        if text.include?("\n")
          paste_multiline_char(text, line, cursor_col)
        else
          @buffer.lines[cursor_row] = line[0...cursor_col].to_s + text + line[cursor_col..].to_s
          self.cursor_col = cursor_col + text.length - 1
          window.clamp_cursor_to_line(@buffer)
        end
      end

      def paste_multiline_char(text, line, insert_col)
        lines = text.split("\n", -1)
        before = line[0...insert_col].to_s
        after = line[insert_col..].to_s

        # First line: before + first part of pasted text
        @buffer.lines[cursor_row] = before + lines.first

        # Middle lines: insert as new lines
        lines[1...-1].each_with_index do |pasted_line, idx|
          @buffer.insert_line(cursor_row + 1 + idx, pasted_line)
        end

        # Last line: last part of pasted text + after
        if lines.length > 1
          last_line_row = cursor_row + lines.length - 1
          @buffer.insert_line(last_line_row, lines.last + after)
        end

        # Position cursor at the end of pasted text (before 'after' part)
        self.cursor_row = cursor_row + lines.length - 1
        self.cursor_col = lines.last.length - 1
        self.cursor_col = 0 if cursor_col.negative?
        window.clamp_cursor_to_line(@buffer)
      end

      def extract_text(start_pos, end_pos, inclusive: false)
        if start_pos[:row] == end_pos[:row]
          extract_text_same_line(start_pos, end_pos, inclusive:)
        else
          extract_text_across_lines(start_pos, end_pos, inclusive:)
        end
      end

      def extract_text_same_line(start_pos, end_pos, inclusive: false)
        from_col = [start_pos[:col], end_pos[:col]].min
        to_col = [start_pos[:col], end_pos[:col]].max
        to_col -= 1 unless inclusive
        return "" if to_col < from_col

        @buffer.line(start_pos[:row])[from_col..to_col] || ""
      end

      def extract_text_across_lines(start_pos, end_pos, inclusive: false)
        from_row, to_row = [start_pos[:row], end_pos[:row]].minmax
        from_col = from_row == start_pos[:row] ? start_pos[:col] : end_pos[:col]
        to_col = to_row == end_pos[:row] ? end_pos[:col] : start_pos[:col]
        to_col -= 1 unless inclusive

        lines = []
        (from_row..to_row).each do |row|
          line = @buffer.line(row)
          lines << if row == from_row
                     line[from_col..]
                   elsif row == to_row
                     line[0..to_col]
                   else
                     line
                   end
        end
        lines.join("\n")
      end

      def calculate_motion_end(motion_type)
        case motion_type
        when :word_forward
          Motion.word_forward(@buffer, cursor_row, cursor_col)
        when :word_end
          Motion.word_end(@buffer, cursor_row, cursor_col)
        when :word_backward
          Motion.word_backward(@buffer, cursor_row, cursor_col)
        end
      end

      def execute_delete(start_pos, end_pos, inclusive: false, clamp: true)
        if start_pos[:row] == end_pos[:row]
          execute_delete_same_line(start_pos, end_pos, inclusive:, clamp:)
        else
          execute_delete_across_lines(start_pos, end_pos, inclusive:, clamp:)
        end
      end

      def execute_delete_same_line(start_pos, end_pos, inclusive: false, clamp: true)
        from_col = [start_pos[:col], end_pos[:col]].min
        to_col = [start_pos[:col], end_pos[:col]].max
        to_col -= 1 unless inclusive
        return if to_col < from_col

        @buffer.delete_range(start_pos[:row], from_col, start_pos[:row], to_col)
        self.cursor_col = from_col
        window.clamp_cursor_to_line(@buffer) if clamp
      end

      def execute_delete_across_lines(start_pos, end_pos, inclusive: false, clamp: true)
        from_row, to_row = [start_pos[:row], end_pos[:row]].minmax
        from_col = from_row == start_pos[:row] ? start_pos[:col] : end_pos[:col]
        to_col = to_row == end_pos[:row] ? end_pos[:col] : start_pos[:col]
        to_col -= 1 unless inclusive

        @buffer.delete_range(from_row, from_col, to_row, to_col)
        self.cursor_row = from_row
        self.cursor_col = from_col
        window.clamp_cursor_to_line(@buffer) if clamp
      end

      def apply_motion(motion_result)
        return unless motion_result

        self.cursor_row = motion_result[:row]
        self.cursor_col = motion_result[:col]
        window.clamp_cursor_to_line(@buffer)
      end

      def result(mode: nil, message: nil, quit: false, start_selection: false, line_mode: false, group_started: false)
        HandlerResult::NormalModeResult.new(
          mode:,
          message:,
          quit:,
          start_selection:,
          line_mode:,
          group_started:
        )
      end

      # Undo/Redo handlers
      def handle_undo
        if @undo_manager&.undo(@buffer)
          window.clamp_cursor_to_line(@buffer)
          result
        else
          result(message: "Already at oldest change")
        end
      end

      def handle_redo
        if @undo_manager&.redo(@buffer)
          window.clamp_cursor_to_line(@buffer)
          result
        else
          result(message: "Already at newest change")
        end
      end

      # Search handlers
      def handle_search_next
        return result(message: "No previous search pattern") unless @search_state&.has_pattern?

        match = if @search_state.direction == :forward
                  @search_state.find_next(cursor_row, cursor_col)
                else
                  @search_state.find_previous(cursor_row, cursor_col)
                end

        if match
          apply_motion(match)
          result
        else
          result(message: "Pattern not found: #{@search_state.pattern}")
        end
      end

      def handle_search_previous
        return result(message: "No previous search pattern") unless @search_state&.has_pattern?

        match = if @search_state.direction == :forward
                  @search_state.find_previous(cursor_row, cursor_col)
                else
                  @search_state.find_next(cursor_row, cursor_col)
                end

        if match
          apply_motion(match)
          result
        else
          result(message: "Pattern not found: #{@search_state.pattern}")
        end
      end
    end
  end
end
