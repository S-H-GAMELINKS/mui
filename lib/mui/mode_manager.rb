# frozen_string_literal: true

module Mui
  # Manages editor mode state and transitions
  class ModeManager
    attr_reader :mode, :selection, :register, :undo_manager

    def initialize(window:, buffer:, command_line:, undo_manager: nil)
      @window = window
      @buffer = buffer
      @command_line = command_line
      @register = Register.new
      @undo_manager = undo_manager
      @mode = Mode::NORMAL
      @selection = nil
      @visual_handler = nil

      initialize_key_handlers
    end

    def current_handler
      if visual_mode?
        @visual_handler || @key_handlers[Mode::NORMAL]
      else
        @key_handlers[@mode]
      end
    end

    def transition(result)
      return unless result.mode

      clear_visual_mode if result.clear_selection?

      case result.mode
      when Mode::VISUAL, Mode::VISUAL_LINE
        handle_visual_transition(result)
      when Mode::INSERT
        handle_insert_transition(result)
      else
        @mode = result.mode
      end
    end

    def visual_mode?
      @mode == Mode::VISUAL || @mode == Mode::VISUAL_LINE
    end

    private

    def initialize_key_handlers
      @key_handlers = {
        Mode::NORMAL => KeyHandler::NormalMode.new(@window, @buffer, @register, undo_manager: @undo_manager),
        # Use group_started: true to prevent begin_group on initialization
        # The handler will be replaced when actually entering Insert mode
        Mode::INSERT => KeyHandler::InsertMode.new(@window, @buffer, undo_manager: @undo_manager, group_started: true),
        Mode::COMMAND => KeyHandler::CommandMode.new(@window, @buffer, @command_line)
      }
    end

    def create_insert_handler(group_started: false)
      KeyHandler::InsertMode.new(@window, @buffer, undo_manager: @undo_manager, group_started: group_started)
    end

    def handle_insert_transition(result)
      group_started = result.respond_to?(:group_started?) && result.group_started?
      @key_handlers[Mode::INSERT] = create_insert_handler(group_started: group_started)
      @mode = Mode::INSERT
    end

    def handle_visual_transition(result)
      if result.start_selection?
        start_visual_mode(result.mode, result.line_mode?)
      elsif result.toggle_line_mode?
        toggle_visual_line_mode(result.mode)
      else
        @mode = result.mode
      end
    end

    def start_visual_mode(mode, line_mode)
      @mode = mode
      @visual_handler = create_visual_handler(line_mode: line_mode)
    end

    def clear_visual_mode
      @selection = nil
      @visual_handler = nil
    end

    def toggle_visual_line_mode(new_mode)
      return unless @selection

      new_line_mode = new_mode == Mode::VISUAL_LINE
      @selection = Selection.new(@selection.start_row, @selection.start_col, line_mode: new_line_mode)
      @selection.update_end(@window.cursor_row, @window.cursor_col)
      @visual_handler = create_visual_handler(line_mode: new_line_mode)
      @mode = new_mode
    end

    def create_visual_handler(line_mode:)
      @selection = Selection.new(@window.cursor_row, @window.cursor_col, line_mode: line_mode)

      if line_mode
        KeyHandler::VisualLineMode.new(@window, @buffer, @selection, @register, undo_manager: @undo_manager)
      else
        KeyHandler::VisualMode.new(@window, @buffer, @selection, @register, undo_manager: @undo_manager)
      end
    end
  end
end
