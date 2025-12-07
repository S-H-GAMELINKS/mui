# frozen_string_literal: true

require "test_helper"

class TestTerminalAdapterBase < Minitest::Test
  def setup
    @adapter = Mui::TerminalAdapter::Base.new
  end

  class TestColorResolver < TestTerminalAdapterBase
    def test_has_color_resolver_accessor
      assert_respond_to @adapter, :color_resolver
      assert_respond_to @adapter, :color_resolver=
    end

    def test_color_resolver_defaults_to_nil
      assert_nil @adapter.color_resolver
    end

    def test_color_resolver_can_be_set
      resolver = ->(color) { color }
      @adapter.color_resolver = resolver

      assert_equal resolver, @adapter.color_resolver
    end
  end

  class TestInit < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.init
      end
    end
  end

  class TestClose < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.close
      end
    end
  end

  class TestClear < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.clear
      end
    end
  end

  class TestRefresh < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.refresh
      end
    end
  end

  class TestWidth < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.width
      end
    end
  end

  class TestHeight < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.height
      end
    end
  end

  class TestSetpos < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.setpos(0, 0)
      end
    end
  end

  class TestAddstr < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.addstr("test")
      end
    end
  end

  class TestWithHighlight < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.with_highlight { nil }
      end
    end
  end

  class TestInitColors < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.init_colors
      end
    end
  end

  class TestInitColorPair < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.init_color_pair(1, :white, :black)
      end
    end
  end

  class TestWithColor < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.with_color(1) { nil }
      end
    end
  end

  class TestGetch < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.getch
      end
    end
  end

  class TestGetchNonblock < TestTerminalAdapterBase
    def test_raises_method_not_overridden_error
      assert_raises(Mui::MethodNotOverriddenError) do
        @adapter.getch_nonblock
      end
    end
  end
end
