# frozen_string_literal: true

require_relative "../test_helper"

class TestUndoManager < Minitest::Test
  def setup
    @undo_manager = Mui::UndoManager.new
    @buffer = Mui::Buffer.new
    @buffer.lines[0] = +"hello world"
  end

  # Basic functionality

  def test_initial_state
    assert_equal 0, @undo_manager.undo_stack_size
    assert_equal 0, @undo_manager.redo_stack_size
    refute @undo_manager.can_undo?
    refute @undo_manager.can_redo?
  end

  def test_record_adds_to_undo_stack
    action = Mui::InsertCharAction.new(0, 0, "x")
    @undo_manager.record(action)

    assert_equal 1, @undo_manager.undo_stack_size
    assert @undo_manager.can_undo?
    refute @undo_manager.can_redo?
  end

  def test_undo_moves_action_to_redo_stack
    action = Mui::InsertCharAction.new(0, 0, "x")
    @undo_manager.record(action)
    @buffer.insert_char_without_record(0, 0, "x")

    @undo_manager.undo(@buffer)

    assert_equal 0, @undo_manager.undo_stack_size
    assert_equal 1, @undo_manager.redo_stack_size
    refute @undo_manager.can_undo?
    assert @undo_manager.can_redo?
  end

  def test_redo_moves_action_to_undo_stack
    action = Mui::InsertCharAction.new(0, 0, "x")
    @undo_manager.record(action)
    @buffer.insert_char_without_record(0, 0, "x")

    @undo_manager.undo(@buffer)
    @undo_manager.redo(@buffer)

    assert_equal 1, @undo_manager.undo_stack_size
    assert_equal 0, @undo_manager.redo_stack_size
    assert @undo_manager.can_undo?
    refute @undo_manager.can_redo?
  end

  def test_new_record_clears_redo_stack
    action1 = Mui::InsertCharAction.new(0, 0, "x")
    action2 = Mui::InsertCharAction.new(0, 1, "y")

    @undo_manager.record(action1)
    @buffer.insert_char_without_record(0, 0, "x")
    @undo_manager.undo(@buffer)

    assert_equal 1, @undo_manager.redo_stack_size

    @undo_manager.record(action2)

    assert_equal 0, @undo_manager.redo_stack_size
  end

  def test_undo_returns_false_when_empty
    refute @undo_manager.undo(@buffer)
  end

  def test_redo_returns_false_when_empty
    refute @undo_manager.redo(@buffer)
  end

  def test_undo_returns_true_on_success
    action = Mui::InsertCharAction.new(0, 0, "x")
    @undo_manager.record(action)
    @buffer.insert_char_without_record(0, 0, "x")

    assert @undo_manager.undo(@buffer)
  end

  def test_redo_returns_true_on_success
    action = Mui::InsertCharAction.new(0, 0, "x")
    @undo_manager.record(action)
    @buffer.insert_char_without_record(0, 0, "x")

    @undo_manager.undo(@buffer)

    assert @undo_manager.redo(@buffer)
  end

  # Stack size limit

  def test_stack_size_limit
    (Mui::UndoManager::MAX_STACK_SIZE + 10).times do |i|
      @undo_manager.record(Mui::InsertCharAction.new(0, i, "x"))
    end

    assert_equal Mui::UndoManager::MAX_STACK_SIZE, @undo_manager.undo_stack_size
  end

  # Group functionality

  def test_begin_group
    @undo_manager.begin_group
    assert @undo_manager.in_group?
  end

  def test_end_group_without_begin
    @undo_manager.end_group
    refute @undo_manager.in_group?
    assert_equal 0, @undo_manager.undo_stack_size
  end

  def test_group_combines_actions
    @undo_manager.begin_group
    @undo_manager.record(Mui::InsertCharAction.new(0, 0, "a"))
    @undo_manager.record(Mui::InsertCharAction.new(0, 1, "b"))
    @undo_manager.record(Mui::InsertCharAction.new(0, 2, "c"))
    @undo_manager.end_group

    # All three actions should be in one group
    assert_equal 1, @undo_manager.undo_stack_size
  end

  def test_empty_group_not_added
    @undo_manager.begin_group
    @undo_manager.end_group

    assert_equal 0, @undo_manager.undo_stack_size
  end

  def test_group_undo_reverses_all_actions
    @buffer.lines[0] = +""
    @undo_manager.begin_group
    @undo_manager.record(Mui::InsertCharAction.new(0, 0, "a"))
    @buffer.insert_char_without_record(0, 0, "a")
    @undo_manager.record(Mui::InsertCharAction.new(0, 1, "b"))
    @buffer.insert_char_without_record(0, 1, "b")
    @undo_manager.record(Mui::InsertCharAction.new(0, 2, "c"))
    @buffer.insert_char_without_record(0, 2, "c")
    @undo_manager.end_group

    assert_equal "abc", @buffer.line(0)

    @undo_manager.undo(@buffer)

    assert_equal "", @buffer.line(0)
  end

  def test_group_redo_reapplies_all_actions
    @buffer.lines[0] = +""
    @undo_manager.begin_group
    @undo_manager.record(Mui::InsertCharAction.new(0, 0, "a"))
    @buffer.insert_char_without_record(0, 0, "a")
    @undo_manager.record(Mui::InsertCharAction.new(0, 1, "b"))
    @buffer.insert_char_without_record(0, 1, "b")
    @undo_manager.record(Mui::InsertCharAction.new(0, 2, "c"))
    @buffer.insert_char_without_record(0, 2, "c")
    @undo_manager.end_group

    @undo_manager.undo(@buffer)
    @undo_manager.redo(@buffer)

    assert_equal "abc", @buffer.line(0)
  end

  # Multiple undo/redo

  def test_multiple_undo
    @buffer.lines[0] = +""
    @undo_manager.record(Mui::InsertCharAction.new(0, 0, "a"))
    @buffer.insert_char_without_record(0, 0, "a")
    @undo_manager.record(Mui::InsertCharAction.new(0, 1, "b"))
    @buffer.insert_char_without_record(0, 1, "b")
    @undo_manager.record(Mui::InsertCharAction.new(0, 2, "c"))
    @buffer.insert_char_without_record(0, 2, "c")

    assert_equal "abc", @buffer.line(0)

    @undo_manager.undo(@buffer)
    assert_equal "ab", @buffer.line(0)

    @undo_manager.undo(@buffer)
    assert_equal "a", @buffer.line(0)

    @undo_manager.undo(@buffer)
    assert_equal "", @buffer.line(0)
  end

  def test_multiple_redo
    @buffer.lines[0] = +""
    @undo_manager.record(Mui::InsertCharAction.new(0, 0, "a"))
    @buffer.insert_char_without_record(0, 0, "a")
    @undo_manager.record(Mui::InsertCharAction.new(0, 1, "b"))
    @buffer.insert_char_without_record(0, 1, "b")
    @undo_manager.record(Mui::InsertCharAction.new(0, 2, "c"))
    @buffer.insert_char_without_record(0, 2, "c")

    @undo_manager.undo(@buffer)
    @undo_manager.undo(@buffer)
    @undo_manager.undo(@buffer)

    assert_equal "", @buffer.line(0)

    @undo_manager.redo(@buffer)
    assert_equal "a", @buffer.line(0)

    @undo_manager.redo(@buffer)
    assert_equal "ab", @buffer.line(0)

    @undo_manager.redo(@buffer)
    assert_equal "abc", @buffer.line(0)
  end
end
