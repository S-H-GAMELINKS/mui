# frozen_string_literal: true

require "test_helper"

class TestCommandContext < Minitest::Test
  def setup
    @buffer = MockBuffer.new
    @buffer.content = "hello world\nsecond line"
    @window = MockWindow.new(@buffer)
    @editor = MockEditor.new(@buffer, @window)
    @context = Mui::CommandContext.new(editor: @editor, buffer: @buffer, window: @window)
  end

  def test_cursor_returns_position
    @buffer.cursor_y = 1
    @buffer.cursor_x = 5

    cursor = @context.cursor

    assert_equal 1, cursor[:line]
    assert_equal 5, cursor[:col]
  end

  def test_current_line_returns_buffer_current_line
    line = @context.current_line

    assert_equal "hello world", line
  end

  def test_set_message_sets_editor_message
    @context.set_message("Test message")

    assert_equal "Test message", @editor.message
  end

  def test_quit_sets_running_to_false
    assert @editor.running

    @context.quit

    refute @editor.running
  end

  def test_buffer_accessor
    assert_equal @buffer, @context.buffer
  end

  def test_window_accessor
    assert_equal @window, @context.window
  end

  def test_editor_accessor
    assert_equal @editor, @context.editor
  end

  def test_command_exists_returns_true_for_existing_command
    # 'ls' should exist on most Unix systems
    assert @context.command_exists?("ls")
  end

  def test_command_exists_returns_false_for_nonexistent_command
    refute @context.command_exists?("nonexistent_command_12345_xyz")
  end

  def test_responds_to_run_interactive_command
    assert_respond_to @context, :run_interactive_command
  end

  def test_responds_to_command_exists
    assert_respond_to @context, :command_exists?
  end
end
