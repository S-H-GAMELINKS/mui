# frozen_string_literal: true

module Mui
  module Syntax
    module Lexers
      # Lexer for JavaScript source code
      class JavaScriptLexer < LexerBase
        # JavaScript keywords
        KEYWORDS = %w[
          async await break case catch class const continue debugger default
          delete do else export extends finally for function if import in
          instanceof let new return static switch throw try typeof var void
          while with yield
        ].freeze

        # JavaScript built-in types and values
        CONSTANTS = %w[true false null undefined NaN Infinity this super].freeze

        # Pre-compiled patterns with \G anchor for position-specific matching
        COMPILED_PATTERNS = [
          # Single line comment
          [:comment, %r{\G//.*}],
          # Single-line block comment /* ... */ on one line
          [:comment, %r{\G/\*.*?\*/}],
          # Template literal (single line)
          [:string, /\G`[^`]*`/],
          # Double quoted string (with escape handling)
          [:string, /\G"(?:[^"\\]|\\.)*"/],
          # Single quoted string (with escape handling)
          [:string, /\G'(?:[^'\\]|\\.)*'/],
          # Regular expression literal
          [:regex, %r{\G/(?:[^/\\]|\\.)+/[gimsuy]*}],
          # Float numbers (must be before integer)
          [:number, /\G\b\d+\.\d+(?:e[+-]?\d+)?\b/i],
          # Hexadecimal
          [:number, /\G\b0x[0-9a-fA-F]+n?\b/i],
          # Octal
          [:number, /\G\b0o[0-7]+n?\b/i],
          # Binary
          [:number, /\G\b0b[01]+n?\b/i],
          # Integer (with optional BigInt suffix)
          [:number, /\G\b\d+n?\b/],
          # Constants (true, false, null, undefined, NaN, Infinity, this, super)
          [:constant, /\G\b(?:true|false|null|undefined|NaN|Infinity|this|super)\b/],
          # Keywords
          [:keyword, /\G\b(?:async|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|export|extends|finally|for|function|if|import|in|instanceof|let|new|return|static|switch|throw|try|typeof|var|void|while|with|yield)\b/],
          # Class/constructor names (start with uppercase)
          [:constant, /\G\b[A-Z][a-zA-Z0-9_]*\b/],
          # Regular identifiers
          [:identifier, /\G\b[a-zA-Z_$][a-zA-Z0-9_$]*\b/],
          # Operators (=>must come before = patterns)
          [:operator, %r{\G(?:\.{3}|=>|&&=?|\|\|=?|\?\?=?|===?|!==?|>>>?=?|<<=?|\+\+|--|\?\.?|[+\-*/%&|^<>=!]=?)}]
        ].freeze

        # Multiline patterns (pre-compiled)
        BLOCK_COMMENT_END = %r{\*/}
        BLOCK_COMMENT_START = %r{/\*}
        BLOCK_COMMENT_START_ANCHOR = %r{\A/\*}

        # Template literal patterns
        TEMPLATE_LITERAL_START = /\A`/
        TEMPLATE_LITERAL_END = /`/

        protected

        def compiled_patterns
          COMPILED_PATTERNS
        end

        # Handle multiline constructs
        def handle_multiline_state(line, pos, state)
          case state
          when :block_comment
            handle_block_comment(line, pos)
          when :template_literal
            handle_template_literal(line, pos)
          else
            [nil, nil, pos]
          end
        end

        def check_multiline_start(line, pos)
          rest = line[pos..]

          # Check for template literal start
          if rest.match?(TEMPLATE_LITERAL_START)
            after_start = line[(pos + 1)..]
            unless after_start&.include?("`")
              text = line[pos..]
              token = Token.new(
                type: :string,
                start_col: pos,
                end_col: line.length - 1,
                text:
              )
              return [:template_literal, token, line.length]
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

        def handle_template_literal(line, pos)
          end_match = line[pos..].match(TEMPLATE_LITERAL_END)
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
            [token, :template_literal, line.length]
          end
        end

        def match_token(line, pos)
          # Check for start of template literal
          if line[pos..].match?(TEMPLATE_LITERAL_START)
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
