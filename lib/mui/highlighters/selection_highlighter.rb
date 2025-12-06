# frozen_string_literal: true

module Mui
  module Highlighters
    class SelectionHighlighter < Base
      def highlights_for(row, line, options = {})
        selection = options[:selection]
        return [] unless selection

        range = selection.normalized_range
        return [] if row < range[:start_row] || row > range[:end_row]

        if selection.line_mode
          line_mode_highlights(line)
        else
          char_mode_highlights(row, line, range)
        end
      end

      def priority
        PRIORITY_SELECTION
      end

      private

      def line_mode_highlights(line)
        [Highlight.new(
          start_col: 0,
          end_col: [line.length - 1, 0].max,
          style: :visual_selection,
          priority:
        )]
      end

      def char_mode_highlights(row, line, range)
        start_col = row == range[:start_row] ? range[:start_col] : 0
        end_col = row == range[:end_row] ? range[:end_col] : [line.length - 1, 0].max

        [Highlight.new(
          start_col:,
          end_col:,
          style: :visual_selection,
          priority:
        )]
      end
    end
  end
end
