# frozen_string_literal: true

require_relative "test_helper"

class TestE2EClipboard < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
    Clipboard.clear
  end

  def teardown
    clear_key_sequence
    Mui.config.set(:clipboard, nil)
    Clipboard.clear
  end

  # Helper to create runner with clipboard enabled
  def create_runner_with_clipboard
    runner = ScriptRunner.new
    Mui.config.set(:clipboard, :unnamedplus)
    runner
  end

  # Yank syncs to clipboard

  def test_yy_syncs_to_clipboard
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("Hello World")
      .type("<Esc>")
      .type("0")
      .type("yy")

    assert_equal "Hello World\n", Clipboard.paste
  end

  def test_yw_syncs_to_clipboard
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")
      .type("yw")

    assert_equal "hello", Clipboard.paste
  end

  def test_visual_yank_syncs_to_clipboard
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")
      .type("v")
      .type("llll")
      .type("y")

    assert_equal "hello", Clipboard.paste
  end

  # Delete syncs to clipboard

  def test_dd_syncs_to_clipboard
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("Line 1<Enter>Line 2")
      .type("<Esc>")
      .type("gg")
      .type("dd")

    assert_equal "Line 1\n", Clipboard.paste
  end

  def test_dw_syncs_to_clipboard
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")
      .type("dw")

    assert_equal "hello ", Clipboard.paste
  end

  # Paste from clipboard

  def test_p_pastes_from_clipboard
    Clipboard.copy("from clipboard")
    runner = create_runner_with_clipboard

    runner
      .type("p")
      .assert_line(0, "from clipboard")
  end

  def test_shift_p_pastes_from_clipboard
    Clipboard.copy("prefix")
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("suffix")
      .type("<Esc>")
      .type("0")
      .type("P")
      .assert_line(0, "prefixsuffix")
  end

  def test_p_pastes_linewise_from_clipboard
    Clipboard.copy("new line\n")
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("existing line")
      .type("<Esc>")
      .type("p")
      .assert_line_count(2)
      .assert_line(0, "existing line")
      .assert_line(1, "new line")
  end

  def test_p_pastes_multiline_from_clipboard
    Clipboard.copy("line1\nline2\nline3\n")
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("existing")
      .type("<Esc>")
      .type("p")
      .assert_line_count(4)
      .assert_line(0, "existing")
      .assert_line(1, "line1")
      .assert_line(2, "line2")
      .assert_line(3, "line3")
  end

  # Clipboard disabled

  def test_yy_does_not_sync_when_clipboard_disabled
    runner = ScriptRunner.new
    # clipboard is nil by default after reset

    runner
      .type("i")
      .type("Hello World")
      .type("<Esc>")
      .type("0")
      .type("yy")

    assert_equal "", Clipboard.paste
  end

  def test_p_does_not_sync_when_clipboard_disabled
    Clipboard.copy("from clipboard")
    runner = ScriptRunner.new
    # clipboard is nil by default after reset

    runner
      .type("i")
      .type("original")
      .type("<Esc>")
      .type("0")
      .type("yy") # Yank "original" to register
      .type("G")
      .type("p")
      .assert_line_count(2)
      .assert_line(1, "original") # Pasted from register, not clipboard
  end

  # Named registers don't affect clipboard

  def test_named_register_yank_does_not_sync_to_clipboard
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("Hello World")
      .type("<Esc>")
      .type("0")
      .type('"ayy')

    assert_equal "", Clipboard.paste
  end

  def test_named_register_paste_does_not_sync_from_clipboard
    Clipboard.copy("clipboard content")
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("line 1")
      .type("<Esc>")
      .type("0")
      .type('"ayy')
      .type("G")
      .type('"ap')
      .assert_line_count(2)
      .assert_line(1, "line 1") # Pasted from register a, not clipboard
  end

  # Workflow test

  def test_external_clipboard_paste_workflow
    # Simulate external copy (e.g., from browser)
    Clipboard.copy("external content")
    runner = create_runner_with_clipboard

    runner
      .type("i")
      .type("existing text")
      .type("<Esc>")
      .type("$")
      .type("p")
      .assert_line(0, "existing textexternal content")
  end

  def test_yank_and_external_paste_workflow
    runner = create_runner_with_clipboard

    # Yank text in Mui
    runner
      .type("i")
      .type("mui content")
      .type("<Esc>")
      .type("0")
      .type("yy")

    # Verify clipboard has yanked content
    assert_equal "mui content\n", Clipboard.paste

    # Simulate external app modifying clipboard (with newline for linewise paste)
    Clipboard.copy("external update\n")

    # Paste should now use external content
    runner
      .type("p")
      .assert_line_count(2)
      .assert_line(1, "external update")
  end
end
