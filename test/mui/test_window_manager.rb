# frozen_string_literal: true

require "test_helper"

class TestWindowManager < Minitest::Test
  def setup
    @screen = Mui::TerminalAdapter::Test.new(width: 80, height: 24)
    @buffer = Mui::Buffer.new
    @window_manager = Mui::WindowManager.new(@screen)
  end

  class TestInitialize < TestWindowManager
    def test_initializes_with_empty_windows
      assert_equal 0, @window_manager.window_count
    end

    def test_initializes_with_nil_active_window
      assert_nil @window_manager.active_window
    end

    def test_initializes_with_nil_layout_root
      assert_nil @window_manager.layout_root
    end
  end

  class TestAddWindow < TestWindowManager
    def test_adds_window_and_returns_it
      window = @window_manager.add_window(@buffer)

      assert_instance_of Mui::Window, window
      assert_equal 1, @window_manager.window_count
    end

    def test_sets_first_window_as_active
      window = @window_manager.add_window(@buffer)

      assert_equal window, @window_manager.active_window
    end

    def test_creates_leaf_node_for_first_window
      @window_manager.add_window(@buffer)

      assert_instance_of Mui::Layout::LeafNode, @window_manager.layout_root
    end

    def test_sets_window_dimensions_from_screen
      window = @window_manager.add_window(@buffer)

      # height 24 - command line 1 = 23 available
      assert_equal 0, window.x
      assert_equal 0, window.y
      assert_equal 80, window.width
      assert_equal 23, window.height
    end
  end

  class TestSplitHorizontal < TestWindowManager
    def test_creates_second_window
      @window_manager.add_window(@buffer)
      new_window = @window_manager.split_horizontal

      assert_instance_of Mui::Window, new_window
      assert_equal 2, @window_manager.window_count
    end

    def test_divides_height_equally
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal

      # height 24 - command line 1 = 23, - separator 1 = 22 available, split 50% = 11 + 11
      windows = @window_manager.windows

      assert_equal 11, windows[0].height
      assert_equal 11, windows[1].height
    end

    def test_maintains_full_width
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal

      windows = @window_manager.windows

      assert_equal 80, windows[0].width
      assert_equal 80, windows[1].width
    end

    def test_positions_windows_correctly
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal

      # window[1] starts after window[0] + separator
      windows = @window_manager.windows

      assert_equal 0, windows[0].y
      assert_equal 12, windows[1].y # 11 + 1 (separator)
    end

    def test_sets_new_window_as_active
      @window_manager.add_window(@buffer)
      new_window = @window_manager.split_horizontal

      assert_equal new_window, @window_manager.active_window
    end

    def test_shares_same_buffer_by_default
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal

      windows = @window_manager.windows

      assert_same windows[0].buffer, windows[1].buffer
    end

    def test_can_specify_different_buffer
      @window_manager.add_window(@buffer)
      new_buffer = Mui::Buffer.new
      @window_manager.split_horizontal(new_buffer)

      windows = @window_manager.windows

      refute_same windows[0].buffer, windows[1].buffer
    end

    def test_creates_split_node_in_layout
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal

      assert_instance_of Mui::Layout::SplitNode, @window_manager.layout_root
      assert_equal :horizontal, @window_manager.layout_root.direction
    end
  end

  class TestSplitVertical < TestWindowManager
    def test_creates_second_window
      @window_manager.add_window(@buffer)
      new_window = @window_manager.split_vertical

      assert_instance_of Mui::Window, new_window
      assert_equal 2, @window_manager.window_count
    end

    def test_divides_width_equally
      @window_manager.add_window(@buffer)
      @window_manager.split_vertical

      # width 80 - separator 1 = 79 available, split 50% = 39 + 40
      windows = @window_manager.windows

      assert_equal 39, windows[0].width
      assert_equal 40, windows[1].width
    end

    def test_maintains_full_height
      @window_manager.add_window(@buffer)
      @window_manager.split_vertical

      # height 24 - command line 1 = 23 available for windows
      windows = @window_manager.windows

      assert_equal 23, windows[0].height
      assert_equal 23, windows[1].height
    end

    def test_positions_windows_correctly
      @window_manager.add_window(@buffer)
      @window_manager.split_vertical

      # window[1] starts after window[0] + separator
      windows = @window_manager.windows

      assert_equal 0, windows[0].x
      assert_equal 40, windows[1].x # 39 + 1 (separator)
    end

    def test_creates_split_node_in_layout
      @window_manager.add_window(@buffer)
      @window_manager.split_vertical

      assert_instance_of Mui::Layout::SplitNode, @window_manager.layout_root
      assert_equal :vertical, @window_manager.layout_root.direction
    end
  end

  class TestNestedSplit < TestWindowManager
    def test_can_split_horizontally_then_vertically
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal
      @window_manager.split_vertical

      assert_equal 3, @window_manager.window_count
    end

    def test_nested_layout_positions_correctly
      # Create layout:
      # +--------+
      # |   1    |
      # +---+|---+
      # | 2 || 3 |
      # +---+|---+
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal  # Now active is window 2 (bottom)
      @window_manager.split_vertical    # Now active is window 3 (bottom right)

      windows = @window_manager.windows
      # height 24 - separator 1 = 23, split 50% = 11 + 12
      # Window 1: top
      assert_equal 0, windows[0].y
      assert_equal 11, windows[0].height
      assert_equal 80, windows[0].width

      # Windows 2 & 3: bottom half (height 12), split vertically
      # width 80 - separator 1 = 79, split 50% = 39 + 40
      assert_equal 12, windows[1].y # 11 + 1 (separator)
      assert_equal 12, windows[2].y
      assert_equal 39, windows[1].width
      assert_equal 40, windows[2].width
    end
  end

  class TestRemoveWindow < TestWindowManager
    def test_cannot_remove_single_window
      window = @window_manager.add_window(@buffer)
      result = @window_manager.remove_window(window)

      refute result
      assert_equal 1, @window_manager.window_count
    end

    def test_removes_window_from_split
      @window_manager.add_window(@buffer)
      second_window = @window_manager.split_horizontal

      @window_manager.remove_window(second_window)

      assert_equal 1, @window_manager.window_count
    end

    def test_sets_active_window_when_active_removed
      first_window = @window_manager.add_window(@buffer)
      second_window = @window_manager.split_horizontal

      @window_manager.remove_window(second_window)

      assert_equal first_window, @window_manager.active_window
    end

    def test_layout_returns_to_leaf_after_close
      @window_manager.add_window(@buffer)
      second_window = @window_manager.split_horizontal

      @window_manager.remove_window(second_window)

      assert_instance_of Mui::Layout::LeafNode, @window_manager.layout_root
    end
  end

  class TestCloseCurrentWindow < TestWindowManager
    def test_cannot_close_single_window
      @window_manager.add_window(@buffer)
      result = @window_manager.close_current_window

      refute result
      assert_equal 1, @window_manager.window_count
    end

    def test_closes_active_window
      first_window = @window_manager.add_window(@buffer)
      @window_manager.split_horizontal  # Creates second window, makes it active

      @window_manager.close_current_window

      assert_equal 1, @window_manager.window_count
      assert_equal first_window, @window_manager.active_window
    end
  end

  class TestCloseAllExceptCurrent < TestWindowManager
    def test_does_nothing_with_single_window
      window = @window_manager.add_window(@buffer)
      @window_manager.close_all_except_current

      assert_equal 1, @window_manager.window_count
      assert_equal window, @window_manager.active_window
    end

    def test_closes_all_other_windows
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal
      active = @window_manager.split_vertical

      @window_manager.close_all_except_current

      assert_equal 1, @window_manager.window_count
      assert_equal active, @window_manager.active_window
    end
  end

  class TestFocusNext < TestWindowManager
    def test_does_nothing_with_single_window
      window = @window_manager.add_window(@buffer)
      @window_manager.focus_next

      assert_equal window, @window_manager.active_window
    end

    def test_cycles_to_next_window
      first_window = @window_manager.add_window(@buffer)
      @window_manager.split_horizontal  # Makes second window active
      @window_manager.focus_previous    # Back to first

      @window_manager.focus_next

      refute_equal first_window, @window_manager.active_window
    end

    def test_wraps_around_to_first_window
      first_window = @window_manager.add_window(@buffer)
      @window_manager.split_horizontal

      @window_manager.focus_next

      assert_equal first_window, @window_manager.active_window
    end
  end

  class TestFocusPrevious < TestWindowManager
    def test_does_nothing_with_single_window
      window = @window_manager.add_window(@buffer)
      @window_manager.focus_previous

      assert_equal window, @window_manager.active_window
    end

    def test_cycles_to_previous_window
      first_window = @window_manager.add_window(@buffer)
      @window_manager.split_horizontal  # Makes second window active

      @window_manager.focus_previous

      assert_equal first_window, @window_manager.active_window
    end
  end

  class TestFocusDirection < TestWindowManager
    def test_focus_right_in_vertical_split
      @window_manager.add_window(@buffer)
      second_window = @window_manager.split_vertical
      @window_manager.focus_previous  # Back to first

      @window_manager.focus_direction(:right)

      assert_equal second_window, @window_manager.active_window
    end

    def test_focus_left_in_vertical_split
      first_window = @window_manager.add_window(@buffer)
      @window_manager.split_vertical  # Makes second window active

      @window_manager.focus_direction(:left)

      assert_equal first_window, @window_manager.active_window
    end

    def test_focus_down_in_horizontal_split
      @window_manager.add_window(@buffer)
      second_window = @window_manager.split_horizontal
      @window_manager.focus_previous  # Back to first

      @window_manager.focus_direction(:down)

      assert_equal second_window, @window_manager.active_window
    end

    def test_focus_up_in_horizontal_split
      first_window = @window_manager.add_window(@buffer)
      @window_manager.split_horizontal # Makes second window active

      @window_manager.focus_direction(:up)

      assert_equal first_window, @window_manager.active_window
    end

    def test_does_nothing_when_no_window_in_direction
      @window_manager.add_window(@buffer)
      active = @window_manager.split_vertical

      @window_manager.focus_direction(:right)

      assert_equal active, @window_manager.active_window
    end
  end

  class TestWindowCount < TestWindowManager
    def test_returns_zero_when_empty
      assert_equal 0, @window_manager.window_count
    end

    def test_returns_one_with_single_window
      @window_manager.add_window(@buffer)

      assert_equal 1, @window_manager.window_count
    end

    def test_returns_correct_count_with_splits
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal
      @window_manager.split_vertical

      assert_equal 3, @window_manager.window_count
    end
  end

  class TestSingleWindow < TestWindowManager
    def test_returns_true_when_empty
      # Empty is considered single (or less)
      assert_predicate @window_manager, :single_window?
    end

    def test_returns_true_with_one_window
      @window_manager.add_window(@buffer)

      assert_predicate @window_manager, :single_window?
    end

    def test_returns_false_with_multiple_windows
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal

      refute_predicate @window_manager, :single_window?
    end
  end

  class TestUpdateSizes < TestWindowManager
    def test_updates_window_layout
      window = @window_manager.add_window(@buffer)

      # Change screen size
      @screen.width = 120
      @screen.height = 40
      @window_manager.update_sizes

      # height 40 - command line 1 = 39 available
      assert_equal 120, window.width
      assert_equal 39, window.height
    end

    def test_updates_split_layout
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal

      @screen.width = 120
      @screen.height = 40
      @window_manager.update_sizes

      # height 40 - command line 1 = 39, - separator 1 = 38 available, split 50% = 19 + 19
      windows = @window_manager.windows

      assert_equal 120, windows[0].width
      assert_equal 19, windows[0].height
      assert_equal 120, windows[1].width
      assert_equal 19, windows[1].height
    end
  end

  class TestRenderAll < TestWindowManager
    def test_renders_without_error
      @window_manager.add_window(@buffer)
      screen = Mui::Screen.new(adapter: @screen)

      # Should not raise
      @window_manager.render_all(screen)
    end

    def test_renders_multiple_windows_without_error
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal
      screen = Mui::Screen.new(adapter: @screen)

      # Should not raise
      @window_manager.render_all(screen)
    end
  end

  class TestWindows < TestWindowManager
    def test_returns_empty_array_when_no_layout
      assert_empty @window_manager.windows
    end

    def test_returns_all_windows_from_layout
      @window_manager.add_window(@buffer)
      @window_manager.split_horizontal
      @window_manager.split_vertical

      assert_equal 3, @window_manager.windows.size
    end
  end
end
