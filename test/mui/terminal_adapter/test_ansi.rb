# frozen_string_literal: true

require "test_helper"
require "stringio"

class TestTerminalAdapterAnsi < Minitest::Test
  # Input comes through a pipe, so reads and waits behave as they do on a
  # terminal; output goes to a StringIO, which has no winsize, so the adapter
  # falls back to 24x80.
  module AnsiHelper
    def setup
      @reader, @writer = IO.pipe
      @output = StringIO.new
      @adapter = Mui::TerminalAdapter::Ansi.new(input: @reader, output: @output)
    end

    def teardown
      @reader.close
      @writer.close
    end

    def type(bytes)
      @writer.write(bytes)
      @writer.flush
    end

    def output_since(mark)
      @output.string[mark..]
    end
  end

  class TestInheritance < Minitest::Test
    def test_inherits_from_base
      assert_operator Mui::TerminalAdapter::Ansi, :<, Mui::TerminalAdapter::Base
    end
  end

  class TestKeys < Minitest::Test
    include AnsiHelper

    def test_plain_byte
      type("a")

      assert_equal 97, @adapter.getch_nonblock
    end

    def test_nothing_to_read
      assert_nil @adapter.getch_nonblock
    end

    def test_arrow_keys
      type("\e[A\e[B\e[C\e[D")

      assert_equal Mui::KeyCode::KEY_UP, @adapter.getch_nonblock
      assert_equal Mui::KeyCode::KEY_DOWN, @adapter.getch_nonblock
      assert_equal Mui::KeyCode::KEY_RIGHT, @adapter.getch_nonblock
      assert_equal Mui::KeyCode::KEY_LEFT, @adapter.getch_nonblock
    end

    def test_application_mode_arrows
      type("\eOA")

      assert_equal Mui::KeyCode::KEY_UP, @adapter.getch_nonblock
    end

    def test_shift_tab_and_delete
      type("\e[Z\e[3~")

      assert_equal Mui::KeyCode::KEY_BTAB, @adapter.getch_nonblock
      assert_equal Mui::KeyCode::KEY_DC, @adapter.getch_nonblock
    end

    def test_lone_escape
      type("\e")

      assert_equal Mui::KeyCode::ESCAPE, @adapter.getch_nonblock
      assert_nil @adapter.getch_nonblock
    end

    def test_escape_then_ordinary_key
      type("\ex")

      assert_equal Mui::KeyCode::ESCAPE, @adapter.getch_nonblock
      assert_equal "x".ord, @adapter.getch_nonblock
    end

    def test_unknown_sequence_is_dropped
      type("\e[99~a")

      assert_equal "a".ord, @adapter.getch_nonblock
    end

    def test_utf8_character
      type("あ")

      assert_equal "あ", @adapter.getch_nonblock
    end

    def test_getch_waits_for_input
      Thread.new do
        sleep 0.05
        type("q")
      end

      assert_equal "q".ord, @adapter.getch
    end
  end

  class TestDrawing < Minitest::Test
    include AnsiHelper

    def setup
      super
      @adapter.init
    end

    def test_init_enters_alternate_screen
      assert_includes @output.string, "\e[?1049h"
    end

    def test_close_leaves_alternate_screen
      @adapter.close

      assert_includes @output.string, "\e[?1049l"
    end

    def test_refresh_draws_text_at_position
      @adapter.clear
      @adapter.setpos(2, 3)
      @adapter.addstr("hello")
      @adapter.refresh

      assert_includes @output.string, "\e[3;1H"
      assert_includes @output.string, "   hello"
    end

    def test_unchanged_screen_sends_no_rows
      @adapter.clear
      @adapter.setpos(0, 0)
      @adapter.addstr("same")
      @adapter.refresh
      mark = @output.string.length

      @adapter.clear
      @adapter.setpos(0, 0)
      @adapter.addstr("same")
      @adapter.refresh

      refute_includes output_since(mark), "same"
    end

    def test_only_changed_row_is_sent
      @adapter.clear
      @adapter.setpos(0, 0)
      @adapter.addstr("first")
      @adapter.setpos(1, 0)
      @adapter.addstr("second")
      @adapter.refresh
      mark = @output.string.length

      @adapter.clear
      @adapter.setpos(0, 0)
      @adapter.addstr("first")
      @adapter.setpos(1, 0)
      @adapter.addstr("changed")
      @adapter.refresh

      refute_includes output_since(mark), "first"
      assert_includes output_since(mark), "changed"
    end

    def test_touchwin_redraws_everything
      @adapter.clear
      @adapter.setpos(0, 0)
      @adapter.addstr("kept")
      @adapter.refresh
      mark = @output.string.length

      @adapter.touchwin

      assert_includes output_since(mark), "kept"
    end

    def test_color_pair_becomes_256_color_sgr
      @adapter.init_color_pair(1, 196, 21)
      @adapter.clear
      @adapter.setpos(0, 0)
      @adapter.with_color(1, bold: true) { @adapter.addstr("red") }
      @adapter.refresh

      assert_includes @output.string, "\e[0;1;38;5;196;48;5;21mred"
    end

    def test_highlight_is_reverse_video
      @adapter.clear
      @adapter.setpos(0, 0)
      @adapter.with_highlight { @adapter.addstr("sel") }
      @adapter.refresh

      assert_includes @output.string, "\e[0;7msel"
    end

    def test_wide_character_takes_two_columns
      @adapter.clear
      @adapter.setpos(0, 0)
      @adapter.addstr("あb")
      @adapter.refresh

      assert_includes @output.string, "あb"
    end

    def test_text_past_the_edge_is_cut
      @adapter.clear
      @adapter.setpos(0, 78)
      @adapter.addstr("xyz")
      @adapter.refresh

      assert_includes @output.string, "xy"
      refute_includes @output.string, "xyz"
    end

    def test_size_falls_back_to_80_by_24
      assert_equal 80, @adapter.width
      assert_equal 24, @adapter.height
    end
  end

  class TestDefault < Minitest::Test
    def test_env_selects_ansi
      original = ENV.fetch("MUI_TERMINAL", nil)
      ENV["MUI_TERMINAL"] = "ansi"

      assert_instance_of Mui::TerminalAdapter::Ansi, Mui::TerminalAdapter.default
    ensure
      ENV["MUI_TERMINAL"] = original
    end
  end
end
