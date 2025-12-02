# frozen_string_literal: true

require "test_helper"

class TestKeyHandlerCommandMode < Minitest::Test
  class TestEscape < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_returns_normal_mode
      result = @handler.handle(27)

      assert_equal Mui::Mode::NORMAL, result[:mode]
    end

    def test_clears_command_line
      @command_line.input("w")
      @command_line.input("q")

      @handler.handle(27)

      assert_equal "", @command_line.buffer
    end
  end

  class TestBackspace < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_deletes_last_char
      @command_line.input("w")
      @command_line.input("q")

      @handler.handle(127)

      assert_equal "w", @command_line.buffer
    end

    def test_curses_backspace_works
      @command_line.input("w")

      @handler.handle(Curses::KEY_BACKSPACE)

      assert_equal "", @command_line.buffer
    end

    def test_empty_buffer_returns_normal_mode
      result = @handler.handle(127)

      assert_equal Mui::Mode::NORMAL, result[:mode]
    end

    def test_non_empty_buffer_stays_in_command_mode
      @command_line.input("w")

      result = @handler.handle(127)

      assert_nil result[:mode]
    end
  end

  class TestCharacterInput < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_inserts_string_character
      @handler.handle("w")

      assert_equal "w", @command_line.buffer
    end

    def test_inserts_integer_character
      @handler.handle(113) # 'q'

      assert_equal "q", @command_line.buffer
    end

    def test_ignores_non_printable_integer
      @handler.handle(1) # Ctrl+A

      assert_equal "", @command_line.buffer
    end

    def test_multiple_characters
      @handler.handle("w")
      @handler.handle("q")

      assert_equal "wq", @command_line.buffer
    end
  end

  class TestEnter < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_returns_normal_mode
      @command_line.input("w")

      result = @handler.handle(13)

      assert_equal Mui::Mode::NORMAL, result[:mode]
    end

    def test_curses_enter_works
      @command_line.input("w")

      result = @handler.handle(Curses::KEY_ENTER)

      assert_equal Mui::Mode::NORMAL, result[:mode]
    end

    def test_clears_command_line
      @command_line.input("w")

      @handler.handle(13)

      assert_equal "", @command_line.buffer
    end
  end

  class TestWriteCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_no_file_name_shows_error
      @command_line.input("w")

      result = @handler.handle(13)

      assert_equal "No file name", result[:message]
    end

    def test_with_file_name_shows_written
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.txt")
        @buffer.save(path)

        @command_line.input("w")
        result = @handler.handle(13)

        assert_match(/written/, result[:message])
      end
    end
  end

  class TestQuitCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_unmodified_buffer_quits
      @command_line.input("q")

      result = @handler.handle(13)

      assert result[:quit]
    end

    def test_modified_buffer_shows_warning
      @buffer.insert_char(0, 0, "a")

      @command_line.input("q")
      result = @handler.handle(13)

      assert_match(/No write since last change/, result[:message])
      refute result[:quit]
    end
  end

  class TestForceQuitCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_force_quits_even_with_modified_buffer
      @buffer.insert_char(0, 0, "a")

      @command_line.input("q")
      @command_line.input("!")
      result = @handler.handle(13)

      assert result[:quit]
    end
  end

  class TestWriteQuitCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_saves_and_quits
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.txt")
        @buffer.save(path)

        @command_line.input("w")
        @command_line.input("q")
        result = @handler.handle(13)

        assert result[:quit]
        assert_match(/written/, result[:message])
      end
    end

    def test_no_file_name_shows_error
      @command_line.input("w")
      @command_line.input("q")
      result = @handler.handle(13)

      assert_equal "No file name", result[:message]
      refute result[:quit]
    end
  end

  class TestWriteAsCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_saves_to_specified_path
      Dir.mktmpdir do |dir|
        path = File.join(dir, "output.txt")

        @command_line.input("w")
        @command_line.input(" ")
        @command_line.input(path)
        result = @handler.handle(13)

        assert_match(/written/, result[:message])
        assert_equal "hello\n", File.read(path)
      end
    end
  end

  class TestUnknownCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_shows_unknown_command_message
      @command_line.input("x")
      @command_line.input("y")
      @command_line.input("z")
      result = @handler.handle(13)

      assert_match(/Unknown command: xyz/, result[:message])
    end
  end

  class TestReturnValue < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @handler = Mui::KeyHandler::CommandMode.new(@window, @buffer, @command_line)
    end

    def test_escape_returns_normal_mode
      result = @handler.handle(27)

      assert_equal Mui::Mode::NORMAL, result[:mode]
    end

    def test_character_input_returns_nil_mode
      result = @handler.handle("w")

      assert_nil result[:mode]
    end
  end
end
