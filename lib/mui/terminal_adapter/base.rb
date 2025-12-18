# frozen_string_literal: true

module Mui
  module TerminalAdapter
    # Abstract base class for terminal adapters
    class Base
      attr_accessor :color_resolver

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

      # Initialize color support
      def init_colors
        raise MethodNotOverriddenError, __method__
      end

      # Initialize a color pair
      def init_color_pair(_pair_index, _fg, _bg)
        raise MethodNotOverriddenError, __method__
      end

      # Execute block with specified color and attributes
      def with_color(_pair_index, bold: false, underline: false)
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

      # Suspend terminal for external interactive command execution
      # Implementations should save terminal state and exit raw mode
      def suspend
        raise MethodNotOverriddenError, __method__
      end

      # Resume terminal after external interactive command execution
      # Implementations should restore terminal state and re-enter raw mode
      def resume
        raise MethodNotOverriddenError, __method__
      end

      # Check if terminal supports colors
      def has_colors?
        raise MethodNotOverriddenError, __method__
      end

      # Get available color count (8, 256, etc.)
      def colors
        raise MethodNotOverriddenError, __method__
      end

      # Get available color pair count
      def color_pairs
        raise MethodNotOverriddenError, __method__
      end

      # Force a complete redraw of the screen
      # This is needed when multibyte characters may have been corrupted
      def touchwin
        # Default implementation does nothing (for mock adapters)
      end
    end
  end
end
