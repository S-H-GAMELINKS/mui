# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handles key inputs in Command mode
    class CommandMode < Base
      attr_reader :completion_state

      def initialize(mode_manager, buffer, command_line)
        super(mode_manager, buffer)
        @command_line = command_line
        @completion_state = CompletionState.new
        @command_completer = CommandCompleter.new
        @file_completer = FileCompleter.new
      end

      def handle(key)
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

      def handle_escape
        @completion_state.reset
        @command_line.clear
        result(mode: Mode::NORMAL)
      end

      def handle_backspace
        if @command_line.buffer.empty?
          @completion_state.reset
          result(mode: Mode::NORMAL)
        else
          @command_line.backspace
          update_completion
          result
        end
      end

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

      def update_completion
        context = @command_line.completion_context
        unless context
          @completion_state.reset
          return
        end

        candidates = case context[:type]
                     when :command
                       @command_completer.complete(context[:prefix])
                     when :file
                       @file_completer.complete(context[:prefix])
                     end

        if candidates.nil? || candidates.empty?
          @completion_state.reset
        else
          @completion_state.start(candidates, @command_line.buffer, context[:type])
        end
      end

      def apply_current_completion
        candidate = @completion_state.current_candidate
        return unless candidate

        context = @command_line.completion_context
        return unless context

        @command_line.apply_completion(candidate, context)
      end

      def handle_enter
        command_result = @command_line.execute
        action_result = execute_action(command_result)
        HandlerResult::CommandModeResult.new(
          mode: Mode::NORMAL,
          message: action_result.message,
          quit: action_result.quit?
        )
      end

      def handle_character_input(key)
        char = extract_printable_char(key)
        if char
          @command_line.input(char)
          update_completion
        end
        result
      end

      def execute_action(command_result)
        case command_result[:action]
        when :open
          handle_open
        when :open_as
          open_buffer(command_result[:path])
        when :write
          handle_write
        when :quit
          handle_quit
        when :write_quit
          handle_write_quit
        when :force_quit
          handle_force_quit
        when :write_as
          save_buffer(command_result[:path])
        when :split_horizontal
          handle_split_horizontal(command_result[:path])
        when :split_vertical
          handle_split_vertical(command_result[:path])
        when :close_window
          handle_close_window
        when :only_window
          handle_only_window
        when :tab_new
          handle_tab_new(command_result[:path])
        when :tab_close
          handle_tab_close
        when :tab_next
          handle_tab_next
        when :tab_prev
          handle_tab_prev
        when :tab_first
          handle_tab_first
        when :tab_last
          handle_tab_last
        when :tab_go
          handle_tab_go(command_result[:index])
        when :tab_move
          handle_tab_move(command_result[:position])
        when :unknown
          # Check plugin commands before reporting unknown
          plugin_result = try_plugin_command(command_result[:command])
          plugin_result || result(message: "Unknown command: #{command_result[:command]}")
        else
          result
        end
      end

      def try_plugin_command(command_str)
        return nil unless @mode_manager&.editor

        parts = command_str.to_s.split(/\s+/, 2)
        cmd_name = parts[0]
        args = parts[1]

        plugin_command = Mui.config.commands[cmd_name.to_sym]
        return nil unless plugin_command

        context = CommandContext.new(
          editor: @mode_manager.editor,
          buffer:,
          window:
        )
        plugin_command.call(context, args)
        result
      end

      def handle_open
        open_buffer
      end

      def handle_write
        save_buffer
      end

      def handle_quit
        return result(message: "No write since last change (add ! to override)") if buffer.modified

        close_or_quit
      end

      def handle_write_quit
        save_result = save_buffer
        return save_result if save_result.message && !save_result.message.include?("written")

        close_or_quit(message: save_result.message)
      end

      def handle_force_quit
        close_or_quit
      end

      def close_or_quit(message: nil)
        with_window_manager do |wm|
          # If multiple windows in current tab, close window
          unless wm.single_window?
            wm.close_current_window
            return result(message:)
          end

          # Single window in current tab - check if we have multiple tabs
          tab_manager = @mode_manager&.editor&.tab_manager
          if tab_manager && !tab_manager.single_tab?
            tab_manager.close_current
            return result(message:)
          end

          # Single window, single tab - quit editor
          return result(message:, quit: true)
        end
        result(message:, quit: true)
      end

      def open_buffer(path = nil)
        if path
          open_new_buffer(path)
        else
          reload_current_buffer
        end
      end

      def open_new_buffer(path)
        new_buffer = create_buffer_from_path(path)
        window.buffer = new_buffer
        result(message: "\"#{path}\" opened")
      rescue SystemCallError => e
        result(message: "Error: #{e.message}")
      end

      def reload_current_buffer
        target_path = buffer.name
        return result(message: "No file name") if target_path.nil? || target_path == "[No Name]"

        buffer.load(target_path)
        result(message: "File reopened")
      rescue SystemCallError => e
        result(message: "Error: #{e.message}")
      end

      def save_buffer(path = nil)
        if path
          buffer.save(path)
        elsif buffer.name == "[No Name]"
          return result(message: "No file name")
        else
          buffer.save
        end
        result(message: "\"#{buffer.name}\" written")
      rescue SystemCallError => e
        result(message: "Error: #{e.message}")
      end

      def handle_split_horizontal(path = nil)
        with_window_manager do |wm|
          buffer = path ? create_buffer_from_path(path) : nil
          wm.split_horizontal(buffer)
          result
        end
      end

      def handle_split_vertical(path = nil)
        with_window_manager do |wm|
          buffer = path ? create_buffer_from_path(path) : nil
          wm.split_vertical(buffer)
          result
        end
      end

      def handle_close_window
        with_window_manager do |wm|
          if wm.single_window?
            result(message: "Cannot close last window")
          else
            wm.close_current_window
            result
          end
        end
      end

      def handle_only_window
        with_window_manager do |wm|
          wm.close_all_except_current
          result
        end
      end

      def with_window_manager
        wm = @mode_manager&.window_manager
        return result(message: "Window commands not available") unless wm

        yield wm
      end

      def with_tab_manager
        tm = @mode_manager&.editor&.tab_manager
        return result(message: "Tab commands not available") unless tm

        yield tm
      end

      def handle_tab_new(path = nil)
        with_tab_manager do |tm|
          new_tab = tm.add
          buffer = path ? create_buffer_from_path(path) : Buffer.new
          new_tab.window_manager.add_window(buffer)
          result
        end
      end

      def handle_tab_close
        with_tab_manager do |tm|
          if tm.single_tab?
            result(message: "Cannot close last tab")
          else
            tm.close_current
            result
          end
        end
      end

      def handle_tab_next
        with_tab_manager do |tm|
          tm.next_tab
          result
        end
      end

      def handle_tab_prev
        with_tab_manager do |tm|
          tm.prev_tab
          result
        end
      end

      def handle_tab_first
        with_tab_manager do |tm|
          tm.first_tab
          result
        end
      end

      def handle_tab_last
        with_tab_manager do |tm|
          tm.last_tab
          result
        end
      end

      def handle_tab_go(index)
        with_tab_manager do |tm|
          if tm.go_to(index)
            result
          else
            result(message: "Invalid tab index")
          end
        end
      end

      def handle_tab_move(position)
        with_tab_manager do |tm|
          tm.move_tab(position)
          result
        end
      end

      def create_buffer_from_path(path)
        new_buffer = Buffer.new
        new_buffer.load(path)
        new_buffer
      rescue SystemCallError
        # File doesn't exist yet, create new buffer with the name
        new_buffer = Buffer.new
        new_buffer.name = path
        new_buffer
      end

      def result(mode: nil, message: nil, quit: false)
        HandlerResult::CommandModeResult.new(mode:, message:, quit:)
      end
    end
  end
end
