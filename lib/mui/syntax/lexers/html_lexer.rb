# frozen_string_literal: true

module Mui
  module Syntax
    module Lexers
      # Lexer for HTML source files
      class HtmlLexer < LexerBase
        # Pre-compiled patterns with \G anchor for position-specific matching
        COMPILED_PATTERNS = [
          # HTML comment (single line)
          [:comment, /\G<!--.*?-->/],
          # DOCTYPE declaration
          [:preprocessor, /\G<!DOCTYPE[^>]*>/i],
          # CDATA section
          [:string, /\G<!\[CDATA\[.*?\]\]>/],
          # Closing tag
          [:keyword, %r{\G</[a-zA-Z][a-zA-Z0-9-]*\s*>}],
          # Self-closing tag
          [:keyword, %r{\G<[a-zA-Z][a-zA-Z0-9-]*(?:\s+[^>]*)?/>}],
          # Opening tag with attributes
          [:keyword, /\G<[a-zA-Z][a-zA-Z0-9-]*(?=[\s>])/],
          # Tag closing bracket
          [:keyword, /\G>/],
          # Attribute name
          [:type, /\G[a-zA-Z][a-zA-Z0-9_-]*(?==)/],
          # Double quoted attribute value
          [:string, /\G"[^"]*"/],
          # Single quoted attribute value
          [:string, /\G'[^']*'/],
          # Unquoted attribute value (limited characters)
          [:string, /\G=[^\s>"']+/],
          # HTML entities
          [:constant, /\G&(?:#\d+|#x[0-9a-fA-F]+|[a-zA-Z]+);/],
          # Equal sign (for attributes)
          [:operator, /\G=/]
        ].freeze

        # Multiline comment patterns
        COMMENT_START = /<!--/
        COMMENT_END = /-->/
        COMMENT_START_ANCHOR = /\G<!--/

        protected

        def compiled_patterns
          COMPILED_PATTERNS
        end

        # Handle multiline HTML comments
        def handle_multiline_state(line, pos, state)
          return [nil, nil, pos] unless state == :html_comment

          end_match = line[pos..].match(COMMENT_END)
          if end_match
            end_pos = pos + end_match.begin(0) + 2 # --> is 3 chars
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
            [token, :html_comment, line.length]
          end
        end

        def check_multiline_start(line, pos)
          rest = line[pos..]

          # Check for <!-- that doesn't have --> on this line
          start_match = rest.match(COMMENT_START)
          return [nil, nil, pos] unless start_match

          start_pos = pos + start_match.begin(0)
          after_start = line[(start_pos + 4)..] # Skip <!--

          if after_start&.include?("-->")
            [nil, nil, pos]
          else
            text = line[start_pos..]
            token = Token.new(
              type: :comment,
              start_col: start_pos,
              end_col: line.length - 1,
              text:
            )
            [:html_comment, token, line.length]
          end
        end

        private

        def match_token(line, pos)
          # Check for start of multiline comment
          if line[pos..].match?(COMMENT_START_ANCHOR)
            rest = line[(pos + 4)..]
            return nil unless rest&.include?("-->")
          end

          super
        end
      end
    end
  end
end
