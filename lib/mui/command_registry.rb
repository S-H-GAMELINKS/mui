# frozen_string_literal: true

module Mui
  # Registry for Ex commands
  class CommandRegistry
    def initialize
      @commands = {}
    end

    def register(name, &block)
      @commands[name.to_sym] = block
    end

    def execute(name, context, *)
      command = @commands[name.to_sym]
      raise UnknownCommandError, name unless command

      command.call(context, *)
    end

    def exists?(name)
      @commands.key?(name.to_sym)
    end
  end
end
