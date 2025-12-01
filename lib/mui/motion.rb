# frozen_string_literal: true

module Mui
  module Motion
    WORD_CHARS = /[a-zA-Z0-9_]/

    class << self
      # Basic movements
      def left(_buffer, row, col)
        col.positive? ? { row: row, col: col - 1 } : nil
      end

      def right(buffer, row, col)
        line = buffer.line(row)
        col < line.size - 1 ? { row: row, col: col + 1 } : nil
      end

      def up(_buffer, row, col)
        row.positive? ? { row: row - 1, col: col } : nil
      end

      def down(buffer, row, col)
        row < buffer.line_count - 1 ? { row: row + 1, col: col } : nil
      end

      # Word movements
      def word_forward(buffer, row, col)
        line = buffer.line(row)

        # Move past current word
        col += 1 while col < line.size && line[col] =~ WORD_CHARS

        # Skip whitespace
        col += 1 while col < line.size && line[col] =~ /\s/

        # If at end of line, move to next line
        if col >= line.size && row < buffer.line_count - 1
          next_line = buffer.line(row + 1)
          # Find first non-whitespace character on next line
          next_col = 0
          next_col += 1 while next_col < next_line.size && next_line[next_col] =~ /\s/
          return { row: row + 1, col: next_col }
        end

        { row: row, col: col }
      end

      def word_backward(buffer, row, col)
        buffer.line(row)

        # If at start of line, go to previous line
        if col.zero? && row.positive?
          prev_line = buffer.line(row - 1)
          return word_backward(buffer, row - 1, prev_line.size)
        end

        # Move back one position to check previous character
        col -= 1 if col.positive?
        line = buffer.line(row)

        # Skip whitespace
        col -= 1 while col.positive? && line[col] =~ /\s/

        # Move to start of word
        col -= 1 while col.positive? && line[col - 1] =~ WORD_CHARS

        { row: row, col: col }
      end

      def word_end(buffer, row, col)
        line = buffer.line(row)

        # Move forward one position
        col += 1 if col < line.size

        # Skip whitespace
        col += 1 while col < line.size && line[col] =~ /\s/

        # If at end of line, move to next line
        return word_end(buffer, row + 1, 0) if col >= line.size && row < buffer.line_count - 1

        # Move to end of word
        col += 1 while col < line.size - 1 && line[col + 1] =~ WORD_CHARS

        { row: row, col: col }
      end

      # Line start/end movements
      def line_start(_buffer, row, _col)
        { row: row, col: 0 }
      end

      def first_non_blank(buffer, row, _col)
        line = buffer.line(row)
        new_col = line.index(/\S/) || 0
        { row: row, col: new_col }
      end

      def line_end(buffer, row, _col)
        line = buffer.line(row)
        { row: row, col: [line.size - 1, 0].max }
      end

      # File start/end movements
      def file_start(_buffer, _row, _col)
        { row: 0, col: 0 }
      end

      def file_end(buffer, _row, _col)
        last_row = buffer.line_count - 1
        { row: last_row, col: 0 }
      end

      # Character search (f, F, t, T)
      def find_char_forward(buffer, row, col, char)
        line = buffer.line(row)
        index = line.index(char, col + 1)
        index ? { row: row, col: index } : nil
      end

      def find_char_backward(buffer, row, col, char)
        line = buffer.line(row)
        search_range = line[0...col]
        index = search_range.rindex(char)
        index ? { row: row, col: index } : nil
      end

      def till_char_forward(buffer, row, col, char)
        result = find_char_forward(buffer, row, col, char)
        result ? { row: result[:row], col: result[:col] - 1 } : nil
      end

      def till_char_backward(buffer, row, col, char)
        result = find_char_backward(buffer, row, col, char)
        result ? { row: result[:row], col: result[:col] + 1 } : nil
      end
    end
  end
end
