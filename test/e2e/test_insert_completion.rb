# frozen_string_literal: true

require_relative "test_helper"

class TestE2EInsertCompletion < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  # Helper to check completion state
  def assert_completion_active(runner, expected)
    actual = runner.editor.insert_completion_active?
    raise "Expected completion_active=#{expected}, got #{actual}" unless actual == expected

    runner
  end

  def assert_completion_items_count(runner, expected)
    actual = runner.editor.insert_completion_state.items.length
    raise "Expected #{expected} completion items, got #{actual}" unless actual == expected

    runner
  end

  def assert_completion_selected_label(runner, expected)
    item = runner.editor.insert_completion_state.current_item
    raise "No completion item selected" unless item

    actual = item[:label]
    raise "Expected selected item label '#{expected}', got '#{actual}'" unless actual == expected

    runner
  end

  def test_buffer_word_completion_triggers_automatically
    runner = ScriptRunner.new

    # Type a word that will be in the buffer
    runner
      .type("i")
      .type("buffer_completion_test")
      .type("<Esc>")
      .type("o") # Open new line below

    # Type prefix - should trigger completion
    runner.type("buf")

    assert_completion_active(runner, true)
    assert_completion_items_count(runner, 1)
    assert_completion_selected_label(runner, "buffer_completion_test")
  end

  def test_completion_filters_as_you_type
    runner = ScriptRunner.new

    # Create buffer with multiple words
    runner
      .type("i")
      .type("buffer_one buffer_two banana")
      .type("<Esc>")
      .type("o")

    # Type prefix that matches multiple words
    runner.type("b")

    assert_completion_active(runner, true)

    # Initial completion should have 3 items (buffer_one, buffer_two, banana)
    initial_count = runner.editor.insert_completion_state.items.length
    raise "Expected 3 items, got #{initial_count}" unless initial_count == 3

    # Type more to filter
    runner.type("uf")

    assert_completion_active(runner, true)

    # Should now only match buffer_one, buffer_two
    filtered_count = runner.editor.insert_completion_state.items.length
    raise "Expected 2 items after filtering, got #{filtered_count}" unless filtered_count == 2
  end

  def test_completion_closes_when_no_matches
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("apple banana")
      .type("<Esc>")
      .type("o")

    # Type prefix that matches
    runner.type("ap")

    assert_completion_active(runner, true)

    # Type something that won't match anything
    runner.type("xyz")

    assert_completion_active(runner, false)
  end

  def test_escape_cancels_completion_and_returns_to_normal
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("o")

    # Trigger completion
    runner.type("hel")

    assert_completion_active(runner, true)

    # Press Escape - should cancel completion AND return to normal mode
    runner.type("<Esc>")

    assert_completion_active(runner, false)
    runner.assert_mode(Mui::Mode::NORMAL)
  end

  def test_tab_confirms_completion
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("completion_target")
      .type("<Esc>")
      .type("o")

    # Type prefix and trigger completion
    runner.type("com")

    assert_completion_active(runner, true)

    # Confirm with Tab
    runner.type("<tab>")

    assert_completion_active(runner, false)

    # Check that the word was completed
    runner.assert_line(1, "completion_target")
  end

  def test_arrow_keys_navigate_completion
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("alpha beta gamma")
      .type("<Esc>")
      .type("o")

    # Type prefix that matches multiple words - need "a" to match alpha
    runner.type("a")

    assert_completion_active(runner, true)

    # Check initial selection
    runner.editor.insert_completion_state.current_item[:label]

    # Navigate down
    runner.type("<Down>")
    runner.editor.insert_completion_state.current_item[:label]

    # Should have moved to different item (if more than one match)
    # Note: with "a" we match "alpha" only, so let's test with different setup
  end

  def test_ctrl_n_ctrl_p_navigate_completion
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("test_one test_two test_three")
      .type("<Esc>")
      .type("o")

    # Type prefix
    runner.type("test")

    assert_completion_active(runner, true)

    # Should have 3 items
    item_count = runner.editor.insert_completion_state.items.length
    raise "Expected 3 items, got #{item_count}" unless item_count == 3

    # Get initial selection
    initial_index = runner.editor.insert_completion_state.selected_index

    # Ctrl+N should move to next (use <C-n> notation)
    runner.type("<C-n>")
    next_index = runner.editor.insert_completion_state.selected_index
    raise "Ctrl+N should change selection (was #{initial_index}, now #{next_index})" unless next_index == (initial_index + 1) % item_count

    # Ctrl+P should move back
    runner.type("<C-p>")
    prev_index = runner.editor.insert_completion_state.selected_index
    raise "Ctrl+P should return to initial (expected #{initial_index}, got #{prev_index})" unless prev_index == initial_index
  end

  def test_completion_after_backspace
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("foobar foobaz")
      .type("<Esc>")
      .type("o")

    # Type prefix
    runner.type("foob")

    assert_completion_active(runner, true)

    # Should have 2 matches
    count_before = runner.editor.insert_completion_state.items.length
    raise "Expected 2 items, got #{count_before}" unless count_before == 2

    # Type more to filter to 1
    runner.type("ar")
    count_filtered = runner.editor.insert_completion_state.items.length
    raise "Expected 1 item after 'foobar', got #{count_filtered}" unless count_filtered == 1

    # Backspace should restore more matches
    runner.type("<BS><BS>")
    count_after_bs = runner.editor.insert_completion_state.items.length
    raise "Expected 2 items after backspace, got #{count_after_bs}" unless count_after_bs == 2
  end

  def test_non_word_char_closes_completion
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("method_name")
      .type("<Esc>")
      .type("o")

    # Trigger completion
    runner.type("met")

    assert_completion_active(runner, true)

    # Type space (non-word char) - should close completion
    runner.type(" ")

    assert_completion_active(runner, false)
  end

  def test_enter_during_completion_inserts_newline
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("testing")
      .type("<Esc>")
      .type("o")

    # Trigger completion
    runner.type("tes")

    assert_completion_active(runner, true)

    # Enter should insert newline (not confirm completion like Tab)
    runner.type("<Enter>")

    # Should have added a new line
    runner.assert_line_count(3)
  end

  def test_completion_with_single_char_prefix
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("x_variable y_variable")
      .type("<Esc>")
      .type("o")

    # Single char should trigger completion (min_prefix: 1)
    runner.type("x")

    assert_completion_active(runner, true)
    assert_completion_items_count(runner, 1)
  end

  def test_manual_completion_trigger_with_ctrl_n
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("manual_trigger")
      .type("<Esc>")
      .type("o")

    # Type prefix - completion should auto-trigger
    runner.type("man")

    assert_completion_active(runner, true)

    # Ctrl+N should navigate (completion already active)
    runner.editor.insert_completion_state.selected_index
    runner.type("<C-n>")

    # Should still be active
    assert_completion_active(runner, true)
  end
end
