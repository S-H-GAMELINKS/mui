# frozen_string_literal: true

require "test_helper"

class TestWindow < Minitest::Test
  class TestInitialize < Minitest::Test
    def test_with_default_geometry
      buffer = Mui::Buffer.new
      window = Mui::Window.new(buffer)

      assert_equal buffer, window.buffer
      assert_equal 0, window.x
      assert_equal 0, window.y
      assert_equal 80, window.width
      assert_equal 24, window.height
      assert_equal 0, window.cursor_row
      assert_equal 0, window.cursor_col
      assert_equal 0, window.scroll_row
      assert_equal 0, window.scroll_col
    end

    def test_with_custom_geometry
      buffer = Mui::Buffer.new
      window = Mui::Window.new(buffer, x: 10, y: 5, width: 40, height: 12)

      assert_equal 10, window.x
      assert_equal 5, window.y
      assert_equal 40, window.width
      assert_equal 12, window.height
    end
  end

  class TestVisibleHeight < Minitest::Test
    def test_returns_height_minus_status_and_command_lines
      buffer = Mui::Buffer.new
      window = Mui::Window.new(buffer, width: 80, height: 24)

      assert_equal 22, window.visible_height
    end
  end

  class TestVisibleWidth < Minitest::Test
    def test_returns_window_width
      buffer = Mui::Buffer.new
      window = Mui::Window.new(buffer, width: 80, height: 24)

      assert_equal 80, window.visible_width
    end
  end

  class TestMoveLeft < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer, width: 80, height: 24)
    end

    def test_decrements_cursor_col
      @buffer.insert_char(0, 0, "abc")
      @window.cursor_col = 2

      @window.move_left

      assert_equal 1, @window.cursor_col
    end

    def test_does_not_move_past_left_edge
      @buffer.insert_char(0, 0, "abc")
      @window.cursor_col = 0

      @window.move_left

      assert_equal 0, @window.cursor_col
    end
  end

  class TestMoveRight < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer, width: 80, height: 24)
    end

    def test_increments_cursor_col
      @buffer.insert_char(0, 0, "a")
      @buffer.insert_char(0, 1, "b")
      @buffer.insert_char(0, 2, "c")
      @window.cursor_col = 0

      @window.move_right

      assert_equal 1, @window.cursor_col
    end

    def test_does_not_move_past_last_character
      @buffer.insert_char(0, 0, "a")
      @buffer.insert_char(0, 1, "b")
      @buffer.insert_char(0, 2, "c")
      @window.cursor_col = 2

      @window.move_right

      assert_equal 2, @window.cursor_col
    end

    def test_does_not_move_on_empty_line
      @window.cursor_col = 0

      @window.move_right

      assert_equal 0, @window.cursor_col
    end
  end

  class TestMoveUp < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer, width: 80, height: 24)
    end

    def test_decrements_cursor_row
      @buffer.insert_line(0, "line1")
      @buffer.insert_line(1, "line2")
      @window.cursor_row = 1

      @window.move_up

      assert_equal 0, @window.cursor_row
    end

    def test_does_not_move_past_first_line
      @buffer.insert_line(0, "line1")
      @window.cursor_row = 0

      @window.move_up

      assert_equal 0, @window.cursor_row
    end

    def test_clamps_cursor_col_to_shorter_line
      @buffer.insert_line(0, "short")
      @buffer.insert_line(1, "this is a longer line")
      @window.cursor_row = 1
      @window.cursor_col = 15

      @window.move_up

      assert_equal 0, @window.cursor_row
      assert_equal 4, @window.cursor_col
    end
  end

  class TestMoveDown < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer, width: 80, height: 24)
    end

    def test_increments_cursor_row
      @buffer.lines[0] = "line1"
      @buffer.insert_line(1, "line2")
      @window.cursor_row = 0

      @window.move_down

      assert_equal 1, @window.cursor_row
    end

    def test_does_not_move_past_last_line
      @buffer.lines[0] = "line1"
      @buffer.insert_line(1, "line2")
      @window.cursor_row = 1

      @window.move_down

      assert_equal 1, @window.cursor_row
    end

    def test_clamps_cursor_col_to_shorter_line
      @buffer.insert_line(0, "this is a longer line")
      @buffer.insert_line(1, "short")
      @window.cursor_row = 0
      @window.cursor_col = 15

      @window.move_down

      assert_equal 1, @window.cursor_row
      assert_equal 4, @window.cursor_col
    end
  end

  class TestEnsureCursorVisible < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer, width: 80, height: 24)
    end

    def test_scrolls_down_when_cursor_below_visible
      25.times { |i| @buffer.insert_line(i, "line#{i}") }
      @window.cursor_row = 24

      @window.ensure_cursor_visible

      assert_equal 3, @window.scroll_row
    end

    def test_scrolls_up_when_cursor_above_visible
      @window.scroll_row = 10
      @window.cursor_row = 5

      @window.ensure_cursor_visible

      assert_equal 5, @window.scroll_row
    end

    def test_scrolls_right_when_cursor_past_visible
      @buffer.insert_line(0, "a" * 100)
      @window.cursor_col = 90

      @window.ensure_cursor_visible

      assert_equal 11, @window.scroll_col
    end

    def test_scrolls_left_when_cursor_before_visible
      @window.scroll_col = 20
      @window.cursor_col = 10

      @window.ensure_cursor_visible

      assert_equal 10, @window.scroll_col
    end
  end

  class TestScreenCursorPosition < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer, width: 80, height: 24)
    end

    def test_returns_cursor_position_adjusted_for_window_and_scroll
      # Add enough lines and content for the test
      20.times { @buffer.insert_line(@buffer.line_count, "") }
      @buffer.replace_line(10, "0123456789abcdefghij")

      @window.x = 5
      @window.y = 2
      @window.cursor_row = 10
      @window.cursor_col = 15
      @window.scroll_row = 3
      @window.scroll_col = 5

      # screen_cursor_x = window.x + display_width(text[scroll_col...cursor_col])
      # = 5 + width("56789abcde") = 5 + 10 = 15
      assert_equal 15, @window.screen_cursor_x
      assert_equal 9, @window.screen_cursor_y
    end

    def test_cursor_position_with_japanese_text
      @buffer.replace_line(0, "Hello世界Test")

      @window.x = 0
      @window.cursor_row = 0
      @window.cursor_col = 7 # After "Hello世界" (5 + 2 chars)
      @window.scroll_col = 0

      # "Hello世界" = 5 (ASCII) + 4 (2 wide chars) = 9 display width
      assert_equal 9, @window.screen_cursor_x
    end

    def test_cursor_position_with_scroll_and_japanese
      @buffer.replace_line(0, "あいうえおABCDE")

      @window.x = 0
      @window.cursor_row = 0
      @window.cursor_col = 7  # After "あいうえおAB"
      @window.scroll_col = 2  # Skip "あい"

      # visible: "うえおAB" from scroll_col=2 to cursor_col=7
      # "うえおAB" = 6 (3 wide chars) + 2 (ASCII) = 8 display width
      assert_equal 8, @window.screen_cursor_x
    end
  end
end
