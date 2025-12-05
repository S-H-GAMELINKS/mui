# frozen_string_literal: true

require_relative "../error"

module Mui
  module KeyHandler
    class MethodNotOverriddenError < Mui::Error; end

    # Base class for mode-specific key handlers
    class Base
      attr_reader :window, :buffer
      attr_accessor :mode_manager

      def initialize(window, buffer)
        @window = window
        @buffer = buffer
        @mode_manager = nil
      end

      # Handle a key input
      # @param key [String, Integer] the key input
      # @return [Hash] result with :mode (next mode) and optional :message
      def handle(_key)
        raise MethodNotOverriddenError, "Subclasses must orverride #handle"
      end

      private

      def cursor_row
        @window.cursor_row
      end

      def cursor_col
        @window.cursor_col
      end

      def cursor_row=(value)
        @window.cursor_row = value
      end

      def cursor_col=(value)
        @window.cursor_col = value
      end

      def current_line
        @buffer.line(cursor_row)
      end

      def current_line_length
        current_line.length
      end

      def result(mode: nil, message: nil, quit: false)
        HandlerResult::Base.new(mode: mode, message: message, quit: quit)
      end
    end
  end
end
