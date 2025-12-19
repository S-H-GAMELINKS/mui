# frozen_string_literal: true

require "test_helper"

class TestKeyHandler < Minitest::Test
  class TestModuleLoading < Minitest::Test
    def test_motion_handler_module_is_loaded
      assert defined?(Mui::KeyHandler::Motions::MotionHandler)
    end

    def test_base_operator_is_loaded
      assert defined?(Mui::KeyHandler::Operators::BaseOperator)
    end

    def test_delete_operator_is_loaded
      assert defined?(Mui::KeyHandler::Operators::DeleteOperator)
    end

    def test_change_operator_is_loaded
      assert defined?(Mui::KeyHandler::Operators::ChangeOperator)
    end

    def test_yank_operator_is_loaded
      assert defined?(Mui::KeyHandler::Operators::YankOperator)
    end

    def test_paste_operator_is_loaded
      assert defined?(Mui::KeyHandler::Operators::PasteOperator)
    end

    def test_base_key_handler_is_loaded
      assert defined?(Mui::KeyHandler::Base)
    end

    def test_normal_mode_is_loaded
      assert defined?(Mui::KeyHandler::NormalMode)
    end

    def test_insert_mode_is_loaded
      assert defined?(Mui::KeyHandler::InsertMode)
    end

    def test_command_mode_is_loaded
      assert defined?(Mui::KeyHandler::CommandMode)
    end

    def test_visual_mode_is_loaded
      assert defined?(Mui::KeyHandler::VisualMode)
    end

    def test_visual_line_mode_is_loaded
      assert defined?(Mui::KeyHandler::VisualLineMode)
    end

    def test_search_mode_is_loaded
      assert defined?(Mui::KeyHandler::SearchMode)
    end
  end

  class TestModeInheritance < Minitest::Test
    def test_normal_mode_inherits_from_base
      assert_operator Mui::KeyHandler::NormalMode, :<, Mui::KeyHandler::Base
    end

    def test_insert_mode_inherits_from_base
      assert_operator Mui::KeyHandler::InsertMode, :<, Mui::KeyHandler::Base
    end

    def test_command_mode_inherits_from_base
      assert_operator Mui::KeyHandler::CommandMode, :<, Mui::KeyHandler::Base
    end

    def test_visual_mode_inherits_from_base
      assert_operator Mui::KeyHandler::VisualMode, :<, Mui::KeyHandler::Base
    end

    def test_visual_line_mode_inherits_from_base
      assert_operator Mui::KeyHandler::VisualLineMode, :<, Mui::KeyHandler::Base
    end

    def test_search_mode_inherits_from_base
      assert_operator Mui::KeyHandler::SearchMode, :<, Mui::KeyHandler::Base
    end
  end

  class TestOperatorInheritance < Minitest::Test
    def test_delete_operator_inherits_from_base
      assert_operator Mui::KeyHandler::Operators::DeleteOperator, :<, Mui::KeyHandler::Operators::BaseOperator
    end

    def test_change_operator_inherits_from_base
      assert_operator Mui::KeyHandler::Operators::ChangeOperator, :<, Mui::KeyHandler::Operators::BaseOperator
    end

    def test_yank_operator_inherits_from_base
      assert_operator Mui::KeyHandler::Operators::YankOperator, :<, Mui::KeyHandler::Operators::BaseOperator
    end

    def test_paste_operator_inherits_from_base
      assert_operator Mui::KeyHandler::Operators::PasteOperator, :<, Mui::KeyHandler::Operators::BaseOperator
    end
  end
end
