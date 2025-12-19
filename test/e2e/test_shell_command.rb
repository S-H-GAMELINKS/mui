# frozen_string_literal: true

require_relative "test_helper"

class TestShellCommand < Minitest::Test
  class TestBasicShellCommand < Minitest::Test
    def test_shell_command_returns_running_message
      runner = ScriptRunner.new
      runner.type(":!echo hello<Enter>")

      runner.assert_mode(Mui::Mode::NORMAL)
      runner.assert_message_contains("Running:")
    end

    def test_shell_command_creates_job
      runner = ScriptRunner.new
      runner.type(":!echo hello<Enter>")

      assert_predicate runner.editor.job_manager, :busy?
    end

    def test_shell_command_creates_scratch_buffer
      runner = ScriptRunner.new
      runner.type(":!echo hello<Enter>")

      # Wait for async job to complete
      sleep 0.1
      runner.editor.job_manager.poll

      runner.assert_window_count(2)

      assert_predicate runner.editor.buffer, :readonly?
      assert_equal "[Shell Output]", runner.editor.buffer.name
    end

    def test_shell_command_output_contains_command
      runner = ScriptRunner.new
      runner.type(":!echo test_output<Enter>")

      sleep 0.1
      runner.editor.job_manager.poll

      lines = (0...runner.editor.buffer.line_count).map { |i| runner.editor.buffer.line(i) }

      assert(lines.any? { |l| l.include?("echo test_output") })
    end

    def test_shell_command_output_contains_stdout
      runner = ScriptRunner.new
      runner.type(":!echo test_output<Enter>")

      sleep 0.1
      runner.editor.job_manager.poll

      lines = (0...runner.editor.buffer.line_count).map { |i| runner.editor.buffer.line(i) }

      assert(lines.any? { |l| l.include?("test_output") })
    end
  end

  class TestShellCommandWithArguments < Minitest::Test
    def test_shell_command_with_multiple_arguments
      runner = ScriptRunner.new
      runner.type(":!echo foo bar baz<Enter>")

      sleep 0.1
      runner.editor.job_manager.poll

      lines = (0...runner.editor.buffer.line_count).map { |i| runner.editor.buffer.line(i) }

      assert(lines.any? { |l| l.include?("foo bar baz") })
    end

    def test_shell_command_with_pipe
      runner = ScriptRunner.new
      runner.type(":!echo pipe_test | cat<Enter>")

      sleep 0.1
      runner.editor.job_manager.poll

      lines = (0...runner.editor.buffer.line_count).map { |i| runner.editor.buffer.line(i) }

      assert(lines.any? { |l| l.include?("pipe_test") })
    end

    def test_shell_command_with_flags
      runner = ScriptRunner.new
      runner.type(":!echo -n no_newline<Enter>")

      sleep 0.1
      runner.editor.job_manager.poll

      lines = (0...runner.editor.buffer.line_count).map { |i| runner.editor.buffer.line(i) }

      assert(lines.any? { |l| l.include?("no_newline") })
    end
  end

  class TestShellCommandErrors < Minitest::Test
    def test_empty_shell_command_shows_error
      runner = ScriptRunner.new
      runner.type(":!<Enter>")

      runner.assert_mode(Mui::Mode::NORMAL)
      runner.assert_message_contains("Argument required")
      runner.assert_window_count(1) # No new window created
    end

    def test_whitespace_only_shell_command_shows_error
      runner = ScriptRunner.new
      runner.type(":!   <Enter>")

      runner.assert_mode(Mui::Mode::NORMAL)
      runner.assert_message_contains("Argument required")
    end

    def test_shell_command_failure_shows_exit_status
      runner = ScriptRunner.new
      runner.type(":!exit 42<Enter>")

      sleep 0.1
      runner.editor.job_manager.poll

      lines = (0...runner.editor.buffer.line_count).map { |i| runner.editor.buffer.line(i) }
      output = lines.join("\n")

      assert_includes output, "42"
      assert_includes output, "Exit status"
    end

    def test_shell_command_stderr_display
      runner = ScriptRunner.new
      runner.type(":!echo error_msg >&2<Enter>")

      sleep 0.1
      runner.editor.job_manager.poll

      lines = (0...runner.editor.buffer.line_count).map { |i| runner.editor.buffer.line(i) }
      output = lines.join("\n")

      assert_includes output, "error_msg"
      assert_includes output, "[stderr]"
    end
  end

  class TestShellCommandNavigation < Minitest::Test
    def test_scratch_buffer_navigation
      runner = ScriptRunner.new
      runner.type(":!echo line1<Enter>")

      sleep 0.1
      runner.editor.job_manager.poll

      # Should be able to navigate in scratch buffer
      runner.type("j")
      runner.type("k")

      # No crash, still in normal mode
      runner.assert_mode(Mui::Mode::NORMAL)
    end

    def test_scratch_buffer_close
      runner = ScriptRunner.new
      runner.type(":!echo test<Enter>")

      sleep 0.1
      runner.editor.job_manager.poll

      runner.assert_window_count(2)

      # Close scratch buffer window
      runner.type(":close<Enter>")

      runner.assert_window_count(1)
    end

    def test_scratch_buffer_readonly_protection
      runner = ScriptRunner.new
      runner.type(":!echo test<Enter>")

      sleep 0.1
      runner.editor.job_manager.poll

      # Try to write to scratch buffer
      runner.type(":w<Enter>")

      runner.assert_message_contains("readonly")
    end
  end

  class TestMultipleShellCommands < Minitest::Test
    def test_second_shell_command_updates_existing_buffer
      runner = ScriptRunner.new

      # Run first command
      runner.type(":!echo first<Enter>")
      sleep 0.1
      runner.editor.job_manager.poll

      window_count_after_first = runner.editor.window_manager.window_count

      # Run second command
      runner.type(":!echo second<Enter>")
      sleep 0.1
      runner.editor.job_manager.poll

      # Window count should be the same (reused existing buffer)
      assert_equal window_count_after_first, runner.editor.window_manager.window_count

      # Content should be updated to second command's output
      lines = (0...runner.editor.buffer.line_count).map { |i| runner.editor.buffer.line(i) }
      output = lines.join("\n")

      assert_includes output, "second"
    end

    def test_shell_command_after_closing_scratch_buffer
      runner = ScriptRunner.new

      # Run first command
      runner.type(":!echo first<Enter>")
      sleep 0.1
      runner.editor.job_manager.poll

      # Close the scratch buffer
      runner.type(":close<Enter>")
      runner.assert_window_count(1)

      # Run second command
      runner.type(":!echo second<Enter>")
      sleep 0.1
      runner.editor.job_manager.poll

      # Should create a new scratch buffer
      runner.assert_window_count(2)
      lines = (0...runner.editor.buffer.line_count).map { |i| runner.editor.buffer.line(i) }
      output = lines.join("\n")

      assert_includes output, "second"
    end
  end
end
