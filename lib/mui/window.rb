# frozen_string_literal: true

module Mui
  class Window
    attr_accessor :x, :y, :width, :height, :cursor_row, :cursor_col, :scroll_row
    attr_reader :buffer

    def initialize(buffer, x: 0, y: 0, width: 80, height: 24, color_scheme: nil)
      @buffer = buffer
      @x = x
      @y = y
      @width = width
      @height = height
      @cursor_row = 0
      @cursor_col = 0
      @scroll_row = 0
      @color_scheme = color_scheme
      @wrap_cache = WrapCache.new
      @syntax_highlighter = Highlighters::SyntaxHighlighter.new(color_scheme, buffer:)
      @line_renderer = create_line_renderer
      @status_line_renderer = StatusLineRenderer.new(buffer, self, color_scheme)
    end

    def buffer=(new_buffer)
      @buffer = new_buffer
      @cursor_row = 0
      @cursor_col = 0
      @scroll_row = 0
      @wrap_cache.clear
      @syntax_highlighter.buffer = new_buffer
      @line_renderer = create_line_renderer
      @status_line_renderer = StatusLineRenderer.new(new_buffer, self, @color_scheme)
    end

    def visible_height
      @height - 1 # Status line only (command line is shared by all windows)
    end

    def visible_width
      @width
    end

    def ensure_cursor_visible
      # Calculate screen row of cursor considering line wrapping
      cursor_screen_row = screen_rows_from_scroll_to_cursor

      # Scroll up if cursor is above visible area
      @scroll_row -= 1 while @cursor_row < @scroll_row

      # Scroll down if cursor is below visible area
      while cursor_screen_row >= visible_height
        @scroll_row += 1
        cursor_screen_row = screen_rows_from_scroll_to_cursor
      end
    end

    def render(screen, selection: nil, search_state: nil)
      options = build_render_options(selection, search_state)
      screen_row = 0
      logical_row = @scroll_row

      while screen_row < visible_height && logical_row < @buffer.line_count
        line = @buffer.line(logical_row)
        wrapped_lines = WrapHelper.wrap_line(line, visible_width, cache: @wrap_cache)

        wrapped_lines.each do |wrap_info|
          break if screen_row >= visible_height

          render_wrapped_segment(screen, logical_row, wrap_info, screen_row, options)
          screen_row += 1
        end

        logical_row += 1
      end

      # Clear remaining lines
      while screen_row < visible_height
        clear_line(screen, screen_row)
        screen_row += 1
      end

      @status_line_renderer.render(screen, @y + visible_height)
    end

    def render_wrapped_segment(screen, logical_row, wrap_info, screen_row, options)
      wrap_options = options.merge(logical_row:)
      @line_renderer.render_wrapped_line(screen, @y + screen_row, @x, wrap_info, wrap_options)

      # Fill remaining width with spaces if line is shorter
      text_width = UnicodeWidth.string_width(wrap_info[:text])
      return unless text_width < visible_width

      remaining_width = visible_width - text_width
      fill_text = " " * remaining_width
      if @color_scheme && @color_scheme[:normal]
        screen.put_with_style(@y + screen_row, @x + text_width, fill_text, @color_scheme[:normal])
      else
        screen.put(@y + screen_row, @x + text_width, fill_text)
      end
    end

    def screen_cursor_x
      line = @buffer.line(@cursor_row) || ""
      _, screen_col = WrapHelper.logical_to_screen(line, @cursor_col, visible_width, cache: @wrap_cache)
      @x + screen_col
    end

    def screen_cursor_y
      @y + screen_rows_from_scroll_to_cursor
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

    # Refresh highlighters (call when custom highlighters change)
    def refresh_highlighters
      @line_renderer = create_line_renderer
    end

    private

    def clear_line(screen, screen_row)
      empty_line = " " * visible_width
      if @color_scheme && @color_scheme[:normal]
        screen.put_with_style(@y + screen_row, @x, empty_line, @color_scheme[:normal])
      else
        screen.put(@y + screen_row, @x, empty_line)
      end
    end

    # Calculates screen rows from scroll_row to cursor position
    def screen_rows_from_scroll_to_cursor
      screen_rows = 0

      # Add screen lines for rows between scroll_row and cursor_row
      (@scroll_row...@cursor_row).each do |row|
        line = @buffer.line(row) || ""
        screen_rows += WrapHelper.screen_line_count(line, visible_width, cache: @wrap_cache)
      end

      # Add the row offset within the cursor's line
      cursor_line = @buffer.line(@cursor_row) || ""
      row_offset, = WrapHelper.logical_to_screen(cursor_line, @cursor_col, visible_width, cache: @wrap_cache)
      screen_rows + row_offset
    end

    # Clear wrap cache when window dimensions change
    def resize(new_width, new_height)
      @width = new_width
      @height = new_height
      @wrap_cache.clear
    end

    def create_line_renderer
      renderer = LineRenderer.new(@color_scheme)
      renderer.add_highlighter(@syntax_highlighter)
      renderer.add_highlighter(Highlighters::SelectionHighlighter.new(@color_scheme))
      renderer.add_highlighter(Highlighters::SearchHighlighter.new(@color_scheme))

      # Add buffer-specific custom highlighters
      @buffer.custom_highlighters(@color_scheme).each do |highlighter|
        renderer.add_highlighter(highlighter)
      end

      renderer
    end

    def build_render_options(selection, search_state)
      { selection:, search_state:, buffer: @buffer }
    end

    def max_cursor_col
      [@buffer.line(@cursor_row).length - 1, 0].max
    end

    def clamp_cursor_col
      @cursor_col = max_cursor_col if @cursor_col > max_cursor_col
    end
  end
end
