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

    def test_does_not_change_active_window_when_adding_second
      first_window = @window_manager.add_window(@buffer)
      second_buffer = Mui::Buffer.new
      @window_manager.add_window(second_buffer)

      assert_equal first_window, @window_manager.active_window
      assert_equal 2, @window_manager.window_count
    end

    def test_sets_window_dimensions_from_screen
      window = @window_manager.add_window(@buffer)

      assert_equal 0, window.x
      assert_equal 0, window.y
      assert_equal 80, window.width
      assert_equal 24, window.height
    end
  end

  class TestRemoveWindow < TestWindowManager
    def test_removes_window_from_list
      window = @window_manager.add_window(@buffer)
      @window_manager.remove_window(window)

      assert_equal 0, @window_manager.window_count
    end

    def test_sets_active_window_to_first_remaining_when_active_removed
      first_window = @window_manager.add_window(@buffer)
      second_buffer = Mui::Buffer.new
      second_window = @window_manager.add_window(second_buffer)

      # Make second window active
      @window_manager.focus_next

      # Remove second window (active)
      @window_manager.remove_window(second_window)

      assert_equal first_window, @window_manager.active_window
    end

    def test_sets_active_window_to_nil_when_last_removed
      window = @window_manager.add_window(@buffer)
      @window_manager.remove_window(window)

      assert_nil @window_manager.active_window
    end
  end

  class TestFocusNext < TestWindowManager
    def test_does_nothing_with_single_window
      window = @window_manager.add_window(@buffer)
      @window_manager.focus_next

      assert_equal window, @window_manager.active_window
    end

    def test_cycles_to_next_window
      @window_manager.add_window(@buffer)
      second_buffer = Mui::Buffer.new
      second_window = @window_manager.add_window(second_buffer)

      @window_manager.focus_next

      assert_equal second_window, @window_manager.active_window
    end

    def test_wraps_around_to_first_window
      first_window = @window_manager.add_window(@buffer)
      second_buffer = Mui::Buffer.new
      @window_manager.add_window(second_buffer)

      @window_manager.focus_next
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
      @window_manager.add_window(@buffer)
      second_buffer = Mui::Buffer.new
      second_window = @window_manager.add_window(second_buffer)

      @window_manager.focus_previous

      # From first, previous wraps to second (last)
      assert_equal second_window, @window_manager.active_window
    end

    def test_wraps_around_to_last_window
      @window_manager.add_window(@buffer)
      second_buffer = Mui::Buffer.new
      second_window = @window_manager.add_window(second_buffer)

      @window_manager.focus_previous

      assert_equal second_window, @window_manager.active_window
    end
  end

  class TestWindowCount < TestWindowManager
    def test_returns_zero_when_empty
      assert_equal 0, @window_manager.window_count
    end

    def test_returns_correct_count
      @window_manager.add_window(@buffer)
      @window_manager.add_window(Mui::Buffer.new)

      assert_equal 2, @window_manager.window_count
    end
  end

  class TestSingleWindow < TestWindowManager
    def test_returns_false_when_empty
      refute @window_manager.single_window?
    end

    def test_returns_true_with_one_window
      @window_manager.add_window(@buffer)

      assert @window_manager.single_window?
    end

    def test_returns_false_with_multiple_windows
      @window_manager.add_window(@buffer)
      @window_manager.add_window(Mui::Buffer.new)

      refute @window_manager.single_window?
    end
  end

  class TestUpdateSizes < TestWindowManager
    def test_updates_window_layout
      window = @window_manager.add_window(@buffer)

      # Change screen size
      @screen.width = 120
      @screen.height = 40
      @window_manager.update_sizes

      assert_equal 120, window.width
      assert_equal 40, window.height
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
      @window_manager.add_window(Mui::Buffer.new)
      screen = Mui::Screen.new(adapter: @screen)

      # Should not raise
      @window_manager.render_all(screen)
    end
  end
end
