# frozen_string_literal: true

require "test_helper"

class TestColorScheme < Minitest::Test
  def setup
    @scheme = Mui::ColorScheme.new("test")
  end

  def test_name
    assert_equal "test", @scheme.name
  end

  def test_define_and_access_element
    @scheme.define :normal, fg: :white, bg: :black

    color = @scheme[:normal]
    assert_equal :white, color[:fg]
    assert_equal :black, color[:bg]
    assert_equal false, color[:bold]
    assert_equal false, color[:underline]
  end

  def test_define_with_bold
    @scheme.define :status_line, fg: :black, bg: :white, bold: true

    color = @scheme[:status_line]
    assert_equal true, color[:bold]
  end

  def test_define_with_underline
    @scheme.define :message_error, fg: :red, bg: nil, underline: true

    color = @scheme[:message_error]
    assert_equal true, color[:underline]
  end

  def test_default_color_for_undefined_element
    color = @scheme[:undefined]
    assert_equal :white, color[:fg]
    assert_nil color[:bg]
    assert_equal false, color[:bold]
    assert_equal false, color[:underline]
  end

  def test_elements_constant
    expected_elements = %i[
      normal
      status_line
      status_line_mode
      search_highlight
      visual_selection
      line_number
      message_error
      message_info
      tab_bar
      tab_bar_active
    ]
    assert_equal expected_elements, Mui::ColorScheme::ELEMENTS
  end
end
