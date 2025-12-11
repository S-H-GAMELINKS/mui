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

    # Run an interactive command that needs terminal access (e.g., fzf)
    # Suspends Curses UI, runs command, resumes UI
    def run_interactive_command(cmd)
      require "tempfile"

      @editor.suspend_ui do
        output_file = Tempfile.new("mui_interactive")
        begin
          # Use shell redirection to capture output while keeping stdin/stderr connected to terminal
          # rubocop:disable Style/SpecialGlobalVars
          success = system("#{cmd} > #{output_file.path}")
          status = $?
          # rubocop:enable Style/SpecialGlobalVars
          exit_status = status&.exitstatus || 1
          {
            stdout: File.read(output_file.path),
            stderr: "",
            exit_status:,
            success: success == true && exit_status.zero?
          }
        ensure
          output_file.close
          output_file.unlink
        end
      end
    end

    # Check if a command exists in PATH
    def command_exists?(cmd)
      system("which #{cmd} > /dev/null 2>&1")
    end
  end
end
