# frozen_string_literal: true

require_relative "test_helper"

class TestE2EPopupRedraw < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end
end

class TestE2EFloatingWindowRedraw < TestE2EPopupRedraw
  def test_floating_window_sets_needs_clear_on_hide
    runner = ScriptRunner.new

    # Show floating window
    runner.editor.show_floating("Test content", max_width: 20, max_height: 5)

    assert runner.editor.floating_window.visible

    # Press any key to close
    runner.type("j")

    # Verify needs_clear flag is set
    refute runner.editor.floating_window.visible
    assert_predicate runner.editor.floating_window, :needs_clear?
  end

  def test_floating_window_clears_after_render
    runner = ScriptRunner.new

    # Show and hide floating window
    runner.editor.show_floating("Test content", max_width: 20, max_height: 5)
    runner.type("j")

    # Call render (private method, use send)
    runner.editor.send(:render)

    # Verify clear flag is reset
    refute_predicate runner.editor.floating_window, :needs_clear?
    assert_nil runner.editor.floating_window.last_bounds
  end

  def test_floating_window_records_last_bounds
    runner = ScriptRunner.new

    # Show floating window
    runner.editor.show_floating("Test", max_width: 20, max_height: 5)

    # Record dimensions
    width = runner.editor.floating_window.width
    height = runner.editor.floating_window.height

    # Close
    runner.type("<Esc>")

    # Verify last_bounds is recorded correctly
    bounds = runner.editor.floating_window.last_bounds

    assert_equal width, bounds[:width]
    assert_equal height, bounds[:height]
  end

  def test_screen_cleared_at_floating_window_position
    runner = ScriptRunner.new

    # Type some text
    runner
      .type("i")
      .type("Hello World")
      .type("<Esc>")

    # Show and hide floating window
    runner.editor.show_floating("Popup", max_width: 10, max_height: 3)
    runner.type("j")

    # Verify needs_clear before render
    assert_predicate runner.editor.floating_window, :needs_clear?

    # Verify cleared after render (private method, use send)
    runner.editor.send(:render)

    refute_predicate runner.editor.floating_window, :needs_clear?
  end

  def test_hide_when_not_visible_does_nothing
    runner = ScriptRunner.new

    # Call hide without showing
    runner.editor.floating_window.hide

    # Verify no needs_clear flag
    refute_predicate runner.editor.floating_window, :needs_clear?
    assert_nil runner.editor.floating_window.last_bounds
  end

  def test_show_clears_needs_clear_flag
    runner = ScriptRunner.new

    # Show, hide, then show again
    runner.editor.show_floating("First", max_width: 20, max_height: 5)
    runner.type("j")

    # Should have needs_clear flag
    assert_predicate runner.editor.floating_window, :needs_clear?

    # Show again
    runner.editor.show_floating("Second", max_width: 20, max_height: 5)

    # needs_clear should be reset
    refute_predicate runner.editor.floating_window, :needs_clear?
  end
end

class TestE2EInsertCompletionRedraw < TestE2EPopupRedraw
  def test_insert_completion_sets_needs_clear_on_reset
    runner = ScriptRunner.new

    # Enter insert mode and type to trigger completion
    runner
      .type("i")
      .type("hello world hello")
      .type("<Esc>")
      .type("o")
      .type("hel")

    # Completion should be active
    assert_predicate runner.editor, :insert_completion_active?

    # Confirm completion with Tab
    runner.type("<Tab>")

    # Verify needs_clear flag is set after completion closes
    assert_predicate runner.editor.insert_completion_state, :needs_clear?
  end

  def test_insert_completion_clears_after_render
    runner = ScriptRunner.new

    # Enter insert mode and type to trigger completion
    runner
      .type("i")
      .type("hello world hello")
      .type("<Esc>")
      .type("o")
      .type("hel")

    # Confirm completion
    runner.type("<Tab>")

    # Call render
    runner.editor.send(:render)

    # Verify clear flag is reset
    refute_predicate runner.editor.insert_completion_state, :needs_clear?
  end

  def test_insert_completion_needs_clear_on_escape
    runner = ScriptRunner.new

    # Enter insert mode and type to trigger completion
    runner
      .type("i")
      .type("hello world hello")
      .type("<Esc>")
      .type("o")
      .type("hel")

    assert_predicate runner.editor, :insert_completion_active?

    # Cancel completion with Escape
    runner.type("<Esc>")

    # Verify needs_clear flag is set
    assert_predicate runner.editor.insert_completion_state, :needs_clear?
  end

  def test_insert_completion_no_needs_clear_when_not_active
    runner = ScriptRunner.new

    # Just enter and exit insert mode without triggering completion
    runner
      .type("i")
      .type("x")
      .type("<Esc>")

    # No completion was active, so needs_clear should be false
    refute_predicate runner.editor.insert_completion_state, :needs_clear?
  end
end
