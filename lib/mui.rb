# frozen_string_literal: true

require_relative "mui/version"
require_relative "mui/error"
require_relative "mui/key_code"
require_relative "mui/key_notation_parser"
require_relative "mui/key_sequence"
require_relative "mui/key_sequence_buffer"
require_relative "mui/key_sequence_matcher"
require_relative "mui/key_sequence_handler"
require_relative "mui/unicode_width"
require_relative "mui/wrap_cache"
require_relative "mui/wrap_helper"
require_relative "mui/config"
require_relative "mui/color_scheme"
require_relative "mui/color_manager"
require_relative "mui/themes/default"
require_relative "mui/terminal_adapter"
require_relative "mui/screen"
require_relative "mui/input"
require_relative "mui/undoable_action"
require_relative "mui/undo_manager"
require_relative "mui/buffer"
require_relative "mui/highlight"
require_relative "mui/highlighters/base"
require_relative "mui/highlighters/selection_highlighter"
require_relative "mui/highlighters/search_highlighter"
require_relative "mui/syntax/token"
require_relative "mui/syntax/lexer_base"
require_relative "mui/syntax/lexers/ruby_lexer"
require_relative "mui/syntax/lexers/c_lexer"
require_relative "mui/syntax/token_cache"
require_relative "mui/syntax/language_detector"
require_relative "mui/highlighters/syntax_highlighter"
require_relative "mui/line_renderer"
require_relative "mui/status_line_renderer"
require_relative "mui/layout/node"
require_relative "mui/layout/leaf_node"
require_relative "mui/layout/split_node"
require_relative "mui/layout/calculator"
require_relative "mui/window"
require_relative "mui/window_manager"
require_relative "mui/tab_page"
require_relative "mui/tab_manager"
require_relative "mui/tab_bar_renderer"
require_relative "mui/mode"
require_relative "mui/handler_result"
require_relative "mui/command_history"
require_relative "mui/command_line"
require_relative "mui/completion_state"
require_relative "mui/insert_completion_state"
require_relative "mui/command_completer"
require_relative "mui/file_completer"
require_relative "mui/buffer_word_completer"
require_relative "mui/buffer_word_cache"
require_relative "mui/completion_renderer"
require_relative "mui/insert_completion_renderer"
require_relative "mui/floating_window"
require_relative "mui/search_state"
require_relative "mui/search_input"
require_relative "mui/search_completer"
require_relative "mui/motion"
require_relative "mui/selection"
require_relative "mui/register"
require_relative "mui/key_handler"
require_relative "mui/mode_manager"
require_relative "mui/command_context"
require_relative "mui/command_registry"
require_relative "mui/autocmd"
require_relative "mui/plugin"
require_relative "mui/plugin_manager"
require_relative "mui/job"
require_relative "mui/job_manager"
require_relative "mui/editor"

# mui(無為) top level module
module Mui
  class << self
    def config
      @config ||= Config.new
    end

    def plugin_manager
      @plugin_manager ||= PluginManager.new
    end

    def register
      @register ||= Register.new
    end

    def set(key, value)
      config.set(key, value)
    end

    # Register gem for lazy installation via bundler/inline
    def use(gem_name, version = nil)
      plugin_manager.add_gem(gem_name, version)
    end

    def keymap(mode, key, &block)
      config.add_keymap(mode, key, block)
    end

    def command(name, &block)
      config.add_command(name, block)
    end

    def autocmd(event, pattern: nil, &block)
      config.add_autocmd(event, pattern, block)
    end

    def define_plugin(name, dependencies: [], &block)
      plugin_manager.register(name, block, dependencies:)
    end

    def load_config
      config.load_file(File.expand_path("~/.muirc"))
      config.load_file(".lmuirc")
    end

    # Stub for LSP configuration DSL
    # This allows .muirc to call Mui.lsp { ... } before mui-lsp gem is loaded
    # When mui-lsp is loaded, it replaces this with the real ConfigDsl
    def lsp(&block)
      @lsp_config ||= LspConfigStub.new
      @lsp_config.instance_eval(&block) if block
      @lsp_config
    end

    def lsp_server_configs
      @lsp_config&.server_configs || []
    end
  end

  # Stub class for LSP configuration before mui-lsp gem is loaded
  # Stores configuration to be applied when the actual gem loads
  class LspConfigStub
    attr_reader :server_configs

    def initialize
      @server_configs = []
    end

    # Stub methods that mirror Mui::Lsp::ConfigDsl
    def use(name, **options)
      @server_configs << { type: :preset, name: name.to_sym, options: }
    end

    def server(name:, command:, language_ids:, file_patterns:, auto_start: true, sync_on_change: true)
      @server_configs << {
        type: :custom,
        name:,
        command:,
        language_ids:,
        file_patterns:,
        auto_start:,
        sync_on_change:
      }
    end
  end

  class << self
    def reset_config!
      @config = nil
      @plugin_manager = nil
      @register = nil
      @lsp_config = nil
    end
  end
end
