# frozen_string_literal: true

module Mui
  class Error < StandardError; end

  # Raised when a subclass does not override a required method
  class MethodNotOverriddenError < Error
    def initialize(method_name)
      super("Subclass must implement ##{method_name}")
    end
  end

  # Raised when a plugin operation fails
  class PluginError < Error; end

  # Raised when a plugin is not found
  class PluginNotFoundError < PluginError
    def initialize(plugin_name)
      super("Plugin '#{plugin_name}' not found")
    end
  end

  # Raised when an unknown command is executed
  class UnknownCommandError < Error
    def initialize(command_name)
      super("Unknown command: #{command_name}")
    end
  end
end
