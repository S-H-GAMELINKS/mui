# frozen_string_literal: true

require "open3"

module Mui
  # Manages asynchronous job execution and result collection
  class JobManager
    def initialize(autocmd: nil)
      @autocmd = autocmd
      @result_queue = Queue.new
      @next_id = 0
      @id_mutex = Mutex.new
      @active_jobs = {}
      @jobs_mutex = Mutex.new
    end

    def run_async(on_complete: nil, &)
      job = create_job(&)

      Thread.new do
        job.run
        @result_queue.push({ job:, callback: on_complete })
      end

      job
    end

    def run_command(cmd, on_complete: nil)
      run_async(on_complete:) do
        stdout, stderr, status = Open3.capture3(*Array(cmd))
        {
          stdout:,
          stderr:,
          exit_status: status.exitstatus,
          success: status.success?
        }
      end
    end

    def poll
      processed = []

      loop do
        entry = @result_queue.pop(true) # non-blocking
        processed << entry
        invoke_callback(entry)
        remove_job(entry[:job].id)
      rescue ThreadError
        break # Queue is empty
      end

      processed
    end

    def job(id)
      @jobs_mutex.synchronize { @active_jobs[id] }
    end

    def cancel(id)
      job = job(id)
      return false unless job

      job.cancel
    end

    def active_count
      @jobs_mutex.synchronize { @active_jobs.values.count { |j| !j.finished? } }
    end

    def busy?
      active_count.positive?
    end

    private

    def create_job(&)
      id = generate_id
      job = Job.new(id, &)
      @jobs_mutex.synchronize { @active_jobs[id] = job }
      job
    end

    def generate_id
      @id_mutex.synchronize do
        @next_id += 1
      end
    end

    def remove_job(id)
      @jobs_mutex.synchronize { @active_jobs.delete(id) }
    end

    def invoke_callback(entry)
      entry[:callback]&.call(entry[:job])
      trigger_autocmd_event(entry[:job])
    rescue StandardError => e
      warn "Job callback error: #{e.message}"
      warn e.backtrace.first(5).join("\n")
    end

    def trigger_autocmd_event(job)
      return unless @autocmd

      event = case job.status
              when Job::Status::COMPLETED then :JobCompleted
              when Job::Status::FAILED then :JobFailed
              when Job::Status::CANCELLED then :JobCancelled
              end

      @autocmd.trigger(event, job:) if event
    end
  end
end
