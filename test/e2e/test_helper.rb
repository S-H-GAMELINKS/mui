# frozen_string_literal: true

require_relative "../test_helper"

# ScriptRunner class for E2E tests
# Allows writing test scenarios in Vim notation
class ScriptRunner
  include MuiTestHelper

  attr_reader :editor, :log

  def initialize(file_path = nil)
    @editor = Mui::Editor.new(file_path, adapter: test_adapter, load_config: false)
    @log = []
  end

  # Key input in Vim notation
  # Example: "iHello<Esc>:wq<Enter>"
  def type(notation)
    keys = parse_vim_keys(notation)
    keys.each do |key|
      snapshot_before = capture_state
      @editor.handle_key(key)
      snapshot_after = capture_state
      @log << {
        key:,
        key_str: key_to_string(key),
        before: snapshot_before,
        after: snapshot_after
      }
    end
    self
  end

  # Capture state snapshot
  def capture_state
    {
      mode: @editor.mode,
      cursor: [@editor.window.cursor_row, @editor.window.cursor_col],
      lines: @editor.buffer.lines.map(&:dup),
      line_count: @editor.buffer.line_count,
      modified: @editor.buffer.modified,
      running: @editor.running,
      message: @editor.message
    }
  end

  # Convert key to human-readable format
  def key_to_string(key)
    case key
    when 27 then "<Esc>"
    when 13 then "<Enter>"
    when 127 then "<BS>"
    when Curses::KEY_UP then "<Up>"
    when Curses::KEY_DOWN then "<Down>"
    when Curses::KEY_LEFT then "<Left>"
    when Curses::KEY_RIGHT then "<Right>"
    when String then key
    when Integer
      key >= 32 && key < 127 ? key.chr : key.to_s
    else
      key.to_s
    end
  end

  # Assertions
  def assert_mode(expected)
    actual = @editor.mode
    raise "Expected mode #{expected}, got #{actual}" unless actual == expected

    self
  end

  def assert_cursor(row, col)
    actual = [@editor.window.cursor_row, @editor.window.cursor_col]
    expected = [row, col]
    raise "Expected cursor #{expected}, got #{actual}" unless actual == expected

    self
  end

  def assert_line(n, expected)
    actual = @editor.buffer.line(n)
    raise "Expected line #{n} to be '#{expected}', got '#{actual}'" unless actual == expected

    self
  end

  def assert_line_count(expected)
    actual = @editor.buffer.line_count
    raise "Expected #{expected} lines, got #{actual}" unless actual == expected

    self
  end

  def assert_running(expected)
    actual = @editor.running
    raise "Expected running=#{expected}, got #{actual}" unless actual == expected

    self
  end

  def assert_modified(expected)
    actual = @editor.buffer.modified
    raise "Expected modified=#{expected}, got #{actual}" unless actual == expected

    self
  end

  def assert_message_contains(substring)
    actual = @editor.message || ""
    raise "Expected message to contain '#{substring}', got '#{actual}'" unless actual.include?(substring)

    self
  end

  def assert_message_nil
    raise "Expected message to be nil, got '#{@editor.message}'" unless @editor.message.nil?

    self
  end

  def assert_selection(start_row, start_col, end_row, end_col)
    selection = @editor.selection
    raise "Expected selection to exist" if selection.nil?

    actual = [selection.start_row, selection.start_col, selection.end_row, selection.end_col]
    expected = [start_row, start_col, end_row, end_col]
    raise "Expected selection #{expected}, got #{actual}" unless actual == expected

    self
  end

  def assert_no_selection
    raise "Expected no selection, got #{@editor.selection.inspect}" unless @editor.selection.nil?

    self
  end

  def assert_line_mode(expected)
    selection = @editor.selection
    raise "Expected selection to exist" if selection.nil?

    actual = selection.line_mode
    raise "Expected line_mode=#{expected}, got #{actual}" unless actual == expected

    self
  end

  def assert_register(name, expected_content, linewise: nil)
    register = @editor.register
    actual = register.get(name:)
    raise "Expected register '#{name}' to be '#{expected_content}', got '#{actual}'" unless actual == expected_content

    unless linewise.nil?
      actual_linewise = register.linewise?(name:)
      raise "Expected register '#{name}' linewise=#{linewise}, got #{actual_linewise}" unless actual_linewise == linewise
    end

    self
  end

  def assert_register_empty(name)
    register = @editor.register
    raise "Expected register '#{name}' to be empty, got '#{register.get(name:)}'" unless register.empty?(name:)

    self
  end

  def assert_window_count(expected)
    actual = @editor.window_manager.window_count
    raise "Expected #{expected} windows, got #{actual}" unless actual == expected

    self
  end

  def assert_tab_count(expected)
    actual = @editor.tab_manager.tab_count
    raise "Expected #{expected} tabs, got #{actual}" unless actual == expected

    self
  end

  def assert_current_tab(expected_index)
    actual = @editor.tab_manager.current_index
    raise "Expected current tab index #{expected_index}, got #{actual}" unless actual == expected_index

    self
  end

  # Get execution log as string
  def format_log
    @log.map.with_index do |entry, i|
      "#{i + 1}. #{entry[:key_str]}: mode=#{entry[:after][:mode]}, " \
        "cursor=#{entry[:after][:cursor]}, " \
        "line0=\"#{entry[:after][:lines][0]}\""
    end.join("\n")
  end

  # Debug: print log to stdout
  def print_log
    puts format_log
    self
  end
end
