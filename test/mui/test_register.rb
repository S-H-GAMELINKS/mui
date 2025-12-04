# frozen_string_literal: true

require "test_helper"

class TestRegister < Minitest::Test
  def setup
    @register = Mui::Register.new
  end

  class TestDefaultRegister < Minitest::Test
    def setup
      @register = Mui::Register.new
    end

    def test_initially_empty
      assert @register.empty?
      assert_nil @register.get
    end

    def test_set_and_get_text
      @register.set("hello")

      assert_equal "hello", @register.get
      refute @register.empty?
    end

    def test_set_linewise_flag
      @register.set("line content", linewise: true)

      assert @register.linewise?
      assert_equal "line content", @register.get
    end

    def test_set_charwise_flag
      @register.set("char content", linewise: false)

      refute @register.linewise?
    end

    def test_overwrite_previous_content
      @register.set("first")
      @register.set("second")

      assert_equal "second", @register.get
    end
  end

  class TestNamedRegisters < Minitest::Test
    def setup
      @register = Mui::Register.new
    end

    def test_set_and_get_named_register
      @register.set("content a", name: "a")

      assert_equal "content a", @register.get(name: "a")
    end

    def test_named_register_independent_of_default
      @register.set("default content")
      @register.set("named content", name: "a")

      assert_equal "default content", @register.get
      assert_equal "named content", @register.get(name: "a")
    end

    def test_named_register_linewise
      @register.set("line", linewise: true, name: "a")

      assert @register.linewise?(name: "a")
    end

    def test_empty_named_register
      assert @register.empty?(name: "a")
      assert_nil @register.get(name: "a")
    end

    def test_multiple_named_registers
      @register.set("content a", name: "a")
      @register.set("content b", name: "b")

      assert_equal "content a", @register.get(name: "a")
      assert_equal "content b", @register.get(name: "b")
    end
  end
end
