# frozen_string_literal: true

require "test_helper"

class TestCommandModeShell < Minitest::Test
  class TestShellCommandError < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_empty_shell_command_shows_error
      "!".each_char { |c| @command_line.input(c) }

      result = @handler.handle(13)

      assert_equal Mui::Mode::NORMAL, result.mode
      assert_includes result.message, "Argument required"
    end

    def test_whitespace_only_shell_command_shows_error
      "!   ".each_char { |c| @command_line.input(c) }

      result = @handler.handle(13)

      assert_equal Mui::Mode::NORMAL, result.mode
      assert_includes result.message, "Argument required"
    end
  end

  class TestShellCommandWithoutEditor < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @mode_manager.editor = nil
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_shell_command_without_editor_shows_error
      "!echo test".each_char { |c| @command_line.input(c) }

      result = @handler.handle(13)

      assert_equal Mui::Mode::NORMAL, result.mode
      assert_includes result.message, "not available"
    end
  end

  class TestShellCommandExecution < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @buffer = @editor.buffer
      @window = @editor.window
      @command_line = Mui::CommandLine.new
      @mode_manager = @editor.instance_variable_get(:@mode_manager)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_shell_command_returns_running_message
      "!echo test".each_char { |c| @command_line.input(c) }

      result = @handler.handle(13)

      assert_equal Mui::Mode::NORMAL, result.mode
      assert_includes result.message, "Running:"
      assert_includes result.message, "echo test"
    end

    def test_shell_command_creates_async_job
      "!echo hello".each_char { |c| @command_line.input(c) }

      @handler.handle(13)

      assert_predicate @editor.job_manager, :busy?
    end

    def test_shell_command_creates_scratch_buffer_on_complete
      "!echo hello".each_char { |c| @command_line.input(c) }
      @handler.handle(13)

      # Wait for async job to complete
      sleep 0.1
      @editor.job_manager.poll

      # Should have created a new window with scratch buffer
      assert_equal 2, @editor.window_manager.window_count
      assert_predicate @editor.buffer, :readonly?
      assert_equal "[Shell Output]", @editor.buffer.name
    end

    def test_shell_command_output_contains_command
      "!echo hello".each_char { |c| @command_line.input(c) }
      @handler.handle(13)

      sleep 0.1
      @editor.job_manager.poll

      assert_includes @editor.buffer.line(0), "echo hello"
    end

    def test_shell_command_output_contains_stdout
      "!echo hello_world".each_char { |c| @command_line.input(c) }
      @handler.handle(13)

      sleep 0.1
      @editor.job_manager.poll

      lines = (0...@editor.buffer.line_count).map { |i| @editor.buffer.line(i) }

      assert(lines.any? { |l| l.include?("hello_world") })
    end

    def test_shell_command_with_arguments
      "!echo foo bar baz".each_char { |c| @command_line.input(c) }
      @handler.handle(13)

      sleep 0.1
      @editor.job_manager.poll

      lines = (0...@editor.buffer.line_count).map { |i| @editor.buffer.line(i) }

      assert(lines.any? { |l| l.include?("foo bar baz") })
    end

    def test_shell_command_with_pipe
      "!echo pipe_test | cat".each_char { |c| @command_line.input(c) }
      @handler.handle(13)

      sleep 0.1
      @editor.job_manager.poll

      lines = (0...@editor.buffer.line_count).map { |i| @editor.buffer.line(i) }

      assert(lines.any? { |l| l.include?("pipe_test") })
    end
  end

  class TestShellCommandOutput < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @buffer = @editor.buffer
      @window = @editor.window
      @command_line = Mui::CommandLine.new
      @mode_manager = @editor.instance_variable_get(:@mode_manager)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_shell_command_failure_shows_exit_status
      "!exit 42".each_char { |c| @command_line.input(c) }
      @handler.handle(13)

      sleep 0.1
      @editor.job_manager.poll

      lines = (0...@editor.buffer.line_count).map { |i| @editor.buffer.line(i) }
      output = lines.join("\n")

      assert_includes output, "42"
      assert_includes output, "Exit status"
    end

    def test_shell_command_stderr_display
      # Use a command that outputs to stderr
      "!echo error_output >&2".each_char { |c| @command_line.input(c) }
      @handler.handle(13)

      sleep 0.1
      @editor.job_manager.poll

      lines = (0...@editor.buffer.line_count).map { |i| @editor.buffer.line(i) }
      output = lines.join("\n")

      assert_includes output, "error_output"
      assert_includes output, "[stderr]"
    end

    def test_shell_command_success_no_exit_status
      "!echo success".each_char { |c| @command_line.input(c) }
      @handler.handle(13)

      sleep 0.1
      @editor.job_manager.poll

      lines = (0...@editor.buffer.line_count).map { |i| @editor.buffer.line(i) }
      output = lines.join("\n")

      refute_includes output, "Exit status"
    end
  end

  class TestShellCommandScratchBufferUpdate < Minitest::Test
    include MuiTestHelper

    def setup
      @editor = create_test_editor
      @buffer = @editor.buffer
      @window = @editor.window
      @command_line = Mui::CommandLine.new
      @mode_manager = @editor.instance_variable_get(:@mode_manager)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_second_shell_command_updates_existing_buffer
      # Run first command
      "!echo first".each_char { |c| @command_line.input(c) }
      @handler.handle(13)
      sleep 0.1
      @editor.job_manager.poll

      window_count_after_first = @editor.window_manager.window_count

      # Run second command
      "!echo second".each_char { |c| @command_line.input(c) }
      @handler.handle(13)
      sleep 0.1
      @editor.job_manager.poll

      # Window count should be the same (reused existing buffer)
      assert_equal window_count_after_first, @editor.window_manager.window_count

      # Content should be updated to second command's output
      lines = (0...@editor.buffer.line_count).map { |i| @editor.buffer.line(i) }
      output = lines.join("\n")

      assert_includes output, "second"
    end
  end

  class TestBuildShellOutput < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_build_output_with_stdout_only
      job = MockJob.new(
        stdout: "output\n",
        stderr: "",
        exit_status: 0,
        success: true
      )

      output = @handler.send(:build_shell_output, job, "echo output")

      assert_includes output, "$ echo output"
      assert_includes output, "output"
      refute_includes output, "[stderr]"
      refute_includes output, "Exit status"
    end

    def test_build_output_with_stderr
      job = MockJob.new(
        stdout: "",
        stderr: "error\n",
        exit_status: 0,
        success: true
      )

      output = @handler.send(:build_shell_output, job, "cmd")

      assert_includes output, "[stderr]"
      assert_includes output, "error"
    end

    def test_build_output_with_failure
      job = MockJob.new(
        stdout: "",
        stderr: "",
        exit_status: 1,
        success: false
      )

      output = @handler.send(:build_shell_output, job, "exit 1")

      assert_includes output, "[Exit status: 1]"
    end

    def test_build_output_with_both_stdout_and_stderr
      job = MockJob.new(
        stdout: "stdout\n",
        stderr: "stderr\n",
        exit_status: 0,
        success: true
      )

      output = @handler.send(:build_shell_output, job, "cmd")

      assert_includes output, "stdout"
      assert_includes output, "[stderr]"
      assert_includes output, "stderr"
    end
  end

  # Mock job class for testing build_shell_output
  class MockJob
    attr_reader :result

    def initialize(stdout:, stderr:, exit_status:, success:)
      @result = {
        stdout:,
        stderr:,
        exit_status:,
        success:
      }
    end
  end
end
