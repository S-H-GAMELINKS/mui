# frozen_string_literal: true

module Mui
  module Syntax
    module Lexers
      # Lexer for Go source code
      class GoLexer < LexerBase
        # Go keywords
        KEYWORDS = %w[
          break case chan const continue default defer else fallthrough
          for func go goto if import interface map package range return
          select struct switch type var
        ].freeze

        # Go built-in types
        TYPES = %w[
          bool byte complex64 complex128 error float32 float64
          int int8 int16 int32 int64 rune string
          uint uint8 uint16 uint32 uint64 uintptr
          any comparable
        ].freeze

        # Go constants
        CONSTANTS = %w[true false nil iota].freeze

        # Pre-compiled patterns with \G anchor for position-specific matching
        COMPILED_PATTERNS = [
          # Single line comment
          [:comment, %r{\G//.*}],
          # Single-line block comment /* ... */ on one line
          [:comment, %r{\G/\*.*?\*/}],
          # Raw string literal (backtick)
          [:string, /\G`[^`]*`/],
          # Double quoted string (with escape handling)
          [:string, /\G"(?:[^"\\]|\\.)*"/],
          # Character literal (rune)
          [:char, /\G'(?:[^'\\]|\\.)*'/],
          # Float numbers (must be before integer)
          [:number, /\G\b\d+\.\d+(?:e[+-]?\d+)?\b/i],
          # Hexadecimal
          [:number, /\G\b0x[0-9a-fA-F]+\b/i],
          # Octal
          [:number, /\G\b0o[0-7]+\b/i],
          # Binary
          [:number, /\G\b0b[01]+\b/i],
          # Integer
          [:number, /\G\b\d+\b/],
          # Constants (true, false, nil, iota)
          [:constant, /\G\b(?:true|false|nil|iota)\b/],
          # Types
          [:type, /\G\b(?:bool|byte|complex64|complex128|error|float32|float64|int|int8|int16|int32|int64|rune|string|uint|uint8|uint16|uint32|uint64|uintptr|any|comparable)\b/],
          # Keywords
          [:keyword, /\G\b(?:break|case|chan|const|continue|default|defer|else|fallthrough|for|func|go|goto|if|import|interface|map|package|range|return|select|struct|switch|type|var)\b/],
          # Exported identifiers (start with uppercase)
          [:constant, /\G\b[A-Z][a-zA-Z0-9_]*\b/],
          # Regular identifiers
          [:identifier, /\G\b[a-z_][a-zA-Z0-9_]*\b/],
          # Operators
          [:operator, %r{\G(?:&&|\|\||<-|<<=?|>>=?|&\^=?|[+\-*/%&|^<>=!]=?|:=|\+\+|--)}]
        ].freeze

        # Multiline comment patterns (pre-compiled)
        BLOCK_COMMENT_END = %r{\*/}
        BLOCK_COMMENT_START = %r{/\*}
        BLOCK_COMMENT_START_ANCHOR = %r{\A/\*}

        # Raw string patterns (pre-compiled)
        RAW_STRING_START = /\A`/
        RAW_STRING_END = /`/

        protected

        def compiled_patterns
          COMPILED_PATTERNS
        end

        # Handle /* ... */ block comments and raw strings that span multiple lines
        def handle_multiline_state(line, pos, state)
          case state
          when :block_comment
            handle_block_comment(line, pos)
          when :raw_string
            handle_raw_string(line, pos)
          else
            [nil, nil, pos]
          end
        end

        def check_multiline_start(line, pos)
          rest = line[pos..]

          # Check for raw string start
          if rest.match?(RAW_STRING_START)
            after_start = line[(pos + 1)..]
            unless after_start&.include?("`")
              # No closing on this line, enter raw string state
              text = line[pos..]
              token = Token.new(
                type: :string,
                start_col: pos,
                end_col: line.length - 1,
                text:
              )
              return [:raw_string, token, line.length]
            end
          end

          # Check for /* that doesn't have a matching */ on this line
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

        def handle_block_comment(line, pos)
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

        def handle_raw_string(line, pos)
          end_match = line[pos..].match(RAW_STRING_END)
          if end_match
            end_pos = pos + end_match.begin(0)
            text = line[pos..end_pos]
            token = Token.new(
              type: :string,
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
                        type: :string,
                        start_col: pos,
                        end_col: line.length - 1,
                        text:
                      )
                    end
            [token, :raw_string, line.length]
          end
        end

        def match_token(line, pos)
          # Check for start of raw string
          if line[pos..].match?(RAW_STRING_START)
            rest = line[(pos + 1)..]
            return nil unless rest&.include?("`")
          end

          # Check for start of multiline comment
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
