# frozen_string_literal: true

module Mui
  # Manages yank/delete registers for copy/paste operations
  # Supports Vim-compatible registers:
  # - "" (unnamed): default register
  # - "a-"z: named registers
  # - "0: yank register (stores last yank, not affected by delete)
  # - "1-"9: delete history (shifted on each delete)
  # - "_: black hole register (discards content)
  class Register
    YANK_REGISTER = "0"
    DELETE_HISTORY_REGISTERS = ("1".."9").to_a.freeze
    BLACK_HOLE_REGISTER = "_"
    UNNAMED_REGISTER = '"'
    NAMED_REGISTERS = ("a".."z").to_a.freeze

    def initialize
      @unnamed = { content: nil, linewise: false }
      @yank_register = { content: nil, linewise: false }
      @delete_history = []
      @named_registers = {}
    end

    # Store text from yank operation
    # Saves to unnamed register and "0 (yank register)
    def yank(text, linewise: false, name: nil)
      return if name == BLACK_HOLE_REGISTER

      if name && NAMED_REGISTERS.include?(name)
        @named_registers[name] = { content: text, linewise: linewise }
      else
        @unnamed = { content: text, linewise: linewise }
        @yank_register = { content: text, linewise: linewise }
      end
    end

    # Store text from delete operation
    # Saves to unnamed register and shifts delete history ("1-"9)
    def delete(text, linewise: false, name: nil)
      return if name == BLACK_HOLE_REGISTER

      if name && NAMED_REGISTERS.include?(name)
        @named_registers[name] = { content: text, linewise: linewise }
      else
        @unnamed = { content: text, linewise: linewise }
        shift_delete_history(text, linewise)
      end
    end

    # Legacy method for backward compatibility
    def set(text, linewise: false, name: nil)
      if name
        @named_registers[name] = { content: text, linewise: linewise }
      else
        @unnamed = { content: text, linewise: linewise }
      end
    end

    def get(name: nil)
      case name
      when nil, UNNAMED_REGISTER
        @unnamed[:content]
      when YANK_REGISTER
        @yank_register[:content]
      when *DELETE_HISTORY_REGISTERS
        index = name.to_i - 1
        @delete_history[index]&.fetch(:content, nil)
      when BLACK_HOLE_REGISTER
        nil
      when *NAMED_REGISTERS
        @named_registers[name]&.fetch(:content, nil)
      end
    end

    def linewise?(name: nil)
      case name
      when nil, UNNAMED_REGISTER
        @unnamed[:linewise]
      when YANK_REGISTER
        @yank_register[:linewise]
      when *DELETE_HISTORY_REGISTERS
        index = name.to_i - 1
        @delete_history[index]&.fetch(:linewise, false) || false
      when BLACK_HOLE_REGISTER
        false
      when *NAMED_REGISTERS
        @named_registers[name]&.fetch(:linewise, false) || false
      else
        false
      end
    end

    def empty?(name: nil)
      get(name: name).nil?
    end

    # For backward compatibility
    def linewise
      @unnamed[:linewise]
    end

    private

    def shift_delete_history(text, linewise)
      @delete_history.unshift({ content: text, linewise: linewise })
      @delete_history = @delete_history.first(9)
    end
  end
end
