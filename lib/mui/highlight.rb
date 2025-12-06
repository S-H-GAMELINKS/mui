# frozen_string_literal: true

module Mui
  class Highlight
    attr_reader :start_col, :end_col, :style, :priority

    def initialize(start_col:, end_col:, style:, priority:)
      @start_col = start_col
      @end_col = end_col
      @style = style
      @priority = priority
    end

    def overlaps?(other)
      start_col <= other.end_col && end_col >= other.start_col
    end

    def <=>(other)
      [start_col, -priority] <=> [other.start_col, -other.priority]
    end
  end
end
