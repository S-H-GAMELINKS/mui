# frozen_string_literal: true

require "test_helper"

class TestPluginManager < Minitest::Test
  def setup
    Mui.reset_config!
  end

  def teardown
    Mui.reset_config!
  end

  def test_add_gem_stores_pending_gems
    Mui.plugin_manager.add_gem("mui-example", "~> 0.1")
    Mui.plugin_manager.add_gem("mui-another")

    assert_equal 2, Mui.plugin_manager.pending_gems.length
    assert_equal({ gem: "mui-example", version: "~> 0.1" }, Mui.plugin_manager.pending_gems[0])
    assert_equal({ gem: "mui-another", version: nil }, Mui.plugin_manager.pending_gems[1])
  end

  def test_register_stores_plugin_definition
    handler = proc { "test" }
    Mui.plugin_manager.register(:test_plugin, handler, dependencies: [:core])

    assert Mui.plugin_manager.plugins.key?(:test_plugin)
    assert_equal handler, Mui.plugin_manager.plugins[:test_plugin][:handler]
    assert_equal [:core], Mui.plugin_manager.plugins[:test_plugin][:dependencies]
  end

  def test_install_and_load_is_idempotent
    # Should not raise even when called multiple times
    Mui.plugin_manager.install_and_load
    Mui.plugin_manager.install_and_load

    assert_predicate Mui.plugin_manager, :installed?
  end

  def test_install_and_load_sets_installed_flag
    refute_predicate Mui.plugin_manager, :installed?

    Mui.plugin_manager.install_and_load

    assert_predicate Mui.plugin_manager, :installed?
  end

  def test_define_plugin_registers_block
    called = false
    Mui.define_plugin :my_plugin do
      called = true
    end

    assert Mui.plugin_manager.plugins.key?(:my_plugin)

    # Manually load the plugin to trigger the block
    Mui.plugin_manager.send(:load_plugin, :my_plugin)

    assert called
  end

  def test_define_plugin_with_dependencies
    Mui.define_plugin :dep_plugin, dependencies: [:base] do
      # empty
    end

    assert_equal [:base], Mui.plugin_manager.plugins[:dep_plugin][:dependencies]
  end
end
