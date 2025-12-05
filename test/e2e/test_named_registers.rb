# frozen_string_literal: true

require_relative "test_helper"

class TestE2ENamedRegisters < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  # Named registers ("a - "z)

  def test_quote_a_yy_yanks_to_named_register_a
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg")

    runner
      .type('"ayy')
      .assert_register("a", "Line 1", linewise: true)
      .assert_line_count(3) # Buffer unchanged
  end

  def test_quote_a_p_pastes_from_named_register_a
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2")
      .type("<Esc>")
      .type("gg")
      .type('"ayy') # Yank Line 1 to register a
      .type("j") # Move to Line 2

    runner
      .type('"ap')
      .assert_line_count(3)
      .assert_line(0, "Line 1")
      .assert_line(1, "Line 2")
      .assert_line(2, "Line 1") # Pasted from register a
  end

  def test_multiple_named_registers
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("AAA<Enter>BBB<Enter>CCC")
      .type("<Esc>")
      .type("gg")

    # Yank each line to different registers
    runner
      .type('"ayy')
      .type("j")
      .type('"byy')
      .type("j")
      .type('"cyy')

    runner
      .assert_register("a", "AAA", linewise: true)
      .assert_register("b", "BBB", linewise: true)
      .assert_register("c", "CCC", linewise: true)

    # Paste from register b
    runner
      .type('"bp')
      .assert_line_count(4)
      .assert_line(3, "BBB")
  end

  # Yank register ("0)

  def test_yank_register_stores_last_yank
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0") # Move to start

    runner
      .type("yw") # Yank "hello"
      .assert_register("0", "hello", linewise: false)
  end

  def test_delete_does_not_overwrite_yank_register
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")
      .type("yw") # Yank "hello"
      .assert_register("0", "hello")

    runner
      .type("dw") # Delete "hello " (includes trailing space)
      .assert_register("0", "hello") # Yank register unchanged
      .assert_register(nil, "hello ") # Unnamed register has deleted text with space
  end

  def test_quote_0_p_pastes_from_yank_register
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world foo")
      .type("<Esc>")
      .type("0")
      .type("yw") # Yank "hello" to "0
      .type("w")  # Move to "world"
      .type("dw") # Delete "world " - unnamed register now has "world "

    # Paste from yank register "0 (should paste "hello", not "world ")
    # After dw, cursor is at 'f' of foo, "0p pastes after cursor
    runner
      .type('"0P') # Paste before cursor
      .assert_line(0, "hello hellofoo")
  end

  # Delete history registers ("1 - "9)

  def test_dd_saves_to_delete_history
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg")

    runner
      .type("dd")
      .assert_register("1", "Line 1", linewise: true)
      .assert_line_count(2)
  end

  def test_delete_history_shifts_on_each_delete
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("First<Enter>Second<Enter>Third<Enter>Fourth")
      .type("<Esc>")
      .type("gg")

    runner
      .type("dd") # Delete "First"
      .assert_register("1", "First")
      .type("dd") # Delete "Second"
      .assert_register("1", "Second")
      .assert_register("2", "First")
      .type("dd") # Delete "Third"
      .assert_register("1", "Third")
      .assert_register("2", "Second")
      .assert_register("3", "First")
  end

  def test_quote_2_p_pastes_from_delete_history
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("First<Enter>Second<Enter>Third")
      .type("<Esc>")
      .type("gg")

    runner
      .type("dd") # "1 = First
      .type("dd") # "1 = Second, "2 = First

    # Paste from "2 (First)
    runner
      .type('"2p')
      .assert_line_count(2)
      .assert_line(1, "First")
  end

  # Black hole register ("_)

  def test_black_hole_register_does_not_save_on_delete
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2")
      .type("<Esc>")
      .type("gg")

    runner
      .type('"_dd')
      .assert_line_count(1)
      .assert_line(0, "Line 2")
      .assert_register_empty(nil)  # Unnamed register empty
      .assert_register_empty("1")  # Delete history empty
  end

  def test_black_hole_register_preserves_unnamed_register
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")
      .type("yw") # Yank "hello"
      .assert_register(nil, "hello")

    runner
      .type("w")     # Move to "world"
      .type('"_dw')  # Delete "world" to black hole
      .assert_register(nil, "hello") # Unchanged
  end

  # Unnamed register ("")

  def test_quote_quote_p_same_as_p
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")
      .type("yw") # Yank "hello"
      .type("$")  # Move to end

    runner
      .type('""p')
      .assert_line(0, "hello worldhello")
  end

  # Visual mode with named registers

  def test_visual_mode_yank_to_named_register
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")

    runner
      .type("v")
      .type("llll") # Select "hello"
      .type('"ay')
      .assert_register("a", "hello", linewise: false)
      .assert_mode(Mui::Mode::NORMAL)
  end

  def test_visual_mode_delete_to_named_register
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")

    runner
      .type("v")
      .type("llll")
      .type('"ad')
      .assert_register("a", "hello")
      .assert_line(0, " world")
  end

  def test_visual_line_mode_yank_to_named_register
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Line 1<Enter>Line 2<Enter>Line 3")
      .type("<Esc>")
      .type("gg")

    runner
      .type("V")
      .type("j") # Select 2 lines
      .type('"ay')
      .assert_register("a", "Line 1\nLine 2", linewise: true)
      .assert_line_count(3) # Buffer unchanged
  end

  # Change operator with registers

  def test_cc_saves_to_delete_history
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")

    runner
      .type("cc")
      .assert_register("1", "hello world", linewise: true)
      .assert_mode(Mui::Mode::INSERT)
  end

  def test_cw_saves_to_delete_history
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")

    runner
      .type("cw")
      .assert_register("1", "hello", linewise: false)
      .type("goodbye")
      .type("<Esc>")
      .assert_line(0, "goodbye world")
  end

  def test_quote_a_cw_saves_to_named_register
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("hello world")
      .type("<Esc>")
      .type("0")

    runner
      .type('"acw')
      .assert_register("a", "hello", linewise: false)
      .assert_register_empty("1") # Delete history not affected
      .type("goodbye")
      .type("<Esc>")
      .assert_line(0, "goodbye world")
  end

  # Complex workflow

  def test_workflow_yank_delete_paste_from_different_registers
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("AAA BBB CCC")
      .type("<Esc>")
      .type("0")

    # Yank "AAA" to unnamed register first (for "0)
    runner
      .type("yw")
      .assert_register(nil, "AAA")
      .assert_register("0", "AAA")

    # Move to "BBB" and delete it (goes to unnamed and "1)
    runner
      .type("w")
      .type("dw") # Deletes "BBB " (with space)
      .assert_register(nil, "BBB ")
      .assert_register("1", "BBB ")
      .assert_register("0", "AAA") # Yank register preserved

    # Now paste from yank register "0 before cursor
    runner
      .type('"0P')
      .assert_line(0, "AAA AAACCC")
  end
end
