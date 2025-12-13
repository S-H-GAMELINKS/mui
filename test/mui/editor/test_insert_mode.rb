# frozen_string_literal: true

require "test_helper"

class TestEditorInsertMode < Minitest::Test
  class TestEscape < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::INSERT
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_returns_to_normal_mode
      @editor.buffer.insert_char(0, 0, "a")
      @editor.window.cursor_col = 1

      @editor.handle_insert_key(27)

      assert_equal Mui::Mode::NORMAL, @editor.mode
      assert_equal 0, @editor.window.cursor_col
    end

    def test_at_column_zero_stays
      @editor.window.cursor_col = 0

      @editor.handle_insert_key(27)

      assert_equal Mui::Mode::NORMAL, @editor.mode
      assert_equal 0, @editor.window.cursor_col
    end
  end

  class TestCharacterInput < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::INSERT
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_inserts_char
      @editor.window.cursor_col = 0

      @editor.handle_insert_key("a")

      assert_equal "a", @editor.buffer.line(0)
      assert_equal 1, @editor.window.cursor_col
    end

    def test_multiple_characters
      @editor.window.cursor_col = 0

      @editor.handle_insert_key("H")
      @editor.handle_insert_key("i")

      assert_equal "Hi", @editor.buffer.line(0)
      assert_equal 2, @editor.window.cursor_col
    end

    def test_integer_character
      @editor.window.cursor_col = 0

      @editor.handle_insert_key(65) # 'A'

      assert_equal "A", @editor.buffer.line(0)
      assert_equal 1, @editor.window.cursor_col
    end

    def test_non_printable_key_ignored
      @editor.window.cursor_col = 0

      @editor.handle_insert_key(1) # Ctrl+A

      assert_equal "", @editor.buffer.line(0)
      assert_equal 0, @editor.window.cursor_col
    end
  end

  class TestBackspace < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::INSERT
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_deletes_previous_char
      @editor.buffer.insert_char(0, 0, "a")
      @editor.buffer.insert_char(0, 1, "b")
      @editor.window.cursor_col = 2

      @editor.handle_insert_key(127)

      assert_equal "a", @editor.buffer.line(0)
      assert_equal 1, @editor.window.cursor_col
    end

    def test_at_column_zero_does_nothing_on_first_line
      @editor.buffer.lines[0] = "text"
      @editor.window.cursor_row = 0
      @editor.window.cursor_col = 0

      @editor.handle_insert_key(127)

      assert_equal "text", @editor.buffer.line(0)
      assert_equal 0, @editor.window.cursor_row
      assert_equal 0, @editor.window.cursor_col
    end

    def test_at_line_start_joins_lines
      @editor.buffer.lines[0] = "Hello"
      @editor.buffer.insert_line(1, "World")
      @editor.window.cursor_row = 1
      @editor.window.cursor_col = 0

      @editor.handle_insert_key(127)

      assert_equal 0, @editor.window.cursor_row
      assert_equal 5, @editor.window.cursor_col
      assert_equal "HelloWorld", @editor.buffer.line(0)
    end

    def test_curses_key_backspace_works
      @editor.buffer.insert_char(0, 0, "a")
      @editor.buffer.insert_char(0, 1, "b")
      @editor.window.cursor_col = 2

      @editor.handle_insert_key(Curses::KEY_BACKSPACE)

      assert_equal "a", @editor.buffer.line(0)
      assert_equal 1, @editor.window.cursor_col
    end
  end

  class TestEnter < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::INSERT
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_splits_line
      @editor.buffer.insert_char(0, 0, "H")
      @editor.buffer.insert_char(0, 1, "e")
      @editor.buffer.insert_char(0, 2, "l")
      @editor.buffer.insert_char(0, 3, "l")
      @editor.buffer.insert_char(0, 4, "o")
      @editor.window.cursor_col = 2

      @editor.handle_insert_key(13)

      assert_equal "He", @editor.buffer.line(0)
      assert_equal "llo", @editor.buffer.line(1)
      assert_equal 1, @editor.window.cursor_row
      assert_equal 0, @editor.window.cursor_col
    end

    def test_at_line_start_creates_empty_line_above
      @editor.buffer.lines[0] = "text"
      @editor.window.cursor_col = 0

      @editor.handle_insert_key(13)

      assert_equal "", @editor.buffer.line(0)
      assert_equal "text", @editor.buffer.line(1)
      assert_equal 1, @editor.window.cursor_row
      assert_equal 0, @editor.window.cursor_col
    end

    def test_at_line_end_creates_empty_line_below
      @editor.buffer.lines[0] = "text"
      @editor.window.cursor_col = 4

      @editor.handle_insert_key(13)

      assert_equal "text", @editor.buffer.line(0)
      assert_equal "", @editor.buffer.line(1)
      assert_equal 1, @editor.window.cursor_row
      assert_equal 0, @editor.window.cursor_col
    end

    def test_curses_key_enter_works
      @editor.buffer.lines[0] = "ab"
      @editor.window.cursor_col = 1

      @editor.handle_insert_key(Curses::KEY_ENTER)

      assert_equal "a", @editor.buffer.line(0)
      assert_equal "b", @editor.buffer.line(1)
    end
  end

  class TestArrowKeys < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::INSERT
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_left_arrow_moves_cursor_left
      @editor.buffer.lines[0] = "abc"
      @editor.window.cursor_col = 2

      @editor.handle_insert_key(Curses::KEY_LEFT)

      assert_equal 1, @editor.window.cursor_col
      assert_equal Mui::Mode::INSERT, @editor.mode
    end

    def test_left_arrow_does_not_move_past_start
      @editor.buffer.lines[0] = "abc"
      @editor.window.cursor_col = 0

      @editor.handle_insert_key(Curses::KEY_LEFT)

      assert_equal 0, @editor.window.cursor_col
    end

    def test_right_arrow_moves_cursor_right
      @editor.buffer.lines[0] = "abc"
      @editor.window.cursor_col = 1

      @editor.handle_insert_key(Curses::KEY_RIGHT)

      assert_equal 2, @editor.window.cursor_col
      assert_equal Mui::Mode::INSERT, @editor.mode
    end

    def test_right_arrow_can_move_to_end_of_line
      @editor.buffer.lines[0] = "abc"
      @editor.window.cursor_col = 2

      @editor.handle_insert_key(Curses::KEY_RIGHT)

      assert_equal 3, @editor.window.cursor_col
    end

    def test_right_arrow_does_not_move_past_end
      @editor.buffer.lines[0] = "abc"
      @editor.window.cursor_col = 3

      @editor.handle_insert_key(Curses::KEY_RIGHT)

      assert_equal 3, @editor.window.cursor_col
    end

    def test_up_arrow_moves_cursor_up
      @editor.buffer.lines[0] = "line1"
      @editor.buffer.insert_line(1, "line2")
      @editor.window.cursor_row = 1
      @editor.window.cursor_col = 2

      @editor.handle_insert_key(Curses::KEY_UP)

      assert_equal 0, @editor.window.cursor_row
      assert_equal Mui::Mode::INSERT, @editor.mode
    end

    def test_down_arrow_moves_cursor_down
      @editor.buffer.lines[0] = "line1"
      @editor.buffer.insert_line(1, "line2")
      @editor.window.cursor_row = 0
      @editor.window.cursor_col = 2

      @editor.handle_insert_key(Curses::KEY_DOWN)

      assert_equal 1, @editor.window.cursor_row
      assert_equal Mui::Mode::INSERT, @editor.mode
    end

    def test_left_arrow_resets_completion
      @editor.start_insert_completion([{ label: "test", insert_text: "test" }], prefix: "t")
      assert @editor.insert_completion_active?

      @editor.buffer.lines[0] = "t"
      @editor.window.cursor_col = 1

      @editor.handle_insert_key(Curses::KEY_LEFT)

      refute @editor.insert_completion_active?
      assert_equal 0, @editor.window.cursor_col
    end

    def test_right_arrow_resets_completion
      @editor.start_insert_completion([{ label: "test", insert_text: "test" }], prefix: "t")
      assert @editor.insert_completion_active?

      @editor.buffer.lines[0] = "test"
      @editor.window.cursor_col = 1

      @editor.handle_insert_key(Curses::KEY_RIGHT)

      refute @editor.insert_completion_active?
      assert_equal 2, @editor.window.cursor_col
    end
  end
end
