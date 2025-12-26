# frozen_string_literal: true

require_relative "lib/mui/version"

Gem::Specification.new do |spec|
  spec.name = "mui"
  spec.version = Mui::VERSION
  spec.authors = ["S-H-GAMELINKS"]
  spec.email = ["gamelinks007@gmail.com"]

  spec.summary = "Mui - A Vim-like TUI editor written in Ruby"
  spec.description = "Mui (無為) is a Vim-like TUI text editor written in Ruby. Inspired by the concept of 'wu wei' (effortless action), it aims to be a minimal yet extensible editor."
  spec.homepage = "https://s-h-gamelinks.github.io/mui/"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/S-H-GAMELINKS/mui"
  spec.metadata["changelog_uri"] = "https://github.com/S-H-GAMELINKS/mui/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "clipboard", "~> 2.0"
  spec.add_dependency "curses"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
