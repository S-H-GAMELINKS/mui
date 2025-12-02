# frozen_string_literal: true

require "test_helper"

class TestSelection < Minitest::Test
  class TestInitialization < Minitest::Test
    def test_initializes_with_start_position
      selection = Mui::Selection.new(5, 10)

      assert_equal 5, selection.start_row
      assert_equal 10, selection.start_col
      assert_equal 5, selection.end_row
      assert_equal 10, selection.end_col
    end

    def test_initializes_with_line_mode_false_by_default
      selection = Mui::Selection.new(0, 0)

      refute selection.line_mode
    end

    def test_initializes_with_line_mode_true
      selection = Mui::Selection.new(0, 0, line_mode: true)

      assert selection.line_mode
    end
  end

  class TestUpdateEnd < Minitest::Test
    def test_update_end_changes_end_position
      selection = Mui::Selection.new(0, 0)

      selection.update_end(3, 5)

      assert_equal 3, selection.end_row
      assert_equal 5, selection.end_col
    end
  end

  class TestNormalizedRange < Minitest::Test
    def test_returns_correct_range_when_end_is_after_start
      selection = Mui::Selection.new(1, 5)
      selection.update_end(3, 10)

      range = selection.normalized_range

      assert_equal({ start_row: 1, start_col: 5, end_row: 3, end_col: 10 }, range)
    end

    def test_returns_swapped_range_when_end_is_before_start
      selection = Mui::Selection.new(3, 10)
      selection.update_end(1, 5)

      range = selection.normalized_range

      assert_equal({ start_row: 1, start_col: 5, end_row: 3, end_col: 10 }, range)
    end

    def test_handles_same_row_with_end_col_before_start_col
      selection = Mui::Selection.new(2, 10)
      selection.update_end(2, 3)

      range = selection.normalized_range

      assert_equal({ start_row: 2, start_col: 3, end_row: 2, end_col: 10 }, range)
    end
  end

  class TestCoversPositionCharMode < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")
      @buffer.insert_line(2, "foo bar")
    end

    def test_covers_single_line_selection
      selection = Mui::Selection.new(1, 2)
      selection.update_end(1, 4)

      assert selection.covers_position?(1, 2, @buffer)
      assert selection.covers_position?(1, 3, @buffer)
      assert selection.covers_position?(1, 4, @buffer)
      refute selection.covers_position?(1, 1, @buffer)
      refute selection.covers_position?(1, 5, @buffer)
      refute selection.covers_position?(0, 3, @buffer)
    end

    def test_covers_multi_line_selection
      selection = Mui::Selection.new(0, 3)
      selection.update_end(2, 2)

      # First line: from col 3 to end
      assert selection.covers_position?(0, 3, @buffer)
      assert selection.covers_position?(0, 4, @buffer)
      refute selection.covers_position?(0, 2, @buffer)

      # Middle line: entire line
      assert selection.covers_position?(1, 0, @buffer)
      assert selection.covers_position?(1, 4, @buffer)

      # Last line: from start to col 2
      assert selection.covers_position?(2, 0, @buffer)
      assert selection.covers_position?(2, 2, @buffer)
      refute selection.covers_position?(2, 3, @buffer)
    end

    def test_covers_backward_selection
      selection = Mui::Selection.new(2, 4)
      selection.update_end(1, 1)

      assert selection.covers_position?(1, 1, @buffer)
      assert selection.covers_position?(1, 4, @buffer)
      assert selection.covers_position?(2, 0, @buffer)
      assert selection.covers_position?(2, 4, @buffer)
      refute selection.covers_position?(1, 0, @buffer)
      refute selection.covers_position?(2, 5, @buffer)
    end
  end

  class TestCoversPositionLineMode < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")
      @buffer.insert_line(2, "foo bar")
    end

    def test_covers_entire_lines_in_selection
      selection = Mui::Selection.new(1, 2, line_mode: true)
      selection.update_end(2, 3)

      # Row 1 is selected (any column)
      assert selection.covers_position?(1, 0, @buffer)
      assert selection.covers_position?(1, 4, @buffer)

      # Row 2 is selected (any column)
      assert selection.covers_position?(2, 0, @buffer)
      assert selection.covers_position?(2, 6, @buffer)

      # Row 0 is not selected
      refute selection.covers_position?(0, 0, @buffer)
      refute selection.covers_position?(0, 4, @buffer)
    end

    def test_covers_backward_line_selection
      selection = Mui::Selection.new(2, 5, line_mode: true)
      selection.update_end(0, 2)

      assert selection.covers_position?(0, 0, @buffer)
      assert selection.covers_position?(1, 2, @buffer)
      assert selection.covers_position?(2, 4, @buffer)
    end
  end
end
