# frozen_string_literal: true

module Mui
  # Manages editor mode state and transitions
  class ModeManager
    attr_reader :mode, :selection, :register, :undo_manager, :search_state, :search_input, :editor,
                :last_visual_selection, :key_sequence_handler

    def initialize(window:, buffer:, command_line:, undo_manager: nil, editor: nil, register: nil, key_sequence_handler: nil)
      @tab_manager = window.is_a?(TabManager) ? window : nil
      @window_manager = window.is_a?(WindowManager) ? window : nil
      @window = !@tab_manager && !@window_manager ? window : nil
      @buffer = buffer
      @command_line = command_line
      @register = register || Mui.register
      @undo_manager = undo_manager
      @editor = editor
      @key_sequence_handler = key_sequence_handler
      @search_state = SearchState.new
      @search_input = SearchInput.new
      @mode = Mode::NORMAL
      @selection = nil
      @visual_handler = nil
      @last_visual_selection = nil

      initialize_key_handlers
    end

    def window_manager
      @tab_manager&.window_manager || @window_manager
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
        handle_insert_transition(result, result.mode)
      when Mode::SEARCH_FORWARD
        handle_search_transition("/", result.mode)
      when Mode::SEARCH_BACKWARD
        handle_search_transition("?", result.mode)
      else
        @mode = result.mode
      end
    end

    def visual_mode?
      @mode == Mode::VISUAL || @mode == Mode::VISUAL_LINE
    end

    def active_window
      @tab_manager&.active_window || @window_manager&.active_window || @window
    end

    alias window active_window

    def restore_visual_selection
      return unless @last_visual_selection

      line_mode = @last_visual_selection[:line_mode]
      @mode = line_mode ? Mode::VISUAL_LINE : Mode::VISUAL
      @selection = Selection.new(
        @last_visual_selection[:start_row],
        @last_visual_selection[:start_col],
        line_mode:
      )
      @selection.update_end(
        @last_visual_selection[:end_row],
        @last_visual_selection[:end_col]
      )
      @visual_handler = create_visual_handler(line_mode:)

      # Move cursor to end of selection
      active_window.cursor_row = @last_visual_selection[:end_row]
      active_window.cursor_col = @last_visual_selection[:end_col]
    end

    private

    def initialize_key_handlers
      @key_handlers = {
        Mode::NORMAL => KeyHandler::NormalMode.new(self, @buffer, @register, undo_manager: @undo_manager, search_state: @search_state),
        # Use group_started: true to prevent begin_group on initialization
        # The handler will be replaced when actually entering Insert mode
        Mode::INSERT => KeyHandler::InsertMode.new(self, @buffer, undo_manager: @undo_manager, group_started: true),
        Mode::COMMAND => KeyHandler::CommandMode.new(self, @buffer, @command_line),
        Mode::SEARCH_FORWARD => KeyHandler::SearchMode.new(self, @buffer, @search_input, @search_state),
        Mode::SEARCH_BACKWARD => KeyHandler::SearchMode.new(self, @buffer, @search_input, @search_state)
      }
    end

    def create_insert_handler(group_started: false)
      KeyHandler::InsertMode.new(self, @buffer, undo_manager: @undo_manager, group_started:)
    end

    def handle_insert_transition(result, mode)
      group_started = result.respond_to?(:group_started?) && result.group_started?
      @key_handlers[mode] = create_insert_handler(group_started:)
      @mode = mode
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
      @selection = Selection.new(active_window.cursor_row, active_window.cursor_col, line_mode:)
      @visual_handler = create_visual_handler(line_mode:)
    end

    def clear_visual_mode
      save_visual_selection if @selection
      @selection = nil
      @visual_handler = nil
    end

    def save_visual_selection
      return unless @selection

      @last_visual_selection = {
        start_row: @selection.start_row,
        start_col: @selection.start_col,
        end_row: @selection.end_row,
        end_col: @selection.end_col,
        line_mode: @selection.line_mode
      }
    end

    def toggle_visual_line_mode(new_mode)
      return unless @selection

      line_mode = new_mode == Mode::VISUAL_LINE
      @selection = Selection.new(@selection.start_row, @selection.start_col, line_mode:)
      @selection.update_end(active_window.cursor_row, active_window.cursor_col)
      @visual_handler = create_visual_handler(line_mode:)
      @mode = new_mode
    end

    def create_visual_handler(line_mode:)
      if line_mode
        KeyHandler::VisualLineMode.new(self, @buffer, @selection, @register, undo_manager: @undo_manager)
      else
        KeyHandler::VisualMode.new(self, @buffer, @selection, @register, undo_manager: @undo_manager)
      end
    end

    def handle_search_transition(prompt, mode)
      @search_input.clear
      @search_input.set_prompt(prompt)
      @key_handlers[mode].start_search
      @mode = mode
    end
  end
end
