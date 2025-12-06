# frozen_string_literal: true

require "test_helper"

class TestSearchMode < Minitest::Test
  def setup
    @buffer = Mui::Buffer.new
    @buffer.lines[0] = "hello world"
    @buffer.lines[1] = "foo bar baz"
    @buffer.lines[2] = "hello again"
    @window = Mui::Window.new(@buffer)
    @mode_manager = MockModeManager.new(@window)
    @search_input = Mui::SearchInput.new("/")
    @search_state = Mui::SearchState.new
    @handler = Mui::KeyHandler::SearchMode.new(@mode_manager, @buffer, @search_input, @search_state)
  end

  def test_escape_cancels_search
    @search_input.input("test")
    result = @handler.handle(Mui::KeyCode::ESCAPE)

    assert_equal Mui::Mode::NORMAL, result.mode
    assert result.cancelled?
    assert_equal "", @search_input.buffer
  end

  def test_backspace_on_empty_cancels
    result = @handler.handle(Mui::KeyCode::BACKSPACE)

    assert_equal Mui::Mode::NORMAL, result.mode
    assert result.cancelled?
  end

  def test_backspace_removes_character
    @search_input.input("test")
    result = @handler.handle(Mui::KeyCode::BACKSPACE)

    assert_nil result.mode
    assert_equal "tes", @search_input.buffer
  end

  def test_character_input
    result = @handler.handle("h")

    assert_nil result.mode
    assert_equal "h", @search_input.buffer
  end

  def test_enter_executes_search
    @search_input.input("hello")
    result = @handler.handle(Mui::KeyCode::ENTER_CR)

    assert_equal Mui::Mode::NORMAL, result.mode
    refute result.cancelled?
    assert_equal "hello", @search_state.pattern
    # Cursor should move to first match (which is at 0,0, but we start there so should find next)
    # Actually, find_next from 0,0 finds match starting after col 0, which is row 2, col 0
    # But the first match at 0,0 overlaps with current position
  end

  def test_enter_with_empty_pattern_cancels
    result = @handler.handle(Mui::KeyCode::ENTER_CR)

    assert_equal Mui::Mode::NORMAL, result.mode
    assert result.cancelled?
  end

  def test_enter_pattern_not_found
    @search_input.input("xyz")
    result = @handler.handle(Mui::KeyCode::ENTER_CR)

    assert_equal Mui::Mode::NORMAL, result.mode
    assert_includes result.message, "Pattern not found"
  end

  def test_search_forward_direction
    @search_input.set_prompt("/")
    @search_input.input("hello")
    @handler.handle(Mui::KeyCode::ENTER_CR)

    assert_equal :forward, @search_state.direction
  end

  def test_search_backward_direction
    @search_input.set_prompt("?")
    @search_input.input("hello")
    @handler.handle(Mui::KeyCode::ENTER_CR)

    assert_equal :backward, @search_state.direction
  end

  def test_cursor_moves_to_match
    @window.cursor_row = 1
    @window.cursor_col = 0
    @search_input.input("hello")
    @handler.handle(Mui::KeyCode::ENTER_CR)

    # Should find "hello" at row 2 (the next one after row 1)
    assert_equal 2, @window.cursor_row
    assert_equal 0, @window.cursor_col
  end

  def test_regex_search
    buffer = Mui::Buffer.new
    buffer.lines[0] = "test123"
    window = Mui::Window.new(buffer)
    mode_manager = MockModeManager.new(window)
    search_input = Mui::SearchInput.new("/")
    search_state = Mui::SearchState.new
    handler = Mui::KeyHandler::SearchMode.new(mode_manager, buffer, search_input, search_state)

    search_input.input("\\d+")
    handler.handle(Mui::KeyCode::ENTER_CR)

    assert_equal 1, search_state.matches.length
  end
end
