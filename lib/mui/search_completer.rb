# frozen_string_literal: true

module Mui
  # Extracts search completion candidates from buffer content
  class SearchCompleter
    MAX_CANDIDATES = 50

    def initialize
      @word_cache = {}
      @cache_buffer_id = nil
      @cache_version = nil
    end

    # Extract words from buffer that match the given prefix
    # @param buffer [Buffer] the buffer to search in
    # @param prefix [String] the search prefix to match
    # @return [Array<String>] matching words sorted by relevance
    def complete(buffer, prefix)
      return [] if prefix.nil? || prefix.empty?

      words = extract_words(buffer)
      matching = words.select { |word| word.start_with?(prefix) && word != prefix }

      # Sort by length (shorter first) then alphabetically
      matching.sort_by { |w| [w.length, w] }.take(MAX_CANDIDATES)
    end

    private

    def extract_words(buffer)
      # Simple cache invalidation based on buffer identity and modification
      buffer_id = buffer.object_id
      version = buffer.lines.hash

      return @word_cache[buffer_id] if @cache_buffer_id == buffer_id && @cache_version == version

      words = Set.new
      buffer.line_count.times do |row|
        line = buffer.line(row)
        # Extract words (alphanumeric + underscore, minimum 2 characters)
        line.scan(/\b[a-zA-Z_][a-zA-Z0-9_]+\b/) do |word|
          words.add(word)
        end
      end

      @cache_buffer_id = buffer_id
      @cache_version = version
      @word_cache[buffer_id] = words.to_a

      @word_cache[buffer_id]
    end
  end
end
