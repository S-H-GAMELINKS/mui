# frozen_string_literal: true

module Mui
  module Syntax
    module Lexers
      # Lexer for Markdown source files
      class MarkdownLexer < LexerBase
        # Pre-compiled patterns with \G anchor for position-specific matching
        # Markdown is line-oriented, so we check line-start patterns separately
        COMPILED_PATTERNS = [
          # Inline code (backtick)
          [:string, /\G`[^`]+`/],
          # Bold with asterisks
          [:keyword, /\G\*\*[^*]+\*\*/],
          # Bold with underscores
          [:keyword, /\G__[^_]+__/],
          # Italic with asterisks
          [:comment, /\G\*[^*]+\*/],
          # Italic with underscores
          [:comment, /\G_[^_]+_/],
          # Strikethrough
          [:comment, /\G~~[^~]+~~/],
          # Link [text](url)
          [:constant, /\G\[[^\]]+\]\([^)]+\)/],
          # Image ![alt](url)
          [:constant, /\G!\[[^\]]*\]\([^)]+\)/],
          # Reference link [text][ref]
          [:constant, /\G\[[^\]]+\]\[[^\]]*\]/],
          # Autolink <url> or <email>
          [:constant, /\G<[a-zA-Z][a-zA-Z0-9+.-]*:[^>]+>/],
          # HTML tags
          [:preprocessor, %r{\G</?[a-zA-Z][a-zA-Z0-9]*[^>]*>}]
        ].freeze

        # Line-start patterns (checked at beginning of line)
        HEADING_PATTERN = /\A(\#{1,6})\s+(.*)$/
        BLOCKQUOTE_PATTERN = /\A>\s*/
        UNORDERED_LIST_PATTERN = /\A\s*[-*+]\s+/
        ORDERED_LIST_PATTERN = /\A\s*\d+\.\s+/
        HORIZONTAL_RULE_PATTERN = /\A([-*_])\s*\1\s*\1[\s\1]*$/
        CODE_FENCE_START = /\A```(\w*)/
        CODE_FENCE_END = /\A```\s*$/
        LINK_DEFINITION_PATTERN = /\A\s*\[[^\]]+\]:\s+\S+/

        # Override tokenize to handle line-start patterns
        def tokenize(line, state = nil)
          tokens = []
          pos = 0

          # Handle code fence state
          if state == :code_fence
            if line.match?(CODE_FENCE_END)
              token = Token.new(
                type: :string,
                start_col: 0,
                end_col: line.length - 1,
                text: line
              )
              return [[token], nil]
            else
              unless line.empty?
                token = Token.new(
                  type: :string,
                  start_col: 0,
                  end_col: line.length - 1,
                  text: line
                )
              end
              return [token ? [token] : [], :code_fence]
            end
          end

          # Check for code fence start
          fence_match = line.match(CODE_FENCE_START)
          if fence_match
            token = Token.new(
              type: :string,
              start_col: 0,
              end_col: line.length - 1,
              text: line
            )
            return [[token], :code_fence]
          end

          # Check line-start patterns
          line_start_token = check_line_start(line)
          if line_start_token
            tokens << line_start_token
            pos = line_start_token.end_col + 1
          end

          # Process rest of line with inline patterns
          while pos < line.length
            # Skip whitespace
            if /\s/.match?(line[pos])
              pos += 1
              next
            end

            # Try to match a token
            token = match_token(line, pos)
            if token
              tokens << token
              pos = token.end_col + 1
            else
              pos += 1
            end
          end

          [tokens, nil]
        end

        protected

        def compiled_patterns
          COMPILED_PATTERNS
        end

        private

        def check_line_start(line)
          # Heading
          heading_match = line.match(HEADING_PATTERN)
          if heading_match
            level = heading_match[1].length
            return Token.new(
              type: :keyword,
              start_col: 0,
              end_col: level - 1,
              text: heading_match[1]
            )
          end

          # Horizontal rule
          if line.match?(HORIZONTAL_RULE_PATTERN)
            return Token.new(
              type: :comment,
              start_col: 0,
              end_col: line.length - 1,
              text: line
            )
          end

          # Link definition
          if line.match?(LINK_DEFINITION_PATTERN)
            return Token.new(
              type: :constant,
              start_col: 0,
              end_col: line.length - 1,
              text: line
            )
          end

          # Blockquote
          blockquote_match = line.match(BLOCKQUOTE_PATTERN)
          if blockquote_match
            return Token.new(
              type: :comment,
              start_col: 0,
              end_col: blockquote_match[0].length - 1,
              text: blockquote_match[0]
            )
          end

          # Unordered list
          list_match = line.match(UNORDERED_LIST_PATTERN)
          if list_match
            return Token.new(
              type: :operator,
              start_col: 0,
              end_col: list_match[0].length - 1,
              text: list_match[0]
            )
          end

          # Ordered list
          ordered_match = line.match(ORDERED_LIST_PATTERN)
          if ordered_match
            return Token.new(
              type: :number,
              start_col: 0,
              end_col: ordered_match[0].length - 1,
              text: ordered_match[0]
            )
          end

          nil
        end

        def match_token(line, pos)
          rest = line[pos..]

          COMPILED_PATTERNS.each do |type, pattern|
            match = rest.match(pattern)
            next unless match&.begin(0)&.zero?

            return Token.new(
              type:,
              start_col: pos,
              end_col: pos + match[0].length - 1,
              text: match[0]
            )
          end

          nil
        end
      end
    end
  end
end
