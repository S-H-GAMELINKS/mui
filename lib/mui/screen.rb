# frozen_string_literal: true

require "curses"

module Mui
  class Screen
    attr_reader :width, :height

    def initialize
      Curses.init_screen
      Curses.raw
      Curses.noecho
      Curses.curs_set(1)
      Curses.stdscr.keypad(true)
      update_size
    end

    def refresh
      update_size
      Curses.refresh
    end

    def close
      Curses.close_screen
    end

    def clear
      Curses.clear
    end

    def put(y, x, text)
      return if y.negative?
      return if y >= @height || x >= @width

      Curses.setpos(y, x)
      max_len = @width - x
      Curses.addstr(text.length > max_len ? text[0, max_len] : text)
    end

    def put_with_highlight(y, x, text)
      return if y.negative?
      return if y >= @height || x >= @width

      Curses.setpos(y, x)
      max_len = @width - x
      Curses.attron(Curses::A_REVERSE)
      Curses.addstr(text.length > max_len ? text[0, max_len] : text)
      Curses.attroff(Curses::A_REVERSE)
    end

    def move_cursor(y, x)
      x = [[x, 0].max, @width - 1].min
      y = [[y, 0].max, @height - 1].min
      Curses.setpos(y, x)
    end

    private

    def update_size
      @width = Curses.cols
      @height = Curses.lines
    end
  end
end
