# frozen_string_literal: true

require "test_helper"

class TestInput < Minitest::Test
  class TestRead < Minitest::Test
    include MuiTestHelper

    def setup
      @input = Mui::Input.new(adapter: test_adapter)
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_returns_single_character
      setup_key_sequence(["a"])

      result = @input.read

      assert_equal "a", result
    end

    def test_returns_special_key
      setup_key_sequence([Curses::KEY_UP])

      result = @input.read

      assert_equal Curses::KEY_UP, result
    end

    def test_returns_escape
      setup_key_sequence([27])

      result = @input.read

      assert_equal 27, result
    end

    def test_consumes_keys_in_sequence
      setup_key_sequence(%w[a b c])

      assert_equal "a", @input.read
      assert_equal "b", @input.read
      assert_equal "c", @input.read
    end

    def test_raises_when_queue_empty
      setup_key_sequence([])

      assert_raises(StopIteration) do
        @input.read
      end
    end
  end

  class TestReadNonblock < Minitest::Test
    include MuiTestHelper

    def setup
      @input = Mui::Input.new(adapter: test_adapter)
      clear_key_sequence
    end

    def teardown
      clear_key_sequence
    end

    def test_returns_key
      setup_key_sequence(["x"])

      result = @input.read_nonblock

      assert_equal "x", result
    end

    def test_returns_nil_when_queue_empty
      setup_key_sequence([])

      result = @input.read_nonblock

      assert_nil result
    end
  end
end
