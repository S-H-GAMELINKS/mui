# frozen_string_literal: true

module Mui
  module KeyHandler
    module Motions
      # Shared motion handling for NormalMode and VisualMode
      # Provides common handle_* methods that delegate to Motion module
      module MotionHandler
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

        private

        def apply_motion(motion_result)
          return unless motion_result

          self.cursor_row = motion_result[:row]
          self.cursor_col = motion_result[:col]
          window.clamp_cursor_to_line(@buffer)
        end
      end
    end
  end
end
