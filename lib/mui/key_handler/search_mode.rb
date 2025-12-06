# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handles key inputs in Search mode (/ and ?)
    class SearchMode < Base
      def initialize(mode_manager, buffer, search_input, search_state)
        super(mode_manager, buffer)
        @search_input = search_input
        @search_state = search_state
      end

      def handle(key)
        case key
        when KeyCode::ESCAPE
          handle_escape
        when KeyCode::BACKSPACE, Curses::KEY_BACKSPACE
          handle_backspace
        when KeyCode::ENTER_CR, KeyCode::ENTER_LF, Curses::KEY_ENTER
          handle_enter
        else
          handle_character_input(key)
        end
      end

      private

      def handle_escape
        @search_input.clear
        result(mode: Mode::NORMAL, cancelled: true)
      end

      def handle_backspace
        if @search_input.empty?
          result(mode: Mode::NORMAL, cancelled: true)
        else
          @search_input.backspace
          result
        end
      end

      def handle_enter
        execute_search
      end

      def handle_character_input(key)
        char = extract_printable_char(key)
        @search_input.input(char) if char
        result
      end

      def execute_search
        pattern = @search_input.pattern
        return result(mode: Mode::NORMAL, cancelled: true) if pattern.empty?

        direction = @search_input.prompt == "/" ? :forward : :backward
        @search_state.set_pattern(pattern, direction)
        @search_state.find_all_matches(@buffer)

        match = if direction == :forward
                  @search_state.find_next(cursor_row, cursor_col)
                else
                  @search_state.find_previous(cursor_row, cursor_col)
                end

        if match
          window.cursor_row = match[:row]
          window.cursor_col = match[:col]
          result(mode: Mode::NORMAL)
        else
          result(mode: Mode::NORMAL, message: "Pattern not found: #{pattern}")
        end
      end

      def result(mode: nil, message: nil, quit: false, cancelled: false)
        HandlerResult::SearchModeResult.new(mode:, message:, quit:, cancelled:)
      end
    end
  end
end
