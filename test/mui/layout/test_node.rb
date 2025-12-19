# frozen_string_literal: true

require "test_helper"

class TestNode < Minitest::Test
  def test_leaf_returns_false
    node = Mui::Layout::Node.new

    refute_predicate node, :leaf?
  end

  def test_split_returns_false
    node = Mui::Layout::Node.new

    refute_predicate node, :split?
  end

  def test_windows_raises_method_not_overridden_error
    node = Mui::Layout::Node.new
    assert_raises(Mui::MethodNotOverriddenError) { node.windows }
  end

  def test_find_window_node_raises_method_not_overridden_error
    node = Mui::Layout::Node.new
    assert_raises(Mui::MethodNotOverriddenError) { node.find_window_node(nil) }
  end

  def test_apply_geometry_raises_method_not_overridden_error
    node = Mui::Layout::Node.new
    assert_raises(Mui::MethodNotOverriddenError) { node.apply_geometry }
  end

  def test_has_position_attributes
    node = Mui::Layout::Node.new
    node.x = 10
    node.y = 20
    node.width = 100
    node.height = 50

    assert_equal 10, node.x
    assert_equal 20, node.y
    assert_equal 100, node.width
    assert_equal 50, node.height
  end

  def test_has_parent_attribute
    node = Mui::Layout::Node.new
    parent = Mui::Layout::Node.new
    node.parent = parent

    assert_equal parent, node.parent
  end
end
