# frozen_string_literal: true

module Mui
  # Matches input key sequences against registered key mappings
  class KeySequenceMatcher
    # Match result types
    MATCH_EXACT = :exact       # Complete match found
    MATCH_PARTIAL = :partial   # Input is prefix of one or more registered sequences
    MATCH_NONE = :none         # No match possible

    # @param keymaps [Hash] Mode => { KeySequence => handler }
    # @param leader_key [String] The leader key to expand :leader symbols
    def initialize(keymaps, leader_key)
      @keymaps = keymaps
      @leader_key = leader_key
    end

    # Match input keys against registered keymaps for a mode
    # @param mode [Symbol] The current mode (:normal, :insert, etc.)
    # @param input_keys [Array<String>] Array of normalized input keys
    # @return [Array<Symbol, Object>] [match_type, handler_or_nil]
    def match(mode, input_keys)
      mode_keymaps = @keymaps[mode]
      return [MATCH_NONE, nil] unless mode_keymaps
      return [MATCH_NONE, nil] if input_keys.empty?

      exact_match = nil
      has_longer_match = false

      mode_keymaps.each do |sequence, handler|
        seq_keys = sequence.normalize(@leader_key)

        if seq_keys == input_keys
          # Exact match found
          exact_match = handler
        elsif prefix_match?(input_keys, seq_keys)
          # Input is a prefix of this sequence (longer sequence exists)
          has_longer_match = true
        end
      end

      if exact_match
        # Exact match found - return it
        # If there are also longer matches, caller may want to wait for timeout
        [MATCH_EXACT, exact_match]
      elsif has_longer_match
        # No exact match, but input could lead to a match
        [MATCH_PARTIAL, nil]
      else
        # No match possible
        [MATCH_NONE, nil]
      end
    end

    # Check if there are any longer sequences that could match
    # Used to determine if we should wait for more input
    # @param mode [Symbol]
    # @param input_keys [Array<String>]
    # @return [Boolean]
    def longer_sequences?(mode, input_keys)
      mode_keymaps = @keymaps[mode]
      return false unless mode_keymaps

      mode_keymaps.any? do |sequence, _handler|
        seq_keys = sequence.normalize(@leader_key)
        seq_keys.length > input_keys.length && prefix_match?(input_keys, seq_keys)
      end
    end

    private

    # Check if input_keys is a prefix of seq_keys
    def prefix_match?(input_keys, seq_keys)
      return false if input_keys.length >= seq_keys.length

      seq_keys.take(input_keys.length) == input_keys
    end
  end
end
