# frozen_string_literal: true

module Mui
  # Helper module for line wrapping calculations
  module WrapHelper
    class << self
      # Wraps a line into screen lines based on display width
      # Returns: [{ text:, start_col:, end_col: }, ...]
      def wrap_line(line, width, cache: nil)
        return [{ text: "", start_col: 0, end_col: 0 }] if line.nil? || line.empty?
        return [{ text: line, start_col: 0, end_col: line.length }] if width <= 0

        if cache
          cached = cache.get(line, width)
          return cached if cached
        end

        result = compute_wrap(line, width)
        cache&.set(line, width, result)
        result
      end

      # Converts logical column to screen position
      # Returns: [screen_row_offset, screen_col]
      def logical_to_screen(line, col, width, cache: nil)
        return [0, 0] if line.nil? || line.empty? || col <= 0

        wrapped = wrap_line(line, width, cache:)

        wrapped.each_with_index do |segment, row|
          next unless col <= segment[:end_col]

          # Found the segment containing this column
          relative_col = col - segment[:start_col]
          prefix = segment[:text][0, relative_col] || ""
          screen_col = UnicodeWidth.string_width(prefix)
          return [row, screen_col]
        end

        # Column is past end of line, return last position
        last_segment = wrapped.last
        last_text = last_segment[:text]
        [wrapped.size - 1, UnicodeWidth.string_width(last_text)]
      end

      # Returns the number of screen lines for a logical line
      def screen_line_count(line, width, cache: nil)
        wrap_line(line, width, cache:).size
      end

      private

      def compute_wrap(line, width)
        result = []
        chars = line.chars
        current_text = String.new
        current_width = 0
        start_col = 0
        col = 0

        chars.each do |char|
          char_w = UnicodeWidth.char_width(char)

          # Check if adding this character would exceed width
          if current_width + char_w > width && !current_text.empty?
            result << { text: current_text, start_col:, end_col: col }
            current_text = String.new
            current_width = 0
            start_col = col
          end

          current_text << char
          current_width += char_w
          col += 1
        end

        # Add remaining text
        result << { text: current_text, start_col:, end_col: col } unless current_text.empty?

        result.empty? ? [{ text: String.new, start_col: 0, end_col: 0 }] : result
      end
    end
  end
end
