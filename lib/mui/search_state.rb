# frozen_string_literal: true

module Mui
  class SearchState
    attr_reader :pattern, :direction, :matches

    def initialize
      @pattern = nil
      @direction = :forward
      @matches = []
    end

    def set_pattern(pattern, direction)
      @pattern = pattern
      @direction = direction
      @matches = []
    end

    def find_all_matches(buffer)
      @matches = []
      return if @pattern.nil? || @pattern.empty?

      begin
        regex = Regexp.new(@pattern)
        buffer.line_count.times do |row|
          line = buffer.line(row)
          scan_line_matches(line, row, regex)
        end
      rescue RegexpError
        # Invalid regex pattern - no matches
        @matches = []
      end
    end

    def find_next(current_row, current_col)
      return nil if @matches.empty?

      # Find next match after current position
      match = @matches.find do |m|
        m[:row] > current_row || (m[:row] == current_row && m[:col] > current_col)
      end

      # Wrap around to beginning if no match found
      match || @matches.first
    end

    def find_previous(current_row, current_col)
      return nil if @matches.empty?

      # Find previous match before current position
      match = @matches.reverse.find do |m|
        m[:row] < current_row || (m[:row] == current_row && m[:col] < current_col)
      end

      # Wrap around to end if no match found
      match || @matches.last
    end

    def clear
      @pattern = nil
      @matches = []
    end

    def has_pattern?
      !@pattern.nil? && !@pattern.empty?
    end

    def matches_for_row(row)
      @matches.select { |m| m[:row] == row }
    end

    private

    def scan_line_matches(line, row, regex)
      offset = 0
      while (match_data = line.match(regex, offset))
        col = match_data.begin(0)
        end_col = match_data.end(0) - 1
        @matches << { row: row, col: col, end_col: end_col }
        # Move offset past the end of the match to avoid overlapping matches
        offset = match_data.end(0)
        # Handle zero-length matches to prevent infinite loop
        offset += 1 if match_data[0].empty?
        break if offset >= line.length
      end
    end
  end
end
