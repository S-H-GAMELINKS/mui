# frozen_string_literal: true

require "test_helper"

class TestSearchHighlighter < Minitest::Test
  def setup
    @color_scheme = { search_highlight: { fg: :black, bg: :yellow } }
    @highlighter = Mui::Highlighters::SearchHighlighter.new(@color_scheme)
  end

  class TestInitialize < TestSearchHighlighter
    def test_initializes_with_color_scheme
      highlighter = Mui::Highlighters::SearchHighlighter.new(@color_scheme)

      assert_instance_of Mui::Highlighters::SearchHighlighter, highlighter
    end
  end

  class TestPriority < TestSearchHighlighter
    def test_returns_priority_search
      assert_equal Mui::Highlighters::Base::PRIORITY_SEARCH, @highlighter.priority
    end
  end

  class TestHighlightsFor < TestSearchHighlighter
    def test_returns_empty_array_without_search_state
      highlights = @highlighter.highlights_for(0, "test line", {})

      assert_empty highlights
    end

    def test_returns_empty_array_with_nil_search_state
      highlights = @highlighter.highlights_for(0, "test line", search_state: nil)

      assert_empty highlights
    end

    def test_returns_empty_array_when_no_pattern
      search_state = MockSearchState.new(has_pattern: false, matches: [])

      highlights = @highlighter.highlights_for(0, "test line", search_state:)

      assert_empty highlights
    end

    def test_returns_highlights_for_matches
      matches = [{ col: 0, end_col: 3 }]
      search_state = MockSearchState.new(has_pattern: true, matches:)

      highlights = @highlighter.highlights_for(0, "test line", search_state:)

      assert_equal 1, highlights.size
      assert_instance_of Mui::Highlight, highlights[0]
    end

    def test_highlight_has_correct_positions
      matches = [{ col: 5, end_col: 8 }]
      search_state = MockSearchState.new(has_pattern: true, matches:)

      highlights = @highlighter.highlights_for(0, "hello test world", search_state:)

      assert_equal 5, highlights[0].start_col
      assert_equal 8, highlights[0].end_col
    end

    def test_highlight_has_search_highlight_style
      matches = [{ col: 0, end_col: 3 }]
      search_state = MockSearchState.new(has_pattern: true, matches:)

      highlights = @highlighter.highlights_for(0, "test", search_state:)

      assert_equal :search_highlight, highlights[0].style
    end

    def test_highlight_has_correct_priority
      matches = [{ col: 0, end_col: 3 }]
      search_state = MockSearchState.new(has_pattern: true, matches:)

      highlights = @highlighter.highlights_for(0, "test", search_state:)

      assert_equal Mui::Highlighters::Base::PRIORITY_SEARCH, highlights[0].priority
    end

    def test_returns_multiple_highlights_for_multiple_matches
      matches = [{ col: 0, end_col: 3 }, { col: 10, end_col: 13 }]
      search_state = MockSearchState.new(has_pattern: true, matches:)

      highlights = @highlighter.highlights_for(0, "test hello test", search_state:)

      assert_equal 2, highlights.size
    end
  end
end

# Mock SearchState for testing
class MockSearchState
  def initialize(has_pattern:, matches:)
    @has_pattern = has_pattern
    @matches = matches
  end

  def pattern?
    @has_pattern
  end

  alias has_pattern? pattern?

  def matches_for_row(_row)
    @matches
  end
end
