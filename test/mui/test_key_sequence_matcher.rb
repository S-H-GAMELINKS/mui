# frozen_string_literal: true

require "test_helper"

class TestKeySequenceMatcher < Minitest::Test
  def setup
    @handler_gd = proc { :goto_definition }
    @handler_gr = proc { :goto_references }
    @handler_g = proc { :g_prefix }
    @handler_single = proc { :single_key }

    @keymaps = {
      normal: {
        Mui::KeySequence.new("<Leader>gd") => @handler_gd,
        Mui::KeySequence.new("<Leader>gr") => @handler_gr,
        Mui::KeySequence.new("<Leader>g") => @handler_g,
        Mui::KeySequence.new("K") => @handler_single
      }
    }

    @matcher = Mui::KeySequenceMatcher.new(@keymaps, "\\")
  end

  def test_exact_match_single_key
    type, handler = @matcher.match(:normal, ["K"])

    assert_equal :exact, type
    assert_equal @handler_single, handler
  end

  def test_exact_match_multi_key
    type, handler = @matcher.match(:normal, ["\\", "g", "d"])

    assert_equal :exact, type
    assert_equal @handler_gd, handler
  end

  def test_exact_match_with_longer_sequences
    # <Leader>g matches exactly, but <Leader>gd and <Leader>gr are longer
    type, handler = @matcher.match(:normal, ["\\", "g"])

    assert_equal :exact, type
    assert_equal @handler_g, handler
  end

  def test_partial_match
    # Just <Leader> - could lead to <Leader>g, <Leader>gd, <Leader>gr
    type, handler = @matcher.match(:normal, ["\\"])

    assert_equal :partial, type
    assert_nil handler
  end

  def test_no_match
    type, handler = @matcher.match(:normal, %w[x y z])

    assert_equal :none, type
    assert_nil handler
  end

  def test_no_match_for_unknown_mode
    type, handler = @matcher.match(:unknown, ["K"])

    assert_equal :none, type
    assert_nil handler
  end

  def test_no_match_for_empty_input
    type, handler = @matcher.match(:normal, [])

    assert_equal :none, type
    assert_nil handler
  end

  def test_longer_sequences_true
    # After typing <Leader>, there are longer sequences (<Leader>g, <Leader>gd, etc.)
    assert @matcher.longer_sequences?(:normal, ["\\"])
  end

  def test_longer_sequences_after_partial
    # After typing <Leader>g, there are longer sequences (<Leader>gd, <Leader>gr)
    assert @matcher.longer_sequences?(:normal, ["\\", "g"])
  end

  def test_longer_sequences_false_after_complete
    # After typing <Leader>gd, no longer sequences
    refute @matcher.longer_sequences?(:normal, ["\\", "g", "d"])
  end

  def test_longer_sequences_false_no_match
    refute @matcher.longer_sequences?(:normal, ["x"])
  end

  def test_leader_key_expansion
    # Test with space as leader
    matcher_space = Mui::KeySequenceMatcher.new(@keymaps, " ")

    type, handler = matcher_space.match(:normal, [" ", "g", "d"])
    assert_equal :exact, type
    assert_equal @handler_gd, handler

    # Original backslash leader should not match
    type_backslash, = matcher_space.match(:normal, ["\\", "g", "d"])
    assert_equal :none, type_backslash
  end

  def test_match_returns_exact_even_with_longer_sequences
    # <Leader>g should return exact even though <Leader>gd exists
    # This allows immediate execution without waiting for timeout
    type, handler = @matcher.match(:normal, ["\\", "g"])

    assert_equal :exact, type
    assert_equal @handler_g, handler
  end
end
