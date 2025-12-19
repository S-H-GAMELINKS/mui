# frozen_string_literal: true

require_relative "test_helper"

class TestInteractiveCommand < Minitest::Test
  def setup
    Mui.reset_config!
  end

  class TestSuspendUi < TestInteractiveCommand
    def test_suspend_is_called_during_suspend_ui
      runner = ScriptRunner.new
      editor = runner.editor
      adapter = editor.instance_variable_get(:@adapter)

      suspend_called = false
      adapter.define_singleton_method(:suspend) { suspend_called = true }
      adapter.define_singleton_method(:resume) { nil }

      editor.suspend_ui { nil }

      assert suspend_called, "suspend should be called"
    end

    def test_resume_is_called_after_suspend_ui
      runner = ScriptRunner.new
      editor = runner.editor
      adapter = editor.instance_variable_get(:@adapter)

      resume_called = false
      adapter.define_singleton_method(:suspend) { nil }
      adapter.define_singleton_method(:resume) { resume_called = true }

      editor.suspend_ui { nil }

      assert resume_called, "resume should be called"
    end

    def test_suspend_ui_returns_block_result
      runner = ScriptRunner.new
      editor = runner.editor
      adapter = editor.instance_variable_get(:@adapter)

      adapter.define_singleton_method(:suspend) { nil }
      adapter.define_singleton_method(:resume) { nil }

      result = editor.suspend_ui { "test_result" }

      assert_equal "test_result", result
    end

    def test_resume_is_called_even_on_exception
      runner = ScriptRunner.new
      editor = runner.editor
      adapter = editor.instance_variable_get(:@adapter)

      resume_called = false
      adapter.define_singleton_method(:suspend) { nil }
      adapter.define_singleton_method(:resume) { resume_called = true }

      assert_raises(RuntimeError) do
        editor.suspend_ui { raise "test error" }
      end

      assert resume_called, "resume should be called even on exception"
    end

    def test_suspend_and_resume_order
      runner = ScriptRunner.new
      editor = runner.editor
      adapter = editor.instance_variable_get(:@adapter)

      call_order = []
      adapter.define_singleton_method(:suspend) { call_order << :suspend }
      adapter.define_singleton_method(:resume) { call_order << :resume }

      editor.suspend_ui { call_order << :block }

      assert_equal %i[suspend block resume], call_order
    end
  end

  class TestCommandContextInteractive < TestInteractiveCommand
    def test_run_interactive_command_returns_hash
      runner = ScriptRunner.new
      editor = runner.editor
      adapter = editor.instance_variable_get(:@adapter)

      adapter.define_singleton_method(:suspend) { nil }
      adapter.define_singleton_method(:resume) { nil }

      context = Mui::CommandContext.new(
        editor:,
        buffer: editor.buffer,
        window: editor.window
      )

      result = context.run_interactive_command("echo hello")

      assert_kind_of Hash, result
      assert result.key?(:stdout)
      assert result.key?(:stderr)
      assert result.key?(:exit_status)
      assert result.key?(:success)
    end

    def test_run_interactive_command_captures_stdout
      runner = ScriptRunner.new
      editor = runner.editor
      adapter = editor.instance_variable_get(:@adapter)

      adapter.define_singleton_method(:suspend) { nil }
      adapter.define_singleton_method(:resume) { nil }

      context = Mui::CommandContext.new(
        editor:,
        buffer: editor.buffer,
        window: editor.window
      )

      result = context.run_interactive_command("echo hello")

      assert_equal "hello\n", result[:stdout]
      assert result[:success]
      assert_equal 0, result[:exit_status]
    end

    def test_run_interactive_command_handles_failure
      runner = ScriptRunner.new
      editor = runner.editor
      adapter = editor.instance_variable_get(:@adapter)

      adapter.define_singleton_method(:suspend) { nil }
      adapter.define_singleton_method(:resume) { nil }

      context = Mui::CommandContext.new(
        editor:,
        buffer: editor.buffer,
        window: editor.window
      )

      result = context.run_interactive_command("exit 1")

      refute result[:success]
      assert_equal 1, result[:exit_status]
    end
  end

  class TestTestAdapterSuspendResume < TestInteractiveCommand
    def test_test_adapter_suspend_sets_suspended_flag
      adapter = Mui::TerminalAdapter::Test.new

      adapter.suspend

      assert_predicate adapter, :suspended?
    end

    def test_test_adapter_resume_clears_suspended_flag
      adapter = Mui::TerminalAdapter::Test.new
      adapter.suspend

      adapter.resume

      refute_predicate adapter, :suspended?
    end

    def test_test_adapter_suspended_default_is_false
      adapter = Mui::TerminalAdapter::Test.new

      refute_predicate adapter, :suspended?
    end
  end
end
