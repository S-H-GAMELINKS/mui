# frozen_string_literal: true

module Mui
  module KeyHandler
    module Operators
      # Handles yank operator (y) in Normal mode
      # Unlike delete/change, yank does not modify the buffer
      class YankOperator < BaseOperator
        # Handle pending yank motion
        def handle_pending(char, pending_register: nil)
          @pending_register = pending_register
          case char
          when "y"
            yank_line
          when "w"
            yank_motion(:word_forward)
          when "e"
            yank_motion(:word_end)
          when "b"
            yank_motion(:word_backward)
          when "0"
            yank_to_line_start
          when "$"
            yank_to_line_end
          when "g"
            :pending_yg
          when "G"
            yank_to_file_end
          when "f"
            :pending_yf
          when "F"
            :pending_yF
          when "t"
            :pending_yt
          when "T"
            :pending_yT
          else
            :cancel
          end
        end

        # Handle yg (yank to file start with gg)
        def handle_to_file_start(char)
          return :cancel unless char == "g"

          lines = (0..cursor_row).map { |r| @buffer.line(r) }
          text = lines.join("\n")
          @register.yank(text, linewise: true, name: @pending_register)
          :done
        end

        # Handle yf/yF/yt/yT (yank with find char)
        def handle_find_char(char, motion_type)
          motion_result = case motion_type
                          when :yf
                            Motion.find_char_forward(@buffer, cursor_row, cursor_col, char)
                          when :yF
                            Motion.find_char_backward(@buffer, cursor_row, cursor_col, char)
                          when :yt
                            Motion.till_char_forward(@buffer, cursor_row, cursor_col, char)
                          when :yT
                            Motion.till_char_backward(@buffer, cursor_row, cursor_col, char)
                          end
          return :cancel unless motion_result

          execute_find_char_yank(motion_result, motion_type)
          :done
        end

        private

        def yank_line
          text = @buffer.line(cursor_row)
          @register.yank(text, linewise: true, name: @pending_register)
          :done
        end

        def yank_motion(motion_type)
          start_pos = { row: cursor_row, col: cursor_col }
          effective_motion = motion_type == :word_forward ? :word_end : motion_type
          end_pos = calculate_motion_end(effective_motion)
          return :cancel unless end_pos

          inclusive = effective_motion == :word_end
          text = extract_text(start_pos, end_pos, inclusive:)
          @register.yank(text, linewise: false, name: @pending_register)
          :done
        end

        def yank_to_line_start
          return :done if cursor_col.zero?

          text = @buffer.line(cursor_row)[0...cursor_col]
          @register.yank(text, linewise: false, name: @pending_register)
          :done
        end

        def yank_to_line_end
          line = @buffer.line(cursor_row)
          return :done if line.empty?

          text = line[cursor_col..]
          @register.yank(text, linewise: false, name: @pending_register)
          :done
        end

        def yank_to_file_end
          lines = (cursor_row...@buffer.line_count).map { |r| @buffer.line(r) }
          text = lines.join("\n")
          @register.yank(text, linewise: true, name: @pending_register)
          :done
        end

        def execute_find_char_yank(motion_result, motion_type)
          line = @buffer.line(cursor_row)
          text = case motion_type
                 when :yf, :yt
                   line[cursor_col..motion_result[:col]]
                 when :yF, :yT
                   line[motion_result[:col]...cursor_col]
                 end
          @register.yank(text, linewise: false, name: @pending_register)
        end
      end
    end
  end
end
