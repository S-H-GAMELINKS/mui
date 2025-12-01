# frozen_string_literal: true

require_relative "mui/version"
require_relative "mui/screen"
require_relative "mui/input"
require_relative "mui/buffer"
require_relative "mui/window"
require_relative "mui/mode"
require_relative "mui/command_line"
require_relative "mui/motion"
require_relative "mui/editor"

module Mui
  class Error < StandardError; end
end
