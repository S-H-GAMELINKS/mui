# frozen_string_literal: true

module Mui
  module TerminalAdapter
    # Abstract base class for terminal adapters
    class Base
      # Initialize terminal
      def init
        raise MethodNotOverriddenError, __method__
      end

      # Close terminal
      def close
        raise MethodNotOverriddenError, __method__
      end

      # Clear screen
      def clear
        raise MethodNotOverriddenError, __method__
      end

      # Refresh screen
      def refresh
        raise MethodNotOverriddenError, __method__
      end

      # Get terminal width
      def width
        raise MethodNotOverriddenError, __method__
      end

      # Get terminal height
      def height
        raise MethodNotOverriddenError, __method__
      end

      # Set cursor position
      def setpos(_y, _x)
        raise MethodNotOverriddenError, __method__
      end

      # Output string at current position
      def addstr(_str)
        raise MethodNotOverriddenError, __method__
      end

      # Execute block with highlight (reverse video)
      def with_highlight
        raise MethodNotOverriddenError, __method__
      end

      # Read single key (blocking)
      def getch
        raise MethodNotOverriddenError, __method__
      end

      # Read single key (non-blocking)
      def getch_nonblock
        raise MethodNotOverriddenError, __method__
      end
    end
  end
end
