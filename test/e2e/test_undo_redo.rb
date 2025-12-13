# frozen_string_literal: true

require_relative "test_helper"

class TestE2EUndoRedo < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  # Basic undo (u)

  def test_u_undoes_dd
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg")

    runner
      .type("dd")
      .assert_line_count(2)
      .assert_line(0, "Line 2")

    runner
      .type("u")
      .assert_line_count(3)
      .assert_line(0, "Line 1")
      .assert_line(1, "Line 2")
      .assert_line(2, "Line 3")
  end

  def test_u_undoes_dw
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")

    runner
      .type("dw")
      .assert_line(0, "world")

    runner
      .type("u")
      .assert_line(0, "hello world")
  end

  def test_u_undoes_x
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello")
      .type("<Esc>")
      .type("0")

    runner
      .type("x")
      .assert_line(0, "ello")

    runner
      .type("u")
      .assert_line(0, "hello")
  end

  # Multiple undo

  def test_multiple_u_undoes_multiple_operations
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg")

    runner
      .type("dd")
      .type("dd")
      .assert_line_count(1)
      .assert_line(0, "Line 3")

    runner
      .type("u")
      .assert_line_count(2)
      .assert_line(0, "Line 2")

    runner
      .type("u")
      .assert_line_count(3)
      .assert_line(0, "Line 1")
  end

  # Basic redo (Ctrl-r)

  def test_ctrl_r_redoes_after_undo
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2")
      .type("<Esc>")
      .type("gg")

    runner
      .type("dd")
      .assert_line_count(1)
      .assert_line(0, "Line 2")

    runner
      .type("u")
      .assert_line_count(2)
      .assert_line(0, "Line 1")

    runner
      .type("<C-r>")
      .assert_line_count(1)
      .assert_line(0, "Line 2")
  end

  def test_multiple_redo
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg")

    runner
      .type("dd")
      .type("dd")
      .assert_line_count(1)

    runner
      .type("u")
      .type("u")
      .assert_line_count(3)

    runner
      .type("<C-r>")
      .assert_line_count(2)
      .type("<C-r>")
      .assert_line_count(1)
  end

  # Redo stack clears on new operation

  def test_new_operation_clears_redo_stack
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")

    runner
      .type("x")
      .assert_line(0, "ello world")

    runner
      .type("u")
      .assert_line(0, "hello world")

    # New operation should clear redo stack
    runner
      .type("x")
      .assert_line(0, "ello world")

    # Redo should have no effect (redo stack cleared)
    runner
      .type("<C-r>")
      .assert_line(0, "ello world")
  end

  # Insert mode grouping

  def test_u_undoes_entire_insert_session
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("abc")
      .type("<Esc>")
      .assert_line(0, "abc")

    # One undo should remove all "abc"
    runner
      .type("u")
      .assert_line(0, "")
  end

  def test_u_undoes_insert_with_enter
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2")
      .type("<Esc>")
      .assert_line_count(2)
      .assert_line(0, "Line 1")
      .assert_line(1, "Line 2")

    # One undo should remove both lines
    runner
      .type("u")
      .assert_line_count(1)
      .assert_line(0, "")
  end

  def test_separate_insert_sessions_are_separate_undo_units
    runner = ScriptRunner.new

    # First insert session
    runner
      .type("i")
      .type("AAA")
      .type("<Esc>")

    # Second insert session
    runner
      .type("a")
      .type("BBB")
      .type("<Esc>")

    runner
      .assert_line(0, "AAABBB")

    # First undo removes BBB
    runner
      .type("u")
      .assert_line(0, "AAA")

    # Second undo removes AAA
    runner
      .type("u")
      .assert_line(0, "")
  end

  # Visual mode operations

  def test_u_undoes_visual_delete
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")

    runner
      .type("v")
      .type("llll") # Select "hello"
      .type("d")
      .assert_line(0, " world")

    runner
      .type("u")
      .assert_line(0, "hello world")
  end

  def test_u_undoes_visual_line_delete
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg")

    runner
      .type("V")
      .type("j") # Select 2 lines
      .type("d")
      .assert_line_count(1)
      .assert_line(0, "Line 3")

    runner
      .type("u")
      .assert_line_count(3)
      .assert_line(0, "Line 1")
      .assert_line(1, "Line 2")
  end

  # Edge cases

  def test_u_at_oldest_change_shows_message
    runner = ScriptRunner.new

    runner
      .type("u")
      .assert_message_contains("oldest")
  end

  def test_ctrl_r_at_newest_change_shows_message
    runner = ScriptRunner.new

    runner
      .type("<C-r>")
      .assert_message_contains("newest")
  end

  # o/O commands

  def test_u_undoes_o_command
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1")
      .type("<Esc>")
      .assert_line_count(1)

    runner
      .type("o")
      .type("Line 2")
      .type("<Esc>")
      .assert_line_count(2)
      .assert_line(1, "Line 2")

    runner
      .type("u")
      .assert_line_count(1)
      .assert_line(0, "Line 1")
  end

  def test_u_undoes_upper_o_command
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 2")
      .type("<Esc>")
      .assert_line_count(1)

    runner
      .type("O")
      .type("Line 1")
      .type("<Esc>")
      .assert_line_count(2)
      .assert_line(0, "Line 1")

    runner
      .type("u")
      .assert_line_count(1)
      .assert_line(0, "Line 2")
  end

  # Backspace in insert mode

  def test_u_undoes_backspace_in_insert_mode
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello")
      .type("<BS><BS>") # Delete "lo"
      .type("<Esc>")
      .assert_line(0, "hel")

    runner
      .type("u")
      .assert_line(0, "")
  end

  # Undo/Redo in newly opened buffer via :e

  def test_undo_redo_works_after_edit_command
    Dir.mktmpdir do |dir|
      path = File.join(dir, "test.txt")
      File.write(path, "original\n")

      runner = ScriptRunner.new

      runner
        .type(":e #{path}<Enter>")
        .assert_line(0, "original")
        .type("i")
        .type("NEW ")
        .type("<Esc>")
        .assert_line(0, "NEW original")
        .type("u")
        .assert_line(0, "original")
        .type("<C-r>")
        .assert_line(0, "NEW original")
    end
  end

  # Undo/Redo in split window with file

  def test_undo_redo_works_after_split_horizontal_with_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "split.txt")
      File.write(path, "split content\n")

      runner = ScriptRunner.new

      runner
        .type(":sp #{path}<Enter>")
        .assert_window_count(2)
        .assert_line(0, "split content")
        .type("i")
        .type("ADDED ")
        .type("<Esc>")
        .assert_line(0, "ADDED split content")
        .type("u")
        .assert_line(0, "split content")
        .type("<C-r>")
        .assert_line(0, "ADDED split content")
    end
  end

  def test_undo_redo_works_after_split_vertical_with_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "vsplit.txt")
      File.write(path, "vsplit content\n")

      runner = ScriptRunner.new

      runner
        .type(":vs #{path}<Enter>")
        .assert_window_count(2)
        .assert_line(0, "vsplit content")
        .type("i")
        .type("ADDED ")
        .type("<Esc>")
        .assert_line(0, "ADDED vsplit content")
        .type("u")
        .assert_line(0, "vsplit content")
        .type("<C-r>")
        .assert_line(0, "ADDED vsplit content")
    end
  end

  # Undo/Redo in new tab with file

  def test_undo_redo_works_after_tabnew_with_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "tab.txt")
      File.write(path, "tab content\n")

      runner = ScriptRunner.new

      runner
        .type(":tabnew #{path}<Enter>")
        .assert_tab_count(2)
        .assert_line(0, "tab content")
        .type("i")
        .type("ADDED ")
        .type("<Esc>")
        .assert_line(0, "ADDED tab content")
        .type("u")
        .assert_line(0, "tab content")
        .type("<C-r>")
        .assert_line(0, "ADDED tab content")
    end
  end

  def test_undo_redo_works_after_tabnew_empty
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .assert_tab_count(2)
      .type("i")
      .type("new content")
      .type("<Esc>")
      .assert_line(0, "new content")
      .type("u")
      .assert_line(0, "")
      .type("<C-r>")
      .assert_line(0, "new content")
  end

  # Multi-line paste undo

  def test_linewise_paste_undos_as_single_action
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg")
      .assert_line_count(3)

    # Yank line and paste twice
    runner
      .type("yy")
      .type("p")
      .type("p")
      .assert_line_count(5)

    # First undo should remove the second paste entirely
    runner
      .type("u")
      .assert_line_count(4)

    # Second undo should remove the first paste entirely
    runner
      .type("u")
      .assert_line_count(3)
  end

  def test_multiline_linewise_paste_undos_as_single_action
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("Line 1\nLine 2\nLine 3\n")
      f.flush

      runner = ScriptRunner.new(f.path)

      runner
        .assert_line_count(3)
        .type("gg")

      # Yank 2 lines using visual line mode then paste
      runner
        .type("V")
        .type("j")  # Select 2 lines
        .type("y")  # Yank
        .type("G")  # Go to last line
        .type("p")  # Paste 2 lines after
        .assert_line_count(5)

      # One undo should remove both pasted lines
      runner
        .type("u")
        .assert_line_count(3)
    end
  end

  def test_charwise_multiline_paste_undos_as_single_action
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")
      .assert_line_count(1)

    # Yank "hello" (charwise)
    runner
      .type("v")
      .type("llll")  # Select "hello"
      .type("y")
      .type("$")     # Go to end of line

    # Paste (should insert after cursor)
    runner
      .type("p")
      .assert_line(0, "hello worldhello")

    # Undo should remove entire paste
    runner
      .type("u")
      .assert_line(0, "hello world")
  end
end
