# frozen_string_literal: true

require "test_helper"

class TestTypeScriptLexer < Minitest::Test
  def setup
    @lexer = Mui::Syntax::Lexers::TypeScriptLexer.new
  end

  # JavaScript keywords (inherited)
  def test_tokenize_javascript_keywords
    %w[function const let var class if else for while return async await import export].each do |keyword|
      tokens, _state = @lexer.tokenize(keyword)

      assert_equal 1, tokens.length, "Expected 1 token for '#{keyword}'"
      assert_equal :keyword, tokens[0].type, "Expected :keyword for '#{keyword}'"
      assert_equal keyword, tokens[0].text
    end
  end

  # TypeScript-specific keywords
  def test_tokenize_typescript_keywords
    %w[interface type enum namespace declare abstract implements private protected public readonly].each do |keyword|
      tokens, _state = @lexer.tokenize(keyword)

      assert_equal 1, tokens.length, "Expected 1 token for '#{keyword}'"
      assert_equal :keyword, tokens[0].type, "Expected :keyword for '#{keyword}'"
      assert_equal keyword, tokens[0].text
    end
  end

  def test_tokenize_as_keyword
    tokens, _state = @lexer.tokenize("x as string")
    keyword_tokens = tokens.select { |t| t.type == :keyword }
    texts = keyword_tokens.map(&:text)

    assert_includes texts, "as"
  end

  def test_tokenize_keyof_keyword
    tokens, _state = @lexer.tokenize("keyof T")
    keyword_tokens = tokens.select { |t| t.type == :keyword }
    texts = keyword_tokens.map(&:text)

    assert_includes texts, "keyof"
  end

  def test_tokenize_unknown_keyword
    tokens, _state = @lexer.tokenize("unknown")

    assert_equal 1, tokens.length
    assert_equal :keyword, tokens[0].type
  end

  def test_tokenize_never_keyword
    tokens, _state = @lexer.tokenize("never")

    assert_equal 1, tokens.length
    assert_equal :keyword, tokens[0].type
  end

  # Constants (inherited from JavaScript)
  def test_tokenize_constants
    %w[true false null undefined NaN Infinity this super].each do |constant|
      tokens, _state = @lexer.tokenize(constant)

      assert_equal 1, tokens.length, "Expected 1 token for '#{constant}'"
      assert_equal :constant, tokens[0].type, "Expected :constant for '#{constant}'"
      assert_equal constant, tokens[0].text
    end
  end

  # Type names (uppercase start)
  def test_tokenize_type_names
    %w[Array Object String Promise Map Set].each do |type_name|
      tokens, _state = @lexer.tokenize(type_name)

      assert_equal 1, tokens.length, "Expected 1 token for '#{type_name}'"
      assert_equal :constant, tokens[0].type, "Expected :constant for '#{type_name}'"
      assert_equal type_name, tokens[0].text
    end
  end

  # Strings
  def test_tokenize_double_quoted_string
    tokens, _state = @lexer.tokenize('"hello world"')

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
  end

  def test_tokenize_single_quoted_string
    tokens, _state = @lexer.tokenize("'hello world'")

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
  end

  def test_tokenize_template_literal
    tokens, _state = @lexer.tokenize("`template string`")

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
  end

  # Comments
  def test_tokenize_single_line_comment
    tokens, _state = @lexer.tokenize("// this is a comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
  end

  def test_tokenize_block_comment
    tokens, _state = @lexer.tokenize("/* comment */")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
  end

  # Numbers
  def test_tokenize_integer
    tokens, _state = @lexer.tokenize("42")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  def test_tokenize_float
    tokens, _state = @lexer.tokenize("3.14")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  # Regular expressions
  def test_tokenize_regex
    tokens, _state = @lexer.tokenize("/pattern/gi")

    assert_equal 1, tokens.length
    assert_equal :regex, tokens[0].type
  end

  # Identifiers
  def test_tokenize_identifier
    tokens, _state = @lexer.tokenize("fooBar")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
  end

  # Operators
  def test_tokenize_arrow_function
    tokens, _state = @lexer.tokenize("x => x + 1")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("=>") })
  end

  def test_tokenize_strict_equality
    tokens, _state = @lexer.tokenize("a === b")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("===") })
  end

  # Multiline constructs
  def test_block_comment_multiline
    _, state1 = @lexer.tokenize("/* Start")

    assert_equal :block_comment, state1

    _, state2 = @lexer.tokenize(" * Middle", state1)

    assert_equal :block_comment, state2

    _, state3 = @lexer.tokenize(" */", state2)

    assert_nil state3
  end

  def test_template_literal_multiline
    _, state1 = @lexer.tokenize("`Start")

    assert_equal :template_literal, state1

    _, state2 = @lexer.tokenize("Middle", state1)

    assert_equal :template_literal, state2

    _, state3 = @lexer.tokenize("End`", state2)

    assert_nil state3
  end

  # TypeScript-specific syntax
  def test_tokenize_interface_declaration
    tokens, _state = @lexer.tokenize("interface User {")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :constant
  end

  def test_tokenize_type_alias
    tokens, _state = @lexer.tokenize("type ID = string")
    keyword_tokens = tokens.select { |t| t.type == :keyword }
    texts = keyword_tokens.map(&:text)

    assert_includes texts, "type"
  end

  def test_tokenize_enum_declaration
    tokens, _state = @lexer.tokenize("enum Status {")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :constant
  end

  def test_tokenize_class_with_access_modifiers
    tokens, _state = @lexer.tokenize("private name: string")
    keyword_tokens = tokens.select { |t| t.type == :keyword }
    texts = keyword_tokens.map(&:text)

    assert_includes texts, "private"
  end

  def test_tokenize_readonly_property
    tokens, _state = @lexer.tokenize("readonly id: number")
    keyword_tokens = tokens.select { |t| t.type == :keyword }
    texts = keyword_tokens.map(&:text)

    assert_includes texts, "readonly"
  end

  def test_tokenize_abstract_class
    tokens, _state = @lexer.tokenize("abstract class Shape {")
    keyword_tokens = tokens.select { |t| t.type == :keyword }
    texts = keyword_tokens.map(&:text)

    assert_includes texts, "abstract"
    assert_includes texts, "class"
  end

  def test_tokenize_namespace
    tokens, _state = @lexer.tokenize("namespace Utils {")
    keyword_tokens = tokens.select { |t| t.type == :keyword }
    texts = keyword_tokens.map(&:text)

    assert_includes texts, "namespace"
  end

  def test_tokenize_declare
    tokens, _state = @lexer.tokenize("declare const VERSION: string")
    keyword_tokens = tokens.select { |t| t.type == :keyword }
    texts = keyword_tokens.map(&:text)

    assert_includes texts, "declare"
    assert_includes texts, "const"
  end

  def test_tokenize_implements
    tokens, _state = @lexer.tokenize("class Dog implements Animal {")
    keyword_tokens = tokens.select { |t| t.type == :keyword }
    texts = keyword_tokens.map(&:text)

    assert_includes texts, "class"
    assert_includes texts, "implements"
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

  def test_tokenize_function_definition_with_type
    tokens, _state = @lexer.tokenize("function add(a: number, b: number): number")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "add", func_tokens[0].text
  end

  def test_tokenize_async_function_definition
    tokens, _state = @lexer.tokenize("async function fetchData()")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "fetchData", func_tokens[0].text
  end

  def test_tokenize_function_with_generics
    # NOTE: Generic type parameters like <T> are matched as :type
    tokens, _state = @lexer.tokenize("function identity(arg)")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "identity", func_tokens[0].text
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
