# frozen_string_literal: true

require "curses"

module Mui
  module TerminalAdapter
    # Curses-based terminal adapter for production use
    class Curses < Base
      def init
        ::Curses.init_screen
        ::Curses.raw
        ::Curses.noecho
        ::Curses.curs_set(1)
        ::Curses.stdscr.keypad(true)
      end

      def close
        ::Curses.close_screen
      end

      def clear
        ::Curses.clear
      end

      def refresh
        ::Curses.refresh
      end

      def width
        ::Curses.cols
      end

      def height
        ::Curses.lines
      end

      def setpos(y, x)
        ::Curses.setpos(y, x)
      end

      def addstr(str)
        ::Curses.addstr(str)
      end

      def with_highlight
        ::Curses.attron(::Curses::A_REVERSE)
        result = yield
        ::Curses.attroff(::Curses::A_REVERSE)
        result
      end

      def getch
        ::Curses.getch
      end

      def getch_nonblock
        ::Curses.stdscr.nodelay = true
        key = ::Curses.getch
        ::Curses.stdscr.nodelay = false
        key
      end
    end
  end
end
