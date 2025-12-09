# frozen_string_literal: true

module Mui
  class ColorScheme
    ELEMENTS = %i[
      normal
      status_line
      status_line_mode
      search_highlight
      visual_selection
      line_number
      message_error
      message_info
      tab_bar
      tab_bar_active
    ].freeze

    attr_reader :name, :colors

    def initialize(name)
      @name = name
      @colors = {}
    end

    def define(element, fg:, bg: nil, bold: false, underline: false)
      @colors[element] = {
        fg:,
        bg:,
        bold:,
        underline:
      }
    end

    def [](element)
      @colors[element] || default_color
    end

    private

    def default_color
      { fg: :white, bg: nil, bold: false, underline: false }
    end
  end
end
