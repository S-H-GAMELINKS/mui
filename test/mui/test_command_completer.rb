# frozen_string_literal: true

require "test_helper"

class TestCommandCompleter < Minitest::Test
  def setup
    @completer = Mui::CommandCompleter.new
  end

  class TestComplete < TestCommandCompleter
    def test_complete_with_empty_prefix_includes_all_builtin_commands
      result = @completer.complete("")

      Mui::CommandCompleter::COMMANDS.each do |cmd|
        assert_includes result, cmd
      end
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

  class TestPluginCommandCompletion < TestCommandCompleter
    def setup
      super
      # Save original commands
      @original_commands = Mui.config.commands.dup
    end

    def teardown
      # Restore original commands
      Mui.config.instance_variable_set(:@commands, @original_commands)
    end

    def test_includes_plugin_commands_in_completion
      Mui.command(:mytest) { |_ctx| nil }

      candidates = @completer.complete("")

      assert_includes candidates, "mytest"
    end

    def test_filters_plugin_commands_by_prefix
      Mui.command(:foo_cmd) { |_ctx| nil }
      Mui.command(:bar_cmd) { |_ctx| nil }

      candidates = @completer.complete("foo")

      assert_includes candidates, "foo_cmd"
      refute_includes candidates, "bar_cmd"
    end

    def test_mixed_builtin_and_plugin_commands
      Mui.command(:tabnew_extra) { |_ctx| nil }

      candidates = @completer.complete("tab")

      # Should include both built-in and plugin commands
      assert_includes candidates, "tabnew"
      assert_includes candidates, "tabnew_extra"
    end

    def test_returns_sorted_unique_candidates
      candidates = @completer.complete("")

      assert_equal candidates, candidates.uniq.sort
    end

    def test_plugin_command_with_no_match_returns_empty
      Mui.command(:zzz_unique_cmd) { |_ctx| nil }

      candidates = @completer.complete("aaa")

      refute_includes candidates, "zzz_unique_cmd"
    end
  end

  class TestCaseInsensitiveCompletion < TestCommandCompleter
    def setup
      super
      @original_commands = Mui.config.commands.dup
    end

    def teardown
      Mui.config.instance_variable_set(:@commands, @original_commands)
    end

    def test_lowercase_prefix_matches_capitalized_command
      Mui.command(:Git) { |_ctx| nil }

      candidates = @completer.complete("git")

      assert_includes candidates, "Git"
    end

    def test_uppercase_prefix_matches_lowercase_command
      candidates = @completer.complete("TAB")

      assert_includes candidates, "tabnew"
      assert_includes candidates, "tabclose"
    end

    def test_mixed_case_prefix_matches
      Mui.command(:LspHover) { |_ctx| nil }

      candidates = @completer.complete("lsp")

      assert_includes candidates, "LspHover"
    end

    def test_exact_case_still_works
      Mui.command(:Git) { |_ctx| nil }

      candidates = @completer.complete("Git")

      assert_includes candidates, "Git"
    end

    def test_preserves_original_case_in_results
      Mui.command(:LspHover) { |_ctx| nil }
      Mui.command(:LspDefinition) { |_ctx| nil }

      candidates = @completer.complete("lsp")

      assert(candidates.any? { |c| c == "LspHover" })
      assert(candidates.any? { |c| c == "LspDefinition" })
    end

    def test_case_insensitive_with_partial_match
      Mui.command(:Rg) { |_ctx| nil }

      candidates = @completer.complete("rg")

      assert_includes candidates, "Rg"
    end

    def test_case_insensitive_with_builtin_commands
      candidates = @completer.complete("SP")

      assert_includes candidates, "sp"
      assert_includes candidates, "split"
    end
  end
end
