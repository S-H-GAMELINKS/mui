# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestCommandModeHistory < Minitest::Test
  def setup
    @temp_file = Tempfile.new("mui_history_test")
    @history = Mui::CommandHistory.new(history_file: @temp_file.path)
    @command_line = Mui::CommandLine.new(history: @history)
    @buffer = Mui::Buffer.new
    @window = MockWindow.new(@buffer)
    @mode_manager = MockModeManager.new(@window)
    @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
  end

  def teardown
    @temp_file.close
    @temp_file.unlink
  end

  class TestHandleHistoryUp < TestCommandModeHistory
    def test_handle_history_up_with_empty_history
      result = @handler.handle(Curses::KEY_UP)

      assert_instance_of Mui::HandlerResult::CommandModeResult, result
      assert_empty @command_line.buffer
    end

    def test_handle_history_up_sets_buffer_to_last_command
      @history.add("e file.txt")

      @handler.handle(Curses::KEY_UP)

      assert_equal "e file.txt", @command_line.buffer
    end

    def test_handle_history_up_navigates_backwards
      @history.add("first")
      @history.add("second")
      @history.add("third")

      @handler.handle(Curses::KEY_UP)
      assert_equal "third", @command_line.buffer

      @handler.handle(Curses::KEY_UP)
      assert_equal "second", @command_line.buffer

      @handler.handle(Curses::KEY_UP)
      assert_equal "first", @command_line.buffer
    end

    def test_handle_history_up_resets_completion
      @history.add("cmd")

      # Mock completion state
      assert @handler.completion_state.respond_to?(:reset)

      @handler.handle(Curses::KEY_UP)

      # Completion should be reset (not active)
      refute @handler.completion_state.active?
    end
  end

  class TestHandleHistoryDown < TestCommandModeHistory
    def test_handle_history_down_when_not_browsing
      @history.add("cmd")

      result = @handler.handle(Curses::KEY_DOWN)

      assert_instance_of Mui::HandlerResult::CommandModeResult, result
      assert_empty @command_line.buffer
    end

    def test_handle_history_down_navigates_forward
      @history.add("first")
      @history.add("second")
      @history.add("third")

      # Go back to first
      @handler.handle(Curses::KEY_UP)
      @handler.handle(Curses::KEY_UP)
      @handler.handle(Curses::KEY_UP)
      assert_equal "first", @command_line.buffer

      # Go forward
      @handler.handle(Curses::KEY_DOWN)
      assert_equal "second", @command_line.buffer

      @handler.handle(Curses::KEY_DOWN)
      assert_equal "third", @command_line.buffer
    end

    def test_handle_history_down_returns_to_saved_input
      @history.add("history_cmd")
      @command_line.input("my_")

      @handler.handle(Curses::KEY_UP)
      assert_equal "history_cmd", @command_line.buffer

      @handler.handle(Curses::KEY_DOWN)
      assert_equal "my_", @command_line.buffer
    end

    def test_handle_history_down_resets_completion
      @history.add("cmd")
      @handler.handle(Curses::KEY_UP)

      @handler.handle(Curses::KEY_DOWN)

      refute @handler.completion_state.active?
    end
  end

  class TestHistoryIntegration < TestCommandModeHistory
    def test_history_preserved_across_commands
      # Type and execute first command
      @command_line.input("w")
      @command_line.execute

      # Type and execute second command
      @command_line.input("q")
      @command_line.execute

      # Now browse history
      @handler.handle(Curses::KEY_UP)
      assert_equal "q", @command_line.buffer

      @handler.handle(Curses::KEY_UP)
      assert_equal "w", @command_line.buffer
    end

    def test_escape_after_history_clears_buffer
      @history.add("old_cmd")
      @handler.handle(Curses::KEY_UP)

      assert_equal "old_cmd", @command_line.buffer

      @handler.handle(Mui::KeyCode::ESCAPE)

      assert_empty @command_line.buffer
    end

    def test_typing_after_history_appends
      @history.add("e ")
      @handler.handle(Curses::KEY_UP)

      # Type additional characters
      @handler.handle("f".ord)
      @handler.handle("i".ord)
      @handler.handle("l".ord)
      @handler.handle("e".ord)

      assert_equal "e file", @command_line.buffer
    end
  end
end
