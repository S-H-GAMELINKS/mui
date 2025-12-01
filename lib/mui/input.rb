# frozen_string_literal: true

require "curses"

module Mui
  class Input
    def read
      Curses.getch
    end

    def read_nonblock
      Curses.stdscr.nodelay = true
      key = Curses.getch
      Curses.stdscr.nodelay = false
      key
    end
  end
end
