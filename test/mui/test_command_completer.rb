# frozen_string_literal: true

require "test_helper"

class TestCommandCompleter < Minitest::Test
  def setup
    @completer = Mui::CommandCompleter.new
  end

  class TestComplete < TestCommandCompleter
    def test_complete_with_empty_prefix_returns_all_commands_sorted
      result = @completer.complete("")

      assert_equal Mui::CommandCompleter::COMMANDS.sort, result
    end

    def test_complete_with_prefix_filters_commands
      result = @completer.complete("tab")

      assert_includes result, "tabnew"
      assert_includes result, "tabclose"
      assert_includes result, "tabnext"
      refute_includes result, "e"
      refute_includes result, "split"
    end

    def test_complete_with_e_returns_e_only
      result = @completer.complete("e")

      assert_equal ["e"], result
    end

    def test_complete_with_sp_returns_sp_and_split
      result = @completer.complete("sp")

      assert_equal %w[sp split], result
    end

    def test_complete_with_no_match_returns_empty
      result = @completer.complete("xyz")

      assert_empty result
    end

    def test_complete_with_q_returns_q_and_q_bang
      result = @completer.complete("q")

      assert_equal %w[q q!], result
    end

    def test_complete_with_full_command_returns_that_command
      result = @completer.complete("tabnew")

      assert_equal ["tabnew"], result
    end

    def test_complete_results_are_sorted
      result = @completer.complete("tab")

      assert_equal result.sort, result
    end

    def test_complete_with_vs_returns_vs_and_vsplit
      result = @completer.complete("vs")

      assert_equal %w[vs vsplit], result
    end

    def test_complete_with_w_returns_w_and_wq
      result = @completer.complete("w")

      assert_equal %w[w wq], result
    end
  end

  class TestCommands < TestCommandCompleter
    def test_commands_includes_file_commands
      assert_includes Mui::CommandCompleter::COMMANDS, "e"
      assert_includes Mui::CommandCompleter::COMMANDS, "w"
      assert_includes Mui::CommandCompleter::COMMANDS, "sp"
      assert_includes Mui::CommandCompleter::COMMANDS, "vs"
    end

    def test_commands_includes_quit_commands
      assert_includes Mui::CommandCompleter::COMMANDS, "q"
      assert_includes Mui::CommandCompleter::COMMANDS, "q!"
      assert_includes Mui::CommandCompleter::COMMANDS, "wq"
    end

    def test_commands_includes_tab_commands
      assert_includes Mui::CommandCompleter::COMMANDS, "tabnew"
      assert_includes Mui::CommandCompleter::COMMANDS, "tabclose"
      assert_includes Mui::CommandCompleter::COMMANDS, "tabnext"
      assert_includes Mui::CommandCompleter::COMMANDS, "tabprev"
    end

    def test_commands_includes_window_commands
      assert_includes Mui::CommandCompleter::COMMANDS, "close"
      assert_includes Mui::CommandCompleter::COMMANDS, "only"
    end

    def test_commands_is_frozen
      assert Mui::CommandCompleter::COMMANDS.frozen?
    end
  end
end
