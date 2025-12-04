# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestEditorExecuteCommand < Minitest::Test
  class TestQuit < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_with_unsaved_changes_shows_message
      @editor.buffer.insert_char(0, 0, "x")
      @editor.command_line.input("q")

      @editor.execute_command

      assert @editor.running
      assert_match(/No write since last change/, @editor.message)
    end

    def test_without_changes_exits
      @editor.buffer.instance_variable_set(:@modified, false)
      @editor.command_line.input("q")

      @editor.execute_command

      refute @editor.running
    end
  end

  class TestForceQuit < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_exits_regardless_of_changes
      @editor.buffer.insert_char(0, 0, "x")
      @editor.command_line.input("q")
      @editor.command_line.input("!")

      @editor.execute_command

      refute @editor.running
    end
  end

  class TestWrite < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_without_filename_shows_error
      @editor.command_line.input("w")

      @editor.execute_command

      assert_equal "No file name", @editor.message
    end

    def test_saves_file
      Tempfile.create(["test", ".txt"]) do |f|
        @editor.buffer.load(f.path)
        @editor.buffer.insert_char(0, 0, "X")
        @editor.command_line.input("w")

        @editor.execute_command

        assert_match(/written/, @editor.message)
        refute @editor.buffer.modified
        assert_equal "X\n", File.read(f.path)
      end
    end

    def test_as_saves_to_new_file
      Tempfile.create(["new", ".txt"]) do |f|
        path = f.path
        @editor.buffer.insert_char(0, 0, "Z")
        "w #{path}".each_char { |c| @editor.command_line.input(c) }

        @editor.execute_command

        assert_match(/written/, @editor.message)
        assert_equal path, @editor.buffer.name
        assert_equal "Z\n", File.read(path)
      end
    end
  end

  class TestWriteQuit < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_saves_and_exits
      Tempfile.create(["test", ".txt"]) do |f|
        @editor.buffer.load(f.path)
        @editor.buffer.insert_char(0, 0, "Y")
        @editor.command_line.input("w")
        @editor.command_line.input("q")

        @editor.execute_command

        refute @editor.running
        refute @editor.buffer.modified
        assert_equal "Y\n", File.read(f.path)
      end
    end
  end

  class TestUnknownCommand < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_shows_error
      "xyz".each_char { |c| @editor.command_line.input(c) }

      @editor.execute_command

      assert_match(/Unknown command: xyz/, @editor.message)
    end
  end
end
