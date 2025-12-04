# frozen_string_literal: true

module Mui
  class Error < StandardError; end

  # Raised when a subclass does not override a required method
  class MethodNotOverriddenError < Error
    def initialize(method_name)
      super("Subclass must implement ##{method_name}")
    end
  end
end
