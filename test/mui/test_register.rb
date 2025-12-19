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
      assert_empty @register
      assert_nil @register.get
    end

    def test_set_and_get_text
      @register.set("hello")

      assert_equal "hello", @register.get
      refute_empty @register
    end

    def test_set_linewise_flag
      @register.set("line content", linewise: true)

      assert_predicate @register, :linewise?
      assert_equal "line content", @register.get
    end

    def test_set_charwise_flag
      @register.set("char content", linewise: false)

      refute_predicate @register, :linewise?
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

  class TestYankMethod < Minitest::Test
    def setup
      @register = Mui::Register.new
    end

    def test_yank_saves_to_unnamed_register
      @register.yank("yanked text")

      assert_equal "yanked text", @register.get
    end

    def test_yank_saves_to_yank_register
      @register.yank("yanked text")

      assert_equal "yanked text", @register.get(name: "0")
    end

    def test_yank_linewise_flag
      @register.yank("line", linewise: true)

      assert_predicate @register, :linewise?
      assert @register.linewise?(name: "0")
    end

    def test_yank_to_named_register
      @register.yank("content", name: "a")

      assert_equal "content", @register.get(name: "a")
      assert_nil @register.get # unnamed not affected
      assert_nil @register.get(name: "0") # yank register not affected
    end

    def test_yank_to_black_hole_register_does_nothing
      @register.yank("text", name: "_")

      assert_nil @register.get
      assert_nil @register.get(name: "_")
      assert_nil @register.get(name: "0")
    end
  end

  class TestDeleteMethod < Minitest::Test
    def setup
      @register = Mui::Register.new
    end

    def test_delete_saves_to_unnamed_register
      @register.delete("deleted text")

      assert_equal "deleted text", @register.get
    end

    def test_delete_saves_to_delete_history
      @register.delete("deleted text")

      assert_equal "deleted text", @register.get(name: "1")
    end

    def test_delete_does_not_affect_yank_register
      @register.yank("yanked")
      @register.delete("deleted")

      assert_equal "yanked", @register.get(name: "0")
      assert_equal "deleted", @register.get # unnamed is overwritten
    end

    def test_delete_history_shift
      @register.delete("first")
      @register.delete("second")
      @register.delete("third")

      assert_equal "third", @register.get(name: "1")
      assert_equal "second", @register.get(name: "2")
      assert_equal "first", @register.get(name: "3")
    end

    def test_delete_history_max_9
      10.times { |i| @register.delete("delete#{i}") }

      assert_equal "delete9", @register.get(name: "1")
      assert_equal "delete1", @register.get(name: "9")
      assert_nil @register.get(name: "10") # invalid register
    end

    def test_delete_linewise_flag
      @register.delete("line", linewise: true)

      assert_predicate @register, :linewise?
      assert @register.linewise?(name: "1")
    end

    def test_delete_to_named_register
      @register.delete("content", name: "a")

      assert_equal "content", @register.get(name: "a")
      assert_nil @register.get # unnamed not affected
      assert_nil @register.get(name: "1") # delete history not affected
    end

    def test_delete_to_black_hole_register_does_nothing
      @register.delete("text", name: "_")

      assert_nil @register.get
      assert_nil @register.get(name: "_")
      assert_nil @register.get(name: "1")
    end
  end

  class TestSpecialRegisters < Minitest::Test
    def setup
      @register = Mui::Register.new
    end

    def test_unnamed_register_alias
      @register.set("content")

      assert_equal "content", @register.get(name: '"')
    end

    def test_black_hole_register_always_empty
      assert @register.empty?(name: "_")
      refute @register.linewise?(name: "_")
    end

    def test_empty_delete_history_register
      assert @register.empty?(name: "1")
      assert_nil @register.get(name: "5")
      refute @register.linewise?(name: "3")
    end

    def test_invalid_register_returns_nil
      assert_nil @register.get(name: "invalid")
      refute @register.linewise?(name: "invalid")
    end
  end
end
