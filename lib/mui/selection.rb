# frozen_string_literal: true

module Mui
  class Selection
    attr_accessor :start_row, :start_col, :end_row, :end_col
    attr_reader :line_mode

    def initialize(start_row, start_col, line_mode: false)
      @start_row = start_row
      @start_col = start_col
      @end_row = start_row
      @end_col = start_col
      @line_mode = line_mode
    end

    def update_end(row, col)
      @end_row = row
      @end_col = col
    end

    def normalized_range
      if @start_row < @end_row || (@start_row == @end_row && @start_col <= @end_col)
        { start_row: @start_row, start_col: @start_col, end_row: @end_row, end_col: @end_col }
      else
        { start_row: @end_row, start_col: @end_col, end_row: @start_row, end_col: @start_col }
      end
    end

    def covers_position?(row, col, buffer)
      range = normalized_range

      if @line_mode
        row.between?(range[:start_row], range[:end_row])
      else
        covers_character_position?(row, col, range, buffer)
      end
    end

    private

    def covers_character_position?(row, col, range, _buffer)
      return false if row < range[:start_row] || row > range[:end_row]

      if range[:start_row] == range[:end_row]
        col.between?(range[:start_col], range[:end_col])
      elsif row == range[:start_row]
        col >= range[:start_col]
      elsif row == range[:end_row]
        col <= range[:end_col]
      else
        true
      end
    end
  end
end
