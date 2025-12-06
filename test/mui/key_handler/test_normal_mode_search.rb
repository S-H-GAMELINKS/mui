# frozen_string_literal: true

require "test_helper"

class TestNormalModeSearch < Minitest::Test
  def setup
    @buffer = Mui::Buffer.new
    @buffer.lines[0] = "hello world hello"
    @buffer.lines[1] = "foo bar"
    @buffer.lines[2] = "hello again"
    @window = Mui::Window.new(@buffer)
    @mode_manager = MockModeManager.new(@window)
    @register = Mui::Register.new
    @search_state = Mui::SearchState.new
    @handler = Mui::KeyHandler::NormalMode.new(@mode_manager, @buffer, @register, search_state: @search_state)
  end

  def test_slash_enters_search_forward_mode
    result = @handler.handle("/")
    assert_equal Mui::Mode::SEARCH_FORWARD, result.mode
  end

  def test_question_mark_enters_search_backward_mode
    result = @handler.handle("?")
    assert_equal Mui::Mode::SEARCH_BACKWARD, result.mode
  end

  def test_n_without_previous_search
    result = @handler.handle("n")
    assert_includes result.message, "No previous search pattern"
  end

  def test_N_without_previous_search
    result = @handler.handle("N")
    assert_includes result.message, "No previous search pattern"
  end

  def test_n_finds_next_match_forward
    setup_search("hello", :forward)
    @window.cursor_row = 0
    @window.cursor_col = 0

    result = @handler.handle("n")

    assert_nil result.message
    # Next "hello" after 0,0 is at 0,12
    assert_equal 0, @window.cursor_row
    assert_equal 12, @window.cursor_col
  end

  def test_n_wraps_around
    setup_search("hello", :forward)
    @window.cursor_row = 2
    @window.cursor_col = 5 # After the last "hello"

    result = @handler.handle("n")

    assert_nil result.message
    # Should wrap to first "hello" at 0,0
    assert_equal 0, @window.cursor_row
    assert_equal 0, @window.cursor_col
  end

  def test_N_finds_previous_match
    setup_search("hello", :forward)
    @window.cursor_row = 2
    @window.cursor_col = 5

    result = @handler.handle("N")

    assert_nil result.message
    # Previous "hello" should be at 2,0
    assert_equal 2, @window.cursor_row
    assert_equal 0, @window.cursor_col
  end

  def test_n_backward_search_reverses_direction
    setup_search("hello", :backward)
    @window.cursor_row = 0
    @window.cursor_col = 12

    @handler.handle("n")

    # n in backward mode goes to previous (which is earlier in file)
    assert_equal 0, @window.cursor_row
    assert_equal 0, @window.cursor_col
  end

  def test_N_backward_search_reverses_direction
    setup_search("hello", :backward)
    @window.cursor_row = 0
    @window.cursor_col = 0

    @handler.handle("N")

    # N in backward mode goes forward (later in file)
    assert_equal 0, @window.cursor_row
    assert_equal 12, @window.cursor_col
  end

  def test_n_no_match_shows_message
    setup_search("xyz", :forward)

    result = @handler.handle("n")

    assert_includes result.message, "Pattern not found"
  end

  private

  def setup_search(pattern, direction)
    @search_state.set_pattern(pattern, direction)
    @search_state.find_all_matches(@buffer)
  end
end
