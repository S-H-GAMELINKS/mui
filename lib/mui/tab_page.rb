# frozen_string_literal: true

module Mui
  # Represents a single tab page containing a window manager
  # Each tab page has its own independent window layout
  class TabPage
    attr_reader :window_manager
    attr_accessor :name

    def initialize(screen, color_scheme: nil, name: nil)
      @window_manager = WindowManager.new(screen, color_scheme:)
      @name = name
    end

    def active_window
      @window_manager.active_window
    end

    def layout_root
      @window_manager.layout_root
    end

    def windows
      @window_manager.windows
    end

    def window_count
      @window_manager.window_count
    end

    def display_name
      @name || active_window&.buffer&.name || "[No Name]"
    end
  end
end
