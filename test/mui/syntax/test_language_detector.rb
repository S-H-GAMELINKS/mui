# frozen_string_literal: true

require "test_helper"

class TestLanguageDetector < Minitest::Test
  # Detection by extension
  def test_detect_ruby_by_extension
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("foo.rb")
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("/path/to/foo.rb")
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("foo.rake")
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("foo.gemspec")
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("config.ru")
  end

  def test_detect_c_by_extension
    assert_equal :c, Mui::Syntax::LanguageDetector.detect("foo.c")
    assert_equal :c, Mui::Syntax::LanguageDetector.detect("/path/to/foo.c")
    assert_equal :c, Mui::Syntax::LanguageDetector.detect("foo.h")
  end

  def test_detect_case_insensitive_extension
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("foo.RB")
    assert_equal :c, Mui::Syntax::LanguageDetector.detect("foo.C")
    assert_equal :c, Mui::Syntax::LanguageDetector.detect("foo.H")
  end

  # Detection by basename
  def test_detect_ruby_by_basename
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("Gemfile")
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("/path/to/Gemfile")
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("Rakefile")
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("Guardfile")
    assert_equal :ruby, Mui::Syntax::LanguageDetector.detect("Vagrantfile")
  end

  # Go detection
  def test_detect_go_by_extension
    assert_equal :go, Mui::Syntax::LanguageDetector.detect("foo.go")
    assert_equal :go, Mui::Syntax::LanguageDetector.detect("/path/to/main.go")
  end

  # Rust detection
  def test_detect_rust_by_extension
    assert_equal :rust, Mui::Syntax::LanguageDetector.detect("foo.rs")
    assert_equal :rust, Mui::Syntax::LanguageDetector.detect("/path/to/main.rs")
  end

  # JavaScript detection
  def test_detect_javascript_by_extension
    assert_equal :javascript, Mui::Syntax::LanguageDetector.detect("foo.js")
    assert_equal :javascript, Mui::Syntax::LanguageDetector.detect("app.mjs")
    assert_equal :javascript, Mui::Syntax::LanguageDetector.detect("app.cjs")
    assert_equal :javascript, Mui::Syntax::LanguageDetector.detect("component.jsx")
  end

  # TypeScript detection
  def test_detect_typescript_by_extension
    assert_equal :typescript, Mui::Syntax::LanguageDetector.detect("foo.ts")
    assert_equal :typescript, Mui::Syntax::LanguageDetector.detect("component.tsx")
    assert_equal :typescript, Mui::Syntax::LanguageDetector.detect("app.mts")
    assert_equal :typescript, Mui::Syntax::LanguageDetector.detect("app.cts")
  end

  # Markdown detection
  def test_detect_markdown_by_extension
    assert_equal :markdown, Mui::Syntax::LanguageDetector.detect("README.md")
    assert_equal :markdown, Mui::Syntax::LanguageDetector.detect("docs.markdown")
  end

  # HTML detection
  def test_detect_html_by_extension
    assert_equal :html, Mui::Syntax::LanguageDetector.detect("index.html")
    assert_equal :html, Mui::Syntax::LanguageDetector.detect("page.htm")
    assert_equal :html, Mui::Syntax::LanguageDetector.detect("doc.xhtml")
  end

  # CSS detection
  def test_detect_css_by_extension
    assert_equal :css, Mui::Syntax::LanguageDetector.detect("styles.css")
    assert_equal :css, Mui::Syntax::LanguageDetector.detect("app.scss")
    assert_equal :css, Mui::Syntax::LanguageDetector.detect("main.sass")
  end

  # Unknown files
  def test_detect_unknown_extension
    assert_nil Mui::Syntax::LanguageDetector.detect("foo.txt")
    assert_nil Mui::Syntax::LanguageDetector.detect("foo.py")
  end

  def test_detect_nil_path
    assert_nil Mui::Syntax::LanguageDetector.detect(nil)
  end

  def test_detect_empty_path
    assert_nil Mui::Syntax::LanguageDetector.detect("")
  end

  # Lexer creation
  def test_lexer_for_ruby
    lexer = Mui::Syntax::LanguageDetector.lexer_for(:ruby)

    assert_instance_of Mui::Syntax::Lexers::RubyLexer, lexer
  end

  def test_lexer_for_c
    lexer = Mui::Syntax::LanguageDetector.lexer_for(:c)

    assert_instance_of Mui::Syntax::Lexers::CLexer, lexer
  end

  def test_lexer_for_go
    lexer = Mui::Syntax::LanguageDetector.lexer_for(:go)

    assert_instance_of Mui::Syntax::Lexers::GoLexer, lexer
  end

  def test_lexer_for_rust
    lexer = Mui::Syntax::LanguageDetector.lexer_for(:rust)

    assert_instance_of Mui::Syntax::Lexers::RustLexer, lexer
  end

  def test_lexer_for_javascript
    lexer = Mui::Syntax::LanguageDetector.lexer_for(:javascript)

    assert_instance_of Mui::Syntax::Lexers::JavaScriptLexer, lexer
  end

  def test_lexer_for_typescript
    lexer = Mui::Syntax::LanguageDetector.lexer_for(:typescript)

    assert_instance_of Mui::Syntax::Lexers::TypeScriptLexer, lexer
  end

  def test_lexer_for_markdown
    lexer = Mui::Syntax::LanguageDetector.lexer_for(:markdown)

    assert_instance_of Mui::Syntax::Lexers::MarkdownLexer, lexer
  end

  def test_lexer_for_html
    lexer = Mui::Syntax::LanguageDetector.lexer_for(:html)

    assert_instance_of Mui::Syntax::Lexers::HtmlLexer, lexer
  end

  def test_lexer_for_css
    lexer = Mui::Syntax::LanguageDetector.lexer_for(:css)

    assert_instance_of Mui::Syntax::Lexers::CssLexer, lexer
  end

  def test_lexer_for_unknown
    assert_nil Mui::Syntax::LanguageDetector.lexer_for(:unknown)
    assert_nil Mui::Syntax::LanguageDetector.lexer_for(nil)
  end

  def test_lexer_for_file
    lexer = Mui::Syntax::LanguageDetector.lexer_for_file("foo.rb")

    assert_instance_of Mui::Syntax::Lexers::RubyLexer, lexer
  end

  def test_lexer_for_file_c
    lexer = Mui::Syntax::LanguageDetector.lexer_for_file("main.c")

    assert_instance_of Mui::Syntax::Lexers::CLexer, lexer
  end

  def test_lexer_for_unknown_file
    assert_nil Mui::Syntax::LanguageDetector.lexer_for_file("foo.txt")
    assert_nil Mui::Syntax::LanguageDetector.lexer_for_file(nil)
  end

  # Utility methods
  def test_supported_languages
    languages = Mui::Syntax::LanguageDetector.supported_languages

    assert_includes languages, :ruby
    assert_includes languages, :c
  end

  def test_supported_extensions
    extensions = Mui::Syntax::LanguageDetector.supported_extensions

    assert_includes extensions, ".rb"
    assert_includes extensions, ".c"
    assert_includes extensions, ".h"
  end
end
