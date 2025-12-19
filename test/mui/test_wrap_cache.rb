# frozen_string_literal: true

require "test_helper"

class TestWrapCache < Minitest::Test
  def setup
    @cache = Mui::WrapCache.new
  end

  def test_get_returns_nil_for_empty_cache
    line = "test"

    assert_nil @cache.get(line, 80)
  end

  def test_set_and_get
    line = "test line"
    result = [{ text: "test line", start_col: 0, end_col: 9 }]

    @cache.set(line, 80, result)

    assert_equal result, @cache.get(line, 80)
  end

  def test_get_returns_nil_for_different_width
    line = "test line"
    result = [{ text: "test line", start_col: 0, end_col: 9 }]

    @cache.set(line, 80, result)

    assert_nil @cache.get(line, 40)
  end

  def test_get_returns_nil_for_different_line
    line1 = "first line"
    line2 = "second line"
    result = [{ text: "first line", start_col: 0, end_col: 10 }]

    @cache.set(line1, 80, result)

    assert_nil @cache.get(line2, 80)
  end

  def test_multiple_widths_for_same_line
    line = "test line"
    result80 = [{ text: "test line", start_col: 0, end_col: 9 }]
    result40 = [{ text: "test", start_col: 0, end_col: 4 }, { text: " line", start_col: 4, end_col: 9 }]

    @cache.set(line, 80, result80)
    @cache.set(line, 40, result40)

    assert_equal result80, @cache.get(line, 80)
    assert_equal result40, @cache.get(line, 40)
  end

  def test_invalidate_removes_line_cache
    line = "test line"
    result = [{ text: "test line", start_col: 0, end_col: 9 }]

    @cache.set(line, 80, result)
    @cache.set(line, 40, result)
    @cache.invalidate(line)

    assert_nil @cache.get(line, 80)
    assert_nil @cache.get(line, 40)
  end

  def test_invalidate_does_not_affect_other_lines
    line1 = "first line"
    line2 = "second line"
    result1 = [{ text: "first line", start_col: 0, end_col: 10 }]
    result2 = [{ text: "second line", start_col: 0, end_col: 11 }]

    @cache.set(line1, 80, result1)
    @cache.set(line2, 80, result2)
    @cache.invalidate(line1)

    assert_nil @cache.get(line1, 80)
    assert_equal result2, @cache.get(line2, 80)
  end

  def test_clear_removes_all_cache
    line1 = "first line"
    line2 = "second line"
    result1 = [{ text: "first line", start_col: 0, end_col: 10 }]
    result2 = [{ text: "second line", start_col: 0, end_col: 11 }]

    @cache.set(line1, 80, result1)
    @cache.set(line2, 80, result2)
    @cache.clear

    assert_nil @cache.get(line1, 80)
    assert_nil @cache.get(line2, 80)
  end

  def test_size_returns_number_of_cache_entries
    line1 = "first"
    line2 = "second"

    assert_equal 0, @cache.size

    @cache.set(line1, 80, [])

    assert_equal 1, @cache.size

    # Same line, different width - separate cache entry
    @cache.set(line1, 40, [])

    assert_equal 2, @cache.size

    @cache.set(line2, 80, [])

    assert_equal 3, @cache.size
  end

  def test_same_content_different_string_objects_share_cache
    line1 = "test content"
    line2 = "test content".dup # Different String object, same content
    result = [{ text: "test content", start_col: 0, end_col: 12 }]

    @cache.set(line1, 80, result)

    # Should hit cache because content is the same
    assert_equal result, @cache.get(line2, 80)
  end

  def test_mutated_string_does_not_use_stale_cache
    line = String.new("hello")
    result_hello = [{ text: "hello", start_col: 0, end_col: 5 }]

    @cache.set(line, 80, result_hello)

    assert_equal result_hello, @cache.get(line, 80)

    # Mutate the string
    line << " world"

    # Should not hit old cache
    assert_nil @cache.get(line, 80)
  end
end
