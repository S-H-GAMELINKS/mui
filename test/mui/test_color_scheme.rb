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
    refute color[:bold]
    refute color[:underline]
  end

  def test_define_with_bold
    @scheme.define :status_line, fg: :black, bg: :white, bold: true

    color = @scheme[:status_line]

    assert color[:bold]
  end

  def test_define_with_underline
    @scheme.define :message_error, fg: :red, bg: nil, underline: true

    color = @scheme[:message_error]

    assert color[:underline]
  end

  def test_default_color_for_undefined_element
    color = @scheme[:undefined]

    assert_equal :white, color[:fg]
    assert_nil color[:bg]
    refute color[:bold]
    refute color[:underline]
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
      completion_popup
      completion_popup_selected
      syntax_keyword
      syntax_string
      syntax_comment
      syntax_number
      syntax_symbol
      syntax_constant
      syntax_operator
      syntax_identifier
      syntax_preprocessor
      syntax_instance_variable
      syntax_global_variable
      syntax_method_call
      syntax_function_definition
      syntax_type
      diff_add
      diff_delete
      diff_hunk
      diff_header
    ]

    assert_equal expected_elements, Mui::ColorScheme::ELEMENTS
  end
end
