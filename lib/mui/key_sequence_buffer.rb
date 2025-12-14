# frozen_string_literal: true

module Mui
  # Buffer for accumulating key inputs for multi-key sequence matching
  # Tracks timing for timeout detection
  class KeySequenceBuffer
    attr_reader :last_input_time

    def initialize
      @buffer = []
      @last_input_time = nil
    end

    # Push a key into the buffer
    # @param key [Integer, String] Raw key input from terminal
    # @return [Boolean] true if key was added, false if key was invalid
    def push(key)
      normalized = KeyNotationParser.normalize_input_key(key)
      return false unless normalized

      @buffer << normalized
      @last_input_time = Time.now
      true
    end

    # Clear the buffer
    def clear
      @buffer.clear
      @last_input_time = nil
    end

    # Check if buffer is empty
    # @return [Boolean]
    def empty?
      @buffer.empty?
    end

    # Get buffer length
    # @return [Integer]
    def length
      @buffer.length
    end

    alias size length

    # Get copy of buffer contents as array
    # @return [Array<String>]
    def to_a
      @buffer.dup
    end

    # Get the first key in the buffer
    # @return [String, nil]
    def first
      @buffer.first
    end

    # Remove and return the first key
    # @return [String, nil]
    def shift
      key = @buffer.shift
      @last_input_time = nil if @buffer.empty?
      key
    end

    # Check if the buffer has timed out
    # @param timeout_ms [Integer] Timeout in milliseconds
    # @return [Boolean]
    def timeout?(timeout_ms)
      return false unless @last_input_time
      return false if @buffer.empty?

      elapsed_ms = (Time.now - @last_input_time) * 1000
      elapsed_ms > timeout_ms
    end

    # Get elapsed time since last input in milliseconds
    # @return [Float, nil] Elapsed time in ms, or nil if no input
    def elapsed_ms
      return nil unless @last_input_time

      (Time.now - @last_input_time) * 1000
    end
  end
end
