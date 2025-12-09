# frozen_string_literal: true

module Mui
  # Provides plugin access to editor internals
  class CommandContext
    attr_reader :buffer, :window, :editor

    def initialize(editor:, buffer:, window:)
      @editor = editor
      @buffer = buffer
      @window = window
    end

    def cursor
      { line: @buffer.cursor_y, col: @buffer.cursor_x }
    end

    def current_line
      @buffer.current_line
    end

    def insert(text)
      @buffer.insert_text(text)
    end

    def set_message(msg)
      @editor.message = msg
    end

    def quit
      @editor.running = false
    end

    def run_command(name, *)
      @editor.command_registry.execute(name, self, *)
    end

    def run_async(on_complete: nil, &)
      @editor.job_manager.run_async(on_complete:, &)
    end

    def run_shell_command(cmd, on_complete: nil)
      @editor.job_manager.run_command(cmd, on_complete:)
    end

    def jobs_running?
      @editor.job_manager.busy?
    end

    def cancel_job(id)
      @editor.job_manager.cancel(id)
    end

    def open_scratch_buffer(name, content)
      @editor.open_scratch_buffer(name, content)
    end
  end
end
