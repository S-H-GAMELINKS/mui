# frozen_string_literal: true

module Mui
  # Caches wrap calculation results for performance
  # Cache key: [line_content, width]
  class WrapCache
    def initialize
      @cache = {}
    end

    def get(line, width)
      key = cache_key(line, width)
      @cache[key]
    end

    def set(line, width, result)
      key = cache_key(line, width)
      @cache[key] = result
    end

    def invalidate(line)
      # Remove all entries for this line content
      @cache.delete_if { |k, _| k.start_with?("#{line}\x00") }
    end

    def clear
      @cache.clear
    end

    def size
      @cache.size
    end

    private

    def cache_key(line, width)
      "#{line}\x00#{width}"
    end
  end
end
