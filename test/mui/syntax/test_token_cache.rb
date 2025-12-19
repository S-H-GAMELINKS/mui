# frozen_string_literal: true

require "test_helper"

class TestTokenCache < Minitest::Test
  # Simple lexer for testing
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

  # Lexer with multiline state for testing
  class MultilineLexer < Mui::Syntax::LexerBase
    protected

    def token_patterns
      [
        [:keyword, /\b(if|else|end)\b/],
        [:identifier, /\b[a-z_][a-z0-9_]*\b/]
      ]
    end

    def check_multiline_start(line, pos)
      if line[pos..].start_with?("/*")
        token = Mui::Syntax::Token.new(
          type: :comment,
          start_col: pos,
          end_col: line.length - 1,
          text: line[pos..]
        )
        [:block_comment, token, line.length]
      else
        [nil, nil, pos]
      end
    end

    def handle_multiline_state(line, pos, state)
      return [nil, nil, pos] unless state == :block_comment

      end_pos = line.index("*/", pos)
      if end_pos
        text = line[pos..(end_pos + 1)]
        token = Mui::Syntax::Token.new(
          type: :comment,
          start_col: pos,
          end_col: end_pos + 1,
          text:
        )
        [token, nil, end_pos + 2]
      else
        text = line[pos..]
        unless text.empty?
          token = Mui::Syntax::Token.new(
            type: :comment,
            start_col: pos,
            end_col: line.length - 1,
            text:
          )
        end
        [token, :block_comment, line.length]
      end
    end
  end

  def setup
    @lexer = SimpleLexer.new
    @cache = Mui::Syntax::TokenCache.new(@lexer)
  end

  def test_tokens_for_returns_tokens
    buffer_lines = ["if x end"]
    tokens = @cache.tokens_for(0, buffer_lines[0], buffer_lines)

    assert_equal 3, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal :identifier, tokens[1].type
    assert_equal :keyword, tokens[2].type
  end

  def test_caches_results
    buffer_lines = ["if x end"]

    tokens1 = @cache.tokens_for(0, buffer_lines[0], buffer_lines)
    tokens2 = @cache.tokens_for(0, buffer_lines[0], buffer_lines)

    assert_same tokens1, tokens2
    assert @cache.cached?(0)
  end

  def test_invalidate_clears_from_row
    buffer_lines = %w[if else end]

    @cache.tokens_for(0, buffer_lines[0], buffer_lines)
    @cache.tokens_for(1, buffer_lines[1], buffer_lines)
    @cache.tokens_for(2, buffer_lines[2], buffer_lines)

    assert @cache.cached?(0)
    assert @cache.cached?(1)
    assert @cache.cached?(2)

    @cache.invalidate(1)

    assert @cache.cached?(0)
    refute @cache.cached?(1)
    refute @cache.cached?(2)
  end

  def test_clear_removes_all_cache
    buffer_lines = %w[if else]

    @cache.tokens_for(0, buffer_lines[0], buffer_lines)
    @cache.tokens_for(1, buffer_lines[1], buffer_lines)

    @cache.clear

    refute @cache.cached?(0)
    refute @cache.cached?(1)
  end

  def test_recomputes_when_line_changes
    buffer_lines = ["if x"]

    tokens1 = @cache.tokens_for(0, buffer_lines[0], buffer_lines)

    assert_equal 2, tokens1.length

    # Change the line
    buffer_lines[0] = "if x end"
    tokens2 = @cache.tokens_for(0, buffer_lines[0], buffer_lines)

    refute_same tokens1, tokens2
    assert_equal 3, tokens2.length
  end

  def test_multiline_state_propagation
    lexer = MultilineLexer.new
    cache = Mui::Syntax::TokenCache.new(lexer)

    buffer_lines = [
      "/* start",
      "middle",
      "end */"
    ]

    tokens0 = cache.tokens_for(0, buffer_lines[0], buffer_lines)

    assert_equal 1, tokens0.length
    assert_equal :comment, tokens0[0].type

    tokens1 = cache.tokens_for(1, buffer_lines[1], buffer_lines)

    assert_equal 1, tokens1.length
    assert_equal :comment, tokens1[0].type

    tokens2 = cache.tokens_for(2, buffer_lines[2], buffer_lines)

    assert_equal 1, tokens2.length
    assert_equal :comment, tokens2[0].type
  end

  def test_cached_returns_false_for_uncached_row
    refute @cache.cached?(0)
  end

  def test_cached_returns_true_for_cached_row
    buffer_lines = ["if"]
    @cache.tokens_for(0, buffer_lines[0], buffer_lines)

    assert @cache.cached?(0)
  end

  def test_handles_empty_buffer
    buffer_lines = []
    tokens = @cache.tokens_for(0, "", buffer_lines)

    assert_empty tokens
  end

  def test_handles_multiple_lines
    buffer_lines = ["if x", "else y", "end"]

    buffer_lines.each_with_index do |line, row|
      @cache.tokens_for(row, line, buffer_lines)
    end

    assert @cache.cached?(0)
    assert @cache.cached?(1)
    assert @cache.cached?(2)
  end
end
