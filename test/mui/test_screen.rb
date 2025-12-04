# frozen_string_literal: true

require "test_helper"

class TestScreen < Minitest::Test
  include MuiTestHelper

  def setup
    @screen = Mui::Screen.new(adapter: test_adapter)
  end

  def teardown
    @screen = nil
  end

  def test_put_returns_early_for_negative_y
    result = @screen.put(-1, 0, "test")
    refute result
  end

  def test_put_returns_early_for_y_beyond_height
    result = @screen.put(24, 0, "test")
    refute result

    result = @screen.put(100, 0, "test")
    refute result
  end

  def test_put_returns_early_for_x_beyond_width
    result = @screen.put(80, 0, "test")
    refute result

    result = @screen.put(100, 0, "test")
    refute result
  end

  def test_put_truncates_text_at_screen_edge
    result = @screen.put(0, 75, "Hello World")

    assert_equal "Hello", result
  end

  def test_put_does_not_truncate_when_fits
    result = @screen.put(0, 0, "Hello")

    assert_equal "Hello", result
  end

  def test_move_cursor_clamps_negative_x
    result = @screen.move_cursor(10, -5)

    assert_equal [10, 0], result
  end

  def test_move_cursor_clamps_negative_y
    result = @screen.move_cursor(-5, 10)

    assert_equal [0, 10], result
  end

  def test_move_cursor_clamps_x_beyond_width
    result = @screen.move_cursor(10, 100)

    assert_equal [10, 79], result
  end

  def test_move_cursor_clamps_y_beyond_height
    result = @screen.move_cursor(100, 10)

    assert_equal [23, 10], result
  end

  def test_move_cursor_valid_position
    result = @screen.move_cursor(12, 40)

    assert_equal [12, 40], result
  end
end
