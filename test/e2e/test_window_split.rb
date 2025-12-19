# frozen_string_literal: true

require_relative "test_helper"

class TestE2EWindowSplit < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  def test_ctrl_w_s_splits_window_horizontally
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Hello World")
      .type("<Esc>")
      .assert_window_count(1)

    runner
      .type("<C-w>s")
      .assert_window_count(2)
  end

  def test_ctrl_w_v_splits_window_vertically
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Hello World")
      .type("<Esc>")
      .assert_window_count(1)

    runner
      .type("<C-w>v")
      .assert_window_count(2)
  end

  def test_ctrl_w_c_closes_window
    runner = ScriptRunner.new

    runner
      .type("<C-w>s")
      .assert_window_count(2)
      .type("<C-w>c")
      .assert_window_count(1)
  end

  def test_ctrl_w_o_closes_all_except_current
    runner = ScriptRunner.new

    runner
      .type("<C-w>s")
      .type("<C-w>v")
      .assert_window_count(3)
      .type("<C-w>o")
      .assert_window_count(1)
  end

  def test_ctrl_w_w_cycles_through_windows
    runner = ScriptRunner.new

    runner
      .type("<C-w>s")
      .assert_window_count(2)

    first_window = runner.editor.window

    runner.type("<C-w>w")

    refute_equal first_window, runner.editor.window
  end

  def test_ctrl_w_hjkl_navigation
    runner = ScriptRunner.new

    # Split vertically (creates left and right windows)
    runner
      .type("<C-w>v")
      .assert_window_count(2)

    # After split, active window is the new one (right side)
    right_window = runner.editor.window

    # Move left
    runner.type("<C-w>h")
    left_window = runner.editor.window

    refute_equal right_window, left_window

    # Move right
    runner.type("<C-w>l")

    assert_equal right_window, runner.editor.window
  end

  def test_ctrl_w_jk_navigation_horizontal_split
    runner = ScriptRunner.new

    # Split horizontally (creates top and bottom windows)
    runner
      .type("<C-w>s")
      .assert_window_count(2)

    # After split, active window is the new one (bottom)
    bottom_window = runner.editor.window

    # Move up
    runner.type("<C-w>k")
    top_window = runner.editor.window

    refute_equal bottom_window, top_window

    # Move down
    runner.type("<C-w>j")

    assert_equal bottom_window, runner.editor.window
  end

  def test_split_command
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Hello World")
      .type("<Esc>")
      .assert_window_count(1)
      .type(":split<Enter>")
      .assert_window_count(2)
  end

  def test_vsplit_command
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Hello World")
      .type("<Esc>")
      .assert_window_count(1)
      .type(":vsplit<Enter>")
      .assert_window_count(2)
  end

  def test_sp_command_alias
    runner = ScriptRunner.new

    runner
      .type(":sp<Enter>")
      .assert_window_count(2)
  end

  def test_vs_command_alias
    runner = ScriptRunner.new

    runner
      .type(":vs<Enter>")
      .assert_window_count(2)
  end

  def test_close_command
    runner = ScriptRunner.new

    runner
      .type(":sp<Enter>")
      .assert_window_count(2)
      .type(":close<Enter>")
      .assert_window_count(1)
  end

  def test_only_command
    runner = ScriptRunner.new

    runner
      .type(":sp<Enter>")
      .type(":vs<Enter>")
      .assert_window_count(3)
      .type(":only<Enter>")
      .assert_window_count(1)
  end

  def test_split_shares_same_buffer
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Hello")
      .type("<Esc>")
      .type("<C-w>s")
      .assert_window_count(2)

    # Both windows should share the same buffer
    windows = runner.editor.window_manager.windows

    assert_same windows[0].buffer, windows[1].buffer
    assert_equal "Hello", windows[0].buffer.line(0)
    assert_equal "Hello", windows[1].buffer.line(0)
  end

  def test_nested_splits
    runner = ScriptRunner.new

    # Create layout:
    # +--------+
    # |   1    |
    # +---+|---+
    # | 2 || 3 |
    # +---+|---+
    runner
      .type("<C-w>s")      # Horizontal split
      .type("<C-w>v")      # Vertical split bottom
      .assert_window_count(3)

    windows = runner.editor.window_manager.windows

    # Window 1 should be full width, top half
    assert_equal 0, windows[0].y
    assert_equal 80, windows[0].width

    # Windows 2 and 3 should be bottom half, split vertically
    # They start after window[0].height + 1 (separator)
    assert_equal windows[0].height + 1, windows[1].y
    assert_equal windows[0].height + 1, windows[2].y
    # width 80 - separator 1 = 79, split 50% = 39 + 40
    assert_equal 39, windows[1].width
    assert_equal 40, windows[2].width
  end
end
