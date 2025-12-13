# frozen_string_literal: true

require "test_helper"

class TestPasteOperator < Minitest::Test
  def setup
    @buffer = Mui::Buffer.new
    @buffer.lines[0] = "hello world"
    @window = Mui::Window.new(@buffer)
    @register = Mui::Register.new
    @operator = Mui::KeyHandler::Operators::PasteOperator.new(
      buffer: @buffer,
      window: @window,
      register: @register
    )
  end

  class TestPasteAfterLinewise < TestPasteOperator
    def test_paste_line_after_inserts_below_cursor
      @register.yank("new line", linewise: true)

      result = @operator.paste_after

      assert_equal :done, result
      assert_equal 2, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
      assert_equal "new line", @buffer.line(1)
    end

    def test_paste_line_after_moves_cursor_to_new_line
      @register.yank("new line", linewise: true)

      @operator.paste_after

      assert_equal 1, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end

    def test_paste_multiple_lines_after
      @register.yank("line1\nline2", linewise: true)

      @operator.paste_after

      assert_equal 3, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
      assert_equal "line1", @buffer.line(1)
      assert_equal "line2", @buffer.line(2)
    end

    def test_paste_with_named_register
      @register.yank("named content", linewise: true, name: "a")

      @operator.paste_after(pending_register: "a")

      assert_equal "named content", @buffer.line(1)
    end
  end

  class TestPasteBeforeLinewise < TestPasteOperator
    def test_paste_line_before_inserts_above_cursor
      @register.yank("new line", linewise: true)

      result = @operator.paste_before

      assert_equal :done, result
      assert_equal 2, @buffer.line_count
      assert_equal "new line", @buffer.line(0)
      assert_equal "hello world", @buffer.line(1)
    end

    def test_paste_line_before_keeps_cursor_row
      @register.yank("new line", linewise: true)

      @operator.paste_before

      assert_equal 0, @window.cursor_row
      assert_equal 0, @window.cursor_col
    end
  end

  class TestPasteAfterCharwise < TestPasteOperator
    def test_paste_char_after_inserts_after_cursor
      @window.cursor_col = 5
      @register.yank("X", linewise: false)

      @operator.paste_after

      assert_equal "hello Xworld", @buffer.line(0)
    end

    def test_paste_char_after_moves_cursor_to_end_of_pasted_text
      @window.cursor_col = 5
      @register.yank("ABC", linewise: false)

      @operator.paste_after

      assert_equal 8, @window.cursor_col
    end

    def test_paste_char_after_on_empty_line
      @buffer.lines[0] = ""
      @register.yank("text", linewise: false)

      @operator.paste_after

      assert_equal "text", @buffer.line(0)
    end
  end

  class TestPasteBeforeCharwise < TestPasteOperator
    def test_paste_char_before_inserts_before_cursor
      @window.cursor_col = 6
      @register.yank("X", linewise: false)

      @operator.paste_before

      assert_equal "hello Xworld", @buffer.line(0)
    end

    def test_paste_char_before_moves_cursor_to_end_of_pasted_text
      @window.cursor_col = 6
      @register.yank("ABC", linewise: false)

      @operator.paste_before

      assert_equal 8, @window.cursor_col
    end
  end

  class TestPasteMultilineCharwise < TestPasteOperator
    def test_paste_multiline_char_after
      @window.cursor_col = 4
      @register.yank("X\nY", linewise: false)

      @operator.paste_after

      assert_equal 2, @buffer.line_count
      assert_equal "helloX", @buffer.line(0)
      assert_equal "Y world", @buffer.line(1)
    end

    def test_paste_multiline_char_before
      @window.cursor_col = 6
      @register.yank("A\nB\nC", linewise: false)

      @operator.paste_before

      assert_equal 3, @buffer.line_count
      assert_equal "hello A", @buffer.line(0)
      assert_equal "B", @buffer.line(1)
      assert_equal "Cworld", @buffer.line(2)
    end

    def test_paste_multiline_moves_cursor_to_last_pasted_line
      @window.cursor_col = 4
      @register.yank("X\nY\nZ", linewise: false)

      @operator.paste_after

      assert_equal 2, @window.cursor_row
    end
  end

  class TestEmptyRegister < TestPasteOperator
    def test_paste_after_with_empty_register_does_nothing
      result = @operator.paste_after

      assert_equal :done, result
      assert_equal "hello world", @buffer.line(0)
    end

    def test_paste_before_with_empty_register_does_nothing
      result = @operator.paste_before

      assert_equal :done, result
      assert_equal "hello world", @buffer.line(0)
    end
  end

  class TestHandlePending < TestPasteOperator
    def test_handle_pending_returns_cancel
      # PasteOperator doesn't use handle_pending pattern
      result = @operator.handle_pending("x")

      assert_equal :cancel, result
    end
  end

  class TestPasteUndo < TestPasteOperator
    def setup
      super
      @undo_manager = Mui::UndoManager.new
      @buffer.undo_manager = @undo_manager
      @operator = Mui::KeyHandler::Operators::PasteOperator.new(
        buffer: @buffer,
        window: @window,
        register: @register,
        undo_manager: @undo_manager
      )
    end

    def test_linewise_paste_undos_as_single_action
      @register.yank("line1\nline2\nline3", linewise: true)
      @operator.paste_after

      assert_equal 4, @buffer.line_count

      @undo_manager.undo(@buffer)

      assert_equal 1, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
    end

    def test_linewise_paste_before_undos_as_single_action
      @register.yank("line1\nline2", linewise: true)
      @operator.paste_before

      assert_equal 3, @buffer.line_count

      @undo_manager.undo(@buffer)

      assert_equal 1, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
    end

    def test_charwise_multiline_paste_undos_as_single_action
      @register.yank("A\nB\nC", linewise: false)
      @window.cursor_col = 5
      @operator.paste_after

      assert_equal 3, @buffer.line_count

      @undo_manager.undo(@buffer)

      assert_equal 1, @buffer.line_count
      assert_equal "hello world", @buffer.line(0)
    end

    def test_charwise_single_line_paste_can_be_undone
      @register.yank("XYZ", linewise: false)
      @window.cursor_col = 5
      @operator.paste_after

      assert_equal "hello XYZworld", @buffer.line(0)

      @undo_manager.undo(@buffer)

      assert_equal "hello world", @buffer.line(0)
    end

    def test_charwise_single_line_paste_before_can_be_undone
      @register.yank("XYZ", linewise: false)
      @window.cursor_col = 6
      @operator.paste_before

      assert_equal "hello XYZworld", @buffer.line(0)

      @undo_manager.undo(@buffer)

      assert_equal "hello world", @buffer.line(0)
    end
  end
end
