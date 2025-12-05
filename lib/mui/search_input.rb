# frozen_string_literal: true

module Mui
  class SearchInput
    attr_reader :buffer, :prompt

    def initialize(prompt = "/")
      @buffer = ""
      @prompt = prompt
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

    def set_prompt(prompt)
      @prompt = prompt
    end

    def to_s
      "#{@prompt}#{@buffer}"
    end

    def pattern
      @buffer
    end

    def empty?
      @buffer.empty?
    end
  end
end
