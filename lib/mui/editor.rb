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
      @selection = nil

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

    def create_visual_handler(line_mode:)
      @selection = Selection.new(@window.cursor_row, @window.cursor_col, line_mode: line_mode)

      if line_mode
        KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
      else
        KeyHandler::VisualMode.new(@window, @buffer, @selection)
      end
    end

    def update_window_size
      @window.width = @screen.width
      @window.height = @screen.height
    end

    def render
      @screen.clear
      @window.ensure_cursor_visible
      @window.render(@screen, selection: @selection)

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
                    when Mode::VISUAL
                      @message || "-- VISUAL --"
                    when Mode::VISUAL_LINE
                      @message || "-- VISUAL LINE --"
                    else
                      @message || "-- NORMAL --"
                    end
      @screen.put(@screen.height - 1, 0, status_line)
    end

    def handle_key(key)
      @message = nil

      handler = current_handler
      result = handler.handle(key)

      apply_result(result)
    end

    def current_handler
      if visual_mode?
        @visual_handler || @key_handlers[Mode::NORMAL]
      else
        @key_handlers[@mode]
      end
    end

    def visual_mode?
      @mode == Mode::VISUAL || @mode == Mode::VISUAL_LINE
    end

    def apply_result(result)
      handle_mode_transition(result)
      @message = result.message if result.message
      @running = false if result.quit?
    end

    def handle_mode_transition(result)
      return unless result.mode

      case result.mode
      when Mode::VISUAL, Mode::VISUAL_LINE
        if result.start_selection?
          start_visual_mode(result.mode, result.line_mode?)
        elsif result.toggle_line_mode?
          toggle_visual_line_mode(result.mode)
        else
          @mode = result.mode
        end
      when Mode::NORMAL
        clear_visual_mode if result.clear_selection?
        @mode = result.mode
      else
        @mode = result.mode
      end
    end

    def start_visual_mode(mode, line_mode)
      @mode = mode
      @visual_handler = create_visual_handler(line_mode: line_mode)
    end

    def clear_visual_mode
      @selection = nil
      @visual_handler = nil
    end

    def toggle_visual_line_mode(new_mode)
      return unless @selection

      new_line_mode = new_mode == Mode::VISUAL_LINE
      @selection = Selection.new(@selection.start_row, @selection.start_col, line_mode: new_line_mode)
      @selection.update_end(@window.cursor_row, @window.cursor_col)
      @visual_handler = if new_line_mode
                          KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
                        else
                          KeyHandler::VisualMode.new(@window, @buffer, @selection)
                        end
      @mode = new_mode
    end
  end
end
