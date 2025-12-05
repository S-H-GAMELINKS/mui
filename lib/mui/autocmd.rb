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
    ].freeze

    def initialize
      @handlers = {}
      EVENTS.each { |e| @handlers[e] = [] }
    end

    def register(event, pattern: nil, &block)
      event = event.to_sym
      raise ArgumentError, "Unknown event: #{event}" unless EVENTS.include?(event)

      @handlers[event] << { pattern: pattern, handler: block }
    end

    def trigger(event, context)
      event = event.to_sym
      return unless @handlers[event]

      @handlers[event].each do |entry|
        next if entry[:pattern] && !match_pattern?(context, entry[:pattern])

        entry[:handler].call(context)
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
