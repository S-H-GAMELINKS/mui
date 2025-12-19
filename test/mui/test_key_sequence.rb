# frozen_string_literal: true

require "test_helper"

class TestKeySequence < Minitest::Test
  def test_parse_simple_notation
    seq = Mui::KeySequence.new("abc")

    assert_equal %w[a b c], seq.keys
    assert_equal "abc", seq.notation
  end

  def test_parse_leader_notation
    seq = Mui::KeySequence.new("<Leader>gd")

    assert_equal [:leader, "g", "d"], seq.keys
  end

  def test_parse_ctrl_notation
    seq = Mui::KeySequence.new("<C-x><C-s>")

    assert_equal ["\x18", "\x13"], seq.keys
  end

  def test_parse_space_notation
    seq = Mui::KeySequence.new("<Space>w")

    assert_equal [" ", "w"], seq.keys
  end

  def test_normalize_with_leader
    seq = Mui::KeySequence.new("<Leader>gd")

    # With backslash as leader
    assert_equal ["\\", "g", "d"], seq.normalize("\\")

    # With space as leader
    assert_equal [" ", "g", "d"], seq.normalize(" ")
  end

  def test_normalize_without_leader
    seq = Mui::KeySequence.new("abc")

    assert_equal %w[a b c], seq.normalize("\\")
  end

  def test_length
    assert_equal 1, Mui::KeySequence.new("a").length
    assert_equal 3, Mui::KeySequence.new("abc").length
    assert_equal 3, Mui::KeySequence.new("<Leader>gd").length
    assert_equal 2, Mui::KeySequence.new("<C-x><C-s>").length
  end

  def test_leader
    assert_predicate Mui::KeySequence.new("<Leader>gd"), :leader?
    refute_predicate Mui::KeySequence.new("abc"), :leader?
    refute_predicate Mui::KeySequence.new("<C-x>"), :leader?
  end

  def test_single_key
    assert_predicate Mui::KeySequence.new("a"), :single_key?
    assert_predicate Mui::KeySequence.new("<Space>"), :single_key?
    refute_predicate Mui::KeySequence.new("ab"), :single_key?
    refute_predicate Mui::KeySequence.new("<Leader>g"), :single_key?
  end

  def test_equality
    seq1 = Mui::KeySequence.new("<Leader>gd")
    seq2 = Mui::KeySequence.new("<Leader>gd")
    seq3 = Mui::KeySequence.new("<Leader>gr")

    assert_equal seq1, seq2
    refute_equal seq1, seq3
  end

  def test_equality_with_different_notation_same_keys
    # Different notation but same keys
    seq1 = Mui::KeySequence.new("<C-x>")
    seq2 = Mui::KeySequence.new("<Ctrl-x>")

    assert_equal seq1, seq2
  end

  def test_hash_equality
    seq1 = Mui::KeySequence.new("<Leader>gd")
    seq2 = Mui::KeySequence.new("<Leader>gd")

    assert_equal seq1.hash, seq2.hash

    # Can be used as hash key
    hash = { seq1 => :handler }

    assert_equal :handler, hash[seq2]
  end

  def test_to_s
    seq = Mui::KeySequence.new("<Leader>gd")

    assert_equal "<Leader>gd", seq.to_s
  end

  def test_inspect
    seq = Mui::KeySequence.new("<Leader>gd")

    assert_includes seq.inspect, "Mui::KeySequence"
    assert_includes seq.inspect, "<Leader>gd"
  end

  def test_equality_with_non_key_sequence
    seq = Mui::KeySequence.new("abc")

    refute_equal seq, "abc"
    refute_equal seq, %w[a b c]
    refute_equal seq, nil
  end
end
