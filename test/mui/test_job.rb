# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/mui/job"

class TestJob < Minitest::Test
  def test_initial_status_is_pending
    job = Mui::Job.new(1) { "result" }

    assert job.pending?
    refute job.running?
    refute job.completed?
    refute job.failed?
    refute job.cancelled?
    refute job.finished?
  end

  def test_run_changes_status_to_completed
    job = Mui::Job.new(1) { "result" }
    job.run

    assert job.completed?
    assert job.finished?
    assert_equal "result", job.result
    assert_nil job.error
  end

  def test_run_captures_exceptions
    job = Mui::Job.new(1) { raise "test error" }
    job.run

    assert job.failed?
    assert job.finished?
    assert_instance_of RuntimeError, job.error
    assert_equal "test error", job.error.message
    assert_nil job.result
  end

  def test_cancel_pending_job
    job = Mui::Job.new(1) { "result" }
    result = job.cancel

    assert result
    assert job.cancelled?
    assert job.finished?
  end

  def test_cancel_completed_job_fails
    job = Mui::Job.new(1) { "result" }
    job.run
    result = job.cancel

    refute result
    assert job.completed?
  end

  def test_cancel_failed_job_fails
    job = Mui::Job.new(1) { raise "error" }
    job.run
    result = job.cancel

    refute result
    assert job.failed?
  end

  def test_cancelled_job_does_not_run
    job = Mui::Job.new(1) { "result" }
    job.cancel
    job.run

    assert job.cancelled?
    assert_nil job.result
  end

  def test_job_id
    job = Mui::Job.new(42) { "result" }

    assert_equal 42, job.id
  end

  def test_running_status_during_execution
    status_during_run = nil
    job = Mui::Job.new(1) do
      status_during_run = job.running?
      "result"
    end
    job.run

    assert status_during_run
    assert job.completed?
  end

  def test_thread_safety_of_status_changes
    jobs = Array.new(10) do |i|
      Mui::Job.new(i) do
        sleep 0.001
        i
      end
    end
    threads = jobs.map { |job| Thread.new { job.run } }

    threads.each(&:join)

    jobs.each_with_index do |job, i|
      assert job.completed?, "Job #{i} should be completed"
      assert_equal i, job.result
    end
  end
end
