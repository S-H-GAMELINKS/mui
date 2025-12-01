# frozen_string_literal: true

module Mui
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

      case @mode
      when Mode::NORMAL
        handle_normal_key(key)
      when Mode::INSERT
        handle_insert_key(key)
      when Mode::COMMAND
        handle_command_key(key)
      end
    end

    def handle_normal_key(key)
      case key
      when "h", Curses::KEY_LEFT
        @window.move_left
      when "j", Curses::KEY_DOWN
        @window.move_down
      when "k", Curses::KEY_UP
        @window.move_up
      when "l", Curses::KEY_RIGHT
        @window.move_right
      when "i"
        @mode = Mode::INSERT
      when "a"
        @window.cursor_col += 1 if @buffer.line(@window.cursor_row).length.positive?
        @mode = Mode::INSERT
      when "o"
        @buffer.insert_line(@window.cursor_row + 1)
        @window.cursor_row += 1
        @window.cursor_col = 0
        @mode = Mode::INSERT
      when "O"
        @buffer.insert_line(@window.cursor_row)
        @window.cursor_col = 0
        @mode = Mode::INSERT
      when "x"
        @buffer.delete_char(@window.cursor_row, @window.cursor_col)
      when ":"
        @mode = Mode::COMMAND
        @command_line.clear
      end
    end

    def handle_insert_key(key)
      case key
      when 27 # Escape
        @window.cursor_col -= 1 if @window.cursor_col.positive?
        @mode = Mode::NORMAL
      when Curses::KEY_LEFT
        @window.cursor_col -= 1 if @window.cursor_col.positive?
      when Curses::KEY_RIGHT
        @window.cursor_col += 1 if @window.cursor_col < @buffer.line(@window.cursor_row).length
      when Curses::KEY_UP
        @window.move_up
      when Curses::KEY_DOWN
        @window.move_down
      when 127, Curses::KEY_BACKSPACE
        if @window.cursor_col.positive?
          @window.cursor_col -= 1
          @buffer.delete_char(@window.cursor_row, @window.cursor_col)
        elsif @window.cursor_row.positive?
          prev_line_len = @buffer.line(@window.cursor_row - 1).length
          @buffer.join_lines(@window.cursor_row - 1)
          @window.cursor_row -= 1
          @window.cursor_col = prev_line_len
        end
      when 13, 10, Curses::KEY_ENTER # Enter
        @buffer.split_line(@window.cursor_row, @window.cursor_col)
        @window.cursor_row += 1
        @window.cursor_col = 0
      else
        if key.is_a?(String)
          @buffer.insert_char(@window.cursor_row, @window.cursor_col, key)
          @window.cursor_col += 1
        elsif key.is_a?(Integer) && key >= 32 && key < 127
          @buffer.insert_char(@window.cursor_row, @window.cursor_col, key.chr)
          @window.cursor_col += 1
        end
      end
    end

    def handle_command_key(key)
      case key
      when 27 # Escape
        @mode = Mode::NORMAL
        @command_line.clear
      when 127, Curses::KEY_BACKSPACE
        if @command_line.buffer.empty?
          @mode = Mode::NORMAL
        else
          @command_line.backspace
        end
      when 13, 10, Curses::KEY_ENTER # Enter
        execute_command
        @mode = Mode::NORMAL
      else
        if key.is_a?(String)
          @command_line.input(key)
        elsif key.is_a?(Integer) && key >= 32 && key < 127
          @command_line.input(key.chr)
        end
      end
    end

    def execute_command
      result = @command_line.execute

      case result[:action]
      when :write
        save_buffer
      when :quit
        if @buffer.modified
          @message = "No write since last change (add ! to override)"
        else
          @running = false
        end
      when :write_quit
        save_buffer
        @running = false
      when :force_quit
        @running = false
      when :write_as
        save_buffer(result[:path])
      when :unknown
        @message = "Unknown command: #{result[:command]}"
      end
    end

    def save_buffer(path = nil)
      if path
        @buffer.save(path)
      elsif @buffer.name == "[No Name]"
        @message = "No file name"
        return
      else
        @buffer.save
      end
      @message = "\"#{@buffer.name}\" written"
    rescue StandardError => e
      @message = "Error: #{e.message}"
    end
  end
end
