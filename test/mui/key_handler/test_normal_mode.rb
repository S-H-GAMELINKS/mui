# frozen_string_literal: true

require "test_helper"

class TestKeyHandlerNormalMode < Minitest::Test
  class TestBasicMovement < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::NormalMode.new(@window, @buffer)
    end

    def test_h_moves_left
      @window.cursor_col = 3

      @handler.handle("h")

      assert_equal 2, @window.cursor_col
    end

    def test_l_moves_right
      @window.cursor_col = 0

      @handler.handle("l")

      assert_equal 1, @window.cursor_col
    end

    def test_j_moves_down
      @window.cursor_row = 0

      @handler.handle("j")

      assert_equal 1, @window.cursor_row
    end

    def test_k_moves_up
      @window.cursor_row = 1

      @handler.handle("k")

      assert_equal 0, @window.cursor_row
    end

    def test_arrow_keys_work
      @window.cursor_col = 2
      @window.cursor_row = 0

      @handler.handle(Curses::KEY_LEFT)
      assert_equal 1, @window.cursor_col

      @handler.handle(Curses::KEY_RIGHT)
      assert_equal 2, @window.cursor_col

      @handler.handle(Curses::KEY_DOWN)
      assert_equal 1, @window.cursor_row

      @handler.handle(Curses::KEY_UP)
      assert_equal 0, @window.cursor_row
    end
  end

  class TestWordMovement < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world foo"
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::NormalMode.new(@window, @buffer)
    end

    def test_w_moves_to_next_word
      @window.cursor_col = 0

      @handler.handle("w")

      assert_equal 6, @window.cursor_col
    end

    def test_b_moves_to_previous_word
      @window.cursor_col = 8

      @handler.handle("b")

      assert_equal 6, @window.cursor_col
    end

    def test_e_moves_to_end_of_word
      @window.cursor_col = 0

      @handler.handle("e")

      assert_equal 4, @window.cursor_col
    end
  end

  class TestLineMovement < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "  hello world"
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::NormalMode.new(@window, @buffer)
    end

    def test_0_moves_to_line_start
      @window.cursor_col = 5

      @handler.handle("0")

      assert_equal 0, @window.cursor_col
    end

    def test_caret_moves_to_first_non_blank
      @window.cursor_col = 10

      @handler.handle("^")

      assert_equal 2, @window.cursor_col
    end

    def test_dollar_moves_to_line_end
      @window.cursor_col = 0

      @handler.handle("$")

      assert_equal 12, @window.cursor_col
    end
  end

  class TestFileMovement < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "line1"
      @buffer.insert_line(1, "line2")
      @buffer.insert_line(2, "line3")
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::NormalMode.new(@window, @buffer)
    end

    def test_gg_moves_to_file_start
      @window.cursor_row = 2
      @window.cursor_col = 3

      @handler.handle("g")
      @handler.handle("g")

      assert_equal 0, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end

    def test_G_moves_to_file_end
      @window.cursor_row = 0

      @handler.handle("G")

      assert_equal 2, @window.cursor_row
    end

    def test_g_without_second_g_does_nothing
      @window.cursor_row = 1
      @window.cursor_col = 2

      @handler.handle("g")
      @handler.handle("x") # Not 'g'

      assert_equal 1, @window.cursor_row
      assert_equal 2, @window.cursor_col
    end
  end

  class TestCharacterSearch < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::NormalMode.new(@window, @buffer)
    end

    def test_f_finds_char_forward
      @window.cursor_col = 0

      @handler.handle("f")
      @handler.handle("o")

      assert_equal 4, @window.cursor_col
    end

    def test_F_finds_char_backward
      @window.cursor_col = 10

      @handler.handle("F")
      @handler.handle("o")

      assert_equal 7, @window.cursor_col
    end

    def test_t_moves_to_before_char
      @window.cursor_col = 0

      @handler.handle("t")
      @handler.handle("o")

      assert_equal 3, @window.cursor_col
    end

    def test_T_moves_to_after_char
      @window.cursor_col = 10

      @handler.handle("T")
      @handler.handle("o")

      assert_equal 8, @window.cursor_col
    end

    def test_f_with_not_found_char_stays
      @window.cursor_col = 0

      @handler.handle("f")
      @handler.handle("z")

      assert_equal 0, @window.cursor_col
    end
  end

  class TestModeTransition < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::NormalMode.new(@window, @buffer)
    end

    def test_i_returns_insert_mode
      result = @handler.handle("i")

      assert_equal Mui::Mode::INSERT, result[:mode]
    end

    def test_a_returns_insert_mode_and_moves_cursor
      @window.cursor_col = 2

      result = @handler.handle("a")

      assert_equal Mui::Mode::INSERT, result[:mode]
      assert_equal 3, @window.cursor_col
    end

    def test_o_opens_line_below_and_returns_insert
      @window.cursor_row = 0

      result = @handler.handle("o")

      assert_equal Mui::Mode::INSERT, result[:mode]
      assert_equal 1, @window.cursor_row
      assert_equal 0, @window.cursor_col
      assert_equal 2, @buffer.line_count
    end

    def test_O_opens_line_above_and_returns_insert
      @buffer.insert_line(1, "world")
      @window.cursor_row = 1

      result = @handler.handle("O")

      assert_equal Mui::Mode::INSERT, result[:mode]
      assert_equal 1, @window.cursor_row
      assert_equal 0, @window.cursor_col
      assert_equal "", @buffer.line(1)
    end

    def test_colon_returns_command_mode
      result = @handler.handle(":")

      assert_equal Mui::Mode::COMMAND, result[:mode]
    end

    def test_v_returns_visual_mode_with_start_selection
      result = @handler.handle("v")

      assert_equal Mui::Mode::VISUAL, result[:mode]
      assert result[:start_selection]
      refute result[:line_mode]
    end

    def test_V_returns_visual_line_mode_with_start_selection
      result = @handler.handle("V")

      assert_equal Mui::Mode::VISUAL_LINE, result[:mode]
      assert result[:start_selection]
      assert result[:line_mode]
    end
  end

  class TestEditing < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = +"hello"
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::NormalMode.new(@window, @buffer)
    end

    def test_x_deletes_character
      @window.cursor_col = 2

      @handler.handle("x")

      assert_equal "helo", @buffer.line(0)
    end
  end

  class TestReturnValue < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::NormalMode.new(@window, @buffer)
    end

    def test_movement_returns_nil_mode
      result = @handler.handle("h")

      assert_nil result[:mode]
    end

    def test_unknown_key_returns_nil_mode
      result = @handler.handle("z")

      assert_nil result[:mode]
    end
  end
end
