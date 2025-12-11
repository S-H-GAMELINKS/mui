# frozen_string_literal: true

require_relative "../error"

module Mui
  module KeyHandler
    class MethodNotOverriddenError < Mui::Error; end

    # Base class for mode-specific key handlers
    class Base
      attr_accessor :mode_manager

      def initialize(mode_manager, buffer)
        @mode_manager = mode_manager
        @buffer = buffer
      end

      def window
        @mode_manager&.active_window
      end

      def buffer
        window&.buffer || @buffer
      end

      # Handle a key input
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
        buffer.line(cursor_row)
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

      def key_to_char(key)
        key.is_a?(String) ? key : key.chr
      rescue RangeError
        nil
      end

      def execute_pending_motion(char)
        case @pending_motion
        when :g
          char == "g" ? Motion.file_start(buffer, cursor_row, cursor_col) : nil
        when :f
          Motion.find_char_forward(buffer, cursor_row, cursor_col, char)
        when :F
          Motion.find_char_backward(buffer, cursor_row, cursor_col, char)
        when :t
          Motion.till_char_forward(buffer, cursor_row, cursor_col, char)
        when :T
          Motion.till_char_backward(buffer, cursor_row, cursor_col, char)
        end
      end

      def result(mode: nil, message: nil, quit: false)
        HandlerResult::Base.new(mode:, message:, quit:)
      end
    end
  end
end
