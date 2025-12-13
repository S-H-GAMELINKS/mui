# frozen_string_literal: true

require "test_helper"

class TestKeyHandlerCommandMode < Minitest::Test
  class TestEscape < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_returns_normal_mode
      result = @handler.handle(27)

      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_clears_command_line
      @command_line.input("w")
      @command_line.input("q")

      @handler.handle(27)

      assert_equal "", @command_line.buffer
    end
  end

  class TestBackspace < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_deletes_last_char
      @command_line.input("w")
      @command_line.input("q")

      @handler.handle(127)

      assert_equal "w", @command_line.buffer
    end

    def test_curses_backspace_works
      @command_line.input("w")

      @handler.handle(Curses::KEY_BACKSPACE)

      assert_equal "", @command_line.buffer
    end

    def test_empty_buffer_returns_normal_mode
      result = @handler.handle(127)

      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_non_empty_buffer_stays_in_command_mode
      @command_line.input("w")

      result = @handler.handle(127)

      assert_nil result.mode
    end
  end

  class TestCharacterInput < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_inserts_string_character
      @handler.handle("w")

      assert_equal "w", @command_line.buffer
    end

    def test_inserts_integer_character
      @handler.handle(113) # 'q'

      assert_equal "q", @command_line.buffer
    end

    def test_ignores_non_printable_integer
      @handler.handle(1) # Ctrl+A

      assert_equal "", @command_line.buffer
    end

    def test_multiple_characters
      @handler.handle("w")
      @handler.handle("q")

      assert_equal "wq", @command_line.buffer
    end
  end

  class TestEnter < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_returns_normal_mode
      @command_line.input("w")

      result = @handler.handle(13)

      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_curses_enter_works
      @command_line.input("w")

      result = @handler.handle(Curses::KEY_ENTER)

      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_clears_command_line
      @command_line.input("w")

      @handler.handle(13)

      assert_equal "", @command_line.buffer
    end
  end

  class TestWriteCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_no_file_name_shows_error
      @command_line.input("w")

      result = @handler.handle(13)

      assert_equal "No file name", result.message
    end

    def test_with_file_name_shows_written
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.txt")
        @buffer.save(path)

        @command_line.input("w")
        result = @handler.handle(13)

        assert_match(/written/, result.message)
      end
    end
  end

  class TestQuitCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_unmodified_buffer_quits
      @command_line.input("q")

      result = @handler.handle(13)

      assert result.quit?
    end

    def test_modified_buffer_shows_warning
      @buffer.insert_char(0, 0, "a")

      @command_line.input("q")
      result = @handler.handle(13)

      assert_match(/No write since last change/, result.message)
      refute result.quit?
    end
  end

  class TestForceQuitCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_force_quits_even_with_modified_buffer
      @buffer.insert_char(0, 0, "a")

      @command_line.input("q")
      @command_line.input("!")
      result = @handler.handle(13)

      assert result.quit?
    end
  end

  class TestWriteQuitCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_saves_and_quits
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.txt")
        @buffer.save(path)

        @command_line.input("w")
        @command_line.input("q")
        result = @handler.handle(13)

        assert result.quit?
        assert_match(/written/, result.message)
      end
    end

    def test_no_file_name_shows_error
      @command_line.input("w")
      @command_line.input("q")
      result = @handler.handle(13)

      assert_equal "No file name", result.message
      refute result.quit?
    end
  end

  class TestOpenAsCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_open_to_specified_path
      Dir.mktmpdir do |dir|
        path = File.join(dir, "output.txt")

        File.write(path, "hello\n")

        @command_line.input("e")
        @command_line.input(" ")
        @command_line.input(path)
        result = @handler.handle(13)

        assert_match(/opened/, result.message)
        assert_equal "hello", @window.buffer.lines[0]
      end
    end

    def test_open_new_buffer_sets_undo_manager
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.txt")
        File.write(path, "test content\n")

        @command_line.input("e")
        @command_line.input(" ")
        path.each_char { |c| @command_line.input(c) }
        @handler.handle(13)

        assert_instance_of Mui::UndoManager, @window.buffer.undo_manager
      end
    end
  end

  class TestOpenAsNewFile < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_open_nonexistent_file_creates_new_buffer
      Dir.mktmpdir do |dir|
        path = File.join(dir, "new_file.txt")

        @command_line.input("e")
        @command_line.input(" ")
        @command_line.input(path)
        result = @handler.handle(13)

        assert_match(/opened/, result.message)
        assert_equal path, @window.buffer.name
      end
    end
  end

  class TestOpenCommand < Minitest::Test
    def test_open_to_current_path
      Dir.mktmpdir do |dir|
        path = File.join(dir, "output.txt")

        @buffer = Mui::Buffer.new(path)
        @buffer.lines[0] = "hello"
        @window = Mui::Window.new(@buffer)
        @command_line = Mui::CommandLine.new
        @mode_manager = MockModeManager.new(@window)
        @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)

        File.write(path, "hello\n")

        @command_line.input("e")
        result = @handler.handle(13)

        assert_match(/File reopened/, result.message)
        assert_equal "hello", @buffer.lines[0]
      end
    end

    def test_open_on_new_buffer_shows_error
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)

      @command_line.input("e")
      result = @handler.handle(13)

      assert_equal "No file name", result.message
    end
  end

  class TestWriteAsCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_saves_to_specified_path
      Dir.mktmpdir do |dir|
        path = File.join(dir, "output.txt")

        @command_line.input("w")
        @command_line.input(" ")
        @command_line.input(path)
        result = @handler.handle(13)

        assert_match(/written/, result.message)
        assert_equal "hello\n", File.read(path)
      end
    end
  end

  class TestUnknownCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_shows_unknown_command_message
      @command_line.input("x")
      @command_line.input("y")
      @command_line.input("z")
      result = @handler.handle(13)

      assert_match(/Unknown command: xyz/, result.message)
    end
  end

  class TestReturnValue < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_escape_returns_normal_mode
      result = @handler.handle(27)

      assert_equal Mui::Mode::NORMAL, result.mode
    end

    def test_character_input_returns_nil_mode
      result = @handler.handle("w")

      assert_nil result.mode
    end
  end

  class TestWriteError < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_write_to_nonexistent_directory_shows_error
      @buffer.instance_variable_set(:@name, "/nonexistent/dir/test.txt")

      @command_line.input("w")
      result = @handler.handle(13)

      assert_match(/Error:/, result.message)
    end

    def test_write_to_readonly_path_shows_error
      Dir.mktmpdir do |dir|
        readonly_dir = File.join(dir, "readonly")
        Dir.mkdir(readonly_dir)
        File.chmod(0o000, readonly_dir)

        path = File.join(readonly_dir, "test.txt")
        @buffer.instance_variable_set(:@name, path)

        @command_line.input("w")
        result = @handler.handle(13)

        assert_match(/Error:/, result.message)
      ensure
        File.chmod(0o755, readonly_dir) if File.exist?(readonly_dir)
      end
    end
  end

  class TestTabCompletion < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_has_completion_state
      assert_respond_to @handler, :completion_state
      assert_instance_of Mui::CompletionState, @handler.completion_state
    end

    def test_typing_starts_completion_automatically
      # Type "tab" character by character
      @handler.handle("t")
      @handler.handle("a")
      @handler.handle("b")

      assert @handler.completion_state.active?
      assert_equal :command, @handler.completion_state.completion_type
    end

    def test_tab_applies_first_candidate
      # Type to activate completion
      @handler.handle("t")
      @handler.handle("a")
      @handler.handle("b")
      @handler.handle("n")

      # Now TAB applies the selected candidate
      @handler.handle(Mui::KeyCode::TAB)

      # Should complete to first matching command (sorted alphabetically)
      assert_includes %w[tabn tabnew tabnext], @command_line.buffer
    end

    def test_first_tab_confirms_without_cycling
      # Type to activate completion
      @handler.handle("t")
      @handler.handle("a")
      @handler.handle("b")

      first_index = @handler.completion_state.selected_index

      @handler.handle(Mui::KeyCode::TAB)

      # After first TAB, it confirms current selection without cycling
      assert_equal first_index, @handler.completion_state.selected_index
      assert @handler.completion_state.confirmed?
    end

    def test_second_tab_cycles_to_next_candidate
      # Type to activate completion
      @handler.handle("t")
      @handler.handle("a")
      @handler.handle("b")

      first_index = @handler.completion_state.selected_index

      # First TAB confirms without cycling
      @handler.handle(Mui::KeyCode::TAB)
      # Second TAB cycles to next candidate
      @handler.handle(Mui::KeyCode::TAB)

      refute_equal first_index, @handler.completion_state.selected_index
    end

    def test_escape_resets_completion_state
      @handler.handle("t")
      @handler.handle("a")
      @handler.handle("b")

      @handler.handle(Mui::KeyCode::ESCAPE)

      refute @handler.completion_state.active?
    end

    def test_backspace_updates_completion
      @handler.handle("t")
      @handler.handle("a")
      @handler.handle("b")
      @handler.handle("n")

      # Backspace updates completion for new prefix
      @handler.handle(Mui::KeyCode::BACKSPACE)

      assert @handler.completion_state.active?
      assert_equal "tab", @command_line.buffer
    end
  end

  class TestShiftTabCompletion < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_shift_tab_cycles_backwards
      # Type to activate completion
      @handler.handle("t")
      @handler.handle("a")
      @handler.handle("b")

      # Cycle forward three times with TAB (first confirms, second and third cycle)
      @handler.handle(Mui::KeyCode::TAB)
      @handler.handle(Mui::KeyCode::TAB)
      @handler.handle(Mui::KeyCode::TAB)
      third_index = @handler.completion_state.selected_index

      # Cycle backwards with Shift+TAB
      @handler.handle(Curses::KEY_BTAB)
      after_shift_tab_index = @handler.completion_state.selected_index

      refute_equal third_index, after_shift_tab_index
    end
  end

  class TestGotoLineCommand < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      10.times { |i| @buffer.lines[i] = "Line #{i + 1}" }
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_goto_line_five_sets_cursor_to_row_four
      @command_line.input("5")
      @handler.handle(13)

      assert_equal 4, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end

    def test_goto_line_one_sets_cursor_to_row_zero
      @window.cursor_row = 5
      @command_line.input("1")
      @handler.handle(13)

      assert_equal 0, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end

    def test_goto_line_ten_sets_cursor_to_row_nine
      @command_line.input("1")
      @command_line.input("0")
      @handler.handle(13)

      assert_equal 9, @window.cursor_row
    end

    def test_goto_line_over_max_clamps_to_last_line
      @command_line.input("1")
      @command_line.input("0")
      @command_line.input("0")
      @handler.handle(13)

      # 10 lines means max row is 9
      assert_equal 9, @window.cursor_row
    end

    def test_goto_line_0_clamps_to_first_line
      @window.cursor_row = 5
      @command_line.input("0")
      @handler.handle(13)

      assert_equal 0, @window.cursor_row
    end

    def test_goto_line_returns_normal_mode
      @command_line.input("5")
      result = @handler.handle(13)

      assert_equal Mui::Mode::NORMAL, result.mode
    end
  end

  class TestSplitHorizontal < Minitest::Test
    include MuiTestHelper

    def setup
      @screen = Mui::TerminalAdapter::Test.new(width: 80, height: 24)
      @buffer = Mui::Buffer.new
      @window_manager = Mui::WindowManager.new(@screen)
      @window_manager.add_window(@buffer)
      @window = @window_manager.active_window
      @command_line = Mui::CommandLine.new
      @mock_mode_manager = MockModeManager.new(@window)
      @mock_mode_manager.window_manager = @window_manager
      @handler = Mui::KeyHandler::CommandMode.new(@mock_mode_manager, @buffer, @command_line)
    end

    def test_split_horizontal_with_path_sets_undo_manager
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.txt")
        File.write(path, "test content\n")

        "sp ".each_char { |c| @command_line.input(c) }
        path.each_char { |c| @command_line.input(c) }
        @handler.handle(13)

        new_window = @mock_mode_manager.window_manager.active_window
        assert_instance_of Mui::UndoManager, new_window.buffer.undo_manager
      end
    end
  end

  class TestSplitVertical < Minitest::Test
    include MuiTestHelper

    def setup
      @screen = Mui::TerminalAdapter::Test.new(width: 80, height: 24)
      @buffer = Mui::Buffer.new
      @window_manager = Mui::WindowManager.new(@screen)
      @window_manager.add_window(@buffer)
      @window = @window_manager.active_window
      @command_line = Mui::CommandLine.new
      @mock_mode_manager = MockModeManager.new(@window)
      @mock_mode_manager.window_manager = @window_manager
      @handler = Mui::KeyHandler::CommandMode.new(@mock_mode_manager, @buffer, @command_line)
    end

    def test_split_vertical_with_path_sets_undo_manager
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.txt")
        File.write(path, "test content\n")

        "vs ".each_char { |c| @command_line.input(c) }
        path.each_char { |c| @command_line.input(c) }
        @handler.handle(13)

        new_window = @mock_mode_manager.window_manager.active_window
        assert_instance_of Mui::UndoManager, new_window.buffer.undo_manager
      end
    end
  end

  class TestTabNew < Minitest::Test
    include MuiTestHelper

    def setup
      @screen = Mui::TerminalAdapter::Test.new(width: 80, height: 24)
      @buffer = Mui::Buffer.new
      @tab_manager = Mui::TabManager.new(@screen)
      @tab_manager.add
      @window_manager = @tab_manager.current_tab.window_manager
      @window_manager.add_window(@buffer)
      @window = @window_manager.active_window
      @command_line = Mui::CommandLine.new
      @mock_mode_manager = MockModeManager.new(@window)
      @mock_mode_manager.window_manager = @window_manager
      @mock_mode_manager.editor = MockEditorWithTabManager.new(@tab_manager)
      @handler = Mui::KeyHandler::CommandMode.new(@mock_mode_manager, @buffer, @command_line)
    end

    def test_tabnew_sets_undo_manager
      "tabnew".each_char { |c| @command_line.input(c) }
      @handler.handle(13)

      current_tab = @mock_mode_manager.editor.tab_manager.current_tab
      buffer = current_tab.window_manager.active_window.buffer
      assert_instance_of Mui::UndoManager, buffer.undo_manager
    end

    def test_tabnew_with_path_sets_undo_manager
      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.txt")
        File.write(path, "test content\n")

        "tabnew ".each_char { |c| @command_line.input(c) }
        path.each_char { |c| @command_line.input(c) }
        @handler.handle(13)

        current_tab = @mock_mode_manager.editor.tab_manager.current_tab
        buffer = current_tab.window_manager.active_window.buffer
        assert_instance_of Mui::UndoManager, buffer.undo_manager
      end
    end
  end

  # Helper class for tab tests
  class MockEditorWithTabManager
    attr_reader :tab_manager

    def initialize(tab_manager)
      @tab_manager = tab_manager
    end

    def trigger_autocmd(_event); end
  end

  class TestFileCompletion < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @mode_manager = MockModeManager.new(@window)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
      @original_dir = Dir.pwd
      @test_dir = Dir.mktmpdir("mui_completion_test")
      Dir.chdir(@test_dir)
      FileUtils.touch("test.txt")
      FileUtils.touch("test.rb")
    end

    def teardown
      Dir.chdir(@original_dir)
      FileUtils.rm_rf(@test_dir)
    end

    def test_file_completion_for_e_command
      # Type "e " to trigger file completion mode
      @handler.handle("e")
      @handler.handle(" ")
      @handler.handle("t")
      @handler.handle("e")
      @handler.handle("s")
      @handler.handle("t")

      assert @handler.completion_state.active?
      assert_equal :file, @handler.completion_state.completion_type
    end

    def test_file_completion_applies_candidate
      # Type "e test" to trigger file completion
      @handler.handle("e")
      @handler.handle(" ")
      @handler.handle("t")
      @handler.handle("e")
      @handler.handle("s")
      @handler.handle("t")

      # TAB applies the selected candidate
      @handler.handle(Mui::KeyCode::TAB)

      assert_match(/^e test\./, @command_line.buffer)
    end
  end

  class TestOpenNewBufferSearchHighlight < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
      @buffer.lines[1] = "test line"
      @window = Mui::Window.new(@buffer)
      @command_line = Mui::CommandLine.new
      @search_state = Mui::SearchState.new
      @mode_manager = MockModeManager.new(@window, search_state: @search_state)
      @handler = Mui::KeyHandler::CommandMode.new(@mode_manager, @buffer, @command_line)
    end

    def test_recalculates_search_matches_on_buffer_switch
      # Set up search pattern in old buffer
      @search_state.set_pattern("hello", :forward)
      @search_state.find_all_matches(@buffer)

      # Verify matches exist in old buffer
      old_matches = @search_state.matches_for_row(0)
      assert_equal 1, old_matches.size
      assert_equal 0, old_matches.first[:col]

      Dir.mktmpdir do |dir|
        path = File.join(dir, "new_file.txt")
        File.write(path, "different content\nhello at line 2\n")

        # Open new buffer
        @command_line.input("e")
        @command_line.input(" ")
        path.each_char { |c| @command_line.input(c) }
        @handler.handle(13)

        # Verify search pattern is preserved
        assert @search_state.has_pattern?
        assert_equal "hello", @search_state.pattern

        # Verify matches are recalculated for new buffer
        # Line 0 should have no matches (content: "different content")
        assert_empty @search_state.matches_for_row(0)
        # Line 1 should have a match (content: "hello at line 2")
        new_matches = @search_state.matches_for_row(1)
        assert_equal 1, new_matches.size
        assert_equal 0, new_matches.first[:col]
      end
    end

    def test_does_not_call_find_all_matches_without_pattern
      # Ensure no pattern is set
      assert_nil @search_state.pattern

      Dir.mktmpdir do |dir|
        path = File.join(dir, "test.txt")
        File.write(path, "test content\n")

        @command_line.input("e")
        @command_line.input(" ")
        path.each_char { |c| @command_line.input(c) }
        @handler.handle(13)

        # No error should occur and matches should remain empty
        refute @search_state.has_pattern?
        assert_empty @search_state.matches_for_row(0)
      end
    end

    def test_clears_old_matches_when_new_buffer_has_no_matches
      # Set up search pattern that matches in old buffer
      @search_state.set_pattern("hello", :forward)
      @search_state.find_all_matches(@buffer)

      # Verify matches exist
      assert_equal 1, @search_state.matches_for_row(0).size

      Dir.mktmpdir do |dir|
        path = File.join(dir, "no_match.txt")
        File.write(path, "no matching content here\n")

        @command_line.input("e")
        @command_line.input(" ")
        path.each_char { |c| @command_line.input(c) }
        @handler.handle(13)

        # All rows should have no matches
        assert_empty @search_state.matches_for_row(0)
      end
    end
  end
end
