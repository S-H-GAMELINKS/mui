# frozen_string_literal: true

require "test_helper"

class TestAutocmd < Minitest::Test
  def setup
    @autocmd = Mui::Autocmd.new
    @buffer = MockBuffer.new(%w[line1 line2])
    @buffer.instance_variable_set(:@file_path, "/path/to/test.rb")
    def @buffer.file_path
      @file_path
    end
    @window = MockWindow.new(@buffer)
    @editor = MockEditor.new(@buffer, @window)
    @context = Mui::CommandContext.new(editor: @editor, buffer: @buffer, window: @window)
  end

  def test_register_valid_event
    called = false
    @autocmd.register(:BufEnter) { called = true }

    @autocmd.trigger(:BufEnter, @context)

    assert called
  end

  def test_register_raises_for_unknown_event
    assert_raises(ArgumentError) do
      @autocmd.register(:UnknownEvent) {}
    end
  end

  def test_trigger_with_string_pattern_match
    called = false
    @autocmd.register(:BufEnter, pattern: "*.rb") { called = true }

    @autocmd.trigger(:BufEnter, @context)

    assert called
  end

  def test_trigger_with_string_pattern_no_match
    called = false
    @autocmd.register(:BufEnter, pattern: "*.py") { called = true }

    @autocmd.trigger(:BufEnter, @context)

    refute called
  end

  def test_trigger_with_regexp_pattern_match
    called = false
    @autocmd.register(:BufEnter, pattern: /\.rb$/) { called = true }

    @autocmd.trigger(:BufEnter, @context)

    assert called
  end

  def test_trigger_with_regexp_pattern_no_match
    called = false
    @autocmd.register(:BufEnter, pattern: /\.py$/) { called = true }

    @autocmd.trigger(:BufEnter, @context)

    refute called
  end

  def test_trigger_calls_multiple_handlers
    calls = []
    @autocmd.register(:BufEnter) { calls << 1 }
    @autocmd.register(:BufEnter) { calls << 2 }

    @autocmd.trigger(:BufEnter, @context)

    assert_equal [1, 2], calls
  end

  def test_all_events_are_supported
    Mui::Autocmd::EVENTS.each do |event|
      @autocmd.register(event) {}
    end

    # Should not raise
    pass
  end
end
