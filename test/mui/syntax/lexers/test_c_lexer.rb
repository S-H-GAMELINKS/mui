# frozen_string_literal: true

require "test_helper"

class TestCLexer < Minitest::Test
  def setup
    @lexer = Mui::Syntax::Lexers::CLexer.new
  end

  # Keywords
  def test_tokenize_keywords
    %w[if else while for return struct const volatile].each do |keyword|
      tokens, _state = @lexer.tokenize(keyword)

      assert_equal 1, tokens.length, "Expected 1 token for '#{keyword}'"
      assert_equal :keyword, tokens[0].type, "Expected :keyword for '#{keyword}'"
      assert_equal keyword, tokens[0].text
    end
  end

  # Type keywords
  def test_tokenize_type_keywords
    %w[int char void unsigned signed long short double float].each do |keyword|
      tokens, _state = @lexer.tokenize(keyword)

      assert_equal 1, tokens.length, "Expected 1 token for '#{keyword}'"
      assert_equal :type, tokens[0].type, "Expected :type for '#{keyword}'"
      assert_equal keyword, tokens[0].text
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

  # Comments
  def test_tokenize_single_line_comment
    tokens, _state = @lexer.tokenize("// this is a comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "// this is a comment", tokens[0].text
  end

  def test_tokenize_code_with_comment
    tokens, _state = @lexer.tokenize("int x; // declare x")
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
    tokens, _state = @lexer.tokenize("int /* type */ x;")
    types = tokens.map(&:type)

    assert_includes types, :type
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

  def test_tokenize_integer_with_suffix
    tokens, _state = @lexer.tokenize("42L")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
    assert_equal "42L", tokens[0].text
  end

  def test_tokenize_unsigned_long
    tokens, _state = @lexer.tokenize("42UL")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  def test_tokenize_float
    tokens, _state = @lexer.tokenize("3.14")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  def test_tokenize_float_with_suffix
    tokens, _state = @lexer.tokenize("3.14f")

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
    tokens, _state = @lexer.tokenize("0755")

    assert_equal 1, tokens.length
    assert_equal :number, tokens[0].type
  end

  # Preprocessor
  def test_tokenize_include
    tokens, _state = @lexer.tokenize("#include <stdio.h>")

    assert_equal 1, tokens.length
    assert_equal :preprocessor, tokens[0].type
  end

  def test_tokenize_define
    tokens, _state = @lexer.tokenize("#define MAX 100")

    assert_equal 1, tokens.length
    assert_equal :preprocessor, tokens[0].type
  end

  def test_tokenize_ifdef
    tokens, _state = @lexer.tokenize("#ifdef DEBUG")

    assert_equal 1, tokens.length
    assert_equal :preprocessor, tokens[0].type
  end

  def test_tokenize_preprocessor_with_leading_space
    tokens, _state = @lexer.tokenize("  #include <stdlib.h>")

    assert_equal 1, tokens.length
    assert_equal :preprocessor, tokens[0].type
  end

  # Identifiers
  def test_tokenize_identifier
    tokens, _state = @lexer.tokenize("foo_bar")

    assert_equal 1, tokens.length
    assert_equal :identifier, tokens[0].type
    assert_equal "foo_bar", tokens[0].text
  end

  def test_tokenize_identifier_with_underscore_prefix
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

  def test_tokenize_pointer_operator
    tokens, _state = @lexer.tokenize("ptr->member")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert(operator_tokens.any? { |t| t.text.include?("->") })
  end

  def test_tokenize_increment_decrement
    tokens, _state = @lexer.tokenize("i++ j--")
    operator_tokens = tokens.select { |t| t.type == :operator }

    assert_equal 2, operator_tokens.length
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
    lexer = @lexer

    tokens1, state1 = lexer.tokenize("/* Start")

    assert_equal :block_comment, state1
    assert_equal :comment, tokens1[0].type

    tokens2, state2 = lexer.tokenize(" * Middle", state1)

    assert_equal :block_comment, state2
    assert_equal :comment, tokens2[0].type

    tokens3, state3 = lexer.tokenize(" */", state2)

    assert_nil state3
    assert_equal :comment, tokens3[0].type
  end

  def test_block_comment_with_code_after
    tokens, state = @lexer.tokenize("end */ int x;", :block_comment)

    assert_nil state
    # Should have comment and then int type and identifier
    types = tokens.map(&:type)

    assert_includes types, :comment
    assert_includes types, :type
    assert_includes types, :identifier
  end

  # Function definitions/calls
  def test_tokenize_function_definition
    tokens, _state = @lexer.tokenize("int main()")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "main", func_tokens[0].text
  end

  def test_tokenize_function_definition_with_args
    tokens, _state = @lexer.tokenize("void print(int x)")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "print", func_tokens[0].text
  end

  def test_tokenize_function_call
    # Function calls are also highlighted as function_definition
    tokens, _state = @lexer.tokenize("printf(msg)")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "printf", func_tokens[0].text
  end

  def test_tokenize_function_with_space_before_paren
    tokens, _state = @lexer.tokenize("int main (void)")
    func_tokens = tokens.select { |t| t.type == :function_definition }

    assert_equal 1, func_tokens.length
    assert_equal "main", func_tokens[0].text
  end

  # Complex examples
  def test_tokenize_function_declaration
    tokens, _state = @lexer.tokenize("int main(void)")
    types = tokens.map(&:type)

    assert_includes types, :type
    assert_includes types, :function_definition
  end

  def test_tokenize_variable_declaration
    tokens, _state = @lexer.tokenize("unsigned long count = 0;")
    type_tokens = tokens.select { |t| t.type == :type }

    assert_operator type_tokens.length, :>=, 2
  end

  def test_tokenize_struct_definition
    tokens, _state = @lexer.tokenize("struct Point { int x; int y; };")
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
