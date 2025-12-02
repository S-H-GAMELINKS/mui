# frozen_string_literal: true

require "test_helper"

class TestKeyHandlerBase < Minitest::Test
  class TestInitialization < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::Base.new(@window, @buffer)
    end

    def test_stores_window
      assert_equal @window, @handler.window
    end

    def test_stores_buffer
      assert_equal @buffer, @handler.buffer
    end
  end

  class TestHandle < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @window = Mui::Window.new(@buffer)
      @handler = Mui::KeyHandler::Base.new(@window, @buffer)
    end

    def test_raises_method_not_overridden_error
      error = assert_raises(Mui::KeyHandler::MethodNotOverriddenError) do
        @handler.handle("a")
      end

      assert_equal "Subclasses must orverride #handle", error.message
    end
  end

  class TestMethodNotOverriddenError < Minitest::Test
    def test_inherits_from_mui_error
      assert Mui::KeyHandler::MethodNotOverriddenError < Mui::Error
    end
  end
end
