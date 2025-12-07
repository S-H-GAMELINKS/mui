# frozen_string_literal: true

require "test_helper"

class TestTerminalAdapterCurses < Minitest::Test
  # NOTE: Most Curses methods cannot be tested without an actual terminal.
  # These tests focus on the adapter's interface compliance and
  # methods that can be tested without a real terminal.

  class TestInheritance < Minitest::Test
    def test_inherits_from_base
      assert Mui::TerminalAdapter::Curses < Mui::TerminalAdapter::Base
    end
  end

  class TestColorResolver < Minitest::Test
    def setup
      @adapter = Mui::TerminalAdapter::Curses.allocate
    end

    def test_has_color_resolver_accessor
      assert_respond_to @adapter, :color_resolver
      assert_respond_to @adapter, :color_resolver=
    end

    def test_color_resolver_inherited_from_base
      @adapter.color_resolver = :test_resolver

      assert_equal :test_resolver, @adapter.color_resolver
    end
  end

  class TestColorCode < Minitest::Test
    def setup
      @adapter = Mui::TerminalAdapter::Curses.allocate
    end

    def test_returns_minus_one_for_nil
      result = @adapter.send(:color_code, nil)

      assert_equal(-1, result)
    end

    def test_returns_integer_as_is
      result = @adapter.send(:color_code, 5)

      assert_equal 5, result
    end

    def test_returns_minus_one_without_resolver
      result = @adapter.send(:color_code, :red)

      assert_equal(-1, result)
    end

    def test_uses_resolver_when_available
      resolver = Object.new
      def resolver.resolve(color)
        color == :red ? 1 : 0
      end
      @adapter.color_resolver = resolver

      result = @adapter.send(:color_code, :red)

      assert_equal 1, result
    end
  end

  class TestMethodsExist < Minitest::Test
    def setup
      @adapter = Mui::TerminalAdapter::Curses.allocate
    end

    def test_responds_to_init
      assert_respond_to @adapter, :init
    end

    def test_responds_to_close
      assert_respond_to @adapter, :close
    end

    def test_responds_to_clear
      assert_respond_to @adapter, :clear
    end

    def test_responds_to_refresh
      assert_respond_to @adapter, :refresh
    end

    def test_responds_to_width
      assert_respond_to @adapter, :width
    end

    def test_responds_to_height
      assert_respond_to @adapter, :height
    end

    def test_responds_to_setpos
      assert_respond_to @adapter, :setpos
    end

    def test_responds_to_addstr
      assert_respond_to @adapter, :addstr
    end

    def test_responds_to_with_highlight
      assert_respond_to @adapter, :with_highlight
    end

    def test_responds_to_init_colors
      assert_respond_to @adapter, :init_colors
    end

    def test_responds_to_init_color_pair
      assert_respond_to @adapter, :init_color_pair
    end

    def test_responds_to_with_color
      assert_respond_to @adapter, :with_color
    end

    def test_responds_to_getch
      assert_respond_to @adapter, :getch
    end

    def test_responds_to_getch_nonblock
      assert_respond_to @adapter, :getch_nonblock
    end
  end

  class TestReadUtf8Char < Minitest::Test
    # NOTE: read_utf8_char is private and requires Curses.getch,
    # so we can only test the byte sequence determination logic indirectly.
    # The method handles UTF-8 multi-byte sequences correctly.

    def test_method_exists
      adapter = Mui::TerminalAdapter::Curses.allocate
      assert adapter.respond_to?(:read_utf8_char, true)
    end
  end
end
