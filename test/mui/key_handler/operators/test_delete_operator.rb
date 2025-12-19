# frozen_string_literal: true

require "test_helper"

class TestDeleteOperator < Minitest::Test
  def setup
    @buffer = Mui::Buffer.new
    @buffer.lines[0] = "hello world"
    @window = Mui::Window.new(@buffer)
    @register = Mui::Register.new
    @undo_manager = Mui::UndoManager.new
    @operator = Mui::KeyHandler::Operators::DeleteOperator.new(
      buffer: @buffer,
      window: @window,
      register: @register,
      undo_manager: @undo_manager
    )
  end

  class TestDeleteLine < TestDeleteOperator
    def test_delete_line_removes_current_line
      result = @operator.handle_pending("d")

      assert_equal :done, result
      assert_equal "", @buffer.line(0)
    end

    def test_delete_line_stores_text_in_register
      @operator.handle_pending("d")

      assert_equal "hello world", @register.get
      assert_predicate @register, :linewise?
    end

    def test_delete_line_with_named_register
      @operator.handle_pending("d", pending_register: "a")

      assert_equal "hello world", @register.get(name: "a")
    end

    def test_delete_line_adjusts_cursor_row
      @buffer.insert_line(1, "second line")
      @window.cursor_row = 0

      @operator.handle_pending("d")

      assert_equal 0, @window.cursor_row
      assert_equal "second line", @buffer.line(0)
    end
  end

  class TestDeleteMotion < TestDeleteOperator
    def test_delete_word_forward
      @window.cursor_col = 0

      result = @operator.handle_pending("w")

      assert_equal :done, result
      assert_equal "world", @buffer.line(0)
    end

    def test_delete_word_end
      @window.cursor_col = 0

      result = @operator.handle_pending("e")

      assert_equal :done, result
      assert_equal " world", @buffer.line(0)
    end

    def test_delete_word_backward
      @window.cursor_col = 8

      result = @operator.handle_pending("b")

      assert_equal :done, result
      assert_equal "hello rld", @buffer.line(0)
    end

    def test_delete_motion_stores_text_in_register
      @window.cursor_col = 0

      @operator.handle_pending("e")

      assert_equal "hello", @register.get
      refute_predicate @register, :linewise?
    end
  end

  class TestDeleteToLineStartEnd < TestDeleteOperator
    def test_delete_to_line_start
      @window.cursor_col = 6

      result = @operator.handle_pending("0")

      assert_equal :done, result
      assert_equal "world", @buffer.line(0)
      assert_equal 0, @window.cursor_col
    end

    def test_delete_to_line_start_at_column_zero_does_nothing
      @window.cursor_col = 0

      result = @operator.handle_pending("0")

      assert_equal :done, result
      assert_equal "hello world", @buffer.line(0)
    end

    def test_delete_to_line_end
      @window.cursor_col = 6

      result = @operator.handle_pending("$")

      assert_equal :done, result
      assert_equal "hello ", @buffer.line(0)
    end

    def test_delete_to_line_end_on_empty_line_does_nothing
      @buffer.lines[0] = ""

      result = @operator.handle_pending("$")

      assert_equal :done, result
      assert_equal "", @buffer.line(0)
    end
  end

  class TestDeleteToFileStartEnd < TestDeleteOperator
    def setup
      super
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
    end

    def test_delete_to_file_end
      @window.cursor_row = 1

      result = @operator.handle_pending("G")

      assert_equal :done, result
      assert_equal 1, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
    end

    def test_delete_to_file_end_stores_linewise_text
      @window.cursor_row = 1

      @operator.handle_pending("G")

      assert_equal "second line\nthird line", @register.get
      assert_predicate @register, :linewise?
    end

    def test_delete_to_file_start_returns_pending
      result = @operator.handle_pending("g")

      assert_equal :pending_dg, result
    end

    def test_handle_to_file_start_with_gg
      @window.cursor_row = 2

      result = @operator.handle_to_file_start("g")

      assert_equal :done, result
      assert_equal 0, @window.cursor_row
    end

    def test_handle_to_file_start_deletes_lines
      @window.cursor_row = 2
      @window.cursor_col = 5

      @operator.handle_to_file_start("g")

      # Lines 0-2 should be deleted, but partial line 2 after cursor remains
      assert_equal " line", @buffer.line(0)
    end
  end

  class TestDeleteFindChar < TestDeleteOperator
    def test_handle_pending_f_returns_pending
      result = @operator.handle_pending("f")

      assert_equal :pending_df, result
    end

    def test_handle_pending_upper_f_returns_pending
      result = @operator.handle_pending("F")

      assert_equal :pending_dF, result
    end

    def test_handle_pending_t_returns_pending
      result = @operator.handle_pending("t")

      assert_equal :pending_dt, result
    end

    def test_handle_pending_upper_t_returns_pending
      result = @operator.handle_pending("T")

      assert_equal :pending_dT, result
    end

    def test_handle_find_char_df
      @window.cursor_col = 0

      result = @operator.handle_find_char("w", :df)

      assert_equal :done, result
      assert_equal "orld", @buffer.line(0)
    end

    def test_handle_find_char_d_upper_f
      @window.cursor_col = 10

      result = @operator.handle_find_char("w", :dF)

      assert_equal :done, result
      assert_equal "hello d", @buffer.line(0)
    end

    def test_handle_find_char_dt
      @window.cursor_col = 0

      result = @operator.handle_find_char("w", :dt)

      assert_equal :done, result
      assert_equal "world", @buffer.line(0)
    end

    def test_handle_find_char_d_upper_t
      # "hello world" cursor at col 10 ('d')
      # dTo: delete backward till 'o', 'o' is at col 7
      # delete from col 8 to col 9, result: "hello wo" + "d" = "hello wod"
      @window.cursor_col = 10

      result = @operator.handle_find_char("o", :dT)

      assert_equal :done, result
      assert_equal "hello wod", @buffer.line(0)
    end

    def test_handle_find_char_not_found_returns_cancel
      result = @operator.handle_find_char("z", :df)

      assert_equal :cancel, result
      assert_equal "hello world", @buffer.line(0)
    end
  end

  class TestUnknownChar < TestDeleteOperator
    def test_unknown_char_returns_cancel
      result = @operator.handle_pending("z")

      assert_equal :cancel, result
      assert_equal "hello world", @buffer.line(0)
    end
  end
end
