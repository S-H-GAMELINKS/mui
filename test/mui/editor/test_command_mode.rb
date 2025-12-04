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
end
