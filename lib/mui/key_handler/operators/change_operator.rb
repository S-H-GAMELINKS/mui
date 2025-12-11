# frozen_string_literal: true

module Mui
  module KeyHandler
    module Operators
      # NOTE: ChangeOperator inherits from DeleteOperator.
      # This aligns with Vim semantics (change = "delete then enter INSERT mode")
      # and keeps the code simple.
      # However, if changes to DeleteOperator cause bugs in ChangeOperator,
      # consider switching to a delegation pattern
      # (inherit from BaseOperator and delegate to a DeleteOperator instance).

      # Handles change operator (c) in Normal mode
      class ChangeOperator < DeleteOperator
        # Handle pending change motion
        def handle_pending(char, pending_register: nil)
          @pending_register = pending_register
          case char
          when "c"
            change_line
          when "w"
            change_motion(:word_forward)
          when "e"
            change_motion(:word_end)
          when "b"
            change_motion(:word_backward)
          when "0"
            change_to_line_start
          when "$"
            change_to_line_end
          when "g"
            :pending_cg
          when "G"
            change_to_file_end
          when "f"
            :pending_cf
          when "F"
            :pending_cF
          when "t"
            :pending_ct
          when "T"
            :pending_cT
          else
            :cancel
          end
        end

        # Handle cg (change to file start with gg)
        def handle_to_file_start(char)
          return :cancel unless char == "g"

          if cursor_row.zero?
            change_to_line_start_internal
          else
            change_to_file_start_internal
          end
          :insert_mode
        end

        # Handle cf/cF/ct/cT (change with find char)
        def handle_find_char(char, motion_type)
          motion_result = case motion_type
                          when :cf
                            Motion.find_char_forward(@buffer, cursor_row, cursor_col, char)
                          when :cF
                            Motion.find_char_backward(@buffer, cursor_row, cursor_col, char)
                          when :ct
                            Motion.till_char_forward(@buffer, cursor_row, cursor_col, char)
                          when :cT
                            Motion.till_char_backward(@buffer, cursor_row, cursor_col, char)
                          end
          return :cancel unless motion_result

          execute_find_char_change(motion_result, motion_type)
          :insert_mode
        end

        private

        def change_line
          text = @buffer.line(cursor_row)
          @register.delete(text, linewise: true, name: @pending_register)
          @buffer.lines[cursor_row] = +""
          self.cursor_col = 0
          :insert_mode
        end

        def change_motion(motion_type)
          start_pos = { row: cursor_row, col: cursor_col }
          # cw behaves like ce in Vim (changes to end of word, not to start of next word)
          effective_motion = motion_type == :word_forward ? :word_end : motion_type
          end_pos = calculate_motion_end(effective_motion)
          return :cancel unless end_pos

          inclusive = effective_motion == :word_end
          text = extract_text(start_pos, end_pos, inclusive:)
          @register.delete(text, linewise: false, name: @pending_register)
          execute_delete(start_pos, end_pos, inclusive:, clamp: false)
          :insert_mode
        end

        def change_to_line_start
          return :insert_mode if cursor_col.zero?

          text = @buffer.line(cursor_row)[0...cursor_col]
          @register.delete(text, linewise: false, name: @pending_register)
          @buffer.delete_range(cursor_row, 0, cursor_row, cursor_col - 1)
          self.cursor_col = 0
          :insert_mode
        end

        def change_to_line_end
          line = @buffer.line(cursor_row)
          return :insert_mode if line.empty?

          text = line[cursor_col..]
          @register.delete(text, linewise: false, name: @pending_register)
          end_col = line.length - 1
          @buffer.delete_range(cursor_row, cursor_col, cursor_row, end_col)
          # Don't clamp cursor - keep it at original position for insert mode
          :insert_mode
        end

        def change_to_file_end
          last_row = @buffer.line_count - 1
          if cursor_row == last_row
            change_line
          else
            lines = (cursor_row..last_row).map { |r| @buffer.line(r) }
            @register.delete(lines.join("\n"), linewise: true, name: @pending_register)
            (last_row - cursor_row + 1).times { @buffer.delete_line(cursor_row) }
            @buffer.insert_line(cursor_row) if @buffer.line_count == cursor_row
            self.cursor_row = [cursor_row, @buffer.line_count - 1].min
            self.cursor_col = 0
            :insert_mode
          end
        end

        def change_to_line_start_internal
          return if cursor_col.zero?

          text = @buffer.line(cursor_row)[0...cursor_col]
          @register.delete(text, linewise: false, name: @pending_register)
          @buffer.delete_range(cursor_row, 0, cursor_row, cursor_col - 1)
          self.cursor_col = 0
        end

        def change_to_file_start_internal
          lines = (0..cursor_row).map { |r| @buffer.line(r) }
          @register.delete(lines.join("\n"), linewise: true, name: @pending_register)
          cursor_row.times { @buffer.delete_line(0) }
          @buffer.delete_range(0, 0, 0, cursor_col - 1) if cursor_col.positive?
          self.cursor_row = 0
          self.cursor_col = 0
        end

        def execute_find_char_change(motion_result, motion_type)
          line = @buffer.line(cursor_row)
          text = case motion_type
                 when :cf, :ct
                   line[cursor_col..motion_result[:col]]
                 when :cF, :cT
                   line[motion_result[:col]...cursor_col]
                 end
          @register.delete(text, linewise: false, name: @pending_register) if text

          case motion_type
          when :cf, :ct
            @buffer.delete_range(cursor_row, cursor_col, cursor_row, motion_result[:col])
          when :cF, :cT
            @buffer.delete_range(cursor_row, motion_result[:col], cursor_row, cursor_col - 1)
            self.cursor_col = motion_result[:col]
          end
          # Don't clamp cursor - keep it at original position for insert mode
        end
      end
    end
  end
end
