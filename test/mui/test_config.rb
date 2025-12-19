# frozen_string_literal: true

require "test_helper"

class TestConfig < Minitest::Test
  def setup
    @config = Mui::Config.new
  end

  def test_default_colorscheme
    assert_equal "mui", @config.get(:colorscheme)
  end

  def test_set_and_get
    @config.set(:colorscheme, "mui")

    assert_equal "mui", @config.get(:colorscheme)
  end

  def test_set_with_string_key
    @config.set("colorscheme", "custom")

    assert_equal "custom", @config.get(:colorscheme)
  end

  def test_use_plugin
    @config.use_plugin("mui-lsp", "~> 0.1")

    assert_equal 1, @config.plugins.length
    assert_equal({ gem: "mui-lsp", version: "~> 0.1" }, @config.plugins.first)
  end

  def test_add_keymap
    block = proc { puts "test" }
    @config.add_keymap(:normal, "K", block)

    assert_equal block, @config.keymaps[:normal]["K"]
  end

  def test_load_file_nonexistent
    # Should not raise error when file doesn't exist
    @config.load_file("/nonexistent/path/.muirc")

    assert_equal "mui", @config.get(:colorscheme)
  end

  def test_load_file_with_dsl
    # Create a temporary config file
    require "tempfile"
    file = Tempfile.new([".muirc", ""])
    file.write('set :colorscheme, "mui"')
    file.close

    @config.load_file(file.path)

    assert_equal "mui", @config.get(:colorscheme)
  ensure
    file&.unlink
  end
end
