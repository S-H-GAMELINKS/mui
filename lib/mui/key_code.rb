# frozen_string_literal: true

module Mui
  # Key code constants for terminal input handling
  module KeyCode
    ESCAPE = 27
    BACKSPACE = 127
    ENTER_CR = 13
    ENTER_LF = 10
    PRINTABLE_MIN = 32
    # Extended to support Unicode characters (including CJK)
    # 0x10FFFF is the maximum valid Unicode code point
    PRINTABLE_MAX = 0x10FFFF
  end
end
