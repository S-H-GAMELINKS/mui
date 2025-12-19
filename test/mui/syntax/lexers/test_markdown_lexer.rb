# frozen_string_literal: true

require "test_helper"

class TestMarkdownLexer < Minitest::Test
  def setup
    @lexer = Mui::Syntax::Lexers::MarkdownLexer.new
  end

  # Headings
  def test_tokenize_heading_h1
    tokens, _state = @lexer.tokenize("# Heading 1")

    assert_equal 1, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "#", tokens[0].text
  end

  def test_tokenize_heading_h2
    tokens, _state = @lexer.tokenize("## Heading 2")

    assert_equal 1, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "##", tokens[0].text
  end

  def test_tokenize_heading_h3
    tokens, _state = @lexer.tokenize("### Heading 3")

    assert_equal 1, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "###", tokens[0].text
  end

  # Inline code
  def test_tokenize_inline_code
    tokens, _state = @lexer.tokenize("Use `code` here")
    code_tokens = tokens.select { |t| t.type == :string }

    assert_equal 1, code_tokens.length
    assert_equal "`code`", code_tokens[0].text
  end

  # Bold
  def test_tokenize_bold_asterisks
    tokens, _state = @lexer.tokenize("This is **bold** text")
    bold_tokens = tokens.select { |t| t.type == :keyword }

    assert_equal 1, bold_tokens.length
    assert_equal "**bold**", bold_tokens[0].text
  end

  def test_tokenize_bold_underscores
    tokens, _state = @lexer.tokenize("This is __bold__ text")
    bold_tokens = tokens.select { |t| t.type == :keyword }

    assert_equal 1, bold_tokens.length
    assert_equal "__bold__", bold_tokens[0].text
  end

  # Italic
  def test_tokenize_italic_asterisks
    tokens, _state = @lexer.tokenize("This is *italic* text")
    italic_tokens = tokens.select { |t| t.type == :comment }

    assert_equal 1, italic_tokens.length
    assert_equal "*italic*", italic_tokens[0].text
  end

  def test_tokenize_italic_underscores
    tokens, _state = @lexer.tokenize("This is _italic_ text")
    italic_tokens = tokens.select { |t| t.type == :comment }

    assert_equal 1, italic_tokens.length
    assert_equal "_italic_", italic_tokens[0].text
  end

  # Strikethrough
  def test_tokenize_strikethrough
    tokens, _state = @lexer.tokenize("This is ~~deleted~~ text")
    strike_tokens = tokens.select { |t| t.type == :comment }

    assert_equal 1, strike_tokens.length
    assert_equal "~~deleted~~", strike_tokens[0].text
  end

  # Links
  def test_tokenize_link
    tokens, _state = @lexer.tokenize("Click [here](https://example.com)")
    link_tokens = tokens.select { |t| t.type == :constant }

    assert_equal 1, link_tokens.length
    assert_equal "[here](https://example.com)", link_tokens[0].text
  end

  # Images
  def test_tokenize_image
    tokens, _state = @lexer.tokenize("![alt text](image.png)")
    image_tokens = tokens.select { |t| t.type == :constant }

    assert_equal 1, image_tokens.length
    assert_equal "![alt text](image.png)", image_tokens[0].text
  end

  # Reference links
  def test_tokenize_reference_link
    tokens, _state = @lexer.tokenize("[text][ref]")
    link_tokens = tokens.select { |t| t.type == :constant }

    assert_equal 1, link_tokens.length
    assert_equal "[text][ref]", link_tokens[0].text
  end

  # Blockquote
  def test_tokenize_blockquote
    tokens, _state = @lexer.tokenize("> This is a quote")

    assert_operator tokens.length, :>=, 1
    assert_equal :comment, tokens[0].type
  end

  # Unordered list
  def test_tokenize_unordered_list_dash
    tokens, _state = @lexer.tokenize("- List item")

    assert_operator tokens.length, :>=, 1
    assert_equal :operator, tokens[0].type
  end

  def test_tokenize_unordered_list_asterisk
    tokens, _state = @lexer.tokenize("* List item")

    assert_operator tokens.length, :>=, 1
    assert_equal :operator, tokens[0].type
  end

  # Ordered list
  def test_tokenize_ordered_list
    tokens, _state = @lexer.tokenize("1. First item")

    assert_operator tokens.length, :>=, 1
    assert_equal :number, tokens[0].type
  end

  # Horizontal rule
  def test_tokenize_horizontal_rule_dashes
    tokens, _state = @lexer.tokenize("---")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
  end

  def test_tokenize_horizontal_rule_asterisks
    tokens, _state = @lexer.tokenize("***")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
  end

  # Code fence (multiline)
  def test_code_fence_start
    tokens, state = @lexer.tokenize("```ruby")

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal :code_fence, state
  end

  def test_code_fence_middle
    tokens, state = @lexer.tokenize("def hello", :code_fence)

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal :code_fence, state
  end

  def test_code_fence_end
    tokens, state = @lexer.tokenize("```", :code_fence)

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_nil state
  end

  def test_code_fence_full_sequence
    tokens1, state1 = @lexer.tokenize("```python")

    assert_equal :code_fence, state1
    assert_equal :string, tokens1[0].type

    tokens2, state2 = @lexer.tokenize("print('hello')", state1)

    assert_equal :code_fence, state2
    assert_equal :string, tokens2[0].type

    tokens3, state3 = @lexer.tokenize("```", state2)

    assert_nil state3
    assert_equal :string, tokens3[0].type
  end

  # HTML tags
  def test_tokenize_html_tag
    tokens, _state = @lexer.tokenize("<div>content</div>")
    html_tokens = tokens.select { |t| t.type == :preprocessor }

    assert_equal 2, html_tokens.length
    assert_equal "<div>", html_tokens[0].text
    assert_equal "</div>", html_tokens[1].text
  end

  # Edge cases
  def test_tokenize_empty_line
    tokens, state = @lexer.tokenize("")

    assert_empty tokens
    assert_nil state
  end

  def test_tokenize_plain_text
    tokens, state = @lexer.tokenize("Plain text without any markdown")
    # Should not have any special tokens for plain text
    assert_empty tokens
    assert_nil state
  end

  def test_tokenize_whitespace_only
    tokens, state = @lexer.tokenize("   ")

    assert_empty tokens
    assert_nil state
  end
end
