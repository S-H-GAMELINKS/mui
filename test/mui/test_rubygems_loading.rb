# frozen_string_literal: true

require "test_helper"

class TestRubygemsLoading < Minitest::Test
  def setup
    Mui.reset_config!
  end

  def teardown
    Mui.reset_config!
  end

  def test_load_real_gem_from_rubygems
    # Use a lightweight existing gem (rake is commonly installed)
    Mui.use "rake"

    # install_and_load should not raise errors
    Mui.plugin_manager.install_and_load

    assert Mui.plugin_manager.installed?
  end

  def test_load_gem_with_version_constraint
    Mui.use "rake", ">= 13.0"

    Mui.plugin_manager.install_and_load

    assert Mui.plugin_manager.installed?
  end

  def test_load_nonexistent_gem_does_not_crash
    Mui.use "nonexistent-gem-that-does-not-exist-12345"

    # Should warn but not crash
    _out, = capture_io do
      Mui.plugin_manager.install_and_load
    end

    # Either a warning is shown or the gem is not found silently
    # The important thing is that it doesn't crash
    assert Mui.plugin_manager.installed?
  end
end
