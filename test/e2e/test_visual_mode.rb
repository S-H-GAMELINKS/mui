# frozen_string_literal: true

require_relative "test_helper"

class TestE2EVisualMode < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  def test_v_enters_visual_mode
    runner = ScriptRunner.new

    runner
      .type("iHello World<Esc>")
      .assert_mode(Mui::Mode::NORMAL)
      .type("0")
      .assert_cursor(0, 0)

    runner
      .type("v")
      .assert_mode(Mui::Mode::VISUAL)
      .assert_selection(0, 0, 0, 0)
      .assert_line_mode(false)
  end

  def test_upper_v_enters_visual_line_mode
    runner = ScriptRunner.new

    runner
      .type("iHello<Enter>World<Esc>")
      .assert_mode(Mui::Mode::NORMAL)
      .type("k0")
      .assert_cursor(0, 0)

    runner
      .type("V")
      .assert_mode(Mui::Mode::VISUAL_LINE)
      .assert_selection(0, 0, 0, 0)
      .assert_line_mode(true)
  end

  def test_escape_exits_visual_mode
    runner = ScriptRunner.new

    runner
      .type("iHello<Esc>")
      .type("0v")
      .assert_mode(Mui::Mode::VISUAL)

    runner
      .type("<Esc>")
      .assert_mode(Mui::Mode::NORMAL)
      .assert_no_selection
  end

  def test_visual_mode_selection_expands_with_movement
    runner = ScriptRunner.new

    runner
      .type("iHello World<Esc>")
      .type("0v")
      .assert_selection(0, 0, 0, 0)

    runner
      .type("l")
      .assert_selection(0, 0, 0, 1)
      .type("ll")
      .assert_selection(0, 0, 0, 3)
  end

  def test_visual_mode_selection_with_word_motion
    runner = ScriptRunner.new

    runner
      .type("iHello World Foo<Esc>")
      .type("0v")
      .assert_selection(0, 0, 0, 0)

    runner
      .type("w")
      .assert_selection(0, 0, 0, 6)
      .type("w")
      .assert_selection(0, 0, 0, 12)
  end

  def test_visual_mode_selection_across_lines
    runner = ScriptRunner.new

    runner
      .type("iLine1<Enter>Line2<Enter>Line3<Esc>")
      .type("gg0")
      .assert_cursor(0, 0)

    runner
      .type("v")
      .type("j")
      .assert_selection(0, 0, 1, 0)
      .type("j")
      .assert_selection(0, 0, 2, 0)
  end

  def test_visual_line_mode_selection_across_lines
    runner = ScriptRunner.new

    runner
      .type("iLine1<Enter>Line2<Enter>Line3<Esc>")
      .type("gg")
      .assert_cursor(0, 0)

    runner
      .type("V")
      .assert_line_mode(true)
      .type("j")
      .assert_selection(0, 0, 1, 0)
      .assert_line_mode(true)
  end

  def test_v_toggles_between_visual_and_normal
    runner = ScriptRunner.new

    runner
      .type("iHello<Esc>")
      .type("0v")
      .assert_mode(Mui::Mode::VISUAL)

    runner
      .type("v")
      .assert_mode(Mui::Mode::NORMAL)
      .assert_no_selection
  end

  def test_upper_v_toggles_between_visual_line_and_normal
    runner = ScriptRunner.new

    runner
      .type("iHello<Esc>")
      .type("0V")
      .assert_mode(Mui::Mode::VISUAL_LINE)

    runner
      .type("V")
      .assert_mode(Mui::Mode::NORMAL)
      .assert_no_selection
  end

  def test_v_in_visual_line_toggles_to_visual_char
    runner = ScriptRunner.new

    runner
      .type("iHello<Esc>")
      .type("0V")
      .assert_mode(Mui::Mode::VISUAL_LINE)
      .assert_line_mode(true)

    runner
      .type("v")
      .assert_mode(Mui::Mode::VISUAL)
      .assert_line_mode(false)
  end

  def test_upper_v_in_visual_char_toggles_to_visual_line
    runner = ScriptRunner.new

    runner
      .type("iHello<Esc>")
      .type("0v")
      .assert_mode(Mui::Mode::VISUAL)
      .assert_line_mode(false)

    runner
      .type("V")
      .assert_mode(Mui::Mode::VISUAL_LINE)
      .assert_line_mode(true)
  end

  def test_visual_mode_backward_selection
    runner = ScriptRunner.new

    runner
      .type("iHello World<Esc>")
      .type("$v")
      .assert_cursor(0, 10)

    runner
      .type("h")
      .assert_selection(0, 10, 0, 9)
      .type("hh")
      .assert_selection(0, 10, 0, 7)
  end

  def test_visual_mode_with_gg_motion
    runner = ScriptRunner.new

    runner
      .type("iLine1<Enter>Line2<Enter>Line3<Esc>")
      .assert_cursor(2, 4)
      .type("v")

    runner
      .type("gg")
      .assert_cursor(0, 0)
      .assert_selection(2, 4, 0, 0)
  end

  def test_visual_mode_with_G_motion
    runner = ScriptRunner.new

    runner
      .type("iLine1<Enter>Line2<Enter>Line3<Esc>")
      .type("gg0v")
      .assert_cursor(0, 0)

    runner
      .type("G")
      .assert_cursor(2, 0)
      .assert_selection(0, 0, 2, 0)
  end

  def test_visual_mode_preserves_start_position
    runner = ScriptRunner.new

    runner
      .type("iHello World<Esc>")
      .type("0llv")
      .assert_selection(0, 2, 0, 2)

    runner
      .type("llll")
      .assert_selection(0, 2, 0, 6)

    runner
      .type("hhhhhh")
      .assert_selection(0, 2, 0, 0)

    # Start position should not change
    selection = runner.editor.selection
    assert_equal 0, selection.start_row
    assert_equal 2, selection.start_col
  end

  def test_visual_mode_with_f_motion
    runner = ScriptRunner.new

    runner
      .type("iHello World<Esc>")
      .type("0v")
      .assert_cursor(0, 0)

    runner
      .type("fo")
      .assert_cursor(0, 4)
      .assert_selection(0, 0, 0, 4)
  end

  def test_visual_mode_with_dollar_motion
    runner = ScriptRunner.new

    runner
      .type("iHello World<Esc>")
      .type("0v")
      .assert_cursor(0, 0)

    runner
      .type("$")
      .assert_cursor(0, 10)
      .assert_selection(0, 0, 0, 10)
  end

  def test_visual_mode_with_caret_motion
    runner = ScriptRunner.new

    runner
      .type("i  Hello<Esc>")
      .type("$v")
      .assert_cursor(0, 6)

    runner
      .type("^")
      .assert_cursor(0, 2)
      .assert_selection(0, 6, 0, 2)
  end
end
