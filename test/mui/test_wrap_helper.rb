# frozen_string_literal: true

require "test_helper"

class TestWrapHelper < Minitest::Test
  def test_wrap_line_nil
    result = Mui::WrapHelper.wrap_line(nil, 80)

    assert_equal [{ text: "", start_col: 0, end_col: 0 }], result
  end

  def test_wrap_line_empty
    result = Mui::WrapHelper.wrap_line("", 80)

    assert_equal [{ text: "", start_col: 0, end_col: 0 }], result
  end

  def test_wrap_line_short_ascii
    result = Mui::WrapHelper.wrap_line("hello", 80)

    assert_equal [{ text: "hello", start_col: 0, end_col: 5 }], result
  end

  def test_wrap_line_exact_width
    result = Mui::WrapHelper.wrap_line("12345", 5)

    assert_equal [{ text: "12345", start_col: 0, end_col: 5 }], result
  end

  def test_wrap_line_ascii_wrap
    result = Mui::WrapHelper.wrap_line("1234567890", 5)

    assert_equal 2, result.size
    assert_equal({ text: "12345", start_col: 0, end_col: 5 }, result[0])
    assert_equal({ text: "67890", start_col: 5, end_col: 10 }, result[1])
  end

  def test_wrap_line_ascii_multiple_wraps
    result = Mui::WrapHelper.wrap_line("123456789012345", 5)

    assert_equal 3, result.size
    assert_equal({ text: "12345", start_col: 0, end_col: 5 }, result[0])
    assert_equal({ text: "67890", start_col: 5, end_col: 10 }, result[1])
    assert_equal({ text: "12345", start_col: 10, end_col: 15 }, result[2])
  end

  def test_wrap_line_japanese
    # Japanese characters are 2 width each
    result = Mui::WrapHelper.wrap_line("あいう", 4)

    assert_equal 2, result.size
    assert_equal({ text: "あい", start_col: 0, end_col: 2 }, result[0])
    assert_equal({ text: "う", start_col: 2, end_col: 3 }, result[1])
  end

  def test_wrap_line_japanese_exact
    result = Mui::WrapHelper.wrap_line("あい", 4)

    assert_equal [{ text: "あい", start_col: 0, end_col: 2 }], result
  end

  def test_wrap_line_mixed_width
    # "aあb" = 1 + 2 + 1 = 4 width
    # At width 3: "aあ" (1+2=3) fits, then "b" wraps
    result = Mui::WrapHelper.wrap_line("aあb", 3)

    assert_equal 2, result.size
    assert_equal({ text: "aあ", start_col: 0, end_col: 2 }, result[0])
    assert_equal({ text: "b", start_col: 2, end_col: 3 }, result[1])
  end

  def test_wrap_line_wide_char_at_boundary
    # Width 3, "aあ" = 1 + 2 = 3, but "あ" doesn't fit after "a" at width 2
    result = Mui::WrapHelper.wrap_line("aあ", 2)

    assert_equal 2, result.size
    assert_equal({ text: "a", start_col: 0, end_col: 1 }, result[0])
    assert_equal({ text: "あ", start_col: 1, end_col: 2 }, result[1])
  end

  def test_wrap_line_zero_width
    result = Mui::WrapHelper.wrap_line("hello", 0)

    assert_equal [{ text: "hello", start_col: 0, end_col: 5 }], result
  end

  def test_wrap_line_negative_width
    result = Mui::WrapHelper.wrap_line("hello", -1)

    assert_equal [{ text: "hello", start_col: 0, end_col: 5 }], result
  end

  # logical_to_screen tests
  def test_logical_to_screen_nil
    row, col = Mui::WrapHelper.logical_to_screen(nil, 0, 80)

    assert_equal 0, row
    assert_equal 0, col
  end

  def test_logical_to_screen_empty
    row, col = Mui::WrapHelper.logical_to_screen("", 0, 80)

    assert_equal 0, row
    assert_equal 0, col
  end

  def test_logical_to_screen_no_wrap
    row, col = Mui::WrapHelper.logical_to_screen("hello", 2, 80)

    assert_equal 0, row
    assert_equal 2, col
  end

  def test_logical_to_screen_with_wrap_first_line
    row, col = Mui::WrapHelper.logical_to_screen("1234567890", 3, 5)

    assert_equal 0, row
    assert_equal 3, col
  end

  def test_logical_to_screen_with_wrap_second_line
    row, col = Mui::WrapHelper.logical_to_screen("1234567890", 7, 5)

    assert_equal 1, row
    assert_equal 2, col # 7 - 5 = 2 (position in second line)
  end

  def test_logical_to_screen_japanese
    # "あいう" at col 1 (after first char)
    row, col = Mui::WrapHelper.logical_to_screen("あいう", 1, 4)
    # First line is "あい" (cols 0-2)
    assert_equal 0, row
    assert_equal 2, col # "あ" = 2 width
  end

  def test_logical_to_screen_japanese_wrapped
    # "あいう" at col 2 (after "あい"), width 4
    # Wraps to: ["あい" (0-2), "う" (2-3)]
    row, col = Mui::WrapHelper.logical_to_screen("あいう", 2, 4)

    assert_equal 0, row
    assert_equal 4, col # "あい" = 4 width
  end

  def test_logical_to_screen_at_wrap_boundary
    row, col = Mui::WrapHelper.logical_to_screen("1234567890", 5, 5)

    assert_equal 0, row
    assert_equal 5, col
  end

  def test_logical_to_screen_past_end
    row, col = Mui::WrapHelper.logical_to_screen("hello", 10, 80)

    assert_equal 0, row
    assert_equal 5, col # at end of string
  end

  # screen_line_count tests
  def test_screen_line_count_nil
    assert_equal 1, Mui::WrapHelper.screen_line_count(nil, 80)
  end

  def test_screen_line_count_empty
    assert_equal 1, Mui::WrapHelper.screen_line_count("", 80)
  end

  def test_screen_line_count_no_wrap
    assert_equal 1, Mui::WrapHelper.screen_line_count("hello", 80)
  end

  def test_screen_line_count_single_wrap
    assert_equal 2, Mui::WrapHelper.screen_line_count("1234567890", 5)
  end

  def test_screen_line_count_multiple_wraps
    assert_equal 3, Mui::WrapHelper.screen_line_count("123456789012345", 5)
  end

  def test_screen_line_count_japanese
    assert_equal 2, Mui::WrapHelper.screen_line_count("あいう", 4)
  end

  # Cache tests
  def test_wrap_line_uses_cache
    cache = Mui::WrapCache.new
    line = "hello world"

    # First call should compute and cache
    result1 = Mui::WrapHelper.wrap_line(line, 5, cache:)

    assert_equal 1, cache.size

    # Second call should use cache
    result2 = Mui::WrapHelper.wrap_line(line, 5, cache:)

    assert_equal result1, result2
    assert_equal 1, cache.size
  end

  def test_wrap_line_different_widths_cached_separately
    cache = Mui::WrapCache.new
    line = "hello world"

    Mui::WrapHelper.wrap_line(line, 5, cache:)
    Mui::WrapHelper.wrap_line(line, 10, cache:)

    # Same line content with different widths creates separate cache entries
    assert_equal 2, cache.size
  end
end
