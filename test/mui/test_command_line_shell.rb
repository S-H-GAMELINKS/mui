# frozen_string_literal: true

require "test_helper"

class TestCommandLineShell < Minitest::Test
  class TestShellCommandParsing < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_shell_command_basic
      "!ls".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal "ls", result[:command]
    end

    def test_shell_command_with_arguments
      "!echo hello world".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal "echo hello world", result[:command]
    end

    def test_shell_command_with_flags
      "!ls -la".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal "ls -la", result[:command]
    end

    def test_shell_command_with_pipe
      "!ls | grep rb".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal "ls | grep rb", result[:command]
    end

    def test_shell_command_with_redirect
      "!echo hello > test.txt".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal "echo hello > test.txt", result[:command]
    end

    def test_shell_command_empty_returns_error
      "!".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command_error, result[:action]
      assert_includes result[:message], "Argument required"
    end

    def test_shell_command_whitespace_only_returns_error
      "!   ".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command_error, result[:action]
      assert_includes result[:message], "Argument required"
    end

    def test_shell_command_strips_leading_spaces
      "!  ls -la".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal "ls -la", result[:command]
    end

    def test_shell_command_strips_trailing_spaces
      "!ls -la  ".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal "ls -la", result[:command]
    end

    def test_shell_command_clears_buffer_after_execute
      "!echo test".each_char { |c| @command_line.input(c) }

      @command_line.execute

      assert_equal "", @command_line.buffer
    end

    def test_shell_command_with_path
      "!cat /etc/passwd".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal "cat /etc/passwd", result[:command]
    end

    def test_shell_command_with_environment_variable
      "!echo $HOME".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal "echo $HOME", result[:command]
    end

    def test_shell_command_with_subshell
      "!echo $(date)".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal "echo $(date)", result[:command]
    end

    def test_shell_command_with_quotes
      '!echo "hello world"'.each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :shell_command, result[:action]
      assert_equal 'echo "hello world"', result[:command]
    end
  end
end
