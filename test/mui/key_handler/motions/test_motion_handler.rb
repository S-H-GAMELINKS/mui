# frozen_string_literal: true

require "test_helper"

class TestMotionHandler < Minitest::Test
  # Test class that includes the module for isolated testing
  class TestHandler < Mui::KeyHandler::Base
    include Mui::KeyHandler::Motions::MotionHandler

    def result(mode: nil, message: nil, quit: false)
      Mui::HandlerResult::Base.new(mode:, message:, quit:)
    end
  end

  class TestWordMotions < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello world foo"
      @window = Mui::Window.new(@buffer)
      @mode_manager = MockModeManager.new(@window)
      @handler = TestMotionHandler::TestHandler.new(@mode_manager, @buffer)
    end

    def test_handle_word_forward_moves_to_next_word
      @window.cursor_col = 0

      @handler.handle_word_forward

      assert_equal 6, @window.cursor_col
    end

    def test_handle_word_backward_moves_to_previous_word
      @window.cursor_col = 8

      @handler.handle_word_backward

      assert_equal 6, @window.cursor_col
    end

    def test_handle_word_end_moves_to_end_of_word
      @window.cursor_col = 0

      @handler.handle_word_end

      assert_equal 4, @window.cursor_col
    end

    def test_handle_word_forward_returns_result
      result = @handler.handle_word_forward

      assert_instance_of Mui::HandlerResult::Base, result
    end
  end

  class TestLineMotions < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "  hello world"
      @window = Mui::Window.new(@buffer)
      @mode_manager = MockModeManager.new(@window)
      @handler = TestMotionHandler::TestHandler.new(@mode_manager, @buffer)
    end

    def test_handle_line_start_moves_to_column_zero
      @window.cursor_col = 5

      @handler.handle_line_start

      assert_equal 0, @window.cursor_col
    end

    def test_handle_first_non_blank_moves_to_first_non_blank
      @window.cursor_col = 10

      @handler.handle_first_non_blank

      assert_equal 2, @window.cursor_col
    end

    def test_handle_line_end_moves_to_end_of_line
      @window.cursor_col = 0

      @handler.handle_line_end

      assert_equal 12, @window.cursor_col
    end
  end

  class TestFileMotions < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "line1"
      @buffer.insert_line(1, "line2")
      @buffer.insert_line(2, "line3")
      @window = Mui::Window.new(@buffer)
      @mode_manager = MockModeManager.new(@window)
      @handler = TestMotionHandler::TestHandler.new(@mode_manager, @buffer)
    end

    def test_handle_file_end_moves_to_last_line
      @window.cursor_row = 0

      @handler.handle_file_end

      assert_equal 2, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end
  end

  class TestApplyMotion < Minitest::Test
    def setup
      @buffer = Mui::Buffer.new
      @buffer.lines[0] = "hello"
      @window = Mui::Window.new(@buffer)
      @mode_manager = MockModeManager.new(@window)
      @handler = TestMotionHandler::TestHandler.new(@mode_manager, @buffer)
    end

    def test_apply_motion_sets_cursor_position
      @handler.send(:apply_motion, { row: 0, col: 3 })

      assert_equal 0, @window.cursor_row
      assert_equal 3, @window.cursor_col
    end

    def test_apply_motion_with_nil_does_nothing
      @window.cursor_col = 2

      @handler.send(:apply_motion, nil)

      assert_equal 2, @window.cursor_col
    end

    def test_apply_motion_clamps_cursor_to_line
      @handler.send(:apply_motion, { row: 0, col: 100 })

      assert_equal 4, @window.cursor_col
    end
  end
end
