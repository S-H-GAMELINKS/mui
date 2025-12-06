# frozen_string_literal: true

module Mui
  class Window
    attr_reader :buffer
    attr_accessor :x, :y, :width, :height, :cursor_row, :cursor_col, :scroll_row, :scroll_col

    def initialize(buffer, x: 0, y: 0, width: 80, height: 24, color_scheme: nil)
      @buffer = buffer
      @x = x
      @y = y
      @width = width
      @height = height
      @cursor_row = 0
      @cursor_col = 0
      @scroll_row = 0
      @scroll_col = 0
      @color_scheme = color_scheme
      @line_renderer = create_line_renderer
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

    def render(screen, selection: nil, search_state: nil)
      options = build_render_options(selection, search_state)

      visible_height.times do |i|
        row = @scroll_row + i
        render_line(screen, row, i, options)
      end

      render_status_line(screen)
    end

    def render_line(screen, row, screen_row, options)
      line = prepare_visible_line(row)
      adjusted_options = adjust_options_for_scroll(options)
      @line_renderer.render(screen, line, row, @x, @y + screen_row, adjusted_options)
    end

    def render_status_line(screen)
      status = " #{@buffer.name}"
      status += " [+]" if @buffer.modified
      position = "#{@cursor_row + 1}:#{@cursor_col + 1} "
      padding = @width - status.length - position.length
      padding = 0 if padding.negative?
      full_status = status + (" " * padding) + position
      full_status = full_status[0, @width]

      if @color_scheme
        screen.put_with_style(@y + visible_height, @x, full_status, @color_scheme[:status_line])
      else
        screen.put(@y + visible_height, @x, full_status)
      end
    end

    def screen_cursor_x
      line = @buffer.line(@cursor_row) || ""
      # Calculate display width from scroll_col to cursor_col
      visible_text = line[@scroll_col...@cursor_col] || ""
      @x + UnicodeWidth.string_width(visible_text)
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

    def create_line_renderer
      renderer = LineRenderer.new(@color_scheme)
      renderer.add_highlighter(Highlighters::SelectionHighlighter.new(@color_scheme))
      renderer.add_highlighter(Highlighters::SearchHighlighter.new(@color_scheme))
      renderer
    end

    def prepare_visible_line(row)
      line = @buffer.line(row)
      visible_line = @scroll_col < line.length ? line[@scroll_col, visible_width] || "" : ""
      visible_line.ljust(visible_width)
    end

    def build_render_options(selection, search_state)
      { selection:, search_state:, scroll_col: @scroll_col }
    end

    def adjust_options_for_scroll(options)
      return options unless options[:selection] || options[:search_state]

      adjusted = options.dup
      adjusted[:scroll_col] = @scroll_col
      adjusted
    end

    def max_cursor_col
      [@buffer.line(@cursor_row).length - 1, 0].max
    end

    def clamp_cursor_col
      @cursor_col = max_cursor_col if @cursor_col > max_cursor_col
    end
  end
end
