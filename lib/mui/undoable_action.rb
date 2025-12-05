# frozen_string_literal: true

module Mui
  # Base class for undoable actions
  class UndoableAction
    def execute(buffer); end
    def undo(buffer); end
  end

  # Insert a single character
  class InsertCharAction < UndoableAction
    def initialize(row, col, char)
      super()
      @row = row
      @col = col
      @char = char
    end

    def execute(buffer)
      buffer.insert_char_without_record(@row, @col, @char)
    end

    def undo(buffer)
      buffer.delete_char_without_record(@row, @col)
    end
  end

  # Delete a single character
  class DeleteCharAction < UndoableAction
    def initialize(row, col, char)
      super()
      @row = row
      @col = col
      @char = char
    end

    def execute(buffer)
      buffer.delete_char_without_record(@row, @col)
    end

    def undo(buffer)
      buffer.insert_char_without_record(@row, @col, @char)
    end
  end

  # Insert a line
  class InsertLineAction < UndoableAction
    def initialize(row, text)
      super()
      @row = row
      @text = text
    end

    def execute(buffer)
      buffer.insert_line_without_record(@row, @text)
    end

    def undo(buffer)
      buffer.delete_line_without_record(@row)
    end
  end

  # Delete a line
  class DeleteLineAction < UndoableAction
    def initialize(row, text)
      super()
      @row = row
      @text = text
    end

    def execute(buffer)
      buffer.delete_line_without_record(@row)
    end

    def undo(buffer)
      buffer.insert_line_without_record(@row, @text)
    end
  end

  # Split a line (Enter key)
  class SplitLineAction < UndoableAction
    def initialize(row, col)
      super()
      @row = row
      @col = col
    end

    def execute(buffer)
      buffer.split_line_without_record(@row, @col)
    end

    def undo(buffer)
      buffer.join_lines_without_record(@row)
    end
  end

  # Join lines (Backspace at line start)
  class JoinLinesAction < UndoableAction
    def initialize(row, col)
      super()
      @row = row
      @col = col
    end

    def execute(buffer)
      buffer.join_lines_without_record(@row)
    end

    def undo(buffer)
      buffer.split_line_without_record(@row, @col)
    end
  end

  # Delete a range of text
  class DeleteRangeAction < UndoableAction
    def initialize(start_row, start_col, end_row, end_col, deleted_lines)
      super()
      @start_row = start_row
      @start_col = start_col
      @end_row = end_row
      @end_col = end_col
      @deleted_lines = deleted_lines
    end

    def execute(buffer)
      buffer.delete_range_without_record(@start_row, @start_col, @end_row, @end_col)
    end

    def undo(buffer)
      buffer.restore_range(@start_row, @start_col, @deleted_lines)
    end
  end

  # Replace line content (for cc command)
  class ReplaceLineAction < UndoableAction
    def initialize(row, old_text, new_text)
      super()
      @row = row
      @old_text = old_text
      @new_text = new_text
    end

    def execute(buffer)
      buffer.replace_line_without_record(@row, @new_text)
    end

    def undo(buffer)
      buffer.replace_line_without_record(@row, @old_text)
    end
  end

  # Group multiple actions into one undo unit
  class GroupAction < UndoableAction
    def initialize(actions)
      super()
      @actions = actions
    end

    def execute(buffer)
      @actions.each { |action| action.execute(buffer) }
    end

    def undo(buffer)
      @actions.reverse_each { |action| action.undo(buffer) }
    end

    def empty?
      @actions.empty?
    end

    def size
      @actions.size
    end
  end
end
