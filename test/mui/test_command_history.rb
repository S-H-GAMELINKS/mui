# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestCommandHistory < Minitest::Test
  def setup
    @temp_file = Tempfile.new("mui_history_test")
    @history = Mui::CommandHistory.new(history_file: @temp_file.path)
  end

  def teardown
    @temp_file.close
    @temp_file.unlink
  end

  class TestAdd < TestCommandHistory
    def test_add_stores_command
      @history.add("e file.txt")

      assert_equal 1, @history.size
      assert_includes @history.history, "e file.txt"
    end

    def test_add_ignores_empty_string
      @history.add("")

      assert_empty @history
    end

    def test_add_ignores_whitespace_only
      @history.add("   ")

      assert_empty @history
    end

    def test_add_removes_duplicate_and_appends
      @history.add("first")
      @history.add("second")
      @history.add("first")

      assert_equal 2, @history.size
      assert_equal "first", @history.history.last
    end

    def test_add_respects_max_history
      (Mui::CommandHistory::MAX_HISTORY + 10).times do |i|
        @history.add("cmd#{i}")
      end

      assert_equal Mui::CommandHistory::MAX_HISTORY, @history.size
    end
  end

  class TestPrevious < TestCommandHistory
    def test_previous_returns_nil_when_empty
      result = @history.previous("")

      assert_nil result
    end

    def test_previous_returns_last_command
      @history.add("first")
      @history.add("second")

      result = @history.previous("")

      assert_equal "second", result
    end

    def test_previous_navigates_backwards
      @history.add("first")
      @history.add("second")
      @history.add("third")

      assert_equal "third", @history.previous("")
      assert_equal "second", @history.previous("")
      assert_equal "first", @history.previous("")
    end

    def test_previous_stops_at_oldest
      @history.add("only")

      assert_equal "only", @history.previous("")
      assert_nil @history.previous("")
    end

    def test_previous_saves_current_input
      @history.add("history")

      @history.previous("my_input")

      # Navigate back to saved input
      result = @history.next_entry

      assert_equal "my_input", result
    end
  end

  class TestNextEntry < TestCommandHistory
    def test_next_entry_returns_nil_when_not_browsing
      @history.add("cmd")

      result = @history.next_entry

      assert_nil result
    end

    def test_next_entry_navigates_forward
      @history.add("first")
      @history.add("second")
      @history.add("third")

      @history.previous("")
      @history.previous("")
      @history.previous("")

      assert_equal "second", @history.next_entry
      assert_equal "third", @history.next_entry
    end

    def test_next_entry_returns_saved_input_at_end
      @history.add("cmd")

      @history.previous("saved")

      result = @history.next_entry

      assert_equal "saved", result
    end

    def test_next_entry_resets_state_at_end
      @history.add("cmd")

      @history.previous("saved")
      @history.next_entry

      refute_predicate @history, :browsing?
    end
  end

  class TestReset < TestCommandHistory
    def test_reset_clears_browsing_state
      @history.add("cmd")
      @history.previous("input")

      assert_predicate @history, :browsing?

      @history.reset

      refute_predicate @history, :browsing?
    end
  end

  class TestBrowsing < TestCommandHistory
    def test_browsing_returns_false_initially
      refute_predicate @history, :browsing?
    end

    def test_browsing_returns_true_after_previous
      @history.add("cmd")
      @history.previous("")

      assert_predicate @history, :browsing?
    end

    def test_browsing_returns_false_after_reset
      @history.add("cmd")
      @history.previous("")
      @history.reset

      refute_predicate @history, :browsing?
    end
  end

  class TestPersistence < TestCommandHistory
    def test_saves_to_file_on_add
      @history.add("saved_cmd")

      content = File.read(@temp_file.path)

      assert_includes content, "saved_cmd"
    end

    def test_loads_from_file_on_initialize
      File.write(@temp_file.path, "cmd1\ncmd2\ncmd3\n")

      new_history = Mui::CommandHistory.new(history_file: @temp_file.path)

      assert_equal 3, new_history.size
      assert_equal %w[cmd1 cmd2 cmd3], new_history.history
    end

    def test_loads_only_last_max_history_entries
      commands = (1..150).map { |i| "cmd#{i}" }
      File.write(@temp_file.path, "#{commands.join("\n")}\n")

      new_history = Mui::CommandHistory.new(history_file: @temp_file.path)

      assert_equal Mui::CommandHistory::MAX_HISTORY, new_history.size
      assert_equal "cmd150", new_history.history.last
    end

    def test_handles_missing_file_gracefully
      new_history = Mui::CommandHistory.new(history_file: "/nonexistent/path/file")

      assert_empty new_history
    end

    def test_handles_corrupt_file_gracefully
      File.write(@temp_file.path, "\x00\xFF\xFE")

      new_history = Mui::CommandHistory.new(history_file: @temp_file.path)

      # Should not raise, history might be empty or contain the corrupt data
      assert_kind_of Mui::CommandHistory, new_history
    end
  end

  class TestEmptyAndSize < TestCommandHistory
    def test_empty_returns_true_initially
      assert_empty @history
    end

    def test_empty_returns_false_after_add
      @history.add("cmd")

      refute_empty @history
    end

    def test_size_returns_zero_initially
      assert_equal 0, @history.size
    end

    def test_size_returns_correct_count
      @history.add("one")
      @history.add("two")
      @history.add("three")

      assert_equal 3, @history.size
    end
  end
end
