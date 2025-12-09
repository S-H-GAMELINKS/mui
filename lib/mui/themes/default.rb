# frozen_string_literal: true

module Mui
  module Themes
    def self.mui
      scheme = ColorScheme.new("mui")
      scheme.define :normal, fg: :white, bg: :darkgray
      scheme.define :status_line, fg: :white, bg: :blue
      scheme.define :status_line_mode, fg: :white, bg: :magenta, bold: true
      scheme.define :search_highlight, fg: :black, bg: :cyan
      scheme.define :visual_selection, fg: :white, bg: :magenta
      scheme.define :line_number, fg: :cyan, bg: :darkgray
      scheme.define :message_error, fg: :red, bg: :darkgray, bold: true
      scheme.define :message_info, fg: :cyan, bg: :darkgray
      scheme.define :separator, fg: :white, bg: :blue
      scheme.define :command_line, fg: :white, bg: :darkgray
      scheme.define :tab_bar, fg: :white, bg: :blue
      scheme.define :tab_bar_active, fg: :white, bg: :magenta, bold: true
      scheme
    end

    def self.solarized_dark
      scheme = ColorScheme.new("solarized_dark")
      scheme.define :normal, fg: :solarized_base0, bg: :solarized_base03
      scheme.define :status_line, fg: :solarized_base1, bg: :solarized_base02
      scheme.define :status_line_mode, fg: :solarized_base03, bg: :solarized_blue, bold: true
      scheme.define :search_highlight, fg: :solarized_base03, bg: :solarized_yellow
      scheme.define :visual_selection, fg: :solarized_base03, bg: :solarized_blue
      scheme.define :line_number, fg: :solarized_base01, bg: :solarized_base03
      scheme.define :message_error, fg: :solarized_red, bg: :solarized_base03, bold: true
      scheme.define :message_info, fg: :solarized_cyan, bg: :solarized_base03
      scheme.define :separator, fg: :solarized_base1, bg: :solarized_base02
      scheme.define :command_line, fg: :solarized_base0, bg: :solarized_base03
      scheme.define :tab_bar, fg: :solarized_base1, bg: :solarized_base02
      scheme.define :tab_bar_active, fg: :solarized_base03, bg: :solarized_blue, bold: true
      scheme
    end

    def self.solarized_light
      scheme = ColorScheme.new("solarized_light")
      scheme.define :normal, fg: :solarized_base00, bg: :solarized_base3
      scheme.define :status_line, fg: :solarized_base01, bg: :solarized_base2
      scheme.define :status_line_mode, fg: :solarized_base3, bg: :solarized_blue, bold: true
      scheme.define :search_highlight, fg: :solarized_base3, bg: :solarized_yellow
      scheme.define :visual_selection, fg: :solarized_base3, bg: :solarized_blue
      scheme.define :line_number, fg: :solarized_base1, bg: :solarized_base3
      scheme.define :message_error, fg: :solarized_red, bg: :solarized_base3, bold: true
      scheme.define :message_info, fg: :solarized_cyan, bg: :solarized_base3
      scheme.define :separator, fg: :solarized_base01, bg: :solarized_base2
      scheme.define :command_line, fg: :solarized_base00, bg: :solarized_base3
      scheme.define :tab_bar, fg: :solarized_base01, bg: :solarized_base2
      scheme.define :tab_bar_active, fg: :solarized_base3, bg: :solarized_blue, bold: true
      scheme
    end

    def self.monokai
      scheme = ColorScheme.new("monokai")
      scheme.define :normal, fg: :monokai_fg, bg: :monokai_bg
      scheme.define :status_line, fg: :monokai_fg, bg: :monokai_purple
      scheme.define :status_line_mode, fg: :monokai_bg, bg: :monokai_pink, bold: true
      scheme.define :search_highlight, fg: :monokai_bg, bg: :monokai_yellow
      scheme.define :visual_selection, fg: :monokai_fg, bg: :monokai_purple
      scheme.define :line_number, fg: :monokai_cyan, bg: :monokai_bg
      scheme.define :message_error, fg: :monokai_pink, bg: :monokai_bg, bold: true
      scheme.define :message_info, fg: :monokai_green, bg: :monokai_bg
      scheme.define :separator, fg: :monokai_fg, bg: :monokai_purple
      scheme.define :command_line, fg: :monokai_fg, bg: :monokai_bg
      scheme.define :tab_bar, fg: :monokai_fg, bg: :monokai_purple
      scheme.define :tab_bar_active, fg: :monokai_bg, bg: :monokai_pink, bold: true
      scheme
    end

    def self.nord
      scheme = ColorScheme.new("nord")
      scheme.define :normal, fg: :nord_snow0, bg: :nord_polar0
      scheme.define :status_line, fg: :nord_snow0, bg: :nord_polar2
      scheme.define :status_line_mode, fg: :nord_polar0, bg: :nord_frost1, bold: true
      scheme.define :search_highlight, fg: :nord_polar0, bg: :nord_aurora_yellow
      scheme.define :visual_selection, fg: :nord_snow0, bg: :nord_frost3
      scheme.define :line_number, fg: :nord_polar3, bg: :nord_polar0
      scheme.define :message_error, fg: :nord_aurora_red, bg: :nord_polar0, bold: true
      scheme.define :message_info, fg: :nord_frost1, bg: :nord_polar0
      scheme.define :separator, fg: :nord_snow0, bg: :nord_polar2
      scheme.define :command_line, fg: :nord_snow0, bg: :nord_polar0
      scheme.define :tab_bar, fg: :nord_snow0, bg: :nord_polar2
      scheme.define :tab_bar_active, fg: :nord_polar0, bg: :nord_frost1, bold: true
      scheme
    end

    def self.gruvbox_dark
      scheme = ColorScheme.new("gruvbox_dark")
      scheme.define :normal, fg: :gruvbox_fg, bg: :gruvbox_bg
      scheme.define :status_line, fg: :gruvbox_fg, bg: :gruvbox_gray
      scheme.define :status_line_mode, fg: :gruvbox_bg, bg: :gruvbox_orange, bold: true
      scheme.define :search_highlight, fg: :gruvbox_bg, bg: :gruvbox_yellow
      scheme.define :visual_selection, fg: :gruvbox_fg, bg: :gruvbox_blue
      scheme.define :line_number, fg: :gruvbox_gray, bg: :gruvbox_bg
      scheme.define :message_error, fg: :gruvbox_red, bg: :gruvbox_bg, bold: true
      scheme.define :message_info, fg: :gruvbox_aqua, bg: :gruvbox_bg
      scheme.define :separator, fg: :gruvbox_fg, bg: :gruvbox_gray
      scheme.define :command_line, fg: :gruvbox_fg, bg: :gruvbox_bg
      scheme.define :tab_bar, fg: :gruvbox_fg, bg: :gruvbox_gray
      scheme.define :tab_bar_active, fg: :gruvbox_bg, bg: :gruvbox_orange, bold: true
      scheme
    end

    def self.dracula
      scheme = ColorScheme.new("dracula")
      scheme.define :normal, fg: :dracula_fg, bg: :dracula_bg
      scheme.define :status_line, fg: :dracula_fg, bg: :dracula_selection
      scheme.define :status_line_mode, fg: :dracula_bg, bg: :dracula_purple, bold: true
      scheme.define :search_highlight, fg: :dracula_bg, bg: :dracula_yellow
      scheme.define :visual_selection, fg: :dracula_fg, bg: :dracula_purple
      scheme.define :line_number, fg: :dracula_comment, bg: :dracula_bg
      scheme.define :message_error, fg: :dracula_red, bg: :dracula_bg, bold: true
      scheme.define :message_info, fg: :dracula_cyan, bg: :dracula_bg
      scheme.define :separator, fg: :dracula_fg, bg: :dracula_selection
      scheme.define :command_line, fg: :dracula_fg, bg: :dracula_bg
      scheme.define :tab_bar, fg: :dracula_fg, bg: :dracula_selection
      scheme.define :tab_bar_active, fg: :dracula_bg, bg: :dracula_purple, bold: true
      scheme
    end

    def self.tokyo_night
      scheme = ColorScheme.new("tokyo_night")
      scheme.define :normal, fg: :tokyo_fg, bg: :tokyo_bg
      scheme.define :status_line, fg: :tokyo_fg, bg: :tokyo_comment
      scheme.define :status_line_mode, fg: :tokyo_bg, bg: :tokyo_blue, bold: true
      scheme.define :search_highlight, fg: :tokyo_bg, bg: :tokyo_yellow
      scheme.define :visual_selection, fg: :tokyo_fg, bg: :tokyo_purple
      scheme.define :line_number, fg: :tokyo_comment, bg: :tokyo_bg
      scheme.define :message_error, fg: :tokyo_red, bg: :tokyo_bg, bold: true
      scheme.define :message_info, fg: :tokyo_cyan, bg: :tokyo_bg
      scheme.define :separator, fg: :tokyo_fg, bg: :tokyo_comment
      scheme.define :command_line, fg: :tokyo_fg, bg: :tokyo_bg
      scheme.define :tab_bar, fg: :tokyo_fg, bg: :tokyo_comment
      scheme.define :tab_bar_active, fg: :tokyo_bg, bg: :tokyo_blue, bold: true
      scheme
    end
  end
end
