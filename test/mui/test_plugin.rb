# frozen_string_literal: true

require "test_helper"

class TestPlugin < Minitest::Test
  def setup
    Mui.reset_config!
  end

  def teardown
    Mui.reset_config!
  end

  def test_plugin_name_class_method
    klass = Class.new(Mui::Plugin) do
      name "my-plugin"
    end

    assert_equal "my-plugin", klass.plugin_name
  end

  def test_plugin_depends_on_class_method
    klass = Class.new(Mui::Plugin) do
      depends_on :core, :utils
    end

    assert_equal %i[core utils], klass.plugin_dependencies
  end

  def test_setup_method_can_be_overridden
    setup_called = false
    klass = Class.new(Mui::Plugin) do
      define_method(:setup) do
        setup_called = true
      end
    end

    instance = klass.new
    instance.setup

    assert setup_called
  end

  def test_command_shortcut
    klass = Class.new(Mui::Plugin) do
      def setup
        command(:test_cmd) { "test" }
      end
    end

    instance = klass.new
    instance.setup

    assert Mui.config.commands.key?(:test_cmd)
  end

  def test_keymap_shortcut
    klass = Class.new(Mui::Plugin) do
      def setup
        keymap(:normal, "K") { "hover" }
      end
    end

    instance = klass.new
    instance.setup

    assert Mui.config.keymaps[:normal].key?("K")
  end

  def test_autocmd_shortcut
    klass = Class.new(Mui::Plugin) do
      def setup
        autocmd(:BufEnter, pattern: "*.rb") { "entered" }
      end
    end

    instance = klass.new
    instance.setup

    assert Mui.config.autocmds.key?(:BufEnter)
    assert_equal 1, Mui.config.autocmds[:BufEnter].length
  end
end
