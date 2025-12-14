# frozen_string_literal: true

module Mui
  # Main handler for multi-key sequence processing
  # Integrates buffer, matcher, and timeout handling
  class KeySequenceHandler
    DEFAULT_TIMEOUT_MS = 1000

    # Process result types
    RESULT_HANDLED = :handled           # Handler executed
    RESULT_PENDING = :pending           # Waiting for more keys
    RESULT_PASSTHROUGH = :passthrough   # No match, pass key to built-in handler

    attr_reader :buffer

    # @param config [Config] Configuration object
    def initialize(config)
      @config = config
      @buffer = KeySequenceBuffer.new
      @keymaps = {} # { mode => { KeySequence => handler } }
      @pending_handler = nil # Handler for exact match while waiting for longer
    end

    # Get the leader key from config
    # @return [String]
    def leader_key
      @config.get(:leader) || "\\"
    end

    # Get the timeout in milliseconds
    # @return [Integer]
    def timeout_ms
      @config.get(:timeoutlen) || DEFAULT_TIMEOUT_MS
    end

    # Register a key sequence mapping
    # @param mode [Symbol] Mode (:normal, :insert, etc.)
    # @param key_notation [String] Key notation (e.g., "<Leader>gd")
    # @param handler [Proc] Handler to execute
    def register(mode, key_notation, handler)
      @keymaps[mode] ||= {}
      sequence = KeySequence.new(key_notation)
      @keymaps[mode][sequence] = handler
    end

    # Process an input key
    # @param key [Integer, String] Raw key input
    # @param mode [Symbol] Current mode
    # @return [Array<Symbol, Object>] [result_type, data]
    #   - [:handled, handler] - Execute the handler
    #   - [:pending, nil] - Wait for more input
    #   - [:passthrough, key] - Pass key to built-in handler
    def process(key, mode)
      # Check timeout first - if timed out, handle before processing new key
      if @buffer.timeout?(timeout_ms) && !@buffer.empty?
        result = handle_timeout(mode)
        # If we got a result, return it; the new key will be processed next time
        return result if result[0] == RESULT_HANDLED

        # If passthrough, clear buffer and continue with new key
        @buffer.clear
        @pending_handler = nil
      end

      # Add key to buffer
      unless @buffer.push(key)
        # Invalid key, pass through as-is
        return [RESULT_PASSTHROUGH, key]
      end

      # Match against keymaps
      matcher = KeySequenceMatcher.new(@keymaps, leader_key)
      match_type, handler = matcher.match(mode, @buffer.to_a)

      case match_type
      when KeySequenceMatcher::MATCH_EXACT
        has_longer = matcher.longer_sequences?(mode, @buffer.to_a)
        if has_longer
          # Exact match but longer sequences exist
          # Store handler and wait for more input or timeout
          @pending_handler = handler
          [RESULT_PENDING, nil]
        else
          # Exact match, no longer sequences - execute immediately
          @buffer.clear
          @pending_handler = nil
          [RESULT_HANDLED, handler]
        end

      when KeySequenceMatcher::MATCH_PARTIAL
        # Could become a match, wait for more input
        [RESULT_PENDING, nil]

      else
        # No match - pass through first key
        handle_no_match
      end
    end

    # Check for timeout and handle if needed (called from main loop)
    # @param mode [Symbol] Current mode
    # @return [Array<Symbol, Object>, nil] Result if timed out, nil otherwise
    def check_timeout(mode)
      return nil if @buffer.empty?
      return nil unless @buffer.timeout?(timeout_ms)

      handle_timeout(mode)
    end

    # Check if there are pending keys in the buffer
    # @return [Boolean]
    def pending?
      !@buffer.empty?
    end

    # Clear the buffer and pending state
    def clear
      @buffer.clear
      @pending_handler = nil
    end

    # Get pending key display for status line
    # @return [String, nil]
    def pending_keys_display
      return nil if @buffer.empty?

      @buffer.to_a.join
    end

    # Rebuild internal keymaps from config
    # Called after config changes
    def rebuild_keymaps
      @keymaps = {}
      @config.keymaps.each do |mode, mappings|
        mappings.each do |key_notation, handler|
          register(mode, key_notation, handler)
        end
      end
    end

    private

    def handle_timeout(_mode)
      if @pending_handler
        # We had an exact match, execute it
        handler = @pending_handler
        @buffer.clear
        @pending_handler = nil
        [RESULT_HANDLED, handler]
      else
        # No exact match, passthrough first key
        handle_no_match
      end
    end

    def handle_no_match
      first_key = @buffer.shift
      @buffer.clear
      @pending_handler = nil
      [RESULT_PASSTHROUGH, first_key]
    end
  end
end
