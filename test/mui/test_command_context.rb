# frozen_string_literal: true

require "test_helper"

class TestCommandContext < Minitest::Test
  def setup
    @buffer = MockBuffer.new(["hello world", "second line"])
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
end
