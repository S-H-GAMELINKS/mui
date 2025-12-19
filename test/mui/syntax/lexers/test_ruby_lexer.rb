# frozen_string_literal: true

require "test_helper"

class TestRubyLexer < Minitest::Test
  def setup
    @lexer = Mui::Syntax::Lexers::RubyLexer.new
  end

  # Keywords
  def test_tokenize_keywords
    %w[def class module if else end while do return].each do |keyword|
      tokens, _state = @lexer.tokenize(keyword)

      assert_equal 1, tokens.length, "Expected 1 token for '#{keyword}'"
      assert_equal :keyword, tokens[0].type, "Expected :keyword for '#{keyword}'"
      assert_equal keyword, tokens[0].text
    end
  end

  def test_tokenize_require
    tokens, _state = @lexer.tokenize("require 'foo'")

    assert_equal 2, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "require", tokens[0].text
    assert_equal :string, tokens[1].type
  end

  # Strings
  def test_tokenize_double_quoted_string
    tokens, _state = @lexer.tokenize('"hello world"')

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal '"hello world"', tokens[0].text
  end

  def test_tokenize_single_quoted_string
    tokens, _state = @lexer.tokenize("'hello'")

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal "'hello'", tokens[0].text
  end

  def test_tokenize_string_with_escape
    tokens, _state = @lexer.tokenize('"hello\\nworld"')

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal '"hello\\nworld"', tokens[0].text
  end

  def test_tokenize_string_with_escaped_quote
    tokens, _state = @lexer.tokenize('"say \\"hello\\""')

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
  end

  # Comments
  def test_tokenize_line_comment
    tokens, _state = @lexer.tokenize("# this is a comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "# this is a comment", tokens[0].text
  end

  def test_tokenize_code_with_comment
    tokens, _state = @lexer.tokenize("x = 1 # assign")
    # x, =, 1, # assign
    assert_equal 4, tokens.length
    assert_equal :identifier, tokens[0].type
    assert_equal :operator, tokens[1].type
    assert_equal :number, tokens[2].type
    assert_equal :comment, tokens[3].type
  end

  # Numbers
  def test_tokenize_integer
    tokens, _state = @lexer.tokenize("42")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
    assert_equal "42", tokens[0].text
  end

  def test_tokenize_float
    tokens, _state = @lexer.tokenize("3.14")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
    assert_equal "3.14", tokens[0].text
  end

  def test_tokenize_hexadecimal
    tokens, _state = @lexer.tokenize("0xFF")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
    assert_equal "0xFF", tokens[0].text
  end

  def test_tokenize_binary
    tokens, _state = @lexer.tokenize("0b1010")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  def test_tokenize_octal
    tokens, _state = @lexer.tokenize("0o755")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  # Symbols
  def test_tokenize_symbol
    tokens, _state = @lexer.tokenize(":foo")

    assert_equal 1, tokens.length
    assert_equal :symbol, tokens[0].type
    assert_equal ":foo", tokens[0].text
  end

  def test_tokenize_symbol_with_question_mark
    tokens, _state = @lexer.tokenize(":empty?")

    assert_equal 1, tokens.length
    assert_equal :symbol, tokens[0].type
    assert_equal ":empty?", tokens[0].text
  end

  # Constants
  def test_tokenize_constant
    tokens, _state = @lexer.tokenize("MyClass")

    assert_equal 1, tokens.length
    assert_equal :constant, tokens[0].type
    assert_equal "MyClass", tokens[0].text
  end

  def test_tokenize_all_caps_constant
    tokens, _state = @lexer.tokenize("MAX_VALUE")

    assert_equal 1, tokens.length
    assert_equal :constant, tokens[0].type
  end

  # Identifiers
  def test_tokenize_identifier
    tokens, _state = @lexer.tokenize("foo_bar")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
    assert_equal "foo_bar", tokens[0].text
  end

  def test_tokenize_method_with_question_mark
    tokens, _state = @lexer.tokenize("empty?")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
    assert_equal "empty?", tokens[0].text
  end

  def test_tokenize_method_with_bang
    tokens, _state = @lexer.tokenize("save!")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
    assert_equal "save!", tokens[0].text
  end

  def test_tokenize_instance_variable
    tokens, _state = @lexer.tokenize("@foo")

    assert_equal 1, tokens.length
    assert_equal :instance_variable, tokens[0].type
    assert_equal "@foo", tokens[0].text
  end

  def test_tokenize_class_variable
    tokens, _state = @lexer.tokenize("@@counter")

    assert_equal 1, tokens.length
    assert_equal :instance_variable, tokens[0].type
    assert_equal "@@counter", tokens[0].text
  end

  def test_tokenize_global_variable
    tokens, _state = @lexer.tokenize("$stdout")

    assert_equal 1, tokens.length
    assert_equal :global_variable, tokens[0].type
    assert_equal "$stdout", tokens[0].text
  end

  # Operators
  def test_tokenize_operators
    tokens, _state = @lexer.tokenize("+ - * / % == != < > <= >=")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert_operator operator_tokens.length, :>=, 5
  end

  # Block comments
  def test_tokenize_block_comment_start
    tokens, state = @lexer.tokenize("=begin")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal :block_comment, state
  end

  def test_tokenize_block_comment_middle
    tokens, state = @lexer.tokenize("  this is inside comment", :block_comment)

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal :block_comment, state
  end

  def test_tokenize_block_comment_end
    tokens, state = @lexer.tokenize("=end", :block_comment)

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_nil state
  end

  def test_block_comment_full_sequence
    lexer = @lexer

    tokens1, state1 = lexer.tokenize("=begin")

    assert_equal :block_comment, state1
    assert_equal :comment, tokens1[0].type

    tokens2, state2 = lexer.tokenize("This is a comment", state1)

    assert_equal :block_comment, state2
    assert_equal :comment, tokens2[0].type

    tokens3, state3 = lexer.tokenize("=end", state2)

    assert_nil state3
    assert_equal :comment, tokens3[0].type
  end

  # Function definitions
  def test_tokenize_function_definition
    tokens, _state = @lexer.tokenize("def hello")

    assert_equal 2, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "def", tokens[0].text
    assert_equal :function_definition, tokens[1].type
    assert_equal "hello", tokens[1].text
  end

  def test_tokenize_function_definition_with_question_mark
    tokens, _state = @lexer.tokenize("def empty?")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "empty?", func_tokens[0].text
  end

  def test_tokenize_function_definition_with_bang
    tokens, _state = @lexer.tokenize("def save!")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "save!", func_tokens[0].text
  end

  def test_tokenize_function_definition_with_equals
    tokens, _state = @lexer.tokenize("def value=")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "value=", func_tokens[0].text
  end

  def test_tokenize_class_method_definition
    tokens, _state = @lexer.tokenize("def self.create")
    # def, self, .create
    # Note: .create is matched as method_call (includes the dot)
    # Both method_call and function_definition use the same color
    assert_equal 3, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "def", tokens[0].text
    assert_equal :keyword, tokens[1].type
    assert_equal "self", tokens[1].text
    assert_equal :method_call, tokens[2].type
    assert_equal ".create", tokens[2].text
  end

  def test_tokenize_function_definition_with_args
    tokens, _state = @lexer.tokenize("def hello(name)")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "hello", func_tokens[0].text
  end

  # Complex examples
  def test_tokenize_method_definition
    tokens, _state = @lexer.tokenize("def hello(name)")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :function_definition
  end

  def test_tokenize_class_definition
    tokens, _state = @lexer.tokenize("class MyClass < Base")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :constant
  end

  def test_tokenize_method_call
    tokens, _state = @lexer.tokenize('puts "hello"')

    assert_equal 2, tokens.length
    assert_equal :identifier, tokens[0].type
    assert_equal :string, tokens[1].type
  end

  def test_tokenize_hash_with_symbol_keys
    tokens, _state = @lexer.tokenize("{ foo: 1, bar: 2 }")
    # foo and bar are identifiers here (before colon)
    assert(tokens.any? { |t| t.type == :number })
  end

  def test_tokenize_attr_accessor
    tokens, _state = @lexer.tokenize("attr_accessor :name")

    assert_equal 2, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal :symbol, tokens[1].type
  end

  # Edge cases
  def test_tokenize_empty_line
    tokens, state = @lexer.tokenize("")

    assert_empty tokens
    assert_nil state
  end

  def test_tokenize_whitespace_only
    tokens, state = @lexer.tokenize("   ")

    assert_empty tokens
    assert_nil state
  end
end
