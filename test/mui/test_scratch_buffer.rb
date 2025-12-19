# frozen_string_literal: true

require "test_helper"

class TestScratchBuffer < Minitest::Test
  def test_buffer_default_not_readonly
    buffer = Mui::Buffer.new

    refute_predicate buffer, :readonly?
  end

  def test_buffer_readonly_flag
    buffer = Mui::Buffer.new
    buffer.readonly = true

    assert_predicate buffer, :readonly?
  end

  def test_content_assignment_single_line
    buffer = Mui::Buffer.new
    buffer.content = "hello world"

    assert_equal 1, buffer.line_count
    assert_equal "hello world", buffer.line(0)
    refute buffer.modified
  end

  def test_content_assignment_multiple_lines
    buffer = Mui::Buffer.new
    buffer.content = "line1\nline2\nline3"

    assert_equal 3, buffer.line_count
    assert_equal "line1", buffer.line(0)
    assert_equal "line2", buffer.line(1)
    assert_equal "line3", buffer.line(2)
  end

  def test_content_assignment_empty_string
    buffer = Mui::Buffer.new
    buffer.content = ""

    assert_equal 1, buffer.line_count
    assert_equal "", buffer.line(0)
  end

  def test_content_assignment_preserves_empty_lines
    buffer = Mui::Buffer.new
    buffer.content = "line1\n\nline3"

    assert_equal 3, buffer.line_count
    assert_equal "line1", buffer.line(0)
    assert_equal "", buffer.line(1)
    assert_equal "line3", buffer.line(2)
  end

  def test_content_assignment_trailing_newline
    buffer = Mui::Buffer.new
    buffer.content = "line1\nline2\n"

    assert_equal 3, buffer.line_count
    assert_equal "line1", buffer.line(0)
    assert_equal "line2", buffer.line(1)
    assert_equal "", buffer.line(2)
  end

  def test_content_assignment_resets_modified_flag
    buffer = Mui::Buffer.new
    buffer.insert_char(0, 0, "x")

    assert buffer.modified

    buffer.content = "new content"

    refute buffer.modified
  end

  def test_scratch_buffer_workflow
    # Typical scratch buffer usage
    buffer = Mui::Buffer.new("[Test Results]")
    buffer.content = "Test output:\n  - test1: pass\n  - test2: fail"
    buffer.readonly = true

    assert_equal "[Test Results]", buffer.name
    assert_predicate buffer, :readonly?
    assert_equal 3, buffer.line_count
    refute buffer.modified
  end
end
