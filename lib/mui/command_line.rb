# frozen_string_literal: true

module Mui
  class CommandLine
    # Commands that accept file path arguments
    FILE_COMMANDS = %w[e w sp split vs vsplit tabnew tabe tabedit].freeze

    attr_reader :buffer, :cursor_pos

    def initialize
      @buffer = ""
      @cursor_pos = 0
    end

    def input(char)
      @buffer = @buffer[0...@cursor_pos].to_s + char + @buffer[@cursor_pos..].to_s
      @cursor_pos += char.length
    end

    def backspace
      return if @cursor_pos.zero?

      @buffer = @buffer[0...(@cursor_pos - 1)].to_s + @buffer[@cursor_pos..].to_s
      @cursor_pos -= 1
    end

    def clear
      @buffer = ""
      @cursor_pos = 0
    end

    def move_cursor_left
      @cursor_pos -= 1 if @cursor_pos.positive?
    end

    def move_cursor_right
      @cursor_pos += 1 if @cursor_pos < @buffer.length
    end

    def execute
      result = parse(@buffer)
      @buffer = ""
      @cursor_pos = 0
      result
    end

    def to_s
      ":#{@buffer}"
    end

    # Determine completion context based on current buffer
    def completion_context
      # Check if buffer contains a space (command + argument)
      if @buffer.include?(" ")
        # Command with argument
        parts = @buffer.split(/\s+/, 2)
        command = parts[0]
        arg = parts[1] || ""

        return { type: :file, command:, prefix: arg } if FILE_COMMANDS.include?(command)

        # Return nil for commands that don't support file completion
        return nil
      end

      # No space -> command completion
      { type: :command, prefix: @buffer.strip }
    end

    # Apply completion result to buffer
    def apply_completion(text, context)
      @buffer = if context[:type] == :command
                  text
                else
                  "#{context[:command]} #{text}"
                end
      @cursor_pos = @buffer.length
    end

    private

    def parse(cmd)
      case cmd.strip
      when ""
        { action: :no_op }
      when "e"
        { action: :open }
      when /^e\s+(.+)/
        { action: :open_as, path: ::Regexp.last_match(1) }
      when "w"
        { action: :write }
      when "q"
        { action: :quit }
      when "wq"
        { action: :write_quit }
      when "q!"
        { action: :force_quit }
      when /^w\s+(.+)/
        { action: :write_as, path: ::Regexp.last_match(1) }
      when "sp", "split"
        { action: :split_horizontal }
      when /^sp\s+(.+)/, /^split\s+(.+)/
        { action: :split_horizontal, path: ::Regexp.last_match(1) }
      when "vs", "vsplit"
        { action: :split_vertical }
      when /^vs\s+(.+)/, /^vsplit\s+(.+)/
        { action: :split_vertical, path: ::Regexp.last_match(1) }
      when "close"
        { action: :close_window }
      when "only"
        { action: :only_window }
      when "tabnew", "tabe", "tabedit"
        { action: :tab_new }
      when /^tabnew\s+(.+)/, /^tabe\s+(.+)/, /^tabedit\s+(.+)/
        { action: :tab_new, path: ::Regexp.last_match(1) }
      when "tabclose", "tabc"
        { action: :tab_close }
      when "tabnext", "tabn"
        { action: :tab_next }
      when "tabprev", "tabp", "tabprevious"
        { action: :tab_prev }
      when "tabfirst", "tabf", "tabrewind", "tabr"
        { action: :tab_first }
      when "tablast", "tabl"
        { action: :tab_last }
      when /^tabmove\s+(\d+)/, /^tabm\s+(\d+)/
        { action: :tab_move, position: ::Regexp.last_match(1).to_i }
      when /^(\d+)tabn(?:ext)?/, /^tabn(?:ext)?\s+(\d+)/
        { action: :tab_go, index: ::Regexp.last_match(1).to_i - 1 }
      when /^(\d+)$/
        { action: :goto_line, line_number: ::Regexp.last_match(1).to_i }
      else
        { action: :unknown, command: cmd }
      end
    end
  end
end
