# frozen_string_literal: true

require "test_helper"

class TestKeyNotationParser < Minitest::Test
  def test_parse_simple_keys
    assert_equal %w[a b c], Mui::KeyNotationParser.parse("abc")
  end

  def test_parse_single_char
    assert_equal ["g"], Mui::KeyNotationParser.parse("g")
  end

  def test_parse_empty_string
    assert_equal [], Mui::KeyNotationParser.parse("")
    assert_equal [], Mui::KeyNotationParser.parse(nil)
  end

  def test_parse_space
    assert_equal [" ", "w"], Mui::KeyNotationParser.parse("<Space>w")
    assert_equal [" "], Mui::KeyNotationParser.parse("<space>")
  end

  def test_parse_leader
    assert_equal [:leader, "g", "d"], Mui::KeyNotationParser.parse("<Leader>gd")
    assert_equal [:leader], Mui::KeyNotationParser.parse("<leader>")
    assert_equal [:leader], Mui::KeyNotationParser.parse("<LEADER>")
  end

  def test_parse_ctrl_keys
    # Ctrl-X = ASCII 24
    assert_equal ["\x18"], Mui::KeyNotationParser.parse("<C-x>")
    assert_equal ["\x18"], Mui::KeyNotationParser.parse("<Ctrl-x>")
    assert_equal ["\x18"], Mui::KeyNotationParser.parse("<c-X>")

    # Ctrl-S = ASCII 19
    assert_equal ["\x13"], Mui::KeyNotationParser.parse("<C-s>")

    # Ctrl-A = ASCII 1
    assert_equal ["\x01"], Mui::KeyNotationParser.parse("<C-a>")

    # Ctrl-[ = Escape = ASCII 27
    assert_equal ["\e"], Mui::KeyNotationParser.parse("<C-[>")
  end

  def test_parse_multiple_ctrl_keys
    # <C-x><C-s>
    assert_equal ["\x18", "\x13"], Mui::KeyNotationParser.parse("<C-x><C-s>")
  end

  def test_parse_shift_keys
    assert_equal ["A"], Mui::KeyNotationParser.parse("<S-a>")
    assert_equal ["X"], Mui::KeyNotationParser.parse("<Shift-x>")
  end

  def test_parse_special_keys
    assert_equal ["\t"], Mui::KeyNotationParser.parse("<Tab>")
    assert_equal ["\r"], Mui::KeyNotationParser.parse("<CR>")
    assert_equal ["\r"], Mui::KeyNotationParser.parse("<Enter>")
    assert_equal ["\r"], Mui::KeyNotationParser.parse("<Return>")
    assert_equal ["\e"], Mui::KeyNotationParser.parse("<Esc>")
    assert_equal ["\e"], Mui::KeyNotationParser.parse("<Escape>")
    assert_equal ["\x7f"], Mui::KeyNotationParser.parse("<BS>")
    assert_equal ["\x7f"], Mui::KeyNotationParser.parse("<Backspace>")
  end

  def test_parse_literal_brackets
    assert_equal ["<"], Mui::KeyNotationParser.parse("<lt>")
    assert_equal [">"], Mui::KeyNotationParser.parse("<gt>")
  end

  def test_parse_mixed_notation
    # <Leader>ff
    assert_equal [:leader, "f", "f"], Mui::KeyNotationParser.parse("<Leader>ff")

    # <Space>gd
    assert_equal [" ", "g", "d"], Mui::KeyNotationParser.parse("<Space>gd")

    # <C-x>s
    assert_equal ["\x18", "s"], Mui::KeyNotationParser.parse("<C-x>s")
  end

  def test_parse_unknown_special_returns_as_is
    # Unknown special key notation returns the name as-is
    assert_equal ["Unknown"], Mui::KeyNotationParser.parse("<Unknown>")
  end

  # normalize_input_key tests

  def test_normalize_input_key_string
    assert_equal "a", Mui::KeyNotationParser.normalize_input_key("a")
    assert_equal "abc", Mui::KeyNotationParser.normalize_input_key("abc")
  end

  def test_normalize_input_key_enter
    assert_equal "\r", Mui::KeyNotationParser.normalize_input_key(Mui::KeyCode::ENTER_CR)
    assert_equal "\r", Mui::KeyNotationParser.normalize_input_key(Mui::KeyCode::ENTER_LF)
  end

  def test_normalize_input_key_escape
    assert_equal "\e", Mui::KeyNotationParser.normalize_input_key(Mui::KeyCode::ESCAPE)
  end

  def test_normalize_input_key_tab
    assert_equal "\t", Mui::KeyNotationParser.normalize_input_key(Mui::KeyCode::TAB)
  end

  def test_normalize_input_key_backspace
    assert_equal "\x7f", Mui::KeyNotationParser.normalize_input_key(Mui::KeyCode::BACKSPACE)
  end

  def test_normalize_input_key_ctrl_chars
    # Ctrl-A = 1
    assert_equal "\x01", Mui::KeyNotationParser.normalize_input_key(1)
    # Ctrl-X = 24
    assert_equal "\x18", Mui::KeyNotationParser.normalize_input_key(24)
  end

  def test_normalize_input_key_printable
    # ASCII 'a' = 97
    assert_equal "a", Mui::KeyNotationParser.normalize_input_key(97)
    # ASCII 'Z' = 90
    assert_equal "Z", Mui::KeyNotationParser.normalize_input_key(90)
  end

  def test_normalize_input_key_unicode
    # Japanese hiragana 'あ' = 0x3042
    assert_equal "あ", Mui::KeyNotationParser.normalize_input_key(0x3042)
  end

  def test_normalize_input_key_nil_for_invalid
    assert_nil Mui::KeyNotationParser.normalize_input_key(nil)
  end
end
