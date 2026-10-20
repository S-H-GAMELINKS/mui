# frozen_string_literal: true

module Mui
  # Key code constants for terminal input handling
  module KeyCode
    ESCAPE = 27
    BACKSPACE = 127
    ENTER_CR = 13
    ENTER_LF = 10
    TAB = 9
    PRINTABLE_MIN = 32
    # Extended to support Unicode characters (including CJK)
    # 0x10FFFF is the maximum valid Unicode code point
    PRINTABLE_MAX = 0x10FFFF

    # Control key codes (Ctrl+letter)
    CTRL_SPACE = 0 # Also Ctrl+@ (NUL)
    CTRL_C = 3
    CTRL_H = 8   # Also backspace in some terminals
    CTRL_J = 10  # Also newline
    CTRL_K = 11
    CTRL_L = 12
    CTRL_N = 14
    CTRL_O = 15
    CTRL_P = 16
    CTRL_S = 19
    CTRL_V = 22
    CTRL_W = 23

    # Shift key codes (Shift+letter)
    SHIFT_LEFT = 393
    SHIFT_RIGHT = 402
    SHIFT_TAB = 353

    # Special keys, with the values curses uses for them, so a key read through
    # the curses adapter and one decoded by the ANSI adapter compare equal.
    # Key handlers refer to these rather than to KeyCode::KEY_*, which keeps
    # curses out of everything but the adapter that uses it.
    KEY_DOWN = 258
    KEY_UP = 259
    KEY_LEFT = 260
    KEY_RIGHT = 261
    KEY_HOME = 262
    KEY_BACKSPACE = 263
    KEY_DC = 330 # Delete
    KEY_NPAGE = 338 # Page Down
    KEY_PPAGE = 339 # Page Up
    KEY_ENTER = 343
    KEY_BTAB = 353 # Shift+Tab
    KEY_END = 360
    KEY_RESIZE = 410
  end
end
