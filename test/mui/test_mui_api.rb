# frozen_string_literal: true

require "test_helper"

class TestMuiApi < Minitest::Test
  def setup
    Mui.reset_config!
  end

  def teardown
    Mui.reset_config!
  end

  def test_config_returns_config_instance
    assert_instance_of Mui::Config, Mui.config
  end

  def test_config_is_memoized
    config1 = Mui.config
    config2 = Mui.config

    assert_same config1, config2
  end

  def test_set_delegates_to_config
    Mui.set :colorscheme, "mui"

    assert_equal "mui", Mui.config.get(:colorscheme)
  end

  def test_use_adds_gem_to_plugin_manager
    Mui.use "mui-lsp", "~> 0.1"

    assert_equal 1, Mui.plugin_manager.pending_gems.length
    assert_equal "mui-lsp", Mui.plugin_manager.pending_gems.first[:gem]
    assert_equal "~> 0.1", Mui.plugin_manager.pending_gems.first[:version]
  end

  def test_keymap_delegates_to_config
    block = proc { puts "hover" }
    Mui.keymap(:normal, "K", &block)

    assert_equal block, Mui.config.keymaps[:normal]["K"]
  end

  def test_reset_config_clears_config
    Mui.set :colorscheme, "custom"
    Mui.reset_config!

    assert_equal "mui", Mui.config.get(:colorscheme)
  end

  def test_load_config_does_not_raise_error
    # Should not raise error when loading config
    Mui.load_config
    # Config value depends on user's ~/.muirc, so just check it's a string
    assert_kind_of String, Mui.config.get(:colorscheme)
  end

  # LSP stub tests
  def test_lsp_returns_lsp_config_stub
    assert_instance_of Mui::LspConfigStub, Mui.lsp
  end

  def test_lsp_is_memoized
    lsp1 = Mui.lsp
    lsp2 = Mui.lsp

    assert_same lsp1, lsp2
  end

  def test_lsp_use_stores_preset_config
    Mui.lsp do
      use :ruby_lsp
    end
    configs = Mui.lsp_server_configs

    assert_equal 1, configs.length
    assert_equal :preset, configs.first[:type]
    assert_equal :ruby_lsp, configs.first[:name]
  end

  def test_lsp_use_stores_options
    Mui.lsp do
      use :ruby_lsp, sync_on_change: true
    end
    configs = Mui.lsp_server_configs

    assert_equal({ sync_on_change: true }, configs.first[:options])
  end

  def test_lsp_server_stores_custom_config
    Mui.lsp do
      server(
        name: "custom-lsp",
        command: "custom-lsp --stdio",
        language_ids: ["custom"],
        file_patterns: ["*.custom"]
      )
    end
    configs = Mui.lsp_server_configs

    assert_equal 1, configs.length
    assert_equal :custom, configs.first[:type]
    assert_equal "custom-lsp", configs.first[:name]
    assert_equal "custom-lsp --stdio", configs.first[:command]
    assert_equal ["custom"], configs.first[:language_ids]
    assert_equal ["*.custom"], configs.first[:file_patterns]
    assert configs.first[:auto_start]
    assert configs.first[:sync_on_change]
  end

  def test_lsp_server_configs_empty_by_default
    assert_empty Mui.lsp_server_configs
  end

  def test_reset_config_clears_lsp_config
    Mui.lsp do
      use :ruby_lsp
    end
    Mui.reset_config!

    assert_empty Mui.lsp_server_configs
  end
end
