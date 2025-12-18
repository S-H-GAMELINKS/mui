# frozen_string_literal: true

module Mui
  class SearchState
    attr_reader :pattern, :direction

    def initialize
      @pattern = nil
      @direction = :forward
      @pattern_version = 0
      @buffer_matches = {} # { buffer_object_id => { version:, matches: [] } }
    end

    def set_pattern(pattern, direction)
      @pattern = pattern
      @direction = direction
      @pattern_version += 1
      @buffer_matches.clear # Invalidate all cached matches
    end

    # Calculate matches for a specific buffer (used for n/N navigation)
    def find_all_matches(buffer)
      return [] if @pattern.nil? || @pattern.empty? || buffer.nil?

      get_or_calculate_matches(buffer)
    end

    def find_next(current_row, current_col, buffer: nil)
      matches = buffer ? get_or_calculate_matches(buffer) : []
      return nil if matches.empty?

      # Find next match after current position
      match = matches.find do |m|
        m[:row] > current_row || (m[:row] == current_row && m[:col] > current_col)
      end

      # Wrap around to beginning if no match found
      match || matches.first
    end

    def find_previous(current_row, current_col, buffer: nil)
      matches = buffer ? get_or_calculate_matches(buffer) : []
      return nil if matches.empty?

      # Find previous match before current position
      match = matches.reverse.find do |m|
        m[:row] < current_row || (m[:row] == current_row && m[:col] < current_col)
      end

      # Wrap around to end if no match found
      match || matches.last
    end

    def clear
      @pattern = nil
      @pattern_version += 1
      @buffer_matches.clear
    end

    def has_pattern?
      !@pattern.nil? && !@pattern.empty?
    end

    # Get matches for a specific row in a specific buffer
    # O(1) lookup using row_index
    def matches_for_row(row, buffer: nil)
      return [] if buffer.nil?

      cache = get_or_calculate_cache(buffer)
      cache[:row_index][row] || []
    end

    private

    def get_or_calculate_matches(buffer)
      get_or_calculate_cache(buffer)[:matches]
    end

    def get_or_calculate_cache(buffer)
      buffer_id = buffer.object_id
      cached = @buffer_matches[buffer_id]

      # Return cached data if valid (same pattern version and buffer hasn't changed)
      return cached if cached && cached[:version] == @pattern_version && cached[:change_count] == buffer.change_count

      # Calculate and cache matches for this buffer
      matches, row_index = calculate_matches(buffer)
      @buffer_matches[buffer_id] = {
        version: @pattern_version,
        change_count: buffer.change_count,
        matches:,
        row_index:
      }
      @buffer_matches[buffer_id]
    end

    def calculate_matches(buffer)
      empty_result = [[], {}]
      return empty_result if @pattern.nil? || @pattern.empty?

      matches = []
      row_index = {}
      begin
        regex = Regexp.new(@pattern)
        buffer.line_count.times do |row|
          line = buffer.line(row)
          row_matches = scan_line_matches(line, row, regex)
          unless row_matches.empty?
            matches.concat(row_matches)
            row_index[row] = row_matches
          end
        end
      rescue RegexpError
        # Invalid regex pattern - no matches
      end
      [matches, row_index]
    end

    def scan_line_matches(line, row, regex)
      matches = []
      offset = 0
      while (match_data = line.match(regex, offset))
        col = match_data.begin(0)
        end_col = match_data.end(0) - 1
        matches << { row:, col:, end_col: }
        # Move offset past the end of the match to avoid overlapping matches
        offset = match_data.end(0)
        # Handle zero-length matches to prevent infinite loop
        offset += 1 if match_data[0].empty?
        break if offset >= line.length
      end
      matches
    end
  end
end
