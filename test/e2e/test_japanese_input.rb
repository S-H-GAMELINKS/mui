# frozen_string_literal: true

require_relative "test_helper"
require "tempfile"

class TestE2EJapaneseInput < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  def test_insert_japanese_text
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("こんにちは")
      .type("<Esc>")
      .assert_mode(Mui::Mode::NORMAL)
      .assert_line(0, "こんにちは")
      .assert_cursor(0, 4) # Cursor moves back one on Esc
  end

  def test_insert_mixed_ascii_and_japanese
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("Hello世界")
      .type("<Esc>")
      .assert_line(0, "Hello世界")
      .assert_cursor(0, 6)
  end

  def test_multiple_lines_with_japanese
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("一行目")
      .type("<Enter>")
      .type("二行目")
      .type("<Enter>")
      .type("三行目")
      .type("<Esc>")
      .assert_line_count(3)
      .assert_line(0, "一行目")
      .assert_line(1, "二行目")
      .assert_line(2, "三行目")
  end

  def test_cursor_movement_in_japanese_text
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("あいうえお")
      .type("<Esc>")
      .assert_cursor(0, 4)
      .type("h")
      .assert_cursor(0, 3)
      .type("h")
      .assert_cursor(0, 2)
      .type("l")
      .assert_cursor(0, 3)
      .type("0") # Go to beginning
      .assert_cursor(0, 0)
      .type("$") # Go to end
      .assert_cursor(0, 4)
  end

  def test_delete_japanese_character
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("あいうえお")
      .type("<Esc>")
      .type("0")        # Go to beginning
      .type("x")        # Delete first character
      .assert_line(0, "いうえお")
      .type("x")
      .assert_line(0, "うえお")
  end

  def test_backspace_japanese_character
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("あいう")
      .type("<BS>")     # Delete う
      .assert_line(0, "あい")
      .type("<BS>")     # Delete い
      .assert_line(0, "あ")
      .type("<Esc>")
  end

  def test_insert_japanese_in_middle
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("始終")
      .type("<Esc>")
      .type("0")        # Go to beginning
      .type("l")        # Move to second character
      .type("i")        # Insert before
      .type("中")
      .type("<Esc>")
      .assert_line(0, "始中終")
  end

  def test_append_japanese_text
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("前")
      .type("<Esc>")
      .type("a")        # Append after cursor
      .type("後")
      .type("<Esc>")
      .assert_line(0, "前後")
  end

  def test_japanese_word_motion
    runner = ScriptRunner.new

    # Use space-separated words for reliable word motion
    runner
      .type("i")
      .type("word1 word2 word3")
      .type("<Esc>")
      .type("0")
      .type("w")        # Next word
      .type("w")        # Next word
      .assert_cursor(0, 12) # At word3
  end

  def test_delete_japanese_character_with_x
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("削除テスト")
      .type("<Esc>")
      .type("0")
      .type("xx")       # Delete first two characters
      .assert_line(0, "テスト")
  end

  def test_yank_and_paste_japanese
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("コピー")
      .type("<Esc>")
      .type("0")
      .type("y$")       # Yank to end of line
      .type("$")        # Go to end
      .type("p")        # Paste after
      .assert_line(0, "コピーコピー")
  end

  def test_change_japanese_text_with_c_dollar
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("古いテキスト")
      .type("<Esc>")
      .type("0")
      .type("ll")       # Move to テ
      .type("c$")       # Change to end of line
      .type("新しい")
      .type("<Esc>")
      .assert_line(0, "古い新しい")
  end

  def test_visual_mode_with_japanese
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("選択テスト")
      .type("<Esc>")
      .type("0")
      .type("v")        # Visual mode
      .type("l")        # Select 2 characters (選択)
      .type("d")        # Delete selection
      .assert_line(0, "テスト")
  end

  def test_save_and_load_japanese_file
    Tempfile.create(["japanese", ".txt"]) do |f|
      runner = ScriptRunner.new

      runner
        .type("i")
        .type("日本語テスト")
        .type("<Enter>")
        .type("保存確認")
        .type("<Esc>")
        .type(":w #{f.path}<Enter>")
        .assert_modified(false)

      # Verify file content
      content = File.read(f.path)

      assert_equal "日本語テスト\n保存確認\n", content

      # Load and verify
      runner2 = ScriptRunner.new(f.path)
      runner2
        .assert_line(0, "日本語テスト")
        .assert_line(1, "保存確認")
    end
  end

  def test_search_japanese_text
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("検索対象の文字列です")
      .type("<Esc>")
      .type("0")
      .type("/対象<Enter>") # Search for 対象
      .assert_cursor(0, 2) # Found at position 2
  end

  def test_delete_and_insert_japanese
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("置換前テスト")
      .type("<Esc>")
      .type("0")
      .type("ll")          # Move to 前
      .type("x")           # Delete 前
      .type("i後") # Insert 後
      .type("<Esc>")
      .assert_line(0, "置換後テスト")
  end

  def test_open_line_with_japanese
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("上の行")
      .type("<Esc>")
      .type("o")           # Open line below
      .type("下の行")
      .type("<Esc>")
      .assert_line_count(2)
      .assert_line(0, "上の行")
      .assert_line(1, "下の行")
  end

  def test_undo_japanese_input
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("入力テスト")
      .type("<Esc>")
      .assert_line(0, "入力テスト")
      .type("u")           # Undo
      .assert_line(0, "")
  end

  def test_redo_japanese_input
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("やり直し")
      .type("<Esc>")
      .type("u")           # Undo
      .assert_line(0, "")
      .type("<C-r>")       # Redo
      .assert_line(0, "やり直し")
  end

  def test_screen_cursor_position_with_japanese
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("あいう")
      .type("<Esc>")

    # cursor_col is 2 (at last char "う")
    # Display width should be 2 * 2 = 4 for "あい" before cursor
    window = runner.editor.window

    assert_equal 2, window.cursor_col
    # screen_cursor_x considers display width
    assert_equal 4, window.screen_cursor_x
  end

  def test_mixed_width_cursor_position
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("ABあいCD")
      .type("<Esc>")

    window = runner.editor.window
    # After Esc, cursor is at position 5 (at 'D')
    assert_equal 5, window.cursor_col
    # Display width: "ABあいC" = 2 + 4 + 1 = 7
    assert_equal 7, window.screen_cursor_x
  end
end
