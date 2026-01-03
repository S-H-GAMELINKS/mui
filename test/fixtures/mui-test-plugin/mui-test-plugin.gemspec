# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "mui-test-plugin"
  spec.version       = "0.1.0"
  spec.authors       = ["Test"]
  spec.summary       = "Test plugin for Mui"
  spec.files         = Dir["lib/**/*"]
  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.required_ruby_version = ">= 3.3.0"
end
