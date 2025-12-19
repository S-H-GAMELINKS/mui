# frozen_string_literal: true

require "test_helper"

class TestRustLexer < Minitest::Test
  def setup
    @lexer = Mui::Syntax::Lexers::RustLexer.new
  end

  # Keywords
  def test_tokenize_keywords
    %w[fn let mut impl trait struct enum match async await pub use mod return if else for while loop break continue].each do |keyword|
      tokens, _state = @lexer.tokenize(keyword)

      assert_equal 1, tokens.length, "Expected 1 token for '#{keyword}'"
      assert_equal :keyword, tokens[0].type, "Expected :keyword for '#{keyword}'"
      assert_equal keyword, tokens[0].text
    end
  end

  # Primitive types
  def test_tokenize_primitive_types
    %w[bool char str i8 i16 i32 i64 i128 isize u8 u16 u32 u64 u128 usize f32 f64].each do |type_name|
      tokens, _state = @lexer.tokenize(type_name)

      assert_equal 1, tokens.length, "Expected 1 token for '#{type_name}'"
      assert_equal :type, tokens[0].type, "Expected :type for '#{type_name}'"
      assert_equal type_name, tokens[0].text
    end
  end

  # Type names (uppercase start)
  def test_tokenize_type_names
    %w[String Vec Option Result HashMap].each do |type_name|
      tokens, _state = @lexer.tokenize(type_name)

      assert_equal 1, tokens.length, "Expected 1 token for '#{type_name}'"
      assert_equal :constant, tokens[0].type, "Expected :constant for '#{type_name}'"
      assert_equal type_name, tokens[0].text
    end
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
    tokens, _state = @lexer.tokenize('r#"raw string"#')

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal 'r#"raw string"#', tokens[0].text
  end

  def test_tokenize_byte_string
    tokens, _state = @lexer.tokenize('b"byte string"')

    assert_equal 1, tokens.length
    assert_equal :string, tokens[0].type
    assert_equal 'b"byte string"', tokens[0].text
  end

  # Character literals
  def test_tokenize_char
    tokens, _state = @lexer.tokenize("'a'")

    assert_equal 1, tokens.length
    assert_equal :char, tokens[0].type
    assert_equal "'a'", tokens[0].text
  end

  def test_tokenize_escaped_char
    tokens, _state = @lexer.tokenize("'\\n'")

    assert_equal 1, tokens.length
    assert_equal :char, tokens[0].type
  end

  # Lifetimes
  def test_tokenize_lifetime
    tokens, _state = @lexer.tokenize("'a")

    assert_equal 1, tokens.length
    assert_equal :symbol, tokens[0].type
    assert_equal "'a", tokens[0].text
  end

  def test_tokenize_static_lifetime
    tokens, _state = @lexer.tokenize("'static")

    assert_equal 1, tokens.length
    assert_equal :symbol, tokens[0].type
    assert_equal "'static", tokens[0].text
  end

  def test_tokenize_lifetime_in_context
    tokens, _state = @lexer.tokenize("fn foo<'a>(x: &'a str)")
    lifetime_tokens = tokens.select { |t| t.type == :symbol }

    assert_equal 2, lifetime_tokens.length
  end

  # Macros
  def test_tokenize_macro
    tokens, _state = @lexer.tokenize("println!")

    assert_equal 1, tokens.length
    assert_equal :macro, tokens[0].type
    assert_equal "println!", tokens[0].text
  end

  def test_tokenize_vec_macro
    tokens, _state = @lexer.tokenize("vec!")

    assert_equal 1, tokens.length
    assert_equal :macro, tokens[0].type
  end

  def test_tokenize_format_macro
    tokens, _state = @lexer.tokenize("format!")

    assert_equal 1, tokens.length
    assert_equal :macro, tokens[0].type
  end

  # Attributes
  def test_tokenize_attribute
    tokens, _state = @lexer.tokenize("#[derive(Debug)]")

    assert_equal 1, tokens.length
    assert_equal :preprocessor, tokens[0].type
    assert_equal "#[derive(Debug)]", tokens[0].text
  end

  def test_tokenize_inner_attribute
    tokens, _state = @lexer.tokenize("#![allow(unused)]")

    assert_equal 1, tokens.length
    assert_equal :preprocessor, tokens[0].type
  end

  # Comments
  def test_tokenize_single_line_comment
    tokens, _state = @lexer.tokenize("// this is a comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "// this is a comment", tokens[0].text
  end

  def test_tokenize_doc_comment
    tokens, _state = @lexer.tokenize("/// This is a doc comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "/// This is a doc comment", tokens[0].text
  end

  def test_tokenize_inner_doc_comment
    tokens, _state = @lexer.tokenize("//! Module doc comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
  end

  def test_tokenize_single_line_block_comment
    tokens, _state = @lexer.tokenize("/* comment */")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "/* comment */", tokens[0].text
  end

  def test_tokenize_inline_block_comment
    tokens, _state = @lexer.tokenize("let /* inline */ x = 5")
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

  def test_tokenize_integer_with_type_suffix
    tokens, _state = @lexer.tokenize("42i32")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
    assert_equal "42i32", tokens[0].text
  end

  def test_tokenize_float
    tokens, _state = @lexer.tokenize("3.14")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  def test_tokenize_float_with_suffix
    tokens, _state = @lexer.tokenize("3.14f64")

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

  def test_tokenize_integer_with_underscores
    tokens, _state = @lexer.tokenize("1_000_000")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  # Identifiers
  def test_tokenize_identifier
    tokens, _state = @lexer.tokenize("foo_bar")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
    assert_equal "foo_bar", tokens[0].text
  end

  def test_tokenize_identifier_with_underscore_prefix
    tokens, _state = @lexer.tokenize("_unused")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
  end

  # Operators
  def test_tokenize_operators
    tokens, _state = @lexer.tokenize("+ - * / % == != < > <= >=")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert_operator operator_tokens.length, :>=, 5
  end

  def test_tokenize_range_operator
    tokens, _state = @lexer.tokenize("0..10")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("..") })
  end

  def test_tokenize_inclusive_range_operator
    tokens, _state = @lexer.tokenize("0..=10")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("..=") })
  end

  def test_tokenize_arrow_operator
    tokens, _state = @lexer.tokenize("fn foo() -> i32")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("->") })
  end

  def test_tokenize_fat_arrow
    tokens, _state = @lexer.tokenize("match x { 1 => true }")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("=>") })
  end

  def test_tokenize_double_colon
    tokens, _state = @lexer.tokenize("std::io::Result")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("::") })
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

  # Function definitions
  def test_tokenize_function_definition
    tokens, _state = @lexer.tokenize("fn main")

    assert_equal 2, tokens.length
    assert_equal :keyword, tokens[0].type
    assert_equal "fn", tokens[0].text
    assert_equal :function_definition, tokens[1].type
    assert_equal "main", tokens[1].text
  end

  def test_tokenize_function_definition_with_parens
    tokens, _state = @lexer.tokenize("fn hello()")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "hello", func_tokens[0].text
  end

  def test_tokenize_function_definition_with_return_type
    tokens, _state = @lexer.tokenize("fn calculate() -> i32")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "calculate", func_tokens[0].text
  end

  def test_tokenize_function_definition_with_lifetime
    # fn foo<'a>(x: &'a str) - 'a is lifetime, foo is function name
    tokens, _state = @lexer.tokenize("fn foo<'a>")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "foo", func_tokens[0].text
  end

  def test_tokenize_impl_method
    # Methods in impl blocks: fn method_name()
    # Note: impl methods have same pattern as standalone functions
    tokens, _state = @lexer.tokenize("fn process_data")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "process_data", func_tokens[0].text
  end

  # Complex examples
  def test_tokenize_function_declaration
    tokens, _state = @lexer.tokenize("fn main() {")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :function_definition
  end

  def test_tokenize_struct_definition
    tokens, _state = @lexer.tokenize("struct Point {")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :constant
  end

  def test_tokenize_impl_block
    tokens, _state = @lexer.tokenize("impl MyStruct {")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :constant
  end

  def test_tokenize_use_statement
    tokens, _state = @lexer.tokenize("use std::io::Result;")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :identifier
    assert_includes types, :constant
  end

  def test_tokenize_let_binding
    tokens, _state = @lexer.tokenize("let mut x: i32 = 5;")
    types = tokens.map(&:type)

    assert_includes types, :keyword
    assert_includes types, :identifier
    assert_includes types, :type
    assert_includes types, :number
  end

  def test_tokenize_match_expression
    tokens, _state = @lexer.tokenize("match value {")
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

  def test_tokenize_self_keyword
    tokens, _state = @lexer.tokenize("self")

    assert_equal 1, tokens.length
    assert_equal :keyword, tokens[0].type
  end

  def test_tokenize_self_type
    tokens, _state = @lexer.tokenize("Self")

    assert_equal 1, tokens.length
    assert_equal :keyword, tokens[0].type
  end

  def test_tokenize_true_false
    %w[true false].each do |keyword|
      tokens, _state = @lexer.tokenize(keyword)

      assert_equal 1, tokens.length
      assert_equal :keyword, tokens[0].type, "Expected :keyword for '#{keyword}'"
    end
  end
end
