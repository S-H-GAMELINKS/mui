# frozen_string_literal: true

module Mui
  # Main editor class that coordinates all components
  class Editor
    attr_reader :buffer, :window, :undo_manager, :autocmd, :command_registry
    attr_accessor :message, :running

    def initialize(file_path = nil, adapter: TerminalAdapter::Curses.new, load_config: true)
      Mui.load_config if load_config

      @adapter = adapter
      @color_manager = ColorManager.new
      @color_scheme = load_color_scheme
      @screen = Screen.new(adapter: @adapter, color_manager: @color_manager)
      @input = Input.new(adapter: @adapter)
      @buffer = Buffer.new
      @buffer.load(file_path) if file_path
      @window = Window.new(@buffer, width: @screen.width, height: @screen.height, color_scheme: @color_scheme)
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
        window: @window,
        buffer: @buffer,
        command_line: @command_line,
        undo_manager: @undo_manager,
        editor: self
      )

      # Trigger BufEnter event
      trigger_autocmd(:BufEnter)
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
      @window.width = @screen.width
      @window.height = @screen.height
    end

    def render
      @screen.clear
      @window.ensure_cursor_visible
      @window.render(@screen, selection: @mode_manager.selection, search_state: @mode_manager.search_state)

      render_status_area

      @screen.move_cursor(@window.screen_cursor_y, @window.screen_cursor_x)
      @screen.refresh
    end

    def render_status_area
      status_line = case @mode_manager.mode
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
      @screen.put(@screen.height - 1, 0, status_line)
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
      context = CommandContext.new(editor: self, buffer: @buffer, window: @window)
      @autocmd.trigger(event, context)
    end
  end
end
