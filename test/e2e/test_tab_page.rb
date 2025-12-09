# frozen_string_literal: true

require_relative "test_helper"

class TestE2ETabPage < Minitest::Test
  include MuiTestHelper

  def setup
    clear_key_sequence
  end

  def teardown
    clear_key_sequence
  end

  # Tab creation commands
  def test_tabnew_creates_new_tab
    runner = ScriptRunner.new

    runner
      .assert_tab_count(1)
      .type(":tabnew<Enter>")
      .assert_tab_count(2)
      .assert_current_tab(1)
  end

  def test_tabe_creates_new_tab
    runner = ScriptRunner.new

    runner
      .assert_tab_count(1)
      .type(":tabe<Enter>")
      .assert_tab_count(2)
  end

  def test_tabedit_creates_new_tab
    runner = ScriptRunner.new

    runner
      .assert_tab_count(1)
      .type(":tabedit<Enter>")
      .assert_tab_count(2)
  end

  # Tab navigation commands
  def test_tabnext_moves_to_next_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .assert_tab_count(2)
      .assert_current_tab(1)
      .type(":tabprev<Enter>")
      .assert_current_tab(0)
      .type(":tabnext<Enter>")
      .assert_current_tab(1)
  end

  def test_tabn_alias_moves_to_next_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabprev<Enter>")
      .assert_current_tab(0)
      .type(":tabn<Enter>")
      .assert_current_tab(1)
  end

  def test_tabprev_moves_to_previous_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .assert_current_tab(1)
      .type(":tabprev<Enter>")
      .assert_current_tab(0)
  end

  def test_tabp_alias_moves_to_previous_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .assert_current_tab(1)
      .type(":tabp<Enter>")
      .assert_current_tab(0)
  end

  def test_tabfirst_moves_to_first_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .assert_tab_count(3)
      .assert_current_tab(2)
      .type(":tabfirst<Enter>")
      .assert_current_tab(0)
  end

  def test_tabf_alias_moves_to_first_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .assert_current_tab(2)
      .type(":tabf<Enter>")
      .assert_current_tab(0)
  end

  def test_tablast_moves_to_last_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .type(":tabfirst<Enter>")
      .assert_current_tab(0)
      .type(":tablast<Enter>")
      .assert_current_tab(2)
  end

  def test_tabl_alias_moves_to_last_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .type(":tabfirst<Enter>")
      .type(":tabl<Enter>")
      .assert_current_tab(2)
  end

  def test_tab_navigation_wraps_around
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .assert_tab_count(2)
      .assert_current_tab(1)
      .type(":tabnext<Enter>")
      .assert_current_tab(0)
  end

  def test_tab_navigation_wraps_backward
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabfirst<Enter>")
      .assert_current_tab(0)
      .type(":tabprev<Enter>")
      .assert_current_tab(1)
  end

  # Tab close commands
  def test_tabclose_closes_current_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .assert_tab_count(3)
      .assert_current_tab(2)
      .type(":tabclose<Enter>")
      .assert_tab_count(2)
      .assert_current_tab(1)
  end

  def test_tabc_alias_closes_current_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .assert_tab_count(3)
      .type(":tabc<Enter>")
      .assert_tab_count(2)
  end

  def test_cannot_close_last_tab
    runner = ScriptRunner.new

    runner
      .assert_tab_count(1)
      .type(":tabclose<Enter>")
      .assert_tab_count(1)
      .assert_message_contains("Cannot close last tab")
  end

  # :q closes tab when multiple tabs exist
  def test_quit_closes_tab_when_multiple_tabs
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .assert_tab_count(3)
      .assert_current_tab(2)
      .type(":q<Enter>")
      .assert_tab_count(2)
      .assert_running(true) # Editor should still be running
  end

  def test_quit_closes_editor_when_single_tab
    runner = ScriptRunner.new

    runner
      .assert_tab_count(1)
      .type(":q<Enter>")
      .assert_running(false) # Editor should quit
  end

  def test_quit_closes_window_first_then_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .assert_tab_count(2)
      .type("<C-w>s") # Split window in current tab
      .assert_window_count(2)
      .type(":q<Enter>")
      .assert_window_count(1) # Window closed, but tab still exists
      .assert_tab_count(2)
      .type(":q<Enter>")
      .assert_tab_count(1) # Now tab is closed
      .assert_running(true) # Still running because first tab exists
  end

  # gt/gT keybindings
  def test_gt_moves_to_next_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabfirst<Enter>")
      .assert_current_tab(0)
      .type("gt")
      .assert_current_tab(1)
  end

  # rubocop:disable Naming/MethodName
  def test_gT_moves_to_previous_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .assert_current_tab(1)
      .type("gT")
      .assert_current_tab(0)
  end
  # rubocop:enable Naming/MethodName

  def test_gt_wraps_around
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .assert_current_tab(1)
      .type("gt")
      .assert_current_tab(0)
  end

  # rubocop:disable Naming/MethodName
  def test_gT_wraps_backward
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabfirst<Enter>")
      .assert_current_tab(0)
      .type("gT")
      .assert_current_tab(1)
  end
  # rubocop:enable Naming/MethodName

  # Tab go command (Ntabn)
  def test_number_tabn_goes_to_specific_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .assert_tab_count(4)
      .assert_current_tab(3)
      .type(":1tabn<Enter>")
      .assert_current_tab(0)
      .type(":3tabn<Enter>")
      .assert_current_tab(2)
  end

  def test_tabnext_with_number_goes_to_specific_tab
    runner = ScriptRunner.new

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .assert_tab_count(3)
      .assert_current_tab(2)
      .type(":tabnext 1<Enter>")
      .assert_current_tab(0)
  end

  # Tab move command
  def test_tabmove_moves_tab_to_position
    runner = ScriptRunner.new
    tab_manager = runner.editor.tab_manager

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .type(":tabfirst<Enter>")
      .assert_tab_count(3)
      .assert_current_tab(0)

    first_tab = tab_manager.current_tab

    runner.type(":tabmove 2<Enter>")

    assert_equal 2, tab_manager.current_index
    assert_equal first_tab, tab_manager.current_tab
  end

  def test_tabm_alias_moves_tab
    runner = ScriptRunner.new
    tab_manager = runner.editor.tab_manager

    runner
      .type(":tabnew<Enter>")
      .type(":tabnew<Enter>")
      .type(":tabfirst<Enter>")

    first_tab = tab_manager.current_tab

    runner.type(":tabm 1<Enter>")

    assert_equal 1, tab_manager.current_index
    assert_equal first_tab, tab_manager.current_tab
  end

  # Tabs maintain separate windows
  def test_each_tab_has_independent_windows
    runner = ScriptRunner.new
    tab_manager = runner.editor.tab_manager

    # First tab: create 2 windows
    runner
      .type("<C-w>s")
      .assert_tab_count(1)
      .assert_window_count(2)

    # Create second tab
    runner.type(":tabnew<Enter>")

    assert_equal 2, tab_manager.tab_count
    assert_equal 1, tab_manager.current_tab.window_manager.window_count

    # Go back to first tab
    runner.type(":tabfirst<Enter>")

    assert_equal 2, tab_manager.current_tab.window_manager.window_count
  end

  # Tabs maintain separate buffers
  def test_tabs_can_have_different_content
    runner = ScriptRunner.new
    tab_manager = runner.editor.tab_manager

    # First tab: add some content
    runner
      .type("i")
      .type("Tab 1 content")
      .type("<Esc>")

    # Create second tab and add different content
    runner
      .type(":tabnew<Enter>")
      .type("i")
      .type("Tab 2 content")
      .type("<Esc>")

    # Check content in each tab
    tab2_buffer = tab_manager.current_tab.active_window.buffer
    assert_equal "Tab 2 content", tab2_buffer.line(0)

    runner.type(":tabfirst<Enter>")

    tab1_buffer = tab_manager.current_tab.active_window.buffer
    assert_equal "Tab 1 content", tab1_buffer.line(0)
  end

  # gg motion still works
  def test_gg_motion_still_works
    runner = ScriptRunner.new

    runner
      .type("i")
      .type("line 1")
      .type("<Enter>")
      .type("line 2")
      .type("<Enter>")
      .type("line 3")
      .type("<Esc>")
      .assert_cursor(2, 5)
      .type("gg")
      .assert_cursor(0, 0)
  end
end
