# frozen_string_literal: true

module Mui
  # Represents a single asynchronous job
  class Job
    # Job status constants
    module Status
      PENDING   = :pending
      RUNNING   = :running
      COMPLETED = :completed
      FAILED    = :failed
      CANCELLED = :cancelled
    end

    attr_reader :id, :status, :result, :error

    def initialize(id, &block)
      @id = id
      @block = block
      @status = Status::PENDING
      @result = nil
      @error = nil
      @cancelled = false
      @mutex = Mutex.new
    end

    def run
      @mutex.synchronize do
        return if @cancelled

        @status = Status::RUNNING
      end

      begin
        @result = @block.call
        @mutex.synchronize do
          @status = @cancelled ? Status::CANCELLED : Status::COMPLETED
        end
      rescue StandardError => e
        @mutex.synchronize do
          @error = e
          @status = Status::FAILED
        end
      end
    end

    def cancel
      @mutex.synchronize do
        return false if @status == Status::COMPLETED || @status == Status::FAILED

        @cancelled = true
        @status = Status::CANCELLED if @status == Status::PENDING
        true
      end
    end

    def pending?
      @status == Status::PENDING
    end

    def running?
      @status == Status::RUNNING
    end

    def completed?
      @status == Status::COMPLETED
    end

    def failed?
      @status == Status::FAILED
    end

    def cancelled?
      @status == Status::CANCELLED
    end

    def finished?
      completed? || failed? || cancelled?
    end
  end
end
