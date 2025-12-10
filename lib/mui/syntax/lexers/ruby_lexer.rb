# frozen_string_literal: true

module Mui
  module Syntax
    module Lexers
      # Lexer for Ruby source code
      class RubyLexer < LexerBase
        KEYWORDS = %w[
          BEGIN END __ENCODING__ __END__ __FILE__ __LINE__
          alias and begin break case class def defined? do
          else elsif end ensure false for if in module next
          nil not or redo rescue retry return self super then
          true undef unless until when while yield
          require require_relative attr_reader attr_writer attr_accessor
          private protected public include extend prepend
          raise fail catch throw
        ].freeze

        # Pre-compiled patterns with \G anchor for position-specific matching
        # These are compiled once at class load time
        COMPILED_PATTERNS = [
          # Single line comment
          [:comment, /\G#.*/],
          # Double quoted string (with escape handling)
          [:string, /\G"(?:[^"\\]|\\.)*"/],
          # Single quoted string (with escape handling)
          [:string, /\G'(?:[^'\\]|\\.)*'/],
          # Symbols
          [:symbol, /\G:[a-zA-Z_][a-zA-Z0-9_]*[?!]?/],
          # Float numbers (must be before integer)
          [:number, /\G\b\d+\.\d+(?:e[+-]?\d+)?\b/i],
          # Hexadecimal
          [:number, /\G\b0x[0-9a-f]+\b/i],
          # Octal
          [:number, /\G\b0o?[0-7]+\b/],
          # Binary
          [:number, /\G\b0b[01]+\b/i],
          # Integer
          [:number, /\G\b\d+\b/],
          # Constants (capitalized identifiers)
          [:constant, /\G\b[A-Z][a-zA-Z0-9_]*\b/],
          # Keywords
          [:keyword, /\G\b(?:BEGIN|END|__ENCODING__|__END__|__FILE__|__LINE__|alias|and|begin|break|case|class|def|defined\?|do|else|elsif|end|ensure|false|for|if|in|module|next|nil|not|or|redo|rescue|retry|return|self|super|then|true|undef|unless|until|when|while|yield|require|require_relative|attr_reader|attr_writer|attr_accessor|private|protected|public|include|extend|prepend|raise|fail|catch|throw)\b/],
          # Instance variables (@foo, @@foo)
          [:instance_variable, /\G@{1,2}[a-zA-Z_][a-zA-Z0-9_]*/],
          # Global variables
          [:global_variable, /\G\$[a-zA-Z_][a-zA-Z0-9_]*/],
          # Method calls (.to_i, .each, .map!, .empty?, etc.)
          [:method_call, /\G\.[a-z_][a-zA-Z0-9_]*[?!]?/],
          # Identifiers (including method names with ? or !)
          [:identifier, /\G\b[a-z_][a-zA-Z0-9_]*[?!]?/],
          # Operators
          [:operator, %r{\G(?:[+\-*/%&|^~<>=!]+|<<|>>|\*\*)}]
        ].freeze

        # Multiline patterns (also pre-compiled)
        BLOCK_COMMENT_END = /\A=end\b/
        BLOCK_COMMENT_START = /\A=begin\b/

        protected

        # Use pre-compiled class-level patterns
        def compiled_patterns
          COMPILED_PATTERNS
        end

        # Handle =begin...=end block comments
        def handle_multiline_state(line, pos, state)
          return [nil, nil, pos] unless state == :block_comment

          # Check for =end
          text = line[pos..]
          if BLOCK_COMMENT_END.match?(text)
            token = Token.new(
              type: :comment,
              start_col: pos,
              end_col: line.length - 1,
              text:
            )
            [token, nil, line.length]
          else
            # Entire line is part of block comment
            unless text.empty?
              token = Token.new(
                type: :comment,
                start_col: pos,
                end_col: line.length - 1,
                text:
              )
            end
            [token, :block_comment, line.length]
          end
        end

        # Check for =begin block comment start
        def check_multiline_start(line, pos)
          return [nil, nil, pos] unless pos.zero?

          if BLOCK_COMMENT_START.match?(line)
            token = Token.new(
              type: :comment,
              start_col: 0,
              end_col: line.length - 1,
              text: line
            )
            [:block_comment, token, line.length]
          else
            [nil, nil, pos]
          end
        end
      end
    end
  end
end
