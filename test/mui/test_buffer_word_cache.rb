# frozen_string_literal: true

require "test_helper"

class TestBufferWordCache < Minitest::Test
  def setup
    @buffer = Mui::Buffer.new
  end

  class TestInitialize < TestBufferWordCache
    def test_builds_cache_from_buffer
      @buffer.content = "hello world"
      cache = Mui::BufferWordCache.new(@buffer)

      # Use cursor on second line to not exclude any word
      candidates = cache.complete("hel", 1, 0)

      assert_includes candidates, "hello"
    end

    def test_builds_cache_with_multiple_lines
      @buffer.content = "first line\nsecond line\nthird line"
      cache = Mui::BufferWordCache.new(@buffer)

      # Use cursor position that doesn't overlap with search results
      candidates = cache.complete("lin", 5, 0)

      assert_equal 1, candidates.length
      assert_includes candidates, "line"
    end

    def test_ignores_short_words
      @buffer.content = "a ab abc abcd"
      cache = Mui::BufferWordCache.new(@buffer)

      # Cursor at end of line, not inside any word
      candidates = cache.complete("a", 0, 14)

      refute_includes candidates, "a"
      assert_includes candidates, "ab"
      assert_includes candidates, "abc"
      assert_includes candidates, "abcd"
    end
  end

  class TestComplete < TestBufferWordCache
    def test_returns_matching_words
      @buffer.content = "apple banana apricot"
      cache = Mui::BufferWordCache.new(@buffer)

      # Cursor on second line
      candidates = cache.complete("ap", 1, 0)

      assert_includes candidates, "apple"
      assert_includes candidates, "apricot"
      refute_includes candidates, "banana"
    end

    def test_returns_sorted_results
      @buffer.content = "zebra apple mango"
      cache = Mui::BufferWordCache.new(@buffer)

      candidates = cache.complete("", 1, 0)

      # Empty prefix returns nothing
      assert_empty candidates
    end

    def test_case_insensitive_matching
      @buffer.content = "Apple APRICOT apron"
      cache = Mui::BufferWordCache.new(@buffer)

      # Cursor on second line
      candidates = cache.complete("ap", 1, 0)

      assert_equal 3, candidates.length
      assert_includes candidates, "Apple"
      assert_includes candidates, "APRICOT"
      assert_includes candidates, "apron"
    end

    def test_excludes_exact_prefix_match
      @buffer.content = "test testing tester"
      cache = Mui::BufferWordCache.new(@buffer)

      # Cursor on second line
      candidates = cache.complete("test", 1, 0)

      refute_includes candidates, "test"
      assert_includes candidates, "testing"
      assert_includes candidates, "tester"
    end

    def test_returns_empty_for_no_matches
      @buffer.content = "hello world"
      cache = Mui::BufferWordCache.new(@buffer)

      candidates = cache.complete("xyz", 1, 0)

      assert_empty candidates
    end

    def test_returns_empty_for_empty_prefix
      @buffer.content = "hello world"
      cache = Mui::BufferWordCache.new(@buffer)

      candidates = cache.complete("", 1, 0)

      assert_empty candidates
    end

    def test_excludes_word_at_cursor_position
      # When cursor is in the middle of a word, that word should be excluded
      @buffer.content = "test testing"
      cache = Mui::BufferWordCache.new(@buffer)

      # Complete with cursor on different line - both words included
      candidates = cache.complete("tes", 1, 0)

      assert_includes candidates, "test"
      assert_includes candidates, "testing"

      # Complete with cursor inside "test" word (col 2 is inside "test" at 0-4)
      candidates = cache.complete("tes", 0, 2)

      # "test" should be excluded because cursor is inside it
      refute_includes candidates, "test"
      assert_includes candidates, "testing"
    end
  end

  class TestPrefixAt < TestBufferWordCache
    def test_returns_word_prefix_at_cursor
      @buffer.content = "hello world"
      cache = Mui::BufferWordCache.new(@buffer)

      prefix = cache.prefix_at(0, 3)

      assert_equal "hel", prefix
    end

    def test_returns_full_word_at_end
      @buffer.content = "hello world"
      cache = Mui::BufferWordCache.new(@buffer)

      prefix = cache.prefix_at(0, 5)

      assert_equal "hello", prefix
    end

    def test_returns_empty_at_beginning
      @buffer.content = "hello world"
      cache = Mui::BufferWordCache.new(@buffer)

      prefix = cache.prefix_at(0, 0)

      assert_equal "", prefix
    end

    def test_returns_empty_after_space
      @buffer.content = "hello world"
      cache = Mui::BufferWordCache.new(@buffer)

      prefix = cache.prefix_at(0, 6)

      assert_equal "", prefix
    end

    def test_returns_word_on_second_line
      @buffer.content = "first\nsecond"
      cache = Mui::BufferWordCache.new(@buffer)

      prefix = cache.prefix_at(1, 3)

      assert_equal "sec", prefix
    end
  end

  class TestMarkDirty < TestBufferWordCache
    def test_mark_dirty_adds_new_words_from_row
      @buffer.content = "original"
      cache = Mui::BufferWordCache.new(@buffer)

      # Verify initial state (cursor on different line)
      candidates = cache.complete("ori", 1, 0)

      assert_includes candidates, "original"

      # Modify buffer by adding text
      @buffer.lines[0] = "original modified"
      cache.mark_dirty(0)

      # After marking dirty and completing, new word should be found
      candidates = cache.complete("mod", 1, 0)

      assert_includes candidates, "modified"

      # Old word should still be in cache
      candidates = cache.complete("ori", 1, 0)

      assert_includes candidates, "original"
    end
  end

  class TestAddWord < TestBufferWordCache
    def test_add_word_makes_it_available
      @buffer.content = "hello"
      cache = Mui::BufferWordCache.new(@buffer)

      cache.add_word("helper")

      # Cursor on second line to not exclude anything
      candidates = cache.complete("hel", 1, 0)

      assert_includes candidates, "hello"
      assert_includes candidates, "helper"
    end

    def test_add_word_ignores_short_words
      @buffer.content = "hello"
      cache = Mui::BufferWordCache.new(@buffer)

      cache.add_word("a")

      candidates = cache.complete("a", 1, 0)

      refute_includes candidates, "a"
    end

    def test_add_word_respects_min_length
      @buffer.content = "test"
      cache = Mui::BufferWordCache.new(@buffer)

      cache.add_word("ab")

      candidates = cache.complete("a", 1, 0)

      assert_includes candidates, "ab"
    end
  end

  class TestWordExtraction < TestBufferWordCache
    def test_extracts_words_separated_by_spaces
      @buffer.content = "one two three"
      cache = Mui::BufferWordCache.new(@buffer)

      # Cursor on second line
      assert_includes cache.complete("on", 1, 0), "one"
      assert_includes cache.complete("tw", 1, 0), "two"
      assert_includes cache.complete("th", 1, 0), "three"
    end

    def test_extracts_words_separated_by_punctuation
      @buffer.content = "foo.bar,baz;qux"
      cache = Mui::BufferWordCache.new(@buffer)

      # Cursor on second line
      assert_includes cache.complete("fo", 1, 0), "foo"
      assert_includes cache.complete("ba", 1, 0), "bar"
      assert_includes cache.complete("ba", 1, 0), "baz"
      assert_includes cache.complete("qu", 1, 0), "qux"
    end

    def test_extracts_words_with_underscores
      @buffer.content = "snake_case variable_name"
      cache = Mui::BufferWordCache.new(@buffer)

      # Cursor on second line
      candidates = cache.complete("sna", 1, 0)

      assert_includes candidates, "snake_case"
    end

    def test_extracts_words_with_numbers
      @buffer.content = "var1 test2 item3"
      cache = Mui::BufferWordCache.new(@buffer)

      # Cursor on second line
      assert_includes cache.complete("var", 1, 0), "var1"
      assert_includes cache.complete("tes", 1, 0), "test2"
    end

    def test_handles_empty_buffer
      @buffer.content = ""
      cache = Mui::BufferWordCache.new(@buffer)

      candidates = cache.complete("a", 1, 0)

      assert_empty candidates
    end

    def test_handles_whitespace_only
      @buffer.content = "   \n\t\n  "
      cache = Mui::BufferWordCache.new(@buffer)

      candidates = cache.complete("a", 5, 0)

      assert_empty candidates
    end
  end

  class TestMaxCandidates < TestBufferWordCache
    def test_limits_candidates_for_performance
      # Create buffer with many matching words
      words = Array.new(100) { |i| "test#{i}" }.join(" ")
      @buffer.content = words
      cache = Mui::BufferWordCache.new(@buffer)

      # Cursor on second line
      candidates = cache.complete("tes", 1, 0)

      # Should be limited by MAX_CANDIDATES (50)
      assert_operator candidates.length, :<=, Mui::BufferWordCache::MAX_CANDIDATES
    end
  end
end
