# frozen_string_literal: true

require_relative "test_helper"

class TestMultiKeySequence < Minitest::Test
  class TestLeaderKeySequence < TestMultiKeySequence
    def test_leader_key_sequence_executes_handler
      runner = ScriptRunner.new
      executed = false

      # Register a keymap with leader key (default is backslash)
      Mui.keymap :normal, "<Leader>gd" do |_ctx|
        executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      # Type \gd (backslash + g + d)
      runner.type("\\gd")

      assert executed, "Leader key sequence handler should have been executed"
    end

    def test_custom_leader_key
      runner = ScriptRunner.new
      executed = false

      # Set leader key AFTER ScriptRunner created (reset_config! is called in constructor)
      Mui.config.set(:leader, " ") # Space as leader

      Mui.keymap :normal, "<Leader>f" do |_ctx|
        executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      # Type space + f
      runner.type(" f")

      assert executed, "Custom leader key sequence should work"
    ensure
      Mui.config.set(:leader, "\\") # Reset to default
    end

    def test_leader_with_multiple_keys
      runner = ScriptRunner.new
      executed = false

      Mui.keymap :normal, "<Leader>ff" do |_ctx|
        executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      runner.type("\\ff")

      assert executed, "Multi-key leader sequence should work"
    end
  end

  class TestCtrlKeySequence < TestMultiKeySequence
    def test_ctrl_key_sequence
      runner = ScriptRunner.new
      executed = false

      Mui.keymap :normal, "<C-x>s" do |_ctx|
        executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      # Type Ctrl-x (0x18) + s
      runner.editor.handle_key(0x18)
      runner.editor.handle_key("s")

      assert executed, "Ctrl key sequence should work"
    end

    def test_double_ctrl_sequence
      runner = ScriptRunner.new
      executed = false

      Mui.keymap :normal, "<C-x><C-s>" do |_ctx|
        executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      # Type Ctrl-x + Ctrl-s
      runner.editor.handle_key(0x18) # Ctrl-X
      runner.editor.handle_key(0x13) # Ctrl-S

      assert executed, "Double Ctrl sequence should work"
    end
  end

  class TestModeSpecificKeymaps < TestMultiKeySequence
    def test_insert_mode_keymap
      runner = ScriptRunner.new
      executed = false

      Mui.keymap :insert, "<C-l>" do |_ctx|
        executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      # Enter insert mode and press Ctrl-L
      runner.type("i")
      runner.editor.handle_key(0x0C) # Ctrl-L

      assert executed, "Insert mode keymap should work"
    end

    def test_visual_mode_keymap
      runner = ScriptRunner.new
      executed = false

      Mui.keymap :visual, "<Leader>s" do |_ctx|
        executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      # Enter visual mode and press leader + s
      runner.type("v\\s")

      assert executed, "Visual mode keymap should work"
    end
  end

  class TestBuiltinPriority < TestMultiKeySequence
    def test_builtin_dd_not_overridden
      runner = ScriptRunner.new
      plugin_executed = false

      # Try to override dd (should not work - builtin priority)
      Mui.keymap :normal, "dd" do |_ctx|
        plugin_executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      runner.type("iHello World<Esc>")
      runner.type("dd")

      # Builtin dd should have deleted the line
      refute plugin_executed, "Plugin should not override builtin dd"
      assert_equal 1, runner.editor.buffer.line_count
      assert_equal "", runner.editor.buffer.line(0)
    end

    def test_builtin_dw_not_overridden
      runner = ScriptRunner.new
      plugin_executed = false

      Mui.keymap :normal, "dw" do |_ctx|
        plugin_executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      runner.type("iHello World<Esc>0")
      runner.type("dw")

      refute plugin_executed, "Plugin should not override builtin dw"
      assert_equal "World", runner.editor.buffer.line(0)
    end
  end

  class TestPartialMatch < TestMultiKeySequence
    def test_partial_match_waits_for_more_keys
      runner = ScriptRunner.new
      executed = false

      Mui.keymap :normal, "<Leader>abc" do |_ctx|
        executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      # Type leader + a + b (partial match)
      runner.type("\\ab")

      # Should not have executed yet
      refute executed, "Partial match should wait for more keys"

      # Complete the sequence
      runner.type("c")

      assert executed, "Complete sequence should execute"
    end

    def test_exact_match_executes_immediately_when_unique
      runner = ScriptRunner.new
      short_executed = false
      long_executed = false

      Mui.keymap :normal, "<Leader>x" do |_ctx|
        short_executed = true
        nil
      end
      Mui.keymap :normal, "<Leader>xy" do |_ctx|
        long_executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      # Type leader + x (partial match with <Leader>xy)
      runner.type("\\x")

      # Should wait since there's a longer match possibility
      refute short_executed, "Should wait when longer match is possible"
      refute long_executed, "Longer sequence not typed yet"

      # Complete with y for longer sequence
      runner.type("y")

      refute short_executed, "Short sequence should not execute"
      assert long_executed, "Long sequence should execute"
    end
  end

  class TestHandlerWithContext < TestMultiKeySequence
    def test_handler_receives_context
      runner = ScriptRunner.new
      received_editor = nil
      received_buffer = nil
      received_window = nil

      Mui.keymap :normal, "<Leader>t" do |ctx|
        received_editor = ctx.editor
        received_buffer = ctx.buffer
        received_window = ctx.window
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      runner.type("\\t")

      assert_equal runner.editor, received_editor
      assert_equal runner.editor.buffer, received_buffer
      assert_equal runner.editor.window, received_window
    end

    def test_handler_can_modify_buffer
      runner = ScriptRunner.new

      Mui.keymap :normal, "<Leader>h" do |ctx|
        ctx.buffer.replace_line(0, "Modified by keymap")
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      runner.type("\\h")

      assert_equal "Modified by keymap", runner.editor.buffer.line(0)
    end

    def test_handler_can_set_message
      runner = ScriptRunner.new

      Mui.keymap :normal, "<Leader>m" do |_ctx|
        Mui::HandlerResult::Base.new(message: "Keymap executed!")
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      runner.type("\\m")

      assert_equal "Keymap executed!", runner.editor.message
    end
  end

  class TestTimeout < TestMultiKeySequence
    def test_timeout_passes_through_first_key
      Mui.config.set(:timeoutlen, 10) # Very short timeout
      runner = ScriptRunner.new
      executed = false

      Mui.keymap :normal, "<Leader>z" do |_ctx|
        executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      # Type leader and wait for timeout
      runner.editor.handle_key("\\")

      # Simulate timeout by sleeping
      sleep 0.02

      # Call check_timeout which editor.run would call
      handler = runner.editor.key_sequence_handler
      handler.check_timeout(:normal) if handler.pending?

      # Should have passed through (no sequence matched due to timeout)
      refute executed, "Should not execute after timeout with incomplete sequence"
    ensure
      Mui.config.set(:timeoutlen, 1000) # Reset to default
    end
  end

  class TestSingleKeyBackwardCompatibility < TestMultiKeySequence
    def test_single_key_keymap_still_works
      runner = ScriptRunner.new
      executed = false

      # Register single-key keymap (backward compatibility)
      Mui.keymap :normal, "Q" do |_ctx|
        executed = true
        nil
      end
      runner.editor.key_sequence_handler.rebuild_keymaps

      runner.type("Q")

      assert executed, "Single-key keymap should still work"
    end
  end
end
