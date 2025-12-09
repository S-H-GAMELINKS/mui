# frozen_string_literal: true

module Mui
  # Renders the tab bar at the top of the screen
  class TabBarRenderer
    TAB_BAR_HEIGHT = 1
    SEPARATOR_HEIGHT = 1
    TAB_SEPARATOR = " | "
    SEPARATOR_CHAR = "─"

    def initialize(tab_manager, color_scheme: nil)
      @tab_manager = tab_manager
      @color_scheme = color_scheme
    end

    def render(screen, row = 0)
      return unless should_render?

      render_tabs(screen, row)
      render_separator_line(screen, row + TAB_BAR_HEIGHT)
    end

    def height
      should_render? ? TAB_BAR_HEIGHT + SEPARATOR_HEIGHT : 0
    end

    private

    def should_render?
      @tab_manager.tab_count > 1
    end

    def render_tabs(screen, row)
      col = 0

      @tab_manager.tabs.each_with_index do |tab, i|
        # Add separator between tabs
        if i.positive?
          screen.put_with_style(row, col, TAB_SEPARATOR, tab_bar_style)
          col += TAB_SEPARATOR.length
        end

        # Render tab with appropriate style
        tab_text = build_tab_text(tab, i)
        style = i == @tab_manager.current_index ? tab_bar_active_style : tab_bar_style
        screen.put_with_style(row, col, tab_text, style)
        col += tab_text.length
      end

      # Fill remaining space with tab bar style
      remaining = screen.width - col
      screen.put_with_style(row, col, " " * remaining, tab_bar_style) if remaining.positive?
    end

    def render_separator_line(screen, row)
      separator_line = SEPARATOR_CHAR * screen.width
      screen.put_with_style(row, 0, separator_line, separator_style)
    end

    def build_tab_text(tab, index)
      marker = index == @tab_manager.current_index ? "*" : " "
      "#{marker}#{index + 1}:#{truncate_name(tab.display_name, 15)}"
    end

    def truncate_name(name, max_length)
      return name if name.length <= max_length

      "#{name[0, max_length - 1]}~"
    end

    def tab_bar_style
      @color_scheme&.[](:tab_bar) || @color_scheme&.[](:status_line) || default_style
    end

    def tab_bar_active_style
      @color_scheme&.[](:tab_bar_active) || @color_scheme&.[](:status_line_mode) || default_style
    end

    def separator_style
      @color_scheme&.[](:separator) || @color_scheme&.[](:status_line) || default_style
    end

    def default_style
      { fg: :white, bg: :blue, bold: false, underline: false }
    end
  end
end
