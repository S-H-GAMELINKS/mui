# frozen_string_literal: true

require "test_helper"

class TestTabBarRenderer < Minitest::Test
  def setup
    @screen = Mui::TerminalAdapter::Test.new(width: 80, height: 24)
    @tab_manager = Mui::TabManager.new(@screen)
    @renderer = Mui::TabBarRenderer.new(@tab_manager)
  end

  class TestHeight < TestTabBarRenderer
    def test_returns_zero_when_single_tab
      @tab_manager.add

      assert_equal 0, @renderer.height
    end

    def test_returns_zero_when_no_tabs
      assert_equal 0, @renderer.height
    end

    def test_returns_two_when_multiple_tabs
      @tab_manager.add
      @tab_manager.add
      # TAB_BAR_HEIGHT (1) + SEPARATOR_HEIGHT (1) = 2
      assert_equal 2, @renderer.height
    end
  end

  class TestRender < TestTabBarRenderer
    def setup
      super
      @screen_obj = Mui::Screen.new(adapter: @screen)
    end

    def test_does_not_render_when_single_tab
      @tab_manager.add
      @renderer.render(@screen_obj)

      # Nothing should be rendered at row 0
      # (no way to directly check, but no error)
    end

    def test_renders_tab_bar_when_multiple_tabs
      @tab_manager.add
      buffer = Mui::Buffer.new
      buffer.name = "file1.rb"
      @tab_manager.current_tab.window_manager.add_window(buffer)

      @tab_manager.add
      buffer2 = Mui::Buffer.new
      buffer2.name = "file2.rb"
      @tab_manager.current_tab.window_manager.add_window(buffer2)

      @renderer.render(@screen_obj)

      # Should render without error
    end

    def test_marks_current_tab_with_asterisk
      @tab_manager.add
      @tab_manager.add

      output = capture_all_tab_texts

      assert(output.any? { |t| t.include?("*2:") }) # Current tab (index 1) should have asterisk
      assert(output.any? { |t| t.include?(" 1:") }) # First tab should have space
    end

    def test_shows_tab_numbers
      @tab_manager.add
      @tab_manager.add
      @tab_manager.add

      output = capture_all_tab_texts

      assert(output.any? { |t| t.include?("1:") })
      assert(output.any? { |t| t.include?("2:") })
      assert(output.any? { |t| t.include?("3:") })
    end

    def test_truncates_long_names
      @tab_manager.add
      buffer = Mui::Buffer.new
      buffer.name = "this_is_a_very_long_filename.rb"
      @tab_manager.current_tab.window_manager.add_window(buffer)

      @tab_manager.add

      output = capture_all_tab_texts

      # Name should be truncated to 15 chars with ~
      assert(output.any? { |t| t.include?("this_is_a_very~") })
    end

    def test_uses_color_scheme_style
      color_scheme = Mui::ColorScheme.new("test")
      color_scheme.define :tab_bar, fg: :white, bg: :blue
      color_scheme.define :tab_bar_active, fg: :black, bg: :cyan
      renderer = Mui::TabBarRenderer.new(@tab_manager, color_scheme:)

      @tab_manager.add
      @tab_manager.add

      # Should render without error
      renderer.render(@screen_obj)
    end

    def test_falls_back_to_status_line_style
      color_scheme = Mui::ColorScheme.new("test")
      color_scheme.define :status_line, fg: :black, bg: :white
      renderer = Mui::TabBarRenderer.new(@tab_manager, color_scheme:)

      @tab_manager.add
      @tab_manager.add

      # Should render without error
      renderer.render(@screen_obj)
    end

    def test_active_tab_uses_different_style
      color_scheme = Mui::ColorScheme.new("test")
      color_scheme.define :tab_bar, fg: :white, bg: :blue
      color_scheme.define :tab_bar_active, fg: :black, bg: :cyan, bold: true
      renderer = Mui::TabBarRenderer.new(@tab_manager, color_scheme:)

      @tab_manager.add
      @tab_manager.add

      # Verify styles are returned correctly
      assert_equal({ fg: :white, bg: :blue, bold: false, underline: false },
                   renderer.send(:tab_bar_style))
      assert_equal({ fg: :black, bg: :cyan, bold: true, underline: false },
                   renderer.send(:tab_bar_active_style))
    end

    private

    def capture_all_tab_texts
      @tab_manager.tabs.map.with_index do |tab, i|
        @renderer.send(:build_tab_text, tab, i)
      end
    end
  end
end
