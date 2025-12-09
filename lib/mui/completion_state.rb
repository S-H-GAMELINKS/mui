# frozen_string_literal: true

module Mui
  # Manages completion popup state
  class CompletionState
    attr_reader :candidates, :selected_index, :original_input, :completion_type

    def initialize
      reset
    end

    def reset
      @candidates = []
      @selected_index = 0
      @original_input = nil
      @completion_type = nil # :command or :file
    end

    def active?
      !@candidates.empty?
    end

    def start(candidates, original_input, type)
      @candidates = candidates
      @selected_index = 0
      @original_input = original_input
      @completion_type = type
    end

    def select_next
      return unless active?

      @selected_index = (@selected_index + 1) % @candidates.length
    end

    def select_previous
      return unless active?

      @selected_index = (@selected_index - 1) % @candidates.length
    end

    def current_candidate
      return nil unless active?

      @candidates[@selected_index]
    end
  end
end
