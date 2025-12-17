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
      # mui theme - Eye-friendly gray-based theme
      mui_bg: 236,             # #303030 - Calm dark gray background
      mui_fg: 253,             # #dadada - Soft white (easy on the eyes)
      mui_comment: 102,        # #878787 - Subtle gray (for comments)
      mui_constant: 110,       # #87afd7 - Calm blue (constants/strings/numbers)
      mui_identifier: 174,     # #d78787 - Soft salmon pink
      mui_statement: 186,      # #d7d787 - Subtle yellow (keywords)
      mui_preproc: 173,        # #d7875f - Orange/brown (preprocessor)
      mui_type: 109,           # #87afaf - Calm cyan (types)
      mui_special: 180,        # #d7af87 - Soft beige (symbols)
      mui_function: 216,       # #ffaf87 - Peach/orange (functions)
      # UI colors
      mui_line_number: 243,    # #767676 - Subtle gray
      mui_status_bg: 238,      # #444444 - Status bar background
      mui_visual: 239,         # #4e4e4e - Selection background
      mui_search: 222,         # #ffd787 - Search highlight (prominent yellow)
      mui_tab_bg: 237,         # #3a3a3a - Tab bar background
      mui_tab_active: 110,     # #87afd7 - Active tab
      mui_error: 167,          # #d75f5f - Error messages
      mui_info: 109,           # #87afaf - Info messages
      darkgray: 235,           # #262626 (~#2b2b2b) - Kept for backward compatibility

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

    # Fallback map: 256-color to 8-color
    FALLBACK_MAP = {
      # mui theme
      mui_bg: :black,
      mui_fg: :white,
      mui_comment: :white,
      mui_constant: :cyan,
      mui_identifier: :red,
      mui_statement: :yellow,
      mui_preproc: :yellow,
      mui_type: :cyan,
      mui_special: :yellow,
      mui_function: :yellow,
      mui_line_number: :white,
      mui_status_bg: :blue,
      mui_visual: :magenta,
      mui_search: :yellow,
      mui_tab_bg: :blue,
      mui_tab_active: :cyan,
      mui_error: :red,
      mui_info: :cyan,
      darkgray: :black,
      # solarized
      solarized_base03: :black, solarized_base02: :black,
      solarized_base01: :white, solarized_base00: :white,
      solarized_base0: :white, solarized_base1: :white,
      solarized_base2: :white, solarized_base3: :white,
      solarized_yellow: :yellow, solarized_orange: :red,
      solarized_red: :red, solarized_magenta: :magenta,
      solarized_violet: :blue, solarized_blue: :blue,
      solarized_cyan: :cyan, solarized_green: :green,
      # monokai
      monokai_bg: :black, monokai_fg: :white,
      monokai_pink: :magenta, monokai_green: :green,
      monokai_orange: :yellow, monokai_purple: :magenta,
      monokai_cyan: :cyan, monokai_yellow: :yellow,
      # nord
      nord_polar0: :black, nord_polar1: :black,
      nord_polar2: :black, nord_polar3: :white,
      nord_snow0: :white, nord_snow1: :white, nord_snow2: :white,
      nord_frost0: :cyan, nord_frost1: :cyan,
      nord_frost2: :blue, nord_frost3: :blue,
      nord_aurora_red: :red, nord_aurora_orange: :yellow,
      nord_aurora_yellow: :yellow, nord_aurora_green: :green,
      nord_aurora_purple: :magenta,
      # gruvbox
      gruvbox_bg: :black, gruvbox_fg: :white,
      gruvbox_red: :red, gruvbox_green: :green,
      gruvbox_yellow: :yellow, gruvbox_blue: :blue,
      gruvbox_purple: :magenta, gruvbox_aqua: :cyan,
      gruvbox_orange: :yellow, gruvbox_gray: :white,
      # dracula
      dracula_bg: :black, dracula_fg: :white,
      dracula_selection: :black, dracula_comment: :blue,
      dracula_cyan: :cyan, dracula_green: :green,
      dracula_orange: :yellow, dracula_pink: :magenta,
      dracula_purple: :magenta, dracula_red: :red,
      dracula_yellow: :yellow,
      # tokyo night
      tokyo_bg: :black, tokyo_fg: :white,
      tokyo_comment: :blue, tokyo_cyan: :cyan,
      tokyo_blue: :blue, tokyo_purple: :magenta,
      tokyo_green: :green, tokyo_orange: :yellow,
      tokyo_red: :red, tokyo_yellow: :yellow
    }.freeze

    attr_reader :pairs, :supports_256_colors

    def initialize(adapter: nil)
      @pair_index = 1
      @pairs = {}
      @pair_order = []
      @adapter = adapter
      configure_color_capability
    end

    def register_pair(fg, bg)
      key = [fg, bg]

      if @pairs[key]
        touch_pair(key)
        return @pairs[key]
      end

      # Check pair limit and evict oldest if needed
      evict_oldest_pair if @max_pairs.positive? && @pair_index >= @max_pairs

      @pairs[key] = @pair_index
      @pair_order << key
      @pair_index += 1
      @pairs[key]
    end

    def get_pair_index(fg, bg)
      register_pair(fg, bg)
    end

    def color_code(color)
      return -1 if color.nil?
      return color if color.is_a?(Integer)

      resolved_color = resolve_with_fallback(color)
      COLOR_MAP[resolved_color] || EXTENDED_COLOR_MAP[resolved_color] || -1
    end

    alias resolve color_code

    private

    def configure_color_capability
      if @adapter.nil?
        # Backward compatibility: assume 256 colors when adapter is not specified
        @available_colors = 256
        @max_pairs = 256
        @supports_256_colors = true
      elsif @adapter.has_colors?
        @available_colors = @adapter.colors
        @max_pairs = [@adapter.color_pairs, 256].min
        @supports_256_colors = @available_colors >= 256
      else
        @available_colors = 0
        @max_pairs = 0
        @supports_256_colors = false
      end
    end

    def resolve_with_fallback(color)
      return color if @supports_256_colors
      return color if COLOR_MAP.key?(color)

      FALLBACK_MAP[color] || :white
    end

    def touch_pair(key)
      @pair_order.delete(key)
      @pair_order << key
    end

    def evict_oldest_pair
      oldest_key = @pair_order.shift
      @pairs.delete(oldest_key) if oldest_key
    end
  end
end
