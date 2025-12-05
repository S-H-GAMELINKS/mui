# frozen_string_literal: true

require "test_helper"

class TestPluginGemLoading < Minitest::Test
  FIXTURE_PATH = File.expand_path("../fixtures/mui-test-plugin/lib", __dir__)

  def setup
    Mui.reset_config!
    $LOAD_PATH.unshift(FIXTURE_PATH) unless $LOAD_PATH.include?(FIXTURE_PATH)
  end

  def teardown
    Mui.reset_config!
    # Remove from loaded features to allow re-require
    $LOADED_FEATURES.reject! { |f| f.include?("mui_test_plugin") }
  end

  def test_plugin_gem_can_be_required
    require "mui_test_plugin"

    assert Mui.plugin_manager.plugins.key?(:test_plugin)
  end

  def test_plugin_registers_command_after_load
    require "mui_test_plugin"
    Mui.plugin_manager.send(:load_plugin, :test_plugin)

    assert Mui.config.commands.key?(:test_cmd)
  end

  def test_plugin_registers_keymap_after_load
    require "mui_test_plugin"
    Mui.plugin_manager.send(:load_plugin, :test_plugin)

    assert Mui.config.keymaps[:normal]&.key?("gt")
  end

  def test_plugin_registers_autocmd_after_load
    require "mui_test_plugin"
    Mui.plugin_manager.send(:load_plugin, :test_plugin)

    assert(Mui.config.autocmds[:BufEnter]&.any? { |h| h[:pattern] == "*.test" })
  end
end
