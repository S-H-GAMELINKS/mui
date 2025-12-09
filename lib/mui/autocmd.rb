# frozen_string_literal: true

module Mui
  # Event-driven hook system for plugins
  class Autocmd
    EVENTS = %i[
      BufEnter
      BufLeave
      BufWrite
      BufWritePre
      BufWritePost
      ModeChanged
      CursorMoved
      TextChanged
      InsertEnter
      InsertLeave
      JobStarted
      JobCompleted
      JobFailed
      JobCancelled
    ].freeze

    def initialize
      @handlers = {}
      EVENTS.each { |e| @handlers[e] = [] }
    end

    def register(event, pattern: nil, &block)
      event = event.to_sym
      raise ArgumentError, "Unknown event: #{event}" unless EVENTS.include?(event)

      @handlers[event] << { pattern:, handler: block }
    end

    def trigger(event, context = nil, **kwargs)
      event = event.to_sym
      return unless @handlers[event]

      @handlers[event].each do |entry|
        # Skip pattern matching for non-buffer events (like Job events)
        next if context && entry[:pattern] && !match_pattern?(context, entry[:pattern])

        # Pass context or kwargs depending on what's available
        entry[:handler].call(context || kwargs)
      end
    end

    private

    def match_pattern?(context, pattern)
      return true unless pattern

      file_path = context.buffer.file_path

      case pattern
      when Regexp
        file_path&.match?(pattern)
      when String
        File.fnmatch(pattern, file_path || "")
      else
        false
      end
    end
  end
end
