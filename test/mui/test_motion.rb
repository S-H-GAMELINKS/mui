# frozen_string_literal: true

require "test_helper"

class TestMotion < Minitest::Test
  class TestLeft < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
    end

    def test_moves_left
      result = Mui::Motion.left(@buffer, 0, 3)

      assert_equal({ row: 0, col: 2 }, result)
    end

    def test_returns_nil_at_start_of_line
      result = Mui::Motion.left(@buffer, 0, 0)

      assert_nil result
    end
  end

  class TestRight < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
    end

    def test_moves_right
      result = Mui::Motion.right(@buffer, 0, 2)

      assert_equal({ row: 0, col: 3 }, result)
    end

    def test_returns_nil_at_end_of_line
      result = Mui::Motion.right(@buffer, 0, 4)

      assert_nil result
    end
  end

  class TestUp < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "line1"
      @buffer.insert_line(1, "line2")
    end

    def test_moves_up
      result = Mui::Motion.up(@buffer, 1, 2)

      assert_equal({ row: 0, col: 2 }, result)
    end

    def test_returns_nil_at_first_line
      result = Mui::Motion.up(@buffer, 0, 2)

      assert_nil result
    end
  end

  class TestDown < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "line1"
      @buffer.insert_line(1, "line2")
    end

    def test_moves_down
      result = Mui::Motion.down(@buffer, 0, 2)

      assert_equal({ row: 1, col: 2 }, result)
    end

    def test_returns_nil_at_last_line
      result = Mui::Motion.down(@buffer, 1, 2)

      assert_nil result
    end
  end

  class TestWordForward < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def test_moves_to_next_word
      @buffer.lines[0] = "hello world"

      result = Mui::Motion.word_forward(@buffer, 0, 0)

      assert_equal({ row: 0, col: 6 }, result)
    end

    def test_moves_to_next_line_if_at_end
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")

      result = Mui::Motion.word_forward(@buffer, 0, 5)

      assert_equal({ row: 1, col: 0 }, result)
    end

    def test_skips_whitespace
      @buffer.lines[0] = "hello   world"

      result = Mui::Motion.word_forward(@buffer, 0, 0)

      assert_equal({ row: 0, col: 8 }, result)
    end
  end

  class TestWordBackward < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def test_moves_to_previous_word
      @buffer.lines[0] = "hello world"

      result = Mui::Motion.word_backward(@buffer, 0, 8)

      assert_equal({ row: 0, col: 6 }, result)
    end

    def test_moves_to_start_of_current_word
      @buffer.lines[0] = "hello world"

      result = Mui::Motion.word_backward(@buffer, 0, 6)

      assert_equal({ row: 0, col: 0 }, result)
    end

    def test_moves_to_previous_line_if_at_start
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")

      result = Mui::Motion.word_backward(@buffer, 1, 0)

      assert_equal({ row: 0, col: 0 }, result)
    end
  end

  class TestWordEnd < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def test_moves_to_end_of_current_word
      @buffer.lines[0] = "hello world"

      result = Mui::Motion.word_end(@buffer, 0, 0)

      assert_equal({ row: 0, col: 4 }, result)
    end

    def test_moves_to_end_of_next_word
      @buffer.lines[0] = "hello world"

      result = Mui::Motion.word_end(@buffer, 0, 4)

      assert_equal({ row: 0, col: 10 }, result)
    end
  end

  class TestLineStart < Minitest::Test
    def test_moves_to_start_of_line
      buffer = Mui::Buffer.new
      buffer.lines[0] = "  hello"

      result = Mui::Motion.line_start(buffer, 0, 5)

      assert_equal({ row: 0, col: 0 }, result)
    end
  end

  class TestFirstNonBlank < Minitest::Test
    def test_moves_to_first_non_blank_character
      buffer = Mui::Buffer.new
      buffer.lines[0] = "  hello"

      result = Mui::Motion.first_non_blank(buffer, 0, 0)

      assert_equal({ row: 0, col: 2 }, result)
    end

    def test_returns_zero_if_line_is_blank
      buffer = Mui::Buffer.new
      buffer.lines[0] = "   "

      result = Mui::Motion.first_non_blank(buffer, 0, 0)

      assert_equal({ row: 0, col: 0 }, result)
    end
  end

  class TestLineEnd < Minitest::Test
    def test_moves_to_end_of_line
      buffer = Mui::Buffer.new
      buffer.lines[0] = "hello"

      result = Mui::Motion.line_end(buffer, 0, 0)

      assert_equal({ row: 0, col: 4 }, result)
    end

    def test_returns_zero_for_empty_line
      buffer = Mui::Buffer.new
      buffer.lines[0] = ""

      result = Mui::Motion.line_end(buffer, 0, 0)

      assert_equal({ row: 0, col: 0 }, result)
    end
  end

  class TestFileStart < Minitest::Test
    def test_moves_to_start_of_file
      buffer = Mui::Buffer.new
      buffer.lines[0] = "line1"
      buffer.insert_line(1, "line2")
      buffer.insert_line(2, "line3")

      result = Mui::Motion.file_start(buffer, 2, 3)

      assert_equal({ row: 0, col: 0 }, result)
    end
  end

  class TestFileEnd < Minitest::Test
    def test_moves_to_end_of_file
      buffer = Mui::Buffer.new
      buffer.lines[0] = "line1"
      buffer.insert_line(1, "line2")
      buffer.insert_line(2, "line3")

      result = Mui::Motion.file_end(buffer, 0, 0)

      assert_equal({ row: 2, col: 0 }, result)
    end
  end

  class TestFindCharForward < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
    end

    def test_finds_character_forward
      result = Mui::Motion.find_char_forward(@buffer, 0, 0, "o")

      assert_equal({ row: 0, col: 4 }, result)
    end

    def test_finds_second_occurrence
      result = Mui::Motion.find_char_forward(@buffer, 0, 4, "o")

      assert_equal({ row: 0, col: 7 }, result)
    end

    def test_returns_nil_if_not_found
      result = Mui::Motion.find_char_forward(@buffer, 0, 0, "z")

      assert_nil result
    end
  end

  class TestFindCharBackward < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
    end

    def test_finds_character_backward
      result = Mui::Motion.find_char_backward(@buffer, 0, 10, "o")

      assert_equal({ row: 0, col: 7 }, result)
    end

    def test_finds_first_occurrence_backward
      result = Mui::Motion.find_char_backward(@buffer, 0, 7, "o")

      assert_equal({ row: 0, col: 4 }, result)
    end

    def test_returns_nil_if_not_found
      result = Mui::Motion.find_char_backward(@buffer, 0, 10, "z")

      assert_nil result
    end
  end

  class TestTillCharForward < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
    end

    def test_moves_to_before_character
      result = Mui::Motion.till_char_forward(@buffer, 0, 0, "o")

      assert_equal({ row: 0, col: 3 }, result)
    end

    def test_returns_nil_if_not_found
      result = Mui::Motion.till_char_forward(@buffer, 0, 0, "z")

      assert_nil result
    end
  end

  class TestTillCharBackward < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world"
    end

    def test_moves_to_after_character
      result = Mui::Motion.till_char_backward(@buffer, 0, 10, "o")

      assert_equal({ row: 0, col: 8 }, result)
    end

    def test_returns_nil_if_not_found
      result = Mui::Motion.till_char_backward(@buffer, 0, 10, "z")

      assert_nil result
    end
  end
end
