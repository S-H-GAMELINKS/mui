# frozen_string_literal: true

require "test_helper"

class TestTabPage < Minitest::Test
  def setup
    @screen = Mui::TerminalAdapter::Test.new(width: 80, height: 24)
    @tab_page = Mui::TabPage.new(@screen)
  end

  class TestInitialize < TestTabPage
    def test_initializes_with_window_manager
      assert_instance_of Mui::WindowManager, @tab_page.window_manager
    end

    def test_initializes_with_nil_name
      assert_nil @tab_page.name
    end

    def test_accepts_custom_name
      tab = Mui::TabPage.new(@screen, name: "MyTab")
      assert_equal "MyTab", tab.name
    end

    def test_passes_color_scheme_to_window_manager
      color_scheme = { status_line: { fg: :white, bg: :black } }
      tab = Mui::TabPage.new(@screen, color_scheme:)

      # WindowManager should be created (can't directly check color_scheme, but no error)
      assert_instance_of Mui::WindowManager, tab.window_manager
    end
  end

  class TestDelegation < TestTabPage
    def test_delegates_active_window_to_window_manager
      buffer = Mui::Buffer.new
      @tab_page.window_manager.add_window(buffer)

      assert_equal @tab_page.window_manager.active_window, @tab_page.active_window
    end

    def test_delegates_layout_root_to_window_manager
      buffer = Mui::Buffer.new
      @tab_page.window_manager.add_window(buffer)

      assert_equal @tab_page.window_manager.layout_root, @tab_page.layout_root
    end

    def test_delegates_windows_to_window_manager
      buffer = Mui::Buffer.new
      @tab_page.window_manager.add_window(buffer)

      assert_equal @tab_page.window_manager.windows, @tab_page.windows
    end

    def test_delegates_window_count_to_window_manager
      buffer = Mui::Buffer.new
      @tab_page.window_manager.add_window(buffer)

      assert_equal 1, @tab_page.window_count
    end
  end

  class TestDisplayName < TestTabPage
    def test_returns_custom_name_if_set
      @tab_page.name = "MyTab"
      assert_equal "MyTab", @tab_page.display_name
    end

    def test_returns_buffer_name_if_no_custom_name
      buffer = Mui::Buffer.new
      buffer.name = "test.txt"
      @tab_page.window_manager.add_window(buffer)

      assert_equal "test.txt", @tab_page.display_name
    end

    def test_returns_no_name_placeholder_when_no_buffer
      assert_equal "[No Name]", @tab_page.display_name
    end

    def test_returns_no_name_placeholder_when_buffer_has_no_name
      buffer = Mui::Buffer.new
      @tab_page.window_manager.add_window(buffer)

      assert_equal "[No Name]", @tab_page.display_name
    end
  end
end
