# frozen_string_literal: true

module Mui
  class WindowManager
    attr_reader :active_window

    def initialize(screen, color_scheme: nil)
      @screen = screen
      @color_scheme = color_scheme
      @windows = []
      @active_window = nil
    end

    def add_window(buffer)
      window = Window.new(
        buffer,
        x: 0,
        y: 0,
        width: @screen.width,
        height: @screen.height,
        color_scheme: @color_scheme
      )
      @windows << window
      @active_window ||= window
      update_layout
      window
    end

    def remove_window(window)
      @windows.delete(window)
      @active_window = @windows.first if @active_window == window
      update_layout
    end

    def render_all(screen, selection: nil, search_state: nil)
      @windows.each do |window|
        window_selection = window == @active_window ? selection : nil
        window.render(screen, selection: window_selection, search_state:)
      end
    end

    def update_sizes
      update_layout
    end

    def focus_next
      return unless @windows.size > 1

      current_index = @windows.index(@active_window)
      @active_window = @windows[(current_index + 1) % @windows.size]
    end

    def focus_previous
      return unless @windows.size > 1

      current_index = @windows.index(@active_window)
      @active_window = @windows[(current_index - 1) % @windows.size]
    end

    def window_count
      @windows.size
    end

    def single_window?
      @windows.size == 1
    end

    private

    def update_layout
      return if @windows.empty?

      @windows.each do |window|
        window.x = 0
        window.y = 0
        window.width = @screen.width
        window.height = @screen.height
      end
    end
  end
end
