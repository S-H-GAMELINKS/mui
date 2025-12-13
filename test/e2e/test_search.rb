# frozen_string_literal: true

require_relative "test_helper"
require "tempfile"

class TestE2ESearch < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  def test_search_forward_basic
    # Scenario: Search for pattern and move to match
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("hello world\nfoo bar\nhello again")
      f.flush

      runner = ScriptRunner.new(f.path)

      runner
        .assert_cursor(0, 0)
        .type("/bar<Enter>")
        .assert_mode(Mui::Mode::NORMAL)
        .assert_cursor(1, 4) # "bar" starts at column 4 on line 1
    end
  end

  def test_search_backward_basic
    # Scenario: Search backward for pattern from end of file
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("hello world\nfoo bar\nend here")
      f.flush

      runner = ScriptRunner.new(f.path)

      runner
        .type("G")              # Go to last line
        .type("$")              # Go to end of line
        .type("?hello<Enter>")
        .assert_mode(Mui::Mode::NORMAL)
        .assert_cursor(0, 0)    # "hello" at line 0
    end
  end

  def test_search_pattern_not_found
    # Scenario: Search for non-existent pattern
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("hello world")
      f.flush

      runner = ScriptRunner.new(f.path)

      runner
        .type("/xyz<Enter>")
        .assert_mode(Mui::Mode::NORMAL)
        .assert_message_contains("Pattern not found")
        .assert_cursor(0, 0) # Cursor should not move
    end
  end

  def test_search_after_edit_command
    # Scenario: Open another file with :e, then search in new file
    # This tests the bug fix: search should use current buffer, not initial buffer
    Tempfile.create(["first", ".txt"]) do |f1|
      Tempfile.create(["second", ".txt"]) do |f2|
        f1.write("first file content")
        f1.flush
        f2.write("second file xyz content\nanother line")
        f2.flush

        runner = ScriptRunner.new(f1.path)

        runner
          .assert_line(0, "first file content")
          .type(":e #{f2.path}<Enter>")
          .assert_message_contains("opened")
          .assert_line(0, "second file xyz content")
          .type("/xyz<Enter>")
          .assert_mode(Mui::Mode::NORMAL)
          # Should find "xyz" in the NEW buffer, not get "Pattern not found"
          .assert_cursor(0, 12) # "xyz" starts at column 12
      end
    end
  end

  def test_search_n_repeats_forward
    # Scenario: Use n to find next match after initial search
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("aaa\nbbb hello\nccc hello")
      f.flush

      runner = ScriptRunner.new(f.path)

      # First search finds the first match
      runner
        .type("/hello<Enter>")
      # Get current position and use n to find next
      runner
        .type("n")              # Move to next match
        .type("n")              # Should wrap around
      # Just verify we can search and use n without errors
      runner.assert_mode(Mui::Mode::NORMAL)
    end
  end

  def test_search_shift_n_repeats_backward
    # Scenario: Use N to find previous match
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("hello first\nbbb\nhello second")
      f.flush

      runner = ScriptRunner.new(f.path)

      runner
        .type("/hello<Enter>")  # Find first "hello"
        .type("n")              # Find next "hello"
        .type("N")              # Go back to previous
        .assert_mode(Mui::Mode::NORMAL)
    end
  end

  def test_search_escape_cancels
    # Scenario: Press Escape to cancel search and restore cursor
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("hello world\nfoo bar")
      f.flush

      runner = ScriptRunner.new(f.path)

      runner
        .type("j")              # Move to line 1
        .assert_cursor(1, 0)
        .type("/hello")         # Start search (incremental moves cursor)
        .type("<Esc>")          # Cancel
        .assert_mode(Mui::Mode::NORMAL)
        .assert_cursor(1, 0)    # Cursor restored to original position
    end
  end

  def test_incremental_search_highlights
    # Scenario: Incremental search moves cursor as you type
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("hello world\nfoo bar")
      f.flush

      runner = ScriptRunner.new(f.path)

      runner
        .type("/foo")
        # During incremental search, cursor should move to match
        .assert_cursor(1, 0)
        .type("<Enter>")
        .assert_mode(Mui::Mode::NORMAL)
        .assert_cursor(1, 0)
    end
  end

  def test_search_after_horizontal_split
    # Scenario: Open file with :sp, then search in new buffer
    Tempfile.create(["first", ".txt"]) do |f1|
      Tempfile.create(["second", ".txt"]) do |f2|
        f1.write("first file content")
        f1.flush
        f2.write("second file xyz content\nanother line")
        f2.flush

        runner = ScriptRunner.new(f1.path)

        runner
          .assert_line(0, "first file content")
          .type(":sp #{f2.path}<Enter>")
          .assert_line(0, "second file xyz content")
          .type("/xyz<Enter>")
          .assert_mode(Mui::Mode::NORMAL)
          # Should find "xyz" in the split buffer
          .assert_cursor(0, 12)
      end
    end
  end

  def test_search_after_vertical_split
    # Scenario: Open file with :vs, then search in new buffer
    Tempfile.create(["first", ".txt"]) do |f1|
      Tempfile.create(["second", ".txt"]) do |f2|
        f1.write("first file content")
        f1.flush
        f2.write("second file xyz content\nanother line")
        f2.flush

        runner = ScriptRunner.new(f1.path)

        runner
          .assert_line(0, "first file content")
          .type(":vs #{f2.path}<Enter>")
          .assert_line(0, "second file xyz content")
          .type("/xyz<Enter>")
          .assert_mode(Mui::Mode::NORMAL)
          # Should find "xyz" in the split buffer
          .assert_cursor(0, 12)
      end
    end
  end

  def test_search_after_tabnew
    # Scenario: Open file with :tabnew, then search in new buffer
    Tempfile.create(["first", ".txt"]) do |f1|
      Tempfile.create(["second", ".txt"]) do |f2|
        f1.write("first file content")
        f1.flush
        f2.write("second file xyz content\nanother line")
        f2.flush

        runner = ScriptRunner.new(f1.path)

        runner
          .assert_line(0, "first file content")
          .type(":tabnew #{f2.path}<Enter>")
          .assert_line(0, "second file xyz content")
          .type("/xyz<Enter>")
          .assert_mode(Mui::Mode::NORMAL)
          # Should find "xyz" in the new tab buffer
          .assert_cursor(0, 12)
      end
    end
  end

  def test_search_highlight_after_gt_tab_switch
    # Scenario: Search in first tab, switch to second tab with gt, search should work
    Tempfile.create(["first", ".txt"]) do |f1|
      Tempfile.create(["second", ".txt"]) do |f2|
        f1.write("hello world\nfoo bar")
        f1.flush
        f2.write("another hello here\nmore hello")
        f2.flush

        runner = ScriptRunner.new(f1.path)

        runner
          .type(":tabnew #{f2.path}<Enter>")
          .type("gT")                     # Go back to first tab
          .type("/hello<Enter>")          # Search
          .assert_cursor(0, 0)            # First "hello" at line 0
          .type("gt")                     # Switch to second tab
          .type("n")                      # Next match in new buffer (from cursor 0,0)
          .assert_cursor(0, 8)            # "hello" at "another hello here"
      end
    end
  end

  def test_search_highlight_after_ctrl_w_window_switch
    # Scenario: Search in one window, switch to another with Ctrl-W, search should work
    Tempfile.create(["first", ".txt"]) do |f1|
      Tempfile.create(["second", ".txt"]) do |f2|
        f1.write("hello world")
        f1.flush
        f2.write("hello again\nmore hello")
        f2.flush

        runner = ScriptRunner.new(f1.path)

        runner
          .type(":vs #{f2.path}<Enter>")
          .type("/hello<Enter>")
          .assert_cursor(0, 0)            # First "hello" in split window
          .type("<C-w>l")                 # Switch to right window
          .type("n")                      # Next match in original buffer
          .assert_mode(Mui::Mode::NORMAL)
      end
    end
  end

  def test_search_highlight_after_tabn_command
    # Scenario: Search, then switch tabs with :tabn command
    Tempfile.create(["first", ".txt"]) do |f1|
      Tempfile.create(["second", ".txt"]) do |f2|
        f1.write("test pattern here")
        f1.flush
        f2.write("another test here\ntest again")
        f2.flush

        runner = ScriptRunner.new(f1.path)

        runner
          .type(":tabnew #{f2.path}<Enter>")
          .type(":tabp<Enter>")           # Go back to first tab
          .type("/test<Enter>")           # Search
          .assert_cursor(0, 0)            # First "test"
          .type(":tabn<Enter>")           # Switch to second tab via command
          .type("n")                      # Next match (from cursor 0,0)
          .assert_cursor(0, 8)            # "test" at "another test here"
      end
    end
  end
end
