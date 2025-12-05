# frozen_string_literal: true

module Mui
  # Manages undo/redo stacks for the editor
  class UndoManager
    MAX_STACK_SIZE = 1000

    def initialize
      @undo_stack = []
      @redo_stack = []
      @current_group = nil
    end

    # Record a single action
    def record(action)
      if @current_group
        @current_group << action
      else
        push_to_undo_stack(action)
      end
      @redo_stack.clear
    end

    # Begin a group (for Insert mode)
    def begin_group
      @current_group = []
    end

    # End a group (when leaving Insert mode)
    def end_group
      return unless @current_group

      push_to_undo_stack(GroupAction.new(@current_group)) unless @current_group.empty?
      @current_group = nil
    end

    # Check if currently in a group
    def in_group?
      !@current_group.nil?
    end

    def undo(buffer)
      return false if @undo_stack.empty?

      action = @undo_stack.pop
      action.undo(buffer)
      @redo_stack.push(action)
      true
    end

    def redo(buffer)
      return false if @redo_stack.empty?

      action = @redo_stack.pop
      action.execute(buffer)
      @undo_stack.push(action)
      true
    end

    def can_undo?
      !@undo_stack.empty?
    end

    def can_redo?
      !@redo_stack.empty?
    end

    def undo_stack_size
      @undo_stack.size
    end

    def redo_stack_size
      @redo_stack.size
    end

    private

    def push_to_undo_stack(action)
      @undo_stack.shift if @undo_stack.size >= MAX_STACK_SIZE
      @undo_stack.push(action)
    end
  end
end
