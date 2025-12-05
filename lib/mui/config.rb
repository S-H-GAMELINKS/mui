# frozen_string_literal: true

module Mui
  class Config
    attr_reader :options, :plugins, :keymaps, :commands, :autocmds

    def initialize
      @options = {
        colorscheme: "mui"
      }
      @plugins = []
      @keymaps = {}
      @commands = {}
      @autocmds = {}
    end

    def set(key, value)
      @options[key.to_sym] = value
    end

    def get(key)
      @options[key.to_sym]
    end

    def load_file(path)
      return unless File.exist?(path)

      instance_eval(File.read(path), path)
    end

    # Stub for future plugin support
    def use_plugin(gem_name, version = nil)
      @plugins << { gem: gem_name, version: version }
    end

    # Stub for future keymap support
    def add_keymap(mode, key, block)
      @keymaps[mode] ||= {}
      @keymaps[mode][key] = block
    end

    def add_command(name, block)
      @commands[name.to_sym] = block
    end

    def add_autocmd(event, pattern, block)
      @autocmds[event.to_sym] ||= []
      @autocmds[event.to_sym] << { pattern: pattern, handler: block }
    end
  end
end
