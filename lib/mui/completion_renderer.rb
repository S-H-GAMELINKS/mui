# frozen_string_literal: true

module Mui
  # Renders completion popup menu
  class CompletionRenderer
    MAX_VISIBLE_ITEMS = 10

    def initialize(screen, color_scheme)
      @screen = screen
      @color_scheme = color_scheme
    end

    def render(completion_state, base_row, base_col)
      return unless completion_state.active?

      candidates = completion_state.candidates
      selected_index = completion_state.selected_index

      # Calculate visible window
      visible_start, visible_end = calculate_visible_range(candidates.length, selected_index)
      visible_candidates = candidates[visible_start...visible_end]

      # Calculate popup dimensions
      max_width = calculate_max_width(visible_candidates)
      popup_height = visible_candidates.length

      # Calculate position (popup appears above the command line)
      popup_row = base_row - popup_height
      popup_col = base_col

      # Ensure popup stays within screen bounds
      popup_col = [@screen.width - max_width - 1, popup_col].min
      popup_col = [0, popup_col].max
      popup_row = [0, popup_row].max

      # Render each visible candidate
      visible_candidates.each_with_index do |candidate, i|
        actual_index = visible_start + i
        is_selected = actual_index == selected_index

        render_item(
          candidate,
          popup_row + i,
          popup_col,
          max_width,
          is_selected
        )
      end
    end

    private

    def calculate_visible_range(total_count, selected_index)
      return [0, total_count] if total_count <= MAX_VISIBLE_ITEMS

      # Try to center the selected item
      half = MAX_VISIBLE_ITEMS / 2
      start_index = selected_index - half
      start_index = [0, start_index].max
      end_index = start_index + MAX_VISIBLE_ITEMS
      end_index = [total_count, end_index].min
      start_index = end_index - MAX_VISIBLE_ITEMS

      [start_index, end_index]
    end

    def calculate_max_width(candidates)
      return 0 if candidates.empty?

      candidates.map { |c| display_width(c) }.max + 2 # +2 for padding
    end

    def display_width(text)
      UnicodeWidth.string_width(text)
    end

    def render_item(text, row, col, width, selected)
      style_key = selected ? :completion_popup_selected : :completion_popup
      style = @color_scheme[style_key]
      padded_text = " #{text}".ljust(width)
      @screen.put_with_style(row, col, padded_text, style)
    end
  end
end
