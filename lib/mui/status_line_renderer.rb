# frozen_string_literal: true

module Mui
  class StatusLineRenderer
    def initialize(buffer, window, color_scheme)
      @buffer = buffer
      @window = window
      @color_scheme = color_scheme
    end

    def render(screen, y_position)
      full_status = format_status_line(build_status_text, build_position_text)

      if @color_scheme
        screen.put_with_style(y_position, @window.x, full_status, @color_scheme[:status_line])
      else
        screen.put(y_position, @window.x, full_status)
      end
    end

    private

    def build_status_text
      status = " #{@buffer.name}"
      status += " [+]" if @buffer.modified
      status
    end

    def build_position_text
      "#{@window.cursor_row + 1}:#{@window.cursor_col + 1} "
    end

    def format_status_line(status, position)
      padding = @window.width - status.length - position.length
      padding = 0 if padding.negative?
      full_status = status + (" " * padding) + position
      full_status[0, @window.width]
    end
  end
end
