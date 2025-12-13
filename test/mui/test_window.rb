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
    def test_returns_height_minus_status_line
      buffer = Mui::Buffer.new
      window = Mui::Window.new(buffer, width: 80, height: 24)

      # height 24 - status line 1 = 23 (command line is shared, not per-window)
      assert_equal 23, window.visible_height
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

      # visible_height = 24 - 1 = 23, cursor at 24 means scroll_row = 24 - 23 + 1 = 2
      assert_equal 2, @window.scroll_row
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

  class TestRender < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @adapter = Mui::TerminalAdapter::Test.new(width: 80, height: 24)
      @screen = Mui::Screen.new(adapter: @adapter)
      @window = Mui::Window.new(@buffer, width: 80, height: 24)
    end

    def test_clears_lines_beyond_buffer_content
      # Add only 3 lines to the buffer
      @buffer.insert_line(0, "Line 1")
      @buffer.insert_line(1, "Line 2")
      @buffer.insert_line(2, "Line 3")

      @window.render(@screen)

      # visible_height = 23 (height 24 - 1 for status line)
      # Lines 0-2 have content, lines 3-22 should be cleared (spaces)

      # Check that line 3 (y=3) is cleared with spaces
      output_at_third_row = @adapter.all_output.find { |entry| entry[:y] == 3 && entry[:x].zero? }
      refute_nil output_at_third_row, "Should have output at row 3"
      assert_equal " " * 80, output_at_third_row[:text], "Line beyond buffer should be cleared with spaces"

      # Check that last visible line (22) is also cleared
      output_at_last_row = @adapter.all_output.find { |entry| entry[:y] == 22 && entry[:x].zero? }
      refute_nil output_at_last_row, "Should have output at row 22"
      assert_equal " " * 80, output_at_last_row[:text], "Last visible line should be cleared"
    end

    def test_clears_lines_after_buffer_switch_to_shorter_file
      # Start with a long file
      10.times { |i| @buffer.insert_line(i, "Line #{i}") }
      @window.render(@screen)

      # Clear adapter output buffer for fresh comparison
      @adapter.clear

      # Switch to a shorter buffer
      short_buffer = Mui::Buffer.new
      short_buffer.insert_line(0, "Short")
      @window.buffer = short_buffer
      @window.render(@screen)

      # Lines beyond the new buffer's content should be cleared
      output_at_second_row = @adapter.all_output.find { |entry| entry[:y] == 1 && entry[:x].zero? }
      refute_nil output_at_second_row, "Should have output at row 1"
      assert_equal " " * 80, output_at_second_row[:text], "Previous content should be cleared"
    end

    def test_clears_lines_with_style_when_color_scheme_present
      color_scheme = Mui::ColorScheme.new("test")
      color_scheme.define :normal, fg: :white, bg: :black

      color_manager = Mui::ColorManager.new
      screen = Mui::Screen.new(adapter: @adapter, color_manager:)
      window = Mui::Window.new(@buffer, width: 80, height: 24, color_scheme:)

      @buffer.insert_line(0, "Line 1")
      window.render(screen)

      # Lines beyond buffer (y=1) should be rendered with style (background color)
      styled_output = @adapter.all_output.find { |e| e[:y] == 1 && e[:x].zero? && e[:style] }
      refute_nil styled_output, "Line beyond buffer should have style"
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
