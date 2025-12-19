# frozen_string_literal: true

require "test_helper"

class TestCommandLine < Minitest::Test
  class TestInitialize < Minitest::Test
    def test_buffer_is_empty
      command_line = Mui::CommandLine.new

      assert_equal "", command_line.buffer
    end
  end

  class TestInput < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_appends_single_character
      @command_line.input("w")

      assert_equal "w", @command_line.buffer
    end

    def test_appends_multiple_characters
      @command_line.input("w")
      @command_line.input("q")

      assert_equal "wq", @command_line.buffer
    end
  end

  class TestBackspace < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_removes_last_character
      @command_line.input("w")
      @command_line.input("q")

      @command_line.backspace

      assert_equal "w", @command_line.buffer
    end

    def test_removes_all_characters
      @command_line.input("w")

      @command_line.backspace

      assert_equal "", @command_line.buffer
    end

    def test_does_nothing_when_empty
      @command_line.backspace

      assert_equal "", @command_line.buffer
    end
  end

  class TestClear < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_clears_buffer
      @command_line.input("w")
      @command_line.input("q")

      @command_line.clear

      assert_equal "", @command_line.buffer
    end
  end

  class TestToS < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_returns_colon_when_empty
      assert_equal ":", @command_line.to_s
    end

    def test_returns_colon_with_buffer
      @command_line.input("w")

      assert_equal ":w", @command_line.to_s
    end

    def test_returns_colon_with_multiple_characters
      @command_line.input("w")
      @command_line.input("q")

      assert_equal ":wq", @command_line.to_s
    end
  end

  class TestExecute < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_open_command
      @command_line.input("e")

      result = @command_line.execute

      assert_equal :open, result[:action]
    end

    def test_write_command
      @command_line.input("w")

      result = @command_line.execute

      assert_equal({ action: :write }, result)
      assert_equal "", @command_line.buffer
    end

    def test_quit_command
      @command_line.input("q")

      result = @command_line.execute

      assert_equal({ action: :quit }, result)
    end

    def test_write_quit_command
      @command_line.input("w")
      @command_line.input("q")

      result = @command_line.execute

      assert_equal({ action: :write_quit }, result)
    end

    def test_force_quit_command
      @command_line.input("q")
      @command_line.input("!")

      result = @command_line.execute

      assert_equal({ action: :force_quit }, result)
    end

    def test_open_as_with_filename
      "e test.txt".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :open_as, result[:action]
      assert_equal "test.txt", result[:path]
    end

    def test_write_as_with_filename
      "w test.txt".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :write_as, result[:action]
      assert_equal "test.txt", result[:path]
    end

    def test_write_as_with_full_path
      "w /path/to/file.txt".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :write_as, result[:action]
      assert_equal "/path/to/file.txt", result[:path]
    end

    def test_unknown_command
      "unknown".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal :unknown, result[:action]
      assert_equal "unknown", result[:command]
    end

    def test_empty_command_returns_no_op
      result = @command_line.execute

      assert_equal({ action: :no_op }, result)
    end

    def test_whitespace_only_command_returns_no_op
      "   ".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal({ action: :no_op }, result)
    end

    def test_strips_leading_and_trailing_spaces
      "  w  ".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal({ action: :write }, result)
    end

    def test_goto_line_single_digit
      "5".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal({ action: :goto_line, line_number: 5 }, result)
    end

    def test_goto_line_multiple_digits
      "123".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal({ action: :goto_line, line_number: 123 }, result)
    end

    def test_goto_line_zero
      "0".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal({ action: :goto_line, line_number: 0 }, result)
    end

    def test_goto_line_one
      "1".each_char { |c| @command_line.input(c) }

      result = @command_line.execute

      assert_equal({ action: :goto_line, line_number: 1 }, result)
    end
  end

  class TestCompletionContext < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_empty_buffer_returns_command_context
      result = @command_line.completion_context

      assert_equal :command, result[:type]
      assert_equal "", result[:prefix]
    end

    def test_partial_command_returns_command_context
      "tab".each_char { |c| @command_line.input(c) }

      result = @command_line.completion_context

      assert_equal :command, result[:type]
      assert_equal "tab", result[:prefix]
    end

    def test_file_command_with_space_returns_file_context
      "e ".each_char { |c| @command_line.input(c) }

      result = @command_line.completion_context

      assert_equal :file, result[:type]
      assert_equal "e", result[:command]
      assert_equal "", result[:prefix]
    end

    def test_file_command_with_partial_path_returns_file_context
      "e test".each_char { |c| @command_line.input(c) }

      result = @command_line.completion_context

      assert_equal :file, result[:type]
      assert_equal "e", result[:command]
      assert_equal "test", result[:prefix]
    end

    def test_split_command_with_path_returns_file_context
      "sp lib/".each_char { |c| @command_line.input(c) }

      result = @command_line.completion_context

      assert_equal :file, result[:type]
      assert_equal "sp", result[:command]
      assert_equal "lib/", result[:prefix]
    end

    def test_vsplit_command_with_path_returns_file_context
      "vs test.rb".each_char { |c| @command_line.input(c) }

      result = @command_line.completion_context

      assert_equal :file, result[:type]
      assert_equal "vs", result[:command]
      assert_equal "test.rb", result[:prefix]
    end

    def test_tabnew_command_with_path_returns_file_context
      "tabnew src/".each_char { |c| @command_line.input(c) }

      result = @command_line.completion_context

      assert_equal :file, result[:type]
      assert_equal "tabnew", result[:command]
      assert_equal "src/", result[:prefix]
    end

    def test_non_file_command_with_arg_returns_nil
      "q!".each_char { |c| @command_line.input(c) }

      result = @command_line.completion_context

      # q! has no space, so still command context
      assert_equal :command, result[:type]
    end

    def test_unknown_command_with_arg_returns_nil
      "unknown arg".each_char { |c| @command_line.input(c) }

      result = @command_line.completion_context

      assert_nil result
    end

    def test_tabmove_command_returns_nil
      "tabmove ".each_char { |c| @command_line.input(c) }

      result = @command_line.completion_context

      # tabmove takes a number, not a file
      assert_nil result
    end
  end

  class TestApplyCompletion < Minitest::Test
    def setup
      @command_line = Mui::CommandLine.new
    end

    def test_apply_command_completion
      "tab".each_char { |c| @command_line.input(c) }
      context = { type: :command, prefix: "tab" }

      @command_line.apply_completion("tabnew", context)

      assert_equal "tabnew", @command_line.buffer
    end

    def test_apply_file_completion
      "e ".each_char { |c| @command_line.input(c) }
      context = { type: :file, command: "e", prefix: "" }

      @command_line.apply_completion("test.rb", context)

      assert_equal "e test.rb", @command_line.buffer
    end

    def test_apply_file_completion_with_directory
      "e lib/".each_char { |c| @command_line.input(c) }
      context = { type: :file, command: "e", prefix: "lib/" }

      @command_line.apply_completion("lib/mui/", context)

      assert_equal "e lib/mui/", @command_line.buffer
    end

    def test_apply_file_completion_for_split
      "sp ".each_char { |c| @command_line.input(c) }
      context = { type: :file, command: "sp", prefix: "" }

      @command_line.apply_completion("Gemfile", context)

      assert_equal "sp Gemfile", @command_line.buffer
    end

    def test_apply_completion_updates_cursor_position_for_command
      "tab".each_char { |c| @command_line.input(c) }
      context = { type: :command, prefix: "tab" }

      @command_line.apply_completion("tabnew", context)

      assert_equal 6, @command_line.cursor_pos
    end

    def test_apply_completion_updates_cursor_position_for_file
      "e ".each_char { |c| @command_line.input(c) }
      context = { type: :file, command: "e", prefix: "" }

      @command_line.apply_completion("lib/mui/", context)

      assert_equal 10, @command_line.cursor_pos # "e lib/mui/".length
    end

    def test_apply_completion_cursor_at_end_of_buffer
      "e li".each_char { |c| @command_line.input(c) }
      context = { type: :file, command: "e", prefix: "li" }

      @command_line.apply_completion("lib/", context)

      assert_equal @command_line.buffer.length, @command_line.cursor_pos
    end
  end

  class TestFileCommands < Minitest::Test
    def test_file_commands_includes_e
      assert_includes Mui::CommandLine::FILE_COMMANDS, "e"
    end

    def test_file_commands_includes_w
      assert_includes Mui::CommandLine::FILE_COMMANDS, "w"
    end

    def test_file_commands_includes_sp
      assert_includes Mui::CommandLine::FILE_COMMANDS, "sp"
    end

    def test_file_commands_includes_split
      assert_includes Mui::CommandLine::FILE_COMMANDS, "split"
    end

    def test_file_commands_includes_vs
      assert_includes Mui::CommandLine::FILE_COMMANDS, "vs"
    end

    def test_file_commands_includes_vsplit
      assert_includes Mui::CommandLine::FILE_COMMANDS, "vsplit"
    end

    def test_file_commands_includes_tabnew
      assert_includes Mui::CommandLine::FILE_COMMANDS, "tabnew"
    end

    def test_file_commands_is_frozen
      assert_predicate Mui::CommandLine::FILE_COMMANDS, :frozen?
    end
  end
end
