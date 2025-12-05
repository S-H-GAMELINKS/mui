# frozen_string_literal: true

module Mui
  # Base class for class-based plugins
  class Plugin
    class << self
      attr_accessor :plugin_name, :plugin_dependencies

      def name(n)
        @plugin_name = n
      end

      def depends_on(*deps)
        @plugin_dependencies = deps
      end
    end

    def setup
      # Override in subclass: plugin initialization
    end

    # API shortcuts
    def command(name, &)
      Mui.command(name, &)
    end

    def keymap(mode, key, &)
      Mui.keymap(mode, key, &)
    end

    def autocmd(event, pattern: nil, &)
      Mui.autocmd(event, pattern: pattern, &)
    end
  end
end
