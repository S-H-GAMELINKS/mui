# frozen_string_literal: true

require "test_helper"

class TestCssLexer < Minitest::Test
  def setup
    @lexer = Mui::Syntax::Lexers::CssLexer.new
  end

  # Selectors
  def test_tokenize_element_selector
    tokens, _state = @lexer.tokenize("div {")
    identifier_tokens = tokens.select { |t| t.type == :identifier }

    assert_operator identifier_tokens.length, :>=, 1
  end

  def test_tokenize_class_selector
    tokens, _state = @lexer.tokenize(".container {")
    class_tokens = tokens.select { |t| t.type == :type }

    assert_equal 1, class_tokens.length
    assert_equal ".container", class_tokens[0].text
  end

  def test_tokenize_id_selector
    tokens, _state = @lexer.tokenize("#main {")
    id_tokens = tokens.select { |t| t.type == :constant }

    assert_equal 1, id_tokens.length
    assert_equal "#main", id_tokens[0].text
  end

  def test_tokenize_pseudo_class
    tokens, _state = @lexer.tokenize("a:hover {")
    keyword_tokens = tokens.select { |t| t.type == :keyword }

    assert(keyword_tokens.any? { |t| t.text.include?(":hover") })
  end

  def test_tokenize_pseudo_element
    tokens, _state = @lexer.tokenize("p::before {")
    keyword_tokens = tokens.select { |t| t.type == :keyword }

    assert(keyword_tokens.any? { |t| t.text.include?("::before") })
  end

  # Properties and values
  def test_tokenize_property
    tokens, _state = @lexer.tokenize("color: red;")
    identifier_tokens = tokens.select { |t| t.type == :identifier }

    assert(identifier_tokens.any? { |t| t.text == "color" })
  end

  def test_tokenize_number_with_unit
    tokens, _state = @lexer.tokenize("width: 100px;")
    number_tokens = tokens.select { |t| t.type == :number }

    assert(number_tokens.any? { |t| t.text.include?("100px") })
  end

  def test_tokenize_percentage
    tokens, _state = @lexer.tokenize("width: 50%;")
    number_tokens = tokens.select { |t| t.type == :number }

    assert(number_tokens.any? { |t| t.text.include?("50%") })
  end

  def test_tokenize_em_unit
    tokens, _state = @lexer.tokenize("font-size: 1.5em;")
    number_tokens = tokens.select { |t| t.type == :number }

    assert(number_tokens.any? { |t| t.text.include?("em") })
  end

  def test_tokenize_rem_unit
    tokens, _state = @lexer.tokenize("margin: 2rem;")
    number_tokens = tokens.select { |t| t.type == :number }

    assert(number_tokens.any? { |t| t.text.include?("rem") })
  end

  # Colors
  def test_tokenize_hex_color_short
    tokens, _state = @lexer.tokenize("color: #fff;")
    number_tokens = tokens.select { |t| t.type == :number }

    assert(number_tokens.any? { |t| t.text == "#fff" })
  end

  def test_tokenize_hex_color_long
    tokens, _state = @lexer.tokenize("color: #ffffff;")
    number_tokens = tokens.select { |t| t.type == :number }

    assert(number_tokens.any? { |t| t.text == "#ffffff" })
  end

  # Strings
  def test_tokenize_double_quoted_string
    tokens, _state = @lexer.tokenize('content: "hello";')
    string_tokens = tokens.select { |t| t.type == :string }

    assert_equal 1, string_tokens.length
    assert_equal '"hello"', string_tokens[0].text
  end

  def test_tokenize_single_quoted_string
    tokens, _state = @lexer.tokenize("content: 'hello';")
    string_tokens = tokens.select { |t| t.type == :string }

    assert_equal 1, string_tokens.length
    assert_equal "'hello'", string_tokens[0].text
  end

  def test_tokenize_url
    tokens, _state = @lexer.tokenize("background: url(image.png);")
    string_tokens = tokens.select { |t| t.type == :string }

    assert(string_tokens.any? { |t| t.text.include?("url") })
  end

  # @rules
  def test_tokenize_media_rule
    tokens, _state = @lexer.tokenize("@media screen {")
    preprocessor_tokens = tokens.select { |t| t.type == :preprocessor }

    assert_equal 1, preprocessor_tokens.length
    assert_equal "@media", preprocessor_tokens[0].text
  end

  def test_tokenize_keyframes_rule
    tokens, _state = @lexer.tokenize("@keyframes slide {")
    preprocessor_tokens = tokens.select { |t| t.type == :preprocessor }

    assert_equal 1, preprocessor_tokens.length
    assert_equal "@keyframes", preprocessor_tokens[0].text
  end

  def test_tokenize_import_rule
    tokens, _state = @lexer.tokenize('@import "styles.css";')
    preprocessor_tokens = tokens.select { |t| t.type == :preprocessor }

    assert_equal 1, preprocessor_tokens.length
  end

  # Comments
  def test_tokenize_single_line_comment
    tokens, _state = @lexer.tokenize("/* comment */")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal "/* comment */", tokens[0].text
  end

  def test_tokenize_inline_comment
    tokens, _state = @lexer.tokenize("color: red; /* set color */")
    comment_tokens = tokens.select { |t| t.type == :comment }

    assert_equal 1, comment_tokens.length
  end

  # Multiline comments
  def test_comment_multiline_start
    tokens, state = @lexer.tokenize("/* start of comment")

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal :block_comment, state
  end

  def test_comment_multiline_middle
    tokens, state = @lexer.tokenize("  middle of comment  ", :block_comment)

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_equal :block_comment, state
  end

  def test_comment_multiline_end
    tokens, state = @lexer.tokenize("end of comment */", :block_comment)

    assert_equal 1, tokens.length
    assert_equal :comment, tokens[0].type
    assert_nil state
  end

  def test_comment_full_sequence
    _, state1 = @lexer.tokenize("/* Start")

    assert_equal :block_comment, state1

    _, state2 = @lexer.tokenize("Middle", state1)

    assert_equal :block_comment, state2

    _, state3 = @lexer.tokenize("End */", state2)

    assert_nil state3
  end

  # Special values
  def test_tokenize_important
    tokens, _state = @lexer.tokenize("color: red !important;")
    constant_tokens = tokens.select { |t| t.type == :constant }

    assert(constant_tokens.any? { |t| t.text.include?("!important") })
  end

  def test_tokenize_inherit
    tokens, _state = @lexer.tokenize("color: inherit;")
    constant_tokens = tokens.select { |t| t.type == :constant }

    assert(constant_tokens.any? { |t| t.text == "inherit" })
  end

  # Functions
  def test_tokenize_calc_function
    tokens, _state = @lexer.tokenize("width: calc(100% - 20px);")
    keyword_tokens = tokens.select { |t| t.type == :keyword }

    assert(keyword_tokens.any? { |t| t.text == "calc" })
  end

  def test_tokenize_rgb_function
    tokens, _state = @lexer.tokenize("color: rgb(255, 0, 0);")
    keyword_tokens = tokens.select { |t| t.type == :keyword }

    assert(keyword_tokens.any? { |t| t.text == "rgb" })
  end

  def test_tokenize_var_function
    tokens, _state = @lexer.tokenize("color: var(--main-color);")
    keyword_tokens = tokens.select { |t| t.type == :keyword }

    assert(keyword_tokens.any? { |t| t.text == "var" })
  end

  # Complex examples
  def test_tokenize_complete_rule
    tokens, _state = @lexer.tokenize(".container { width: 100%; }")
    types = tokens.map(&:type)

    assert_includes types, :type # .container
    assert_includes types, :identifier # width
    assert_includes types, :number # 100%
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
