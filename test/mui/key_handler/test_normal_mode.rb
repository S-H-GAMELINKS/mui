# frozen_string_literal: true

require "test_helper"

class TestKeyHandlerNormalMode < Minitest::Test
  class TestBasicMovement < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")
      @window = Mui::Window.new(@buffer)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
    end

    def test_i_returns_insert_mode
      result = @handler.handle("i")

      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_a_returns_insert_mode_and_moves_cursor
      @window.cursor_col = 2

      result = @handler.handle("a")

      assert_equal Mui::Mode::INSERT, result.mode
      assert_equal 3, @window.cursor_col
    end

    def test_o_opens_line_below_and_returns_insert
      @window.cursor_row = 0

      result = @handler.handle("o")

      assert_equal Mui::Mode::INSERT, result.mode
      assert_equal 1, @window.cursor_row
      assert_equal 0, @window.cursor_col
      assert_equal 2, @buffer.line_count
    end

    def test_O_opens_line_above_and_returns_insert
      @buffer.insert_line(1, "world")
      @window.cursor_row = 1

      result = @handler.handle("O")

      assert_equal Mui::Mode::INSERT, result.mode
      assert_equal 1, @window.cursor_row
      assert_equal 0, @window.cursor_col
      assert_equal "", @buffer.line(1)
    end

    def test_colon_returns_command_mode
      result = @handler.handle(":")

      assert_equal Mui::Mode::COMMAND, result.mode
    end

    def test_v_returns_visual_mode_with_start_selection
      result = @handler.handle("v")

      assert_equal Mui::Mode::VISUAL, result.mode
      assert result.start_selection?
      refute result.line_mode?
    end

    def test_upper_v_returns_visual_line_mode_with_start_selection
      result = @handler.handle("V")

      assert_equal Mui::Mode::VISUAL_LINE, result.mode
      assert result.start_selection?
      assert result.line_mode?
    end
  end

  class TestEditing < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = +"hello"
      @window = Mui::Window.new(@buffer)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
    end

    def test_movement_returns_nil_mode
      result = @handler.handle("h")

      assert_nil result.mode
    end

    def test_unknown_key_returns_nil_mode
      result = @handler.handle("z")

      assert_nil result.mode
    end
  end

  class TestKeyToChar < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @window = Mui::Window.new(@buffer)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
    end

    def test_returns_nil_for_out_of_range_integer
      # RangeError should be caught and return nil
      result = @handler.send(:key_to_char, -1)

      assert_nil result
    end

    def test_returns_nil_for_very_large_integer
      # RangeError should be caught and return nil
      result = @handler.send(:key_to_char, 0x110000)

      assert_nil result
    end

    def test_returns_string_for_valid_string_input
      result = @handler.send(:key_to_char, "a")

      assert_equal "a", result
    end

    def test_returns_char_for_valid_integer_input
      result = @handler.send(:key_to_char, 97) # 'a'

      assert_equal "a", result
    end
  end

  class TestDeleteOperator < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
      @window = Mui::Window.new(@buffer)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
    end

    def test_dd_deletes_current_line
      @window.cursor_row = 1

      @handler.handle("d")
      @handler.handle("d")

      assert_equal 2, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
      assert_equal "third line", @buffer.line(1)
    end

    def test_dd_on_last_line_moves_cursor_up
      @window.cursor_row = 2

      @handler.handle("d")
      @handler.handle("d")

      assert_equal 2, @buffer.line_count
      assert_equal 1, @window.cursor_row
    end

    def test_dw_deletes_word
      @window.cursor_col = 0

      @handler.handle("d")
      @handler.handle("w")

      assert_equal "world", @buffer.line(0)
      assert_equal 0, @window.cursor_col
    end

    def test_de_deletes_to_end_of_word
      @window.cursor_col = 0

      @handler.handle("d")
      @handler.handle("e")

      assert_equal " world", @buffer.line(0)
    end

    def test_db_deletes_to_previous_word
      @window.cursor_col = 8

      @handler.handle("d")
      @handler.handle("b")

      assert_equal "hello rld", @buffer.line(0)
    end

    def test_d0_deletes_to_line_start
      @window.cursor_col = 5

      @handler.handle("d")
      @handler.handle("0")

      assert_equal " world", @buffer.line(0)
      assert_equal 0, @window.cursor_col
    end

    def test_d_dollar_deletes_to_line_end
      @window.cursor_col = 5

      @handler.handle("d")
      @handler.handle("$")

      assert_equal "hello", @buffer.line(0)
    end

    def test_dG_deletes_to_file_end
      @window.cursor_row = 1

      @handler.handle("d")
      @handler.handle("G")

      assert_equal 1, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
    end

    def test_dgg_deletes_to_file_start
      @window.cursor_row = 2
      @window.cursor_col = 3

      @handler.handle("d")
      @handler.handle("g")
      @handler.handle("g")

      assert_equal 1, @buffer.line_count
      assert_equal "rd line", @buffer.line(0)
    end

    def test_df_deletes_to_char
      @window.cursor_col = 0

      @handler.handle("d")
      @handler.handle("f")
      @handler.handle("o")

      assert_equal " world", @buffer.line(0)
    end

    def test_dt_deletes_till_char
      @window.cursor_col = 0

      @handler.handle("d")
      @handler.handle("t")
      @handler.handle("o")

      assert_equal "o world", @buffer.line(0)
    end

    def test_dF_deletes_backward_to_char
      @window.cursor_col = 10

      @handler.handle("d")
      @handler.handle("F")
      @handler.handle("o")

      assert_equal "hello wd", @buffer.line(0)
    end

    def test_dT_deletes_backward_till_char
      @window.cursor_col = 10

      @handler.handle("d")
      @handler.handle("T")
      @handler.handle("o")

      assert_equal "hello wod", @buffer.line(0)
    end

    def test_d_with_invalid_motion_cancels
      @window.cursor_col = 5

      @handler.handle("d")
      @handler.handle("z")

      assert_equal "hello world", @buffer.line(0)
    end
  end

  class TestChangeOperator < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
      @window = Mui::Window.new(@buffer)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer)
    end

    def test_cc_clears_line_and_enters_insert_mode
      @window.cursor_row = 1
      @window.cursor_col = 3

      @handler.handle("c")
      result = @handler.handle("c")

      assert_equal "", @buffer.line(1)
      assert_equal 0, @window.cursor_col
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_cw_changes_word
      @window.cursor_col = 0

      @handler.handle("c")
      result = @handler.handle("w")

      # cw behaves like ce in Vim (changes to end of word, not to start of next word)
      assert_equal " world", @buffer.line(0)
      assert_equal 0, @window.cursor_col
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_ce_changes_to_end_of_word
      @window.cursor_col = 0

      @handler.handle("c")
      result = @handler.handle("e")

      assert_equal " world", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_cb_changes_to_previous_word
      @window.cursor_col = 8

      @handler.handle("c")
      result = @handler.handle("b")

      assert_equal "hello rld", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_c0_changes_to_line_start
      @window.cursor_col = 5

      @handler.handle("c")
      result = @handler.handle("0")

      assert_equal " world", @buffer.line(0)
      assert_equal 0, @window.cursor_col
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_c_dollar_changes_to_line_end
      @window.cursor_col = 5

      @handler.handle("c")
      result = @handler.handle("$")

      assert_equal "hello", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_cG_changes_to_file_end
      @window.cursor_row = 1

      @handler.handle("c")
      result = @handler.handle("G")

      assert_equal 2, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
      assert_equal "", @buffer.line(1)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_cgg_changes_to_file_start
      @window.cursor_row = 2
      @window.cursor_col = 3

      @handler.handle("c")
      @handler.handle("g")
      result = @handler.handle("g")

      assert_equal 1, @buffer.line_count
      assert_equal "rd line", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_cf_changes_to_char
      @window.cursor_col = 0

      @handler.handle("c")
      @handler.handle("f")
      result = @handler.handle("o")

      assert_equal " world", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_ct_changes_till_char
      @window.cursor_col = 0

      @handler.handle("c")
      @handler.handle("t")
      result = @handler.handle("o")

      assert_equal "o world", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_cF_changes_backward_to_char
      @window.cursor_col = 10

      @handler.handle("c")
      @handler.handle("F")
      result = @handler.handle("o")

      assert_equal "hello wd", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_cT_changes_backward_till_char
      @window.cursor_col = 10

      @handler.handle("c")
      @handler.handle("T")
      result = @handler.handle("o")

      assert_equal "hello wod", @buffer.line(0)
      assert_equal Mui::Mode::INSERT, result.mode
    end

    def test_c_with_invalid_motion_cancels
      @window.cursor_col = 5

      @handler.handle("c")
      result = @handler.handle("z")

      assert_equal "hello world", @buffer.line(0)
      assert_nil result.mode
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
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer, @register)
    end

    def test_yy_yanks_current_line
      @window.cursor_row = 1

      @handler.handle("y")
      @handler.handle("y")

      assert_equal "second line", @register.get
      assert @register.linewise?
    end

    def test_yw_yanks_word
      @window.cursor_col = 0

      @handler.handle("y")
      @handler.handle("w")

      assert_equal "hello", @register.get
      refute @register.linewise?
    end

    def test_ye_yanks_to_end_of_word
      @window.cursor_col = 0

      @handler.handle("y")
      @handler.handle("e")

      assert_equal "hello", @register.get
    end

    def test_y_dollar_yanks_to_line_end
      @window.cursor_col = 6

      @handler.handle("y")
      @handler.handle("$")

      assert_equal "world", @register.get
    end

    def test_y0_yanks_to_line_start
      @window.cursor_col = 6

      @handler.handle("y")
      @handler.handle("0")

      assert_equal "hello ", @register.get
    end

    def test_yG_yanks_to_file_end
      @window.cursor_row = 1

      @handler.handle("y")
      @handler.handle("G")

      assert_equal "second line\nthird line", @register.get
      assert @register.linewise?
    end

    def test_ygg_yanks_to_file_start
      @window.cursor_row = 2

      @handler.handle("y")
      @handler.handle("g")
      @handler.handle("g")

      assert_equal "hello world\nsecond line\nthird line", @register.get
      assert @register.linewise?
    end

    def test_yf_yanks_to_char
      @window.cursor_col = 0

      @handler.handle("y")
      @handler.handle("f")
      @handler.handle("o")

      assert_equal "hello", @register.get
    end

    def test_yt_yanks_till_char
      @window.cursor_col = 0

      @handler.handle("y")
      @handler.handle("t")
      @handler.handle("o")

      assert_equal "hell", @register.get
    end
  end

  class TestPasteOperator < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @window = Mui::Window.new(@buffer)
      @register = Mui::Register.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer, @register)
    end

    def test_p_pastes_charwise_after_cursor
      @register.set("XYZ", linewise: false)
      @window.cursor_col = 4

      @handler.handle("p")

      assert_equal "helloXYZ world", @buffer.line(0)
    end

    def test_P_pastes_charwise_before_cursor
      @register.set("XYZ", linewise: false)
      @window.cursor_col = 5

      @handler.handle("P")

      assert_equal "helloXYZ world", @buffer.line(0)
    end

    def test_p_pastes_linewise_below_cursor
      @register.set("new line", linewise: true)
      @window.cursor_row = 0

      @handler.handle("p")

      assert_equal 3, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
      assert_equal "new line", @buffer.line(1)
      assert_equal "second line", @buffer.line(2)
    end

    def test_P_pastes_linewise_above_cursor
      @register.set("new line", linewise: true)
      @window.cursor_row = 1

      @handler.handle("P")

      assert_equal 3, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
      assert_equal "new line", @buffer.line(1)
      assert_equal "second line", @buffer.line(2)
    end

    def test_p_with_empty_register_does_nothing
      @handler.handle("p")

      assert_equal "hello world", @buffer.line(0)
      assert_equal 2, @buffer.line_count
    end

    def test_yy_p_duplicates_line
      @window.cursor_row = 0

      @handler.handle("y")
      @handler.handle("y")
      @handler.handle("p")

      assert_equal 3, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
      assert_equal "hello world", @buffer.line(1)
    end
  end

  class TestNamedRegisters < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.insert_line(1, "second line")
      @register = Mui::Register.new
      @window = Mui::Window.new(@buffer)
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer, @register)
    end

    def test_quote_a_yy_yanks_to_named_register
      @window.cursor_row = 0

      @handler.handle('"')
      @handler.handle("a")
      @handler.handle("y")
      @handler.handle("y")

      assert_equal "hello world", @register.get(name: "a")
      assert @register.linewise?(name: "a")
    end

    def test_quote_a_p_pastes_from_named_register
      @register.yank("from a", linewise: false, name: "a")
      @window.cursor_col = 4

      @handler.handle('"')
      @handler.handle("a")
      @handler.handle("p")

      assert_equal "hellofrom a world", @buffer.line(0)
    end

    def test_dd_saves_to_delete_history
      @window.cursor_row = 0

      @handler.handle("d")
      @handler.handle("d")

      assert_equal "hello world", @register.get(name: "1")
      assert @register.linewise?(name: "1")
    end

    def test_delete_history_shifts
      @window.cursor_row = 0

      @handler.handle("d")
      @handler.handle("d")
      # Now at "second line"
      @handler.handle("d")
      @handler.handle("d")

      assert_equal "second line", @register.get(name: "1")
      assert_equal "hello world", @register.get(name: "2")
    end

    def test_yy_saves_to_yank_register
      @window.cursor_row = 0

      @handler.handle("y")
      @handler.handle("y")

      assert_equal "hello world", @register.get(name: "0")
    end

    def test_dd_does_not_affect_yank_register
      @window.cursor_row = 0
      @handler.handle("y")
      @handler.handle("y")

      @handler.handle("d")
      @handler.handle("d")

      assert_equal "hello world", @register.get(name: "0")
      assert_equal "hello world", @register.get(name: "1")
    end

    def test_quote_underscore_dd_does_not_save_to_registers
      @window.cursor_row = 0

      @handler.handle('"')
      @handler.handle("_")
      @handler.handle("d")
      @handler.handle("d")

      assert_nil @register.get
      assert_nil @register.get(name: "1")
    end

    def test_quote_0_p_pastes_from_yank_register
      @window.cursor_row = 0
      @handler.handle("y")
      @handler.handle("y")

      @handler.handle("d")
      @handler.handle("d")

      @handler.handle('"')
      @handler.handle("0")
      @handler.handle("p")

      assert_equal "second line", @buffer.line(0)
      assert_equal "hello world", @buffer.line(1)
    end

    def test_cw_saves_to_delete_history
      @window.cursor_col = 0
      @window.cursor_row = 0

      @handler.handle("c")
      @handler.handle("w")

      assert_equal "hello", @register.get(name: "1")
      refute @register.linewise?(name: "1")
    end
  end

  class TestTabNavigation < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @tab_manager = @editor.tab_manager
    end

    def test_gt_moves_to_next_tab
      # Create a second tab
      @tab_manager.add

      assert_equal 2, @tab_manager.tab_count
      assert_equal 1, @tab_manager.current_index

      # Go back to first tab
      @tab_manager.first_tab
      assert_equal 0, @tab_manager.current_index

      # Use gt to go to next tab
      @editor.handle_key("g")
      @editor.handle_key("t")

      assert_equal 1, @tab_manager.current_index
    end

    def test_gT_moves_to_previous_tab
      # Create a second tab (cursor is at tab 1)
      @tab_manager.add

      assert_equal 2, @tab_manager.tab_count
      assert_equal 1, @tab_manager.current_index

      # Use gT to go to previous tab
      @editor.handle_key("g")
      @editor.handle_key("T")

      assert_equal 0, @tab_manager.current_index
    end

    def test_gt_wraps_around
      # Create two tabs
      @tab_manager.add

      assert_equal 2, @tab_manager.tab_count
      assert_equal 1, @tab_manager.current_index

      # gt should wrap to first tab
      @editor.handle_key("g")
      @editor.handle_key("t")

      assert_equal 0, @tab_manager.current_index
    end

    def test_gT_wraps_around
      # Start on first tab
      assert_equal 1, @tab_manager.tab_count
      assert_equal 0, @tab_manager.current_index

      # Create second tab and go back to first
      @tab_manager.add
      @tab_manager.first_tab
      assert_equal 0, @tab_manager.current_index

      # gT should wrap to last tab
      @editor.handle_key("g")
      @editor.handle_key("T")

      assert_equal 1, @tab_manager.current_index
    end

    def test_gg_still_works_for_file_start
      # Setup a buffer with multiple lines
      buffer = @tab_manager.window_manager.active_window.buffer
      buffer.lines[0] = "line 1"
      buffer.insert_line(1, "line 2")
      buffer.insert_line(2, "line 3")

      window = @tab_manager.active_window
      window.cursor_row = 2

      # gg should go to first line
      @editor.handle_key("g")
      @editor.handle_key("g")

      assert_equal 0, window.cursor_row
    end
  end
end
