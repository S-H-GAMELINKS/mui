# frozen_string_literal: true

require "test_helper"

class TestError < Minitest::Test
  class TestMuiError < Minitest::Test
    def test_inherits_from_standard_error
      assert Mui::Error < StandardError
    end

    def test_can_be_raised
      assert_raises(Mui::Error) do
        raise Mui::Error, "test error"
      end
    end

    def test_has_message
      error = Mui::Error.new("test message")

      assert_equal "test message", error.message
    end
  end

  class TestMethodNotOverriddenError < Minitest::Test
    def test_inherits_from_mui_error
      assert Mui::MethodNotOverriddenError < Mui::Error
    end

    def test_formats_message_with_method_name
      error = Mui::MethodNotOverriddenError.new(:some_method)

      assert_equal "Subclass must implement #some_method", error.message
    end

    def test_can_be_raised
      assert_raises(Mui::MethodNotOverriddenError) do
        raise Mui::MethodNotOverriddenError, :test_method
      end
    end
  end

  class TestPluginError < Minitest::Test
    def test_inherits_from_mui_error
      assert Mui::PluginError < Mui::Error
    end

    def test_can_be_raised
      assert_raises(Mui::PluginError) do
        raise Mui::PluginError, "plugin error"
      end
    end
  end

  class TestPluginNotFoundError < Minitest::Test
    def test_inherits_from_plugin_error
      assert Mui::PluginNotFoundError < Mui::PluginError
    end

    def test_formats_message_with_plugin_name
      error = Mui::PluginNotFoundError.new("my-plugin")

      assert_equal "Plugin 'my-plugin' not found", error.message
    end

    def test_can_be_raised
      assert_raises(Mui::PluginNotFoundError) do
        raise Mui::PluginNotFoundError, "missing-plugin"
      end
    end
  end

  class TestUnknownCommandError < Minitest::Test
    def test_inherits_from_mui_error
      assert Mui::UnknownCommandError < Mui::Error
    end

    def test_formats_message_with_command_name
      error = Mui::UnknownCommandError.new("foobar")

      assert_equal "Unknown command: foobar", error.message
    end

    def test_can_be_raised
      assert_raises(Mui::UnknownCommandError) do
        raise Mui::UnknownCommandError, "unknown"
      end
    end
  end
end
