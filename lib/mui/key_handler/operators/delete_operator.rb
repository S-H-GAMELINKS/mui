# frozen_string_literal: true

module Mui
  module KeyHandler
    module Operators
      # Handles delete operator (d) in Normal mode
      class DeleteOperator < BaseOperator
        # Handle pending delete motion
        def handle_pending(char, pending_register: nil)
          @pending_register = pending_register
          case char
          when "d"
            delete_line
          when "w"
            delete_motion(:word_forward)
          when "e"
            delete_motion(:word_end)
          when "b"
            delete_motion(:word_backward)
          when "0"
            delete_to_line_start
          when "$"
            delete_to_line_end
          when "g"
            :pending_dg
          when "G"
            delete_to_file_end
          when "f"
            :pending_df
          when "F"
            :pending_dF
          when "t"
            :pending_dt
          when "T"
            :pending_dT
          else
            :cancel
          end
        end

        # Handle dg (delete to file start with gg)
        def handle_to_file_start(char)
          return :cancel unless char == "g"

          if cursor_row.zero?
            delete_to_line_start_internal
          else
            delete_to_file_start_internal
          end
          :done
        end

        # Handle df/dF/dt/dT (delete with find char)
        def handle_find_char(char, motion_type)
          motion_result = case motion_type
                          when :df
                            Motion.find_char_forward(@buffer, cursor_row, cursor_col, char)
                          when :dF
                            Motion.find_char_backward(@buffer, cursor_row, cursor_col, char)
                          when :dt
                            Motion.till_char_forward(@buffer, cursor_row, cursor_col, char)
                          when :dT
                            Motion.till_char_backward(@buffer, cursor_row, cursor_col, char)
                          end
          return :cancel unless motion_result

          execute_find_char_delete(motion_result, motion_type)
          :done
        end

        protected

        def delete_line
          text = @buffer.line(cursor_row)
          @register.delete(text, linewise: true, name: @pending_register)
          @buffer.delete_line(cursor_row)
          self.cursor_row = [cursor_row, @buffer.line_count - 1].min
          @window.clamp_cursor_to_line(@buffer)
          :done
        end

        def delete_motion(motion_type)
          start_pos = { row: cursor_row, col: cursor_col }
          end_pos = calculate_motion_end(motion_type)
          return :cancel unless end_pos

          inclusive = motion_type == :word_end
          text = extract_text(start_pos, end_pos, inclusive:)
          @register.delete(text, linewise: false, name: @pending_register)
          execute_delete(start_pos, end_pos, inclusive:)
          :done
        end

        def delete_to_line_start
          return :done if cursor_col.zero?

          text = @buffer.line(cursor_row)[0...cursor_col]
          @register.delete(text, linewise: false, name: @pending_register)
          @buffer.delete_range(cursor_row, 0, cursor_row, cursor_col - 1)
          self.cursor_col = 0
          :done
        end

        def delete_to_line_end
          line = @buffer.line(cursor_row)
          return :done if line.empty?

          text = line[cursor_col..]
          @register.delete(text, linewise: false, name: @pending_register)
          end_col = line.length - 1
          @buffer.delete_range(cursor_row, cursor_col, cursor_row, end_col)
          @window.clamp_cursor_to_line(@buffer)
          :done
        end

        def delete_to_file_end
          last_row = @buffer.line_count - 1
          if cursor_row == last_row
            delete_line
          else
            lines = (cursor_row..last_row).map { |r| @buffer.line(r) }
            @register.delete(lines.join("\n"), linewise: true, name: @pending_register)
            @undo_manager&.begin_group
            (last_row - cursor_row + 1).times { @buffer.delete_line(cursor_row) }
            @undo_manager&.end_group
            self.cursor_row = [cursor_row, @buffer.line_count - 1].min
            @window.clamp_cursor_to_line(@buffer)
            :done
          end
        end

        private

        def delete_to_line_start_internal
          return if cursor_col.zero?

          text = @buffer.line(cursor_row)[0...cursor_col]
          @register.delete(text, linewise: false, name: @pending_register)
          @buffer.delete_range(cursor_row, 0, cursor_row, cursor_col - 1)
          self.cursor_col = 0
        end

        def delete_to_file_start_internal
          lines = (0..cursor_row).map { |r| @buffer.line(r) }
          @register.delete(lines.join("\n"), linewise: true, name: @pending_register)
          @undo_manager&.begin_group
          cursor_row.times { @buffer.delete_line(0) }
          @buffer.delete_range(0, 0, 0, cursor_col - 1) if cursor_col.positive?
          @undo_manager&.end_group
          self.cursor_row = 0
          self.cursor_col = 0
        end

        def execute_find_char_delete(motion_result, motion_type)
          line = @buffer.line(cursor_row)
          text = case motion_type
                 when :df, :dt
                   line[cursor_col..motion_result[:col]]
                 when :dF, :dT
                   line[motion_result[:col]...cursor_col]
                 end
          @register.delete(text, linewise: false, name: @pending_register) if text

          case motion_type
          when :df, :dt
            @buffer.delete_range(cursor_row, cursor_col, cursor_row, motion_result[:col])
          when :dF, :dT
            @buffer.delete_range(cursor_row, motion_result[:col], cursor_row, cursor_col - 1)
            self.cursor_col = motion_result[:col]
          end
          @window.clamp_cursor_to_line(@buffer)
        end
      end
    end
  end
end
