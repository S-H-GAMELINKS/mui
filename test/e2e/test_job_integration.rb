# frozen_string_literal: true

require_relative "test_helper"

class TestJobIntegration < Minitest::Test
  def test_job_manager_exists_in_editor
    runner = ScriptRunner.new
    editor = runner.editor

    assert_instance_of Mui::JobManager, editor.job_manager
  end

  def test_async_job_completes_during_polling
    runner = ScriptRunner.new
    editor = runner.editor

    result_received = false
    editor.job_manager.run_async(on_complete: ->(_job) { result_received = true }) do
      "done"
    end

    # Wait for thread to complete and poll
    sleep 0.05
    editor.job_manager.poll

    assert result_received
  end

  def test_shell_command_execution
    runner = ScriptRunner.new
    editor = runner.editor

    output_captured = nil
    editor.job_manager.run_command("echo test_output", on_complete: lambda { |job|
      output_captured = job.result[:stdout]
    })

    sleep 0.1
    editor.job_manager.poll

    assert_equal "test_output\n", output_captured
  end

  def test_job_failure_handling
    runner = ScriptRunner.new
    editor = runner.editor

    error_caught = nil
    editor.job_manager.run_async(on_complete: lambda { |job|
      error_caught = job.error
    }) do
      raise "intentional error"
    end

    sleep 0.05
    editor.job_manager.poll

    assert_instance_of RuntimeError, error_caught
    assert_equal "intentional error", error_caught.message
  end

  def test_job_cancellation
    runner = ScriptRunner.new
    manager = runner.editor.job_manager

    job = manager.run_async { sleep 10 }

    assert manager.cancel(job.id)
    assert_predicate job, :cancelled?
  end

  def test_command_context_run_async
    runner = ScriptRunner.new
    editor = runner.editor

    # Create a command context
    context = Mui::CommandContext.new(
      editor:,
      buffer: editor.buffer,
      window: editor.window
    )

    job = context.run_async { "async_result" }

    assert_instance_of Mui::Job, job
    refute_nil job.id
  end

  def test_command_context_run_shell_command
    runner = ScriptRunner.new
    editor = runner.editor

    context = Mui::CommandContext.new(
      editor:,
      buffer: editor.buffer,
      window: editor.window
    )

    job = context.run_shell_command("echo hello")

    sleep 0.1
    editor.job_manager.poll

    assert_predicate job, :completed?
    assert_equal "hello\n", job.result[:stdout]
  end

  def test_jobs_running_check
    runner = ScriptRunner.new
    editor = runner.editor

    context = Mui::CommandContext.new(
      editor:,
      buffer: editor.buffer,
      window: editor.window
    )

    refute_predicate context, :jobs_running?

    context.run_async { sleep 0.1 }

    assert_predicate context, :jobs_running?

    sleep 0.15
    editor.job_manager.poll

    refute_predicate context, :jobs_running?
  end
end

class TestScratchBufferIntegration < Minitest::Test
  def test_open_scratch_buffer_creates_window
    runner = ScriptRunner.new
    editor = runner.editor

    initial_window_count = editor.window_manager.window_count

    editor.open_scratch_buffer("[Test]", "Hello\nWorld")

    assert_equal initial_window_count + 1, editor.window_manager.window_count
  end

  def test_scratch_buffer_is_readonly
    runner = ScriptRunner.new
    editor = runner.editor

    editor.open_scratch_buffer("[Test]", "Content")

    # The new window should be active and its buffer should be readonly
    assert_predicate editor.buffer, :readonly?
  end

  def test_scratch_buffer_content
    runner = ScriptRunner.new
    editor = runner.editor

    editor.open_scratch_buffer("[Results]", "Line1\nLine2\nLine3")

    assert_equal "[Results]", editor.buffer.name
    assert_equal 3, editor.buffer.line_count
    assert_equal "Line1", editor.buffer.line(0)
    assert_equal "Line2", editor.buffer.line(1)
    assert_equal "Line3", editor.buffer.line(2)
  end

  def test_command_context_open_scratch_buffer
    runner = ScriptRunner.new
    editor = runner.editor

    context = Mui::CommandContext.new(
      editor:,
      buffer: editor.buffer,
      window: editor.window
    )

    context.open_scratch_buffer("[Output]", "Test content")

    assert_predicate editor.buffer, :readonly?
    assert_equal "[Output]", editor.buffer.name
  end
end

class TestReadonlyProtection < Minitest::Test
  def test_insert_mode_blocked_on_readonly_buffer
    runner = ScriptRunner.new
    editor = runner.editor

    # Set buffer as readonly
    editor.buffer.readonly = true

    # Try to enter insert mode
    runner.type("i")

    # Should still be in normal mode with error message
    runner.assert_mode(Mui::Mode::NORMAL)
    runner.assert_message_contains("readonly")
  end

  def test_append_blocked_on_readonly_buffer
    runner = ScriptRunner.new
    editor = runner.editor

    editor.buffer.readonly = true

    runner.type("a")

    runner.assert_mode(Mui::Mode::NORMAL)
    runner.assert_message_contains("readonly")
  end

  def test_delete_blocked_on_readonly_buffer
    runner = ScriptRunner.new

    # Add some content first
    runner.type("ihello<Esc>")

    # Set readonly
    runner.editor.buffer.readonly = true

    # Try to delete
    runner.type("x")

    # Content should be unchanged
    runner.assert_line(0, "hello")
    runner.assert_message_contains("readonly")
  end

  def test_write_command_blocked_on_readonly_buffer
    runner = ScriptRunner.new
    editor = runner.editor

    editor.buffer.readonly = true

    runner.type(":w<Enter>")

    runner.assert_mode(Mui::Mode::NORMAL)
    runner.assert_message_contains("readonly")
  end

  def test_yank_allowed_on_readonly_buffer
    runner = ScriptRunner.new

    # Add some content
    runner.type("ihello<Esc>")

    # Set readonly
    runner.editor.buffer.readonly = true

    # Move to start and yank
    runner.type("0yw")

    # Yank should work (no error message about readonly)
    # The register should contain the yanked text
    runner.assert_register(nil, "hello", linewise: false)
  end

  def test_navigation_allowed_on_readonly_buffer
    runner = ScriptRunner.new

    # Add some content
    runner.type("ihello world<Esc>")

    # Set readonly
    runner.editor.buffer.readonly = true

    # Navigation should work
    runner.type("0")
    runner.assert_cursor(0, 0)

    runner.type("w")
    runner.assert_cursor(0, 6)

    runner.type("$")
    runner.assert_cursor(0, 10)
  end
end

class TestJobAutocmdEvents < Minitest::Test
  def test_job_completed_event_triggered
    runner = ScriptRunner.new
    editor = runner.editor

    event_triggered = false
    editor.autocmd.register(:JobCompleted) do |kwargs|
      event_triggered = true

      assert_predicate kwargs[:job], :completed?
    end

    editor.job_manager.run_async { "result" }

    sleep 0.05
    editor.job_manager.poll

    assert event_triggered
  end

  def test_job_failed_event_triggered
    runner = ScriptRunner.new
    editor = runner.editor

    event_triggered = false
    editor.autocmd.register(:JobFailed) do |kwargs|
      event_triggered = true

      assert_predicate kwargs[:job], :failed?
    end

    editor.job_manager.run_async { raise "error" }

    sleep 0.05
    editor.job_manager.poll

    assert event_triggered
  end
end
