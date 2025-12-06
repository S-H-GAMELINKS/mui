# frozen_string_literal: true

module Mui
  module Highlighters
    class Base
      PRIORITY_SELECTION = 100
      PRIORITY_SEARCH = 200
      PRIORITY_SYNTAX = 300

      def initialize(color_scheme)
        @color_scheme = color_scheme
      end

      def highlights_for(_row, _line, _options = {})
        raise Mui::MethodNotOverriddenError, "#{self.class}#highlights_for must be implemented"
      end

      def priority
        0
      end
    end
  end
end
