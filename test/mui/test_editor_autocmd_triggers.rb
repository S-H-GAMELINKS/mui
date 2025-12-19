# frozen_string_literal: true

require "test_helper"
require "tempfile"

class TestEditorAutocmdTriggers < Minitest::Test
  include MuiTestHelper

  def setup
    @adapter = Mui::TerminalAdapter::Test.new
    @editor = Mui::Editor.new(nil, adapter: @adapter, load_config: false)
  end

  def test_trigger_autocmd_is_public_method
    assert_respond_to @editor, :trigger_autocmd
    assert_includes @editor.public_methods, :trigger_autocmd
  end

  def test_trigger_autocmd_triggers_registered_handlers
    called = false
    @editor.autocmd.register(:BufEnter) { called = true }

    @editor.trigger_autocmd(:BufEnter)

    assert called
  end

  def test_trigger_autocmd_passes_context_with_editor
    received_editor = nil
    @editor.autocmd.register(:BufEnter) { |ctx| received_editor = ctx.editor }

    @editor.trigger_autocmd(:BufEnter)

    assert_equal @editor, received_editor
  end

  def test_trigger_autocmd_passes_context_with_buffer
    received_buffer = nil
    @editor.autocmd.register(:BufEnter) { |ctx| received_buffer = ctx.buffer }

    @editor.trigger_autocmd(:BufEnter)

    assert_equal @editor.buffer, received_buffer
  end

  def test_trigger_autocmd_passes_context_with_window
    received_window = nil
    @editor.autocmd.register(:BufEnter) { |ctx| received_window = ctx.window }

    @editor.trigger_autocmd(:BufEnter)

    assert_equal @editor.window, received_window
  end
end

class TestTextChangedAutocmdTrigger < Minitest::Test
  include MuiTestHelper

  def setup
    @adapter = Mui::TerminalAdapter::Test.new
    @editor = Mui::Editor.new(nil, adapter: @adapter, load_config: false)
  end

  def test_text_changed_triggered_on_insert
    text_changed_count = 0
    @editor.autocmd.register(:TextChanged) { text_changed_count += 1 }

    # Enter insert mode
    @editor.handle_key("i")

    # Type a character (modifies buffer)
    @editor.handle_key("a")

    assert_operator text_changed_count, :>=, 1
  end

  def test_text_changed_triggered_when_buffer_content_changes
    text_changed_count = 0
    @editor.autocmd.register(:TextChanged) { text_changed_count += 1 }

    # Enter insert mode
    @editor.handle_key("i")

    initial_count = text_changed_count

    # Type characters
    @editor.handle_key("h")
    @editor.handle_key("e")
    @editor.handle_key("l")
    @editor.handle_key("l")
    @editor.handle_key("o")

    assert_operator text_changed_count, :>, initial_count
  end

  def test_text_changed_not_triggered_on_movement_only
    # First, add some content so we can move around
    @editor.handle_key("i")
    @editor.handle_key("a")
    @editor.handle_key("b")
    @editor.handle_key("c")
    @editor.handle_key(27) # Escape

    text_changed_count = 0
    @editor.autocmd.register(:TextChanged) { text_changed_count += 1 }

    # Movement keys shouldn't trigger TextChanged
    @editor.handle_key("h")
    @editor.handle_key("l")
    @editor.handle_key("0")
    @editor.handle_key("$")

    assert_equal 0, text_changed_count
  end
end

class TestBufEnterAutocmdTrigger < Minitest::Test
  include MuiTestHelper

  def setup
    @adapter = Mui::TerminalAdapter::Test.new
    @editor = Mui::Editor.new(nil, adapter: @adapter, load_config: false)
  end

  def test_buf_enter_triggered_on_editor_init
    buf_enter_count = 0

    # Create new editor with autocmd pre-registered via config
    adapter = Mui::TerminalAdapter::Test.new
    Mui.autocmd(:BufEnter) { buf_enter_count += 1 }
    Mui::Editor.new(nil, adapter:, load_config: false)

    # BufEnter is triggered once during initialization
    assert_operator buf_enter_count, :>=, 1
  ensure
    # Clean up global config
    Mui.config.instance_variable_get(:@autocmds)[:BufEnter]&.clear
  end

  def test_buf_enter_triggered_on_buffer_switch
    # Create a second buffer by opening a new file
    temp_file = Tempfile.new(["test", ".txt"])
    temp_file.write("test content")
    temp_file.close

    begin
      # Split and edit a different file
      @editor.handle_key(":")
      "sp #{temp_file.path}".chars.each { |c| @editor.handle_key(c) }
      @editor.handle_key(13) # Enter

      buf_enter_count = 0
      @editor.autocmd.register(:BufEnter) { buf_enter_count += 1 }

      # Switch windows with Ctrl-W (will switch to different buffer)
      @editor.handle_key(23) # Ctrl-W
      @editor.handle_key("w")

      # When switching to a different buffer, BufEnter should trigger
      # Note: if both windows share the same buffer, BufEnter won't trigger
      # This test verifies the mechanism works when buffers are different
      assert_operator buf_enter_count, :>=, 1
    ensure
      temp_file.unlink
    end
  end
end

class TestBufWriteAutocmdTriggers < Minitest::Test
  include MuiTestHelper

  def setup
    @adapter = Mui::TerminalAdapter::Test.new
    @temp_file = Tempfile.new(["test", ".txt"])
    @temp_file.write("initial content")
    @temp_file.close
    @editor = Mui::Editor.new(@temp_file.path, adapter: @adapter, load_config: false)
  end

  def teardown
    @temp_file.unlink
  end

  def test_buf_write_pre_triggered_before_save
    events = []
    @editor.autocmd.register(:BufWritePre) { events << :pre }
    @editor.autocmd.register(:BufWritePost) { events << :post }

    # Add some content and save
    @editor.handle_key("i")
    @editor.handle_key("x")
    @editor.handle_key(27) # Escape

    # Execute :w command
    @editor.handle_key(":")
    "w".chars.each { |c| @editor.handle_key(c) }
    @editor.handle_key(13) # Enter

    assert_includes events, :pre
    assert_includes events, :post

    # Pre should come before post
    pre_index = events.index(:pre)
    post_index = events.index(:post)

    assert_operator pre_index, :<, post_index
  end

  def test_buf_write_pre_triggered_on_write_command
    pre_called = false
    @editor.autocmd.register(:BufWritePre) { pre_called = true }

    # Execute :w command
    @editor.handle_key(":")
    "w".chars.each { |c| @editor.handle_key(c) }
    @editor.handle_key(13) # Enter

    assert pre_called
  end

  def test_buf_write_post_triggered_after_save
    post_called = false
    @editor.autocmd.register(:BufWritePost) { post_called = true }

    # Execute :w command
    @editor.handle_key(":")
    "w".chars.each { |c| @editor.handle_key(c) }
    @editor.handle_key(13) # Enter

    assert post_called
  end

  def test_buf_write_events_receive_correct_context
    received_buffer = nil
    @editor.autocmd.register(:BufWritePre) { |ctx| received_buffer = ctx.buffer }

    # Execute :w command
    @editor.handle_key(":")
    "w".chars.each { |c| @editor.handle_key(c) }
    @editor.handle_key(13) # Enter

    assert_equal @editor.buffer, received_buffer
  end
end
