# frozen_string_literal: true

# Test plugin for Mui plugin system
class MuiTestPlugin < Mui::Plugin
  name "test_plugin"

  def setup
    command :test_cmd do |ctx|
      ctx.set_message "Test plugin loaded!"
    end

    keymap :normal, "gt" do |ctx|
      ctx.set_message "Test keymap triggered!"
    end

    autocmd :BufEnter, pattern: "*.test" do |ctx|
      ctx.set_message "Test autocmd fired!"
    end
  end
end

Mui.plugin_manager.register(:test_plugin, MuiTestPlugin)
