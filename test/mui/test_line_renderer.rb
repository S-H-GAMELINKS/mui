# frozen_string_literal: true

require "test_helper"

class TestLineRenderer < Minitest::Test
  def setup
    @adapter = Mui::TerminalAdapter::Test.new(width: 80, height: 24)
    @screen = Mui::Screen.new(adapter: @adapter)
    @color_scheme = nil
    @renderer = Mui::LineRenderer.new(@color_scheme)
  end

  class TestInitialize < TestLineRenderer
    def test_initializes_with_color_scheme
      color_scheme = { normal: { fg: :white, bg: :black } }
      renderer = Mui::LineRenderer.new(color_scheme)

      assert_instance_of Mui::LineRenderer, renderer
    end

    def test_initializes_with_nil_color_scheme
      renderer = Mui::LineRenderer.new(nil)

      assert_instance_of Mui::LineRenderer, renderer
    end
  end

  class TestAddHighlighter < TestLineRenderer
    def test_adds_highlighter
      highlighter = MockHighlighter.new([])
      @renderer.add_highlighter(highlighter)

      # Render should use the highlighter
      @renderer.render(@screen, "test", 0, 0, 0)
      assert highlighter.called
    end
  end

  class TestRender < TestLineRenderer
    def test_renders_simple_line_without_highlights
      @renderer.render(@screen, "Hello World", 0, 0, 0)

      output = @adapter.all_output
      assert_equal 1, output.size
      assert_equal "Hello World", output[0][:text]
    end

    def test_renders_at_specified_position
      @renderer.render(@screen, "Test", 0, 5, 3)

      output = @adapter.all_output
      assert_equal 1, output.size
      assert_equal 5, output[0][:x]
      assert_equal 3, output[0][:y]
    end

    def test_renders_empty_line
      @renderer.render(@screen, "", 0, 0, 0)

      output = @adapter.all_output
      # Empty line may or may not produce output
      assert output.empty? || output[0][:text].empty?
    end

    def test_renders_with_single_highlight
      highlight = Mui::Highlight.new(start_col: 0, end_col: 4, style: :search_highlight, priority: 100)
      highlighter = MockHighlighter.new([highlight])
      @renderer.add_highlighter(highlighter)

      @renderer.render(@screen, "Hello World", 0, 0, 0)

      output = @adapter.all_output
      # Should have at least 2 segments: highlighted "Hello" and normal " World"
      assert output.size >= 1
    end

    def test_renders_with_multiple_highlights
      highlight1 = Mui::Highlight.new(start_col: 0, end_col: 4, style: :search_highlight, priority: 100)
      highlight2 = Mui::Highlight.new(start_col: 6, end_col: 10, style: :visual_selection, priority: 200)
      highlighter = MockHighlighter.new([highlight1, highlight2])
      @renderer.add_highlighter(highlighter)

      @renderer.render(@screen, "Hello World", 0, 0, 0)

      output = @adapter.all_output
      assert output.size >= 1
    end
  end

  class TestBuildSegments < TestLineRenderer
    def test_builds_single_segment_without_highlights
      # Use send to access private method
      segments = @renderer.send(:build_segments, "Hello", [])

      assert_equal 1, segments.size
      assert_equal "Hello", segments[0][:text]
      assert_equal :normal, segments[0][:style]
    end

    def test_builds_segments_with_partial_highlight
      highlight = Mui::Highlight.new(start_col: 0, end_col: 2, style: :search_highlight, priority: 100)
      segments = @renderer.send(:build_segments, "Hello", [highlight])

      # Should have highlighted "Hel" and normal "lo"
      assert segments.size >= 2
    end

    def test_builds_segments_with_full_line_highlight
      highlight = Mui::Highlight.new(start_col: 0, end_col: 4, style: :search_highlight, priority: 100)
      segments = @renderer.send(:build_segments, "Hello", [highlight])

      assert segments.size >= 1
      assert_equal :search_highlight, segments[0][:style]
    end
  end

  class TestCollectHighlights < TestLineRenderer
    def test_returns_empty_array_without_highlighters
      highlights = @renderer.send(:collect_highlights, 0, "test", {})

      assert_empty highlights
    end

    def test_collects_from_multiple_highlighters
      h1 = Mui::Highlight.new(start_col: 0, end_col: 2, style: :search_highlight, priority: 100)
      h2 = Mui::Highlight.new(start_col: 3, end_col: 5, style: :visual_selection, priority: 200)
      @renderer.add_highlighter(MockHighlighter.new([h1]))
      @renderer.add_highlighter(MockHighlighter.new([h2]))

      highlights = @renderer.send(:collect_highlights, 0, "test line", {})

      assert_equal 2, highlights.size
    end

    def test_sorts_highlights_by_position
      h1 = Mui::Highlight.new(start_col: 5, end_col: 7, style: :search_highlight, priority: 100)
      h2 = Mui::Highlight.new(start_col: 0, end_col: 2, style: :visual_selection, priority: 200)
      @renderer.add_highlighter(MockHighlighter.new([h1, h2]))

      highlights = @renderer.send(:collect_highlights, 0, "test line", {})

      assert_equal 0, highlights[0].start_col
      assert_equal 5, highlights[1].start_col
    end
  end
end

# Mock highlighter for testing
class MockHighlighter
  attr_reader :called

  def initialize(highlights)
    @highlights = highlights
    @called = false
  end

  def highlights_for(_row, _line, _options = {})
    @called = true
    @highlights
  end

  def priority
    100
  end
end
