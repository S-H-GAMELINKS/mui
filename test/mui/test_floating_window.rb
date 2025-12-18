# frozen_string_literal: true

require "test_helper"

class TestFloatingWindow < Minitest::Test
  class MockScreen
    attr_reader :output, :positions, :width, :height

    def initialize(width: 80, height: 24)
      @width = width
      @height = height
      @output = []
      @positions = []
    end

    def put_with_style(row, col, text, _style)
      @positions << [row, col]
      @output << text
    end

    def put(row, col, text)
      @positions << [row, col]
      @output << text
    end
  end

  class MockColorScheme
    def [](_key)
      { fg: :white, bg: :blue, bold: false, underline: false }
    end
  end

  def setup
    @color_scheme = MockColorScheme.new
    @floating = Mui::FloatingWindow.new(@color_scheme)
  end

  class TestInitialization < TestFloatingWindow
    def test_starts_hidden
      refute @floating.visible
    end

    def test_content_empty_initially
      assert_empty @floating.content
    end
  end

  class TestShow < TestFloatingWindow
    def test_show_makes_visible
      @floating.show("Hello", row: 5, col: 10)

      assert @floating.visible
    end

    def test_show_sets_position
      @floating.show("Hello", row: 5, col: 10)

      assert_equal 5, @floating.row
      assert_equal 10, @floating.col
    end

    def test_show_normalizes_string_content
      @floating.show("Line 1\nLine 2\nLine 3", row: 0, col: 0)

      assert_equal ["Line 1", "Line 2", "Line 3"], @floating.content
    end

    def test_show_normalizes_array_content
      @floating.show(["Line 1", "Line 2"], row: 0, col: 0)

      assert_equal ["Line 1", "Line 2"], @floating.content
    end

    def test_show_handles_mixed_newlines_in_array
      @floating.show(["Line 1\nLine 2", "Line 3"], row: 0, col: 0)

      assert_equal ["Line 1", "Line 2", "Line 3"], @floating.content
    end

    def test_show_calculates_dimensions
      @floating.show("Hello", row: 0, col: 0)

      # width = content_width(5) + 2 (border) = 7
      assert_equal 7, @floating.width
      # height = content_height(1) + 2 (border) = 3
      assert_equal 3, @floating.height
    end

    def test_show_respects_max_width
      @floating.show("This is a very long line of text", row: 0, col: 0, max_width: 20)

      assert @floating.width <= 20
    end

    def test_show_respects_max_height
      content = (1..20).map { |i| "Line #{i}" }
      @floating.show(content, row: 0, col: 0, max_height: 10)

      assert @floating.height <= 10
    end
  end

  class TestHide < TestFloatingWindow
    def test_hide_makes_invisible
      @floating.show("Hello", row: 5, col: 10)
      @floating.hide

      refute @floating.visible
    end

    def test_hide_clears_content
      @floating.show("Hello", row: 5, col: 10)
      @floating.hide

      assert_empty @floating.content
    end
  end

  class TestScroll < TestFloatingWindow
    def test_scroll_up_decreases_offset
      content = (1..20).map { |i| "Line #{i}" }
      @floating.show(content, row: 0, col: 0, max_height: 5)

      # First scroll down to have something to scroll up from
      @floating.scroll_down
      @floating.scroll_down

      initial_scroll = @floating.instance_variable_get(:@scroll_offset)
      @floating.scroll_up

      assert_equal initial_scroll - 1, @floating.instance_variable_get(:@scroll_offset)
    end

    def test_scroll_up_stops_at_zero
      @floating.show("Line 1\nLine 2", row: 0, col: 0)

      5.times { @floating.scroll_up }

      assert_equal 0, @floating.instance_variable_get(:@scroll_offset)
    end

    def test_scroll_down_increases_offset
      content = (1..20).map { |i| "Line #{i}" }
      @floating.show(content, row: 0, col: 0, max_height: 5)

      @floating.scroll_down

      assert_equal 1, @floating.instance_variable_get(:@scroll_offset)
    end

    def test_scroll_ignored_when_not_visible
      @floating.scroll_down

      assert_equal 0, @floating.instance_variable_get(:@scroll_offset)
    end
  end

  class TestRender < TestFloatingWindow
    def test_render_does_nothing_when_not_visible
      screen = MockScreen.new
      @floating.render(screen)

      assert_empty screen.output
    end

    def test_render_does_nothing_with_empty_content
      screen = MockScreen.new
      @floating.show("", row: 5, col: 10)
      @floating.render(screen)

      # Empty string normalizes to empty array
      assert_empty screen.output
    end

    def test_render_draws_border_and_content
      screen = MockScreen.new
      @floating.show("Hello", row: 5, col: 10)
      @floating.render(screen)

      # Should have: top border, content line with side borders, bottom border
      refute_empty screen.output

      # Check for border characters
      assert(screen.output.any? { |s| s.include?("┌") })
      assert(screen.output.any? { |s| s.include?("└") })
      assert(screen.output.any? { |s| s.include?("│") })
    end

    def test_render_adjusts_position_for_right_edge
      screen = MockScreen.new(width: 80, height: 24)
      @floating.show("Hello World", row: 5, col: 75)
      @floating.render(screen)

      # All positions should be within screen bounds
      assert(screen.positions.all? { |_row, col| col < 80 })
    end

    def test_render_adjusts_position_for_bottom_edge
      screen = MockScreen.new(width: 80, height: 24)
      content = (1..10).map { |i| "Line #{i}" }
      @floating.show(content, row: 20, col: 5)
      @floating.render(screen)

      # All positions should be within screen bounds
      assert(screen.positions.all? { |row, _col| row < 24 })
    end
  end

  class TestClearBounds < TestFloatingWindow
    def test_hide_sets_needs_clear_flag
      @floating.show("Hello", row: 5, col: 10)
      @floating.hide

      assert @floating.needs_clear?
    end

    def test_hide_records_last_bounds
      @floating.show("Hello", row: 5, col: 10)
      @floating.hide

      assert_equal 5, @floating.last_bounds[:row]
      assert_equal 10, @floating.last_bounds[:col]
      assert_equal 7, @floating.last_bounds[:width]   # "Hello" + 2 (border)
      assert_equal 3, @floating.last_bounds[:height]  # 1 line + 2 (border)
    end

    def test_needs_clear_returns_false_when_not_hidden
      @floating.show("Hello", row: 5, col: 10)

      refute @floating.needs_clear?
    end

    def test_needs_clear_returns_false_after_clearing
      screen = MockScreen.new
      @floating.show("Hello", row: 5, col: 10)
      @floating.hide
      @floating.clear_last_bounds(screen)

      refute @floating.needs_clear?
    end

    def test_clear_last_bounds_resets_last_bounds
      screen = MockScreen.new
      @floating.show("Hello", row: 5, col: 10)
      @floating.hide
      @floating.clear_last_bounds(screen)

      assert_nil @floating.last_bounds
    end

    def test_clear_last_bounds_fills_area_with_spaces
      screen = MockScreen.new
      @floating.show("Hi", row: 5, col: 10)
      @floating.hide
      @floating.clear_last_bounds(screen)

      # Should have output spaces to clear the area
      assert(screen.output.any? { |s| s.match?(/^\s+$/) })
    end

    def test_hide_when_not_visible_does_nothing
      @floating.hide

      refute @floating.needs_clear?
      assert_nil @floating.last_bounds
    end

    def test_show_clears_needs_clear_flag
      @floating.show("Hello", row: 5, col: 10)
      @floating.hide
      @floating.show("World", row: 10, col: 20)

      refute @floating.needs_clear?
    end

    def test_clear_last_bounds_adjusts_position_for_screen_edge
      screen = MockScreen.new(width: 80, height: 24)
      @floating.show("Hello", row: 5, col: 78) # Near right edge
      @floating.hide
      @floating.clear_last_bounds(screen)

      # All positions should be within screen bounds
      assert(screen.positions.all? { |_row, col| col < 80 })
    end
  end
end
