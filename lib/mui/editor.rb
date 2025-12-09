# frozen_string_literal: true

module Mui
  # Main editor class that coordinates all components
  class Editor
    attr_reader :tab_manager, :undo_manager, :autocmd, :command_registry
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
      @message = nil
      @running = true

      @undo_manager = UndoManager.new
      @buffer.undo_manager = @undo_manager

      @autocmd = Autocmd.new
      @command_registry = CommandRegistry.new

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
        update_window_size
        render
        handle_key(@input.read)
      end
    ensure
      @adapter.close
    end

    def handle_key(key)
      @message = nil
      result = @mode_manager.current_handler.handle(key)
      apply_result(result)
    end

    private

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

      # screen_cursor_y already includes y_offset via window.y
      @screen.move_cursor(window.screen_cursor_y, window.screen_cursor_x)
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

    def trigger_autocmd(event)
      context = CommandContext.new(editor: self, buffer: @buffer, window:)
      @autocmd.trigger(event, context)
    end
  end
end
