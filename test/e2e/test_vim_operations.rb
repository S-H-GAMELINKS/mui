# frozen_string_literal: true

require_relative "test_helper"

class TestE2EVimOperations < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  def test_vim_navigation_hjkl
    # Scenario: Cursor movement with hjkl
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("ABCDE<Enter>FGHIJ<Enter>KLMNO")
      .type("<Esc>")
      .assert_line_count(3)
      .assert_cursor(2, 4)  # Last character position (moves back from O on Esc)

    runner
      .type("k")            # Up
      .assert_cursor(1, 4)
      .type("k")            # Up
      .assert_cursor(0, 4)
      .type("k")            # Can't go higher
      .assert_cursor(0, 4)

    runner
      .type("h")            # Left
      .assert_cursor(0, 3)
      .type("hh")           # Left twice
      .assert_cursor(0, 1)

    runner
      .type("j")            # Down
      .assert_cursor(1, 1)
      .type("j")            # Down
      .assert_cursor(2, 1)

    runner
      .type("l")            # Right
      .assert_cursor(2, 2)
      .type("lll")          # Right 3 times (max 4)
      .assert_cursor(2, 4)
  end

  def test_vim_navigation_arrow_keys
    # Scenario: Cursor movement with arrow keys
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("ABC<Enter>DEF")
      .type("<Esc>")
      .assert_cursor(1, 2)

    runner
      .type("<Up>")
      .assert_cursor(0, 2)
      .type("<Down>")
      .assert_cursor(1, 2)
      .type("<Left>")
      .assert_cursor(1, 1)
      .type("<Right>")
      .assert_cursor(1, 2)
  end

  def test_vim_editing_x_delete
    # Scenario: Delete character with x
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("ABCDE")
      .type("<Esc>")
      .assert_line(0, "ABCDE")

    runner
      .type("h")             # Move to D position
      .type("x")             # Delete D
      .assert_line(0, "ABCE")

    runner
      .type("hh")            # Move to B position
      .type("x")             # Delete B
      .assert_line(0, "ACE")
  end

  def test_vim_editing_o_new_line_below
    # Scenario: Insert new line below with o
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("First")
      .type("<Esc>")
      .type("o") # New line below
      .assert_mode(Mui::Mode::INSERT)
      .type("Second")
      .type("<Esc>")
      .assert_line_count(2)
      .assert_line(0, "First")
      .assert_line(1, "Second")
  end

  def test_vim_editing_O_new_line_above
    # Scenario: Insert new line above with O
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Second")
      .type("<Esc>")
      .type("O") # New line above
      .assert_mode(Mui::Mode::INSERT)
      .type("First")
      .type("<Esc>")
      .assert_line_count(2)
      .assert_line(0, "First")
      .assert_line(1, "Second")
  end

  def test_vim_insert_modes_i_a
    # Scenario: Difference between i and a
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("AC")
      .type("<Esc>")
      .assert_line(0, "AC")
      .assert_cursor(0, 1) # At C position

    # Move to A position with h and use a to append
    runner
      .type("h")             # Move to A position
      .assert_cursor(0, 0)
      .type("a")             # Insert after A
      .assert_mode(Mui::Mode::INSERT)
      .type("B")
      .type("<Esc>")
      .assert_line(0, "ABC")
  end

  def test_multiline_editing
    # Scenario: Multi-line editing
    runner = ScriptRunner.new

    # Input 10 lines
    runner.type("i")
    10.times do |i|
      runner.type("Line #{i + 1}")
      runner.type("<Enter>") if i < 9
    end
    runner.type("<Esc>")

    runner
      .assert_line_count(10)
      .assert_line(0, "Line 1")
      .assert_line(9, "Line 10")
      .assert_cursor(9, 6) # One position back from end of "Line 10"

    # Move up
    5.times { runner.type("k") }
    runner.assert_cursor(4, 5) # "Line 5" position (length 6 so col 5)
  end

  def test_backspace_join_lines
    # Scenario: Join lines with Backspace
    runner = ScriptRunner.new

    # Create simple 2 lines
    runner
      .type("i")
      .type("AB")
      .type("<Enter>")
      .type("CD")
      .type("<Esc>")
      .assert_line_count(2)
      .assert_line(0, "AB")
      .assert_line(1, "CD")

    # After Esc, col is 1 ("D" position)
    # 'i' enters Insert mode before "D"
    runner
      .type("i")
      .type("<BS>")          # Delete "C"
      .assert_line(1, "D")
      .type("<BS>")          # Backspace at line start -> join lines
      .assert_line_count(1)
      .assert_line(0, "ABD")
      .type("<Esc>")
  end

  def test_mode_transitions
    # Scenario: Mode transition verification
    runner = ScriptRunner.new

    runner
      .assert_mode(Mui::Mode::NORMAL)
      .type("i")
      .assert_mode(Mui::Mode::INSERT)
      .type("<Esc>")
      .assert_mode(Mui::Mode::NORMAL)
      .type(":")
      .assert_mode(Mui::Mode::COMMAND)
      .type("<Esc>")
      .assert_mode(Mui::Mode::NORMAL)
  end

  def test_cursor_clamp_on_vertical_movement
    # Scenario: Cursor clamped when moving to shorter line
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("This is a long line")
      .type("<Enter>")
      .type("Short")
      .type("<Esc>")
      .assert_cursor(1, 4) # End of "Short"

    # Move to longer line above
    runner
      .type("k")
      .assert_cursor(0, 4) # Cursor position is maintained

    # Move to end of line
    runner
      .type("lllllllllllllll")  # Move to end
      .assert_cursor(0, 18)     # End of "This is a long line"

    # Move to shorter line below -> cursor gets clamped
    runner
      .type("j")
      .assert_cursor(1, 4) # Clamped to end of "Short"
  end

  def test_complete_editing_workflow
    # Scenario: Complete editing workflow
    runner = ScriptRunner.new

    # 1. Text input
    runner
      .type("i")
      .type("ABCD")
      .type("<Esc>")
      .assert_line(0, "ABCD")

    # 2. Delete with x (after Esc, col 3 = "D" position)
    runner
      .type("x")
      .assert_line(0, "ABC")

    # 3. Insert in middle with i
    # After deleting D, cursor is at C position (col 2)
    # h moves to B position (col 1)
    # i inserts before B
    runner
      .type("h") # Move to "B" position
      .type("i")
      .type("X")
      .type("<Esc>")
      .assert_line(0, "ABXC") # "X" inserted before "B"

    # 4. Add new line
    runner
      .type("o")
      .type("Line 2")
      .type("<Esc>")
      .assert_line_count(2)
      .assert_line(1, "Line 2")

    # 5. Quit (without saving)
    runner
      .type(":q!<Enter>")
      .assert_running(false)
  end

  def test_dd_delete_line
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .assert_line_count(3)

    runner
      .type("k") # Move to Line 2
      .type("dd")
      .assert_line_count(2)
      .assert_line(0, "Line 1")
      .assert_line(1, "Line 3")
  end

  def test_dw_delete_word
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world foo")
      .type("<Esc>")
      .type("0") # Move to start

    runner
      .type("dw")
      .assert_line(0, "world foo")
  end

  def test_d_dollar_delete_to_line_end
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0") # Move to start
      .type("w") # Move to "world"
      .assert_cursor(0, 6)

    runner
      .type("d$")
      .assert_line(0, "hello ")
  end

  def test_visual_mode_delete
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0") # Move to start

    runner
      .type("v")
      .assert_mode(Mui::Mode::VISUAL)
      .type("llll") # Select "hello"
      .type("d")
      .assert_mode(Mui::Mode::NORMAL)
      .assert_line(0, " world")
  end

  def test_visual_line_mode_delete
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg") # Move to start

    runner
      .type("V")
      .assert_mode(Mui::Mode::VISUAL_LINE)
      .type("j") # Select 2 lines
      .type("d")
      .assert_mode(Mui::Mode::NORMAL)
      .assert_line_count(1)
      .assert_line(0, "Line 3")
  end

  def test_cc_change_line
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("k") # Move to Line 2
      .assert_line(1, "Line 2")

    runner
      .type("cc")
      .assert_mode(Mui::Mode::INSERT)
      .assert_line(1, "")
      .type("New Line 2")
      .type("<Esc>")
      .assert_line(1, "New Line 2")
  end

  def test_cw_change_word
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world foo")
      .type("<Esc>")
      .type("0") # Move to start

    # cw behaves like ce in Vim (changes to end of word, preserving space)
    runner
      .type("cw")
      .assert_mode(Mui::Mode::INSERT)
      .type("goodbye")
      .type("<Esc>")
      .assert_line(0, "goodbye world foo")
  end

  def test_c_dollar_change_to_line_end
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0") # Move to start
      .type("w") # Move to "world"
      .assert_cursor(0, 6)

    runner
      .type("c$")
      .assert_mode(Mui::Mode::INSERT)
      .type("universe")
      .type("<Esc>")
      .assert_line(0, "hello universe")
  end

  def test_visual_mode_change
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0") # Move to start

    runner
      .type("v")
      .assert_mode(Mui::Mode::VISUAL)
      .type("llll") # Select "hello"
      .type("c")
      .assert_mode(Mui::Mode::INSERT)
      .type("goodbye")
      .type("<Esc>")
      .assert_line(0, "goodbye world")
  end

  def test_visual_line_mode_change
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg") # Move to start

    runner
      .type("V")
      .assert_mode(Mui::Mode::VISUAL_LINE)
      .type("j") # Select 2 lines
      .type("c")
      .assert_mode(Mui::Mode::INSERT)
      .assert_line_count(2)
      .type("New content")
      .type("<Esc>")
      .assert_line(0, "New content")
      .assert_line(1, "Line 3")
  end

  def test_yy_yank_line
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg") # Move to Line 1

    runner
      .type("yy")
      .assert_line_count(3) # No change to buffer

    # p should paste the line below
    runner
      .type("p")
      .assert_line_count(4)
      .assert_line(0, "Line 1")
      .assert_line(1, "Line 1")
      .assert_line(2, "Line 2")
      .assert_line(3, "Line 3")
  end

  def test_yw_yank_word
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world foo")
      .type("<Esc>")
      .type("0") # Move to start

    runner
      .type("yw")
      .assert_line(0, "hello world foo") # No change

    # p should paste the word after cursor
    runner
      .type("p")
      .assert_line(0, "hhelloello world foo")
  end

  def test_y_dollar_yank_to_line_end
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0") # Move to start
      .type("w") # Move to "world"
      .assert_cursor(0, 6)

    runner
      .type("y$")
      .assert_line(0, "hello world") # No change

    # p should paste after cursor
    runner
      .type("p")
      .assert_line(0, "hello wworldorld")
  end

  def test_P_paste_before
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0") # Move to start
      .type("yw") # Yank "hello"
      .type("w") # Move to "world"
      .assert_cursor(0, 6)

    # P should paste before cursor
    runner
      .type("P")
      .assert_line(0, "hello helloworld")
  end

  def test_yy_p_paste_line_below
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg") # Move to Line 1
      .type("j") # Move to Line 2

    runner
      .type("yy")
      .type("p")
      .assert_line_count(4)
      .assert_line(0, "Line 1")
      .assert_line(1, "Line 2")
      .assert_line(2, "Line 2")
      .assert_line(3, "Line 3")
  end

  def test_yy_P_paste_line_above
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg") # Move to Line 1
      .type("j") # Move to Line 2

    runner
      .type("yy")
      .type("P")
      .assert_line_count(4)
      .assert_line(0, "Line 1")
      .assert_line(1, "Line 2")
      .assert_line(2, "Line 2")
      .assert_line(3, "Line 3")
      .assert_cursor(1, 0) # Cursor stays on pasted line
  end

  def test_goto_line_command
    # Scenario: Jump to specific line with :number command
    runner = ScriptRunner.new

    # Create 10 lines
    runner.type("i")
    10.times do |i|
      runner.type("Line #{i + 1}")
      runner.type("<Enter>") if i < 9
    end
    runner.type("<Esc>")

    runner
      .assert_line_count(10)
      .assert_cursor(9, 6) # Last position

    # Jump to line 5
    runner
      .type(":5<Enter>")
      .assert_cursor(4, 0) # Line 5 (0-indexed = 4), column 0
      .assert_mode(Mui::Mode::NORMAL)

    # Jump to line 1
    runner
      .type(":1<Enter>")
      .assert_cursor(0, 0) # Line 1 (0-indexed = 0), column 0

    # Jump to line 10
    runner
      .type(":10<Enter>")
      .assert_cursor(9, 0) # Line 10 (0-indexed = 9), column 0
  end

  def test_goto_line_clamps_to_valid_range
    # Scenario: Jump beyond file bounds gets clamped
    runner = ScriptRunner.new

    # Create 5 lines
    runner.type("i")
    5.times do |i|
      runner.type("Line #{i + 1}")
      runner.type("<Enter>") if i < 4
    end
    runner.type("<Esc>")

    runner.assert_line_count(5)

    # Jump to line 100 (should clamp to last line 5)
    runner
      .type(":100<Enter>")
      .assert_cursor(4, 0) # Clamped to line 5 (0-indexed = 4)

    # Jump to line 0 (should clamp to line 1)
    runner
      .type(":0<Enter>")
      .assert_cursor(0, 0) # Clamped to line 1 (0-indexed = 0)
  end
end
