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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)
    end

    def test_escape_returns_to_normal_mode
      result = @handler.handle(27) # Escape

      assert_equal Mui::Mode::NORMAL, result.mode
      assert_predicate result, :clear_selection?
    end

    def test_v_in_char_mode_clears_selection
      result = @handler.handle("v")

      assert_equal Mui::Mode::NORMAL, result.mode
      assert_predicate result, :clear_selection?
    end

    def test_upper_v_in_char_mode_toggles_to_line_mode
      result = @handler.handle("V")

      assert_equal Mui::Mode::VISUAL_LINE, result.mode
      assert_predicate result, :toggle_line_mode?
    end
  end

  class TestSelectionPreservation < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(0, 2)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

      result = @handler.handle("d")

      assert_equal "heorld", @buffer.line(0)
      assert_equal Mui::Mode::NORMAL, result.mode
      assert_predicate result, :clear_selection?
    end

    def test_d_deletes_multi_line_selection
      @selection = Mui::Selection.new(0, 6)
      @selection.update_end(1, 6)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

      result = @handler.handle("d")

      assert_equal 2, @buffer.line_count
      assert_equal "hello line", @buffer.line(0)
      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_d_deletes_reverse_selection
      @window.cursor_col = 2
      @selection = Mui::Selection.new(0, 6)
      @selection.update_end(0, 2)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

      @handler.handle("d")

      assert_equal "heorld", @buffer.line(0)
      assert_equal 2, @window.cursor_col
    end

    def test_d_moves_cursor_to_selection_start
      @selection = Mui::Selection.new(0, 3)
      @selection.update_end(0, 8)
      @window.cursor_col = 8
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualLineMode.new(@mode_manager, @buffer, @selection)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualLineMode.new(@mode_manager, @buffer, @selection)

      @handler.handle("d")

      assert_equal 1, @buffer.line_count
      assert_equal "third line", @buffer.line(0)
      assert_equal 0, @window.cursor_row
    end

    def test_d_moves_cursor_to_first_deleted_line
      @selection = Mui::Selection.new(1, 0, line_mode: true)
      @selection.update_end(2, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualLineMode.new(@mode_manager, @buffer, @selection)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

      result = @handler.handle("c")

      assert_equal "heorld", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
      assert_predicate result, :clear_selection?
    end

    def test_c_changes_multi_line_selection
      @selection = Mui::Selection.new(0, 6)
      @selection.update_end(1, 6)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

      result = @handler.handle("c")

      assert_equal 2, @buffer.line_count
      assert_equal "hello line", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_c_moves_cursor_to_selection_start
      @selection = Mui::Selection.new(0, 3)
      @selection.update_end(0, 8)
      @window.cursor_col = 8
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualLineMode.new(@mode_manager, @buffer, @selection)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualLineMode.new(@mode_manager, @buffer, @selection)

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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualLineMode.new(@mode_manager, @buffer, @selection)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, @register)

      result = @handler.handle("y")

      assert_equal "llo w", @register.get
      refute_predicate @register, :linewise?
      assert_equal Mui::Mode::NORMAL, result.mode
      assert_predicate result, :clear_selection?
    end

    def test_y_yanks_multi_line_selection
      @selection = Mui::Selection.new(0, 6)
      @selection.update_end(1, 6)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, @register)

      result = @handler.handle("y")

      assert_equal "world\nsecond ", @register.get
      refute_predicate @register, :linewise?
      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_y_yanks_reverse_selection
      @window.cursor_col = 2
      @selection = Mui::Selection.new(0, 6)
      @selection.update_end(0, 2)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, @register)

      @handler.handle("y")

      assert_equal "llo w", @register.get
      refute_predicate @register, :linewise?
    end

    def test_y_moves_cursor_to_selection_start
      @selection = Mui::Selection.new(0, 3)
      @selection.update_end(0, 8)
      @window.cursor_col = 8
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, @register)

      @handler.handle("y")

      assert_equal 3, @window.cursor_col
    end

    def test_y_does_not_modify_buffer
      @selection = Mui::Selection.new(0, 2)
      @selection.update_end(0, 6)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, @register)

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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualLineMode.new(@mode_manager, @buffer, @selection, @register)
      @window.cursor_row = 1

      result = @handler.handle("y")

      assert_equal "second line", @register.get
      assert_predicate @register, :linewise?
      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_y_yanks_multiple_lines_in_line_mode
      @selection = Mui::Selection.new(0, 0, line_mode: true)
      @selection.update_end(1, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualLineMode.new(@mode_manager, @buffer, @selection, @register)

      @handler.handle("y")

      assert_equal "hello world\nsecond line", @register.get
      assert_predicate @register, :linewise?
    end

    def test_y_moves_cursor_to_first_yanked_line
      @selection = Mui::Selection.new(1, 0, line_mode: true)
      @selection.update_end(2, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualLineMode.new(@mode_manager, @buffer, @selection, @register)
      @window.cursor_row = 2

      @handler.handle("y")

      assert_equal 1, @window.cursor_row
    end

    def test_y_does_not_modify_buffer_in_line_mode
      @selection = Mui::Selection.new(0, 0, line_mode: true)
      @selection.update_end(1, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualLineMode.new(@mode_manager, @buffer, @selection, @register)

      @handler.handle("y")

      assert_equal "hello world", @buffer.line(0)
      assert_equal "second line", @buffer.line(1)
      assert_equal "third line", @buffer.line(2)
      assert_equal 3, @buffer.line_count
    end
  end

  class TestNamedRegisters < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @register = Mui::Register.new
      @window = Mui::Window.new(@buffer)
      @selection = Mui::Selection.new(0, 0)
      @selection.update_end(0, 4)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, @register)
    end

    def test_quote_a_y_yanks_to_named_register
      @handler.handle('"')
      @handler.handle("a")
      @handler.handle("y")

      assert_equal "hello", @register.get(name: "a")
      refute @register.linewise?(name: "a")
    end

    def test_d_saves_to_delete_history
      @handler.handle("d")

      assert_equal "hello", @register.get(name: "1")
      refute @register.linewise?(name: "1")
    end

    def test_quote_underscore_d_does_not_save
      @handler.handle('"')
      @handler.handle("_")
      @handler.handle("d")

      assert_nil @register.get
      assert_nil @register.get(name: "1")
    end

    def test_y_saves_to_yank_register
      @handler.handle("y")

      assert_equal "hello", @register.get(name: "0")
    end

    def test_d_does_not_affect_yank_register
      @handler.handle("y")
      @selection = Mui::Selection.new(0, 0)
      @selection.update_end(0, 4)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, @register)

      @handler.handle("d")

      assert_equal "hello", @register.get(name: "0")
    end

    def test_line_mode_d_saves_linewise
      @selection = Mui::Selection.new(0, 0, line_mode: true)
      @selection.update_end(0, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, @register)

      @handler.handle("d")

      assert_equal "hello world", @register.get(name: "1")
      assert @register.linewise?(name: "1")
    end
  end

  class TestIndentOperator < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.replace_line(0, "hello")
      @buffer.insert_line(1, "world")
      @buffer.insert_line(2, "test")
      @window = Mui::Window.new(@buffer)
      @undo_manager = Mui::UndoManager.new
    end

    def test_indent_right_single_line
      @selection = Mui::Selection.new(0, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, nil, undo_manager: @undo_manager)

      result = @handler.handle(">")

      assert_equal "  hello", @buffer.line(0)
      assert_equal "world", @buffer.line(1)
      assert_equal Mui::Mode::NORMAL, result.mode
      assert_predicate result, :clear_selection?
    end

    def test_indent_right_multiple_lines
      @selection = Mui::Selection.new(0, 0)
      @selection.update_end(1, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, nil, undo_manager: @undo_manager)

      @handler.handle(">")

      assert_equal "  hello", @buffer.line(0)
      assert_equal "  world", @buffer.line(1)
      assert_equal "test", @buffer.line(2)
    end

    def test_indent_left_single_line
      @buffer.replace_line(0, "  hello")
      @selection = Mui::Selection.new(0, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, nil, undo_manager: @undo_manager)

      result = @handler.handle("<")

      assert_equal "hello", @buffer.line(0)
      assert_equal Mui::Mode::NORMAL, result.mode
      assert_predicate result, :clear_selection?
    end

    def test_indent_left_multiple_lines
      @buffer.replace_line(0, "  hello")
      @buffer.replace_line(1, "  world")
      @selection = Mui::Selection.new(0, 0)
      @selection.update_end(1, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, nil, undo_manager: @undo_manager)

      @handler.handle("<")

      assert_equal "hello", @buffer.line(0)
      assert_equal "world", @buffer.line(1)
      assert_equal "test", @buffer.line(2)
    end

    def test_indent_left_no_indent
      @selection = Mui::Selection.new(0, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, nil, undo_manager: @undo_manager)

      @handler.handle("<")

      assert_equal "hello", @buffer.line(0)
    end

    def test_indent_skips_empty_lines
      @buffer.replace_line(0, "hello")
      @buffer.replace_line(1, "")
      @buffer.replace_line(2, "test")
      @selection = Mui::Selection.new(0, 0)
      @selection.update_end(2, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, nil, undo_manager: @undo_manager)

      @handler.handle(">")

      assert_equal "  hello", @buffer.line(0)
      assert_equal "", @buffer.line(1)
      assert_equal "  test", @buffer.line(2)
    end

    def test_indent_moves_cursor_to_start_row
      @selection = Mui::Selection.new(0, 0)
      @selection.update_end(2, 0)
      @window.cursor_row = 2
      @window.cursor_col = 3
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, nil, undo_manager: @undo_manager)

      @handler.handle(">")

      assert_equal 0, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end

    def test_indent_with_tab_when_expandtab_false
      Mui.config.set(:expandtab, false)
      @selection = Mui::Selection.new(0, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, nil, undo_manager: @undo_manager)

      @handler.handle(">")

      assert_equal "\thello", @buffer.line(0)
    ensure
      Mui.config.set(:expandtab, true)
    end

    def test_indent_left_removes_partial_indent
      @buffer.replace_line(0, " hello")
      @selection = Mui::Selection.new(0, 0)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection, nil, undo_manager: @undo_manager)

      @handler.handle("<")

      assert_equal "hello", @buffer.line(0)
    end
  end

  class TestSearchSelection < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "foo bar")
      @buffer.insert_line(2, "hello again")
      @window = Mui::Window.new(@buffer)
      @search_state = Mui::SearchState.new
      @mode_manager = MockModeManager.new(@window, search_state: @search_state)
    end

    def test_star_searches_selection_forward
      @window.cursor_col = 0
      @selection = Mui::Selection.new(0, 0)
      @selection.update_end(0, 4) # Select "hello"
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

      result = @handler.handle("*")

      assert_equal Mui::Mode::NORMAL, result.mode
      assert_predicate result, :clear_selection?
      # Should find next "hello" at row 2
      assert_equal 2, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end

    def test_hash_searches_selection_backward
      @window.cursor_row = 2
      @window.cursor_col = 0
      @selection = Mui::Selection.new(2, 0)
      @selection.update_end(2, 4) # Select "hello"
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

      result = @handler.handle("#")

      assert_equal Mui::Mode::NORMAL, result.mode
      # Should find previous "hello" at row 0
      assert_equal 0, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end

    def test_star_escapes_regex_special_chars
      @buffer.lines[0] = "foo.bar"
      @buffer.insert_line(1, "foo.bar again")
      @window.cursor_col = 0
      @selection = Mui::Selection.new(0, 0)
      @selection.update_end(0, 6) # Select "foo.bar"
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

      @handler.handle("*")

      # Should match literal "foo.bar", not "foo" + any char + "bar"
      assert_equal 1, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end

    def test_star_sets_search_state
      @window.cursor_col = 0
      @selection = Mui::Selection.new(0, 0)
      @selection.update_end(0, 4) # Select "hello"
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

      @handler.handle("*")

      assert_predicate @search_state, :has_pattern?
      assert_equal 2, @search_state.find_all_matches(@buffer).length # Two "hello" matches
    end

    def test_star_with_no_match_returns_message
      @window.cursor_col = 0
      @selection = Mui::Selection.new(0, 0)
      @buffer.lines[0] = "unique_text"
      @buffer.lines[1] = "something else"
      @buffer.lines[2] = "another line"
      @selection.update_end(0, 10) # Select "unique_text"
      @handler = Mui::KeyHandler::VisualMode.new(@mode_manager, @buffer, @selection)

      result = @handler.handle("*")

      # Only one match (the selected text itself), so find_next wraps to same position
      assert_equal Mui::Mode::NORMAL, result.mode
    end
  end
end
