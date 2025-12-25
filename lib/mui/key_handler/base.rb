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

      def editor
        @mode_manager&.editor
      end

      # Returns the current buffer's undo_manager for dynamic access
      # This ensures undo/redo works correctly when buffer changes (e.g., via :e)
      def undo_manager
        buffer&.undo_manager
      end

      # Access to key sequence handler for multi-key mappings
      def key_sequence_handler
        @mode_manager&.key_sequence_handler
      end

      # Handle a key input
      def handle(_key)
        raise MethodNotOverriddenError, "Subclasses must orverride #handle"
      end

      # Check plugin keymap with multi-key sequence support
      # @param key [Integer, String] Raw key input
      # @param mode_symbol [Symbol] Mode symbol (:normal, :insert, :visual, :command)
      # @return [HandlerResult, nil] Result if handled or pending, nil to continue with built-in
      def check_plugin_keymap(key, mode_symbol)
        return nil unless key_sequence_handler

        type, data = key_sequence_handler.process(key, mode_symbol)

        case type
        when KeySequenceHandler::RESULT_HANDLED
          execute_plugin_handler(data, mode_symbol)
        when KeySequenceHandler::RESULT_PENDING
          # Return a result that tells the handler to wait
          # Use base class directly since subclasses may not support pending_sequence
          HandlerResult::Base.new(pending_sequence: true)
        when KeySequenceHandler::RESULT_PASSTHROUGH
          # Check for single-key keymap (backward compatibility)
          check_single_key_keymap(data, mode_symbol)
        end
      end

      private

      # Check single-key keymap for backward compatibility
      def check_single_key_keymap(key, mode_symbol)
        key_str = convert_key_to_string(key)
        return nil unless key_str

        plugin_handler = Mui.config.keymaps[mode_symbol]&.[](key_str)
        return nil unless plugin_handler

        execute_plugin_handler(plugin_handler, mode_symbol)
      end

      # Execute a plugin handler and wrap result
      def execute_plugin_handler(handler, mode_symbol)
        return nil unless @mode_manager&.editor

        context = CommandContext.new(
          editor: @mode_manager.editor,
          buffer:,
          window:
        )
        handler_result = handler.call(context)

        return nil unless handler_result

        wrap_handler_result(handler_result, mode_symbol)
      end

      # Wrap handler result in appropriate type
      def wrap_handler_result(handler_result, _mode_symbol)
        return handler_result if handler_result.is_a?(HandlerResult::Base)

        result
      end

      # Convert key to string for keymap lookup
      def convert_key_to_string(key)
        return key if key.is_a?(String)

        case key
        when KeyCode::ENTER_CR, KeyCode::ENTER_LF
          "\r"
        when KeyCode::ESCAPE
          "\e"
        when KeyCode::TAB
          "\t"
        when KeyCode::SHIFT_TAB
          "\T"
        when KeyCode::BACKSPACE
          "\x7f"
        else
          key.chr
        end
      rescue RangeError
        nil
      end

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
