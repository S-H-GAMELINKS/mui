# frozen_string_literal: true

require_relative "terminal_adapter/base"
require_relative "terminal_adapter/ansi"

module Mui
  module TerminalAdapter
    # Loaded on first reference, so mui runs where the curses gem is not
    # installed or cannot be built -- the ANSI adapter needs nothing beyond
    # io/console.
    autoload :Curses, File.expand_path("terminal_adapter/curses", __dir__)

    # The adapter Editor uses when none is given. MUI_TERMINAL=ansi or
    # MUI_TERMINAL=curses chooses one; otherwise curses when it can be loaded,
    # and the ANSI adapter when it cannot.
    def self.default
      case ENV.fetch("MUI_TERMINAL", nil)
      when "ansi" then Ansi.new
      when "curses" then Curses.new
      else curses_available? ? Curses.new : Ansi.new
      end
    end

    def self.curses_available?
      require "curses"
      true
    rescue LoadError
      false
    end
  end
end
