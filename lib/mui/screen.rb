# frozen_string_literal: true

module Mui
  class Screen
    attr_reader :width, :height

    def initialize(adapter:)
      @adapter = adapter
      @adapter.init
      update_size
    end

    def refresh
      update_size
      @adapter.refresh
    end

    def close
      @adapter.close
    end

    def clear
      @adapter.clear
    end

    def put(y, x, text)
      return if y.negative?
      return if y >= @height || x >= @width

      @adapter.setpos(y, x)
      max_len = @width - x
      @adapter.addstr(text.length > max_len ? text[0, max_len] : text)
    end

    def put_with_highlight(y, x, text)
      return if y.negative?
      return if y >= @height || x >= @width

      @adapter.setpos(y, x)
      max_len = @width - x
      @adapter.with_highlight do
        @adapter.addstr(text.length > max_len ? text[0, max_len] : text)
      end
    end

    def move_cursor(y, x)
      x = [[x, 0].max, @width - 1].min
      y = [[y, 0].max, @height - 1].min
      @adapter.setpos(y, x)
    end

    private

    def update_size
      @width = @adapter.width
      @height = @adapter.height
    end
  end
end
