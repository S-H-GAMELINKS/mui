# frozen_string_literal: true

require "test_helper"

module Mui
  module HandlerResult
    class TestBase < Minitest::Test
      def test_default_values
        result = Base.new

        assert_nil result.mode
        assert_nil result.message
        refute result.quit?
        refute result.start_selection?
        refute result.line_mode?
        refute result.clear_selection?
        refute result.toggle_line_mode?
      end

      def test_with_mode
        result = Base.new(mode: Mode::INSERT)

        assert_equal Mode::INSERT, result.mode
      end

      def test_with_message
        result = Base.new(message: "test message")

        assert_equal "test message", result.message
      end

      def test_with_quit
        result = Base.new(quit: true)

        assert result.quit?
      end

      def test_is_frozen
        result = Base.new

        assert result.frozen?
      end
    end

    class TestNormalModeResult < Minitest::Test
      def test_default_values
        result = NormalModeResult.new

        refute result.start_selection?
        refute result.line_mode?
      end

      def test_with_start_selection
        result = NormalModeResult.new(mode: Mode::VISUAL, start_selection: true)

        assert result.start_selection?
        assert_equal Mode::VISUAL, result.mode
      end

      def test_with_line_mode
        result = NormalModeResult.new(mode: Mode::VISUAL_LINE, start_selection: true, line_mode: true)

        assert result.start_selection?
        assert result.line_mode?
      end

      def test_inherits_base_defaults
        result = NormalModeResult.new

        refute result.clear_selection?
        refute result.toggle_line_mode?
      end

      def test_is_frozen
        result = NormalModeResult.new

        assert result.frozen?
      end
    end

    class TestVisualModeResult < Minitest::Test
      def test_default_values
        result = VisualModeResult.new

        refute result.clear_selection?
        refute result.toggle_line_mode?
      end

      def test_with_clear_selection
        result = VisualModeResult.new(mode: Mode::NORMAL, clear_selection: true)

        assert result.clear_selection?
        assert_equal Mode::NORMAL, result.mode
      end

      def test_with_toggle_line_mode
        result = VisualModeResult.new(mode: Mode::VISUAL_LINE, toggle_line_mode: true)

        assert result.toggle_line_mode?
      end

      def test_inherits_base_defaults
        result = VisualModeResult.new

        refute result.start_selection?
        refute result.line_mode?
      end

      def test_is_frozen
        result = VisualModeResult.new

        assert result.frozen?
      end
    end

    class TestInsertModeResult < Minitest::Test
      def test_uses_base_functionality
        result = InsertModeResult.new(mode: Mode::NORMAL)

        assert_equal Mode::NORMAL, result.mode
        refute result.quit?
      end

      def test_is_frozen
        result = InsertModeResult.new

        assert result.frozen?
      end
    end

    class TestCommandModeResult < Minitest::Test
      def test_uses_base_functionality
        result = CommandModeResult.new(mode: Mode::NORMAL, message: "File saved")

        assert_equal Mode::NORMAL, result.mode
        assert_equal "File saved", result.message
      end

      def test_with_quit
        result = CommandModeResult.new(quit: true)

        assert result.quit?
      end

      def test_is_frozen
        result = CommandModeResult.new

        assert result.frozen?
      end
    end
  end
end
