# frozen_string_literal: true

require "test_helper"

class TestCommandRegistry < Minitest::Test
  def setup
    @registry = Mui::CommandRegistry.new
    @buffer = MockBuffer.new(["test"])
    @window = MockWindow.new(@buffer)
    @editor = MockEditor.new(@buffer, @window)
    @context = Mui::CommandContext.new(editor: @editor, buffer: @buffer, window: @window)
  end

  def test_register_and_execute
    result = nil
    @registry.register(:hello) { |_ctx| result = "hello" }

    @registry.execute(:hello, @context)

    assert_equal "hello", result
  end

  def test_execute_with_args
    received_args = nil
    @registry.register(:greet) { |_ctx, *args| received_args = args }

    @registry.execute(:greet, @context, "world", "!")

    assert_equal ["world", "!"], received_args
  end

  def test_execute_unknown_command_raises
    assert_raises(Mui::UnknownCommandError) do
      @registry.execute(:nonexistent, @context)
    end
  end

  def test_exists_returns_true_for_registered
    @registry.register(:test) {}

    assert @registry.exists?(:test)
  end

  def test_exists_returns_false_for_unknown
    refute @registry.exists?(:unknown)
  end

  def test_register_overwrites_existing
    first_called = false
    second_called = false

    @registry.register(:cmd) { first_called = true }
    @registry.register(:cmd) { second_called = true }

    @registry.execute(:cmd, @context)

    refute first_called
    assert second_called
  end

  # Tests for plugin command integration
  def test_exists_returns_true_for_plugin_command
    Mui.config.add_command(:plugin_cmd, ->(_ctx) { "plugin" })

    assert @registry.exists?(:plugin_cmd)
  ensure
    Mui.config.commands.delete(:plugin_cmd)
  end

  def test_find_returns_builtin_command
    @registry.register(:test_cmd) { "builtin" }

    command = @registry.find(:test_cmd)

    assert command
  end

  def test_find_returns_plugin_command
    Mui.config.add_command(:plugin_cmd, ->(_ctx) { "plugin" })

    command = @registry.find(:plugin_cmd)

    assert command
  ensure
    Mui.config.commands.delete(:plugin_cmd)
  end

  def test_find_returns_nil_for_unknown
    command = @registry.find(:unknown_cmd)

    assert_nil command
  end

  def test_builtin_takes_precedence_over_plugin
    builtin_called = false
    plugin_called = false

    @registry.register(:same_name) { |_ctx| builtin_called = true }
    Mui.config.add_command(:same_name, ->(_ctx) { plugin_called = true })

    @registry.execute(:same_name, @context)

    assert builtin_called
    refute plugin_called
  ensure
    Mui.config.commands.delete(:same_name)
  end

  def test_execute_plugin_command
    result = nil
    Mui.config.add_command(:plugin_exec, ->(_ctx) { result = "executed" })

    @registry.execute(:plugin_exec, @context)

    assert_equal "executed", result
  ensure
    Mui.config.commands.delete(:plugin_exec)
  end
end
