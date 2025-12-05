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
      visible_height.times do |i|
        row = @scroll_row + i
        render_line(screen, row, i, selection, search_state)
      end

      render_status_line(screen)
    end

    def render_line(screen, row, screen_row, selection, search_state = nil)
      line = @buffer.line(row)
      visible_line = if @scroll_col < line.length
                       line[@scroll_col, visible_width] || ""
                     else
                       ""
                     end
      padded_line = visible_line.ljust(visible_width)

      if selection
        render_line_with_selection(screen, row, screen_row, padded_line, selection)
      elsif search_state&.has_pattern?
        render_line_with_search_highlight(screen, row, screen_row, padded_line, search_state)
      else
        put_normal_text(screen, @y + screen_row, @x, padded_line)
      end
    end

    def render_line_with_selection(screen, row, screen_row, padded_line, selection)
      range = selection.normalized_range

      if selection.line_mode
        render_visual_line_mode_selection(screen, row, screen_row, padded_line, range)
      else
        render_visual_mode_selection(screen, row, screen_row, padded_line, range)
      end
    end

    def render_visual_line_mode_selection(screen, row, screen_row, padded_line, range)
      if row.between?(range[:start_row], range[:end_row])
        put_visual_highlight(screen, @y + screen_row, @x, padded_line)
      else
        put_normal_text(screen, @y + screen_row, @x, padded_line)
      end
    end

    def render_visual_mode_selection(screen, row, screen_row, padded_line, range)
      if row < range[:start_row] || row > range[:end_row]
        put_normal_text(screen, @y + screen_row, @x, padded_line)
        return
      end

      start_col, end_col = calculate_selection_columns(row, range, padded_line.length)
      render_line_segments(screen, screen_row, padded_line, start_col, end_col)
    end

    def calculate_selection_columns(row, range, line_length)
      start_col = row == range[:start_row] ? [range[:start_col] - @scroll_col, 0].max : 0
      end_col = row == range[:end_row] ? [range[:end_col] - @scroll_col, line_length - 1].min : line_length - 1
      [start_col, end_col]
    end

    def render_line_segments(screen, screen_row, padded_line, start_col, end_col)
      put_normal_text(screen, @y + screen_row, @x, padded_line[0, start_col]) if start_col.positive?
      put_visual_highlight(screen, @y + screen_row, @x + start_col, padded_line[start_col..end_col])
      remaining_start = end_col + 1
      return unless remaining_start < padded_line.length

      put_normal_text(screen, @y + screen_row, @x + remaining_start,
                      padded_line[remaining_start..])
    end

    def render_line_with_search_highlight(screen, row, screen_row, padded_line, search_state)
      matches = search_state.matches_for_row(row)
      if matches.empty?
        put_normal_text(screen, @y + screen_row, @x, padded_line)
        return
      end

      render_line_with_multiple_highlights(screen, screen_row, padded_line, matches)
    end

    def render_line_with_multiple_highlights(screen, screen_row, padded_line, matches)
      current_pos = 0
      sorted_matches = matches.sort_by { |m| m[:col] }

      sorted_matches.each do |match|
        # Adjust for horizontal scroll
        start_col = match[:col] - @scroll_col
        end_col = match[:end_col] - @scroll_col

        next if end_col.negative? || start_col >= padded_line.length

        start_col = [start_col, 0].max
        end_col = [end_col, padded_line.length - 1].min

        # Render text before this match
        put_normal_text(screen, @y + screen_row, @x + current_pos, padded_line[current_pos...start_col]) if current_pos < start_col

        # Render the highlighted match
        put_search_highlight(screen, @y + screen_row, @x + start_col, padded_line[start_col..end_col])
        current_pos = end_col + 1
      end

      # Render remaining text after all matches
      return unless current_pos < padded_line.length

      put_normal_text(screen, @y + screen_row, @x + current_pos, padded_line[current_pos..])
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

    def max_cursor_col
      [@buffer.line(@cursor_row).length - 1, 0].max
    end

    def clamp_cursor_col
      @cursor_col = max_cursor_col if @cursor_col > max_cursor_col
    end

    def put_visual_highlight(screen, y, x, text)
      if @color_scheme
        screen.put_with_style(y, x, text, @color_scheme[:visual_selection])
      else
        screen.put_with_highlight(y, x, text)
      end
    end

    def put_search_highlight(screen, y, x, text)
      if @color_scheme
        screen.put_with_style(y, x, text, @color_scheme[:search_highlight])
      else
        screen.put_with_highlight(y, x, text)
      end
    end

    def put_normal_text(screen, y, x, text)
      if @color_scheme
        screen.put_with_style(y, x, text, @color_scheme[:normal])
      else
        screen.put(y, x, text)
      end
    end
  end
end
