# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handles key inputs in Search mode (/ and ?)
    class SearchMode < Base
      attr_reader :completion_state

      def initialize(mode_manager, buffer, search_input, search_state)
        super(mode_manager, buffer)
        @search_input = search_input
        @search_state = search_state
        @original_cursor_row = nil
        @original_cursor_col = nil
        @completion_state = CompletionState.new
        @search_completer = SearchCompleter.new
      end

      def start_search
        @original_cursor_row = cursor_row
        @original_cursor_col = cursor_col
        @completion_state.reset
      end

      def handle(key)
        # Check plugin keymaps first
        plugin_result = check_plugin_keymap(key, :search)
        return plugin_result if plugin_result

        case key
        when KeyCode::ESCAPE
          handle_escape
        when KeyCode::BACKSPACE, Curses::KEY_BACKSPACE
          handle_backspace
        when KeyCode::ENTER_CR, KeyCode::ENTER_LF, Curses::KEY_ENTER
          handle_enter
        when KeyCode::TAB
          handle_tab
        when Curses::KEY_BTAB
          handle_shift_tab
        else
          handle_character_input(key)
        end
      end

      private

      def handle_tab
        return result unless @completion_state.active?

        @completion_state.select_next
        apply_current_completion
        result
      end

      def handle_shift_tab
        return result unless @completion_state.active?

        @completion_state.select_previous
        apply_current_completion
        result
      end

      def apply_current_completion
        candidate = @completion_state.current_candidate
        return unless candidate

        @search_input.clear
        candidate.each_char { |c| @search_input.input(c) }
        update_incremental_search
      end

      def handle_escape
        @search_input.clear
        @search_state.clear
        @completion_state.reset
        # Restore original cursor position
        restore_cursor_position
        result(mode: Mode::NORMAL, cancelled: true)
      end

      def restore_cursor_position
        return unless @original_cursor_row && @original_cursor_col

        window.cursor_row = @original_cursor_row
        window.cursor_col = @original_cursor_col
      end

      def handle_backspace
        if @search_input.empty?
          @search_state.clear
          @completion_state.reset
          restore_cursor_position
          result(mode: Mode::NORMAL, cancelled: true)
        else
          @search_input.backspace
          update_incremental_search
          update_completion
          result
        end
      end

      def handle_enter
        @completion_state.reset
        execute_search
      end

      def handle_character_input(key)
        char = extract_printable_char(key)
        if char
          @search_input.input(char)
          update_incremental_search
          update_completion
        end
        result
      end

      def update_completion
        prefix = @search_input.pattern
        if prefix.empty?
          @completion_state.reset
          return
        end

        candidates = @search_completer.complete(buffer, prefix)
        if candidates.empty?
          @completion_state.reset
        else
          @completion_state.start(candidates, prefix, :search)
        end
      end

      def update_incremental_search
        pattern = @search_input.pattern
        if pattern.empty?
          @search_state.clear
          restore_cursor_position
          return
        end

        direction = @search_input.prompt == "/" ? :forward : :backward
        @search_state.set_pattern(pattern, direction)

        # Move cursor to first match from original position
        matches = @search_state.find_all_matches(buffer)
        return if matches.empty?

        # Use original position if set, otherwise use current cursor position
        search_row = @original_cursor_row || cursor_row
        search_col = @original_cursor_col || cursor_col

        match = if direction == :forward
                  @search_state.find_next(search_row, search_col, buffer:)
                else
                  @search_state.find_previous(search_row, search_col, buffer:)
                end

        return unless match

        window.cursor_row = match[:row]
        window.cursor_col = match[:col]
      end

      def execute_search
        pattern = @search_input.pattern
        return result(mode: Mode::NORMAL, cancelled: true) if pattern.empty?

        direction = @search_input.prompt == "/" ? :forward : :backward
        @search_state.set_pattern(pattern, direction)

        match = if direction == :forward
                  @search_state.find_next(cursor_row, cursor_col, buffer:)
                else
                  @search_state.find_previous(cursor_row, cursor_col, buffer:)
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
