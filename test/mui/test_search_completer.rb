# frozen_string_literal: true

require "test_helper"

class TestSearchCompleter < Minitest::Test
  def setup
    @completer = Mui::SearchCompleter.new
    @buffer = Mui::Buffer.new
    @buffer.lines[0] = "hello world"
    @buffer.lines[1] = "hello_world function"
    @buffer.lines[2] = "helper method helps"
  end

  def test_complete_returns_matching_words
    candidates = @completer.complete(@buffer, "hel")

    assert_includes candidates, "hello"
    assert_includes candidates, "hello_world"
    assert_includes candidates, "helper"
    assert_includes candidates, "helps"
  end

  def test_complete_excludes_exact_match
    candidates = @completer.complete(@buffer, "hello")

    refute_includes candidates, "hello"
    assert_includes candidates, "hello_world"
  end

  def test_complete_returns_empty_for_no_match
    candidates = @completer.complete(@buffer, "xyz")

    assert_empty candidates
  end

  def test_complete_returns_empty_for_empty_prefix
    candidates = @completer.complete(@buffer, "")

    assert_empty candidates
  end

  def test_complete_returns_empty_for_nil_prefix
    candidates = @completer.complete(@buffer, nil)

    assert_empty candidates
  end

  def test_complete_sorts_by_length_then_alphabetically
    candidates = @completer.complete(@buffer, "hel")

    # Shorter words first
    hello_index = candidates.index("hello")
    hello_world_index = candidates.index("hello_world")

    assert hello_index < hello_world_index, "Shorter words should come first"
  end

  def test_complete_extracts_words_with_underscores
    candidates = @completer.complete(@buffer, "hello_")

    assert_includes candidates, "hello_world"
  end

  def test_complete_ignores_single_character_words
    @buffer.lines[0] = "a b c test"

    candidates = @completer.complete(@buffer, "t")

    assert_includes candidates, "test"
    refute_includes candidates, "a"
  end

  def test_complete_finds_words_starting_with_underscore
    @buffer.lines[0] = "_private_method test"

    candidates = @completer.complete(@buffer, "_priv")

    assert_includes candidates, "_private_method"
  end

  def test_complete_respects_max_candidates
    # Create buffer with many matching words
    @buffer.lines[0] = (1..100).map { |i| "test#{i}" }.join(" ")

    candidates = @completer.complete(@buffer, "test")

    assert candidates.length <= Mui::SearchCompleter::MAX_CANDIDATES
  end

  def test_complete_uses_cache_for_same_buffer
    # First call
    candidates1 = @completer.complete(@buffer, "hel")

    # Second call with same buffer should use cache
    candidates2 = @completer.complete(@buffer, "wor")

    assert_includes candidates1, "hello"
    assert_includes candidates2, "world"
  end

  def test_complete_invalidates_cache_on_buffer_change
    candidates1 = @completer.complete(@buffer, "hel")
    assert_includes candidates1, "hello"

    # Modify buffer
    @buffer.lines[0] = "goodbye world"

    candidates2 = @completer.complete(@buffer, "hel")

    # hello should no longer be found
    refute_includes candidates2, "hello"
    assert_includes candidates2, "helper"
  end
end
