# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestEditorIntegration < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  def test_file_load_and_display
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("Hello\nWorld")
      f.flush

      editor = create_test_editor(f.path)

      assert_equal "Hello", editor.buffer.line(0)
      assert_equal "World", editor.buffer.line(1)
      assert_equal 2, editor.buffer.line_count
      assert_equal f.path, editor.buffer.name
    end
  end

  def test_mode_transition_sequence
    editor = create_test_editor

    # Normal -> Insert
    editor.handle_key("i")

    assert_equal Mui::Mode::INSERT, editor.mode

    # Insert -> Normal
    editor.handle_key(27)

    assert_equal Mui::Mode::NORMAL, editor.mode

    # Normal -> Command
    editor.handle_key(":")

    assert_equal Mui::Mode::COMMAND, editor.mode

    # Command -> Normal (via Escape)
    editor.handle_key(27)

    assert_equal Mui::Mode::NORMAL, editor.mode
  end

  def test_insert_text_and_navigate
    editor = create_test_editor

    # Input "Hello" in Insert mode
    editor.handle_key("i")
    "Hello".each_char { |c| editor.handle_key(c) }

    assert_equal "Hello", editor.buffer.line(0)
    assert_equal 5, editor.window.cursor_col

    # Return to Normal mode
    editor.handle_key(27)

    assert_equal 4, editor.window.cursor_col # Moves back one

    # Navigate with hjkl
    editor.handle_key("h")

    assert_equal 3, editor.window.cursor_col

    editor.handle_key("l")

    assert_equal 4, editor.window.cursor_col
  end

  def test_delete_flow
    editor = create_test_editor

    # Input text
    editor.handle_key("i")
    "abc".each_char { |c| editor.handle_key(c) }
    editor.handle_key(27) # Normal mode

    # Delete with x
    editor.handle_key("h") # Move to 'c' position (cursor is at 'b')
    editor.handle_key("x") # Delete 'b'

    assert_equal "ac", editor.buffer.line(0)
  end

  def test_command_execution_flow
    Tempfile.create(["test", ".txt"]) do |f|
      editor = create_test_editor

      # Input text
      editor.handle_key("i")
      "Test".each_char { |c| editor.handle_key(c) }
      editor.handle_key(27)

      # Save with :w filename
      editor.handle_key(":")
      "w #{f.path}".each_char { |c| editor.handle_key(c) }
      editor.handle_key(13) # Enter

      assert_match(/written/, editor.message)
      assert_equal "Test\n", File.read(f.path)
    end
  end

  def test_multiline_input_and_navigation
    editor = create_test_editor

    # Input multiple lines
    editor.handle_key("i")
    "Line1".each_char { |c| editor.handle_key(c) }
    editor.handle_key(13) # Enter
    "Line2".each_char { |c| editor.handle_key(c) }
    editor.handle_key(13) # Enter
    "Line3".each_char { |c| editor.handle_key(c) }
    editor.handle_key(27) # Normal mode

    assert_equal 3, editor.buffer.line_count
    assert_equal "Line1", editor.buffer.line(0)
    assert_equal "Line2", editor.buffer.line(1)
    assert_equal "Line3", editor.buffer.line(2)
    assert_equal 2, editor.window.cursor_row

    # Move up
    editor.handle_key("k")

    assert_equal 1, editor.window.cursor_row

    editor.handle_key("k")

    assert_equal 0, editor.window.cursor_row
  end

  def test_backspace_joins_lines
    editor = create_test_editor

    # Input 2 lines
    editor.handle_key("i")
    "AB".each_char { |c| editor.handle_key(c) }
    editor.handle_key(13) # Enter
    "CD".each_char { |c| editor.handle_key(c) }
    editor.handle_key(27) # Normal mode

    assert_equal 2, editor.buffer.line_count
    assert_equal "AB", editor.buffer.line(0)
    assert_equal "CD", editor.buffer.line(1)

    # After Esc, cursor is at col 1 ("D" position)
    # 'i' enters Insert mode before "D" (col 1)
    editor.handle_key("i")

    assert_equal 1, editor.window.cursor_col

    # Delete "C" (Backspace deletes character before cursor)
    editor.handle_key(127)

    assert_equal "D", editor.buffer.line(1)

    # Backspace at line start -> join lines
    editor.handle_key(127)

    assert_equal 1, editor.buffer.line_count
    assert_equal "ABD", editor.buffer.line(0)
  end

  def test_o_and_O_new_line_insertion
    editor = create_test_editor

    # Initial text
    editor.handle_key("i")
    "Middle".each_char { |c| editor.handle_key(c) }
    editor.handle_key(27)

    # Insert line above with O
    editor.handle_key("O")
    "Top".each_char { |c| editor.handle_key(c) }
    editor.handle_key(27)

    assert_equal "Top", editor.buffer.line(0)
    assert_equal "Middle", editor.buffer.line(1)

    # Move to line below and insert line with o
    editor.handle_key("j") # To Middle line
    editor.handle_key("o")
    "Bottom".each_char { |c| editor.handle_key(c) }
    editor.handle_key(27)

    assert_equal 3, editor.buffer.line_count
    assert_equal "Top", editor.buffer.line(0)
    assert_equal "Middle", editor.buffer.line(1)
    assert_equal "Bottom", editor.buffer.line(2)
  end

  def test_quit_with_unsaved_changes_blocked
    editor = create_test_editor

    # Input text (modified = true)
    editor.handle_key("i")
    editor.handle_key("x")
    editor.handle_key(27)

    # Try to quit with :q
    editor.handle_key(":")
    editor.handle_key("q")
    editor.handle_key(13)

    assert editor.running # Not exited yet
    assert_match(/No write since last change/, editor.message)

    # Force quit with :q!
    editor.handle_key(":")
    editor.handle_key("q")
    editor.handle_key("!")
    editor.handle_key(13)

    refute editor.running
  end
end
