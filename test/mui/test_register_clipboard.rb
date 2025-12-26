# frozen_string_literal: true

require "test_helper"

class TestRegisterClipboard < Minitest::Test
  def setup
    @register = Mui::Register.new
    @original_clipboard_setting = Mui.config.get(:clipboard)
    # Clear clipboard before each test
    Clipboard.clear
  end

  def teardown
    Mui.config.set(:clipboard, @original_clipboard_setting)
    Clipboard.clear
  end

  class TestClipboardDisabled < Minitest::Test
    def setup
      @register = Mui::Register.new
      Mui.config.set(:clipboard, nil)
      Clipboard.clear
    end

    def teardown
      Mui.config.set(:clipboard, nil)
      Clipboard.clear
    end

    def test_yank_does_not_sync_to_clipboard_when_disabled
      @register.yank("test content")

      assert_equal "", Clipboard.paste
    end

    def test_get_does_not_sync_from_clipboard_when_disabled
      Clipboard.copy("clipboard content")
      @register.yank("register content")

      assert_equal "register content", @register.get
    end
  end

  class TestClipboardEnabledWithUnnamed < Minitest::Test
    def setup
      @register = Mui::Register.new
      Mui.config.set(:clipboard, :unnamed)
      Clipboard.clear
    end

    def teardown
      Mui.config.set(:clipboard, nil)
      Clipboard.clear
    end

    def test_yank_syncs_to_clipboard
      @register.yank("yanked text")

      assert_equal "yanked text", Clipboard.paste
    end

    def test_yank_linewise_adds_newline_to_clipboard
      @register.yank("line content", linewise: true)

      assert_equal "line content\n", Clipboard.paste
    end

    def test_delete_syncs_to_clipboard
      @register.delete("deleted text")

      assert_equal "deleted text", Clipboard.paste
    end

    def test_delete_linewise_adds_newline_to_clipboard
      @register.delete("line content", linewise: true)

      assert_equal "line content\n", Clipboard.paste
    end

    def test_get_syncs_from_clipboard
      Clipboard.copy("from clipboard")

      assert_equal "from clipboard", @register.get
    end

    def test_get_with_trailing_newline_is_linewise
      Clipboard.copy("line from clipboard\n")

      assert_equal "line from clipboard", @register.get
      assert_predicate @register, :linewise?
    end

    def test_get_without_trailing_newline_is_charwise
      Clipboard.copy("char from clipboard")

      assert_equal "char from clipboard", @register.get
      refute_predicate @register, :linewise?
    end

    def test_linewise_syncs_from_clipboard
      Clipboard.copy("line content\n")

      assert_predicate @register, :linewise?
    end

    def test_named_register_yank_does_not_sync_to_clipboard
      @register.yank("named content", name: "a")

      assert_equal "", Clipboard.paste
    end

    def test_named_register_delete_does_not_sync_to_clipboard
      @register.delete("named content", name: "a")

      assert_equal "", Clipboard.paste
    end

    def test_get_named_register_does_not_sync_from_clipboard
      Clipboard.copy("clipboard content")
      @register.yank("named content", name: "a")

      assert_equal "named content", @register.get(name: "a")
    end

    def test_clipboard_content_same_as_register_does_not_update
      @register.yank("same content")
      # Clipboard should have "same content" now
      # Calling get should not create a new register entry
      content = @register.get

      assert_equal "same content", content
    end
  end

  class TestClipboardEnabledWithUnnamedplus < Minitest::Test
    def setup
      @register = Mui::Register.new
      Mui.config.set(:clipboard, :unnamedplus)
      Clipboard.clear
    end

    def teardown
      Mui.config.set(:clipboard, nil)
      Clipboard.clear
    end

    def test_yank_syncs_to_clipboard
      @register.yank("yanked text")

      assert_equal "yanked text", Clipboard.paste
    end

    def test_get_syncs_from_clipboard
      Clipboard.copy("from clipboard")

      assert_equal "from clipboard", @register.get
    end
  end

  class TestClipboardMultilineContent < Minitest::Test
    def setup
      @register = Mui::Register.new
      Mui.config.set(:clipboard, :unnamedplus)
      Clipboard.clear
    end

    def teardown
      Mui.config.set(:clipboard, nil)
      Clipboard.clear
    end

    def test_yank_multiline_content
      @register.yank("line1\nline2\nline3")

      assert_equal "line1\nline2\nline3", Clipboard.paste
    end

    def test_get_multiline_content_from_clipboard
      Clipboard.copy("line1\nline2\nline3")

      assert_equal "line1\nline2\nline3", @register.get
      refute_predicate @register, :linewise?
    end

    def test_get_multiline_content_with_trailing_newline_is_linewise
      Clipboard.copy("line1\nline2\nline3\n")

      assert_equal "line1\nline2\nline3", @register.get
      assert_predicate @register, :linewise?
    end
  end

  class TestBlackHoleRegister < Minitest::Test
    def setup
      @register = Mui::Register.new
      Mui.config.set(:clipboard, :unnamedplus)
      Clipboard.clear
    end

    def teardown
      Mui.config.set(:clipboard, nil)
      Clipboard.clear
    end

    def test_yank_to_black_hole_does_not_sync_to_clipboard
      @register.yank("text", name: "_")

      assert_equal "", Clipboard.paste
    end

    def test_delete_to_black_hole_does_not_sync_to_clipboard
      @register.delete("text", name: "_")

      assert_equal "", Clipboard.paste
    end
  end
end
