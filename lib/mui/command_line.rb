# frozen_string_literal: true

module Mui
  class CommandLine
    attr_reader :buffer

    def initialize
      @buffer = ""
    end

    def input(char)
      @buffer += char
    end

    def backspace
      @buffer = @buffer.chop
    end

    def clear
      @buffer = ""
    end

    def execute
      result = parse(@buffer)
      @buffer = ""
      result
    end

    def to_s
      ":#{@buffer}"
    end

    private

    def parse(cmd)
      case cmd.strip
      when "e"
        { action: :open }
      when /^e\s+(.+)/
        { action: :open_as, path: ::Regexp.last_match(1) }
      when "w"
        { action: :write }
      when "q"
        { action: :quit }
      when "wq"
        { action: :write_quit }
      when "q!"
        { action: :force_quit }
      when /^w\s+(.+)/
        { action: :write_as, path: ::Regexp.last_match(1) }
      when "sp", "split"
        { action: :split_horizontal }
      when /^sp\s+(.+)/, /^split\s+(.+)/
        { action: :split_horizontal, path: ::Regexp.last_match(1) }
      when "vs", "vsplit"
        { action: :split_vertical }
      when /^vs\s+(.+)/, /^vsplit\s+(.+)/
        { action: :split_vertical, path: ::Regexp.last_match(1) }
      when "close"
        { action: :close_window }
      when "only"
        { action: :only_window }
      when "tabnew", "tabe", "tabedit"
        { action: :tab_new }
      when /^tabnew\s+(.+)/, /^tabe\s+(.+)/, /^tabedit\s+(.+)/
        { action: :tab_new, path: ::Regexp.last_match(1) }
      when "tabclose", "tabc"
        { action: :tab_close }
      when "tabnext", "tabn"
        { action: :tab_next }
      when "tabprev", "tabp", "tabprevious"
        { action: :tab_prev }
      when "tabfirst", "tabf", "tabrewind", "tabr"
        { action: :tab_first }
      when "tablast", "tabl"
        { action: :tab_last }
      when /^tabmove\s+(\d+)/, /^tabm\s+(\d+)/
        { action: :tab_move, position: ::Regexp.last_match(1).to_i }
      when /^(\d+)tabn(?:ext)?/, /^tabn(?:ext)?\s+(\d+)/
        { action: :tab_go, index: ::Regexp.last_match(1).to_i - 1 }
      else
        { action: :unknown, command: cmd }
      end
    end
  end
end
