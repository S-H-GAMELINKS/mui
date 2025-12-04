# frozen_string_literal: true

require "test_helper"

class TestEditorNormalMode < Minitest::Test
  class TestCursorMovement < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::NORMAL
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_h_moves_cursor_left
      @editor.buffer.insert_char(0, 0, "a")
      @editor.buffer.insert_char(0, 1, "b")
      @editor.buffer.insert_char(0, 2, "c")
      @editor.window.cursor_col = 2

      @editor.handle_normal_key("h")

      assert_equal 1, @editor.window.cursor_col
    end

    def test_h_does_not_move_past_left_edge
      @editor.buffer.insert_char(0, 0, "a")
      @editor.window.cursor_col = 0

      @editor.handle_normal_key("h")

      assert_equal 0, @editor.window.cursor_col
    end

    def test_j_moves_cursor_down
      @editor.buffer.insert_line(1, "line2")
      @editor.window.cursor_row = 0

      @editor.handle_normal_key("j")

      assert_equal 1, @editor.window.cursor_row
    end

    def test_j_does_not_move_past_last_line
      @editor.window.cursor_row = 0

      @editor.handle_normal_key("j")

      assert_equal 0, @editor.window.cursor_row
    end

    def test_k_moves_cursor_up
      @editor.buffer.insert_line(1, "line2")
      @editor.window.cursor_row = 1

      @editor.handle_normal_key("k")

      assert_equal 0, @editor.window.cursor_row
    end

    def test_k_does_not_move_past_first_line
      @editor.window.cursor_row = 0

      @editor.handle_normal_key("k")

      assert_equal 0, @editor.window.cursor_row
    end

    def test_l_moves_cursor_right
      @editor.buffer.insert_char(0, 0, "a")
      @editor.buffer.insert_char(0, 1, "b")
      @editor.buffer.insert_char(0, 2, "c")
      @editor.window.cursor_col = 0

      @editor.handle_normal_key("l")

      assert_equal 1, @editor.window.cursor_col
    end

    def test_l_does_not_move_past_last_character
      @editor.buffer.insert_char(0, 0, "a")
      @editor.buffer.insert_char(0, 1, "b")
      @editor.buffer.insert_char(0, 2, "c")
      @editor.window.cursor_col = 2

      @editor.handle_normal_key("l")

      assert_equal 2, @editor.window.cursor_col
    end

    def test_arrow_left_works_like_h
      @editor.buffer.insert_char(0, 0, "a")
      @editor.buffer.insert_char(0, 1, "b")
      @editor.window.cursor_col = 1

      @editor.handle_normal_key(Curses::KEY_LEFT)

      assert_equal 0, @editor.window.cursor_col
    end

    def test_arrow_right_works_like_l
      @editor.buffer.insert_char(0, 0, "a")
      @editor.buffer.insert_char(0, 1, "b")
      @editor.window.cursor_col = 0

      @editor.handle_normal_key(Curses::KEY_RIGHT)

      assert_equal 1, @editor.window.cursor_col
    end

    def test_arrow_up_works_like_k
      @editor.buffer.insert_line(1, "line2")
      @editor.window.cursor_row = 1

      @editor.handle_normal_key(Curses::KEY_UP)

      assert_equal 0, @editor.window.cursor_row
    end

    def test_arrow_down_works_like_j
      @editor.buffer.insert_line(1, "line2")
      @editor.window.cursor_row = 0

      @editor.handle_normal_key(Curses::KEY_DOWN)

      assert_equal 1, @editor.window.cursor_row
    end
  end

  class TestModeTransition < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::NORMAL
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_i_enters_insert_mode
      @editor.handle_normal_key("i")

      assert_equal Mui::Mode::INSERT, @editor.mode
    end

    def test_a_enters_insert_mode_after_cursor
      @editor.buffer.insert_char(0, 0, "a")
      @editor.buffer.insert_char(0, 1, "b")
      @editor.window.cursor_col = 0

      @editor.handle_normal_key("a")

      assert_equal Mui::Mode::INSERT, @editor.mode
      assert_equal 1, @editor.window.cursor_col
    end

    def test_a_on_empty_line_stays_at_position
      @editor.window.cursor_col = 0

      @editor.handle_normal_key("a")

      assert_equal Mui::Mode::INSERT, @editor.mode
      assert_equal 0, @editor.window.cursor_col
    end

    def test_o_opens_new_line_below
      @editor.buffer.lines[0] = "first"
      @editor.window.cursor_row = 0

      @editor.handle_normal_key("o")

      assert_equal Mui::Mode::INSERT, @editor.mode
      assert_equal 1, @editor.window.cursor_row
      assert_equal 0, @editor.window.cursor_col
      assert_equal 2, @editor.buffer.line_count
      assert_equal "", @editor.buffer.line(1)
    end

    def test_O_opens_new_line_above
      @editor.buffer.lines[0] = "first"
      @editor.window.cursor_row = 0

      @editor.handle_normal_key("O")

      assert_equal Mui::Mode::INSERT, @editor.mode
      assert_equal 0, @editor.window.cursor_row
      assert_equal 0, @editor.window.cursor_col
      assert_equal 2, @editor.buffer.line_count
      assert_equal "", @editor.buffer.line(0)
      assert_equal "first", @editor.buffer.line(1)
    end

    def test_colon_enters_command_mode
      @editor.handle_normal_key(":")

      assert_equal Mui::Mode::COMMAND, @editor.mode
      assert_equal "", @editor.command_line.buffer
    end
  end

  class TestDelete < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::NORMAL
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_x_deletes_character_at_cursor
      @editor.buffer.insert_char(0, 0, "a")
      @editor.buffer.insert_char(0, 1, "b")
      @editor.buffer.insert_char(0, 2, "c")
      @editor.window.cursor_col = 1

      @editor.handle_normal_key("x")

      assert_equal "ac", @editor.buffer.line(0)
    end
  end
end
