# frozen_string_literal: true

require "test_helper"

class TestSelectionHighlighter < Minitest::Test
  def setup
    @color_scheme = { visual_selection: { fg: :black, bg: :white } }
    @highlighter = Mui::Highlighters::SelectionHighlighter.new(@color_scheme)
  end

  class TestInitialize < TestSelectionHighlighter
    def test_initializes_with_color_scheme
      highlighter = Mui::Highlighters::SelectionHighlighter.new(@color_scheme)

      assert_instance_of Mui::Highlighters::SelectionHighlighter, highlighter
    end
  end

  class TestPriority < TestSelectionHighlighter
    def test_returns_priority_selection
      assert_equal Mui::Highlighters::Base::PRIORITY_SELECTION, @highlighter.priority
    end
  end

  class TestHighlightsFor < TestSelectionHighlighter
    def test_returns_empty_array_without_selection
      highlights = @highlighter.highlights_for(0, "test line", {})

      assert_empty highlights
    end

    def test_returns_empty_array_with_nil_selection
      highlights = @highlighter.highlights_for(0, "test line", selection: nil)

      assert_empty highlights
    end

    def test_returns_empty_array_when_row_before_selection
      selection = Mui::Selection.new(5, 0)
      selection.update_end(7, 10)

      highlights = @highlighter.highlights_for(2, "test line", selection:)

      assert_empty highlights
    end

    def test_returns_empty_array_when_row_after_selection
      selection = Mui::Selection.new(0, 0)
      selection.update_end(2, 10)

      highlights = @highlighter.highlights_for(5, "test line", selection:)

      assert_empty highlights
    end

    def test_returns_highlight_for_single_line_selection
      selection = Mui::Selection.new(0, 2)
      selection.update_end(0, 5)

      highlights = @highlighter.highlights_for(0, "test line", selection:)

      assert_equal 1, highlights.size
      assert_equal 2, highlights[0].start_col
      assert_equal 5, highlights[0].end_col
    end

    def test_returns_highlight_for_start_row_of_multiline
      selection = Mui::Selection.new(0, 5)
      selection.update_end(2, 3)

      highlights = @highlighter.highlights_for(0, "test line", selection:)

      assert_equal 1, highlights.size
      assert_equal 5, highlights[0].start_col
      # End col should be end of line
      assert highlights[0].end_col >= 5
    end

    def test_returns_highlight_for_middle_row_of_multiline
      selection = Mui::Selection.new(0, 5)
      selection.update_end(2, 3)

      highlights = @highlighter.highlights_for(1, "middle line", selection:)

      assert_equal 1, highlights.size
      assert_equal 0, highlights[0].start_col
    end

    def test_returns_highlight_for_end_row_of_multiline
      selection = Mui::Selection.new(0, 5)
      selection.update_end(2, 3)

      highlights = @highlighter.highlights_for(2, "end line", selection:)

      assert_equal 1, highlights.size
      assert_equal 0, highlights[0].start_col
      assert_equal 3, highlights[0].end_col
    end

    def test_highlight_has_visual_selection_style
      selection = Mui::Selection.new(0, 0)
      selection.update_end(0, 5)

      highlights = @highlighter.highlights_for(0, "test line", selection:)

      assert_equal :visual_selection, highlights[0].style
    end

    def test_highlight_has_correct_priority
      selection = Mui::Selection.new(0, 0)
      selection.update_end(0, 5)

      highlights = @highlighter.highlights_for(0, "test line", selection:)

      assert_equal Mui::Highlighters::Base::PRIORITY_SELECTION, highlights[0].priority
    end
  end

  class TestLineModeHighlights < TestSelectionHighlighter
    def test_highlights_full_line_in_line_mode
      selection = Mui::Selection.new(0, 0, line_mode: true)
      selection.update_end(2, 0)

      highlights = @highlighter.highlights_for(1, "middle line", selection:)

      assert_equal 1, highlights.size
      assert_equal 0, highlights[0].start_col
      assert_equal 10, highlights[0].end_col # "middle line".length - 1
    end

    def test_handles_empty_line_in_line_mode
      selection = Mui::Selection.new(0, 0, line_mode: true)
      selection.update_end(2, 0)

      highlights = @highlighter.highlights_for(1, "", selection:)

      assert_equal 1, highlights.size
      assert_equal 0, highlights[0].start_col
      assert_equal 0, highlights[0].end_col
    end
  end

  class TestCharModeHighlights < TestSelectionHighlighter
    def test_highlights_partial_line_in_char_mode
      selection = Mui::Selection.new(0, 3)
      selection.update_end(0, 7)

      highlights = @highlighter.highlights_for(0, "test line", selection:)

      assert_equal 1, highlights.size
      assert_equal 3, highlights[0].start_col
      assert_equal 7, highlights[0].end_col
    end

    def test_handles_reversed_selection
      selection = Mui::Selection.new(0, 7)
      selection.update_end(0, 3)

      highlights = @highlighter.highlights_for(0, "test line", selection:)

      assert_equal 1, highlights.size
      assert_equal 3, highlights[0].start_col
      assert_equal 7, highlights[0].end_col
    end
  end
end
