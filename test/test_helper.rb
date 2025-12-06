# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "curses"
require "mui"

require "minitest/autorun"

module Mui
  module TerminalAdapter
    # Test adapter for unit testing without actual terminal
    class Test < Base
      attr_accessor :input_queue, :width, :height

      def initialize(width: 80, height: 24)
        @width = width
        @height = height
        @input_queue = []
        @output_buffer = []
        @cursor_y = 0
        @cursor_x = 0
        @highlight_mode = false
      end

      def init
        # No-op for testing
      end

      def close
        # No-op for testing
      end

      def clear
        @output_buffer = []
      end

      def refresh
        # No-op for testing
      end

      def setpos(y, x)
        @cursor_y = y
        @cursor_x = x
        [y, x]
      end

      def addstr(str)
        @output_buffer << { y: @cursor_y, x: @cursor_x, text: str, highlight: @highlight_mode }
        str
      end

      def with_highlight
        @highlight_mode = true
        result = yield
        @highlight_mode = false
        result
      end

      def getch
        raise StopIteration, "Input queue exhausted" if @input_queue.empty?

        @input_queue.shift
      end

      def getch_nonblock
        return nil if @input_queue.empty?

        @input_queue.shift
      end

      # Test helpers

      def output_at(y, x)
        @output_buffer.find { |entry| entry[:y] == y && entry[:x] == x }
      end

      def all_output
        @output_buffer.dup
      end
    end
  end
end

# Mock classes for unit testing
class MockBuffer
  attr_accessor :lines, :cursor_x, :cursor_y, :modified, :file_path

  def initialize(lines = [""])
    @lines = lines.map(&:dup)
    @cursor_x = 0
    @cursor_y = 0
    @modified = false
    @file_path = nil
  end

  def line(index)
    @lines[index] || ""
  end

  def current_line
    line(@cursor_y)
  end

  def line_count
    @lines.length
  end
end

class MockWindow
  attr_accessor :cursor_row, :cursor_col

  def initialize(buffer)
    @buffer = buffer
    @cursor_row = 0
    @cursor_col = 0
  end
end

class MockEditor
  attr_accessor :message, :running, :command_registry

  def initialize(buffer, window)
    @buffer = buffer
    @window = window
    @message = nil
    @running = true
    @command_registry = Mui::CommandRegistry.new
  end
end

# Test helper module
module MuiTestHelper
  def test_adapter
    @test_adapter ||= Mui::TerminalAdapter::Test.new
  end

  # Set up key input sequence
  def setup_key_sequence(keys)
    test_adapter.input_queue = keys.dup
  end

  # Clear key input sequence
  def clear_key_sequence
    test_adapter.input_queue = []
  end

  # Parse Vim-style key notation
  # Example: "<Esc>", "<Enter>", "<BS>", "i", "hello"
  def parse_vim_keys(notation)
    keys = []
    i = 0
    while i < notation.length
      if notation[i] == "<"
        end_idx = notation.index(">", i)
        if end_idx
          special = notation[(i + 1)...end_idx]
          keys << vim_special_key(special)
          i = end_idx + 1
        else
          keys << notation[i]
          i += 1
        end
      else
        keys << notation[i]
        i += 1
      end
    end
    keys
  end

  # Convert special keys
  def vim_special_key(name)
    case name.downcase
    when "esc", "escape"
      27
    when "enter", "cr", "return"
      13
    when "bs", "backspace"
      127
    when "left"
      Curses::KEY_LEFT
    when "right"
      Curses::KEY_RIGHT
    when "up"
      Curses::KEY_UP
    when "down"
      Curses::KEY_DOWN
    when "c-r"
      18 # Ctrl-r
    else
      raise "Unknown special key: <#{name}>"
    end
  end

  # Create editor with test adapter
  def create_test_editor(file_path = nil)
    Mui::Editor.new(file_path, adapter: test_adapter, load_config: false)
  end
end

# Editor extension for testing
module Mui
  class Editor
    attr_accessor :running
    attr_reader :buffer, :window_manager, :command_line, :message, :screen, :input, :mode_manager
    public :handle_key

    # Setter for test compatibility
    def mode=(new_mode)
      @mode_manager.set_mode(new_mode)
    end

    # Compatibility methods for tests that use the old API
    def handle_normal_key(key)
      result = @mode_manager.key_handlers[Mode::NORMAL].handle(key)
      @mode_manager.transition(result)
      result
    end

    def handle_insert_key(key)
      result = @mode_manager.key_handlers[Mode::INSERT].handle(key)
      @mode_manager.transition(result)
      result
    end

    def handle_command_key(key)
      result = @mode_manager.key_handlers[Mode::COMMAND].handle(key)
      @mode_manager.transition(result)
      @message = result.message if result.message
      @running = false if result.quit?
      result
    end

    def execute_command
      result = @mode_manager.key_handlers[Mode::COMMAND].send(:execute_action, @command_line.execute)
      @mode_manager.transition(result)
      @message = result.message if result.message
      @running = false if result.quit?
      result
    end
  end

  class ModeManager
    attr_reader :key_handlers

    # For test compatibility
    def set_mode(new_mode)
      @mode = new_mode
    end
  end
end
