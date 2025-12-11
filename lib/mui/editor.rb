# frozen_string_literal: true

module Mui
  # Main editor class that coordinates all components
  class Editor
    attr_reader :tab_manager, :undo_manager, :autocmd, :command_registry, :job_manager, :color_scheme, :floating_window
    attr_accessor :message, :running

    def initialize(file_path = nil, adapter: TerminalAdapter::Curses.new, load_config: true)
      Mui.load_config if load_config

      @adapter = adapter
      @color_manager = ColorManager.new
      @adapter.color_resolver = @color_manager
      @color_scheme = load_color_scheme
      @screen = Screen.new(adapter: @adapter, color_manager: @color_manager)
      @input = Input.new(adapter: @adapter)
      @buffer = Buffer.new
      @buffer.load(file_path) if file_path

      @tab_manager = TabManager.new(@screen, color_scheme: @color_scheme)
      initial_tab = @tab_manager.add
      initial_tab.window_manager.add_window(@buffer)

      @tab_bar_renderer = TabBarRenderer.new(@tab_manager, color_scheme: @color_scheme)

      @command_line = CommandLine.new
      @completion_renderer = CompletionRenderer.new(@screen, @color_scheme)
      @floating_window = FloatingWindow.new(@color_scheme)
      @message = nil
      @running = true

      @undo_manager = UndoManager.new
      @buffer.undo_manager = @undo_manager

      @autocmd = Autocmd.new
      @command_registry = CommandRegistry.new
      @job_manager = JobManager.new(autocmd: @autocmd)

      # Install and load plugins via bundler/inline
      Mui.plugin_manager.install_and_load

      # Load plugin autocmds
      load_plugin_autocmds

      @mode_manager = ModeManager.new(
        window: @tab_manager,
        buffer: @buffer,
        command_line: @command_line,
        undo_manager: @undo_manager,
        editor: self
      )

      # Trigger BufEnter event
      trigger_autocmd(:BufEnter)
    end

    def window_manager
      @tab_manager.window_manager
    end

    def window
      @tab_manager.active_window
    end

    def buffer
      window.buffer
    end

    def mode
      @mode_manager.mode
    end

    def selection
      @mode_manager.selection
    end

    def register
      @mode_manager.register
    end

    def run
      while @running
        process_job_results
        update_window_size
        render
        key = @input.read_nonblock
        if key
          handle_key(key)
        else
          sleep 0.01 # CPU usage optimization
        end
      end
    ensure
      @adapter.close
    end

    # Open a scratch buffer (read-only) with the given content
    def open_scratch_buffer(name, content)
      scratch_buffer = Buffer.new(name)
      scratch_buffer.content = content
      scratch_buffer.readonly = true

      # Split horizontally and show the scratch buffer
      window_manager.split_horizontal(scratch_buffer)
    end

    # Suspend UI for running external interactive commands (e.g., fzf)
    def suspend_ui
      @adapter.suspend
      yield
    ensure
      @adapter.resume
    end

    def handle_key(key)
      @message = nil

      # Close floating window on Escape or any key input (except scroll keys if we add them)
      if @floating_window.visible
        @floating_window.hide
        return if key == KeyCode::ESCAPE
      end

      old_window = window
      old_buffer = old_window&.buffer
      old_modified = old_buffer&.modified
      result = @mode_manager.current_handler.handle(key)
      apply_result(result)

      current_window = window
      return unless current_window # Guard against nil window (e.g., after closing last tab)

      current_buffer = current_window.buffer

      # Trigger BufEnter if buffer changed (window focus change)
      trigger_autocmd(:BufEnter) if current_buffer != old_buffer

      # Trigger TextChanged if buffer was modified
      trigger_autocmd(:TextChanged) if (current_buffer.modified && !old_modified) || buffer_content_changed?
    end

    # Trigger autocmd event with current context
    def trigger_autocmd(event)
      context = CommandContext.new(editor: self, buffer:, window:)
      @autocmd.trigger(event, context)
    end

    # Show a floating window with content at the cursor position
    def show_floating(content, max_width: nil, max_height: nil)
      # Position below cursor
      row = window.screen_cursor_y + 1
      col = window.screen_cursor_x

      @floating_window.show(
        content,
        row:,
        col:,
        max_width: max_width || (@screen.width / 2),
        max_height: max_height || 10
      )
    end

    # Hide the floating window
    def hide_floating
      @floating_window.hide
    end

    private

    def buffer_content_changed?
      # Track if content actually changed (for TextChanged event)
      @last_buffer_hash ||= buffer.lines.hash
      current_hash = buffer.lines.hash
      changed = @last_buffer_hash != current_hash
      @last_buffer_hash = current_hash
      changed
    end

    def update_window_size
      window_manager.update_layout(y_offset: tab_bar_height)
    end

    def render
      @screen.clear

      @tab_bar_renderer.render(@screen, 0)

      window.ensure_cursor_visible
      window_manager.render_all(
        @screen,
        selection: @mode_manager.selection,
        search_state: @mode_manager.search_state
      )

      render_status_area

      # Position cursor based on current mode
      if @mode_manager.mode == Mode::COMMAND
        # In command mode, cursor is on the command line (after ":" + buffer position)
        @screen.move_cursor(@screen.height - 1, 1 + @command_line.cursor_pos)
      elsif [Mode::SEARCH_FORWARD, Mode::SEARCH_BACKWARD].include?(@mode_manager.mode)
        # In search mode, cursor is on the search input line (after "/" or "?" + pattern)
        @screen.move_cursor(@screen.height - 1, 1 + @mode_manager.search_input.buffer.length)
      else
        # In other modes, cursor is in the editor window
        @screen.move_cursor(window.screen_cursor_y, window.screen_cursor_x)
      end
      @screen.refresh
    end

    def tab_bar_height
      @tab_bar_renderer.height
    end

    def render_status_area
      status_text = case @mode_manager.mode
                    when Mode::COMMAND
                      @command_line.to_s
                    when Mode::INSERT
                      @message || "-- INSERT --"
                    when Mode::VISUAL
                      @message || "-- VISUAL --"
                    when Mode::VISUAL_LINE
                      @message || "-- VISUAL LINE --"
                    when Mode::SEARCH_FORWARD, Mode::SEARCH_BACKWARD
                      @mode_manager.search_input.to_s
                    else
                      @message || "-- NORMAL --"
                    end

      status_line = status_text.ljust(@screen.width)
      style = @color_scheme[:command_line]
      @screen.put_with_style(@screen.height - 1, 0, status_line, style)

      # Render completion popup in command mode or search mode
      if @mode_manager.mode == Mode::COMMAND
        render_completion_popup
      elsif [Mode::SEARCH_FORWARD, Mode::SEARCH_BACKWARD].include?(@mode_manager.mode)
        render_search_completion_popup
      end

      # Render floating window if visible
      @floating_window.render(@screen)
    end

    def render_search_completion_popup
      completion_state = @mode_manager.current_handler.completion_state
      return unless completion_state&.active?

      # Popup appears above the search line, starting after "/" or "?"
      base_row = @screen.height - 1
      base_col = 1 # After the prompt
      @completion_renderer.render(completion_state, base_row, base_col)
    end

    def render_completion_popup
      completion_state = @mode_manager.current_handler.completion_state
      return unless completion_state&.active?

      # Popup appears above the command line, starting after the ":"
      base_row = @screen.height - 1
      base_col = 1 # After the ":"
      @completion_renderer.render(completion_state, base_row, base_col)
    end

    def apply_result(result)
      @mode_manager.transition(result)
      @message = result.message if result.message
      @running = false if result.quit?
    end

    def load_color_scheme
      scheme_name = Mui.config.get(:colorscheme)
      Themes.send(scheme_name.to_sym)
    rescue NoMethodError
      Themes.mui
    end

    def load_plugin_autocmds
      Mui.config.autocmds.each do |event, handlers|
        handlers.each do |h|
          @autocmd.register(event, pattern: h[:pattern], &h[:handler])
        end
      end
    end

    def process_job_results
      @job_manager.poll
    end
  end
end
