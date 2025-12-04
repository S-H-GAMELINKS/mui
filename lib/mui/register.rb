# frozen_string_literal: true

module Mui
  # Manages yank/delete registers for copy/paste operations
  class Register
    attr_reader :linewise

    def initialize
      @content = nil
      @linewise = false
      @named_registers = {}
    end

    def set(text, linewise: false, name: nil)
      if name
        @named_registers[name] = { content: text, linewise: linewise }
      else
        @content = text
        @linewise = linewise
      end
    end

    def get(name: nil)
      if name
        reg = @named_registers[name]
        reg ? reg[:content] : nil
      else
        @content
      end
    end

    def linewise?(name: nil)
      if name
        reg = @named_registers[name]
        reg ? reg[:linewise] : false
      else
        @linewise
      end
    end

    def empty?(name: nil)
      get(name: name).nil?
    end
  end
end
