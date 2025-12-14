# frozen_string_literal: true

module Mui
  # Represents a sequence of keys for key mapping
  # Parses Vim-style notation and provides normalization for matching
  class KeySequence
    attr_reader :keys, :notation

    # @param notation [String] Key notation string (e.g., "<Leader>gd", "<C-x><C-s>")
    def initialize(notation)
      @notation = notation
      @keys = KeyNotationParser.parse(notation)
    end

    # Normalize the key sequence by expanding :leader to actual leader key
    # @param leader_key [String] The actual leader key (e.g., "\\", " ")
    # @return [Array<String>] Array of normalized key strings
    def normalize(leader_key)
      @keys.map { |k| k == :leader ? leader_key : k }
    end

    # Get the length of the key sequence
    # @return [Integer] Number of keys in the sequence
    def length
      @keys.length
    end

    # Check if this sequence contains a leader key
    # @return [Boolean]
    def leader?
      @keys.include?(:leader)
    end

    # Check if this is a single key sequence
    # @return [Boolean]
    def single_key?
      @keys.length == 1
    end

    # Check equality with another KeySequence
    # @param other [KeySequence]
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(KeySequence)

      @keys == other.keys
    end

    alias eql? ==

    # Hash for use in Hash keys
    def hash
      @keys.hash
    end

    # Convert back to notation string for display
    # @return [String]
    def to_s
      @notation
    end

    # Inspect for debugging
    def inspect
      "#<Mui::KeySequence #{@notation.inspect} => #{@keys.inspect}>"
    end
  end
end
