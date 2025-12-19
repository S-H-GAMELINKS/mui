# frozen_string_literal: true

require "test_helper"

module Mui
  class TestModeManager < Minitest::Test
    def setup
      @buffer = Buffer.new
      @window = Window.new(@buffer, width: 80, height: 24)
      @command_line = CommandLine.new
      @mode_manager = ModeManager.new(
        window: @window,
        buffer: @buffer,
        command_line: @command_line
      )
    end

    def test_initial_mode_is_normal
      assert_equal Mode::NORMAL, @mode_manager.mode
    end

    def test_initial_selection_is_nil
      assert_nil @mode_manager.selection
    end

    def test_visual_mode_returns_false_initially
      refute_predicate @mode_manager, :visual_mode?
    end

    def test_current_handler_returns_normal_mode_handler
      assert_instance_of KeyHandler::NormalMode, @mode_manager.current_handler
    end

    def test_transition_to_insert_mode
      result = HandlerResult::NormalModeResult.new(mode: Mode::INSERT)

      @mode_manager.transition(result)

      assert_equal Mode::INSERT, @mode_manager.mode
    end

    def test_transition_to_command_mode
      result = HandlerResult::NormalModeResult.new(mode: Mode::COMMAND)

      @mode_manager.transition(result)

      assert_equal Mode::COMMAND, @mode_manager.mode
    end

    def test_current_handler_returns_insert_mode_handler_after_transition
      result = HandlerResult::NormalModeResult.new(mode: Mode::INSERT)
      @mode_manager.transition(result)

      assert_instance_of KeyHandler::InsertMode, @mode_manager.current_handler
    end

    def test_current_handler_returns_command_mode_handler_after_transition
      result = HandlerResult::NormalModeResult.new(mode: Mode::COMMAND)
      @mode_manager.transition(result)

      assert_instance_of KeyHandler::CommandMode, @mode_manager.current_handler
    end

    def test_transition_to_visual_mode_with_start_selection
      result = HandlerResult::NormalModeResult.new(
        mode: Mode::VISUAL,
        start_selection: true,
        line_mode: false
      )

      @mode_manager.transition(result)

      assert_equal Mode::VISUAL, @mode_manager.mode
      assert_predicate @mode_manager, :visual_mode?
      assert_instance_of Selection, @mode_manager.selection
      refute @mode_manager.selection.line_mode
    end

    def test_transition_to_visual_line_mode_with_start_selection
      result = HandlerResult::NormalModeResult.new(
        mode: Mode::VISUAL_LINE,
        start_selection: true,
        line_mode: true
      )

      @mode_manager.transition(result)

      assert_equal Mode::VISUAL_LINE, @mode_manager.mode
      assert_predicate @mode_manager, :visual_mode?
      assert_instance_of Selection, @mode_manager.selection
      assert @mode_manager.selection.line_mode
    end

    def test_current_handler_returns_visual_mode_handler_after_visual_transition
      result = HandlerResult::NormalModeResult.new(
        mode: Mode::VISUAL,
        start_selection: true,
        line_mode: false
      )
      @mode_manager.transition(result)

      assert_instance_of KeyHandler::VisualMode, @mode_manager.current_handler
    end

    def test_current_handler_returns_visual_line_mode_handler_after_visual_line_transition
      result = HandlerResult::NormalModeResult.new(
        mode: Mode::VISUAL_LINE,
        start_selection: true,
        line_mode: true
      )
      @mode_manager.transition(result)

      assert_instance_of KeyHandler::VisualLineMode, @mode_manager.current_handler
    end

    def test_transition_to_normal_with_clear_selection
      # First enter visual mode
      visual_result = HandlerResult::NormalModeResult.new(
        mode: Mode::VISUAL,
        start_selection: true,
        line_mode: false
      )
      @mode_manager.transition(visual_result)

      # Then exit to normal mode
      normal_result = HandlerResult::VisualModeResult.new(
        mode: Mode::NORMAL,
        clear_selection: true
      )
      @mode_manager.transition(normal_result)

      assert_equal Mode::NORMAL, @mode_manager.mode
      refute_predicate @mode_manager, :visual_mode?
      assert_nil @mode_manager.selection
    end

    def test_toggle_visual_line_mode
      # First enter visual mode
      visual_result = HandlerResult::NormalModeResult.new(
        mode: Mode::VISUAL,
        start_selection: true,
        line_mode: false
      )
      @mode_manager.transition(visual_result)

      # Then toggle to visual line mode
      toggle_result = HandlerResult::VisualModeResult.new(
        mode: Mode::VISUAL_LINE,
        toggle_line_mode: true
      )
      @mode_manager.transition(toggle_result)

      assert_equal Mode::VISUAL_LINE, @mode_manager.mode
      assert @mode_manager.selection.line_mode
      assert_instance_of KeyHandler::VisualLineMode, @mode_manager.current_handler
    end

    def test_toggle_from_visual_line_to_visual_mode
      # First enter visual line mode
      visual_line_result = HandlerResult::NormalModeResult.new(
        mode: Mode::VISUAL_LINE,
        start_selection: true,
        line_mode: true
      )
      @mode_manager.transition(visual_line_result)

      # Then toggle to visual mode
      toggle_result = HandlerResult::VisualModeResult.new(
        mode: Mode::VISUAL,
        toggle_line_mode: true
      )
      @mode_manager.transition(toggle_result)

      assert_equal Mode::VISUAL, @mode_manager.mode
      refute @mode_manager.selection.line_mode
      assert_instance_of KeyHandler::VisualMode, @mode_manager.current_handler
    end

    def test_transition_with_nil_result_mode_does_nothing
      original_mode = @mode_manager.mode

      result = HandlerResult::Base.new(mode: nil)
      @mode_manager.transition(result)

      assert_equal original_mode, @mode_manager.mode
    end
  end
end
