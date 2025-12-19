# frozen_string_literal: true

require "test_helper"

class TestLeafNode < Minitest::Test
  def setup
    @buffer = Mui::Buffer.new
    @window = Mui::Window.new(@buffer)
  end

  def test_leaf_returns_true
    node = Mui::Layout::LeafNode.new(@window)

    assert_predicate node, :leaf?
  end

  def test_split_returns_false
    node = Mui::Layout::LeafNode.new(@window)

    refute_predicate node, :split?
  end

  def test_windows_returns_single_window
    node = Mui::Layout::LeafNode.new(@window)

    assert_equal [@window], node.windows
  end

  def test_find_window_node_returns_self_when_window_matches
    node = Mui::Layout::LeafNode.new(@window)

    assert_equal node, node.find_window_node(@window)
  end

  def test_find_window_node_returns_nil_when_window_does_not_match
    node = Mui::Layout::LeafNode.new(@window)
    other_window = Mui::Window.new(Mui::Buffer.new)

    assert_nil node.find_window_node(other_window)
  end

  def test_apply_geometry_sets_window_position
    node = Mui::Layout::LeafNode.new(@window)
    node.x = 10
    node.y = 20
    node.width = 80
    node.height = 24

    node.apply_geometry

    assert_equal 10, @window.x
    assert_equal 20, @window.y
    assert_equal 80, @window.width
    assert_equal 24, @window.height
  end

  def test_stores_window_reference
    node = Mui::Layout::LeafNode.new(@window)

    assert_equal @window, node.window
  end

  def test_window_is_accessible
    node = Mui::Layout::LeafNode.new(@window)
    new_window = Mui::Window.new(Mui::Buffer.new)
    node.window = new_window

    assert_equal new_window, node.window
  end
end
