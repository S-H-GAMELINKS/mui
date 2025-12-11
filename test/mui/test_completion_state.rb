# frozen_string_literal: true

require "test_helper"

class TestCompletionState < Minitest::Test
  def setup
    @state = Mui::CompletionState.new
  end

  class TestInitialize < TestCompletionState
    def test_initially_inactive
      refute @state.active?
    end

    def test_initially_empty_candidates
      assert_empty @state.candidates
    end

    def test_initially_zero_selected_index
      assert_equal 0, @state.selected_index
    end

    def test_initially_nil_original_input
      assert_nil @state.original_input
    end

    def test_initially_nil_completion_type
      assert_nil @state.completion_type
    end
  end

  class TestStart < TestCompletionState
    def test_start_activates_with_candidates
      @state.start(%w[foo bar], "f", :command)

      assert @state.active?
    end

    def test_start_sets_candidates
      @state.start(%w[foo bar], "f", :command)

      assert_equal %w[foo bar], @state.candidates
    end

    def test_start_sets_original_input
      @state.start(%w[foo bar], "f", :command)

      assert_equal "f", @state.original_input
    end

    def test_start_sets_completion_type
      @state.start(%w[foo bar], "f", :command)

      assert_equal :command, @state.completion_type
    end

    def test_start_resets_selected_index_to_zero
      @state.start(%w[a b c], "", :command)
      @state.select_next
      @state.select_next

      @state.start(%w[x y], "", :file)

      assert_equal 0, @state.selected_index
    end
  end

  class TestReset < TestCompletionState
    def test_reset_clears_candidates
      @state.start(%w[foo bar], "f", :command)

      @state.reset

      assert_empty @state.candidates
    end

    def test_reset_makes_inactive
      @state.start(%w[foo bar], "f", :command)

      @state.reset

      refute @state.active?
    end

    def test_reset_clears_original_input
      @state.start(%w[foo bar], "f", :command)

      @state.reset

      assert_nil @state.original_input
    end

    def test_reset_clears_completion_type
      @state.start(%w[foo bar], "f", :command)

      @state.reset

      assert_nil @state.completion_type
    end

    def test_reset_resets_selected_index
      @state.start(%w[foo bar], "f", :command)
      @state.select_next

      @state.reset

      assert_equal 0, @state.selected_index
    end
  end

  class TestSelectNext < TestCompletionState
    def test_select_next_increments_index
      @state.start(%w[a b c], "", :command)

      @state.select_next

      assert_equal 1, @state.selected_index
    end

    def test_select_next_wraps_around
      @state.start(%w[a b c], "", :command)

      @state.select_next
      @state.select_next
      @state.select_next

      assert_equal 0, @state.selected_index
    end

    def test_select_next_does_nothing_when_inactive
      @state.select_next

      assert_equal 0, @state.selected_index
    end
  end

  class TestSelectPrevious < TestCompletionState
    def test_select_previous_decrements_index
      @state.start(%w[a b c], "", :command)
      @state.select_next
      @state.select_next

      @state.select_previous

      assert_equal 1, @state.selected_index
    end

    def test_select_previous_wraps_around
      @state.start(%w[a b c], "", :command)

      @state.select_previous

      assert_equal 2, @state.selected_index
    end

    def test_select_previous_does_nothing_when_inactive
      @state.select_previous

      assert_equal 0, @state.selected_index
    end
  end

  class TestCurrentCandidate < TestCompletionState
    def test_current_candidate_returns_selected
      @state.start(%w[a b c], "", :command)

      assert_equal "a", @state.current_candidate
    end

    def test_current_candidate_returns_selected_after_navigation
      @state.start(%w[a b c], "", :command)
      @state.select_next

      assert_equal "b", @state.current_candidate
    end

    def test_current_candidate_returns_nil_when_inactive
      assert_nil @state.current_candidate
    end
  end

  class TestActive < TestCompletionState
    def test_active_false_with_empty_candidates
      refute @state.active?
    end

    def test_active_true_with_candidates
      @state.start(%w[foo], "f", :command)

      assert @state.active?
    end

    def test_active_false_after_reset
      @state.start(%w[foo], "f", :command)
      @state.reset

      refute @state.active?
    end
  end

  class TestConfirmed < TestCompletionState
    def test_initially_not_confirmed
      refute @state.confirmed?
    end

    def test_not_confirmed_after_start
      @state.start(%w[foo bar], "f", :command)

      refute @state.confirmed?
    end

    def test_confirmed_after_confirm
      @state.start(%w[foo bar], "f", :command)

      @state.confirm

      assert @state.confirmed?
    end

    def test_reset_clears_confirmed
      @state.start(%w[foo bar], "f", :command)
      @state.confirm

      @state.reset

      refute @state.confirmed?
    end

    def test_start_clears_confirmed
      @state.start(%w[foo bar], "f", :command)
      @state.confirm

      @state.start(%w[baz qux], "b", :file)

      refute @state.confirmed?
    end
  end
end
