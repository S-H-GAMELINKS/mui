# frozen_string_literal: true

require_relative "test_helper"
require "tempfile"

class TestE2EFileEditing < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  def test_basic_file_editing
    # Scenario: Open existing file -> Edit -> Save
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("Hello\nWorld")
      f.flush

      runner = ScriptRunner.new(f.path)

      runner
        .type("j")         # Move to line 2
        .assert_cursor(1, 0)
        .type("llll")      # Move toward end of line (4 times)
        .type("a")         # Append mode
        .type("!")         # Add "!"
        .type("<Esc>")     # Normal mode
        .assert_mode(Mui::Mode::NORMAL)
        .assert_line(1, "World!")
        .type(":w<Enter>") # Save
        .assert_message_contains("written")
        .assert_modified(false)

      # Verify file was actually saved
      assert_equal "Hello\nWorld!\n", File.read(f.path)
    end
  end

  def test_new_file_creation
    # Scenario: Create new -> Input text -> Save as -> Quit
    Tempfile.create(["new", ".txt"]) do |f|
      path = f.path
      File.delete(path) # Delete to simulate new file creation

      runner = ScriptRunner.new

      runner
        .type("i")                  # Insert mode
        .type("Line 1")
        .type("<Enter>")            # New line
        .type("Line 2")
        .type("<Esc>")              # Normal mode
        .assert_line_count(2)
        .assert_line(0, "Line 1")
        .assert_line(1, "Line 2")
        .type(":w #{path}<Enter>")  # Save as
        .assert_message_contains("written")
        .type(":q<Enter>")          # Quit
        .assert_running(false)

      # Verify file was created
      assert_path_exists path
      assert_equal "Line 1\nLine 2\n", File.read(path)
    end
  end

  def test_cancel_editing
    # Scenario: Edit -> :q rejected -> :q! force quit
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("Original")
      f.flush

      runner = ScriptRunner.new(f.path)

      # Use 'a' for append mode (append at end of line)
      runner
        .type("$")              # Go to end of line (use l if not implemented)
        .type("lllllll")        # Move toward end of line
        .type("a")              # Append mode
        .type(" Modified")      # Add text
        .type("<Esc>")          # Normal mode
        .assert_modified(true)
        .type(":q<Enter>")      # Try to quit without saving
        .assert_running(true)   # Not exited yet
        .assert_message_contains("No write since last change")
        .type(":q!<Enter>")     # Force quit
        .assert_running(false)

      # File is unchanged
      assert_equal "Original", File.read(f.path)
    end
  end

  def test_write_quit_flow
    # Scenario: Edit -> :wq save and quit
    Tempfile.create(["test", ".txt"]) do |f|
      runner = ScriptRunner.new

      runner
        .type("i")
        .type("Save and quit test")
        .type("<Esc>")
        .type(":w #{f.path}<Enter>")
        .assert_modified(false)

      runner
        .type("a")               # Append to add more
        .type("!")
        .type("<Esc>")
        .assert_modified(true)
        .type(":wq<Enter>")      # Save and quit
        .assert_running(false)

      assert_equal "Save and quit test!\n", File.read(f.path)
    end
  end

  def test_edit_middle_of_file
    # Scenario: Edit middle position of file
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("Line A\nLine B\nLine C")
      f.flush

      runner = ScriptRunner.new(f.path)

      # Delete "B" on line 2 and replace with "MODIFIED"
      runner
        .type("j")           # Go to line 2
        .type("lllll")       # Move to "B" position (5 times l)
        .type("x")           # Delete "B"
        .type("i")           # Insert mode (insert at position after delete)
        .type("MODIFIED")
        .type("<Esc>")
        .type(":w<Enter>")
        .assert_modified(false)

      content = File.read(f.path)

      assert_includes content, "MODIFIED"
    end
  end

  def test_append_to_empty_file
    # Scenario: Add text to empty file
    Tempfile.create(["empty", ".txt"]) do |f|
      runner = ScriptRunner.new(f.path)

      runner
        .assert_line_count(1)
        .assert_line(0, "")
        .type("i")
        .type("First line of content")
        .type("<Esc>")
        .type(":w<Enter>")

      assert_equal "First line of content\n", File.read(f.path)
    end
  end

  def test_edit_command_reload_file
    # Scenario: Modify file externally -> :e to reload
    Tempfile.create(["test", ".txt"]) do |f|
      f.write("Original content")
      f.flush

      runner = ScriptRunner.new(f.path)

      runner
        .assert_line(0, "Original content")

      # Modify file externally
      File.write(f.path, "Modified externally\n")

      runner
        .type(":e<Enter>")
        .assert_message_contains("File reopened")
        .assert_line(0, "Modified externally")
    end
  end

  def test_edit_command_open_another_file
    # Scenario: Open file -> :e another_file to switch
    Tempfile.create(["first", ".txt"]) do |f1|
      Tempfile.create(["second", ".txt"]) do |f2|
        f1.write("First file")
        f1.flush
        f2.write("Second file")
        f2.flush

        runner = ScriptRunner.new(f1.path)

        runner
          .assert_line(0, "First file")
          .type(":e #{f2.path}<Enter>")
          .assert_message_contains("opened")
          .assert_line(0, "Second file")
      end
    end
  end

  def test_edit_command_open_new_file
    # Scenario: :e nonexistent_file creates new buffer (Vim-compatible)
    Dir.mktmpdir do |dir|
      new_file_path = File.join(dir, "new_file.txt")

      runner = ScriptRunner.new

      runner
        .type(":e #{new_file_path}<Enter>")
        .assert_message_contains("opened")
        .type("i")
        .type("New content")
        .type("<Esc>")
        .type(":w<Enter>")
        .assert_message_contains("written")

      assert_path_exists new_file_path
      assert_equal "New content\n", File.read(new_file_path)
    end
  end

  def test_edit_command_no_filename_on_new_buffer
    # Scenario: :e on new buffer without filename shows error
    runner = ScriptRunner.new

    runner
      .type(":e<Enter>")
      .assert_message_contains("No file name")
  end
end
