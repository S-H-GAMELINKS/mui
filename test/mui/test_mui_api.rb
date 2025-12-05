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
end
