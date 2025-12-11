# frozen_string_literal: true

module Mui
  module Syntax
    # Detects programming language from file path and provides appropriate lexer
    class LanguageDetector
      # Map file extensions to language symbols
      EXTENSION_MAP = {
        ".rb" => :ruby,
        ".ru" => :ruby,
        ".rake" => :ruby,
        ".gemspec" => :ruby,
        ".c" => :c,
        ".h" => :c,
        ".y" => :c
      }.freeze

      # Map basenames (files without extension) to language symbols
      BASENAME_MAP = {
        "Gemfile" => :ruby,
        "Rakefile" => :ruby,
        "Guardfile" => :ruby,
        "Vagrantfile" => :ruby,
        "Berksfile" => :ruby,
        "Capfile" => :ruby,
        "Thorfile" => :ruby,
        "Podfile" => :ruby,
        "Brewfile" => :ruby
      }.freeze

      class << self
        # Detect language from file path
        def detect(file_path)
          return nil if file_path.nil? || file_path.empty?

          # Try extension first
          ext = File.extname(file_path).downcase
          language = EXTENSION_MAP[ext]
          return language if language

          # Try basename
          basename = File.basename(file_path)
          BASENAME_MAP[basename]
        end

        # Get a lexer instance for a language
        def lexer_for(language)
          case language
          when :ruby
            Lexers::RubyLexer.new
          when :c
            Lexers::CLexer.new
          end
        end

        # Get a lexer instance for a file path
        def lexer_for_file(file_path)
          language = detect(file_path)
          lexer_for(language)
        end

        # List all supported languages
        def supported_languages
          (EXTENSION_MAP.values + BASENAME_MAP.values).uniq
        end

        # List all supported extensions
        def supported_extensions
          EXTENSION_MAP.keys
        end
      end
    end
  end
end
