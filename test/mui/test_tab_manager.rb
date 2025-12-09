# frozen_string_literal: true

require "test_helper"

class TestTabManager < Minitest::Test
  def setup
    @screen = Mui::TerminalAdapter::Test.new(width: 80, height: 24)
    @tab_manager = Mui::TabManager.new(@screen)
  end

  class TestInitialize < TestTabManager
    def test_starts_with_empty_tabs
      assert_equal 0, @tab_manager.tab_count
    end

    def test_starts_with_index_zero
      assert_equal 0, @tab_manager.current_index
    end

    def test_current_tab_is_nil_when_empty
      assert_nil @tab_manager.current_tab
    end
  end

  class TestAdd < TestTabManager
    def test_adds_new_tab
      @tab_manager.add
      assert_equal 1, @tab_manager.tab_count
    end

    def test_sets_new_tab_as_current
      @tab_manager.add
      @tab_manager.add
      assert_equal 1, @tab_manager.current_index
    end

    def test_returns_the_new_tab
      tab = @tab_manager.add
      assert_instance_of Mui::TabPage, tab
    end

    def test_returns_the_same_tab_if_provided
      custom_tab = Mui::TabPage.new(@screen, name: "Custom")
      returned_tab = @tab_manager.add(custom_tab)

      assert_same custom_tab, returned_tab
      assert_equal "Custom", @tab_manager.current_tab.name
    end

    def test_creates_tab_with_color_scheme
      color_scheme = { status_line: { fg: :white, bg: :black } }
      manager = Mui::TabManager.new(@screen, color_scheme:)
      tab = manager.add

      assert_instance_of Mui::TabPage, tab
    end
  end

  class TestCloseCurrent < TestTabManager
    def test_cannot_close_last_tab
      @tab_manager.add
      result = @tab_manager.close_current

      refute result
      assert_equal 1, @tab_manager.tab_count
    end

    def test_cannot_close_when_empty
      result = @tab_manager.close_current

      refute result
    end

    def test_closes_current_tab
      @tab_manager.add
      @tab_manager.add
      @tab_manager.close_current

      assert_equal 1, @tab_manager.tab_count
    end

    def test_adjusts_index_when_closing_last_tab
      @tab_manager.add
      @tab_manager.add
      # current_index is 1 (last tab)
      @tab_manager.close_current

      assert_equal 0, @tab_manager.current_index
    end

    def test_keeps_index_when_closing_first_tab
      @tab_manager.add
      @tab_manager.add
      @tab_manager.add
      @tab_manager.go_to(0)
      @tab_manager.close_current

      assert_equal 0, @tab_manager.current_index
    end

    def test_returns_true_on_success
      @tab_manager.add
      @tab_manager.add
      result = @tab_manager.close_current

      assert result
    end
  end

  class TestNextTab < TestTabManager
    def test_does_nothing_when_empty
      @tab_manager.next_tab
      assert_equal 0, @tab_manager.current_index
    end

    def test_cycles_forward
      @tab_manager.add
      @tab_manager.add
      @tab_manager.go_to(0)

      @tab_manager.next_tab

      assert_equal 1, @tab_manager.current_index
    end

    def test_wraps_around
      @tab_manager.add
      @tab_manager.add
      # current_index is 1

      @tab_manager.next_tab

      assert_equal 0, @tab_manager.current_index
    end
  end

  class TestPrevTab < TestTabManager
    def test_does_nothing_when_empty
      @tab_manager.prev_tab
      assert_equal 0, @tab_manager.current_index
    end

    def test_cycles_backward
      @tab_manager.add
      @tab_manager.add
      # current_index is 1

      @tab_manager.prev_tab

      assert_equal 0, @tab_manager.current_index
    end

    def test_wraps_around
      @tab_manager.add
      @tab_manager.add
      @tab_manager.go_to(0)

      @tab_manager.prev_tab

      assert_equal 1, @tab_manager.current_index
    end
  end

  class TestFirstTab < TestTabManager
    def test_does_nothing_when_empty
      @tab_manager.first_tab
      assert_equal 0, @tab_manager.current_index
    end

    def test_goes_to_first_tab
      @tab_manager.add
      @tab_manager.add
      @tab_manager.add
      # current_index is 2

      @tab_manager.first_tab

      assert_equal 0, @tab_manager.current_index
    end
  end

  class TestLastTab < TestTabManager
    def test_does_nothing_when_empty
      @tab_manager.last_tab
      assert_equal 0, @tab_manager.current_index
    end

    def test_goes_to_last_tab
      @tab_manager.add
      @tab_manager.add
      @tab_manager.add
      @tab_manager.go_to(0)

      @tab_manager.last_tab

      assert_equal 2, @tab_manager.current_index
    end
  end

  class TestGoTo < TestTabManager
    def test_goes_to_valid_index
      @tab_manager.add
      @tab_manager.add
      @tab_manager.add
      @tab_manager.go_to(0)

      result = @tab_manager.go_to(1)

      assert result
      assert_equal 1, @tab_manager.current_index
    end

    def test_returns_false_for_negative_index
      @tab_manager.add

      result = @tab_manager.go_to(-1)

      refute result
      assert_equal 0, @tab_manager.current_index
    end

    def test_returns_false_for_index_out_of_bounds
      @tab_manager.add

      result = @tab_manager.go_to(5)

      refute result
      assert_equal 0, @tab_manager.current_index
    end
  end

  class TestMoveTab < TestTabManager
    def test_returns_false_when_single_tab
      @tab_manager.add
      result = @tab_manager.move_tab(0)

      refute result
    end

    def test_moves_tab_to_new_position
      @tab_manager.add # tab 0
      @tab_manager.add # tab 1 (current)
      @tab_manager.add # tab 2

      tab1 = @tab_manager.current_tab

      @tab_manager.move_tab(0) # move current tab to position 0

      assert_equal 0, @tab_manager.current_index
      assert_same tab1, @tab_manager.current_tab
    end

    def test_clamps_position_to_valid_range
      @tab_manager.add
      @tab_manager.add
      @tab_manager.go_to(0)

      @tab_manager.move_tab(100)

      assert_equal 1, @tab_manager.current_index
    end

    def test_returns_true_on_success
      @tab_manager.add
      @tab_manager.add

      result = @tab_manager.move_tab(0)

      assert result
    end
  end

  class TestTabCount < TestTabManager
    def test_returns_zero_when_empty
      assert_equal 0, @tab_manager.tab_count
    end

    def test_returns_correct_count
      @tab_manager.add
      @tab_manager.add
      @tab_manager.add

      assert_equal 3, @tab_manager.tab_count
    end
  end

  class TestSingleTab < TestTabManager
    def test_returns_true_when_empty
      assert @tab_manager.single_tab?
    end

    def test_returns_true_with_one_tab
      @tab_manager.add

      assert @tab_manager.single_tab?
    end

    def test_returns_false_with_multiple_tabs
      @tab_manager.add
      @tab_manager.add

      refute @tab_manager.single_tab?
    end
  end

  class TestWindowManagerDelegation < TestTabManager
    def test_window_manager_returns_current_tabs_window_manager
      @tab_manager.add

      assert_same @tab_manager.current_tab.window_manager, @tab_manager.window_manager
    end

    def test_window_manager_returns_nil_when_empty
      assert_nil @tab_manager.window_manager
    end

    def test_active_window_returns_current_tabs_active_window
      @tab_manager.add
      buffer = Mui::Buffer.new
      @tab_manager.window_manager.add_window(buffer)

      assert_same @tab_manager.current_tab.active_window, @tab_manager.active_window
    end

    def test_active_window_returns_nil_when_empty
      assert_nil @tab_manager.active_window
    end
  end
end
