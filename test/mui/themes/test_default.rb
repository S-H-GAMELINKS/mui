# frozen_string_literal: true

require "test_helper"

class TestThemesDefault < Minitest::Test
  EXPECTED_THEMES = %i[
    mui
    solarized_dark
    solarized_light
    monokai
    nord
    gruvbox_dark
    dracula
    tokyo_night
  ].freeze

  REQUIRED_STYLES = %i[
    normal
    status_line
    status_line_mode
    search_highlight
    visual_selection
    line_number
    message_error
    message_info
  ].freeze

  class TestThemeAvailability < TestThemesDefault
    EXPECTED_THEMES.each do |theme_name|
      define_method("test_#{theme_name}_theme_exists") do
        assert_respond_to Mui::Themes, theme_name
      end

      define_method("test_#{theme_name}_returns_color_scheme") do
        scheme = Mui::Themes.send(theme_name)

        assert_instance_of Mui::ColorScheme, scheme
      end
    end
  end

  class TestMuiTheme < TestThemesDefault
    def setup
      @scheme = Mui::Themes.mui
    end

    def test_has_name
      assert_equal "mui", @scheme.name
    end

    REQUIRED_STYLES.each do |style|
      define_method("test_defines_#{style}_style") do
        assert @scheme[style], "Expected #{style} style to be defined"
      end
    end
  end

  class TestSolarizedDarkTheme < TestThemesDefault
    def setup
      @scheme = Mui::Themes.solarized_dark
    end

    def test_has_name
      assert_equal "solarized_dark", @scheme.name
    end

    REQUIRED_STYLES.each do |style|
      define_method("test_defines_#{style}_style") do
        assert @scheme[style], "Expected #{style} style to be defined"
      end
    end
  end

  class TestSolarizedLightTheme < TestThemesDefault
    def setup
      @scheme = Mui::Themes.solarized_light
    end

    def test_has_name
      assert_equal "solarized_light", @scheme.name
    end

    REQUIRED_STYLES.each do |style|
      define_method("test_defines_#{style}_style") do
        assert @scheme[style], "Expected #{style} style to be defined"
      end
    end
  end

  class TestMonokaiTheme < TestThemesDefault
    def setup
      @scheme = Mui::Themes.monokai
    end

    def test_has_name
      assert_equal "monokai", @scheme.name
    end

    REQUIRED_STYLES.each do |style|
      define_method("test_defines_#{style}_style") do
        assert @scheme[style], "Expected #{style} style to be defined"
      end
    end
  end

  class TestNordTheme < TestThemesDefault
    def setup
      @scheme = Mui::Themes.nord
    end

    def test_has_name
      assert_equal "nord", @scheme.name
    end

    REQUIRED_STYLES.each do |style|
      define_method("test_defines_#{style}_style") do
        assert @scheme[style], "Expected #{style} style to be defined"
      end
    end
  end

  class TestGruvboxDarkTheme < TestThemesDefault
    def setup
      @scheme = Mui::Themes.gruvbox_dark
    end

    def test_has_name
      assert_equal "gruvbox_dark", @scheme.name
    end

    REQUIRED_STYLES.each do |style|
      define_method("test_defines_#{style}_style") do
        assert @scheme[style], "Expected #{style} style to be defined"
      end
    end
  end

  class TestDraculaTheme < TestThemesDefault
    def setup
      @scheme = Mui::Themes.dracula
    end

    def test_has_name
      assert_equal "dracula", @scheme.name
    end

    REQUIRED_STYLES.each do |style|
      define_method("test_defines_#{style}_style") do
        assert @scheme[style], "Expected #{style} style to be defined"
      end
    end
  end

  class TestTokyoNightTheme < TestThemesDefault
    def setup
      @scheme = Mui::Themes.tokyo_night
    end

    def test_has_name
      assert_equal "tokyo_night", @scheme.name
    end

    REQUIRED_STYLES.each do |style|
      define_method("test_defines_#{style}_style") do
        assert @scheme[style], "Expected #{style} style to be defined"
      end
    end
  end
end
