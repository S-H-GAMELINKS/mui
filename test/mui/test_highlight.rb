# frozen_string_literal: true

require "test_helper"

class TestHighlight < Minitest::Test
  def setup
    @highlight = Mui::Highlight.new(
      start_col: 5,
      end_col: 10,
      style: :search_highlight,
      priority: 100
    )
  end

  class TestInitialize < TestHighlight
    def test_sets_start_col
      assert_equal 5, @highlight.start_col
    end

    def test_sets_end_col
      assert_equal 10, @highlight.end_col
    end

    def test_sets_style
      assert_equal :search_highlight, @highlight.style
    end

    def test_sets_priority
      assert_equal 100, @highlight.priority
    end
  end

  class TestAccessors < TestHighlight
    def test_start_col_is_readable
      assert_respond_to @highlight, :start_col
    end

    def test_end_col_is_readable
      assert_respond_to @highlight, :end_col
    end

    def test_style_is_readable
      assert_respond_to @highlight, :style
    end

    def test_priority_is_readable
      assert_respond_to @highlight, :priority
    end
  end

  class TestOverlaps < TestHighlight
    def test_returns_true_when_overlapping
      other = Mui::Highlight.new(start_col: 8, end_col: 15, style: :visual, priority: 50)

      assert @highlight.overlaps?(other)
    end

    def test_returns_true_when_other_inside_self
      other = Mui::Highlight.new(start_col: 6, end_col: 8, style: :visual, priority: 50)

      assert @highlight.overlaps?(other)
    end

    def test_returns_true_when_self_inside_other
      other = Mui::Highlight.new(start_col: 0, end_col: 20, style: :visual, priority: 50)

      assert @highlight.overlaps?(other)
    end

    def test_returns_true_when_touching_at_end
      other = Mui::Highlight.new(start_col: 10, end_col: 15, style: :visual, priority: 50)

      assert @highlight.overlaps?(other)
    end

    def test_returns_true_when_touching_at_start
      other = Mui::Highlight.new(start_col: 0, end_col: 5, style: :visual, priority: 50)

      assert @highlight.overlaps?(other)
    end

    def test_returns_false_when_not_overlapping_before
      other = Mui::Highlight.new(start_col: 0, end_col: 3, style: :visual, priority: 50)

      refute @highlight.overlaps?(other)
    end

    def test_returns_false_when_not_overlapping_after
      other = Mui::Highlight.new(start_col: 15, end_col: 20, style: :visual, priority: 50)

      refute @highlight.overlaps?(other)
    end
  end

  class TestComparison < TestHighlight
    def test_sorts_by_start_col_first
      h1 = Mui::Highlight.new(start_col: 5, end_col: 10, style: :a, priority: 100)
      h2 = Mui::Highlight.new(start_col: 10, end_col: 15, style: :b, priority: 100)

      assert_equal(-1, h1 <=> h2)
      assert_equal 1, h2 <=> h1
    end

    def test_sorts_by_priority_when_same_start_col
      h1 = Mui::Highlight.new(start_col: 5, end_col: 10, style: :a, priority: 100)
      h2 = Mui::Highlight.new(start_col: 5, end_col: 15, style: :b, priority: 200)

      # Higher priority should come first (negative priority in comparison)
      assert_equal 1, h1 <=> h2
      assert_equal(-1, h2 <=> h1)
    end

    def test_equal_when_same_start_and_priority
      h1 = Mui::Highlight.new(start_col: 5, end_col: 10, style: :a, priority: 100)
      h2 = Mui::Highlight.new(start_col: 5, end_col: 15, style: :b, priority: 100)

      assert_equal 0, h1 <=> h2
    end

    def test_can_be_sorted
      h1 = Mui::Highlight.new(start_col: 10, end_col: 15, style: :a, priority: 100)
      h2 = Mui::Highlight.new(start_col: 0, end_col: 5, style: :b, priority: 100)
      h3 = Mui::Highlight.new(start_col: 5, end_col: 10, style: :c, priority: 100)

      sorted = [h1, h2, h3].sort

      assert_equal 0, sorted[0].start_col
      assert_equal 5, sorted[1].start_col
      assert_equal 10, sorted[2].start_col
    end
  end
end
