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
      else
        { action: :unknown, command: cmd }
      end
    end
  end
end
