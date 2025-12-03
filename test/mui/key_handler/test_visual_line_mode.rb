# frozen_string_literal: true

require "test_helper"

class TestKeyHandlerVisualLineMode < Minitest::Test
  class TestBasicMovement < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(0, 2, line_mode: true)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
    end

    def test_h_moves_left_and_updates_selection
      @window.cursor_col = 3

      @handler.handle("h")

      assert_equal 2, @window.cursor_col
      assert_equal 2, @selection.end_col
    end

    def test_l_moves_right_and_updates_selection
      @window.cursor_col = 2

      @handler.handle("l")

      assert_equal 3, @window.cursor_col
      assert_equal 3, @selection.end_col
    end

    def test_j_moves_down_and_updates_selection
      @window.cursor_row = 0

      @handler.handle("j")

      assert_equal 1, @window.cursor_row
      assert_equal 1, @selection.end_row
    end

    def test_k_moves_up_and_updates_selection
      @window.cursor_row = 1
      @selection.update_end(1, 2)

      @handler.handle("k")

      assert_equal 0, @window.cursor_row
      assert_equal 0, @selection.end_row
    end
  end

  class TestWordMovement < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world foo"
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(0, 0, line_mode: true)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
    end

    def test_w_moves_to_next_word_and_updates_selection
      @window.cursor_col = 0

      @handler.handle("w")

      assert_equal 6, @window.cursor_col
      assert_equal 6, @selection.end_col
    end

    def test_b_moves_to_previous_word_and_updates_selection
      @window.cursor_col = 8
      @selection.update_end(0, 8)

      @handler.handle("b")

      assert_equal 6, @window.cursor_col
      assert_equal 6, @selection.end_col
    end

    def test_e_moves_to_end_of_word_and_updates_selection
      @window.cursor_col = 0

      @handler.handle("e")

      assert_equal 4, @window.cursor_col
      assert_equal 4, @selection.end_col
    end
  end

  class TestLineMovement < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "  hello world"
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(0, 5, line_mode: true)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
    end

    def test_0_moves_to_line_start_and_updates_selection
      @window.cursor_col = 5

      @handler.handle("0")

      assert_equal 0, @window.cursor_col
      assert_equal 0, @selection.end_col
    end

    def test_caret_moves_to_first_non_blank_and_updates_selection
      @window.cursor_col = 10

      @handler.handle("^")

      assert_equal 2, @window.cursor_col
      assert_equal 2, @selection.end_col
    end

    def test_dollar_moves_to_line_end_and_updates_selection
      @window.cursor_col = 0

      @handler.handle("$")

      assert_equal 12, @window.cursor_col
      assert_equal 12, @selection.end_col
    end
  end

  class TestFileMovement < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "line1"
      @buffer.insert_line(1, "line2")
      @buffer.insert_line(2, "line3")
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(1, 2, line_mode: true)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
    end

    def test_gg_moves_to_file_start_and_updates_selection
      @window.cursor_row = 2
      @window.cursor_col = 3

      @handler.handle("g")
      @handler.handle("g")

      assert_equal 0, @window.cursor_row
      assert_equal 0, @window.cursor_col
      assert_equal 0, @selection.end_row
      assert_equal 0, @selection.end_col
    end

    def test_G_moves_to_file_end_and_updates_selection
      @window.cursor_row = 0

      @handler.handle("G")

      assert_equal 2, @window.cursor_row
      assert_equal 2, @selection.end_row
    end
  end

  class TestCharacterSearch < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(0, 0, line_mode: true)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
    end

    def test_f_finds_char_forward_and_updates_selection
      @window.cursor_col = 0

      @handler.handle("f")
      @handler.handle("o")

      assert_equal 4, @window.cursor_col
      assert_equal 4, @selection.end_col
    end

    def test_F_finds_char_backward_and_updates_selection
      @window.cursor_col = 10
      @selection.update_end(0, 10)

      @handler.handle("F")
      @handler.handle("o")

      assert_equal 7, @window.cursor_col
      assert_equal 7, @selection.end_col
    end
  end

  class TestModeTransition < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(0, 0, line_mode: true)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
    end

    def test_escape_returns_to_normal_mode
      result = @handler.handle(27) # Escape

      assert_equal Mui::Mode::NORMAL, result.mode
      assert result.clear_selection?
    end

    def test_v_in_line_mode_toggles_to_char_mode
      result = @handler.handle("v")

      assert_equal Mui::Mode::VISUAL, result.mode
      assert result.toggle_line_mode?
    end

    def test_upper_v_in_line_mode_clears_selection
      result = @handler.handle("V")

      assert_equal Mui::Mode::NORMAL, result.mode
      assert result.clear_selection?
    end
  end

  class TestSelectionPreservation < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(0, 2, line_mode: true)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
    end

    def test_start_position_is_preserved_during_movement
      @window.cursor_col = 2

      @handler.handle("l")
      @handler.handle("l")
      @handler.handle("j")

      assert_equal 0, @selection.start_row
      assert_equal 2, @selection.start_col
      assert_equal 1, @selection.end_row
      assert_equal 4, @selection.end_col
    end

    def test_line_mode_is_preserved
      @handler.handle("j")

      assert @selection.line_mode
    end
  end
end
