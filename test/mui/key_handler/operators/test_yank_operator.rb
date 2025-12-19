# frozen_string_literal: true

require "test_helper"

class TestYankOperator < Minitest::Test
  def setup
    @buffer = Mui::Buffer.new
    @buffer.lines[0] = "hello world"
    @window = Mui::Window.new(@buffer)
    @register = Mui::Register.new
    @operator = Mui::KeyHandler::Operators::YankOperator.new(
      buffer: @buffer,
      window: @window,
      register: @register
    )
  end

  class TestYankLine < TestYankOperator
    def test_yank_line_stores_text_in_register
      result = @operator.handle_pending("y")

      assert_equal :done, result
      assert_equal "hello world", @register.get
      assert_predicate @register, :linewise?
    end

    def test_yank_line_does_not_modify_buffer
      @operator.handle_pending("y")

      assert_equal "hello world", @buffer.line(0)
    end

    def test_yank_line_with_named_register
      @operator.handle_pending("y", pending_register: "a")

      assert_equal "hello world", @register.get(name: "a")
    end
  end

  class TestYankMotion < TestYankOperator
    def test_yank_word_forward_behaves_like_word_end
      # yw behaves like ye in Vim for yank
      @window.cursor_col = 0

      result = @operator.handle_pending("w")

      assert_equal :done, result
      assert_equal "hello", @register.get
      refute_predicate @register, :linewise?
    end

    def test_yank_word_end
      @window.cursor_col = 0

      result = @operator.handle_pending("e")

      assert_equal :done, result
      assert_equal "hello", @register.get
    end

    def test_yank_word_backward
      @window.cursor_col = 8

      result = @operator.handle_pending("b")

      assert_equal :done, result
      assert_equal "wo", @register.get
    end

    def test_yank_motion_does_not_modify_buffer
      @window.cursor_col = 0

      @operator.handle_pending("e")

      assert_equal "hello world", @buffer.line(0)
    end
  end

  class TestYankToLineStartEnd < TestYankOperator
    def test_yank_to_line_start
      @window.cursor_col = 6

      result = @operator.handle_pending("0")

      assert_equal :done, result
      assert_equal "hello ", @register.get
      refute_predicate @register, :linewise?
    end

    def test_yank_to_line_start_at_column_zero_does_nothing
      @window.cursor_col = 0

      result = @operator.handle_pending("0")

      assert_equal :done, result
      assert_empty @register
    end

    def test_yank_to_line_end
      @window.cursor_col = 6

      result = @operator.handle_pending("$")

      assert_equal :done, result
      assert_equal "world", @register.get
    end

    def test_yank_to_line_end_on_empty_line_does_nothing
      @buffer.lines[0] = ""

      result = @operator.handle_pending("$")

      assert_equal :done, result
      assert_empty @register
    end

    def test_yank_does_not_modify_buffer
      @window.cursor_col = 6

      @operator.handle_pending("0")

      assert_equal "hello world", @buffer.line(0)
    end
  end

  class TestYankToFileStartEnd < TestYankOperator
    def setup
      super
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
    end

    def test_yank_to_file_end
      @window.cursor_row = 1

      result = @operator.handle_pending("G")

      assert_equal :done, result
      assert_equal "second line\nthird line", @register.get
      assert_predicate @register, :linewise?
    end

    def test_yank_to_file_start_returns_pending
      result = @operator.handle_pending("g")

      assert_equal :pending_yg, result
    end

    def test_handle_to_file_start_with_gg
      @window.cursor_row = 2

      result = @operator.handle_to_file_start("g")

      assert_equal :done, result
      assert_equal "hello world\nsecond line\nthird line", @register.get
      assert_predicate @register, :linewise?
    end

    def test_yank_does_not_modify_buffer
      @window.cursor_row = 1

      @operator.handle_pending("G")

      assert_equal 3, @buffer.line_count
      assert_equal "second line", @buffer.line(1)
    end
  end

  class TestYankFindChar < TestYankOperator
    def test_handle_pending_f_returns_pending
      result = @operator.handle_pending("f")

      assert_equal :pending_yf, result
    end

    def test_handle_pending_upper_f_returns_pending
      result = @operator.handle_pending("F")

      assert_equal :pending_yF, result
    end

    def test_handle_pending_t_returns_pending
      result = @operator.handle_pending("t")

      assert_equal :pending_yt, result
    end

    def test_handle_pending_upper_t_returns_pending
      result = @operator.handle_pending("T")

      assert_equal :pending_yT, result
    end

    def test_handle_find_char_yf
      @window.cursor_col = 0

      result = @operator.handle_find_char("w", :yf)

      assert_equal :done, result
      assert_equal "hello w", @register.get
    end

    def test_handle_find_char_y_upper_f
      @window.cursor_col = 10

      result = @operator.handle_find_char("w", :yF)

      assert_equal :done, result
      assert_equal "worl", @register.get
    end

    def test_handle_find_char_yt
      @window.cursor_col = 0

      result = @operator.handle_find_char("w", :yt)

      assert_equal :done, result
      assert_equal "hello ", @register.get
    end

    def test_handle_find_char_y_upper_t
      # "hello world" cursor at col 10 ('d')
      # yTo: yank backward till 'o', 'o' is at col 7
      # yank from col 8 to col 9 = "rl"
      @window.cursor_col = 10

      result = @operator.handle_find_char("o", :yT)

      assert_equal :done, result
      assert_equal "rl", @register.get
    end

    def test_handle_find_char_not_found_returns_cancel
      result = @operator.handle_find_char("z", :yf)

      assert_equal :cancel, result
      assert_empty @register
    end

    def test_yank_find_char_does_not_modify_buffer
      @window.cursor_col = 0

      @operator.handle_find_char("w", :yf)

      assert_equal "hello world", @buffer.line(0)
    end
  end

  class TestUnknownChar < TestYankOperator
    def test_unknown_char_returns_cancel
      result = @operator.handle_pending("z")

      assert_equal :cancel, result
      assert_empty @register
    end
  end
end
