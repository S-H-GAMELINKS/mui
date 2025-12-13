# frozen_string_literal: true

require_relative "test_helper"

class TestCommandCompletion < Minitest::Test
  def setup
    Mui.reset_config!
  end

  class TestPluginCommandCompletion < TestCommandCompletion
    def test_plugin_command_appears_in_completion
      runner = ScriptRunner.new

      # Register plugin command AFTER ScriptRunner (which calls reset_config!)
      Mui.command(:mytest) do |ctx|
        ctx.set_message("mytest executed!")
      end

      # Enter command mode, type prefix, press Tab to complete
      runner.type(":myt<Tab>")

      # Verify the command line buffer contains the completed command
      assert_equal "mytest", runner.editor.command_line.buffer
    end

    def test_plugin_command_can_be_executed_after_completion
      runner = ScriptRunner.new

      # Register plugin command AFTER ScriptRunner
      executed = false
      Mui.command(:testcmd) do |_ctx|
        executed = true
      end

      # Type prefix, complete with Tab, and execute with Enter
      runner.type(":test<Tab><Enter>")

      assert executed, "Plugin command should have been executed"
    end

    def test_multiple_plugin_commands_cycle_with_tab
      runner = ScriptRunner.new

      # Register plugin commands AFTER ScriptRunner
      Mui.command(:alpha_cmd) { |_ctx| nil }
      Mui.command(:alpha_test) { |_ctx| nil }

      # Type prefix and Tab twice to cycle
      runner.type(":alpha<Tab>")
      first_completion = runner.editor.command_line.buffer.dup

      runner.type("<Tab>")
      second_completion = runner.editor.command_line.buffer.dup

      # Should cycle between the two commands
      refute_equal first_completion, second_completion
      assert_includes %w[alpha_cmd alpha_test], first_completion
      assert_includes %w[alpha_cmd alpha_test], second_completion
    end

    def test_plugin_and_builtin_commands_mixed_completion
      runner = ScriptRunner.new

      # Register plugin command AFTER ScriptRunner
      Mui.command(:tabnew_extra) { |_ctx| nil }

      # Type 'tabn' - should match both built-in 'tabnew' and plugin 'tabnew_extra'
      runner.type(":tabn<Tab>")

      # Should complete to one of them
      buffer = runner.editor.command_line.buffer
      assert(buffer.start_with?("tabn"), "Should complete to a tabn* command")
    end
  end
end
