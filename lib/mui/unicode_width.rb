# frozen_string_literal: true

module Mui
  # Utility module for calculating display width of Unicode characters
  # CJK characters and some other characters are "wide" (2 cells)
  module UnicodeWidth
    class << self
      # Returns the display width of a single character
      def char_width(char)
        return 0 if char.nil? || char.empty?

        ord = char.ord

        # Control characters
        return 0 if ord < 32

        # ASCII printable characters
        return 1 if ord < 127

        # Non-printable
        return 0 if ord == 127

        # Wide characters (East Asian Wide and Fullwidth)
        return 2 if wide_char?(ord)

        # Default to 1 for other characters
        1
      end

      # Returns the display width of a string
      def string_width(str)
        return 0 if str.nil?

        str.chars.sum { |c| char_width(c) }
      end

      # Returns the display width of a substring from index 0 to col (exclusive)
      def width_to_col(str, col)
        return 0 if str.nil? || col <= 0

        str.chars.take(col).sum { |c| char_width(c) }
      end

      # Returns the character index for a given display width position
      def col_at_width(str, target_width)
        return 0 if str.nil? || target_width <= 0

        current_width = 0
        str.chars.each_with_index do |char, index|
          return index if current_width >= target_width

          current_width += char_width(char)
        end
        str.length
      end

      private

      def wide_char?(ord)
        # CJK ranges (simplified, covers most common cases)
        # Full implementation would use Unicode East Asian Width property

        # Hangul Jamo
        return true if ord.between?(0x1100, 0x115F)

        # CJK Radicals Supplement to Enclosed CJK Letters
        return true if ord.between?(0x2E80, 0x4DBF)

        # CJK Unified Ideographs
        return true if ord.between?(0x4E00, 0x9FFF)

        # Hangul Syllables
        return true if ord.between?(0xAC00, 0xD7AF)

        # CJK Compatibility Ideographs
        return true if ord.between?(0xF900, 0xFAFF)

        # Fullwidth Forms
        return true if ord.between?(0xFF00, 0xFF60)

        # CJK Unified Ideographs Extension B-F
        return true if ord.between?(0x20000, 0x2FA1F)

        # Halfwidth Katakana (narrow, actually 1)
        return false if ord.between?(0xFF61, 0xFFDC)

        # Japanese Hiragana
        return true if ord.between?(0x3040, 0x309F)

        # Japanese Katakana
        return true if ord.between?(0x30A0, 0x30FF)

        # CJK Symbols and Punctuation
        return true if ord.between?(0x3000, 0x303F)

        false
      end
    end
  end
end
