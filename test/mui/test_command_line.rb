# frozen_string_literal: true

require "test_helper"

class TestCommandLine < Minitest::Test
  class TestInitialize < Minitest::Test
    def test_buffer_is_empty
      command_line = Mui::CommandLine.new

      assert_equal "", command_line.buffer
    end
  end

  class TestInput < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_appends_single_character
      @command_line.input("w")

      assert_equal "w", @command_line.buffer
    end

    def test_appends_multiple_characters
      @command_line.input("w")
      @command_line.input("q")

      assert_equal "wq", @command_line.buffer
    end
  end

  class TestBackspace < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_removes_last_character
      @command_line.input("w")
      @command_line.input("q")

      @command_line.backspace

      assert_equal "w", @command_line.buffer
    end

    def test_removes_all_characters
      @command_line.input("w")

      @command_line.backspace

      assert_equal "", @command_line.buffer
    end

    def test_does_nothing_when_empty
      @command_line.backspace

      assert_equal "", @command_line.buffer
    end
  end

  class TestClear < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_clears_buffer
      @command_line.input("w")
      @command_line.input("q")

      @command_line.clear

      assert_equal "", @command_line.buffer
    end
  end

  class TestToS < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_returns_colon_when_empty
      assert_equal ":", @command_line.to_s
    end

    def test_returns_colon_with_buffer
      @command_line.input("w")

      assert_equal ":w", @command_line.to_s
    end

    def test_returns_colon_with_multiple_characters
      @command_line.input("w")
      @command_line.input("q")

      assert_equal ":wq", @command_line.to_s
    end
  end

  class TestExecute < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_open_command
      @command_line.input("e")

      result = @command_line.execute

      assert_equal :open, result[:action]
    end

    def test_write_command
      @command_line.input("w")

      result = @command_line.execute

      assert_equal({ action: :write }, result)
      assert_equal "", @command_line.buffer
    end

    def test_quit_command
      @command_line.input("q")

      result = @command_line.execute

      assert_equal({ action: :quit }, result)
    end

    def test_write_quit_command
      @command_line.input("w")
      @command_line.input("q")

      result = @command_line.execute

      assert_equal({ action: :write_quit }, result)
    end

    def test_force_quit_command
      @command_line.input("q")
      @command_line.input("!")

      result = @command_line.execute

      assert_equal({ action: :force_quit }, result)
    end

    def test_open_as_with_filename
      "e test.txt".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :open_as, result[:action]
      assert_equal "test.txt", result[:path]
    end

    def test_write_as_with_filename
      "w test.txt".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :write_as, result[:action]
      assert_equal "test.txt", result[:path]
    end

    def test_write_as_with_full_path
      "w /path/to/file.txt".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :write_as, result[:action]
      assert_equal "/path/to/file.txt", result[:path]
    end

    def test_unknown_command
      "unknown".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :unknown, result[:action]
      assert_equal "unknown", result[:command]
    end

    def test_strips_leading_and_trailing_spaces
      "  w  ".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal({ action: :write }, result)
    end
  end
end
