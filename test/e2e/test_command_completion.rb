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

  class TestCommandRegistryPluginIntegration < TestCommandCompletion
    def test_command_registry_exists_returns_true_for_plugin_command
      ScriptRunner.new
      registry = Mui::CommandRegistry.new

      # Register plugin command
      Mui.command(:my_plugin_cmd) { |_ctx| nil }

      # CommandRegistry should recognize plugin command via exists?
      assert registry.exists?(:my_plugin_cmd),
             "CommandRegistry should recognize plugin commands"
    end

    def test_command_registry_find_returns_plugin_command
      ScriptRunner.new
      registry = Mui::CommandRegistry.new

      # Register plugin command
      Mui.command(:findable_cmd) { |_ctx| "found" }

      # CommandRegistry should find plugin command
      command = registry.find(:findable_cmd)

      assert command, "CommandRegistry#find should return plugin command"
    end

    def test_command_registry_execute_runs_plugin_command
      runner = ScriptRunner.new
      registry = Mui::CommandRegistry.new

      # Register plugin command
      executed = false
      Mui.command(:exec_test_cmd) { |_ctx| executed = true }

      # Create context
      context = Mui::CommandContext.new(
        editor: runner.editor,
        buffer: runner.editor.buffer,
        window: runner.editor.window
      )

      # Execute via registry
      registry.execute(:exec_test_cmd, context)

      assert executed, "Plugin command should be executed via CommandRegistry"
    end

    def test_builtin_command_takes_precedence_over_plugin
      runner = ScriptRunner.new
      registry = Mui::CommandRegistry.new

      # Register both builtin and plugin with same name
      builtin_called = false
      plugin_called = false

      registry.register(:duplicate_name) { |_ctx| builtin_called = true }
      Mui.command(:duplicate_name) { |_ctx| plugin_called = true }

      # Create context
      context = Mui::CommandContext.new(
        editor: runner.editor,
        buffer: runner.editor.buffer,
        window: runner.editor.window
      )

      # Execute - builtin should win
      registry.execute(:duplicate_name, context)

      assert builtin_called, "Built-in command should be called"
      refute plugin_called, "Plugin command should not be called when builtin exists"
    end
  end
end
