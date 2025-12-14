# frozen_string_literal: true

module Mui
  module Syntax
    module Lexers
      # Lexer for CSS source files
      class CssLexer < LexerBase
        # Pre-compiled patterns with \G anchor for position-specific matching
        COMPILED_PATTERNS = [
          # Single-line block comment /* ... */ on one line
          [:comment, %r{\G/\*.*?\*/}],
          # @rules (at-rules)
          [:preprocessor, /\G@[a-zA-Z-]+/],
          # Hex color (must be before ID selector - matches 3-8 hex digits only)
          [:number, /\G#[0-9a-fA-F]{3,8}(?![a-zA-Z0-9_-])/],
          # ID selector (starts with letter or underscore/hyphen after #)
          [:constant, /\G#[a-zA-Z_-][a-zA-Z0-9_-]*/],
          # Class selector
          [:type, /\G\.[a-zA-Z_-][a-zA-Z0-9_-]*/],
          # Pseudo-elements and pseudo-classes
          [:keyword, /\G::?[a-zA-Z-]+(?:\([^)]*\))?/],
          # Property name (followed by colon)
          [:identifier, /\G[a-zA-Z-]+(?=\s*:)/],
          # Double quoted string
          [:string, /\G"(?:[^"\\]|\\.)*"/],
          # Single quoted string
          [:string, /\G'(?:[^'\\]|\\.)*'/],
          # URL function
          [:string, /\Gurl\([^)]*\)/i],
          # Numbers with units
          [:number, /\G-?\d+\.?\d*(?:px|em|rem|%|vh|vw|vmin|vmax|ch|ex|cm|mm|in|pt|pc|deg|rad|grad|turn|s|ms|Hz|kHz|dpi|dpcm|dppx|fr)?/i],
          # Functions (calc, rgb, rgba, hsl, var, etc.)
          [:keyword, /\G[a-zA-Z-]+(?=\()/],
          # Property values / keywords (important, inherit, etc.)
          [:constant, /\G!important\b/i],
          [:constant, /\G\b(?:inherit|initial|unset|revert|none|auto|normal)\b/],
          # Element selectors and identifiers
          [:identifier, /\G[a-zA-Z_-][a-zA-Z0-9_-]*/],
          # Operators and symbols
          [:operator, /\G[{}():;,>+~*=\[\]]/]
        ].freeze

        # Multiline comment patterns
        BLOCK_COMMENT_END = %r{\*/}
        BLOCK_COMMENT_START = %r{/\*}
        BLOCK_COMMENT_START_ANCHOR = %r{\A/\*}

        protected

        def compiled_patterns
          COMPILED_PATTERNS
        end

        # Handle /* ... */ block comments that span multiple lines
        def handle_multiline_state(line, pos, state)
          return [nil, nil, pos] unless state == :block_comment

          end_match = line[pos..].match(BLOCK_COMMENT_END)
          if end_match
            end_pos = pos + end_match.begin(0) + 1
            text = line[pos..end_pos]
            token = Token.new(
              type: :comment,
              start_col: pos,
              end_col: end_pos,
              text:
            )
            [token, nil, end_pos + 1]
          else
            text = line[pos..]
            token = if text.empty?
                      nil
                    else
                      Token.new(
                        type: :comment,
                        start_col: pos,
                        end_col: line.length - 1,
                        text:
                      )
                    end
            [token, :block_comment, line.length]
          end
        end

        def check_multiline_start(line, pos)
          rest = line[pos..]

          start_match = rest.match(BLOCK_COMMENT_START)
          return [nil, nil, pos] unless start_match

          start_pos = pos + start_match.begin(0)
          after_start = line[(start_pos + 2)..]

          if after_start&.include?("*/")
            [nil, nil, pos]
          else
            text = line[start_pos..]
            token = Token.new(
              type: :comment,
              start_col: start_pos,
              end_col: line.length - 1,
              text:
            )
            [:block_comment, token, line.length]
          end
        end

        private

        def match_token(line, pos)
          if line[pos..].match?(BLOCK_COMMENT_START_ANCHOR)
            rest = line[(pos + 2)..]
            return nil unless rest&.include?("*/")
          end

          super
        end
      end
    end
  end
end
