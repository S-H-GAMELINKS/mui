# frozen_string_literal: true

require "test_helper"

class TestColorManager < Minitest::Test
  def setup
    @manager = Mui::ColorManager.new
  end

  def test_register_pair
    pair1 = @manager.register_pair(:white, :black)
    assert_equal 1, pair1
  end

  def test_register_same_pair_returns_same_index
    pair1 = @manager.register_pair(:white, :black)
    pair2 = @manager.register_pair(:white, :black)
    assert_equal pair1, pair2
  end

  def test_register_different_pairs_returns_different_indices
    pair1 = @manager.register_pair(:white, :black)
    pair2 = @manager.register_pair(:black, :white)
    refute_equal pair1, pair2
  end

  def test_get_pair_index
    @manager.register_pair(:red, :blue)
    pair_index = @manager.get_pair_index(:red, :blue)
    assert_equal 1, pair_index
  end

  def test_color_map
    assert_equal 0, Mui::ColorManager::COLOR_MAP[:black]
    assert_equal 1, Mui::ColorManager::COLOR_MAP[:red]
    assert_equal 2, Mui::ColorManager::COLOR_MAP[:green]
    assert_equal 3, Mui::ColorManager::COLOR_MAP[:yellow]
    assert_equal 4, Mui::ColorManager::COLOR_MAP[:blue]
    assert_equal 5, Mui::ColorManager::COLOR_MAP[:magenta]
    assert_equal 6, Mui::ColorManager::COLOR_MAP[:cyan]
    assert_equal 7, Mui::ColorManager::COLOR_MAP[:white]
  end
end

class TestColorManagerColorCapability < Minitest::Test
  def test_256_color_support_detection
    adapter = Mui::TerminalAdapter::Test.new
    adapter.test_colors = 256
    manager = Mui::ColorManager.new(adapter:)

    assert manager.supports_256_colors
  end

  def test_8_color_fallback_detection
    adapter = Mui::TerminalAdapter::Test.new
    adapter.test_colors = 8
    manager = Mui::ColorManager.new(adapter:)

    refute manager.supports_256_colors
  end

  def test_extended_color_fallback_to_8_colors
    adapter = Mui::TerminalAdapter::Test.new
    adapter.test_colors = 8
    manager = Mui::ColorManager.new(adapter:)

    # solarized_blue -> blue (4)
    assert_equal 4, manager.color_code(:solarized_blue)
  end

  def test_basic_color_unchanged_in_8_color_mode
    adapter = Mui::TerminalAdapter::Test.new
    adapter.test_colors = 8
    manager = Mui::ColorManager.new(adapter:)

    # Basic colors should remain unchanged
    assert_equal 1, manager.color_code(:red)
    assert_equal 4, manager.color_code(:blue)
  end

  def test_backward_compatibility_without_adapter
    manager = Mui::ColorManager.new

    # adapter not specified assumes 256 colors
    assert manager.supports_256_colors
  end

  def test_no_color_support
    adapter = Mui::TerminalAdapter::Test.new
    adapter.test_has_colors = false
    adapter.test_colors = 0
    manager = Mui::ColorManager.new(adapter:)

    refute manager.supports_256_colors
  end

  def test_pair_limit_eviction
    adapter = Mui::TerminalAdapter::Test.new
    adapter.test_color_pairs = 3
    manager = Mui::ColorManager.new(adapter:)

    manager.register_pair(:white, :black)  # index 1
    manager.register_pair(:red, :black)    # index 2
    manager.register_pair(:green, :black)  # evicts white/black, index 3

    assert_nil manager.pairs[%i[white black]]
    assert_equal 2, manager.pairs[%i[red black]]
    assert_equal 3, manager.pairs[%i[green black]]
  end

  def test_lru_touch_prevents_eviction
    adapter = Mui::TerminalAdapter::Test.new
    adapter.test_color_pairs = 3
    manager = Mui::ColorManager.new(adapter:)

    manager.register_pair(:white, :black)  # index 1
    manager.register_pair(:red, :black)    # index 2
    manager.register_pair(:white, :black)  # touch, moves to end
    manager.register_pair(:green, :black)  # evicts red/black, index 3

    # white/black should still exist (was touched)
    assert_equal 1, manager.pairs[%i[white black]]
    assert_nil manager.pairs[%i[red black]]
    assert_equal 3, manager.pairs[%i[green black]]
  end

  def test_all_extended_colors_have_fallback
    Mui::ColorManager::EXTENDED_COLOR_MAP.each_key do |color|
      fallback = Mui::ColorManager::FALLBACK_MAP[color]
      assert_includes Mui::ColorManager::COLOR_MAP.keys, fallback,
                      "#{color} should have a valid 8-color fallback"
    end
  end
end

class TestMuiExtendedColors < Minitest::Test
  MUI_COLORS = %i[
    mui_bg mui_fg mui_comment mui_constant mui_identifier
    mui_statement mui_preproc mui_type mui_special mui_function
    mui_line_number mui_status_bg mui_visual
    mui_search mui_tab_bg mui_tab_active mui_error mui_info
  ].freeze

  def test_mui_extended_colors_exist
    MUI_COLORS.each do |color|
      assert Mui::ColorManager::EXTENDED_COLOR_MAP.key?(color),
             "#{color} should be defined in EXTENDED_COLOR_MAP"
    end
  end

  def test_mui_colors_fallback_to_8_colors
    adapter = Mui::TerminalAdapter::Test.new
    adapter.test_colors = 8
    manager = Mui::ColorManager.new(adapter:)

    # mui_constant (110) should fallback to cyan (6)
    assert_equal 6, manager.color_code(:mui_constant)

    # mui_statement (186) should fallback to yellow (3)
    assert_equal 3, manager.color_code(:mui_statement)
  end

  def test_mui_colors_use_256_palette
    manager = Mui::ColorManager.new

    assert_equal 236, manager.color_code(:mui_bg)
    assert_equal 253, manager.color_code(:mui_fg)
    assert_equal 110, manager.color_code(:mui_constant)
    assert_equal 186, manager.color_code(:mui_statement)
  end
end
