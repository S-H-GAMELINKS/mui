# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handles key inputs in Insert mode
    class InsertMode < Base
      def initialize(mode_manager, buffer, undo_manager: nil, group_started: false)
        super(mode_manager, buffer)
        @undo_manager = undo_manager
        # Start undo group unless already started (e.g., by change operator)
        @undo_manager&.begin_group unless group_started
      end

      def handle(key)
        case key
        when KeyCode::ESCAPE
          handle_escape
        when Curses::KEY_LEFT
          handle_move_left
        when Curses::KEY_RIGHT
          handle_move_right
        when Curses::KEY_UP
          handle_move_up
        when Curses::KEY_DOWN
          handle_move_down
        when KeyCode::BACKSPACE, Curses::KEY_BACKSPACE
          handle_backspace
        when KeyCode::ENTER_CR, KeyCode::ENTER_LF, Curses::KEY_ENTER
          handle_enter
        else
          handle_character_input(key)
        end
      end

      private

      def handle_escape
        @undo_manager&.end_group
        # Remove trailing whitespace from current line if it's whitespace-only (Vim behavior)
        stripped = strip_trailing_whitespace_if_empty_line
        # Move cursor back one position unless we just stripped whitespace (cursor already at 0)
        self.cursor_col = cursor_col - 1 if cursor_col.positive? && !stripped
        result(mode: Mode::NORMAL)
      end

      def strip_trailing_whitespace_if_empty_line
        line = buffer.line(cursor_row)
        return false unless line.match?(/\A[ \t]+\z/)

        # Line contains only whitespace, clear it
        line.length.times { buffer.delete_char(cursor_row, 0) }
        self.cursor_col = 0
        true
      end

      def handle_move_left
        self.cursor_col = cursor_col - 1 if cursor_col.positive?
        result
      end

      def handle_move_right
        self.cursor_col = cursor_col + 1 if cursor_col < current_line_length
        result
      end

      def handle_move_up
        window.move_up
        result
      end

      def handle_move_down
        window.move_down
        result
      end

      def handle_backspace
        if cursor_col.positive?
          self.cursor_col = cursor_col - 1
          buffer.delete_char(cursor_row, cursor_col)
        elsif cursor_row.positive?
          join_with_previous_line
        end
        result
      end

      def join_with_previous_line
        prev_line_len = buffer.line(cursor_row - 1).length
        buffer.join_lines(cursor_row - 1)
        self.cursor_row = cursor_row - 1
        self.cursor_col = prev_line_len
      end

      def handle_enter
        # Get indent from current line before splitting
        current_line = buffer.line(cursor_row)
        indent = extract_indent(current_line)

        buffer.split_line(cursor_row, cursor_col)
        self.cursor_row = cursor_row + 1

        # Insert indent at the beginning of the new line
        if indent && !indent.empty?
          indent.each_char.with_index do |char, i|
            buffer.insert_char(cursor_row, i, char)
          end
          self.cursor_col = indent.length
        else
          self.cursor_col = 0
        end
        result
      end

      def extract_indent(line)
        match = line.match(/\A([ \t]*)/)
        match ? match[1] : ""
      end

      def handle_character_input(key)
        char = extract_printable_char(key)
        if char
          buffer.insert_char(cursor_row, cursor_col, char)
          self.cursor_col = cursor_col + 1
        end
        result
      end

      def result(mode: nil, message: nil, quit: false)
        HandlerResult::InsertModeResult.new(mode:, message:, quit:)
      end
    end
  end
end
