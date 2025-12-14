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
      command = find(name)
      raise UnknownCommandError, name unless command

      command.call(context, *)
    end

    def exists?(name)
      @commands.key?(name.to_sym) || plugin_command_exists?(name)
    end

    def find(name)
      # Built-in commands take precedence
      command = @commands[name.to_sym]
      return command if command

      # Fall back to plugin commands
      plugin_commands[name.to_sym]
    end

    private

    def plugin_command_exists?(name)
      plugin_commands.key?(name.to_sym)
    end

    def plugin_commands
      Mui.config.commands
    end
  end
end
