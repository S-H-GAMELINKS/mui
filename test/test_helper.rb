# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "curses"

# Mocked Curses's method for testing
module Curses
  # Key input queue (for testing)
  @input_queue = []

  class << self
    attr_accessor :input_queue
  end

  FakeStdscr = Data.define do
    def keypad(val)
      val
    end

    def nodelay=(val)
      val
    end
  end

  ORVERRIDE_METHODS = {
    init_screen: -> {},
    close_screen: -> {},
    raw: -> {},
    noraw: -> {},
    echo: -> {},
    noecho: -> {},
    start_color: -> {},
    use_default_colors: -> {},
    doupdate: -> {},
    beep: -> {},
    clear: -> {},
    refresh: -> {},
    curs_set: ->(val) { val },
    init_pair: ->(*args) { args },
    setpos: ->(y, x) { [y, x] },
    addstr: ->(str) { str },
    lines: -> { 24 },
    cols: -> { 80 },
    stdscr: -> { FakeStdscr.new },
    getch: lambda {
      key = Curses.input_queue.shift
      raise StopIteration, "Input queue exhausted" if key.nil?

      key
    }
  }.freeze

  class << self
    ORVERRIDE_METHODS.each do |name, block|
      undef_method name if method_defined?(name)
      define_method(name, block)
    end
  end
end

require "mui"

require "minitest/autorun"

# Test helper module
module MuiTestHelper
  # Set up key input sequence
  def setup_key_sequence(keys)
    Curses.input_queue = keys.dup
  end

  # Clear key input sequence
  def clear_key_sequence
    Curses.input_queue = []
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
    else
      raise "Unknown special key: <#{name}>"
    end
  end
end

# Editor extension for testing
module Mui
  class Editor
    attr_accessor :mode, :running
    attr_reader :buffer, :window, :command_line, :message, :screen, :input, :key_handlers, :selection
    public :handle_key

    # Compatibility methods for tests that use the old API
    def handle_normal_key(key)
      result = @key_handlers[Mode::NORMAL].handle(key)
      @mode = result.mode if result.mode
      result
    end

    def handle_insert_key(key)
      result = @key_handlers[Mode::INSERT].handle(key)
      @mode = result.mode if result.mode
      result
    end

    def handle_command_key(key)
      result = @key_handlers[Mode::COMMAND].handle(key)
      @mode = result.mode if result.mode
      @message = result.message if result.message
      @running = false if result.quit?
      result
    end

    def execute_command
      result = @key_handlers[Mode::COMMAND].send(:execute_action, @command_line.execute)
      @mode = result.mode if result.mode
      @message = result.message if result.message
      @running = false if result.quit?
      result
    end
  end
end
