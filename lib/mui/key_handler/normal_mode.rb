# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handles key inputs in Normal mode
    class NormalMode < Base
      include Motions::MotionHandler

      def initialize(mode_manager, buffer, register = nil, undo_manager: nil, search_state: nil)
        super(mode_manager, buffer)
        @register = register || Register.new
        @undo_manager = undo_manager
        @search_state = search_state
        @pending_motion = nil
        @pending_register = nil
        @window_command = nil
        initialize_operators
      end

      def handle(key)
        # Sync operators with current buffer/window (may have changed via tab switch)
        sync_operators

        # Check plugin keymaps first (only when no pending motion)
        unless @pending_motion
          plugin_result = check_plugin_keymap(key, :normal)
          return plugin_result if plugin_result
        end

        if @pending_motion
          handle_pending_motion(key)
        else
          handle_normal_key(key)
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
        # This allows buffer-specific keymaps to pass through for other buffers
        return nil unless handler_result

        # Return a valid result to indicate the key was handled
        handler_result.is_a?(HandlerResult::NormalModeResult) ? handler_result : result
      end

      private

      # Convert key to string for keymap lookup
      # Handles special keys like Enter that have Curses constants
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

      def initialize_operators
        @operators = {
          delete: Operators::DeleteOperator.new(
            buffer:, window:, register: @register, undo_manager: @undo_manager
          ),
          change: Operators::ChangeOperator.new(
            buffer:, window:, register: @register, undo_manager: @undo_manager
          ),
          yank: Operators::YankOperator.new(
            buffer:, window:, register: @register
          ),
          paste: Operators::PasteOperator.new(
            buffer:, window:, register: @register
          )
        }
      end

      def sync_operators
        @operators.each_value { |op| op.update(buffer:, window:) }
      end

      def handle_normal_key(key)
        case key
        when "h", Curses::KEY_LEFT
          handle_move_left
        when "j", Curses::KEY_DOWN
          handle_move_down
        when "k", Curses::KEY_UP
          handle_move_up
        when "l", Curses::KEY_RIGHT
          handle_move_right
        when "w"
          handle_word_forward
        when "b"
          handle_word_backward
        when "e"
          handle_word_end
        when "0"
          handle_line_start
        when "^"
          handle_first_non_blank
        when "$"
          handle_line_end
        when "g"
          @pending_motion = :g
          result
        when "G"
          handle_file_end
        when "f"
          @pending_motion = :f
          result
        when "F"
          @pending_motion = :F
          result
        when "t"
          @pending_motion = :t
          result
        when "T"
          @pending_motion = :T
          result
        when "i"
          return readonly_error if buffer.readonly?

          result(mode: Mode::INSERT)
        when "a"
          return readonly_error if buffer.readonly?

          handle_append
        when "o"
          return readonly_error if buffer.readonly?

          handle_open_below
        when "O"
          return readonly_error if buffer.readonly?

          handle_open_above
        when "x"
          return readonly_error if buffer.readonly?

          handle_delete_char
        when "d"
          return readonly_error if buffer.readonly?

          @pending_motion = :d
          result
        when "c"
          return readonly_error if buffer.readonly?

          @pending_motion = :c
          result
        when "y"
          @pending_motion = :y
          result
        when "p"
          return readonly_error if buffer.readonly?

          handle_paste_after
        when "P"
          return readonly_error if buffer.readonly?

          handle_paste_before
        when ":"
          result(mode: Mode::COMMAND)
        when "v"
          result(mode: Mode::VISUAL, start_selection: true)
        when "V"
          result(mode: Mode::VISUAL_LINE, start_selection: true, line_mode: true)
        when '"'
          @pending_motion = :register_select
          result
        when "u"
          handle_undo
        when 18 # Ctrl-r
          handle_redo
        when "/"
          result(mode: Mode::SEARCH_FORWARD)
        when "?"
          result(mode: Mode::SEARCH_BACKWARD)
        when "n"
          handle_search_next
        when "N"
          handle_search_previous
        when "*"
          handle_search_word(:forward)
        when "#"
          handle_search_word(:backward)
        when KeyCode::CTRL_W
          @pending_motion = :window_command
          result
        else
          result
        end
      end

      def handle_pending_motion(key)
        # Window command doesn't need char conversion
        return dispatch_window_command(key) if @pending_motion == :window_command

        char = key_to_char(key)
        return clear_pending unless char

        case @pending_motion
        when :register_select
          handle_register_select(char)
        when :g
          dispatch_g_command(char)
        when :d
          dispatch_delete_operator(char)
        when :dg
          dispatch_delete_to_file_start(char)
        when :df, :dF, :dt, :dT
          dispatch_delete_find_char(char)
        when :c
          dispatch_change_operator(char)
        when :cg
          dispatch_change_to_file_start(char)
        when :cf, :cF, :ct, :cT
          dispatch_change_find_char(char)
        when :y
          dispatch_yank_operator(char)
        when :yg
          dispatch_yank_to_file_start(char)
        when :yf, :yF, :yt, :yT
          dispatch_yank_find_char(char)
        else
          motion_result = execute_pending_motion(char)
          apply_motion(motion_result) if motion_result
          clear_pending
        end
      end

      def clear_pending
        @pending_motion = nil
        @pending_register = nil
        result
      end

      def handle_register_select(char)
        if valid_register_name?(char)
          @pending_register = char
          @pending_motion = nil
          result
        else
          clear_pending
        end
      end

      def valid_register_name?(char)
        Register::NAMED_REGISTERS.include?(char) ||
          Register::DELETE_HISTORY_REGISTERS.include?(char) ||
          [Register::YANK_REGISTER, Register::BLACK_HOLE_REGISTER, Register::UNNAMED_REGISTER].include?(char)
      end

      # Movement handlers
      def handle_move_left
        window.move_left
        result
      end

      def handle_move_down
        window.move_down
        result
      end

      def handle_move_up
        window.move_up
        result
      end

      def handle_move_right
        window.move_right
        result
      end

      # Edit handlers
      def handle_append
        self.cursor_col = cursor_col + 1 if current_line_length.positive?
        result(mode: Mode::INSERT)
      end

      def handle_open_below
        @undo_manager&.begin_group
        buffer.insert_line(cursor_row + 1)
        self.cursor_row = cursor_row + 1
        self.cursor_col = 0
        result(mode: Mode::INSERT, group_started: true)
      end

      def handle_open_above
        @undo_manager&.begin_group
        buffer.insert_line(cursor_row)
        self.cursor_col = 0
        result(mode: Mode::INSERT, group_started: true)
      end

      def handle_delete_char
        buffer.delete_char(cursor_row, cursor_col)
        result
      end

      # Delete operator dispatchers
      def dispatch_delete_operator(char)
        status = @operators[:delete].handle_pending(char, pending_register: @pending_register)
        handle_operator_result(status)
      end

      def dispatch_delete_to_file_start(char)
        status = @operators[:delete].handle_to_file_start(char)
        handle_operator_result(status)
      end

      def dispatch_delete_find_char(char)
        status = @operators[:delete].handle_find_char(char, @pending_motion)
        handle_operator_result(status)
      end

      # Change operator dispatchers
      def dispatch_change_operator(char)
        status = @operators[:change].handle_pending(char, pending_register: @pending_register)
        handle_operator_result(status)
      end

      def dispatch_change_to_file_start(char)
        status = @operators[:change].handle_to_file_start(char)
        handle_operator_result(status)
      end

      def dispatch_change_find_char(char)
        status = @operators[:change].handle_find_char(char, @pending_motion)
        handle_operator_result(status)
      end

      # Yank operator dispatchers
      def dispatch_yank_operator(char)
        status = @operators[:yank].handle_pending(char, pending_register: @pending_register)
        handle_operator_result(status)
      end

      def dispatch_yank_to_file_start(char)
        status = @operators[:yank].handle_to_file_start(char)
        handle_operator_result(status)
      end

      def dispatch_yank_find_char(char)
        status = @operators[:yank].handle_find_char(char, @pending_motion)
        handle_operator_result(status)
      end

      # Paste handlers (delegate to operator)
      def handle_paste_after
        @operators[:paste].paste_after(pending_register: @pending_register)
        @pending_register = nil
        result
      end

      def handle_paste_before
        @operators[:paste].paste_before(pending_register: @pending_register)
        @pending_register = nil
        result
      end

      def handle_operator_result(status)
        case status
        when :insert_mode
          @pending_motion = nil
          @pending_register = nil
          result(mode: Mode::INSERT)
        when /^pending_/
          @pending_motion = status.to_s.sub("pending_", "").to_sym
          result
        else
          # :done, :cancel, or any other status
          clear_pending
        end
      end

      def result(mode: nil, message: nil, quit: false, start_selection: false, line_mode: false, group_started: false)
        HandlerResult::NormalModeResult.new(
          mode:,
          message:,
          quit:,
          start_selection:,
          line_mode:,
          group_started:
        )
      end

      def readonly_error
        result(message: "E21: Cannot make changes, buffer is readonly")
      end

      # Undo/Redo handlers
      def handle_undo
        if @undo_manager&.undo(buffer)
          window.clamp_cursor_to_line(buffer)
          result
        else
          result(message: "Already at oldest change")
        end
      end

      def handle_redo
        if @undo_manager&.redo(buffer)
          window.clamp_cursor_to_line(buffer)
          result
        else
          result(message: "Already at newest change")
        end
      end

      # Window command dispatcher
      def dispatch_window_command(key)
        window_manager = @mode_manager&.window_manager
        unless window_manager
          @pending_motion = nil
          return result(message: "Window commands not available")
        end

        @window_command ||= WindowCommand.new(window_manager)
        @window_command.handle(key)
        clear_pending
      end

      # g command dispatcher (gg, gt, gT)
      def dispatch_g_command(char)
        case char
        when "g"
          # gg - go to file start
          motion_result = Motion.file_start(buffer, cursor_row, cursor_col)
          apply_motion(motion_result) if motion_result
          clear_pending
        when "t"
          # gt - next tab
          handle_tab_next
        when "T"
          # gT - previous tab
          handle_tab_prev
        when "v"
          # gv - restore last visual selection
          handle_restore_visual
        else
          clear_pending
        end
      end

      def handle_restore_visual
        @pending_motion = nil
        if @mode_manager.last_visual_selection
          @mode_manager.restore_visual_selection
          line_mode = @mode_manager.last_visual_selection[:line_mode]
          result(mode: line_mode ? Mode::VISUAL_LINE : Mode::VISUAL)
        else
          result(message: "No previous visual selection")
        end
      end

      def handle_tab_next
        tab_manager = @mode_manager&.editor&.tab_manager
        unless tab_manager
          @pending_motion = nil
          return result(message: "Tab commands not available")
        end

        tab_manager.next_tab
        clear_pending
      end

      def handle_tab_prev
        tab_manager = @mode_manager&.editor&.tab_manager
        unless tab_manager
          @pending_motion = nil
          return result(message: "Tab commands not available")
        end

        tab_manager.prev_tab
        clear_pending
      end

      # Search handlers
      def handle_search_next
        return result(message: "No previous search pattern") unless @search_state&.has_pattern?

        match = if @search_state.direction == :forward
                  @search_state.find_next(cursor_row, cursor_col)
                else
                  @search_state.find_previous(cursor_row, cursor_col)
                end

        if match
          apply_motion(match)
          result
        else
          result(message: "Pattern not found: #{@search_state.pattern}")
        end
      end

      def handle_search_previous
        return result(message: "No previous search pattern") unless @search_state&.has_pattern?

        match = if @search_state.direction == :forward
                  @search_state.find_previous(cursor_row, cursor_col)
                else
                  @search_state.find_next(cursor_row, cursor_col)
                end

        if match
          apply_motion(match)
          result
        else
          result(message: "Pattern not found: #{@search_state.pattern}")
        end
      end

      def handle_search_word(direction)
        word = word_under_cursor
        return result if word.nil? || word.empty?

        # Use word boundary for whole word matching (Vim behavior)
        escaped_pattern = "\\b#{Regexp.escape(word)}\\b"

        @search_state.set_pattern(escaped_pattern, direction)
        @search_state.find_all_matches(buffer)

        # Find next/previous match from current position
        match = if direction == :forward
                  @search_state.find_next(cursor_row, cursor_col)
                else
                  @search_state.find_previous(cursor_row, cursor_col)
                end

        if match
          apply_motion(match)
          result
        else
          result(message: "Pattern not found: #{word}")
        end
      end

      def word_under_cursor
        line = buffer.line(cursor_row)
        return nil if line.nil? || line.empty?

        col = cursor_col
        return nil if col >= line.length

        # Check if cursor is on a word character
        return nil unless line[col]&.match?(/\w/)

        # Find word boundaries
        start_col = col
        start_col -= 1 while start_col.positive? && line[start_col - 1]&.match?(/\w/)

        end_col = col
        end_col += 1 while end_col < line.length && line[end_col]&.match?(/\w/)

        line[start_col...end_col]
      end
    end
  end
end
