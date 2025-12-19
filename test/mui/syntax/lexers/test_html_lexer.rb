# frozen_string_literal: true

require "test_helper"

class TestHtmlLexer < Minitest::Test
  def setup
    @lexer = Mui::Syntax::Lexers::HtmlLexer.new
  end

  # Tags
  def test_tokenize_opening_tag
    tokens, _state = @lexer.tokenize("<div>")
    tag_tokens = tokens.select { |t| t.type == :keyword }

    assert_operator tag_tokens.length, :>=, 1
    assert(tag_tokens.any? { |t| t.text.include?("div") })
  end

  def test_tokenize_closing_tag
    tokens, _state = @lexer.tokenize("</div>")

    assert_equal 1, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "</div>", tokens[0].text
  end

  def test_tokenize_self_closing_tag
    tokens, _state = @lexer.tokenize("<br/>")

    assert_equal 1, tokens.length
    assert_equal :keyword, tokens[0].type
  end

  def test_tokenize_self_closing_with_space
    tokens, _state = @lexer.tokenize("<br />")
    tag_tokens = tokens.select { |t| t.type == :keyword }

    assert_operator tag_tokens.length, :>=, 1
  end

  # Attributes
  def test_tokenize_attribute_with_double_quotes
    tokens, _state = @lexer.tokenize('<div class="container">')
    string_tokens = tokens.select { |t| t.type == :string }

    assert_equal 1, string_tokens.length
    assert_equal '"container"', string_tokens[0].text
  end

  def test_tokenize_attribute_with_single_quotes
    tokens, _state = @lexer.tokenize("<div class='container'>")
    string_tokens = tokens.select { |t| t.type == :string }

    assert_equal 1, string_tokens.length
    assert_equal "'container'", string_tokens[0].text
  end

  def test_tokenize_multiple_attributes
    tokens, _state = @lexer.tokenize('<div id="main" class="container">')
    string_tokens = tokens.select { |t| t.type == :string }

    assert_equal 2, string_tokens.length
  end

  def test_tokenize_attribute_name
    tokens, _state = @lexer.tokenize('<div class="x">')
    type_tokens = tokens.select { |t| t.type == :type }

    assert_equal 1, type_tokens.length
    assert_equal "class", type_tokens[0].text
  end

  # Comments
  def test_tokenize_single_line_comment
    tokens, _state = @lexer.tokenize("<!-- comment -->")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "<!-- comment -->", tokens[0].text
  end

  def test_tokenize_inline_comment
    tokens, _state = @lexer.tokenize("<div><!-- note --></div>")
    comment_tokens = tokens.select { |t| t.type == :comment }

    assert_equal 1, comment_tokens.length
  end

  # Multiline comments
  def test_comment_multiline_start
    tokens, state = @lexer.tokenize("<!-- start of comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal :html_comment, state
  end

  def test_comment_multiline_middle
    tokens, state = @lexer.tokenize("  middle of comment  ", :html_comment)

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal :html_comment, state
  end

  def test_comment_multiline_end
    tokens, state = @lexer.tokenize("end of comment -->", :html_comment)

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_nil state
  end

  def test_comment_full_sequence
    _, state1 = @lexer.tokenize("<!-- Start")

    assert_equal :html_comment, state1

    _, state2 = @lexer.tokenize("Middle", state1)

    assert_equal :html_comment, state2

    _, state3 = @lexer.tokenize("End -->", state2)

    assert_nil state3
  end

  # DOCTYPE
  def test_tokenize_doctype
    tokens, _state = @lexer.tokenize("<!DOCTYPE html>")

    assert_equal 1, tokens.length
    assert_equal :preprocessor, tokens[0].type
    assert_equal "<!DOCTYPE html>", tokens[0].text
  end

  def test_tokenize_doctype_case_insensitive
    tokens, _state = @lexer.tokenize("<!doctype html>")

    assert_equal 1, tokens.length
    assert_equal :preprocessor, tokens[0].type
  end

  # HTML entities
  def test_tokenize_entity_named
    tokens, _state = @lexer.tokenize("&amp;")

    assert_equal 1, tokens.length
    assert_equal :constant, tokens[0].type
    assert_equal "&amp;", tokens[0].text
  end

  def test_tokenize_entity_decimal
    tokens, _state = @lexer.tokenize("&#169;")

    assert_equal 1, tokens.length
    assert_equal :constant, tokens[0].type
  end

  def test_tokenize_entity_hex
    tokens, _state = @lexer.tokenize("&#x00A9;")

    assert_equal 1, tokens.length
    assert_equal :constant, tokens[0].type
  end

  def test_tokenize_common_entities
    %w[&lt; &gt; &nbsp; &copy;].each do |entity|
      tokens, _state = @lexer.tokenize(entity)

      assert_equal 1, tokens.length, "Expected 1 token for '#{entity}'"
      assert_equal :constant, tokens[0].type, "Expected :constant for '#{entity}'"
    end
  end

  # Complex examples
  def test_tokenize_complete_tag
    tokens, _state = @lexer.tokenize('<a href="https://example.com">Link</a>')
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :string
  end

  def test_tokenize_nested_tags
    tokens, _state = @lexer.tokenize("<div><span></span></div>")
    keyword_tokens = tokens.select { |t| t.type == :keyword }

    assert_operator keyword_tokens.length, :>=, 2
  end

  def test_tokenize_input_tag
    # Self-closing tags with attributes are matched as a single keyword token
    tokens, _state = @lexer.tokenize('<input type="text" name="username"/>')
    keyword_tokens = tokens.select { |t| t.type == :keyword }

    assert_equal 1, keyword_tokens.length
  end

  # Edge cases
  def test_tokenize_empty_line
    tokens, state = @lexer.tokenize("")

    assert_empty tokens
    assert_nil state
  end

  def test_tokenize_plain_text
    tokens, state = @lexer.tokenize("Just plain text")
    # Plain text should not produce tokens
    assert_empty tokens
    assert_nil state
  end

  def test_tokenize_whitespace_only
    tokens, state = @lexer.tokenize("   ")

    assert_empty tokens
    assert_nil state
  end
end
