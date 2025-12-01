# frozen_string_literal: true

module Mui
  class Buffer
    attr_reader :lines, :name
    attr_accessor :modified

    def initialize(name = "[No Name]")
      @name = name
      @lines = [empty_line]
      @modified = false
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
      File.write(path, @lines.join("\n") + "\n")
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
      @lines[row] ||= empty_line
      @lines[row].insert(col, char)
      @modified = true
    end

    def delete_char(row, col)
      return if col < 0
      return if @lines[row].nil? || col >= @lines[row].size

      @lines[row].slice!(col)
      @modified = true
    end

    def insert_line(row, text = nil)
      @lines.insert(row, text&.dup || empty_line)
      @modified = true
    end

    def delete_line(row)
      @lines.delete_at(row)
      @lines = [empty_line] if @lines.empty?
      @modified = true
    end

    def split_line(row, col)
      return unless @lines[row]

      rest = (@lines[row][col..] || "").dup
      @lines[row] = (@lines[row][0...col] || "").dup
      insert_line(row + 1, rest)
    end

    def join_lines(row)
      return if row >= line_count - 1

      @lines[row] = ((@lines[row] || "") + (@lines[row + 1] || "")).dup
      delete_line(row + 1)
    end

    private

    def empty_line
      String.new
    end
  end
end
