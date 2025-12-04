# frozen_string_literal: true

module Mui
  class Input
    def initialize(adapter:)
      @adapter = adapter
    end

    def read
      @adapter.getch
    end

    def read_nonblock
      @adapter.getch_nonblock
    end
  end
end
