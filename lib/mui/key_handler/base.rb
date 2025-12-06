# frozen_string_literal: true

require_relative "../error"

module Mui
  module KeyHandler
    class MethodNotOverriddenError < Mui::Error; end

    # Base class for mode-specific key handlers
    class Base
      attr_reader :buffer
      attr_accessor :mode_manager

      def initialize(mode_manager, buffer)
        @mode_manager = mode_manager
        @buffer = buffer
      end

      def window
        @mode_manager&.active_window
      end

      # Handle a key input
      # @param key [String, Integer] the key input
      # @return [Hash] result with :mode (next mode) and optional :message
      def handle(_key)
        raise MethodNotOverriddenError, "Subclasses must orverride #handle"
      end

      private

      def cursor_row
        window.cursor_row
      end

      def cursor_col
        window.cursor_col
      end

      def cursor_row=(value)
        window.cursor_row = value
      end

      def cursor_col=(value)
        window.cursor_col = value
      end

      def current_line
        @buffer.line(cursor_row)
      end

      def current_line_length
        current_line.length
      end

      def extract_printable_char(key)
        if key.is_a?(String)
          # Curses returns multibyte characters as String
          key
        elsif key.is_a?(Integer) && key >= KeyCode::PRINTABLE_MIN && key <= KeyCode::PRINTABLE_MAX
          # Use UTF-8 encoding to support Unicode characters
          key.chr(Encoding::UTF_8)
        end
      rescue RangeError
        # Invalid Unicode code point
        nil
      end

      def result(mode: nil, message: nil, quit: false)
        HandlerResult::Base.new(mode:, message:, quit:)
      end
    end
  end
end
