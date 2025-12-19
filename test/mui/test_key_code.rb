# frozen_string_literal: true

require "test_helper"

class TestKeyCode < Minitest::Test
  class TestConstants < Minitest::Test
    def test_escape_constant
      assert_equal 27, Mui::KeyCode::ESCAPE
    end

    def test_backspace_constant
      assert_equal 127, Mui::KeyCode::BACKSPACE
    end

    def test_enter_cr_constant
      assert_equal 13, Mui::KeyCode::ENTER_CR
    end

    def test_enter_lf_constant
      assert_equal 10, Mui::KeyCode::ENTER_LF
    end

    def test_printable_min_constant
      assert_equal 32, Mui::KeyCode::PRINTABLE_MIN
    end

    def test_printable_max_constant
      # Maximum valid Unicode code point
      assert_equal 0x10FFFF, Mui::KeyCode::PRINTABLE_MAX
    end
  end

  class TestConstantValues < Minitest::Test
    def test_escape_matches_ascii_escape
      assert_equal "\e".ord, Mui::KeyCode::ESCAPE
    end

    def test_enter_cr_matches_carriage_return
      assert_equal "\r".ord, Mui::KeyCode::ENTER_CR
    end

    def test_enter_lf_matches_line_feed
      assert_equal "\n".ord, Mui::KeyCode::ENTER_LF
    end

    def test_printable_min_is_space
      assert_equal " ".ord, Mui::KeyCode::PRINTABLE_MIN
    end
  end

  class TestConstantUsage < Minitest::Test
    def test_escape_can_detect_escape_key
      key = 27

      assert_equal key, Mui::KeyCode::ESCAPE
    end

    def test_printable_range_includes_ascii_letters
      assert_operator "a".ord, :>=, Mui::KeyCode::PRINTABLE_MIN
      assert_operator "a".ord, :<=, Mui::KeyCode::PRINTABLE_MAX
      assert_operator "Z".ord, :>=, Mui::KeyCode::PRINTABLE_MIN
      assert_operator "Z".ord, :<=, Mui::KeyCode::PRINTABLE_MAX
    end

    def test_printable_range_includes_unicode
      # Japanese hiragana "あ"
      assert_operator "あ".ord, :>=, Mui::KeyCode::PRINTABLE_MIN
      assert_operator "あ".ord, :<=, Mui::KeyCode::PRINTABLE_MAX
    end

    def test_printable_range_excludes_control_characters
      assert_operator "\t".ord, :<, Mui::KeyCode::PRINTABLE_MIN
      assert_operator "\n".ord, :<, Mui::KeyCode::PRINTABLE_MIN
    end
  end
end
