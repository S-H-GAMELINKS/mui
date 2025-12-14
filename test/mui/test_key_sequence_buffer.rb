# frozen_string_literal: true

require "test_helper"

class TestKeySequenceBuffer < Minitest::Test
  def setup
    @buffer = Mui::KeySequenceBuffer.new
  end

  def test_initial_state
    assert @buffer.empty?
    assert_equal 0, @buffer.length
    assert_nil @buffer.first
    assert_nil @buffer.last_input_time
  end

  def test_push_string_key
    assert @buffer.push("a")
    assert_equal ["a"], @buffer.to_a
    refute @buffer.empty?
    assert_equal 1, @buffer.length
  end

  def test_push_integer_key
    # ASCII 'a' = 97
    assert @buffer.push(97)
    assert_equal ["a"], @buffer.to_a
  end

  def test_push_special_key
    # Enter key
    assert @buffer.push(Mui::KeyCode::ENTER_CR)
    assert_equal ["\r"], @buffer.to_a
  end

  def test_push_multiple_keys
    @buffer.push("a")
    @buffer.push("b")
    @buffer.push("c")

    assert_equal %w[a b c], @buffer.to_a
    assert_equal 3, @buffer.length
  end

  def test_push_invalid_key_returns_false
    refute @buffer.push(nil)
    assert @buffer.empty?
  end

  def test_clear
    @buffer.push("a")
    @buffer.push("b")
    refute @buffer.empty?

    @buffer.clear
    assert @buffer.empty?
    assert_nil @buffer.last_input_time
  end

  def test_first
    @buffer.push("a")
    @buffer.push("b")

    assert_equal "a", @buffer.first
    # first doesn't remove the key
    assert_equal %w[a b], @buffer.to_a
  end

  def test_shift
    @buffer.push("a")
    @buffer.push("b")

    assert_equal "a", @buffer.shift
    assert_equal ["b"], @buffer.to_a

    assert_equal "b", @buffer.shift
    assert @buffer.empty?
    assert_nil @buffer.last_input_time
  end

  def test_shift_on_empty
    assert_nil @buffer.shift
  end

  def test_to_a_returns_copy
    @buffer.push("a")
    array = @buffer.to_a
    array << "b"

    assert_equal ["a"], @buffer.to_a
  end

  def test_size_alias
    @buffer.push("a")
    assert_equal @buffer.length, @buffer.size
  end

  def test_last_input_time_updated_on_push
    assert_nil @buffer.last_input_time

    @buffer.push("a")
    time1 = @buffer.last_input_time
    refute_nil time1

    sleep 0.01
    @buffer.push("b")
    time2 = @buffer.last_input_time

    assert time2 > time1
  end

  def test_timeout_when_empty
    refute @buffer.timeout?(1000)
  end

  def test_timeout_immediately_after_push
    @buffer.push("a")
    refute @buffer.timeout?(1000) # 1 second
  end

  def test_timeout_after_delay
    @buffer.push("a")

    # Manually set last_input_time to simulate delay
    @buffer.instance_variable_set(:@last_input_time, Time.now - 2)

    assert @buffer.timeout?(1000) # 1 second, but 2 seconds have passed
  end

  def test_timeout_not_exceeded
    @buffer.push("a")

    # Manually set last_input_time to simulate small delay
    @buffer.instance_variable_set(:@last_input_time, Time.now - 0.5)

    refute @buffer.timeout?(1000) # 1 second, only 0.5 seconds passed
  end

  def test_elapsed_ms_when_empty
    assert_nil @buffer.elapsed_ms
  end

  def test_elapsed_ms_after_push
    @buffer.push("a")
    elapsed = @buffer.elapsed_ms

    refute_nil elapsed
    assert elapsed >= 0
    assert elapsed < 100 # Should be very small
  end
end
