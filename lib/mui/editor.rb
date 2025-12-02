# frozen_string_literal: true

module Mui
  # Main editor class that coordinates all components
  class Editor
    def initialize(file_path = nil)
      @screen = Screen.new
      @input = Input.new
      @buffer = Buffer.new
      @buffer.load(file_path) if file_path
      @window = Window.new(@buffer, width: @screen.width, height: @screen.height)
      @mode = Mode::NORMAL
      @command_line = CommandLine.new
      @message = nil
      @running = true

      initialize_key_handlers
    end

    def run
      while @running
        update_window_size
        render
        handle_key(@input.read)
      end
    ensure
      @screen.close
    end

    private

    def initialize_key_handlers
      @key_handlers = {
        Mode::NORMAL => KeyHandler::NormalMode.new(@window, @buffer),
        Mode::INSERT => KeyHandler::InsertMode.new(@window, @buffer),
        Mode::COMMAND => KeyHandler::CommandMode.new(@window, @buffer, @command_line)
      }
    end

    def update_window_size
      @window.width = @screen.width
      @window.height = @screen.height
    end

    def render
      @screen.clear
      @window.ensure_cursor_visible
      @window.render(@screen)

      render_status_area

      @screen.move_cursor(@window.screen_cursor_y, @window.screen_cursor_x)
      @screen.refresh
    end

    def render_status_area
      status_line = case @mode
                    when Mode::COMMAND
                      @command_line.to_s
                    when Mode::INSERT
                      @message || "-- INSERT --"
                    else
                      @message || "-- NORMAL --"
                    end
      @screen.put(@screen.height - 1, 0, status_line)
    end

    def handle_key(key)
      @message = nil

      handler = @key_handlers[@mode]
      result = handler.handle(key)

      apply_result(result)
    end

    def apply_result(result)
      @mode = result[:mode] if result[:mode]
      @message = result[:message] if result[:message]
      @running = false if result[:quit]
    end
  end
end
