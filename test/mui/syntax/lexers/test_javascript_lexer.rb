# frozen_string_literal: true

require "test_helper"

class TestJavaScriptLexer < Minitest::Test
  def setup
    @lexer = Mui::Syntax::Lexers::JavaScriptLexer.new
  end

  # Keywords
  def test_tokenize_keywords
    %w[function const let var class if else for while return async await import export].each do |keyword|
      tokens, _state = @lexer.tokenize(keyword)

      assert_equal 1, tokens.length, "Expected 1 token for '#{keyword}'"
      assert_equal :keyword, tokens[0].type, "Expected :keyword for '#{keyword}'"
      assert_equal keyword, tokens[0].text
    end
  end

  # Constants
  def test_tokenize_constants
    %w[true false null undefined NaN Infinity this super].each do |constant|
      tokens, _state = @lexer.tokenize(constant)

      assert_equal 1, tokens.length, "Expected 1 token for '#{constant}'"
      assert_equal :constant, tokens[0].type, "Expected :constant for '#{constant}'"
      assert_equal constant, tokens[0].text
    end
  end

  # Class names (uppercase start)
  def test_tokenize_class_names
    %w[Array Object String Promise Map Set].each do |class_name|
      tokens, _state = @lexer.tokenize(class_name)

      assert_equal 1, tokens.length, "Expected 1 token for '#{class_name}'"
      assert_equal :constant, tokens[0].type, "Expected :constant for '#{class_name}'"
      assert_equal class_name, tokens[0].text
    end
  end

  # Strings
  def test_tokenize_double_quoted_string
    tokens, _state = @lexer.tokenize('"hello world"')

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal '"hello world"', tokens[0].text
  end

  def test_tokenize_single_quoted_string
    tokens, _state = @lexer.tokenize("'hello world'")

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal "'hello world'", tokens[0].text
  end

  def test_tokenize_string_with_escape
    tokens, _state = @lexer.tokenize('"hello\\nworld"')

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
  end

  def test_tokenize_template_literal
    tokens, _state = @lexer.tokenize("`template string`")

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal "`template string`", tokens[0].text
  end

  # Regular expressions
  def test_tokenize_regex
    tokens, _state = @lexer.tokenize("/pattern/")

    assert_equal 1, tokens.length
    assert_equal :regex, tokens[0].type
    assert_equal "/pattern/", tokens[0].text
  end

  def test_tokenize_regex_with_flags
    tokens, _state = @lexer.tokenize("/pattern/gi")

    assert_equal 1, tokens.length
    assert_equal :regex, tokens[0].type
    assert_equal "/pattern/gi", tokens[0].text
  end

  def test_tokenize_regex_with_escape
    tokens, _state = @lexer.tokenize('/hello\\/world/')

    assert_equal 1, tokens.length
    assert_equal :regex, tokens[0].type
  end

  # Comments
  def test_tokenize_single_line_comment
    tokens, _state = @lexer.tokenize("// this is a comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "// this is a comment", tokens[0].text
  end

  def test_tokenize_code_with_comment
    tokens, _state = @lexer.tokenize("const x = 1 // declare x")
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
    tokens, _state = @lexer.tokenize("const /* type */ x = 5")
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

  def test_tokenize_bigint
    tokens, _state = @lexer.tokenize("42n")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
    assert_equal "42n", tokens[0].text
  end

  def test_tokenize_float
    tokens, _state = @lexer.tokenize("3.14")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  def test_tokenize_float_with_exponent
    tokens, _state = @lexer.tokenize("1.5e10")

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

  def test_tokenize_identifier_with_dollar
    tokens, _state = @lexer.tokenize("$element")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
  end

  # Operators
  def test_tokenize_operators
    tokens, _state = @lexer.tokenize("+ - * / % == != < > <= >=")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert_operator operator_tokens.length, :>=, 5
  end

  def test_tokenize_strict_equality
    tokens, _state = @lexer.tokenize("a === b")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("===") })
  end

  def test_tokenize_strict_inequality
    tokens, _state = @lexer.tokenize("a !== b")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("!==") })
  end

  def test_tokenize_arrow_function
    tokens, _state = @lexer.tokenize("x => x + 1")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("=>") })
  end

  def test_tokenize_spread_operator
    tokens, _state = @lexer.tokenize("...args")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("...") })
  end

  def test_tokenize_optional_chaining
    tokens, _state = @lexer.tokenize("obj?.prop")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("?.") })
  end

  def test_tokenize_nullish_coalescing
    tokens, _state = @lexer.tokenize("a ?? b")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("??") })
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

  # Template literals (multiline)
  def test_template_literal_multiline_start
    tokens, state = @lexer.tokenize("`start of template")

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal :template_literal, state
  end

  def test_template_literal_multiline_middle
    tokens, state = @lexer.tokenize("  middle of template  ", :template_literal)

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal :template_literal, state
  end

  def test_template_literal_multiline_end
    tokens, state = @lexer.tokenize("end of template`", :template_literal)

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_nil state
  end

  def test_template_literal_full_sequence
    tokens1, state1 = @lexer.tokenize("`SELECT")

    assert_equal :template_literal, state1
    assert_equal :string, tokens1[0].type

    tokens2, state2 = @lexer.tokenize("FROM users", state1)

    assert_equal :template_literal, state2
    assert_equal :string, tokens2[0].type

    tokens3, state3 = @lexer.tokenize("WHERE id = ?`", state2)

    assert_nil state3
    assert_equal :string, tokens3[0].type
  end

  # Function definitions
  def test_tokenize_function_definition
    tokens, _state = @lexer.tokenize("function hello")

    assert_equal 2, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "function", tokens[0].text
    assert_equal :function_definition, tokens[1].type
    assert_equal "hello", tokens[1].text
  end

  def test_tokenize_function_definition_with_parens
    tokens, _state = @lexer.tokenize("function main()")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "main", func_tokens[0].text
  end

  def test_tokenize_function_definition_with_args
    tokens, _state = @lexer.tokenize("function add(a, b)")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "add", func_tokens[0].text
  end

  def test_tokenize_async_function_definition
    # async function fetchData()
    tokens, _state = @lexer.tokenize("async function fetchData()")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "fetchData", func_tokens[0].text
  end

  def test_tokenize_function_expression
    # const foo = function bar()
    # Note: 'bar' is a named function expression, should be function_definition
    tokens, _state = @lexer.tokenize("const foo = function bar()")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "bar", func_tokens[0].text
  end

  # Complex examples
  def test_tokenize_function_declaration
    tokens, _state = @lexer.tokenize("function main() {")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :function_definition
  end

  def test_tokenize_const_declaration
    tokens, _state = @lexer.tokenize("const count = 0")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :identifier
    assert_includes types, :number
  end

  def test_tokenize_class_definition
    tokens, _state = @lexer.tokenize("class Point {")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :constant
  end

  def test_tokenize_import_statement
    tokens, _state = @lexer.tokenize('import { foo } from "module"')
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :string
  end

  def test_tokenize_arrow_function_definition
    tokens, _state = @lexer.tokenize("const add = (a, b) => a + b")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :identifier
    assert_includes types, :operator
  end

  def test_tokenize_async_function
    tokens, _state = @lexer.tokenize("async function fetchData() {")
    keyword_tokens = tokens.select { |t| t.type == :keyword }
    texts = keyword_tokens.map(&:text)

    assert_includes texts, "async"
    assert_includes texts, "function"
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
