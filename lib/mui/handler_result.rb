# frozen_string_literal: true

module Mui
  module HandlerResult
    # Base class for handler results with common attributes and default implementations
    class Base
      attr_reader :mode, :message

      def initialize(mode: nil, message: nil, quit: false)
        @mode = mode
        @message = message
        @quit = quit
        freeze
      end

      def quit?
        @quit
      end

      def start_selection?
        false
      end

      def line_mode?
        false
      end

      def clear_selection?
        false
      end

      def toggle_line_mode?
        false
      end
    end

    # Result for NormalMode - handles visual mode start
    class NormalModeResult < Base
      def initialize(mode: nil, message: nil, quit: false, start_selection: false, line_mode: false, group_started: false)
        @start_selection = start_selection
        @line_mode = line_mode
        @group_started = group_started
        super(mode: mode, message: message, quit: quit)
      end

      def start_selection?
        @start_selection
      end

      def line_mode?
        @line_mode
      end

      def group_started?
        @group_started
      end
    end

    # Result for VisualMode - handles selection clear and line mode toggle
    class VisualModeResult < Base
      def initialize(mode: nil, message: nil, quit: false, clear_selection: false, toggle_line_mode: false, group_started: false)
        @clear_selection = clear_selection
        @toggle_line_mode = toggle_line_mode
        @group_started = group_started
        super(mode: mode, message: message, quit: quit)
      end

      def clear_selection?
        @clear_selection
      end

      def toggle_line_mode?
        @toggle_line_mode
      end

      def group_started?
        @group_started
      end
    end

    # Result for InsertMode - uses base functionality only
    class InsertModeResult < Base
    end

    # Result for CommandMode - uses base functionality only
    class CommandModeResult < Base
    end
  end
end
