# frozen_string_literal: true

module Mui
  module Syntax
    # Base class for language-specific lexers
    # Subclasses should override token_patterns and optionally handle_multiline_state
    class LexerBase
      # Tokenize a single line of text
      # TODO: Refactor to reduce complexity (Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity)
      def tokenize(line, state = nil)
        tokens = []
        pos = 0
        current_state = state

        while pos < line.length
          # Handle multiline state first (e.g., inside block comment)
          if current_state
            token, new_state, new_pos = handle_multiline_state(line, pos, current_state)
            if token
              tokens << token
              pos = new_pos
              current_state = new_state
              next
            elsif new_state.nil?
              # State ended, continue normal tokenization
              current_state = nil
              pos = new_pos
              next
            end
          end

          # Check for multiline state start
          new_state, token, new_pos = check_multiline_start(line, pos)
          if new_state
            tokens << token if token
            pos = new_pos
            current_state = new_state
            next
          end

          # Normal token matching
          token = match_token(line, pos)
          if token
            tokens << token
            pos = token.end_col + 1
          else
            # Skip unrecognized character
            pos += 1
          end
        end

        [tokens, current_state]
      end

      # Check if a state continues to the next line
      def continuing_state?(state)
        !state.nil?
      end

      protected

      # Override in subclass to define token patterns
      def token_patterns
        []
      end

      # Override in subclass to handle multiline constructs
      def handle_multiline_state(_line, pos, _state)
        [nil, nil, pos]
      end

      # Override in subclass to check for multiline construct starts
      def check_multiline_start(_line, pos)
        [nil, nil, pos]
      end

      private

      # Get compiled patterns (cached)
      # Uses \G anchor for efficient matching at specific position
      def compiled_patterns
        @compiled_patterns ||= token_patterns.map do |type, pattern|
          [type, /\G#{pattern}/]
        end
      end

      def match_token(line, pos)
        return nil if pos >= line.length

        compiled_patterns.each do |type, pattern|
          match = pattern.match(line, pos)
          next unless match

          text = match[0]
          return Token.new(
            type:,
            start_col: pos,
            end_col: pos + text.length - 1,
            text:
          )
        end
        nil
      end
    end
  end
end
