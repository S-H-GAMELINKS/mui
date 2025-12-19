# frozen_string_literal: true

require "test_helper"

class TestGoLexer < Minitest::Test
  def setup
    @lexer = Mui::Syntax::Lexers::GoLexer.new
  end

  # Keywords
  def test_tokenize_keywords
    %w[func package import go defer chan select return if else for range switch case default break continue].each do |keyword|
      tokens, _state = @lexer.tokenize(keyword)

      assert_equal 1, tokens.length, "Expected 1 token for '#{keyword}'"
      assert_equal :keyword, tokens[0].type, "Expected :keyword for '#{keyword}'"
      assert_equal keyword, tokens[0].text
    end
  end

  # Type keywords
  def test_tokenize_type_keywords
    %w[int int8 int16 int32 int64 uint uint8 uint16 uint32 uint64 float32 float64 string bool byte rune error].each do |keyword|
      tokens, _state = @lexer.tokenize(keyword)

      assert_equal 1, tokens.length, "Expected 1 token for '#{keyword}'"
      assert_equal :type, tokens[0].type, "Expected :type for '#{keyword}'"
      assert_equal keyword, tokens[0].text
    end
  end

  # Constants
  def test_tokenize_constants
    %w[true false nil iota].each do |constant|
      tokens, _state = @lexer.tokenize(constant)

      assert_equal 1, tokens.length, "Expected 1 token for '#{constant}'"
      assert_equal :constant, tokens[0].type, "Expected :constant for '#{constant}'"
      assert_equal constant, tokens[0].text
    end
  end

  # Exported identifiers (uppercase)
  def test_tokenize_exported_identifier
    tokens, _state = @lexer.tokenize("Printf")

    assert_equal 1, tokens.length
    assert_equal :constant, tokens[0].type
    assert_equal "Printf", tokens[0].text
  end

  # Strings
  def test_tokenize_string
    tokens, _state = @lexer.tokenize('"hello world"')

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal '"hello world"', tokens[0].text
  end

  def test_tokenize_string_with_escape
    tokens, _state = @lexer.tokenize('"hello\\nworld"')

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
  end

  def test_tokenize_raw_string
    tokens, _state = @lexer.tokenize("`raw string`")

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal "`raw string`", tokens[0].text
  end

  # Character literals (runes)
  def test_tokenize_rune
    tokens, _state = @lexer.tokenize("'a'")

    assert_equal 1, tokens.length
    assert_equal :char, tokens[0].type
    assert_equal "'a'", tokens[0].text
  end

  def test_tokenize_escaped_rune
    tokens, _state = @lexer.tokenize("'\\n'")

    assert_equal 1, tokens.length
    assert_equal :char, tokens[0].type
  end

  # Comments
  def test_tokenize_single_line_comment
    tokens, _state = @lexer.tokenize("// this is a comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "// this is a comment", tokens[0].text
  end

  def test_tokenize_code_with_comment
    tokens, _state = @lexer.tokenize("var x int // declare x")
    comment_tokens = tokens.select { |t| t.type == :comment }

    assert_equal 1, comment_tokens.length
  end

  def test_tokenize_single_line_block_comment
    tokens, _state = @lexer.tokenize("/* comment */")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "/* comment */", tokens[0].text
  end

  def test_tokenize_inline_block_comment
    tokens, _state = @lexer.tokenize("var /* type */ x int")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :comment
    assert_includes types, :identifier
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
  end

  def test_tokenize_hexadecimal
    tokens, _state = @lexer.tokenize("0xFF")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
    assert_equal "0xFF", tokens[0].text
  end

  def test_tokenize_octal
    tokens, _state = @lexer.tokenize("0o755")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  def test_tokenize_binary
    tokens, _state = @lexer.tokenize("0b1010")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  # Identifiers
  def test_tokenize_identifier
    tokens, _state = @lexer.tokenize("fooBar")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
    assert_equal "fooBar", tokens[0].text
  end

  def test_tokenize_identifier_with_underscore
    tokens, _state = @lexer.tokenize("_private")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
  end

  # Operators
  def test_tokenize_operators
    tokens, _state = @lexer.tokenize("+ - * / % == != < > <= >=")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert_operator operator_tokens.length, :>=, 5
  end

  def test_tokenize_channel_operator
    tokens, _state = @lexer.tokenize("ch <- value")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("<-") })
  end

  def test_tokenize_short_declaration
    tokens, _state = @lexer.tokenize("x := 10")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?(":=") })
  end

  # Block comments (multiline)
  def test_block_comment_start
    tokens, state = @lexer.tokenize("/* start of comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal :block_comment, state
  end

  def test_block_comment_middle
    tokens, state = @lexer.tokenize("  middle of comment  ", :block_comment)

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal :block_comment, state
  end

  def test_block_comment_end
    tokens, state = @lexer.tokenize("end of comment */", :block_comment)

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_nil state
  end

  def test_block_comment_full_sequence
    tokens1, state1 = @lexer.tokenize("/* Start")

    assert_equal :block_comment, state1
    assert_equal :comment, tokens1[0].type

    tokens2, state2 = @lexer.tokenize(" * Middle", state1)

    assert_equal :block_comment, state2
    assert_equal :comment, tokens2[0].type

    tokens3, state3 = @lexer.tokenize(" */", state2)

    assert_nil state3
    assert_equal :comment, tokens3[0].type
  end

  # Raw strings (multiline)
  def test_raw_string_multiline_start
    tokens, state = @lexer.tokenize("`start of raw string")

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal :raw_string, state
  end

  def test_raw_string_multiline_middle
    tokens, state = @lexer.tokenize("  middle of raw string  ", :raw_string)

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal :raw_string, state
  end

  def test_raw_string_multiline_end
    tokens, state = @lexer.tokenize("end of raw string`", :raw_string)

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_nil state
  end

  def test_raw_string_full_sequence
    tokens1, state1 = @lexer.tokenize("`SELECT")

    assert_equal :raw_string, state1
    assert_equal :string, tokens1[0].type

    tokens2, state2 = @lexer.tokenize("FROM users", state1)

    assert_equal :raw_string, state2
    assert_equal :string, tokens2[0].type

    tokens3, state3 = @lexer.tokenize("WHERE id = ?`", state2)

    assert_nil state3
    assert_equal :string, tokens3[0].type
  end

  # Function definitions
  def test_tokenize_function_definition
    tokens, _state = @lexer.tokenize("func main")

    assert_equal 2, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "func", tokens[0].text
    assert_equal :function_definition, tokens[1].type
    assert_equal "main", tokens[1].text
  end

  def test_tokenize_function_definition_with_parens
    tokens, _state = @lexer.tokenize("func hello()")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "hello", func_tokens[0].text
  end

  def test_tokenize_function_definition_with_receiver
    # Method with receiver: func (p *Point) String() string
    tokens, _state = @lexer.tokenize("func (p *Point) String() string")
    # NOTE: String is exported so it's a constant, not function_definition
    # This is expected behavior since Go's exported functions start with uppercase
    types = tokens.map(&:type)

    assert_includes types, :keyword  # func
    assert_includes types, :constant # Point, String
  end

  def test_tokenize_unexported_method
    tokens, _state = @lexer.tokenize("func (p *point) format()")
    # NOTE: Methods with receivers are not highlighted as function_definition
    # because lookbehind only works for "func " directly followed by name
    # This is acceptable since method names are less common than top-level funcs
    identifiers = tokens.select { |t| t.type == :identifier }

    assert(identifiers.any? { |t| t.text == "format" })
  end

  # Complex examples
  def test_tokenize_function_declaration
    tokens, _state = @lexer.tokenize("func main() {")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :function_definition
  end

  def test_tokenize_variable_declaration
    tokens, _state = @lexer.tokenize("var count int = 0")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :identifier
    assert_includes types, :type
    assert_includes types, :number
  end

  def test_tokenize_struct_definition
    tokens, _state = @lexer.tokenize("type Point struct {")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :constant # Point is exported
  end

  def test_tokenize_import_statement
    tokens, _state = @lexer.tokenize('import "fmt"')
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :string
  end

  def test_tokenize_package_statement
    tokens, _state = @lexer.tokenize("package main")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :identifier
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
