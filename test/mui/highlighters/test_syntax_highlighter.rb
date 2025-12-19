# frozen_string_literal: true

require "test_helper"

class TestSyntaxHighlighter < Minitest::Test
  def setup
    @color_scheme = Mui::Themes.mui
  end

  def create_buffer(name, lines = [])
    buffer = Mui::Buffer.new(name)
    buffer.instance_variable_set(:@lines, lines.empty? ? [""] : lines)
    buffer
  end

  # Initialization
  def test_initialize_without_buffer
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme)

    refute_predicate highlighter, :active?
  end

  def test_initialize_with_ruby_buffer
    buffer = create_buffer("test.rb", ["def foo"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    assert_predicate highlighter, :active?
  end

  def test_initialize_with_unknown_extension
    buffer = create_buffer("test.txt", ["hello"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    refute_predicate highlighter, :active?
  end

  # Buffer assignment
  def test_buffer_assignment_updates_lexer
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme)

    refute_predicate highlighter, :active?

    buffer = create_buffer("test.rb", ["def foo"])
    highlighter.buffer = buffer

    assert_predicate highlighter, :active?
  end

  def test_buffer_assignment_to_nil
    buffer = create_buffer("test.rb", ["def foo"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    assert_predicate highlighter, :active?

    highlighter.buffer = nil

    refute_predicate highlighter, :active?
  end

  # Priority
  def test_priority
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme)

    assert_equal Mui::Highlighters::Base::PRIORITY_SYNTAX, highlighter.priority
  end

  # Highlights for Ruby
  def test_highlights_for_ruby_keyword
    buffer = create_buffer("test.rb", ["def foo"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights = highlighter.highlights_for(0, "def foo", buffer:)

    keyword_highlights = highlights.select { |h| h.style == :syntax_keyword }

    assert_equal 1, keyword_highlights.length
    assert_equal 0, keyword_highlights[0].start_col
    assert_equal 2, keyword_highlights[0].end_col
  end

  def test_highlights_for_ruby_string
    buffer = create_buffer("test.rb", ['"hello"'])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights = highlighter.highlights_for(0, '"hello"', buffer:)

    string_highlights = highlights.select { |h| h.style == :syntax_string }

    assert_equal 1, string_highlights.length
  end

  def test_highlights_for_ruby_comment
    buffer = create_buffer("test.rb", ["# comment"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights = highlighter.highlights_for(0, "# comment", buffer:)

    comment_highlights = highlights.select { |h| h.style == :syntax_comment }

    assert_equal 1, comment_highlights.length
  end

  def test_highlights_for_ruby_number
    buffer = create_buffer("test.rb", ["x = 42"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights = highlighter.highlights_for(0, "x = 42", buffer:)

    number_highlights = highlights.select { |h| h.style == :syntax_number }

    assert_equal 1, number_highlights.length
  end

  def test_highlights_for_ruby_symbol
    buffer = create_buffer("test.rb", [":foo"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights = highlighter.highlights_for(0, ":foo", buffer:)

    symbol_highlights = highlights.select { |h| h.style == :syntax_symbol }

    assert_equal 1, symbol_highlights.length
  end

  def test_highlights_for_ruby_constant
    buffer = create_buffer("test.rb", ["MyClass"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights = highlighter.highlights_for(0, "MyClass", buffer:)

    constant_highlights = highlights.select { |h| h.style == :syntax_constant }

    assert_equal 1, constant_highlights.length
  end

  # Highlights for C
  def test_highlights_for_c_type
    buffer = create_buffer("test.c", ["int main()"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights = highlighter.highlights_for(0, "int main()", buffer:)

    type_highlights = highlights.select { |h| h.style == :syntax_type }

    assert_equal 1, type_highlights.length
  end

  def test_highlights_for_c_preprocessor
    buffer = create_buffer("test.c", ["#include <stdio.h>"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights = highlighter.highlights_for(0, "#include <stdio.h>", buffer:)

    preprocessor_highlights = highlights.select { |h| h.style == :syntax_preprocessor }

    assert_equal 1, preprocessor_highlights.length
  end

  # No lexer scenarios
  def test_highlights_for_inactive_highlighter
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme)
    highlights = highlighter.highlights_for(0, "def foo", {})

    assert_empty highlights
  end

  def test_highlights_for_unknown_file_type
    buffer = create_buffer("test.txt", ["hello world"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights = highlighter.highlights_for(0, "hello world", buffer:)

    assert_empty highlights
  end

  # Cache operations
  def test_invalidate_from
    buffer = create_buffer("test.rb", ["def foo", "end"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    # Populate cache
    highlighter.highlights_for(0, "def foo", buffer:)
    highlighter.highlights_for(1, "end", buffer:)

    # Should not raise
    highlighter.invalidate_from(1)
  end

  def test_clear_cache
    buffer = create_buffer("test.rb", ["def foo"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlighter.highlights_for(0, "def foo", buffer:)

    # Should not raise
    highlighter.clear_cache
  end

  def test_clear_cache_when_inactive
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme)
    # Should not raise
    highlighter.clear_cache
  end

  # Multiline state
  def test_ruby_block_comment
    buffer = create_buffer("test.rb", ["=begin", "comment", "=end"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights0 = highlighter.highlights_for(0, "=begin", buffer:)
    highlights1 = highlighter.highlights_for(1, "comment", buffer:)
    highlights2 = highlighter.highlights_for(2, "=end", buffer:)

    assert(highlights0.all? { |h| h.style == :syntax_comment })
    assert(highlights1.all? { |h| h.style == :syntax_comment })
    assert(highlights2.all? { |h| h.style == :syntax_comment })
  end

  def test_c_block_comment
    buffer = create_buffer("test.c", ["/* start", "middle", "end */"])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights0 = highlighter.highlights_for(0, "/* start", buffer:)
    highlights1 = highlighter.highlights_for(1, "middle", buffer:)
    highlights2 = highlighter.highlights_for(2, "end */", buffer:)

    assert(highlights0.all? { |h| h.style == :syntax_comment })
    assert(highlights1.all? { |h| h.style == :syntax_comment })
    assert(highlights2.all? { |h| h.style == :syntax_comment })
  end

  # Empty line
  def test_highlights_for_empty_line
    buffer = create_buffer("test.rb", [""])
    highlighter = Mui::Highlighters::SyntaxHighlighter.new(@color_scheme, buffer:)

    highlights = highlighter.highlights_for(0, "", buffer:)

    assert_empty highlights
  end
end
