# frozen_string_literal: true

require_relative "test_helper"

class TestE2EMotion < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  def test_word_forward_w
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world foo bar")
      .type("<Esc>")
      .type("0") # Go to start of line

    runner
      .assert_cursor(0, 0)
      .type("w")
      .assert_cursor(0, 6) # "world"
      .type("w")
      .assert_cursor(0, 12) # "foo"
      .type("w")
      .assert_cursor(0, 16) # "bar"
  end

  def test_word_backward_b
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world foo bar")
      .type("<Esc>")
      .assert_cursor(0, 18) # End of line

    runner
      .type("b")
      .assert_cursor(0, 16) # "bar"
      .type("b")
      .assert_cursor(0, 12) # "foo"
      .type("b")
      .assert_cursor(0, 6) # "world"
      .type("b")
      .assert_cursor(0, 0) # "hello"
  end

  def test_word_end_e
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world foo")
      .type("<Esc>")
      .type("0") # Go to start of line

    runner
      .assert_cursor(0, 0)
      .type("e")
      .assert_cursor(0, 4) # End of "hello"
      .type("e")
      .assert_cursor(0, 10) # End of "world"
      .type("e")
      .assert_cursor(0, 14) # End of "foo"
  end

  def test_line_start_0
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .assert_cursor(0, 10)

    runner
      .type("0")
      .assert_cursor(0, 0)
  end

  def test_first_non_blank_caret
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("   hello world")
      .type("<Esc>")
      .type("0") # Go to start of line

    runner
      .assert_cursor(0, 0)
      .type("^")
      .assert_cursor(0, 3) # First non-blank character
  end

  def test_line_end_dollar
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0") # Go to start of line

    runner
      .assert_cursor(0, 0)
      .type("$")
      .assert_cursor(0, 10) # End of line
  end

  def test_file_start_gg
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("line1<Enter>line2<Enter>line3")
      .type("<Esc>")
      .assert_cursor(2, 4) # End of line3

    runner
      .type("gg")
      .assert_cursor(0, 0) # Start of file
  end

  def test_file_end_G
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("line1<Enter>line2<Enter>line3")
      .type("<Esc>")
      .type("gg") # Go to start

    runner
      .assert_cursor(0, 0)
      .type("G")
      .assert_cursor(2, 0) # Start of last line
  end

  def test_find_char_forward_f
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0") # Go to start of line

    runner
      .assert_cursor(0, 0)
      .type("fo") # Find 'o'
      .assert_cursor(0, 4) # First 'o' in "hello"
      .type("fo") # Find next 'o'
      .assert_cursor(0, 7) # 'o' in "world"
  end

  def test_find_char_backward_F
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .assert_cursor(0, 10) # End of line

    runner
      .type("Fo") # Find 'o' backward
      .assert_cursor(0, 7) # 'o' in "world"
      .type("Fo") # Find 'o' backward again
      .assert_cursor(0, 4) # 'o' in "hello"
  end

  def test_till_char_forward_t
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0") # Go to start of line

    runner
      .assert_cursor(0, 0)
      .type("to") # Till 'o'
      .assert_cursor(0, 3) # One before 'o' in "hello"
  end

  def test_till_char_backward_T
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .assert_cursor(0, 10) # End of line

    runner
      .type("To") # Till 'o' backward
      .assert_cursor(0, 8) # One after 'o' in "world"
  end

  def test_word_movement_across_lines
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello<Enter>world")
      .type("<Esc>")
      .type("gg") # Go to start
      .type("$") # Go to end of first line

    runner
      .assert_cursor(0, 4)
      .type("w") # Should move to next line
      .assert_cursor(1, 0) # Start of "world"
  end

  def test_combined_motions
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("first line<Enter>second line<Enter>third line")
      .type("<Esc>")

    # Go to start, then navigate
    runner
      .type("gg")
      .assert_cursor(0, 0)
      .type("G") # Go to last line
      .assert_cursor(2, 0)
      .type("$") # Go to end of line
      .assert_cursor(2, 9) # End of "third line"
      .type("b") # Back one word
      .assert_cursor(2, 6) # Start of "line"
      .type("gg") # Back to start
      .assert_cursor(0, 0)
  end

  def test_motion_with_editing
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world foo")
      .type("<Esc>")
      .type("0") # Go to start

    # Navigate to "world" and delete it
    runner
      .type("w") # Move to "world"
      .assert_cursor(0, 6)
      .type("x") # Delete 'w'
      .assert_line(0, "hello orld foo")
  end

  def test_g_without_second_key
    # Test that pressing 'g' alone doesn't crash
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello")
      .type("<Esc>")
      .type("g") # Pending motion
      .type("j") # Not 'g', should cancel and do nothing useful
      .assert_cursor(0, 4) # Should stay at same position
  end

  def test_f_not_found
    # Test that f with non-existent char doesn't move cursor
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello")
      .type("<Esc>")
      .type("0")
      .assert_cursor(0, 0)
      .type("fz") # 'z' doesn't exist
      .assert_cursor(0, 0) # Should stay at same position
  end
end
