# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestBuffer
  class TestInitialize < Minitest::Test
    def test_initialize_with_default_name
      buffer = Mui::Buffer.new

      assert_equal "[No Name]", buffer.name
      assert_equal 1, buffer.line_count
      assert_equal [""], buffer.lines
      refute buffer.modified
    end

    def test_initialize_with_custom_name
      buffer = Mui::Buffer.new("test.txt")

      assert_equal "test.txt", buffer.name
    end
  end

  class TestLoad < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_load_existing_file
      Tempfile.create(["test", ".txt"]) do |f|
        f.write("line1\nline2\nline3")
        f.flush

        @buffer.load(f.path)

        assert_equal f.path, @buffer.name
        assert_equal 3, @buffer.line_count
        assert_equal "line1", @buffer.line(0)
        assert_equal "line2", @buffer.line(1)
        assert_equal "line3", @buffer.line(2)
        refute @buffer.modified
      end
    end

    def test_load_nonexistent_file
      @buffer.load("/nonexistent/path/file.txt")

      assert_equal "/nonexistent/path/file.txt", @buffer.name
      assert_equal 1, @buffer.line_count
      assert_equal "", @buffer.line(0)
    end

    def test_load_empty_file
      Tempfile.create(["empty", ".txt"]) do |f|
        @buffer.load(f.path)

        assert_equal 1, @buffer.line_count
        assert_equal "", @buffer.line(0)
      end
    end
  end

  class TestSave < Minitest::Test
    def test_save
      buffer = Mui::Buffer.new

      buffer.insert_char(0, 0, "H")
      buffer.insert_char(0, 1, "i")

      Tempfile.create(["save", ".txt"]) do |f|
        buffer.save(f.path)

        assert_equal "Hi\n", File.read(f.path)
        assert_equal f.path, buffer.name
        refute buffer.modified
      end
    end
  end

  class TestLineCount < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_line_count_with_initialize_default
      assert_equal 1, @buffer.line_count
    end

    def test_line_count_with_file
      Tempfile.create(["test", ".txt"]) do |f|
        f.write("line1\nline2\nline3")
        f.flush

        @buffer.load(f.path)

        assert_equal 3, @buffer.line_count
      end
    end

    def test_line_count_with_empty_file
      Tempfile.create(["empty", ".txt"]) do |f|
        @buffer.load(f.path)

        assert_equal 1, @buffer.line_count
      end
    end
  end

  class TestLine < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_line_was_exist
      Tempfile.create(["test", ".txt"]) do |f|
        f.write("line1\nline2\nline3")
        f.flush

        @buffer.load(f.path)

        assert_equal "line1", @buffer.line(0)
        assert_equal "line2", @buffer.line(1)
        assert_equal "line3", @buffer.line(2)
      end
    end

    def test_line_was_not_exist
      Tempfile.create(["test", ".txt"]) do |f|
        f.write("line1\nline2\nline3")
        f.flush

        @buffer.load(f.path)

        assert_equal "", @buffer.line(3)
      end
    end
  end

  class TestInsertChar < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_insert_char
      @buffer.insert_char(0, 0, "a")

      assert_equal "a", @buffer.line(0)
      assert @buffer.modified

      @buffer.insert_char(0, 1, "b")

      assert_equal "ab", @buffer.line(0)
      assert @buffer.modified

      @buffer.insert_char(0, 1, "X")

      assert_equal "aXb", @buffer.line(0)
      assert @buffer.modified

      @buffer.insert_char(0, 1, "")

      assert_equal "aXb", @buffer.line(0)
      assert @buffer.modified
    end

    def test_insert_char_with_empty_char
      @buffer.insert_char(0, 0, "a")
      @buffer.insert_char(0, 1, "b")
      @buffer.insert_char(0, 1, "")

      assert_equal "ab", @buffer.line(0)
      assert @buffer.modified
    end

    def test_insert_char_creates_line_if_nil
      @buffer.insert_char(5, 0, "x")

      assert_equal "x", @buffer.lines[5]
      assert @buffer.modified
    end
  end

  class DeleteChar < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_delete_char
      @buffer.insert_char(0, 0, "a")
      @buffer.insert_char(0, 1, "b")
      @buffer.insert_char(0, 2, "c")

      @buffer.delete_char(0, 1)

      assert_equal "ac", @buffer.line(0)
    end

    def test_delete_char_at_invalid_position
      @buffer.insert_char(0, 0, "a")

      @buffer.delete_char(0, -1)

      assert_equal "a", @buffer.line(0)

      @buffer.delete_char(0, 10)

      assert_equal "a", @buffer.line(0)
    end
  end

  class TestInsertLine < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_insert_line
      @buffer.insert_line(0, "first")

      assert_equal "first", @buffer.line(0)
      assert_equal "", @buffer.line(1)

      @buffer.insert_line(1, "second")

      assert_equal "first", @buffer.line(0)
      assert_equal "second", @buffer.line(1)
    end

    def test_insert_line_with_nil_creates_empty_string
      @buffer.insert_line(0)

      assert_equal "", @buffer.line(0)
      # Verify the string is mutable
      @buffer.lines[0].insert(0, "x")

      assert_equal "x", @buffer.line(0)
    end
  end

  class TestDeleteLine < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_delete_line
      @buffer.insert_line(0, "first")
      @buffer.insert_line(1, "second")

      @buffer.delete_line(0)

      assert_equal "second", @buffer.line(0)
    end

    def test_delete_line_keeps_one_empty_line
      @buffer.delete_line(0)

      assert_equal 1, @buffer.line_count
      assert_equal "", @buffer.line(0)
    end
  end

  class TestSplitLine < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_split_line
      @buffer.insert_char(0, 0, "H")
      @buffer.insert_char(0, 1, "e")
      @buffer.insert_char(0, 2, "l")
      @buffer.insert_char(0, 3, "l")
      @buffer.insert_char(0, 4, "o")

      @buffer.split_line(0, 2)

      assert_equal 2, @buffer.line_count
      assert_equal "He", @buffer.line(0)
      assert_equal "llo", @buffer.line(1)
    end

    def test_split_line_at_beginning
      @buffer.insert_char(0, 0, "a")
      @buffer.insert_char(0, 1, "b")

      @buffer.split_line(0, 0)

      assert_equal "", @buffer.line(0)
      assert_equal "ab", @buffer.line(1)
    end

    def test_split_line_at_end
      @buffer.insert_char(0, 0, "a")
      @buffer.insert_char(0, 1, "b")

      @buffer.split_line(0, 2)

      assert_equal "ab", @buffer.line(0)
      assert_equal "", @buffer.line(1)
    end
  end

  class TestJoinLines < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_join_lines
      @buffer.insert_line(0, "Hello")
      @buffer.insert_line(1, "World")

      @buffer.join_lines(0)

      assert_equal 2, @buffer.line_count
      assert_equal "HelloWorld", @buffer.line(0)
    end

    def test_join_lines_at_last_line_does_nothing
      @buffer.insert_line(0, "only")
      initial_count = @buffer.line_count

      @buffer.join_lines(@buffer.line_count - 1)

      assert_equal initial_count, @buffer.line_count
    end
  end

  class TestLine < Minitest::Test
    def test_line_returns_empty_string_for_invalid_row
      buffer = Mui::Buffer.new

      assert_equal "", buffer.line(-1)
      assert_equal "", buffer.line(100)
    end
  end

  class TestDeleteRange < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_delete_range_within_same_line
      @buffer.lines[0] = "hello world"

      @buffer.delete_range(0, 2, 0, 5)

      assert_equal "heworld", @buffer.line(0)
      assert @buffer.modified
    end

    def test_delete_range_at_line_start
      @buffer.lines[0] = "hello"

      @buffer.delete_range(0, 0, 0, 2)

      assert_equal "lo", @buffer.line(0)
    end

    def test_delete_range_at_line_end
      @buffer.lines[0] = "hello"

      @buffer.delete_range(0, 3, 0, 4)

      assert_equal "hel", @buffer.line(0)
    end

    def test_delete_range_across_two_lines
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")

      @buffer.delete_range(0, 2, 1, 2)

      assert_equal 1, @buffer.line_count
      assert_equal "held", @buffer.line(0)
    end

    def test_delete_range_across_multiple_lines
      @buffer.lines[0] = "line1"
      @buffer.insert_line(1, "line2")
      @buffer.insert_line(2, "line3")
      @buffer.insert_line(3, "line4")

      @buffer.delete_range(0, 2, 2, 2)

      assert_equal 2, @buffer.line_count
      assert_equal "lie3", @buffer.line(0)
      assert_equal "line4", @buffer.line(1)
    end

    def test_delete_range_entire_line_content
      @buffer.lines[0] = "hello"
      @buffer.insert_line(1, "world")

      @buffer.delete_range(0, 0, 0, 4)

      assert_equal 2, @buffer.line_count
      assert_equal "", @buffer.line(0)
      assert_equal "world", @buffer.line(1)
    end
  end

  class TestCustomHighlighters < Minitest::Test
    class MockHighlighter
      def initialize(name)
        @name = name
      end

      attr_reader :name
    end

    def setup
      @buffer = Mui::Buffer.new
    end

    def teardown
      @buffer = nil
    end

    def test_add_custom_highlighter
      highlighter = MockHighlighter.new("test")

      @buffer.add_custom_highlighter(:test, highlighter)

      assert @buffer.custom_highlighter?(:test)
    end

    def test_custom_highlighter_returns_false_when_not_present
      refute @buffer.custom_highlighter?(:nonexistent)
    end

    def test_remove_custom_highlighter
      highlighter = MockHighlighter.new("test")
      @buffer.add_custom_highlighter(:test, highlighter)

      @buffer.remove_custom_highlighter(:test)

      refute @buffer.custom_highlighter?(:test)
    end

    def test_remove_nonexistent_highlighter_does_not_raise
      @buffer.remove_custom_highlighter(:nonexistent)
      # Should not raise
    end

    def test_custom_highlighters_returns_all_highlighters
      h1 = MockHighlighter.new("first")
      h2 = MockHighlighter.new("second")

      @buffer.add_custom_highlighter(:first, h1)
      @buffer.add_custom_highlighter(:second, h2)

      highlighters = @buffer.custom_highlighters(nil)

      assert_equal 2, highlighters.length
      assert_includes highlighters, h1
      assert_includes highlighters, h2
    end

    def test_overwrite_existing_highlighter
      h1 = MockHighlighter.new("original")
      h2 = MockHighlighter.new("replacement")

      @buffer.add_custom_highlighter(:test, h1)
      @buffer.add_custom_highlighter(:test, h2)

      highlighters = @buffer.custom_highlighters(nil)

      assert_equal 1, highlighters.length
      assert_includes highlighters, h2
      refute_includes highlighters, h1
    end
  end
end
