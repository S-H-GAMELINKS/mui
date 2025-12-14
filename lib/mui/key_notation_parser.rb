# frozen_string_literal: true

require "strscan"

module Mui
  # Parser for Vim-style key notation strings
  # Converts notation like "<Leader>gd", "<C-x><C-s>", "<Space>w" to internal key arrays
  module KeyNotationParser
    # Special key mappings (case-insensitive)
    SPECIAL_KEYS = {
      "space" => " ",
      "tab" => "\t",
      "cr" => "\r",
      "enter" => "\r",
      "return" => "\r",
      "esc" => "\e",
      "escape" => "\e",
      "bs" => "\x7f",
      "backspace" => "\x7f",
      "del" => "\x7f",
      "delete" => "\x7f",
      "lt" => "<",
      "gt" => ">",
      "bar" => "|",
      "bslash" => "\\",
      "leader" => :leader
    }.freeze

    # Ctrl key mappings (a-z and some special characters)
    CTRL_CHARS = {
      "@" => 0,  # NUL
      "a" => 1,
      "b" => 2,
      "c" => 3,
      "d" => 4,
      "e" => 5,
      "f" => 6,
      "g" => 7,
      "h" => 8,  # Also backspace
      "i" => 9,  # Also tab
      "j" => 10, # Also newline
      "k" => 11,
      "l" => 12,
      "m" => 13, # Also carriage return
      "n" => 14,
      "o" => 15,
      "p" => 16,
      "q" => 17,
      "r" => 18,
      "s" => 19,
      "t" => 20,
      "u" => 21,
      "v" => 22,
      "w" => 23,
      "x" => 24,
      "y" => 25,
      "z" => 26,
      "[" => 27, # Also escape
      "\\" => 28,
      "]" => 29,
      "^" => 30,
      "_" => 31
    }.freeze

    class << self
      # Parse a key notation string into an array of keys
      # @param notation [String] Key notation (e.g., "<Leader>gd", "<C-x><C-s>")
      # @return [Array<String, Symbol>] Array of normalized keys
      def parse(notation)
        return [] if notation.nil? || notation.empty?

        tokens = []
        scanner = StringScanner.new(notation)

        until scanner.eos?
          if scanner.scan(/<([^>]+)>/)
            # Special key notation <...>
            tokens << parse_special(scanner[1])
          else
            # Regular character
            char = scanner.getch
            tokens << char if char
          end
        end

        tokens
      end

      # Parse a special key notation (content inside < >)
      # @param name [String] Special key name (e.g., "C-x", "Leader", "Space")
      # @return [String, Symbol] Normalized key
      def parse_special(name)
        return :leader if name.casecmp?("leader")

        # Handle Ctrl key: <C-x>, <Ctrl-x>, <C-X>
        return parse_ctrl_key(::Regexp.last_match(2)) if name =~ /\A(c|ctrl)-(.+)\z/i

        # Handle Shift key: <S-x>, <Shift-x>
        return parse_shift_key(::Regexp.last_match(2)) if name =~ /\A(s|shift)-(.+)\z/i

        # Handle other special keys
        normalized_name = name.downcase
        SPECIAL_KEYS[normalized_name] || name
      end

      # Normalize an input key (from terminal) to internal representation
      # @param key [Integer, String] Raw key input
      # @return [String, nil] Normalized key string, or nil if invalid
      def normalize_input_key(key)
        case key
        when String
          key
        when Integer
          normalize_integer_key(key)
        end
      end

      private

      def parse_ctrl_key(char)
        char_lower = char.downcase
        code = CTRL_CHARS[char_lower]
        code ? code.chr : char
      end

      def parse_shift_key(char)
        # Shift typically produces uppercase for letters
        char.length == 1 ? char.upcase : char
      end

      def normalize_integer_key(key)
        case key
        when KeyCode::ENTER_CR, KeyCode::ENTER_LF
          "\r"
        when KeyCode::ESCAPE
          "\e"
        when KeyCode::TAB
          "\t"
        when KeyCode::BACKSPACE
          "\x7f"
        when 0..31
          # Control characters - convert to the character they represent
          key.chr
        when KeyCode::PRINTABLE_MIN..KeyCode::PRINTABLE_MAX
          key.chr(Encoding::UTF_8)
        end
      rescue RangeError
        nil
      end
    end
  end
end
