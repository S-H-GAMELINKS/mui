# frozen_string_literal: true

module Mui
  class ColorManager
    # Standard 8 colors
    COLOR_MAP = {
      black: 0,
      red: 1,
      green: 2,
      yellow: 3,
      blue: 4,
      magenta: 5,
      cyan: 6,
      white: 7
    }.freeze

    # 256-color palette extended colors
    # Use https://www.ditig.com/256-colors-cheat-sheet for reference
    EXTENDED_COLOR_MAP = {
      # mui theme
      darkgray: 235, # #262626 (~#2b2b2b)

      # solarized
      solarized_base03: 234,   # #1c1c1c (~#002b36)
      solarized_base02: 235,   # #262626 (~#073642)
      solarized_base01: 240,   # #585858 (~#586e75)
      solarized_base00: 241,   # #626262 (~#657b83)
      solarized_base0: 244,    # #808080 (~#839496)
      solarized_base1: 245,    # #8a8a8a (~#93a1a1)
      solarized_base2: 254,    # #e4e4e4 (~#eee8d5)
      solarized_base3: 230,    # #ffffd7 (~#fdf6e3)
      solarized_yellow: 136,   # #af8700 (~#b58900)
      solarized_orange: 166,   # #d75f00 (~#cb4b16)
      solarized_red: 160,      # #d70000 (~#dc322f)
      solarized_magenta: 125,  # #af005f (~#d33682)
      solarized_violet: 61,    # #5f5faf (~#6c71c4)
      solarized_blue: 33,      # #0087ff (~#268bd2)
      solarized_cyan: 37,      # #00afaf (~#2aa198)
      solarized_green: 64,     # #5f8700 (~#859900)

      # monokai
      monokai_bg: 235,         # #262626 (~#272822)
      monokai_fg: 231,         # #ffffff (~#f8f8f2)
      monokai_pink: 197,       # #ff005f (~#f92672)
      monokai_green: 148,      # #afd700 (~#a6e22e)
      monokai_orange: 208,     # #ff8700 (~#fd971f)
      monokai_purple: 141,     # #af87ff (~#ae81ff)
      monokai_cyan: 81,        # #5fd7ff (~#66d9ef)
      monokai_yellow: 186,     # #d7d787 (~#e6db74)

      # nord
      nord_polar0: 236,        # #303030 (~#2e3440)
      nord_polar1: 238,        # #444444 (~#3b4252)
      nord_polar2: 239,        # #4e4e4e (~#434c5e)
      nord_polar3: 240,        # #585858 (~#4c566a)
      nord_snow0: 253,         # #dadada (~#d8dee9)
      nord_snow1: 254,         # #e4e4e4 (~#e5e9f0)
      nord_snow2: 255,         # #eeeeee (~#eceff4)
      nord_frost0: 109,        # #87afaf (~#8fbcbb)
      nord_frost1: 110,        # #87afd7 (~#88c0d0)
      nord_frost2: 111,        # #87afff (~#81a1c1)
      nord_frost3: 68,         # #5f87d7 (~#5e81ac)
      nord_aurora_red: 167,    # #d75f5f (~#bf616a)
      nord_aurora_orange: 208, # #ff8700 (~#d08770)
      nord_aurora_yellow: 179, # #d7af5f (~#ebcb8b)
      nord_aurora_green: 108,  # #87af87 (~#a3be8c)
      nord_aurora_purple: 139, # #af87af (~#b48ead)

      # gruvbox
      gruvbox_bg: 235,         # #262626 (~#282828)
      gruvbox_fg: 223,         # #ffd7af (~#ebdbb2)
      gruvbox_red: 124,        # #af0000 (~#cc241d)
      gruvbox_green: 106,      # #87af00 (~#98971a)
      gruvbox_yellow: 172,     # #d78700 (~#d79921)
      gruvbox_blue: 66,        # #5f8787 (~#458588)
      gruvbox_purple: 132,     # #af5f87 (~#b16286)
      gruvbox_aqua: 72,        # #5faf87 (~#689d6a)
      gruvbox_orange: 166,     # #d75f00 (~#d65d0e)
      gruvbox_gray: 245,       # #8a8a8a (~#928374)

      # dracula
      dracula_bg: 236,         # #303030 (~#282a36)
      dracula_fg: 231,         # #ffffff (~#f8f8f2)
      dracula_selection: 239,  # #4e4e4e (~#44475a)
      dracula_comment: 61,     # #5f5faf (~#6272a4)
      dracula_cyan: 117,       # #87d7ff (~#8be9fd)
      dracula_green: 84,       # #5fdf5f (~#50fa7b)
      dracula_orange: 215,     # #ffaf5f (~#ffb86c)
      dracula_pink: 212,       # #ff87d7 (~#ff79c6)
      dracula_purple: 141,     # #af87ff (~#bd93f9)
      dracula_red: 203,        # #ff5f5f (~#ff5555)
      dracula_yellow: 228,     # #ffff87 (~#f1fa8c)

      # tokyo night
      tokyo_bg: 234,           # #1c1c1c (~#1a1b26)
      tokyo_fg: 146,           # #afafd7 (~#a9b1d6)
      tokyo_comment: 60,       # #5f5f87 (~#565f89)
      tokyo_cyan: 115,         # #87d7af (~#7dcfff)
      tokyo_blue: 75,          # #5fafff (~#7aa2f7)
      tokyo_purple: 140,       # #af87d7 (~#bb9af7)
      tokyo_green: 108,        # #87af87 (~#9ece6a)
      tokyo_orange: 215,       # #ffaf5f (~#ff9e64)
      tokyo_red: 203,          # #ff5f5f (~#f7768e)
      tokyo_yellow: 223        # #ffd7af (~#e0af68)
    }.freeze

    attr_reader :pairs

    def initialize
      @pair_index = 1
      @pairs = {}
    end

    def register_pair(fg, bg)
      key = [fg, bg]
      return @pairs[key] if @pairs[key]

      @pairs[key] = @pair_index
      @pair_index += 1
      @pairs[key]
    end

    def get_pair_index(fg, bg)
      register_pair(fg, bg)
    end

    def color_code(color)
      return -1 if color.nil?
      return color if color.is_a?(Integer)

      COLOR_MAP[color] || EXTENDED_COLOR_MAP[color] || -1
    end

    alias resolve color_code
  end
end
