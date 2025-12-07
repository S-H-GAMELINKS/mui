# frozen_string_literal: true

require "test_helper"

class TestStatusLineRenderer < Minitest::Test
  def setup
    @adapter = Mui::TerminalAdapter::Test.new(width: 80, height: 24)
    @screen = Mui::Screen.new(adapter: @adapter)
    @buffer = Mui::Buffer.new
    @window = Mui::Window.new(@buffer, width: 80, height: 24)
    @color_scheme = nil
    @renderer = Mui::StatusLineRenderer.new(@buffer, @window, @color_scheme)
  end

  class TestInitialize < TestStatusLineRenderer
    def test_initializes_with_dependencies
      renderer = Mui::StatusLineRenderer.new(@buffer, @window, @color_scheme)

      assert_instance_of Mui::StatusLineRenderer, renderer
    end

    def test_initializes_with_color_scheme
      color_scheme = { status_line: { fg: :white, bg: :blue } }
      renderer = Mui::StatusLineRenderer.new(@buffer, @window, color_scheme)

      assert_instance_of Mui::StatusLineRenderer, renderer
    end
  end

  class TestRender < TestStatusLineRenderer
    def test_renders_at_specified_y_position
      @renderer.render(@screen, 22)

      output = @adapter.all_output
      assert(output.any? { |o| o[:y] == 22 })
    end

    def test_renders_at_window_x_position
      @window.x = 10
      renderer = Mui::StatusLineRenderer.new(@buffer, @window, @color_scheme)

      renderer.render(@screen, 22)

      output = @adapter.all_output
      assert(output.any? { |o| o[:x] == 10 })
    end

    def test_includes_buffer_name
      @buffer.instance_variable_set(:@name, "file.rb")

      @renderer.render(@screen, 22)

      output = @adapter.all_output
      text = output.map { |o| o[:text] }.join
      assert_includes text, "file.rb"
    end

    def test_includes_modified_indicator_when_modified
      @buffer.instance_variable_set(:@modified, true)

      @renderer.render(@screen, 22)

      output = @adapter.all_output
      text = output.map { |o| o[:text] }.join
      assert_includes text, "[+]"
    end

    def test_excludes_modified_indicator_when_not_modified
      @buffer.instance_variable_set(:@modified, false)

      @renderer.render(@screen, 22)

      output = @adapter.all_output
      text = output.map { |o| o[:text] }.join
      refute_includes text, "[+]"
    end

    def test_includes_cursor_position
      @window.cursor_row = 5
      @window.cursor_col = 10

      @renderer.render(@screen, 22)

      output = @adapter.all_output
      text = output.map { |o| o[:text] }.join
      # Position is 1-indexed in display
      assert_includes text, "6:11"
    end
  end

  class TestBuildStatusText < TestStatusLineRenderer
    def test_includes_buffer_name
      @buffer.instance_variable_set(:@name, "test.txt")

      status = @renderer.send(:build_status_text)

      assert_includes status, "test.txt"
    end

    def test_includes_modified_marker_when_modified
      @buffer.instance_variable_set(:@modified, true)

      status = @renderer.send(:build_status_text)

      assert_includes status, "[+]"
    end

    def test_uses_no_name_for_unnamed
      # Default buffer name is "[No Name]"
      status = @renderer.send(:build_status_text)

      assert_includes status, "[No Name]"
    end
  end

  class TestBuildPositionText < TestStatusLineRenderer
    def test_returns_1_indexed_position
      @window.cursor_row = 0
      @window.cursor_col = 0

      position = @renderer.send(:build_position_text)

      assert_equal "1:1 ", position
    end

    def test_returns_correct_position
      @window.cursor_row = 9
      @window.cursor_col = 24

      position = @renderer.send(:build_position_text)

      assert_equal "10:25 ", position
    end
  end

  class TestFormatStatusLine < TestStatusLineRenderer
    def test_pads_to_window_width
      result = @renderer.send(:format_status_line, " test", "1:1 ")

      assert_equal 80, result.length
    end

    def test_truncates_if_exceeds_width
      @window.width = 20
      renderer = Mui::StatusLineRenderer.new(@buffer, @window, @color_scheme)

      result = renderer.send(:format_status_line, " #{"a" * 30}", "1:1 ")

      assert_equal 20, result.length
    end

    def test_includes_status_and_position
      result = @renderer.send(:format_status_line, " file.rb", "5:10 ")

      assert_includes result, "file.rb"
      assert_includes result, "5:10"
    end
  end
end
