# frozen_string_literal: true

require "test_helper"

class TestThemes < Minitest::Test
  AVAILABLE_THEMES = %i[
    mui
    solarized_dark
    solarized_light
    monokai
    nord
    gruvbox_dark
    dracula
    tokyo_night
  ].freeze

  def test_mui_theme_exists
    scheme = Mui::Themes.mui

    assert_instance_of Mui::ColorScheme, scheme
    assert_equal "mui", scheme.name
  end

  def test_mui_theme_has_required_elements
    scheme = Mui::Themes.mui
    Mui::ColorScheme::ELEMENTS.each do |element|
      color = scheme[element]

      refute_nil color[:fg], "#{element} should have fg defined"
    end
  end

  def test_mui_status_line_colors
    scheme = Mui::Themes.mui
    status = scheme[:status_line]

    assert_equal :mui_fg, status[:fg]
    assert_equal :mui_status_bg, status[:bg]
  end

  def test_all_themes_exist
    AVAILABLE_THEMES.each do |theme_name|
      scheme = Mui::Themes.send(theme_name)

      assert_instance_of Mui::ColorScheme, scheme
      assert_equal theme_name.to_s, scheme.name
    end
  end

  def test_all_themes_have_required_elements
    AVAILABLE_THEMES.each do |theme_name|
      scheme = Mui::Themes.send(theme_name)
      Mui::ColorScheme::ELEMENTS.each do |element|
        color = scheme[element]

        refute_nil color[:fg], "#{theme_name}:#{element} should have fg defined"
      end
    end
  end
end
