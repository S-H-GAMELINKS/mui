# frozen_string_literal: true

require "test_helper"

class TestSearchState < Minitest::Test
  def setup
    @search_state = Mui::SearchState.new
    @buffer = Mui::Buffer.new
  end

  def test_initial_state
    assert_nil @search_state.pattern
    assert_equal :forward, @search_state.direction
    refute_predicate @search_state, :has_pattern?
  end

  def test_set_pattern
    @search_state.set_pattern("test", :forward)

    assert_equal "test", @search_state.pattern
    assert_equal :forward, @search_state.direction
    assert_predicate @search_state, :has_pattern?
  end

  def test_set_pattern_backward
    @search_state.set_pattern("hello", :backward)

    assert_equal "hello", @search_state.pattern
    assert_equal :backward, @search_state.direction
  end

  def test_clear
    @search_state.set_pattern("test", :forward)
    @search_state.clear

    assert_nil @search_state.pattern
    refute_predicate @search_state, :has_pattern?
  end

  def test_find_all_matches_simple
    @buffer.lines[0] = "hello world hello"
    @search_state.set_pattern("hello", :forward)
    matches = @search_state.find_all_matches(@buffer)

    assert_equal 2, matches.length
    assert_equal({ row: 0, col: 0, end_col: 4 }, matches[0])
    assert_equal({ row: 0, col: 12, end_col: 16 }, matches[1])
  end

  def test_find_all_matches_multiple_lines
    @buffer.lines[0] = "foo bar"
    @buffer.lines[1] = "bar baz"
    @buffer.lines[2] = "bar foo"
    @search_state.set_pattern("bar", :forward)
    matches = @search_state.find_all_matches(@buffer)

    assert_equal 3, matches.length
    assert_equal({ row: 0, col: 4, end_col: 6 }, matches[0])
    assert_equal({ row: 1, col: 0, end_col: 2 }, matches[1])
    assert_equal({ row: 2, col: 0, end_col: 2 }, matches[2])
  end

  def test_find_all_matches_regex
    buffer = Mui::Buffer.new
    buffer.lines[0] = "foo123bar456"
    @search_state.set_pattern("\\d+", :forward)
    matches = @search_state.find_all_matches(buffer)

    assert_equal 2, matches.length
    assert_equal({ row: 0, col: 3, end_col: 5 }, matches[0])
    assert_equal({ row: 0, col: 9, end_col: 11 }, matches[1])
  end

  def test_find_all_matches_invalid_regex
    @buffer.lines[0] = "test"
    @search_state.set_pattern("[invalid", :forward)
    matches = @search_state.find_all_matches(@buffer)

    assert_empty matches
  end

  def test_find_all_matches_empty_pattern
    @buffer.lines[0] = "test"
    @search_state.set_pattern("", :forward)
    matches = @search_state.find_all_matches(@buffer)

    assert_empty matches
  end

  def test_find_next_basic
    @buffer.lines[0] = "foo foo foo"
    @search_state.set_pattern("foo", :forward)

    match = @search_state.find_next(0, 0, buffer: @buffer)

    assert_equal({ row: 0, col: 4, end_col: 6 }, match)
  end

  def test_find_next_wrap_around
    @buffer.lines[0] = "foo bar"
    @buffer.lines[1] = "baz"
    @search_state.set_pattern("foo", :forward)

    # Current position is after the only match, should wrap to first match
    match = @search_state.find_next(1, 0, buffer: @buffer)

    assert_equal({ row: 0, col: 0, end_col: 2 }, match)
  end

  def test_find_previous_basic
    @buffer.lines[0] = "foo foo foo"
    @search_state.set_pattern("foo", :forward)

    match = @search_state.find_previous(0, 10, buffer: @buffer)

    assert_equal({ row: 0, col: 8, end_col: 10 }, match)
  end

  def test_find_previous_wrap_around
    @buffer.lines[0] = "baz"
    @buffer.lines[1] = "foo bar"
    @search_state.set_pattern("foo", :forward)

    # Current position is before the only match, should wrap to last match
    match = @search_state.find_previous(0, 0, buffer: @buffer)

    assert_equal({ row: 1, col: 0, end_col: 2 }, match)
  end

  def test_find_next_no_matches
    @buffer.lines[0] = "hello"
    @search_state.set_pattern("xyz", :forward)

    match = @search_state.find_next(0, 0, buffer: @buffer)

    assert_nil match
  end

  def test_find_previous_no_matches
    @buffer.lines[0] = "hello"
    @search_state.set_pattern("xyz", :forward)

    match = @search_state.find_previous(0, 0, buffer: @buffer)

    assert_nil match
  end

  def test_matches_for_row
    @buffer.lines[0] = "foo bar"
    @buffer.lines[1] = "foo baz foo"
    @search_state.set_pattern("foo", :forward)

    row0_matches = @search_state.matches_for_row(0, buffer: @buffer)

    assert_equal 1, row0_matches.length

    row1_matches = @search_state.matches_for_row(1, buffer: @buffer)

    assert_equal 2, row1_matches.length

    row2_matches = @search_state.matches_for_row(2, buffer: @buffer)

    assert_empty row2_matches
  end

  def test_per_buffer_match_caching
    buffer1 = Mui::Buffer.new
    buffer1.lines[0] = "hello world"
    buffer2 = Mui::Buffer.new
    buffer2.lines[0] = "hello hello"

    @search_state.set_pattern("hello", :forward)

    # Get matches for buffer1
    matches1 = @search_state.find_all_matches(buffer1)

    assert_equal 1, matches1.length

    # Get matches for buffer2 (should be different)
    matches2 = @search_state.find_all_matches(buffer2)

    assert_equal 2, matches2.length

    # Verify buffer1 matches are still cached correctly
    matches1_again = @search_state.find_all_matches(buffer1)

    assert_equal 1, matches1_again.length
  end

  def test_pattern_change_invalidates_cache
    @buffer.lines[0] = "hello world"
    @search_state.set_pattern("hello", :forward)
    matches1 = @search_state.find_all_matches(@buffer)

    assert_equal 1, matches1.length

    # Change pattern
    @search_state.set_pattern("world", :forward)
    matches2 = @search_state.find_all_matches(@buffer)

    assert_equal 1, matches2.length
    assert_equal 6, matches2[0][:col] # "world" starts at col 6
  end

  def test_buffer_content_change_recalculates
    @buffer.lines[0] = "hello"
    @search_state.set_pattern("hello", :forward)
    matches1 = @search_state.find_all_matches(@buffer)

    assert_equal 1, matches1.length

    # Modify buffer content (this increments change_count)
    @buffer.replace_line(0, "hello hello")
    matches2 = @search_state.find_all_matches(@buffer)

    assert_equal 2, matches2.length
  end
end
