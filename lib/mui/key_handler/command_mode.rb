# frozen_string_literal: true

module Mui
  module KeyHandler
    # Handles key inputs in Command mode
    class CommandMode < Base
      def initialize(window, buffer, command_line)
        super(window, buffer)
        @command_line = command_line
      end

      def handle(key)
        case key
        when 27 # Escape
          handle_escape
        when 127, Curses::KEY_BACKSPACE
          handle_backspace
        when 13, 10, Curses::KEY_ENTER
          handle_enter
        else
          handle_character_input(key)
        end
      end

      private

      def handle_escape
        @command_line.clear
        result(mode: Mode::NORMAL)
      end

      def handle_backspace
        if @command_line.buffer.empty?
          result(mode: Mode::NORMAL)
        else
          @command_line.backspace
          result
        end
      end

      def handle_enter
        command_result = @command_line.execute
        action_result = execute_action(command_result)
        action_result.merge(mode: Mode::NORMAL)
      end

      def handle_character_input(key)
        char = extract_printable_char(key)
        @command_line.input(char) if char
        result
      end

      def extract_printable_char(key)
        if key.is_a?(String)
          key
        elsif key.is_a?(Integer) && key >= 32 && key < 127
          key.chr
        end
      end

      def execute_action(command_result)
        case command_result[:action]
        when :write
          handle_write
        when :quit
          handle_quit
        when :write_quit
          handle_write_quit
        when :force_quit
          handle_force_quit
        when :write_as
          handle_write_as(command_result[:path])
        when :unknown
          result(message: "Unknown command: #{command_result[:command]}")
        else
          result
        end
      end

      def handle_write
        save_buffer
      end

      def handle_quit
        if @buffer.modified
          result(message: "No write since last change (add ! to override)")
        else
          result(quit: true)
        end
      end

      def handle_write_quit
        save_result = save_buffer
        if save_result[:message] && !save_result[:message].include?("written")
          save_result
        else
          save_result.merge(quit: true)
        end
      end

      def handle_force_quit
        result(quit: true)
      end

      def handle_write_as(path)
        save_buffer(path)
      end

      def save_buffer(path = nil)
        if path
          @buffer.save(path)
        elsif @buffer.name == "[No Name]"
          return result(message: "No file name")
        else
          @buffer.save
        end
        result(message: "\"#{@buffer.name}\" written")
      rescue StandardError => e
        result(message: "Error: #{e.message}")
      end
    end
  end
end
