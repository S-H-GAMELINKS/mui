# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handler for line-wise visual mode (V)
    class VisualLineMode < VisualMode
      private

      def handle_v_key
        # v in visual line mode switches to visual mode
        result(mode: Mode::VISUAL, toggle_line_mode: true)
      end

      def handle_upper_v_key
        # V in visual line mode exits to normal mode
        result(mode: Mode::NORMAL, clear_selection: true)
      end
    end
  end
end
