# frozen_string_literal: true

module Mui
  class Window
    attr_reader :buffer
    attr_accessor :x, :y, :width, :height, :cursor_row, :cursor_col, :scroll_row, :scroll_col

    def initialize(buffer, x: 0, y: 0, width: 80, height: 24)
      @buffer = buffer
      @x = x
      @y = y
      @width = width
      @height = height
      @cursor_row = 0
      @cursor_col = 0
      @scroll_row = 0
      @scroll_col = 0
    end

    def visible_height
      @height - 2 # Status line and command line
    end

    def visible_width
      @width
    end

    def ensure_cursor_visible
      # 縦スクロール
      if @cursor_row < @scroll_row
        @scroll_row = @cursor_row
      elsif @cursor_row >= @scroll_row + visible_height
        @scroll_row = @cursor_row - visible_height + 1
      end

      # 横スクロール
      if @cursor_col < @scroll_col
        @scroll_col = @cursor_col
      elsif @cursor_col >= @scroll_col + visible_width
        @scroll_col = @cursor_col - visible_width + 1
      end
    end

    def render(screen)
      visible_height.times do |i|
        row = @scroll_row + i
        line = @buffer.line(row)
        visible_line = if @scroll_col < line.length
                         line[@scroll_col, visible_width] || ""
                       else
                         ""
                       end
        screen.put(@y + i, @x, visible_line.ljust(visible_width))
      end

      render_status_line(screen)
    end

    def render_status_line(screen)
      status = " #{@buffer.name}"
      status += " [+]" if @buffer.modified
      position = "#{@cursor_row + 1}:#{@cursor_col + 1} "
      padding = @width - status.length - position.length
      padding = 0 if padding.negative?
      full_status = status + (" " * padding) + position
      screen.put(@y + visible_height, @x, full_status[0, @width])
    end

    def screen_cursor_x
      @x + @cursor_col - @scroll_col
    end

    def screen_cursor_y
      @y + @cursor_row - @scroll_row
    end

    # カーソル移動
    def move_left
      @cursor_col -= 1 if @cursor_col.positive?
    end

    def move_right
      @cursor_col += 1 if @cursor_col < max_cursor_col
    end

    def move_up
      @cursor_row -= 1 if @cursor_row.positive?
      clamp_cursor_col
    end

    def move_down
      @cursor_row += 1 if @cursor_row < @buffer.line_count - 1
      clamp_cursor_col
    end

    def clamp_cursor_to_line(buffer)
      max_col = [buffer.line(@cursor_row).length - 1, 0].max
      @cursor_col = max_col if @cursor_col > max_col
    end

    private

    def max_cursor_col
      [@buffer.line(@cursor_row).length - 1, 0].max
    end

    def clamp_cursor_col
      @cursor_col = max_cursor_col if @cursor_col > max_cursor_col
    end
  end
end
