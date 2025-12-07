# frozen_string_literal: true

require "test_helper"

class TestHighlightersBase < Minitest::Test
  def setup
    @color_scheme = { visual_selection: { fg: :white, bg: :blue } }
    @highlighter = Mui::Highlighters::Base.new(@color_scheme)
  end

  class TestConstants < TestHighlightersBase
    def test_priority_selection_constant
      assert_equal 100, Mui::Highlighters::Base::PRIORITY_SELECTION
    end

    def test_priority_search_constant
      assert_equal 200, Mui::Highlighters::Base::PRIORITY_SEARCH
    end

    def test_priority_syntax_constant
      assert_equal 300, Mui::Highlighters::Base::PRIORITY_SYNTAX
    end
  end

  class TestInitialize < TestHighlightersBase
    def test_initializes_with_color_scheme
      highlighter = Mui::Highlighters::Base.new(@color_scheme)

      assert_instance_of Mui::Highlighters::Base, highlighter
    end

    def test_initializes_with_nil_color_scheme
      highlighter = Mui::Highlighters::Base.new(nil)

      assert_instance_of Mui::Highlighters::Base, highlighter
    end
  end

  class TestHighlightsFor < TestHighlightersBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @highlighter.highlights_for(0, "test line")
      end
    end
  end

  class TestPriority < TestHighlightersBase
    def test_returns_zero_by_default
      assert_equal 0, @highlighter.priority
    end
  end
end
