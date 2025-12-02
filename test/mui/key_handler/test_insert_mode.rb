# frozen_string_literal: true

require "test_helper"

class TestKeyHandlerInsertMode < Minitest::Test
  class TestEscape < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::InsertMode.new(@window, @buffer)
    end

    def test_returns_normal_mode
      @window.cursor_col = 3

      result = @handler.handle(27)

      assert_equal Mui::Mode::NORMAL, result[:mode]
    end

    def test_moves_cursor_back
      @window.cursor_col = 3

      @handler.handle(27)

      assert_equal 2, @window.cursor_col
    end

    def test_stays_at_zero_if_at_start
      @window.cursor_col = 0

      @handler.handle(27)

      assert_equal 0, @window.cursor_col
    end
  end

  class TestArrowKeys < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::InsertMode.new(@window, @buffer)
    end

    def test_left_moves_cursor_left
      @window.cursor_col = 3

      result = @handler.handle(Curses::KEY_LEFT)

      assert_equal 2, @window.cursor_col
      assert_nil result[:mode]
    end

    def test_left_does_not_go_past_zero
      @window.cursor_col = 0

      @handler.handle(Curses::KEY_LEFT)

      assert_equal 0, @window.cursor_col
    end

    def test_right_moves_cursor_right
      @window.cursor_col = 2

      @handler.handle(Curses::KEY_RIGHT)

      assert_equal 3, @window.cursor_col
    end

    def test_right_can_go_past_last_char
      @window.cursor_col = 4

      @handler.handle(Curses::KEY_RIGHT)

      assert_equal 5, @window.cursor_col
    end

    def test_right_does_not_go_past_line_length
      @window.cursor_col = 5

      @handler.handle(Curses::KEY_RIGHT)

      assert_equal 5, @window.cursor_col
    end

    def test_up_moves_cursor_up
      @window.cursor_row = 1

      @handler.handle(Curses::KEY_UP)

      assert_equal 0, @window.cursor_row
    end

    def test_down_moves_cursor_down
      @window.cursor_row = 0

      @handler.handle(Curses::KEY_DOWN)

      assert_equal 1, @window.cursor_row
    end
  end

  class TestBackspace < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = +"hello"
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::InsertMode.new(@window, @buffer)
    end

    def test_deletes_char_before_cursor
      @window.cursor_col = 3

      @handler.handle(127)

      assert_equal "helo", @buffer.line(0)
      assert_equal 2, @window.cursor_col
    end

    def test_curses_backspace_works
      @window.cursor_col = 3

      @handler.handle(Curses::KEY_BACKSPACE)

      assert_equal "helo", @buffer.line(0)
    end

    def test_at_start_of_line_joins_with_previous
      @buffer.insert_line(1, "world")
      @window.cursor_row = 1
      @window.cursor_col = 0

      @handler.handle(127)

      assert_equal 1, @buffer.line_count
      assert_equal "helloworld", @buffer.line(0)
      assert_equal 0, @window.cursor_row
      assert_equal 5, @window.cursor_col
    end

    def test_at_start_of_first_line_does_nothing
      @window.cursor_row = 0
      @window.cursor_col = 0

      @handler.handle(127)

      assert_equal "hello", @buffer.line(0)
      assert_equal 0, @window.cursor_col
    end
  end

  class TestEnter < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = +"hello"
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::InsertMode.new(@window, @buffer)
    end

    def test_splits_line_at_cursor
      @window.cursor_col = 2

      @handler.handle(13)

      assert_equal 2, @buffer.line_count
      assert_equal "he", @buffer.line(0)
      assert_equal "llo", @buffer.line(1)
    end

    def test_moves_cursor_to_next_line_start
      @window.cursor_col = 2

      @handler.handle(13)

      assert_equal 1, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end

    def test_curses_enter_works
      @window.cursor_col = 2

      @handler.handle(Curses::KEY_ENTER)

      assert_equal 2, @buffer.line_count
    end

    def test_at_line_end_creates_empty_line
      @window.cursor_col = 5

      @handler.handle(13)

      assert_equal "hello", @buffer.line(0)
      assert_equal "", @buffer.line(1)
    end
  end

  class TestCharacterInput < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = +""
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::InsertMode.new(@window, @buffer)
    end

    def test_inserts_string_character
      @handler.handle("a")

      assert_equal "a", @buffer.line(0)
      assert_equal 1, @window.cursor_col
    end

    def test_inserts_integer_character
      @handler.handle(65) # 'A'

      assert_equal "A", @buffer.line(0)
      assert_equal 1, @window.cursor_col
    end

    def test_ignores_non_printable_integer
      @handler.handle(1) # Ctrl+A

      assert_equal "", @buffer.line(0)
      assert_equal 0, @window.cursor_col
    end

    def test_multiple_characters
      @handler.handle("h")
      @handler.handle("i")

      assert_equal "hi", @buffer.line(0)
      assert_equal 2, @window.cursor_col
    end
  end

  class TestReturnValue < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = +"hello"
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::InsertMode.new(@window, @buffer)
    end

    def test_escape_returns_normal_mode
      result = @handler.handle(27)

      assert_equal Mui::Mode::NORMAL, result[:mode]
    end

    def test_other_keys_return_nil_mode
      result = @handler.handle("a")

      assert_nil result[:mode]
    end
  end
end
