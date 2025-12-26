# frozen_string_literal: true

module Mui
  class Config
    attr_reader :options, :plugins, :keymaps, :commands, :autocmds

    def initialize
      @options = {
        colorscheme: "mui",
        syntax: true, # Enable/disable syntax highlighting
        shiftwidth: 2, # Indent width for > and < commands
        expandtab: true, # Use spaces instead of tabs
        tabstop: 8, # Tab display width
        reselect_after_indent: false, # Keep selection after > / < in visual mode
        leader: "\\", # Leader key for key mappings (default: backslash)
        timeoutlen: 1000, # Timeout for multi-key sequences in milliseconds
        use_yjit: true, # Enable YJIT
        clipboard: nil # Clipboard integration (:unnamed or :unnamedplus to enable)
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
      @plugins << { gem: gem_name, version: }
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
      @autocmds[event.to_sym] << { pattern:, handler: block }
    end
  end
end
