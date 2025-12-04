# frozen_string_literal: true

module Mui
  # Main editor class that coordinates all components
  class Editor
    attr_reader :buffer, :window, :message, :running

    def initialize(file_path = nil, adapter: TerminalAdapter::Curses.new)
      @adapter = adapter
      @screen = Screen.new(adapter: @adapter)
      @input = Input.new(adapter: @adapter)
      @buffer = Buffer.new
      @buffer.load(file_path) if file_path
      @window = Window.new(@buffer, width: @screen.width, height: @screen.height)
      @command_line = CommandLine.new
      @message = nil
      @running = true

      @mode_manager = ModeManager.new(
        window: @window,
        buffer: @buffer,
        command_line: @command_line
      )
    end

    def mode
      @mode_manager.mode
    end

    def selection
      @mode_manager.selection
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
      @window.render(@screen, selection: @mode_manager.selection)

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
  end
end
