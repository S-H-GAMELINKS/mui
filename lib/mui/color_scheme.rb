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
      completion_popup
      completion_popup_selected
      syntax_keyword
      syntax_string
      syntax_comment
      syntax_number
      syntax_symbol
      syntax_constant
      syntax_operator
      syntax_identifier
      syntax_preprocessor
      syntax_instance_variable
      syntax_global_variable
      syntax_method_call
      syntax_type
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
