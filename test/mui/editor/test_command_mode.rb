# frozen_string_literal: true

require "test_helper"

class TestEditorCommandMode < Minitest::Test
  class TestEscape < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::COMMAND
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_returns_to_normal_mode
      @editor.command_line.input("w")

      @editor.handle_command_key(27)

      assert_equal Mui::Mode::NORMAL, @editor.mode
      assert_equal "", @editor.command_line.buffer
    end
  end

  class TestBackspace < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::COMMAND
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_on_empty_returns_to_normal
      @editor.handle_command_key(127)

      assert_equal Mui::Mode::NORMAL, @editor.mode
    end

    def test_deletes_character
      @editor.command_line.input("w")
      @editor.command_line.input("q")

      @editor.handle_command_key(127)

      assert_equal "w", @editor.command_line.buffer
      assert_equal Mui::Mode::COMMAND, @editor.mode
    end

    def test_curses_key_backspace_works
      @editor.command_line.input("w")
      @editor.command_line.input("q")

      @editor.handle_command_key(Curses::KEY_BACKSPACE)

      assert_equal "w", @editor.command_line.buffer
    end
  end

  class TestCharacterInput < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::COMMAND
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_single_character
      @editor.handle_command_key("w")

      assert_equal "w", @editor.command_line.buffer
    end

    def test_multiple_characters
      @editor.handle_command_key("w")
      @editor.handle_command_key("q")

      assert_equal "wq", @editor.command_line.buffer
    end

    def test_integer_character
      @editor.handle_command_key(119) # 'w'

      assert_equal "w", @editor.command_line.buffer
    end
  end

  class TestEnter < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @editor.mode = Mui::Mode::COMMAND
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_executes_command_and_returns_to_normal
      @editor.command_line.input("q")
      @editor.buffer.instance_variable_set(:@modified, false)

      @editor.handle_command_key(13)

      assert_equal Mui::Mode::NORMAL, @editor.mode
      refute @editor.running
    end

    def test_curses_key_enter_works
      @editor.command_line.input("q")
      @editor.buffer.instance_variable_set(:@modified, false)

      @editor.handle_command_key(Curses::KEY_ENTER)

      assert_equal Mui::Mode::NORMAL, @editor.mode
      refute @editor.running
    end
  end

  class TestSearchHighlightOnBufferSwitch < Minitest::Test
    include MuiTestHelper

    def setup
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_search_highlight_recalculated_after_edit_command
      Dir.mktmpdir do |dir|
        # Create first file with "hello"
        file1 = File.join(dir, "file1.txt")
        File.write(file1, "hello world\ntest line\n")

        # Create second file without "hello" on first line
        file2 = File.join(dir, "file2.txt")
        File.write(file2, "different content\nhello here\n")

        @editor = create_test_editor(file1)

        # Perform search in first file
        @editor.mode = Mui::Mode::SEARCH_FORWARD
        search_state = @editor.mode_manager.search_state
        search_state.set_pattern("hello", :forward)
        search_state.find_all_matches(@editor.buffer)

        # Verify matches in first file
        assert_equal 1, search_state.matches_for_row(0).size

        # Switch to second file using :e command
        @editor.mode = Mui::Mode::COMMAND
        @editor.command_line.input("e")
        @editor.command_line.input(" ")
        file2.each_char { |c| @editor.command_line.input(c) }
        @editor.handle_command_key(13)

        # Verify matches are recalculated for new buffer
        # Line 0 of file2 has "different content" - no match
        assert_empty search_state.matches_for_row(0)
        # Line 1 of file2 has "hello here" - should have match
        assert_equal 1, search_state.matches_for_row(1).size
      end
    end

    def test_search_pattern_preserved_after_buffer_switch
      Dir.mktmpdir do |dir|
        file1 = File.join(dir, "file1.txt")
        File.write(file1, "original content\n")

        file2 = File.join(dir, "file2.txt")
        File.write(file2, "new content\n")

        @editor = create_test_editor(file1)

        # Set up search pattern
        search_state = @editor.mode_manager.search_state
        search_state.set_pattern("test", :forward)
        search_state.find_all_matches(@editor.buffer)

        # Switch buffer
        @editor.mode = Mui::Mode::COMMAND
        @editor.command_line.input("e")
        @editor.command_line.input(" ")
        file2.each_char { |c| @editor.command_line.input(c) }
        @editor.handle_command_key(13)

        # Pattern should be preserved
        assert search_state.has_pattern?
        assert_equal "test", search_state.pattern
      end
    end
  end
end
