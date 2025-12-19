# frozen_string_literal: true

require "test_helper"

class TestChangeOperator < Minitest::Test
  def setup
    @buffer = Mui::Buffer.new
    @buffer.lines[0] = "hello world"
    @window = Mui::Window.new(@buffer)
    @register = Mui::Register.new
    @undo_manager = Mui::UndoManager.new
    @operator = Mui::KeyHandler::Operators::ChangeOperator.new(
      buffer: @buffer,
      window: @window,
      register: @register,
      undo_manager: @undo_manager
    )
  end

  class TestChangeLine < TestChangeOperator
    def test_change_line_clears_line_and_returns_insert_mode
      result = @operator.handle_pending("c")

      assert_equal :insert_mode, result
      assert_equal "", @buffer.line(0)
    end

    def test_change_line_stores_text_in_register
      @operator.handle_pending("c")

      assert_equal "hello world", @register.get
      assert_predicate @register, :linewise?
    end

    def test_change_line_sets_cursor_to_zero
      @window.cursor_col = 5

      @operator.handle_pending("c")

      assert_equal 0, @window.cursor_col
    end

    def test_change_line_with_named_register
      @operator.handle_pending("c", pending_register: "a")

      assert_equal "hello world", @register.get(name: "a")
    end
  end

  class TestChangeMotion < TestChangeOperator
    def test_change_word_forward_behaves_like_word_end
      # cw behaves like ce in Vim
      @window.cursor_col = 0

      result = @operator.handle_pending("w")

      assert_equal :insert_mode, result
      assert_equal " world", @buffer.line(0)
    end

    def test_change_word_end
      @window.cursor_col = 0

      result = @operator.handle_pending("e")

      assert_equal :insert_mode, result
      assert_equal " world", @buffer.line(0)
    end

    def test_change_word_backward
      @window.cursor_col = 8

      result = @operator.handle_pending("b")

      assert_equal :insert_mode, result
      assert_equal "hello rld", @buffer.line(0)
    end

    def test_change_motion_stores_text_in_register
      @window.cursor_col = 0

      @operator.handle_pending("e")

      assert_equal "hello", @register.get
      refute_predicate @register, :linewise?
    end
  end

  class TestChangeToLineStartEnd < TestChangeOperator
    def test_change_to_line_start
      @window.cursor_col = 6

      result = @operator.handle_pending("0")

      assert_equal :insert_mode, result
      assert_equal "world", @buffer.line(0)
      assert_equal 0, @window.cursor_col
    end

    def test_change_to_line_start_at_column_zero
      @window.cursor_col = 0

      result = @operator.handle_pending("0")

      assert_equal :insert_mode, result
      assert_equal "hello world", @buffer.line(0)
    end

    def test_change_to_line_end
      @window.cursor_col = 6

      result = @operator.handle_pending("$")

      assert_equal :insert_mode, result
      assert_equal "hello ", @buffer.line(0)
    end

    def test_change_to_line_end_on_empty_line
      @buffer.lines[0] = ""

      result = @operator.handle_pending("$")

      assert_equal :insert_mode, result
      assert_equal "", @buffer.line(0)
    end
  end

  class TestChangeToFileStartEnd < TestChangeOperator
    def setup
      super
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
    end

    def test_change_to_file_end
      @window.cursor_row = 1

      result = @operator.handle_pending("G")

      assert_equal :insert_mode, result
      # Lines 1-2 deleted, new empty line inserted
      assert_equal 2, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
    end

    def test_change_to_file_end_stores_linewise_text
      @window.cursor_row = 1

      @operator.handle_pending("G")

      assert_equal "second line\nthird line", @register.get
      assert_predicate @register, :linewise?
    end

    def test_change_to_file_start_returns_pending
      result = @operator.handle_pending("g")

      assert_equal :pending_cg, result
    end

    def test_handle_to_file_start_with_gg
      @window.cursor_row = 2

      result = @operator.handle_to_file_start("g")

      assert_equal :insert_mode, result
      assert_equal 0, @window.cursor_row
    end
  end

  class TestChangeFindChar < TestChangeOperator
    def test_handle_pending_f_returns_pending
      result = @operator.handle_pending("f")

      assert_equal :pending_cf, result
    end

    def test_handle_pending_upper_f_returns_pending
      result = @operator.handle_pending("F")

      assert_equal :pending_cF, result
    end

    def test_handle_pending_t_returns_pending
      result = @operator.handle_pending("t")

      assert_equal :pending_ct, result
    end

    def test_handle_pending_upper_t_returns_pending
      result = @operator.handle_pending("T")

      assert_equal :pending_cT, result
    end

    def test_handle_find_char_cf
      @window.cursor_col = 0

      result = @operator.handle_find_char("w", :cf)

      assert_equal :insert_mode, result
      assert_equal "orld", @buffer.line(0)
    end

    def test_handle_find_char_c_upper_f
      @window.cursor_col = 10

      result = @operator.handle_find_char("w", :cF)

      assert_equal :insert_mode, result
      assert_equal "hello d", @buffer.line(0)
    end

    def test_handle_find_char_ct
      @window.cursor_col = 0

      result = @operator.handle_find_char("w", :ct)

      assert_equal :insert_mode, result
      assert_equal "world", @buffer.line(0)
    end

    def test_handle_find_char_c_upper_t
      # "hello world" cursor at col 10 ('d')
      # cTo: change backward till 'o', 'o' is at col 7
      # delete from col 8 to col 9, result: "hello wo" + "d" = "hello wod"
      @window.cursor_col = 10

      result = @operator.handle_find_char("o", :cT)

      assert_equal :insert_mode, result
      assert_equal "hello wod", @buffer.line(0)
    end

    def test_handle_find_char_not_found_returns_cancel
      result = @operator.handle_find_char("z", :cf)

      assert_equal :cancel, result
      assert_equal "hello world", @buffer.line(0)
    end
  end

  class TestUnknownChar < TestChangeOperator
    def test_unknown_char_returns_cancel
      result = @operator.handle_pending("z")

      assert_equal :cancel, result
      assert_equal "hello world", @buffer.line(0)
    end
  end

  class TestInheritanceFromDeleteOperator < TestChangeOperator
    def test_change_operator_is_subclass_of_delete_operator
      assert_kind_of Mui::KeyHandler::Operators::DeleteOperator, @operator
    end
  end
end
