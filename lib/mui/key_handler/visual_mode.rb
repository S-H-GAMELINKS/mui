# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handler for character-wise visual mode (v)
    class VisualMode < Base
      include Motions::MotionHandler

      attr_reader :selection

      def initialize(mode_manager, buffer, selection, register = nil, undo_manager: nil)
        super(mode_manager, buffer)
        @selection = selection
        @register = register || Register.new
        @undo_manager = undo_manager
        @pending_motion = nil
        @pending_register = nil
      end

      def handle(key)
        # Check plugin keymaps first (only when no pending motion)
        unless @pending_motion
          plugin_result = check_plugin_keymap(key, :visual)
          return plugin_result if plugin_result
        end

        if @pending_motion
          handle_pending_motion(key)
        else
          handle_visual_key(key)
        end
      end

      private

      def handle_visual_key(key)
        case key
        when KeyCode::ESCAPE
          result(mode: Mode::NORMAL, clear_selection: true)
        when "v"
          handle_v_key
        when "V"
          handle_upper_v_key
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
        when "d"
          handle_delete
        when "c"
          handle_change
        when "y"
          handle_yank
        when ">"
          handle_indent(:right)
        when "<"
          handle_indent(:left)
        when '"'
          @pending_motion = :register_select
          result
        when "*"
          handle_search_selection(:forward)
        when "#"
          handle_search_selection(:backward)
        else
          result
        end
      end

      def handle_v_key
        # v in visual mode exits to normal mode
        result(mode: Mode::NORMAL, clear_selection: true)
      end

      def handle_upper_v_key
        # V in visual mode switches to visual line mode
        result(mode: Mode::VISUAL_LINE, toggle_line_mode: true)
      end

      def handle_delete
        range = @selection.normalized_range
        if @selection.line_mode
          delete_lines(range)
        else
          delete_range(range)
        end
        @pending_register = nil
        result(mode: Mode::NORMAL, clear_selection: true)
      end

      def handle_change
        range = @selection.normalized_range
        if @selection.line_mode
          change_lines(range)
        else
          undo_manager&.begin_group
          change_range(range)
        end
        @pending_register = nil
        result(mode: Mode::INSERT, clear_selection: true, group_started: true)
      end

      def handle_yank
        range = @selection.normalized_range
        if @selection.line_mode
          yank_lines(range)
        else
          yank_range(range)
        end
        @pending_register = nil
        self.cursor_row = range[:start_row]
        self.cursor_col = range[:start_col]
        result(mode: Mode::NORMAL, clear_selection: true)
      end

      def handle_search_selection(direction)
        range = @selection.normalized_range
        text = if @selection.line_mode
                 # For line mode, use the full line content (trimmed)
                 buffer.line(range[:start_row]).strip
               else
                 extract_selection_text(range)
               end

        return result(mode: Mode::NORMAL, clear_selection: true) if text.empty?

        # Escape special regex characters for literal search
        escaped_pattern = Regexp.escape(text)

        # Set search state
        search_state = @mode_manager.search_state
        search_state.set_pattern(escaped_pattern, direction)

        # Find next/previous match from current position
        match = if direction == :forward
                  search_state.find_next(cursor_row, cursor_col, buffer:)
                else
                  search_state.find_previous(cursor_row, cursor_col, buffer:)
                end

        if match
          window.cursor_row = match[:row]
          window.cursor_col = match[:col]
          result(mode: Mode::NORMAL, clear_selection: true)
        else
          result(mode: Mode::NORMAL, clear_selection: true, message: "Pattern not found: #{text}")
        end
      end

      def yank_lines(range)
        lines = (range[:start_row]..range[:end_row]).map { |r| buffer.line(r) }
        @register.yank(lines.join("\n"), linewise: true, name: @pending_register)
      end

      def yank_range(range)
        text = extract_selection_text(range)
        @register.yank(text, linewise: false, name: @pending_register)
      end

      def extract_selection_text(range)
        if range[:start_row] == range[:end_row]
          buffer.line(range[:start_row])[range[:start_col]..range[:end_col]] || ""
        else
          lines = []
          (range[:start_row]..range[:end_row]).each do |row|
            line = buffer.line(row)
            lines << if row == range[:start_row]
                       line[range[:start_col]..]
                     elsif row == range[:end_row]
                       line[0..range[:end_col]]
                     else
                       line
                     end
          end
          lines.join("\n")
        end
      end

      def change_lines(range)
        lines = (range[:start_row]..range[:end_row]).map { |r| buffer.line(r) }
        @register.delete(lines.join("\n"), linewise: true, name: @pending_register)
        undo_manager&.begin_group
        (range[:end_row] - range[:start_row] + 1).times do
          buffer.delete_line(range[:start_row])
        end
        buffer.insert_line(range[:start_row])
        # NOTE: group will be closed when leaving Insert mode
        self.cursor_row = range[:start_row]
        self.cursor_col = 0
      end

      def change_range(range)
        text = extract_selection_text(range)
        @register.delete(text, linewise: false, name: @pending_register)
        buffer.delete_range(range[:start_row], range[:start_col], range[:end_row], range[:end_col])
        self.cursor_row = range[:start_row]
        self.cursor_col = range[:start_col]
        window.clamp_cursor_to_line(buffer)
      end

      def delete_lines(range)
        lines = (range[:start_row]..range[:end_row]).map { |r| buffer.line(r) }
        @register.delete(lines.join("\n"), linewise: true, name: @pending_register)
        undo_manager&.begin_group unless undo_manager&.in_group?
        (range[:end_row] - range[:start_row] + 1).times do
          buffer.delete_line(range[:start_row])
        end
        undo_manager&.end_group
        self.cursor_row = [range[:start_row], buffer.line_count - 1].min
        self.cursor_col = 0
        window.clamp_cursor_to_line(buffer)
      end

      def delete_range(range)
        text = extract_selection_text(range)
        @register.delete(text, linewise: false, name: @pending_register)
        buffer.delete_range(range[:start_row], range[:start_col], range[:end_row], range[:end_col])
        self.cursor_row = range[:start_row]
        self.cursor_col = range[:start_col]
        window.clamp_cursor_to_line(buffer)
      end

      def handle_indent(direction)
        range = @selection.normalized_range
        indent_lines(range[:start_row], range[:end_row], direction)

        # Move cursor to the beginning of the first selected line (Vim behavior)
        self.cursor_row = range[:start_row]
        self.cursor_col = 0

        if Mui.config.get(:reselect_after_indent)
          # Keep selection for continuous indent adjustment
          @selection.update_end(range[:end_row], buffer.line(range[:end_row]).length)
          result
        else
          result(mode: Mode::NORMAL, clear_selection: true)
        end
      end

      def indent_lines(start_row, end_row, direction)
        indent_string = build_indent_string

        undo_manager&.begin_group unless undo_manager&.in_group?

        (start_row..end_row).each do |row|
          if direction == :right
            add_indent(row, indent_string)
          else
            remove_indent(row, Mui.config.get(:shiftwidth))
          end
        end

        undo_manager&.end_group
      end

      def build_indent_string
        if Mui.config.get(:expandtab)
          " " * Mui.config.get(:shiftwidth)
        else
          "\t"
        end
      end

      def add_indent(row, indent_string)
        return if buffer.line(row).empty? # Skip empty lines

        indent_string.reverse.each_char do |char|
          buffer.insert_char(row, 0, char)
        end
      end

      def remove_indent(row, width)
        line = buffer.line(row)
        return if line.empty? # Skip empty lines

        removed = 0

        while removed < width && !line.empty?
          char = line[0]
          break unless [" ", "\t"].include?(char)

          char_width = char == "\t" ? Mui.config.get(:tabstop) : 1
          break if removed + char_width > width && char == "\t"

          buffer.delete_char(row, 0)
          removed += char_width
          line = buffer.line(row)
        end
      end

      def handle_pending_motion(key)
        char = key_to_char(key)
        return clear_pending unless char

        return handle_register_select(char) if @pending_motion == :register_select

        motion_result = execute_pending_motion(char)
        apply_motion(motion_result) if motion_result
        clear_pending
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

      def clear_pending
        @pending_motion = nil
        @pending_register = nil
        result
      end

      def handle_move_left
        window.move_left
        update_selection
        result
      end

      def handle_move_down
        window.move_down
        update_selection
        result
      end

      def handle_move_up
        window.move_up
        update_selection
        result
      end

      def handle_move_right
        window.move_right
        update_selection
        result
      end

      def apply_motion(motion_result)
        super
        update_selection if motion_result
      end

      def update_selection
        @selection.update_end(cursor_row, cursor_col)
      end

      def result(mode: nil, message: nil, quit: false, clear_selection: false, toggle_line_mode: false, group_started: false)
        HandlerResult::VisualModeResult.new(
          mode:,
          message:,
          quit:,
          clear_selection:,
          toggle_line_mode:,
          group_started:
        )
      end
    end
  end
end
