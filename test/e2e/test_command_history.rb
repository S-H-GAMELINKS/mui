# frozen_string_literal: true

require_relative "test_helper"

# Helper module to clear history before each test
module ClearHistorySetup
  def setup
    super if defined?(super)
    history_file = File.expand_path("~/.mui_history")
    FileUtils.rm_f(history_file)
  end
end

class TestCommandHistory < Minitest::Test
  class TestBasicHistoryNavigation < Minitest::Test
    include ClearHistorySetup

    def test_up_arrow_recalls_last_command
      runner = ScriptRunner.new
      runner.type(":e test.txt<Enter>")
      runner.type(":<Up>")

      runner.assert_mode(Mui::Mode::COMMAND)

      assert_equal "e test.txt", runner.editor.instance_variable_get(:@command_line).buffer
    end

    def test_down_arrow_returns_to_empty_after_up
      runner = ScriptRunner.new
      runner.type(":w<Enter>")
      runner.type(":<Up>")
      runner.type("<Down>")

      runner.assert_mode(Mui::Mode::COMMAND)

      assert_empty runner.editor.instance_variable_get(:@command_line).buffer
    end

    def test_multiple_commands_in_history
      runner = ScriptRunner.new
      runner.type(":e file1.txt<Enter>")
      runner.type(":w<Enter>")
      runner.type(":e file2.txt<Enter>")

      runner.type(":<Up>")

      assert_equal "e file2.txt", runner.editor.instance_variable_get(:@command_line).buffer

      runner.type("<Up>")

      assert_equal "w", runner.editor.instance_variable_get(:@command_line).buffer

      runner.type("<Up>")

      assert_equal "e file1.txt", runner.editor.instance_variable_get(:@command_line).buffer
    end

    def test_history_navigation_then_forward
      runner = ScriptRunner.new
      runner.type(":first<Enter>")
      runner.type(":second<Enter>")
      runner.type(":third<Enter>")

      runner.type(":<Up><Up><Up>")

      assert_equal "first", runner.editor.instance_variable_get(:@command_line).buffer

      runner.type("<Down>")

      assert_equal "second", runner.editor.instance_variable_get(:@command_line).buffer

      runner.type("<Down>")

      assert_equal "third", runner.editor.instance_variable_get(:@command_line).buffer
    end
  end

  class TestHistorySavesCurrentInput < Minitest::Test
    include ClearHistorySetup

    def test_preserves_typed_input_when_browsing
      runner = ScriptRunner.new
      runner.type(":old_cmd<Enter>")
      runner.type(":new_")

      runner.type("<Up>")

      assert_equal "old_cmd", runner.editor.instance_variable_get(:@command_line).buffer

      runner.type("<Down>")

      assert_equal "new_", runner.editor.instance_variable_get(:@command_line).buffer
    end
  end

  class TestHistoryEdgeCases < Minitest::Test
    include ClearHistorySetup

    def test_up_arrow_with_empty_history
      runner = ScriptRunner.new
      runner.type(":<Up>")

      runner.assert_mode(Mui::Mode::COMMAND)

      assert_empty runner.editor.instance_variable_get(:@command_line).buffer
    end

    def test_down_arrow_without_browsing
      runner = ScriptRunner.new
      runner.type(":cmd<Enter>")
      runner.type(":<Down>")

      runner.assert_mode(Mui::Mode::COMMAND)

      assert_empty runner.editor.instance_variable_get(:@command_line).buffer
    end

    def test_escape_clears_history_state
      runner = ScriptRunner.new
      runner.type(":old<Enter>")
      runner.type(":<Up>")
      runner.type("<Escape>")

      runner.assert_mode(Mui::Mode::NORMAL)

      # Start new command and browse history again
      runner.type(":<Up>")

      assert_equal "old", runner.editor.instance_variable_get(:@command_line).buffer
    end

    def test_empty_command_not_added_to_history
      runner = ScriptRunner.new
      runner.type(":valid<Enter>")
      runner.type(":<Enter>") # Empty command

      runner.type(":<Up>")

      assert_equal "valid", runner.editor.instance_variable_get(:@command_line).buffer
    end
  end

  class TestHistoryDuplicateHandling < Minitest::Test
    include ClearHistorySetup

    def test_duplicate_command_moves_to_end
      runner = ScriptRunner.new
      runner.type(":first<Enter>")
      runner.type(":second<Enter>")
      runner.type(":first<Enter>") # Duplicate

      runner.type(":<Up>")

      assert_equal "first", runner.editor.instance_variable_get(:@command_line).buffer

      runner.type("<Up>")

      assert_equal "second", runner.editor.instance_variable_get(:@command_line).buffer

      # "first" should not appear again
      runner.type("<Up>")
      # Should stay at "second" (oldest)
      assert_equal "second", runner.editor.instance_variable_get(:@command_line).buffer
    end
  end

  class TestHistoryWithCompletion < Minitest::Test
    include ClearHistorySetup

    def test_history_resets_completion_popup
      runner = ScriptRunner.new
      runner.type(":old_cmd<Enter>")
      runner.type(":tab") # Should show completion popup

      handler = runner.editor.instance_variable_get(:@mode_manager).current_handler
      # Completion should be active after typing "tab"
      # (depends on having tab-related commands)

      runner.type("<Up>")
      # After history navigation, completion should be reset
      refute_predicate handler.completion_state, :active?
    end
  end

  class TestTypingAfterHistory < Minitest::Test
    include ClearHistorySetup

    def test_can_edit_recalled_command
      runner = ScriptRunner.new
      runner.type(":e file<Enter>")
      runner.type(":<Up>")

      # Add more text
      runner.type(".txt")

      assert_equal "e file.txt", runner.editor.instance_variable_get(:@command_line).buffer
    end

    def test_backspace_on_recalled_command
      runner = ScriptRunner.new
      runner.type(":tabnew<Enter>")
      runner.type(":<Up>")

      runner.type("<Backspace><Backspace><Backspace>")

      assert_equal "tab", runner.editor.instance_variable_get(:@command_line).buffer
    end
  end
end
