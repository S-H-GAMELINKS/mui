# frozen_string_literal: true

module Mui
  module Highlighters
    class SearchHighlighter < Base
      def highlights_for(row, _line, options = {})
        search_state = options[:search_state]
        buffer = options[:buffer]
        return [] unless search_state&.has_pattern?

        matches = search_state.matches_for_row(row, buffer:)
        matches.map do |match|
          Highlight.new(
            start_col: match[:col],
            end_col: match[:end_col],
            style: :search_highlight,
            priority:
          )
        end
      end

      def priority
        PRIORITY_SEARCH
      end
    end
  end
end
