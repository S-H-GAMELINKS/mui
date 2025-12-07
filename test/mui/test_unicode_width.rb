# frozen_string_literal: true

require "test_helper"

class TestUnicodeWidth < Minitest::Test
  class TestCharWidth < Minitest::Test
    def test_returns_zero_for_nil
      assert_equal 0, Mui::UnicodeWidth.char_width(nil)
    end

    def test_returns_zero_for_empty_string
      assert_equal 0, Mui::UnicodeWidth.char_width("")
    end

    def test_returns_zero_for_control_characters
      assert_equal 0, Mui::UnicodeWidth.char_width("\x00")
      assert_equal 0, Mui::UnicodeWidth.char_width("\t")
      assert_equal 0, Mui::UnicodeWidth.char_width("\n")
    end

    def test_returns_one_for_ascii_printable
      assert_equal 1, Mui::UnicodeWidth.char_width("a")
      assert_equal 1, Mui::UnicodeWidth.char_width("Z")
      assert_equal 1, Mui::UnicodeWidth.char_width("0")
      assert_equal 1, Mui::UnicodeWidth.char_width("!")
      assert_equal 1, Mui::UnicodeWidth.char_width(" ")
    end

    def test_returns_zero_for_delete_character
      assert_equal 0, Mui::UnicodeWidth.char_width("\x7F")
    end

    def test_returns_two_for_japanese_hiragana
      assert_equal 2, Mui::UnicodeWidth.char_width("あ")
      assert_equal 2, Mui::UnicodeWidth.char_width("い")
    end

    def test_returns_two_for_japanese_katakana
      assert_equal 2, Mui::UnicodeWidth.char_width("ア")
      assert_equal 2, Mui::UnicodeWidth.char_width("イ")
    end

    def test_returns_two_for_kanji
      assert_equal 2, Mui::UnicodeWidth.char_width("漢")
      assert_equal 2, Mui::UnicodeWidth.char_width("字")
    end

    def test_returns_two_for_fullwidth_forms
      assert_equal 2, Mui::UnicodeWidth.char_width("Ａ") # Fullwidth A
      assert_equal 2, Mui::UnicodeWidth.char_width("１") # Fullwidth 1
    end

    def test_returns_two_for_cjk_symbols
      assert_equal 2, Mui::UnicodeWidth.char_width("。") # CJK period
      assert_equal 2, Mui::UnicodeWidth.char_width("、") # CJK comma
    end

    def test_returns_one_for_halfwidth_katakana
      assert_equal 1, Mui::UnicodeWidth.char_width("ｱ") # Halfwidth katakana
    end
  end

  class TestStringWidth < Minitest::Test
    def test_returns_zero_for_nil
      assert_equal 0, Mui::UnicodeWidth.string_width(nil)
    end

    def test_returns_zero_for_empty_string
      assert_equal 0, Mui::UnicodeWidth.string_width("")
    end

    def test_returns_length_for_ascii_string
      assert_equal 5, Mui::UnicodeWidth.string_width("Hello")
      assert_equal 11, Mui::UnicodeWidth.string_width("Hello World")
    end

    def test_returns_correct_width_for_japanese
      # "あいう" = 3 characters * 2 width = 6
      assert_equal 6, Mui::UnicodeWidth.string_width("あいう")
    end

    def test_returns_correct_width_for_mixed_content
      # "Hello世界" = 5 (ASCII) + 4 (2 wide chars) = 9
      assert_equal 9, Mui::UnicodeWidth.string_width("Hello世界")
    end
  end

  class TestWidthToCol < Minitest::Test
    def test_returns_zero_for_nil
      assert_equal 0, Mui::UnicodeWidth.width_to_col(nil, 5)
    end

    def test_returns_zero_for_zero_col
      assert_equal 0, Mui::UnicodeWidth.width_to_col("Hello", 0)
    end

    def test_returns_zero_for_negative_col
      assert_equal 0, Mui::UnicodeWidth.width_to_col("Hello", -1)
    end

    def test_returns_correct_width_for_ascii
      assert_equal 3, Mui::UnicodeWidth.width_to_col("Hello", 3)
    end

    def test_returns_correct_width_for_japanese
      # First 2 characters of "あいう" = 4 width
      assert_equal 4, Mui::UnicodeWidth.width_to_col("あいう", 2)
    end

    def test_returns_correct_width_for_mixed
      # "Helloあ" - col=6 means "Hello" + "あ" = 5 + 2 = 7
      assert_equal 7, Mui::UnicodeWidth.width_to_col("Helloあい", 6)
    end
  end

  class TestColAtWidth < Minitest::Test
    def test_returns_zero_for_nil
      assert_equal 0, Mui::UnicodeWidth.col_at_width(nil, 5)
    end

    def test_returns_zero_for_zero_width
      assert_equal 0, Mui::UnicodeWidth.col_at_width("Hello", 0)
    end

    def test_returns_zero_for_negative_width
      assert_equal 0, Mui::UnicodeWidth.col_at_width("Hello", -1)
    end

    def test_returns_correct_col_for_ascii
      assert_equal 3, Mui::UnicodeWidth.col_at_width("Hello", 3)
    end

    def test_returns_correct_col_for_japanese
      # Width 4 in "あいう" = 2 characters (each is width 2)
      assert_equal 2, Mui::UnicodeWidth.col_at_width("あいう", 4)
    end

    def test_returns_length_when_width_exceeds_string
      assert_equal 5, Mui::UnicodeWidth.col_at_width("Hello", 100)
    end
  end
end
