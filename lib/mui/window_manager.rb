# frozen_string_literal: true

module Mui
  class WindowManager
    # Predicates for determining if a window is in a given direction from another
    DIRECTION_PREDICATES = {
      left: ->(w, active) { w.x + w.width <= active.x },
      right: ->(w, active) { w.x >= active.x + active.width },
      up: ->(w, active) { w.y + w.height <= active.y },
      down: ->(w, active) { w.y >= active.y + active.height }
    }.freeze

    attr_reader :active_window, :layout_root

    def initialize(screen, color_scheme: nil)
      @screen = screen
      @color_scheme = color_scheme
      @active_window = nil
      @layout_root = nil
      @layout_calculator = Layout::Calculator.new
    end

    def add_window(buffer)
      window = create_window(buffer)

      @layout_root = Layout::LeafNode.new(window) if @layout_root.nil?

      @active_window ||= window
      update_layout
      window
    end

    def remove_window(window)
      return false if single_window?

      node = @layout_root.find_window_node(window)
      return false unless node

      remove_node(node)

      @active_window = windows.first if @active_window == window
      update_layout
      true
    end

    def split_horizontal(buffer = nil)
      split(:horizontal, buffer)
    end

    def split_vertical(buffer = nil)
      split(:vertical, buffer)
    end

    def close_current_window
      return false if single_window?

      current_node = @layout_root.find_window_node(@active_window)
      return false unless current_node

      remove_node(current_node)

      @active_window = windows.first
      update_layout
      true
    end

    def close_all_except_current
      return if single_window?

      @layout_root = Layout::LeafNode.new(@active_window)
      @layout_root.parent = nil
      update_layout
    end

    def render_all(screen, selection: nil, search_state: nil)
      windows.each do |window|
        window_selection = window == @active_window ? selection : nil
        window.render(screen, selection: window_selection, search_state:)
      end
      render_separators(screen)
    end

    def separators
      return [] unless @layout_root.respond_to?(:separators)

      @layout_root.separators
    end

    def update_sizes
      update_layout
    end

    def focus_next
      focus_cycle(1)
    end

    def focus_previous
      focus_cycle(-1)
    end

    def focus_direction(direction)
      return unless windows.size > 1

      target = find_window_in_direction(direction)
      @active_window = target if target
    end

    def windows
      return [] unless @layout_root

      @layout_root.windows
    end

    def window_count
      windows.size
    end

    def single_window?
      windows.size <= 1
    end

    def update_layout(y_offset: 0)
      return unless @layout_root

      @layout_calculator.calculate(
        @layout_root, 0, y_offset, @screen.width, @screen.height - 1 - y_offset
      )
    end

    private

    def focus_cycle(offset)
      all_windows = windows
      return if all_windows.size <= 1

      current_index = all_windows.index(@active_window) || 0
      @active_window = all_windows[(current_index + offset) % all_windows.size]
    end

    def split(direction, buffer)
      return nil unless @active_window

      target_buffer = buffer || @active_window.buffer
      new_window = create_window(target_buffer)

      current_node = @layout_root.find_window_node(@active_window)
      return nil unless current_node

      parent = current_node.parent

      new_leaf = Layout::LeafNode.new(new_window)
      split_node = Layout::SplitNode.new(
        direction:,
        children: [current_node, new_leaf],
        ratio: 0.5
      )

      if parent
        parent.replace_child(current_node, split_node)
      else
        @layout_root = split_node
      end

      @active_window = new_window
      update_layout
      new_window
    end

    def remove_node(node)
      parent = node.parent
      return false unless parent

      parent.remove_child(node)

      if parent.children.size == 1
        remaining_child = parent.children.first
        grandparent = parent.parent

        if grandparent
          grandparent.replace_child(parent, remaining_child)
        else
          @layout_root = remaining_child
          remaining_child.parent = nil
        end
      end

      true
    end

    def find_window_in_direction(direction)
      return nil unless @active_window

      predicate = DIRECTION_PREDICATES[direction]
      return nil unless predicate

      current_x = @active_window.x + (@active_window.width / 2)
      current_y = @active_window.y + (@active_window.height / 2)

      candidates = windows.reject { |w| w == @active_window }
                          .select { |w| predicate.call(w, @active_window) }

      candidates.min_by do |w|
        wx = w.x + (w.width / 2)
        wy = w.y + (w.height / 2)
        Math.sqrt(((wx - current_x)**2) + ((wy - current_y)**2))
      end
    end

    def create_window(buffer)
      Window.new(
        buffer,
        x: 0,
        y: 0,
        width: @screen.width,
        height: @screen.height,
        color_scheme: @color_scheme
      )
    end

    def render_separators(screen)
      style = separator_style
      separators.each do |sep|
        case sep[:type]
        when :horizontal
          render_horizontal_separator(screen, sep, style)
        when :vertical
          render_vertical_separator(screen, sep, style)
        end
      end
    end

    def render_horizontal_separator(screen, sep, style)
      line = "─" * sep[:length]
      screen.put_with_style(sep[:y], sep[:x], line, style)
    end

    def render_vertical_separator(screen, sep, style)
      sep[:length].times do |i|
        screen.put_with_style(sep[:y] + i, sep[:x], "│", style)
      end
    end

    def separator_style
      return nil unless @color_scheme

      @color_scheme[:separator]
    end
  end
end
