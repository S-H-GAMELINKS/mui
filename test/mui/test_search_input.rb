# frozen_string_literal: true

require "test_helper"

class TestSearchInput < Minitest::Test
  def setup
    @search_input = Mui::SearchInput.new
  end

  def test_default_prompt
    assert_equal "/", @search_input.prompt
    assert_equal "", @search_input.buffer
    assert_equal "/", @search_input.to_s
  end

  def test_custom_prompt
    input = Mui::SearchInput.new("?")

    assert_equal "?", input.prompt
    assert_equal "?", input.to_s
  end

  def test_input
    @search_input.input("t")
    @search_input.input("e")
    @search_input.input("s")
    @search_input.input("t")

    assert_equal "test", @search_input.buffer
    assert_equal "test", @search_input.pattern
    assert_equal "/test", @search_input.to_s
  end

  def test_backspace
    @search_input.input("hello")
    @search_input.backspace

    assert_equal "hell", @search_input.buffer
  end

  def test_backspace_empty
    @search_input.backspace

    assert_equal "", @search_input.buffer
  end

  def test_clear
    @search_input.input("test")
    @search_input.clear

    assert_equal "", @search_input.buffer
    assert_empty @search_input
  end

  def test_set_prompt
    @search_input.set_prompt("?")

    assert_equal "?", @search_input.prompt
    assert_equal "?", @search_input.to_s
  end

  def test_empty
    assert_empty @search_input

    @search_input.input("a")

    refute_empty @search_input
  end
end
