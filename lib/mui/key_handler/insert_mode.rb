# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handles key inputs in Insert mode
    class InsertMode < Base
      def initialize(mode_manager, buffer, undo_manager: nil, group_started: false)
        super(mode_manager, buffer)
        @undo_manager = undo_manager
        # Start undo group unless already started (e.g., by change operator)
        @undo_manager&.begin_group unless group_started
        # Build word cache for fast completion (use active window's buffer)
        @word_cache = BufferWordCache.new(self.buffer)
      end

      def handle(key)
        # Check plugin keymaps first
        plugin_result = check_plugin_keymap(key, :insert)
        return plugin_result if plugin_result

        case key
        when KeyCode::ESCAPE
          handle_escape
        when Curses::KEY_LEFT
          handle_move_left
        when Curses::KEY_RIGHT
          handle_move_right
        when Curses::KEY_UP
          completion_active? ? handle_completion_previous : handle_move_up
        when Curses::KEY_DOWN
          completion_active? ? handle_completion_next : handle_move_down
        when KeyCode::CTRL_P
          completion_active? ? handle_completion_previous : handle_buffer_completion
        when KeyCode::CTRL_N
          completion_active? ? handle_completion_next : handle_buffer_completion
        when KeyCode::TAB
          completion_active? ? handle_completion_confirm : handle_tab
        when KeyCode::BACKSPACE, Curses::KEY_BACKSPACE
          handle_backspace
        when KeyCode::ENTER_CR, KeyCode::ENTER_LF, Curses::KEY_ENTER
          handle_enter
        else
          handle_character_input(key)
        end
      end

      def check_plugin_keymap(key, mode_symbol)
        return nil unless @mode_manager&.editor

        key_str = convert_key_to_string(key)
        return nil unless key_str

        plugin_handler = Mui.config.keymaps[mode_symbol]&.[](key_str)
        return nil unless plugin_handler

        context = CommandContext.new(
          editor: @mode_manager.editor,
          buffer:,
          window:
        )
        handler_result = plugin_handler.call(context)

        # If handler returns nil/false, let built-in handle it
        return nil unless handler_result

        # Return a valid result to indicate the key was handled
        handler_result.is_a?(HandlerResult::InsertModeResult) ? handler_result : result
      end

      def convert_key_to_string(key)
        return key if key.is_a?(String)

        # Handle special Curses keys
        case key
        when KeyCode::ENTER_CR, KeyCode::ENTER_LF, Curses::KEY_ENTER
          "\r"
        else
          key.chr
        end
      rescue RangeError
        # Key code out of char range (e.g., special function keys)
        nil
      end

      private

      def handle_escape
        # Cancel completion if active
        editor.insert_completion_state.reset if completion_active?

        @undo_manager&.end_group
        # Remove trailing whitespace from current line if it's whitespace-only (Vim behavior)
        stripped = strip_trailing_whitespace_if_empty_line
        # Move cursor back one position unless we just stripped whitespace (cursor already at 0)
        self.cursor_col = cursor_col - 1 if cursor_col.positive? && !stripped
        result(mode: Mode::NORMAL)
      end

      def strip_trailing_whitespace_if_empty_line
        line = buffer.line(cursor_row)
        return false unless line.match?(/\A[ \t]+\z/)

        # Line contains only whitespace, clear it
        line.length.times { buffer.delete_char(cursor_row, 0) }
        self.cursor_col = 0
        true
      end

      def handle_move_left
        reset_insert_completion_state
        self.cursor_col = cursor_col - 1 if cursor_col.positive?
        result
      end

      def handle_move_right
        reset_insert_completion_state
        self.cursor_col = cursor_col + 1 if cursor_col < current_line_length
        result
      end

      def handle_move_up
        window.move_up
        result
      end

      def handle_move_down
        window.move_down
        result
      end

      def handle_backspace
        if cursor_col.positive?
          self.cursor_col = cursor_col - 1
          buffer.delete_char(cursor_row, cursor_col)
          # Update completion list after backspace
          update_completion_list if completion_active?
        elsif cursor_row.positive?
          join_with_previous_line
          reset_insert_completion_state
        end
        result
      end

      def join_with_previous_line
        prev_line_len = buffer.line(cursor_row - 1).length
        buffer.join_lines(cursor_row - 1)
        self.cursor_row = cursor_row - 1
        self.cursor_col = prev_line_len
      end

      def handle_enter
        # Get indent from current line before splitting
        current_line = buffer.line(cursor_row)
        indent = extract_indent(current_line)

        buffer.split_line(cursor_row, cursor_col)
        self.cursor_row = cursor_row + 1

        # Insert indent at the beginning of the new line
        if indent && !indent.empty?
          indent.each_char.with_index do |char, i|
            buffer.insert_char(cursor_row, i, char)
          end
          self.cursor_col = indent.length
        else
          self.cursor_col = 0
        end
        result
      end

      def extract_indent(line)
        match = line.match(/\A([ \t]*)/)
        match ? match[1] : ""
      end

      def handle_character_input(key)
        char = extract_printable_char(key)
        if char
          buffer.insert_char(cursor_row, cursor_col, char)
          self.cursor_col = cursor_col + 1

          # Update completion list if active
          if completion_active? && word_char?(char)
            update_completion_list
          elsif completion_active?
            # Non-word character typed, close completion and add completed word to cache
            add_current_word_to_cache
            editor.insert_completion_state.reset
            trigger_completion_for(char)
          else
            # Non-word char means previous word is complete, add to cache
            add_current_word_to_cache unless word_char?(char)
            # Trigger completion for certain characters
            trigger_completion_for(char)
          end
        end
        result
      end

      def add_current_word_to_cache
        # Get the word that just ended (before current cursor)
        line = buffer.line(cursor_row)
        return if cursor_col < 2

        # Find the word that just ended
        end_col = cursor_col - 1
        start_col = end_col
        start_col -= 1 while start_col.positive? && word_char?(line[start_col - 1])

        word = line[start_col...end_col]
        @word_cache.add_word(word) if word && word.length >= BufferWordCache::MIN_WORD_LENGTH
      end

      def update_completion_list
        return unless editor

        new_prefix = @word_cache.prefix_at(cursor_row, cursor_col)

        if new_prefix.empty?
          editor.insert_completion_state.reset
          return
        end

        editor.insert_completion_state.update_prefix(new_prefix)

        # Close completion if no matches remain
        editor.insert_completion_state.reset unless editor.insert_completion_state.active?
      end

      def trigger_completion_for(char)
        return unless editor

        # LSP completion triggers
        if %w[. @].include?(char) || (char == ":" && previous_char == ":")
          editor.trigger_autocmd(:InsertCompletion)
          return
        end

        # Buffer word completion - trigger after typing word characters
        trigger_buffer_completion_if_needed(min_prefix: 1) if word_char?(char)
      end

      def trigger_buffer_completion_if_needed(min_prefix: 3)
        prefix = @word_cache.prefix_at(cursor_row, cursor_col)

        return if prefix.length < min_prefix

        # Mark current row as dirty to exclude word at cursor
        @word_cache.mark_dirty(cursor_row)
        candidates = @word_cache.complete(prefix, cursor_row, cursor_col)
        return if candidates.empty?

        # Format candidates for InsertCompletionState
        items = candidates.map do |word|
          {
            label: word,
            insert_text: word
          }
        end

        editor.start_insert_completion(items, prefix:)
      end

      def word_char?(char)
        char&.match?(/\w/)
      end

      def previous_char
        return nil if cursor_col < 2

        buffer.line(cursor_row)[cursor_col - 2]
      end

      def handle_buffer_completion
        return result unless editor

        # For manual trigger (Ctrl+N/P), allow 1+ character prefix
        trigger_buffer_completion_if_needed(min_prefix: 1)
        result
      end

      def handle_tab
        buffer.insert_char(cursor_row, cursor_col, "\t")
        self.cursor_col = cursor_col + 1
        result
      end

      def completion_active?
        editor&.insert_completion_active?
      end

      def handle_completion_next
        editor.insert_completion_state.select_next
        result
      end

      def handle_completion_previous
        editor.insert_completion_state.select_previous
        result
      end

      def handle_completion_confirm
        state = editor.insert_completion_state
        return result unless state.current_item

        insert_text = state.insert_text
        text_edit_range = state.text_edit_range

        if text_edit_range
          # Use textEdit range for precise replacement
          apply_text_edit(insert_text, text_edit_range)
        else
          # Fallback to prefix-based replacement
          apply_prefix_replacement(insert_text, state.prefix)
        end

        state.reset
        result
      end

      def apply_text_edit(insert_text, range)
        start_char = range.dig(:start, :character) || range.dig("start", "character")
        end_char = range.dig(:end, :character) || range.dig("end", "character")

        # Delete from start to end
        delete_count = end_char - start_char
        self.cursor_col = start_char
        delete_count.times { buffer.delete_char(cursor_row, cursor_col) }

        # Insert new text
        insert_text.each_char do |c|
          buffer.insert_char(cursor_row, cursor_col, c)
          self.cursor_col = cursor_col + 1
        end
      end

      def apply_prefix_replacement(insert_text, prefix)
        # Delete prefix
        prefix.length.times do
          self.cursor_col = cursor_col - 1
          buffer.delete_char(cursor_row, cursor_col)
        end

        # Insert completion text
        insert_text.each_char do |c|
          buffer.insert_char(cursor_row, cursor_col, c)
          self.cursor_col = cursor_col + 1
        end
      end

      def reset_insert_completion_state
        editor.insert_completion_state.reset if completion_active?
      end

      def result(mode: nil, message: nil, quit: false)
        HandlerResult::InsertModeResult.new(mode:, message:, quit:)
      end
    end
  end
end
