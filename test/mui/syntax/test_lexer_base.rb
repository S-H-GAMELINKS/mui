# frozen_string_literal: true

require "test_helper"

class TestLexerBase < Minitest::Test
  # Test subclass with simple patterns
  class SimpleLexer < Mui::Syntax::LexerBase
    protected

    def token_patterns
      [
        [:keyword, /\b(if|else|end)\b/],
        [:number, /\b\d+\b/],
        [:identifier, /\b[a-z_][a-z0-9_]*\b/]
      ]
    end
  end

  def setup
    @lexer = SimpleLexer.new
  end

  def test_tokenize_empty_line
    tokens, state = @lexer.tokenize("")

    assert_empty tokens
    assert_nil state
  end

  def test_tokenize_single_keyword
    tokens, state = @lexer.tokenize("if")

    assert_equal 1, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "if", tokens[0].text
    assert_equal 0, tokens[0].start_col
    assert_equal 1, tokens[0].end_col
    assert_nil state
  end

  def test_tokenize_single_number
    tokens, _state = @lexer.tokenize("42")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
    assert_equal "42", tokens[0].text
  end

  def test_tokenize_single_identifier
    tokens, _state = @lexer.tokenize("foo")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
    assert_equal "foo", tokens[0].text
  end

  def test_tokenize_multiple_tokens
    tokens, _state = @lexer.tokenize("if x end")

    assert_equal 3, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "if", tokens[0].text
    assert_equal 0, tokens[0].start_col

    assert_equal :identifier, tokens[1].type
    assert_equal "x", tokens[1].text
    assert_equal 3, tokens[1].start_col

    assert_equal :keyword, tokens[2].type
    assert_equal "end", tokens[2].text
    assert_equal 5, tokens[2].start_col
  end

  def test_tokenize_with_leading_whitespace
    tokens, _state = @lexer.tokenize("  if")

    assert_equal 1, tokens.length
    assert_equal 2, tokens[0].start_col
  end

  def test_tokenize_skips_unrecognized_chars
    tokens, _state = @lexer.tokenize("if + else")

    assert_equal 2, tokens.length
    assert_equal "if", tokens[0].text
    assert_equal "else", tokens[1].text
  end

  def test_continuing_state_with_nil
    refute @lexer.continuing_state?(nil)
  end

  def test_continuing_state_with_symbol
    assert @lexer.continuing_state?(:block_comment)
  end
end
