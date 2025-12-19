# frozen_string_literal: true

require "test_helper"

class TestCompletionRenderer < Minitest::Test
  class MockScreen
    attr_reader :output, :positions, :width, :height

    def initialize(width: 80, height: 24)
      @width = width
      @height = height
      @output = []
      @positions = []
    end

    def put_with_style(row, col, text, _style)
      @positions << [row, col]
      @output << text
    end
  end

  class MockColorScheme
    def [](_key)
      { fg: :white, bg: :blue, bold: false, underline: false }
    end
  end

  def setup
    @screen = MockScreen.new
    @color_scheme = MockColorScheme.new
    @renderer = Mui::CompletionRenderer.new(@screen, @color_scheme)
  end

  class TestRenderInactive < TestCompletionRenderer
    def test_does_nothing_when_completion_inactive
      state = Mui::CompletionState.new

      @renderer.render(state, 23, 1)

      assert_empty @screen.output
    end
  end

  class TestRenderActive < TestCompletionRenderer
    def test_renders_candidates
      state = Mui::CompletionState.new
      state.start(%w[write wq], "w", :command)

      @renderer.render(state, 23, 1)

      assert_equal 2, @screen.output.length
    end

    def test_positions_above_command_line
      state = Mui::CompletionState.new
      state.start(%w[write wq], "w", :command)

      @renderer.render(state, 23, 1)

      # 2 candidates, popup should start at row 21 (23 - 2)
      assert_includes @screen.positions, [21, 1]
      assert_includes @screen.positions, [22, 1]
    end

    def test_includes_candidate_text
      state = Mui::CompletionState.new
      state.start(%w[tabnew tabclose], "tab", :command)

      @renderer.render(state, 23, 1)

      assert(@screen.output.any? { |s| s.include?("tabnew") })
      assert(@screen.output.any? { |s| s.include?("tabclose") })
    end
  end

  class TestVisibleRange < TestCompletionRenderer
    def test_shows_all_when_fewer_than_max
      state = Mui::CompletionState.new
      candidates = %w[one two three]
      state.start(candidates, "", :command)

      @renderer.render(state, 23, 1)

      assert_equal 3, @screen.output.length
    end

    def test_limits_visible_when_more_than_max
      state = Mui::CompletionState.new
      candidates = (1..15).map { |i| "item#{i}" }
      state.start(candidates, "", :command)

      @renderer.render(state, 23, 1)

      # Should show at most MAX_VISIBLE_ITEMS (10)
      assert_equal 10, @screen.output.length
    end
  end

  class TestWidth < TestCompletionRenderer
    def test_pads_to_max_width
      state = Mui::CompletionState.new
      state.start(%w[a longer], "", :command)

      @renderer.render(state, 23, 1)

      # All outputs should have same length (padded)
      widths = @screen.output.map(&:length).uniq

      assert_equal 1, widths.length
    end
  end

  class TestBounds < TestCompletionRenderer
    def test_clamps_column_to_screen_bounds
      state = Mui::CompletionState.new
      state.start(%w[verylongcommandname], "", :command)

      # Start at column 70, but screen is 80 wide
      @renderer.render(state, 23, 70)

      # Should clamp column to fit within screen
      col = @screen.positions.first[1]

      assert_operator col, :<, 70, "Column should be clamped to fit popup"
    end

    def test_clamps_row_to_screen_bounds
      state = Mui::CompletionState.new
      candidates = (1..5).map { |i| "item#{i}" }
      state.start(candidates, "", :command)

      # Base row is 3, popup height is 5, so popup_row would be -2
      @renderer.render(state, 3, 1)

      # Should clamp row to 0
      assert(@screen.positions.all? { |row, _col| row >= 0 })
    end
  end
end
