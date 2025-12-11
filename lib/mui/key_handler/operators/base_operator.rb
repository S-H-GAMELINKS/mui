# frozen_string_literal: true

module Mui
  module KeyHandler
    module Operators
      # Base class for operator implementations (delete, change, yank, paste)
      # Provides common functionality for text extraction, deletion, and cursor management
      class BaseOperator
        def initialize(buffer:, window:, register:, undo_manager: nil)
          @buffer = buffer
          @window = window
          @register = register
          @undo_manager = undo_manager
        end

        # Update dependencies (called when window changes)
        def update(buffer: nil, window: nil, register: nil, undo_manager: nil)
          @buffer = buffer if buffer
          @window = window if window
          @register = register if register
          @undo_manager = undo_manager if undo_manager
        end

        # Handle pending operator motion
        def handle_pending(_char, pending_register: nil) # rubocop:disable Lint/UnusedMethodArgument
          raise Mui::MethodNotOverriddenError, :handle_pending
        end

        protected

        attr_reader :buffer, :window, :register, :undo_manager

        # Cursor accessors
        def cursor_row
          @window.cursor_row
        end

        def cursor_col
          @window.cursor_col
        end

        def cursor_row=(value)
          @window.cursor_row = value
        end

        def cursor_col=(value)
          @window.cursor_col = value
        end

        # Text extraction methods
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

        # Motion calculation
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

        # Delete execution methods (used by delete and change operators)
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
          @window.clamp_cursor_to_line(@buffer) if clamp
        end

        def execute_delete_across_lines(start_pos, end_pos, inclusive: false, clamp: true)
          from_row, to_row = [start_pos[:row], end_pos[:row]].minmax
          from_col = from_row == start_pos[:row] ? start_pos[:col] : end_pos[:col]
          to_col = to_row == end_pos[:row] ? end_pos[:col] : start_pos[:col]
          to_col -= 1 unless inclusive

          @buffer.delete_range(from_row, from_col, to_row, to_col)
          self.cursor_row = from_row
          self.cursor_col = from_col
          @window.clamp_cursor_to_line(@buffer) if clamp
        end
      end
    end
  end
end
