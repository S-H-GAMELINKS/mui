# frozen_string_literal: true

require "test_helper"

class TestSplitNode < Minitest::Test
  def setup
    @buffer1 = Mui::Buffer.new
    @buffer2 = Mui::Buffer.new
    @window1 = Mui::Window.new(@buffer1)
    @window2 = Mui::Window.new(@buffer2)
    @leaf1 = Mui::Layout::LeafNode.new(@window1)
    @leaf2 = Mui::Layout::LeafNode.new(@window2)
  end

  def test_split_returns_true
    node = Mui::Layout::SplitNode.new(direction: :horizontal)

    assert_predicate node, :split?
  end

  def test_leaf_returns_false
    node = Mui::Layout::SplitNode.new(direction: :horizontal)

    refute_predicate node, :leaf?
  end

  def test_windows_returns_all_windows
    node = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf1, @leaf2]
    )

    assert_equal [@window1, @window2], node.windows
  end

  def test_children_have_parent_set
    node = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf1, @leaf2]
    )

    assert_equal node, @leaf1.parent
    assert_equal node, @leaf2.parent
  end

  def test_find_window_node_finds_correct_child
    node = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf1, @leaf2]
    )

    assert_equal @leaf1, node.find_window_node(@window1)
    assert_equal @leaf2, node.find_window_node(@window2)
  end

  def test_find_window_node_returns_nil_for_unknown_window
    node = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf1, @leaf2]
    )
    other_window = Mui::Window.new(Mui::Buffer.new)

    assert_nil node.find_window_node(other_window)
  end

  def test_horizontal_split_divides_height
    node = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf1, @leaf2],
      ratio: 0.5
    )
    node.x = 0
    node.y = 0
    node.width = 80
    node.height = 24

    node.apply_geometry

    # height 24 - separator 1 = 23 available, split 50% = 11 + 12
    # First child: top half
    assert_equal 0, @window1.x
    assert_equal 0, @window1.y
    assert_equal 80, @window1.width
    assert_equal 11, @window1.height

    # Second child: bottom half (after separator at y=11)
    assert_equal 0, @window2.x
    assert_equal 12, @window2.y # 11 + 1 (separator)
    assert_equal 80, @window2.width
    assert_equal 12, @window2.height
  end

  def test_vertical_split_divides_width
    node = Mui::Layout::SplitNode.new(
      direction: :vertical,
      children: [@leaf1, @leaf2],
      ratio: 0.5
    )
    node.x = 0
    node.y = 0
    node.width = 80
    node.height = 24

    node.apply_geometry

    # width 80 - separator 1 = 79 available, split 50% = 39 + 40
    # First child: left half
    assert_equal 0, @window1.x
    assert_equal 0, @window1.y
    assert_equal 39, @window1.width
    assert_equal 24, @window1.height

    # Second child: right half (after separator at x=39)
    assert_equal 40, @window2.x # 39 + 1 (separator)
    assert_equal 0, @window2.y
    assert_equal 40, @window2.width
    assert_equal 24, @window2.height
  end

  def test_custom_ratio
    node = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf1, @leaf2],
      ratio: 0.25
    )
    node.x = 0
    node.y = 0
    node.width = 80
    node.height = 24

    node.apply_geometry

    # height 24 - separator 1 = 23 available
    # First child: 25% of 23 = 5.75 -> 5
    assert_equal 5, @window1.height
    # Second child: 75% of 23 = 23 - 5 = 18
    assert_equal 18, @window2.height
  end

  def test_single_child_takes_full_space
    node = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf1]
    )
    node.x = 10
    node.y = 20
    node.width = 80
    node.height = 24

    node.apply_geometry

    assert_equal 10, @window1.x
    assert_equal 20, @window1.y
    assert_equal 80, @window1.width
    assert_equal 24, @window1.height
  end

  def test_replace_child
    node = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf1, @leaf2]
    )

    new_buffer = Mui::Buffer.new
    new_window = Mui::Window.new(new_buffer)
    new_leaf = Mui::Layout::LeafNode.new(new_window)

    node.replace_child(@leaf1, new_leaf)

    assert_equal [new_leaf, @leaf2], node.children
    assert_equal node, new_leaf.parent
  end

  def test_remove_child
    node = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf1, @leaf2]
    )

    node.remove_child(@leaf1)

    assert_equal [@leaf2], node.children
  end

  def test_nested_split_calculates_correctly
    # Create nested layout:
    # +--------+|--------+
    # |        || window2|
    # |window1 |+--------+
    # |        || window3|
    # +--------+|--------+

    buffer3 = Mui::Buffer.new
    window3 = Mui::Window.new(buffer3)
    leaf3 = Mui::Layout::LeafNode.new(window3)

    right_split = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf2, leaf3],
      ratio: 0.5
    )

    root = Mui::Layout::SplitNode.new(
      direction: :vertical,
      children: [@leaf1, right_split],
      ratio: 0.5
    )

    root.x = 0
    root.y = 0
    root.width = 80
    root.height = 24

    root.apply_geometry

    # width 80 - separator 1 = 79, split 50% = 39 + 40
    # Window1: left half (39), full height
    assert_equal 0, @window1.x
    assert_equal 0, @window1.y
    assert_equal 39, @window1.width
    assert_equal 24, @window1.height

    # right_split gets width=40, height=24, starts at x=40
    # height 24 - separator 1 = 23, split 50% = 11 + 12

    # Window2: right half, top half
    assert_equal 40, @window2.x # 39 + 1 (separator)
    assert_equal 0, @window2.y
    assert_equal 40, @window2.width
    assert_equal 11, @window2.height

    # Window3: right half, bottom half
    assert_equal 40, window3.x
    assert_equal 12, window3.y # 11 + 1 (separator)
    assert_equal 40, window3.width
    assert_equal 12, window3.height
  end

  def test_separators_for_horizontal_split
    node = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf1, @leaf2],
      ratio: 0.5
    )
    node.x = 0
    node.y = 0
    node.width = 80
    node.height = 24
    node.apply_geometry

    seps = node.separators

    assert_equal 1, seps.size
    assert_equal :horizontal, seps[0][:type]
    assert_equal 0, seps[0][:x]
    assert_equal 11, seps[0][:y]  # After first window's height
    assert_equal 80, seps[0][:length]
  end

  def test_separators_for_vertical_split
    node = Mui::Layout::SplitNode.new(
      direction: :vertical,
      children: [@leaf1, @leaf2],
      ratio: 0.5
    )
    node.x = 0
    node.y = 0
    node.width = 80
    node.height = 24
    node.apply_geometry

    seps = node.separators

    assert_equal 1, seps.size
    assert_equal :vertical, seps[0][:type]
    assert_equal 39, seps[0][:x]  # After first window's width
    assert_equal 0, seps[0][:y]
    assert_equal 24, seps[0][:length]
  end

  def test_separators_for_nested_split
    buffer3 = Mui::Buffer.new
    window3 = Mui::Window.new(buffer3)
    leaf3 = Mui::Layout::LeafNode.new(window3)

    right_split = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf2, leaf3],
      ratio: 0.5
    )

    root = Mui::Layout::SplitNode.new(
      direction: :vertical,
      children: [@leaf1, right_split],
      ratio: 0.5
    )
    root.x = 0
    root.y = 0
    root.width = 80
    root.height = 24

    # Need to apply geometry first so child nodes have their positions set
    root.apply_geometry

    seps = root.separators

    assert_equal 2, seps.size
    # First separator: vertical (between left and right, at x=39)
    assert_equal :vertical, seps[0][:type]
    assert_equal 39, seps[0][:x]
    # Second separator: horizontal (in right split, at y=11)
    assert_equal :horizontal, seps[1][:type]
  end

  def test_find_window_in_nested_structure
    buffer3 = Mui::Buffer.new
    window3 = Mui::Window.new(buffer3)
    leaf3 = Mui::Layout::LeafNode.new(window3)

    right_split = Mui::Layout::SplitNode.new(
      direction: :horizontal,
      children: [@leaf2, leaf3]
    )

    root = Mui::Layout::SplitNode.new(
      direction: :vertical,
      children: [@leaf1, right_split]
    )

    assert_equal @leaf1, root.find_window_node(@window1)
    assert_equal @leaf2, root.find_window_node(@window2)
    assert_equal leaf3, root.find_window_node(window3)
  end
end
