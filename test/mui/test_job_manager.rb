# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/mui/job"
require_relative "../../lib/mui/job_manager"

class TestJobManager < Minitest::Test
  def setup
    @manager = Mui::JobManager.new
  end

  def test_run_async_returns_job
    job = @manager.run_async { "result" }

    assert_instance_of Mui::Job, job
    refute_nil job.id
  end

  def test_run_async_executes_in_thread
    executed = false
    @manager.run_async { executed = true }

    sleep 0.05 # Wait for thread

    assert executed
  end

  def test_poll_returns_completed_jobs
    callback_called = false
    @manager.run_async(on_complete: ->(_job) { callback_called = true }) { "result" }

    sleep 0.05
    processed = @manager.poll

    assert callback_called
    assert_equal 1, processed.size
  end

  def test_poll_invokes_callback_with_job
    received_job = nil
    @manager.run_async(on_complete: ->(job) { received_job = job }) { "result" }

    sleep 0.05
    @manager.poll

    refute_nil received_job
    assert_predicate received_job, :completed?
    assert_equal "result", received_job.result
  end

  def test_run_command_executes_shell_command
    job = @manager.run_command("echo hello")

    sleep 0.1
    @manager.poll

    assert_predicate job, :completed?
    assert_equal "hello\n", job.result[:stdout]
    assert job.result[:success]
    assert_equal 0, job.result[:exit_status]
  end

  def test_run_command_captures_stderr
    job = @manager.run_command("ls /nonexistent_path_12345 2>&1 || true")

    sleep 0.1
    @manager.poll

    assert_predicate job, :completed?
  end

  def test_run_command_with_array_argument
    job = @manager.run_command(["echo", "hello world"])

    sleep 0.1
    @manager.poll

    assert_predicate job, :completed?
    assert_equal "hello world\n", job.result[:stdout]
  end

  def test_cancel_job
    job = @manager.run_async { sleep 10 }
    result = @manager.cancel(job.id)

    assert result
  end

  def test_cancel_nonexistent_job_returns_false
    result = @manager.cancel(9999)

    refute result
  end

  def test_busy_when_jobs_running
    refute_predicate @manager, :busy?

    @manager.run_async { sleep 0.1 }

    assert_predicate @manager, :busy?

    sleep 0.15
    @manager.poll

    refute_predicate @manager, :busy?
  end

  def test_active_count
    assert_equal 0, @manager.active_count

    @manager.run_async { sleep 0.1 }
    @manager.run_async { sleep 0.1 }

    # Give threads time to start
    sleep 0.01

    assert_equal 2, @manager.active_count

    sleep 0.15
    @manager.poll

    assert_equal 0, @manager.active_count
  end

  def test_job_lookup_by_id
    job = @manager.run_async { "result" }
    found = @manager.job(job.id)

    assert_equal job.id, found.id
  end

  def test_callback_exception_does_not_propagate
    @manager.run_async(on_complete: ->(_job) { raise "callback error" }) { "result" }

    sleep 0.05
    # Should not raise - suppress warning output during test
    original_stderr = $stderr
    $stderr = StringIO.new
    begin
      @manager.poll
    ensure
      $stderr = original_stderr
    end
  end

  def test_job_removed_after_poll
    job = @manager.run_async { "result" }

    sleep 0.05
    @manager.poll

    assert_nil @manager.job(job.id)
  end

  def test_multiple_jobs_concurrent
    results = []
    mutex = Mutex.new

    5.times do |i|
      @manager.run_async(on_complete: ->(job) { mutex.synchronize { results << job.result } }) { i * 2 }
    end

    sleep 0.1
    @manager.poll

    assert_equal 5, results.size
    assert_equal [0, 2, 4, 6, 8].sort, results.sort
  end

  def test_unique_job_ids
    ids = []
    10.times do
      job = @manager.run_async { "result" }
      ids << job.id
    end

    assert_equal ids.uniq.size, ids.size
  end
end

class TestJobManagerWithAutocmd < Minitest::Test
  def setup
    @autocmd = MockAutocmd.new
    @manager = Mui::JobManager.new(autocmd: @autocmd)
  end

  def test_triggers_job_completed_event
    @manager.run_async { "result" }

    sleep 0.05
    @manager.poll

    assert_includes @autocmd.triggered_events, :JobCompleted
  end

  def test_triggers_job_failed_event
    @manager.run_async { raise "error" }

    sleep 0.05
    @manager.poll

    assert_includes @autocmd.triggered_events, :JobFailed
  end
end

# Mock Autocmd for testing
class MockAutocmd
  attr_reader :triggered_events

  def initialize
    @triggered_events = []
  end

  def trigger(event, **_kwargs)
    @triggered_events << event
  end
end
