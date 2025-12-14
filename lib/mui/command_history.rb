# frozen_string_literal: true

module Mui
  # Manages command history with file persistence
  class CommandHistory
    MAX_HISTORY = 100
    HISTORY_FILE = File.expand_path("~/.mui_history")

    attr_reader :history

    def initialize(history_file: HISTORY_FILE)
      @history_file = history_file
      @history = []
      @index = nil
      @saved_input = nil
      load_from_file
    end

    def add(command)
      return if command.strip.empty?

      @history.delete(command)
      @history.push(command)
      @history.shift if @history.size > MAX_HISTORY
      save_to_file
    end

    def previous(current_input)
      return nil if @history.empty?

      if @index.nil?
        @saved_input = current_input
        @index = @history.size - 1
      elsif @index.positive?
        @index -= 1
      else
        return nil
      end

      @history[@index]
    end

    def next_entry
      return nil if @index.nil?

      if @index < @history.size - 1
        @index += 1
        @history[@index]
      else
        result = @saved_input
        reset
        result
      end
    end

    def reset
      @index = nil
      @saved_input = nil
    end

    def browsing?
      !@index.nil?
    end

    def size
      @history.size
    end

    def empty?
      @history.empty?
    end

    private

    def load_from_file
      return unless File.exist?(@history_file)

      @history = File.readlines(@history_file, chomp: true).last(MAX_HISTORY)
    rescue StandardError
      @history = []
    end

    def save_to_file
      File.write(@history_file, "#{@history.join("\n")}\n")
    rescue StandardError
      # Ignore write failures
    end
  end
end
