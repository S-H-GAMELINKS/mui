# frozen_string_literal: true

require "test_helper"

class TestInsertCompletionState < Minitest::Test
  def setup
    @state = Mui::InsertCompletionState.new
  end

  class TestInitialize < TestInsertCompletionState
    def test_initially_inactive
      refute @state.active?
    end

    def test_initially_empty_items
      assert_empty @state.items
    end

    def test_initially_zero_selected_index
      assert_equal 0, @state.selected_index
    end

    def test_initially_empty_prefix
      assert_equal "", @state.prefix
    end
  end

  class TestStart < TestInsertCompletionState
    def test_start_activates_with_items
      @state.start([{ label: "foo" }], prefix: "f")

      assert @state.active?
    end

    def test_start_sets_items
      items = [{ label: "foo" }, { label: "bar" }]
      @state.start(items, prefix: "")

      assert_equal items, @state.items
    end

    def test_start_sets_prefix
      @state.start([{ label: "foo" }], prefix: "fo")

      assert_equal "fo", @state.prefix
    end

    def test_start_resets_selected_index_to_zero
      @state.start([{ label: "a" }, { label: "b" }, { label: "c" }], prefix: "")
      @state.select_next
      @state.select_next

      @state.start([{ label: "x" }, { label: "y" }], prefix: "")

      assert_equal 0, @state.selected_index
    end
  end

  class TestReset < TestInsertCompletionState
    def test_reset_clears_items
      @state.start([{ label: "foo" }], prefix: "f")

      @state.reset

      assert_empty @state.items
    end

    def test_reset_makes_inactive
      @state.start([{ label: "foo" }], prefix: "f")

      @state.reset

      refute @state.active?
    end

    def test_reset_clears_prefix
      @state.start([{ label: "foo" }], prefix: "fo")

      @state.reset

      assert_equal "", @state.prefix
    end

    def test_reset_resets_selected_index
      @state.start([{ label: "foo" }, { label: "bar" }], prefix: "")
      @state.select_next

      @state.reset

      assert_equal 0, @state.selected_index
    end
  end

  class TestSelectNext < TestInsertCompletionState
    def test_select_next_increments_index
      @state.start([{ label: "a" }, { label: "b" }, { label: "c" }], prefix: "")

      @state.select_next

      assert_equal 1, @state.selected_index
    end

    def test_select_next_wraps_around
      @state.start([{ label: "a" }, { label: "b" }, { label: "c" }], prefix: "")

      @state.select_next
      @state.select_next
      @state.select_next

      assert_equal 0, @state.selected_index
    end

    def test_select_next_does_nothing_when_inactive
      @state.select_next

      assert_equal 0, @state.selected_index
    end
  end

  class TestSelectPrevious < TestInsertCompletionState
    def test_select_previous_decrements_index
      @state.start([{ label: "a" }, { label: "b" }, { label: "c" }], prefix: "")
      @state.select_next
      @state.select_next

      @state.select_previous

      assert_equal 1, @state.selected_index
    end

    def test_select_previous_wraps_around
      @state.start([{ label: "a" }, { label: "b" }, { label: "c" }], prefix: "")

      @state.select_previous

      assert_equal 2, @state.selected_index
    end

    def test_select_previous_does_nothing_when_inactive
      @state.select_previous

      assert_equal 0, @state.selected_index
    end
  end

  class TestCurrentItem < TestInsertCompletionState
    def test_current_item_returns_selected
      items = [{ label: "a" }, { label: "b" }, { label: "c" }]
      @state.start(items, prefix: "")

      assert_equal({ label: "a" }, @state.current_item)
    end

    def test_current_item_returns_selected_after_navigation
      items = [{ label: "a" }, { label: "b" }, { label: "c" }]
      @state.start(items, prefix: "")
      @state.select_next

      assert_equal({ label: "b" }, @state.current_item)
    end

    def test_current_item_returns_nil_when_inactive
      assert_nil @state.current_item
    end
  end

  class TestInsertText < TestInsertCompletionState
    def test_insert_text_returns_insert_text_if_present
      @state.start([{ label: "foo", insert_text: "foobar" }], prefix: "")

      assert_equal "foobar", @state.insert_text
    end

    def test_insert_text_falls_back_to_label
      @state.start([{ label: "foo" }], prefix: "")

      assert_equal "foo", @state.insert_text
    end

    def test_insert_text_returns_nil_when_inactive
      assert_nil @state.insert_text
    end
  end

  class TestActive < TestInsertCompletionState
    def test_active_false_with_empty_items
      refute @state.active?
    end

    def test_active_true_with_items
      @state.start([{ label: "foo" }], prefix: "f")

      assert @state.active?
    end

    def test_active_false_after_reset
      @state.start([{ label: "foo" }], prefix: "f")
      @state.reset

      refute @state.active?
    end
  end

  class TestUpdatePrefix < TestInsertCompletionState
    def test_update_prefix_filters_items
      items = [
        { label: "buffer" },
        { label: "buffer_word" },
        { label: "banana" }
      ]
      @state.start(items, prefix: "b")

      @state.update_prefix("buf")

      assert_equal 2, @state.items.length
      assert_equal "buffer", @state.items[0][:label]
      assert_equal "buffer_word", @state.items[1][:label]
    end

    def test_update_prefix_resets_selected_index
      items = [
        { label: "buffer" },
        { label: "banana" },
        { label: "buffer_word" }
      ]
      @state.start(items, prefix: "b")
      @state.select_next

      @state.update_prefix("buf")

      assert_equal 0, @state.selected_index
    end

    def test_update_prefix_updates_prefix
      items = [{ label: "buffer" }]
      @state.start(items, prefix: "b")

      @state.update_prefix("buf")

      assert_equal "buf", @state.prefix
    end

    def test_update_prefix_case_insensitive
      items = [
        { label: "Buffer" },
        { label: "BUFFER_WORD" },
        { label: "banana" }
      ]
      @state.start(items, prefix: "b")

      @state.update_prefix("buf")

      assert_equal 2, @state.items.length
    end

    def test_update_prefix_keeps_original_items
      items = [
        { label: "buffer" },
        { label: "banana" }
      ]
      @state.start(items, prefix: "b")

      @state.update_prefix("buf")

      assert_equal 2, @state.original_items.length
    end

    def test_update_prefix_same_prefix_does_nothing
      items = [{ label: "buffer" }, { label: "banana" }]
      @state.start(items, prefix: "b")
      @state.select_next

      @state.update_prefix("b")

      assert_equal 1, @state.selected_index
    end

    def test_update_prefix_removes_all_when_no_match
      items = [{ label: "buffer" }, { label: "banana" }]
      @state.start(items, prefix: "b")

      @state.update_prefix("xyz")

      refute @state.active?
    end

    def test_update_prefix_uses_insert_text_for_matching
      items = [
        { label: "display_label", insert_text: "buffer" },
        { label: "banana" }
      ]
      @state.start(items, prefix: "b")

      @state.update_prefix("buf")

      # Should match on label first, so only "display_label" won't match "buf"
      assert_equal 0, @state.items.length
    end
  end

  class TestNeedsClear < TestInsertCompletionState
    def test_initially_not_needs_clear
      refute @state.needs_clear?
    end

    def test_reset_sets_needs_clear_when_had_items
      @state.start([{ label: "foo" }], prefix: "f")

      @state.reset

      assert @state.needs_clear?
    end

    def test_reset_does_not_set_needs_clear_when_empty
      @state.reset

      refute @state.needs_clear?
    end

    def test_clear_needs_clear_resets_flag
      @state.start([{ label: "foo" }], prefix: "f")
      @state.reset

      @state.clear_needs_clear

      refute @state.needs_clear?
    end

    def test_start_does_not_affect_needs_clear
      @state.start([{ label: "foo" }], prefix: "f")

      refute @state.needs_clear?
    end

    def test_multiple_reset_calls_maintain_needs_clear
      @state.start([{ label: "foo" }], prefix: "f")
      @state.reset

      # Second reset when already empty should not change needs_clear
      @state.reset

      assert @state.needs_clear?
    end
  end
end
