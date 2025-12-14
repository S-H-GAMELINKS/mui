# frozen_string_literal: true

module Mui
  module Syntax
    module Lexers
      # Lexer for Rust source code
      class RustLexer < LexerBase
        # Rust keywords
        KEYWORDS = %w[
          as async await break const continue crate dyn else enum extern
          false fn for if impl in let loop match mod move mut pub ref
          return self Self static struct super trait true type unsafe use
          where while
        ].freeze

        # Rust primitive types
        TYPES = %w[
          bool char str
          i8 i16 i32 i64 i128 isize
          u8 u16 u32 u64 u128 usize
          f32 f64
        ].freeze

        # Pre-compiled patterns with \G anchor for position-specific matching
        COMPILED_PATTERNS = [
          # Doc comments (must be before regular comments)
          [:comment, %r{\G///.*}],
          [:comment, %r{\G//!.*}],
          # Single line comment
          [:comment, %r{\G//.*}],
          # Single-line block comment /* ... */ on one line
          [:comment, %r{\G/\*.*?\*/}],
          # Attributes
          [:preprocessor, /\G#!\[[^\]]*\]/],
          [:preprocessor, /\G#\[[^\]]*\]/],
          # Character literal - single char or escape sequence (must be before lifetime)
          [:char, /\G'(?:[^'\\]|\\.)'/],
          # Lifetime
          [:symbol, /\G'[a-z_][a-zA-Z0-9_]*/],
          # Raw string r#"..."#
          [:string, /\Gr#+"[^"]*"#+/],
          # Byte string
          [:string, /\Gb"(?:[^"\\]|\\.)*"/],
          # Regular string
          [:string, /\G"(?:[^"\\]|\\.)*"/],
          # Float numbers (must be before integer)
          [:number, /\G\b\d+\.\d+(?:e[+-]?\d+)?(?:f32|f64)?\b/i],
          # Hexadecimal
          [:number, /\G\b0x[0-9a-fA-F_]+(?:i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|usize)?\b/],
          # Octal
          [:number, /\G\b0o[0-7_]+(?:i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|usize)?\b/],
          # Binary
          [:number, /\G\b0b[01_]+(?:i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|usize)?\b/],
          # Integer
          [:number, /\G\b\d[0-9_]*(?:i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|usize)?\b/],
          # Macros (identifier followed by !)
          [:macro, /\G\b[a-z_][a-zA-Z0-9_]*!/],
          # Primitive types
          [:type, /\G\b(?:bool|char|str|i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|usize|f32|f64)\b/],
          # Keywords
          [:keyword, /\G\b(?:as|async|await|break|const|continue|crate|dyn|else|enum|extern|false|fn|for|if|impl|in|let|loop|match|mod|move|mut|pub|ref|return|self|Self|static|struct|super|trait|true|type|unsafe|use|where|while)\b/],
          # Type names (start with uppercase)
          [:constant, /\G\b[A-Z][a-zA-Z0-9_]*\b/],
          # Regular identifiers
          [:identifier, /\G\b[a-z_][a-zA-Z0-9_]*\b/],
          # Operators
          [:operator, %r{\G(?:&&|\|\||<<|>>|=>|->|::|\.\.=?|[+\-*/%&|^<>=!]=?|\?)}]
        ].freeze

        # Multiline comment patterns (pre-compiled)
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
