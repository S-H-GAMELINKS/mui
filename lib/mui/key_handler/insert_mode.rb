# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handles key inputs in Insert mode
    class InsertMode < Base
      def handle(key)
        case key
        when 27 # Escape
          handle_escape
        when Curses::KEY_LEFT
          handle_move_left
        when Curses::KEY_RIGHT
          handle_move_right
        when Curses::KEY_UP
          handle_move_up
        when Curses::KEY_DOWN
          handle_move_down
        when 127, Curses::KEY_BACKSPACE
          handle_backspace
        when 13, 10, Curses::KEY_ENTER
          handle_enter
        else
          handle_character_input(key)
        end
      end

      private

      def handle_escape
        self.cursor_col = cursor_col - 1 if cursor_col.positive?
        result(mode: Mode::NORMAL)
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
        @window.move_up
        result
      end

      def handle_move_down
        @window.move_down
        result
      end

      def handle_backspace
        if cursor_col.positive?
          self.cursor_col = cursor_col - 1
          @buffer.delete_char(cursor_row, cursor_col)
        elsif cursor_row.positive?
          join_with_previous_line
        end
        result
      end

      def join_with_previous_line
        prev_line_len = @buffer.line(cursor_row - 1).length
        @buffer.join_lines(cursor_row - 1)
        self.cursor_row = cursor_row - 1
        self.cursor_col = prev_line_len
      end

      def handle_enter
        @buffer.split_line(cursor_row, cursor_col)
        self.cursor_row = cursor_row + 1
        self.cursor_col = 0
        result
      end

      def handle_character_input(key)
        char = extract_printable_char(key)
        if char
          @buffer.insert_char(cursor_row, cursor_col, char)
          self.cursor_col = cursor_col + 1
        end
        result
      end

      def extract_printable_char(key)
        if key.is_a?(String)
          key
        elsif key.is_a?(Integer) && key >= 32 && key < 127
          key.chr
        end
      end
    end
  end
end
