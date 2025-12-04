# frozen_string_literal: true

require "test_helper"

class TestKeyHandlerVisualMode < Minitest::Test
  class TestBasicMovement < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(0, 2)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)
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
      @selection = Mui::Selection.new(0, 0)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)
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
      @selection = Mui::Selection.new(0, 5)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)
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
      @selection = Mui::Selection.new(1, 2)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)
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
      @selection = Mui::Selection.new(0, 0)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)
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
      @selection = Mui::Selection.new(0, 0)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)
    end

    def test_escape_returns_to_normal_mode
      result = @handler.handle(27) # Escape

      assert_equal Mui::Mode::NORMAL, result.mode
      assert result.clear_selection?
    end

    def test_v_in_char_mode_clears_selection
      result = @handler.handle("v")

      assert_equal Mui::Mode::NORMAL, result.mode
      assert result.clear_selection?
    end

    def test_upper_v_in_char_mode_toggles_to_line_mode
      result = @handler.handle("V")

      assert_equal Mui::Mode::VISUAL_LINE, result.mode
      assert result.toggle_line_mode?
    end
  end

  class TestSelectionPreservation < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(0, 2)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)
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
  end

  class TestDeleteOperator < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
      @window = Mui::Window.new(@buffer)
    end

    def test_d_deletes_character_selection
      @selection = Mui::Selection.new(0, 2)
      @selection.update_end(0, 6)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)

      result = @handler.handle("d")

      assert_equal "heorld", @buffer.line(0)
      assert_equal Mui::Mode::NORMAL, result.mode
      assert result.clear_selection?
    end

    def test_d_deletes_multi_line_selection
      @selection = Mui::Selection.new(0, 6)
      @selection.update_end(1, 6)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)

      result = @handler.handle("d")

      assert_equal 2, @buffer.line_count
      assert_equal "hello line", @buffer.line(0)
      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_d_deletes_reverse_selection
      @window.cursor_col = 2
      @selection = Mui::Selection.new(0, 6)
      @selection.update_end(0, 2)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)

      @handler.handle("d")

      assert_equal "heorld", @buffer.line(0)
      assert_equal 2, @window.cursor_col
    end

    def test_d_moves_cursor_to_selection_start
      @selection = Mui::Selection.new(0, 3)
      @selection.update_end(0, 8)
      @window.cursor_col = 8
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)

      @handler.handle("d")

      assert_equal 3, @window.cursor_col
    end
  end

  class TestDeleteOperatorLineMode < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
      @window = Mui::Window.new(@buffer)
    end

    def test_d_deletes_single_line_in_line_mode
      @selection = Mui::Selection.new(1, 0, line_mode: true)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
      @window.cursor_row = 1

      result = @handler.handle("d")

      assert_equal 2, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
      assert_equal "third line", @buffer.line(1)
      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_d_deletes_multiple_lines_in_line_mode
      @selection = Mui::Selection.new(0, 0, line_mode: true)
      @selection.update_end(1, 0)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)

      @handler.handle("d")

      assert_equal 1, @buffer.line_count
      assert_equal "third line", @buffer.line(0)
      assert_equal 0, @window.cursor_row
    end

    def test_d_moves_cursor_to_first_deleted_line
      @selection = Mui::Selection.new(1, 0, line_mode: true)
      @selection.update_end(2, 0)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
      @window.cursor_row = 2

      @handler.handle("d")

      assert_equal 0, @window.cursor_row
    end
  end

  class TestChangeOperator < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
      @window = Mui::Window.new(@buffer)
    end

    def test_c_changes_character_selection
      @selection = Mui::Selection.new(0, 2)
      @selection.update_end(0, 6)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)

      result = @handler.handle("c")

      assert_equal "heorld", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
      assert result.clear_selection?
    end

    def test_c_changes_multi_line_selection
      @selection = Mui::Selection.new(0, 6)
      @selection.update_end(1, 6)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)

      result = @handler.handle("c")

      assert_equal 2, @buffer.line_count
      assert_equal "hello line", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_c_moves_cursor_to_selection_start
      @selection = Mui::Selection.new(0, 3)
      @selection.update_end(0, 8)
      @window.cursor_col = 8
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection)

      @handler.handle("c")

      assert_equal 3, @window.cursor_col
    end
  end

  class TestChangeOperatorLineMode < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
      @window = Mui::Window.new(@buffer)
    end

    def test_c_changes_single_line_in_line_mode
      @selection = Mui::Selection.new(1, 0, line_mode: true)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
      @window.cursor_row = 1

      result = @handler.handle("c")

      assert_equal 3, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
      assert_equal "", @buffer.line(1)
      assert_equal "third line", @buffer.line(2)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_c_changes_multiple_lines_in_line_mode
      @selection = Mui::Selection.new(0, 0, line_mode: true)
      @selection.update_end(1, 0)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)

      result = @handler.handle("c")

      assert_equal 2, @buffer.line_count
      assert_equal "", @buffer.line(0)
      assert_equal "third line", @buffer.line(1)
      assert_equal 0, @window.cursor_row
      assert_equal 0, @window.cursor_col
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_c_moves_cursor_to_first_changed_line
      @selection = Mui::Selection.new(1, 0, line_mode: true)
      @selection.update_end(2, 0)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection)
      @window.cursor_row = 2

      @handler.handle("c")

      assert_equal 1, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end
  end

  class TestYankOperator < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
      @window = Mui::Window.new(@buffer)
      @register = Mui::Register.new
    end

    def test_y_yanks_character_selection
      @selection = Mui::Selection.new(0, 2)
      @selection.update_end(0, 6)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection, @register)

      result = @handler.handle("y")

      assert_equal "llo w", @register.get
      refute @register.linewise?
      assert_equal Mui::Mode::NORMAL, result.mode
      assert result.clear_selection?
    end

    def test_y_yanks_multi_line_selection
      @selection = Mui::Selection.new(0, 6)
      @selection.update_end(1, 6)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection, @register)

      result = @handler.handle("y")

      assert_equal "world\nsecond ", @register.get
      refute @register.linewise?
      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_y_yanks_reverse_selection
      @window.cursor_col = 2
      @selection = Mui::Selection.new(0, 6)
      @selection.update_end(0, 2)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection, @register)

      @handler.handle("y")

      assert_equal "llo w", @register.get
      refute @register.linewise?
    end

    def test_y_moves_cursor_to_selection_start
      @selection = Mui::Selection.new(0, 3)
      @selection.update_end(0, 8)
      @window.cursor_col = 8
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection, @register)

      @handler.handle("y")

      assert_equal 3, @window.cursor_col
    end

    def test_y_does_not_modify_buffer
      @selection = Mui::Selection.new(0, 2)
      @selection.update_end(0, 6)
      @handler = Mui::KeyHandler::VisualMode.new(@window, @buffer, @selection, @register)

      @handler.handle("y")

      assert_equal "hello world", @buffer.line(0)
      assert_equal 3, @buffer.line_count
    end
  end

  class TestYankOperatorLineMode < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
      @window = Mui::Window.new(@buffer)
      @register = Mui::Register.new
    end

    def test_y_yanks_single_line_in_line_mode
      @selection = Mui::Selection.new(1, 0, line_mode: true)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection, @register)
      @window.cursor_row = 1

      result = @handler.handle("y")

      assert_equal "second line", @register.get
      assert @register.linewise?
      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_y_yanks_multiple_lines_in_line_mode
      @selection = Mui::Selection.new(0, 0, line_mode: true)
      @selection.update_end(1, 0)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection, @register)

      @handler.handle("y")

      assert_equal "hello world\nsecond line", @register.get
      assert @register.linewise?
    end

    def test_y_moves_cursor_to_first_yanked_line
      @selection = Mui::Selection.new(1, 0, line_mode: true)
      @selection.update_end(2, 0)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection, @register)
      @window.cursor_row = 2

      @handler.handle("y")

      assert_equal 1, @window.cursor_row
    end

    def test_y_does_not_modify_buffer_in_line_mode
      @selection = Mui::Selection.new(0, 0, line_mode: true)
      @selection.update_end(1, 0)
      @handler = Mui::KeyHandler::VisualLineMode.new(@window, @buffer, @selection, @register)

      @handler.handle("y")

      assert_equal "hello world", @buffer.line(0)
      assert_equal "second line", @buffer.line(1)
      assert_equal "third line", @buffer.line(2)
      assert_equal 3, @buffer.line_count
    end
  end
end
