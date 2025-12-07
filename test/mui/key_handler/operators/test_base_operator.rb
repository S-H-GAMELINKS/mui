# frozen_string_literal: true

require "test_helper"

class TestBaseOperator < Minitest::Test
  # Concrete subclass for testing BaseOperator
  class TestOperator < Mui::KeyHandler::Operators::BaseOperator
    def handle_pending(_char, pending_register: nil) # rubocop:disable Lint/UnusedMethodArgument
      :done
    end

    # Expose protected methods for testing
    public :extract_text, :extract_text_same_line, :extract_text_across_lines
    public :calculate_motion_end
    public :execute_delete, :execute_delete_same_line, :execute_delete_across_lines
    public :cursor_row, :cursor_col, :cursor_row=, :cursor_col=
  end

  def setup
    @buffer = Mui::Buffer.new
    @buffer.lines[0] = "hello world"
    @window = Mui::Window.new(@buffer)
    @register = Mui::Register.new
    @operator = TestOperator.new(buffer: @buffer, window: @window, register: @register)
  end

  class TestInitialization < TestBaseOperator
    def test_initialize_sets_dependencies
      assert_equal @buffer, @operator.send(:buffer)
      assert_equal @register, @operator.send(:register)
    end

    def test_update_changes_dependencies
      new_buffer = Mui::Buffer.new
      new_window = Mui::Window.new(new_buffer)
      new_register = Mui::Register.new

      @operator.update(buffer: new_buffer, window: new_window, register: new_register)

      assert_equal new_buffer, @operator.send(:buffer)
      assert_equal new_register, @operator.send(:register)
    end
  end

  class TestCursorAccessors < TestBaseOperator
    def test_cursor_row_returns_window_cursor_row
      @window.cursor_row = 0

      assert_equal 0, @operator.cursor_row
    end

    def test_cursor_col_returns_window_cursor_col
      @window.cursor_col = 5

      assert_equal 5, @operator.cursor_col
    end

    def test_cursor_row_setter_updates_window
      @operator.cursor_row = 0

      assert_equal 0, @window.cursor_row
    end

    def test_cursor_col_setter_updates_window
      @operator.cursor_col = 3

      assert_equal 3, @window.cursor_col
    end
  end

  class TestExtractTextSameLine < TestBaseOperator
    def test_extract_text_same_line_non_inclusive
      start_pos = { row: 0, col: 0 }
      end_pos = { row: 0, col: 5 }

      text = @operator.extract_text_same_line(start_pos, end_pos, inclusive: false)

      assert_equal "hello", text
    end

    def test_extract_text_same_line_inclusive
      start_pos = { row: 0, col: 0 }
      end_pos = { row: 0, col: 4 }

      text = @operator.extract_text_same_line(start_pos, end_pos, inclusive: true)

      assert_equal "hello", text
    end

    def test_extract_text_same_line_reversed_positions
      start_pos = { row: 0, col: 5 }
      end_pos = { row: 0, col: 0 }

      text = @operator.extract_text_same_line(start_pos, end_pos, inclusive: false)

      assert_equal "hello", text
    end

    def test_extract_text_same_line_empty_when_to_less_than_from
      start_pos = { row: 0, col: 5 }
      end_pos = { row: 0, col: 5 }

      text = @operator.extract_text_same_line(start_pos, end_pos, inclusive: false)

      assert_equal "", text
    end
  end

  class TestExtractTextAcrossLines < TestBaseOperator
    def setup
      super
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
    end

    def test_extract_text_across_lines_inclusive
      # "hello world" (row 0), "second line" (row 1)
      # inclusive: true, col 6 = 'w', col 5 = 'd' -> "world\nsecond"
      start_pos = { row: 0, col: 6 }
      end_pos = { row: 1, col: 5 }

      text = @operator.extract_text_across_lines(start_pos, end_pos, inclusive: true)

      assert_equal "world\nsecond", text
    end

    def test_extract_text_across_multiple_lines_inclusive
      # "hello world" (row 0, col 6-10 = "world")
      # "second line" (row 1, full line)
      # "third line" (row 2, col 0-4 = "third")
      start_pos = { row: 0, col: 6 }
      end_pos = { row: 2, col: 4 }

      text = @operator.extract_text_across_lines(start_pos, end_pos, inclusive: true)

      assert_equal "world\nsecond line\nthird", text
    end
  end

  class TestExtractText < TestBaseOperator
    def test_extract_text_delegates_to_same_line_method
      # "hello world", col 0-4 inclusive = "hello"
      start_pos = { row: 0, col: 0 }
      end_pos = { row: 0, col: 4 }

      text = @operator.extract_text(start_pos, end_pos, inclusive: true)

      assert_equal "hello", text
    end

    def test_extract_text_delegates_to_across_lines_method
      @buffer.insert_line(1, "world")
      start_pos = { row: 0, col: 0 }
      end_pos = { row: 1, col: 5 }

      text = @operator.extract_text(start_pos, end_pos, inclusive: true)

      assert_equal "hello world\nworld", text
    end
  end

  class TestCalculateMotionEnd < TestBaseOperator
    def test_word_forward_motion
      @window.cursor_col = 0

      result = @operator.calculate_motion_end(:word_forward)

      assert_equal 0, result[:row]
      assert_equal 6, result[:col]
    end

    def test_word_end_motion
      @window.cursor_col = 0

      result = @operator.calculate_motion_end(:word_end)

      assert_equal 0, result[:row]
      assert_equal 4, result[:col]
    end

    def test_word_backward_motion
      @window.cursor_col = 8

      result = @operator.calculate_motion_end(:word_backward)

      assert_equal 0, result[:row]
      assert_equal 6, result[:col]
    end
  end

  class TestExecuteDeleteSameLine < TestBaseOperator
    def test_execute_delete_same_line_non_inclusive
      start_pos = { row: 0, col: 0 }
      end_pos = { row: 0, col: 5 }

      @operator.execute_delete_same_line(start_pos, end_pos, inclusive: false)

      assert_equal " world", @buffer.line(0)
      assert_equal 0, @window.cursor_col
    end

    def test_execute_delete_same_line_inclusive
      start_pos = { row: 0, col: 0 }
      end_pos = { row: 0, col: 4 }

      @operator.execute_delete_same_line(start_pos, end_pos, inclusive: true)

      assert_equal " world", @buffer.line(0)
    end

    def test_execute_delete_same_line_clamps_cursor
      @buffer.lines[0] = "ab"
      start_pos = { row: 0, col: 0 }
      end_pos = { row: 0, col: 2 }

      @operator.execute_delete_same_line(start_pos, end_pos, inclusive: true, clamp: true)

      assert_equal "", @buffer.line(0)
      assert_equal 0, @window.cursor_col
    end
  end

  class TestExecuteDeleteAcrossLines < TestBaseOperator
    def setup
      super
      @buffer.insert_line(1, "second line")
      @buffer.insert_line(2, "third line")
    end

    def test_execute_delete_across_lines
      start_pos = { row: 0, col: 6 }
      end_pos = { row: 1, col: 6 }

      @operator.execute_delete_across_lines(start_pos, end_pos, inclusive: true)

      assert_equal "hello line", @buffer.line(0)
      assert_equal 0, @window.cursor_row
      assert_equal 6, @window.cursor_col
    end
  end

  class TestExecuteDelete < TestBaseOperator
    def test_execute_delete_delegates_to_same_line_method
      # "hello world", delete col 0-4 inclusive = delete "hello", result = " world"
      start_pos = { row: 0, col: 0 }
      end_pos = { row: 0, col: 4 }

      @operator.execute_delete(start_pos, end_pos, inclusive: true)

      assert_equal " world", @buffer.line(0)
    end

    def test_execute_delete_delegates_to_across_lines_method
      @buffer.insert_line(1, "second")
      start_pos = { row: 0, col: 6 }
      end_pos = { row: 1, col: 3 }

      @operator.execute_delete(start_pos, end_pos, inclusive: true)

      assert_equal "hello nd", @buffer.line(0)
    end
  end
end
