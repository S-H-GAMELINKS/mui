# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestCommandLineHistory < Minitest::Test
  def setup
    @temp_file = Tempfile.new("mui_history_test")
    @history = Mui::CommandHistory.new(history_file: @temp_file.path)
    @command_line = Mui::CommandLine.new(history: @history)
  end

  def teardown
    @temp_file.close
    @temp_file.unlink
  end

  class TestHistoryPrevious < TestCommandLineHistory
    def test_history_previous_returns_false_when_empty
      result = @command_line.history_previous

      refute result
    end

    def test_history_previous_sets_buffer_to_last_command
      @history.add("e file.txt")

      @command_line.history_previous

      assert_equal "e file.txt", @command_line.buffer
    end

    def test_history_previous_sets_cursor_to_end
      @history.add("tabnew")

      @command_line.history_previous

      assert_equal 6, @command_line.cursor_pos
    end

    def test_history_previous_saves_current_input
      @history.add("w")
      @command_line.input("q")

      @command_line.history_previous
      @command_line.history_next

      assert_equal "q", @command_line.buffer
    end

    def test_history_previous_navigates_backwards
      @history.add("first")
      @history.add("second")
      @history.add("third")

      @command_line.history_previous
      assert_equal "third", @command_line.buffer

      @command_line.history_previous
      assert_equal "second", @command_line.buffer

      @command_line.history_previous
      assert_equal "first", @command_line.buffer
    end

    def test_history_previous_returns_false_at_oldest
      @history.add("only")

      assert @command_line.history_previous
      refute @command_line.history_previous
    end
  end

  class TestHistoryNext < TestCommandLineHistory
    def test_history_next_returns_false_when_not_browsing
      @history.add("cmd")

      result = @command_line.history_next

      refute result
    end

    def test_history_next_navigates_forward
      @history.add("first")
      @history.add("second")

      @command_line.history_previous
      @command_line.history_previous

      @command_line.history_next

      assert_equal "second", @command_line.buffer
    end

    def test_history_next_returns_to_saved_input
      @history.add("cmd")
      @command_line.input("my input")

      @command_line.history_previous
      @command_line.history_next

      assert_equal "my input", @command_line.buffer
    end

    def test_history_next_sets_cursor_to_end
      @history.add("short")
      @history.add("verylongcommand")

      @command_line.history_previous
      @command_line.history_previous
      @command_line.history_next

      assert_equal 15, @command_line.cursor_pos
    end
  end

  class TestExecuteWithHistory < TestCommandLineHistory
    def test_execute_adds_command_to_history
      @command_line.input("w")
      @command_line.execute

      assert_equal 1, @history.size
      assert_includes @history.history, "w"
    end

    def test_execute_does_not_add_empty_command
      @command_line.execute

      assert @history.empty?
    end

    def test_execute_resets_history_state
      @history.add("old")
      @command_line.history_previous

      assert @history.browsing?

      @command_line.execute

      refute @history.browsing?
    end

    def test_execute_clears_buffer
      @command_line.input("tabnew")
      @command_line.execute

      assert_empty @command_line.buffer
    end
  end

  class TestClearWithHistory < TestCommandLineHistory
    def test_clear_resets_history_state
      @history.add("cmd")
      @command_line.history_previous

      assert @history.browsing?

      @command_line.clear

      refute @history.browsing?
    end
  end

  class TestHistoryIntegration < TestCommandLineHistory
    def test_full_history_workflow
      # Execute some commands
      @command_line.input("e file1.txt")
      @command_line.execute

      @command_line.input("w")
      @command_line.execute

      @command_line.input("e file2.txt")
      @command_line.execute

      # Now browse history
      @command_line.history_previous
      assert_equal "e file2.txt", @command_line.buffer

      @command_line.history_previous
      assert_equal "w", @command_line.buffer

      @command_line.history_previous
      assert_equal "e file1.txt", @command_line.buffer

      # Go back forward
      @command_line.history_next
      assert_equal "w", @command_line.buffer
    end

    def test_input_while_browsing_resets_state
      @history.add("old_cmd")
      @command_line.history_previous

      # User types something while browsing
      @command_line.input("q")

      # The buffer should now be the history item + new input
      assert_equal "old_cmdq", @command_line.buffer
    end
  end
end
