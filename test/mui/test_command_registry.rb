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
end
