# frozen_string_literal: true

module Mui
  # A floating window (popup) for displaying temporary content like hover info
  class FloatingWindow
    attr_reader :content, :row, :col, :width, :height, :last_bounds
    attr_accessor :visible

    def initialize(color_scheme)
      @color_scheme = color_scheme
      @content = []
      @row = 0
      @col = 0
      @width = 0
      @height = 0
      @visible = false
      @scroll_offset = 0
      @last_bounds = nil
      @needs_clear = false
    end

    # Show the floating window with content at the specified position
    def show(content, row:, col:, max_width: nil, max_height: nil)
      @content = normalize_content(content)
      @row = row
      @col = col
      @max_width = max_width
      @max_height = max_height
      @scroll_offset = 0
      calculate_dimensions
      @visible = true
      @needs_clear = false
    end

    # Hide the floating window
    def hide
      return unless @visible

      # Record bounds for clearing on next render
      @last_bounds = {
        row: @row,
        col: @col,
        width: @width,
        height: @height
      }
      @needs_clear = true
      @visible = false
      @content = []
    end

    # Check if the previous window area needs to be cleared
    def needs_clear?
      @needs_clear && @last_bounds
    end

    # Clear the area where the floating window was previously displayed
    def clear_last_bounds(screen)
      return unless needs_clear?

      bounds = @last_bounds
      adjusted_row, adjusted_col = adjust_position_for_bounds(screen, bounds)

      bounds[:height].times do |i|
        row = adjusted_row + i
        next if row.negative? || row >= screen.height

        spaces = " " * bounds[:width]
        screen.put(row, adjusted_col, spaces)
      end

      @needs_clear = false
      @last_bounds = nil
    end

    # Scroll content up
    def scroll_up
      @scroll_offset = [@scroll_offset - 1, 0].max if @visible
    end

    # Scroll content down
    def scroll_down
      max_offset = [@content.length - @height, 0].max
      @scroll_offset = [@scroll_offset + 1, max_offset].min if @visible
    end

    # Render the floating window to the screen
    def render(screen)
      return unless @visible
      return if @content.empty?

      # Adjust position to fit within screen bounds
      adjusted_row, adjusted_col = adjust_position(screen)

      # Draw border and content
      draw_border(screen, adjusted_row, adjusted_col)
      draw_content(screen, adjusted_row, adjusted_col)
    end

    private

    def normalize_content(content)
      case content
      when String
        content.split("\n")
      when Array
        content.flat_map { |line| line.to_s.split("\n") }
      else
        [content.to_s]
      end
    end

    def calculate_dimensions
      return if @content.empty?

      # Calculate content dimensions
      content_width = @content.map { |line| UnicodeWidth.string_width(line) }.max || 0
      content_height = @content.length

      # Apply max constraints (+2 for border)
      @width = content_width + 2
      @width = [@width, @max_width].min if @max_width

      @height = content_height + 2
      @height = [@height, @max_height].min if @max_height
    end

    def adjust_position(screen)
      row = @row
      col = @col

      # Adjust horizontal position
      col = screen.width - @width if col + @width > screen.width
      col = [col, 0].max

      # Adjust vertical position - prefer below cursor, but go above if not enough space
      if row + @height > screen.height
        # Try above the original position
        row = @row - @height
      end
      row = [row, 0].max

      [row, col]
    end

    def adjust_position_for_bounds(screen, bounds)
      row = bounds[:row]
      col = bounds[:col]

      # Adjust horizontal position
      col = screen.width - bounds[:width] if col + bounds[:width] > screen.width
      col = [col, 0].max

      # Adjust vertical position
      row = bounds[:row] - bounds[:height] if row + bounds[:height] > screen.height
      row = [row, 0].max

      [row, col]
    end

    def draw_border(screen, row, col)
      style = @color_scheme[:floating_window] || @color_scheme[:completion_popup]

      # Top border
      top_border = "┌#{"─" * (@width - 2)}┐"
      screen.put_with_style(row, col, top_border, style)

      # Side borders
      inner_height = @height - 2
      inner_height.times do |i|
        screen.put_with_style(row + 1 + i, col, "│", style)
        screen.put_with_style(row + 1 + i, col + @width - 1, "│", style)
      end

      # Bottom border
      bottom_border = "└#{"─" * (@width - 2)}┘"
      screen.put_with_style(row + @height - 1, col, bottom_border, style)
    end

    def draw_content(screen, row, col)
      style = @color_scheme[:floating_window] || @color_scheme[:completion_popup]
      inner_width = @width - 2
      inner_height = @height - 2

      inner_height.times do |i|
        line_index = @scroll_offset + i
        line = @content[line_index] || ""

        # Truncate line if needed
        display_line = truncate_to_width(line, inner_width)
        padded_line = display_line.ljust(inner_width)

        screen.put_with_style(row + 1 + i, col + 1, padded_line, style)
      end
    end

    def truncate_to_width(text, max_width)
      return text if UnicodeWidth.string_width(text) <= max_width

      result = ""
      current_width = 0

      text.each_char do |char|
        char_width = UnicodeWidth.char_width(char)
        break if current_width + char_width > max_width

        result += char
        current_width += char_width
      end

      result
    end
  end
end
