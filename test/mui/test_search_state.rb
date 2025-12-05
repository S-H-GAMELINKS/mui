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
    assert_empty @search_state.matches
    refute @search_state.has_pattern?
  end

  def test_set_pattern
    @search_state.set_pattern("test", :forward)
    assert_equal "test", @search_state.pattern
    assert_equal :forward, @search_state.direction
    assert @search_state.has_pattern?
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
    assert_empty @search_state.matches
    refute @search_state.has_pattern?
  end

  def test_find_all_matches_simple
    @buffer.lines[0] = "hello world hello"
    @search_state.set_pattern("hello", :forward)
    @search_state.find_all_matches(@buffer)

    assert_equal 2, @search_state.matches.length
    assert_equal({ row: 0, col: 0, end_col: 4 }, @search_state.matches[0])
    assert_equal({ row: 0, col: 12, end_col: 16 }, @search_state.matches[1])
  end

  def test_find_all_matches_multiple_lines
    @buffer.lines[0] = "foo bar"
    @buffer.lines[1] = "bar baz"
    @buffer.lines[2] = "bar foo"
    @search_state.set_pattern("bar", :forward)
    @search_state.find_all_matches(@buffer)

    assert_equal 3, @search_state.matches.length
    assert_equal({ row: 0, col: 4, end_col: 6 }, @search_state.matches[0])
    assert_equal({ row: 1, col: 0, end_col: 2 }, @search_state.matches[1])
    assert_equal({ row: 2, col: 0, end_col: 2 }, @search_state.matches[2])
  end

  def test_find_all_matches_regex
    buffer = Mui::Buffer.new
    buffer.lines[0] = "foo123bar456"
    @search_state.set_pattern("\\d+", :forward)
    @search_state.find_all_matches(buffer)

    assert_equal 2, @search_state.matches.length
    assert_equal({ row: 0, col: 3, end_col: 5 }, @search_state.matches[0])
    assert_equal({ row: 0, col: 9, end_col: 11 }, @search_state.matches[1])
  end

  def test_find_all_matches_invalid_regex
    @buffer.lines[0] = "test"
    @search_state.set_pattern("[invalid", :forward)
    @search_state.find_all_matches(@buffer)

    assert_empty @search_state.matches
  end

  def test_find_all_matches_empty_pattern
    @buffer.lines[0] = "test"
    @search_state.set_pattern("", :forward)
    @search_state.find_all_matches(@buffer)

    assert_empty @search_state.matches
  end

  def test_find_next_basic
    @buffer.lines[0] = "foo foo foo"
    @search_state.set_pattern("foo", :forward)
    @search_state.find_all_matches(@buffer)

    match = @search_state.find_next(0, 0)
    assert_equal({ row: 0, col: 4, end_col: 6 }, match)
  end

  def test_find_next_wrap_around
    @buffer.lines[0] = "foo bar"
    @buffer.lines[1] = "baz"
    @search_state.set_pattern("foo", :forward)
    @search_state.find_all_matches(@buffer)

    # Current position is after the only match, should wrap to first match
    match = @search_state.find_next(1, 0)
    assert_equal({ row: 0, col: 0, end_col: 2 }, match)
  end

  def test_find_previous_basic
    @buffer.lines[0] = "foo foo foo"
    @search_state.set_pattern("foo", :forward)
    @search_state.find_all_matches(@buffer)

    match = @search_state.find_previous(0, 10)
    assert_equal({ row: 0, col: 8, end_col: 10 }, match)
  end

  def test_find_previous_wrap_around
    @buffer.lines[0] = "baz"
    @buffer.lines[1] = "foo bar"
    @search_state.set_pattern("foo", :forward)
    @search_state.find_all_matches(@buffer)

    # Current position is before the only match, should wrap to last match
    match = @search_state.find_previous(0, 0)
    assert_equal({ row: 1, col: 0, end_col: 2 }, match)
  end

  def test_find_next_no_matches
    @buffer.lines[0] = "hello"
    @search_state.set_pattern("xyz", :forward)
    @search_state.find_all_matches(@buffer)

    match = @search_state.find_next(0, 0)
    assert_nil match
  end

  def test_find_previous_no_matches
    @buffer.lines[0] = "hello"
    @search_state.set_pattern("xyz", :forward)
    @search_state.find_all_matches(@buffer)

    match = @search_state.find_previous(0, 0)
    assert_nil match
  end

  def test_matches_for_row
    @buffer.lines[0] = "foo bar"
    @buffer.lines[1] = "foo baz foo"
    @search_state.set_pattern("foo", :forward)
    @search_state.find_all_matches(@buffer)

    row0_matches = @search_state.matches_for_row(0)
    assert_equal 1, row0_matches.length

    row1_matches = @search_state.matches_for_row(1)
    assert_equal 2, row1_matches.length

    row2_matches = @search_state.matches_for_row(2)
    assert_empty row2_matches
  end
end
