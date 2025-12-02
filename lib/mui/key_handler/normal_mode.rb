# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handles key inputs in Normal mode
    class NormalMode < Base
      def initialize(window, buffer)
        super
        @pending_motion = nil
      end

      def handle(key)
        if @pending_motion
          handle_pending_motion(key)
        else
          handle_normal_key(key)
        end
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
        when ":"
          result(mode: Mode::COMMAND)
        else
          result
        end
      end

      def handle_pending_motion(key)
        char = key_to_char(key)
        return clear_pending unless char

        motion_result = execute_pending_motion(char)
        apply_motion(motion_result) if motion_result
        clear_pending
      end

      def key_to_char(key)
        key.is_a?(String) ? key : key.chr
      rescue StandardError
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
        result
      end

      # Movement handlers
      def handle_move_left
        @window.move_left
        result
      end

      def handle_move_down
        @window.move_down
        result
      end

      def handle_move_up
        @window.move_up
        result
      end

      def handle_move_right
        @window.move_right
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
        @buffer.insert_line(cursor_row + 1)
        self.cursor_row = cursor_row + 1
        self.cursor_col = 0
        result(mode: Mode::INSERT)
      end

      def handle_open_above
        @buffer.insert_line(cursor_row)
        self.cursor_col = 0
        result(mode: Mode::INSERT)
      end

      def handle_delete_char
        @buffer.delete_char(cursor_row, cursor_col)
        result
      end

      def apply_motion(motion_result)
        return unless motion_result

        self.cursor_row = motion_result[:row]
        self.cursor_col = motion_result[:col]
        @window.clamp_cursor_to_line(@buffer)
      end
    end
  end
end
