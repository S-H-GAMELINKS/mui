# frozen_string_literal: true

module Mui
  module Syntax
    # Caches tokenization results on a per-line basis
    # Handles multiline state propagation across lines
    class TokenCache
      # Number of lines to prefetch ahead/behind visible area
      PREFETCH_LINES = 50

      def initialize(lexer)
        @lexer = lexer
        @cache = {} # row => { tokens:, line_hash:, state_after: }
      end

      # Get tokens for a specific line, using cache when available
      # Only tokenizes the requested line - does NOT pre-compute previous lines
      # @param row [Integer] the line number (0-indexed)
      # @param line [String] the line content
      # @param buffer_lines [Array<String>] all lines in the buffer (for state propagation)
      # @return [Array<Token>] the tokens for this line
      def tokens_for(row, line, _buffer_lines)
        line_hash = line.hash

        # Check cache validity (single hash lookup)
        cached = @cache[row]
        return cached[:tokens] if cached && cached[:line_hash] == line_hash

        # Get state from previous line's cache (if available)
        # If not available, assume nil (no multiline state)
        # This trades accuracy for performance - multiline constructs
        # may not highlight correctly until user scrolls through the file
        prev_cached = @cache[row - 1]
        state_before = prev_cached&.dig(:state_after)

        # Tokenize this line
        tokens, state_after = @lexer.tokenize(line, state_before)

        # Store in cache
        @cache[row] = {
          tokens:,
          line_hash:,
          state_after:
        }

        tokens
      end

      # Prefetch tokens for lines around the visible area
      # @param visible_start [Integer] first visible row
      # @param visible_end [Integer] last visible row
      # @param buffer_lines [Array<String>] all lines in the buffer
      def prefetch(visible_start, visible_end, buffer_lines)
        return if buffer_lines.empty?

        # Calculate prefetch range
        prefetch_start = [visible_start - PREFETCH_LINES, 0].max
        prefetch_end = [visible_end + PREFETCH_LINES, buffer_lines.length - 1].min

        # Tokenize lines that aren't cached yet
        (prefetch_start..prefetch_end).each do |row|
          line = buffer_lines[row]
          next if line.nil?

          line_hash = line.hash
          cached = @cache[row]
          next if cached && cached[:line_hash] == line_hash

          prev_cached = @cache[row - 1]
          state_before = prev_cached&.dig(:state_after)
          tokens, state_after = @lexer.tokenize(line, state_before)

          @cache[row] = {
            tokens:,
            line_hash:,
            state_after:
          }
        end
      end

      # Invalidate cache from a specific row onwards
      # This is called when a line is modified
      # @param from_row [Integer] the first row to invalidate
      def invalidate(from_row)
        @cache.delete_if { |row, _| row >= from_row }
      end

      # Clear the entire cache
      def clear
        @cache.clear
      end

      # Check if a row has cached data
      def cached?(row)
        @cache.key?(row)
      end
    end
  end
end
