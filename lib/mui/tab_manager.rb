# frozen_string_literal: true

module Mui
  # Manages multiple tab pages
  # Each tab page has its own window layout
  class TabManager
    attr_reader :tabs, :current_index

    def initialize(screen, color_scheme: nil)
      @screen = screen
      @color_scheme = color_scheme
      @tabs = []
      @current_index = 0
    end

    def current_tab
      @tabs[@current_index]
    end

    def add(tab = nil)
      tab ||= TabPage.new(@screen, color_scheme: @color_scheme)
      @tabs << tab
      @current_index = @tabs.size - 1
      tab
    end

    # rubocop:disable Naming/PredicateMethod
    def close_current
      return false if single_tab?

      @tabs.delete_at(@current_index)
      @current_index = [@current_index, @tabs.size - 1].min
      true
    end
    # rubocop:enable Naming/PredicateMethod

    def next_tab
      return if @tabs.empty?

      @current_index = (@current_index + 1) % @tabs.size
    end

    def prev_tab
      return if @tabs.empty?

      @current_index = (@current_index - 1) % @tabs.size
    end

    def first_tab
      return if @tabs.empty?

      @current_index = 0
    end

    def last_tab
      return if @tabs.empty?

      @current_index = @tabs.size - 1
    end

    # rubocop:disable Naming/PredicateMethod
    def go_to(index)
      return false if index.negative? || index >= @tabs.size

      @current_index = index
      true
    end

    def move_tab(position)
      return false if @tabs.size <= 1

      tab = @tabs.delete_at(@current_index)
      new_position = position.clamp(0, @tabs.size)
      @tabs.insert(new_position, tab)
      @current_index = new_position
      true
    end
    # rubocop:enable Naming/PredicateMethod

    def tab_count
      @tabs.size
    end

    def single_tab?
      @tabs.size <= 1
    end

    def window_manager
      current_tab&.window_manager
    end

    def active_window
      current_tab&.active_window
    end
  end
end
