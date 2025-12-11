# frozen_string_literal: true

module Mui
  class Buffer
    attr_reader :lines
    attr_accessor :name, :modified, :undo_manager, :readonly

    # Alias for autocmd pattern matching
    alias file_path name

    def initialize(name = "[No Name]")
      @name = name
      @lines = [empty_line]
      @modified = false
      @undo_manager = nil
      @readonly = false
      @custom_highlighter_map = {}
    end

    def readonly?
      @readonly
    end

    # Override in subclasses to provide buffer-specific highlighters
    def custom_highlighters(_color_scheme)
      @custom_highlighter_map.values
    end

    # Add a custom highlighter with a unique key
    def add_custom_highlighter(key, highlighter)
      @custom_highlighter_map[key] = highlighter
    end

    # Remove a custom highlighter by key
    def remove_custom_highlighter(key)
      @custom_highlighter_map.delete(key)
    end

    # Check if a custom highlighter exists
    def custom_highlighter?(key)
      @custom_highlighter_map.key?(key)
    end

    # Set content directly (for scratch buffers)
    def content=(text)
      @lines = text.split("\n", -1)
      @lines = [empty_line] if @lines.empty?
      @modified = false
    end

    # Reload file from disk
    def reload
      return unless @name && File.exist?(@name)

      load(@name)
    end

    def load(path)
      @name = path
      if File.exist?(path)
        @lines = File.readlines(path, chomp: true)
        @lines = [empty_line] if @lines.empty?
      end
      @modified = false
    end

    def save(path = @name)
      File.write(path, "#{@lines.join("\n")}\n")
      @name = path
      @modified = false
    end

    def line_count
      @lines.size
    end

    def line(n)
      @lines[n] || ""
    end

    def insert_char(row, col, char)
      with_undo(InsertCharAction.new(row, col, char)) do
        insert_char_without_record(row, col, char)
      end
    end

    def delete_char(row, col)
      return unless valid_char_position?(row, col)

      char = @lines[row][col]
      with_undo(DeleteCharAction.new(row, col, char)) do
        delete_char_without_record(row, col)
      end
    end

    def insert_line(row, text = nil)
      actual_text = text&.dup || empty_line
      with_undo(InsertLineAction.new(row, actual_text)) do
        insert_line_without_record(row, actual_text)
      end
    end

    def delete_line(row)
      text = @lines[row]&.dup
      return unless text

      with_undo(DeleteLineAction.new(row, text)) do
        delete_line_without_record(row)
      end
    end

    def split_line(row, col)
      return unless @lines[row]

      with_undo(SplitLineAction.new(row, col)) do
        split_line_without_record(row, col)
      end
    end

    def join_lines(row)
      return if row >= line_count - 1

      col = @lines[row]&.size || 0
      with_undo(JoinLinesAction.new(row, col)) do
        join_lines_without_record(row)
      end
    end

    def delete_range(start_row, start_col, end_row, end_col)
      deleted_lines = capture_range(start_row, start_col, end_row, end_col)
      with_undo(DeleteRangeAction.new(start_row, start_col, end_row, end_col, deleted_lines)) do
        delete_range_without_record(start_row, start_col, end_row, end_col)
      end
    end

    def replace_line(row, text)
      old_text = @lines[row]&.dup || empty_line
      with_undo(ReplaceLineAction.new(row, old_text, text.dup)) do
        replace_line_without_record(row, text)
      end
    end

    def insert_char_without_record(row, col, char)
      @lines[row] ||= empty_line
      @lines[row].insert(col, char)
      @modified = true
    end

    def delete_char_without_record(row, col)
      return unless valid_char_position?(row, col)

      @lines[row].slice!(col)
      @modified = true
    end

    def insert_line_without_record(row, text = nil)
      @lines.insert(row, text&.dup || empty_line)
      @modified = true
    end

    def delete_line_without_record(row)
      @lines.delete_at(row)
      @lines = [empty_line] if @lines.empty?
      @modified = true
    end

    def split_line_without_record(row, col)
      return unless @lines[row]

      rest = (@lines[row][col..] || "").dup
      @lines[row] = (@lines[row][0...col] || "").dup
      insert_line_without_record(row + 1, rest)
    end

    def join_lines_without_record(row)
      return if row >= line_count - 1

      @lines[row] = ((@lines[row] || "") + (@lines[row + 1] || "")).dup
      delete_line_without_record(row + 1)
    end

    def delete_range_without_record(start_row, start_col, end_row, end_col)
      if start_row == end_row
        delete_within_line(start_row, start_col, end_col)
      else
        delete_across_lines(start_row, start_col, end_row, end_col)
      end
      @modified = true
    end

    def replace_line_without_record(row, text)
      @lines[row] = text.dup
      @modified = true
    end

    def restore_range(start_row, start_col, deleted_lines)
      return if deleted_lines.empty?

      current_line = @lines[start_row] || empty_line
      if deleted_lines.size == 1
        # Single line restore: insert at start_col
        @lines[start_row] = current_line[0...start_col] + deleted_lines[0] + current_line[start_col..]
      else
        # Multi-line restore
        first_part = current_line[0...start_col]
        last_part = current_line[start_col..]

        # Set first line
        @lines[start_row] = first_part + deleted_lines[0]

        # Insert middle lines
        (1...(deleted_lines.size - 1)).each do |i|
          @lines.insert(start_row + i, deleted_lines[i].dup)
        end

        # Insert last line with remainder
        last_deleted = deleted_lines[-1]
        @lines.insert(start_row + deleted_lines.size - 1, last_deleted + last_part)
      end
      @modified = true
    end

    private

    def with_undo(action)
      @undo_manager&.record(action)
      yield
    end

    def valid_char_position?(row, col)
      !col.negative? && @lines[row] && col < @lines[row].size
    end

    def empty_line
      String.new
    end

    def capture_range(start_row, start_col, end_row, end_col)
      if start_row == end_row
        line = @lines[start_row] || ""
        [line[start_col..end_col] || ""]
      else
        lines = []
        lines << ((@lines[start_row] || "")[start_col..] || "")
        ((start_row + 1)...end_row).each do |row|
          lines << (@lines[row]&.dup || "")
        end
        lines << ((@lines[end_row] || "")[0..end_col] || "")
        lines
      end
    end

    def delete_within_line(row, start_col, end_col)
      line = @lines[row] || ""
      @lines[row] = (line[0...start_col] || "") + (line[(end_col + 1)..] || "")
    end

    def delete_across_lines(start_row, start_col, end_row, end_col)
      first_part = (@lines[start_row] || "")[0...start_col] || ""
      last_part = (@lines[end_row] || "")[(end_col + 1)..] || ""

      (end_row - start_row).times { @lines.delete_at(start_row + 1) }

      @lines[start_row] = first_part + last_part
    end
  end
end
