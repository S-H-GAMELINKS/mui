# frozen_string_literal: true

module Mui
  module Highlighters
    # Provides syntax highlighting based on language-specific lexers
    class SyntaxHighlighter < Base
      # Maps token types to ColorScheme style names
      # Note: identifier and operator are excluded to reduce highlight count
      # (they typically use the same color as normal text)
      TOKEN_STYLE_MAP = {
        keyword: :syntax_keyword,
        string: :syntax_string,
        comment: :syntax_comment,
        number: :syntax_number,
        symbol: :syntax_symbol,
        constant: :syntax_constant,
        preprocessor: :syntax_preprocessor,
        char: :syntax_string,
        instance_variable: :syntax_instance_variable,
        global_variable: :syntax_global_variable,
        method_call: :syntax_method_call,
        type: :syntax_type
      }.freeze

      def initialize(color_scheme, buffer: nil)
        super(color_scheme)
        @buffer = buffer
        setup_lexer
      end

      # Update the buffer and reset the lexer
      def buffer=(new_buffer)
        @buffer = new_buffer
        setup_lexer
      end

      # Generate highlights for a line
      # @param row [Integer] the line number
      # @param line [String] the line content
      # @param options [Hash] additional options (may include :buffer)
      # @return [Array<Highlight>] highlights for this line
      # TODO: Refactor to reduce complexity (Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity)
      def highlights_for(row, line, options = {})
        return [] unless @lexer
        return [] unless Mui.config.get(:syntax)

        buffer_lines = options[:buffer]&.lines || @buffer&.lines || []
        tokens = @token_cache.tokens_for(row, line, buffer_lines)

        tokens.filter_map do |token|
          style = style_for_token_type(token.type)
          next unless style && @color_scheme[style]

          Highlight.new(
            start_col: token.start_col,
            end_col: token.end_col,
            style:,
            priority:
          )
        end
      end

      def priority
        PRIORITY_SYNTAX
      end

      # Invalidate cache from a specific row onwards
      # Called when buffer content changes
      def invalidate_from(row)
        @token_cache&.invalidate(row)
      end

      # Clear the entire cache
      def clear_cache
        @token_cache&.clear
      end

      # Prefetch tokens for lines around the visible area
      # @param visible_start [Integer] first visible row
      # @param visible_end [Integer] last visible row
      def prefetch(visible_start, visible_end)
        return unless @lexer && @token_cache && @buffer
        return unless Mui.config.get(:syntax)

        @token_cache.prefetch(visible_start, visible_end, @buffer.lines)
      end

      # Check if this highlighter is active (has a lexer)
      def active?
        !@lexer.nil?
      end

      private

      def setup_lexer
        @lexer = nil
        @token_cache = nil
        return unless @buffer

        @lexer = Syntax::LanguageDetector.lexer_for_file(@buffer.name)
        return unless @lexer

        @token_cache = Syntax::TokenCache.new(@lexer)
      end

      def style_for_token_type(type)
        TOKEN_STYLE_MAP[type]
      end
    end
  end
end
