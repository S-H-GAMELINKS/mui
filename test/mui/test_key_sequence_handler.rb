# frozen_string_literal: true

require "test_helper"

class TestKeySequenceHandler < Minitest::Test
  def setup
    Mui.reset_config!
    Mui.set :leader, "\\"
    Mui.set :timeoutlen, 1000

    @handler = Mui::KeySequenceHandler.new(Mui.config)
  end

  def teardown
    Mui.reset_config!
  end

  def test_leader_key_default
    Mui.reset_config!
    handler = Mui::KeySequenceHandler.new(Mui.config)

    assert_equal "\\", handler.leader_key
  end

  def test_leader_key_custom
    Mui.set :leader, " "
    handler = Mui::KeySequenceHandler.new(Mui.config)

    assert_equal " ", handler.leader_key
  end

  def test_timeout_ms_default
    Mui.reset_config!
    handler = Mui::KeySequenceHandler.new(Mui.config)

    assert_equal 1000, handler.timeout_ms
  end

  def test_timeout_ms_custom
    Mui.set :timeoutlen, 500
    handler = Mui::KeySequenceHandler.new(Mui.config)

    assert_equal 500, handler.timeout_ms
  end

  def test_register_and_match_single_key
    handler_proc = proc { :test }
    @handler.register(:normal, "K", handler_proc)

    type, handler = @handler.process("K", :normal)

    assert_equal :handled, type
    assert_equal handler_proc, handler
  end

  def test_register_and_match_multi_key
    handler_proc = proc { :goto_definition }
    @handler.register(:normal, "<Leader>gd", handler_proc)

    # First key: \
    type1, = @handler.process("\\", :normal)

    assert_equal :pending, type1

    # Second key: g
    type2, = @handler.process("g", :normal)

    assert_equal :pending, type2

    # Third key: d - complete match
    type3, handler = @handler.process("d", :normal)

    assert_equal :handled, type3
    assert_equal handler_proc, handler
  end

  def test_passthrough_on_no_match
    @handler.register(:normal, "<Leader>gd", proc { :test })

    # Input 'x' - no match
    type, key = @handler.process("x", :normal)

    assert_equal :passthrough, type
    assert_equal "x", key
  end

  def test_passthrough_after_failed_sequence
    @handler.register(:normal, "<Leader>gd", proc { :test })

    # Start with leader
    @handler.process("\\", :normal)

    # Then 'x' - no match possible
    type, key = @handler.process("x", :normal)

    assert_equal :passthrough, type
    assert_equal "\\", key # First key is passed through
  end

  def test_pending_with_exact_and_longer
    handler_g = proc { :g_command }
    handler_gd = proc { :goto_definition }

    @handler.register(:normal, "<Leader>g", handler_g)
    @handler.register(:normal, "<Leader>gd", handler_gd)

    # Input <Leader>
    type1, = @handler.process("\\", :normal)

    assert_equal :pending, type1

    # Input g - exact match exists, but longer sequence too
    type2, = @handler.process("g", :normal)

    assert_equal :pending, type2
    assert_predicate @handler, :pending?
  end

  def test_timeout_executes_pending_handler
    handler_g = proc { :g_command }
    handler_gd = proc { :goto_definition }

    @handler.register(:normal, "<Leader>g", handler_g)
    @handler.register(:normal, "<Leader>gd", handler_gd)

    @handler.process("\\", :normal)
    @handler.process("g", :normal)

    # Simulate timeout
    @handler.buffer.instance_variable_set(:@last_input_time, Time.now - 2)

    type, handler = @handler.check_timeout(:normal)

    assert_equal :handled, type
    assert_equal handler_g, handler
    refute_predicate @handler, :pending?
  end

  def test_timeout_passthrough_when_no_exact_match
    @handler.register(:normal, "<Leader>gd", proc { :test })

    @handler.process("\\", :normal)

    # Simulate timeout
    @handler.buffer.instance_variable_set(:@last_input_time, Time.now - 2)

    type, key = @handler.check_timeout(:normal)

    assert_equal :passthrough, type
    assert_equal "\\", key
    refute_predicate @handler, :pending?
  end

  def test_check_timeout_returns_nil_when_not_timed_out
    @handler.register(:normal, "<Leader>gd", proc { :test })

    @handler.process("\\", :normal)

    result = @handler.check_timeout(:normal)

    assert_nil result
  end

  def test_check_timeout_returns_nil_when_empty
    result = @handler.check_timeout(:normal)

    assert_nil result
  end

  def test_clear
    @handler.register(:normal, "<Leader>gd", proc { :test })
    @handler.process("\\", :normal)

    assert_predicate @handler, :pending?

    @handler.clear

    refute_predicate @handler, :pending?
  end

  def test_pending_keys_display
    @handler.register(:normal, "<Leader>gd", proc { :test })

    @handler.process("\\", :normal)
    @handler.process("g", :normal)

    assert_equal "\\g", @handler.pending_keys_display
  end

  def test_pending_keys_display_when_empty
    assert_nil @handler.pending_keys_display
  end

  def test_rebuild_keymaps
    Mui.keymap :normal, "<Leader>test" do
      :test_handler
    end

    @handler.rebuild_keymaps

    type1, = @handler.process("\\", :normal)

    assert_equal :pending, type1
  end

  def test_different_modes
    handler_normal = proc { :normal_handler }
    handler_insert = proc { :insert_handler }

    @handler.register(:normal, "<Leader>g", handler_normal)
    @handler.register(:insert, "<Leader>g", handler_insert)

    # Test normal mode
    @handler.process("\\", :normal)
    type1, handler1 = @handler.process("g", :normal)

    assert_equal :handled, type1
    assert_equal handler_normal, handler1

    # Test insert mode
    @handler.process("\\", :insert)
    type2, handler2 = @handler.process("g", :insert)

    assert_equal :handled, type2
    assert_equal handler_insert, handler2
  end

  def test_ctrl_key_sequence
    handler_proc = proc { :save }
    @handler.register(:normal, "<C-x><C-s>", handler_proc)

    # Ctrl-X = 24
    type1, = @handler.process(24, :normal)

    assert_equal :pending, type1

    # Ctrl-S = 19
    type2, handler = @handler.process(19, :normal)

    assert_equal :handled, type2
    assert_equal handler_proc, handler
  end
end
