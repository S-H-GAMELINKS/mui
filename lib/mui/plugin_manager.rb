# frozen_string_literal: true

require "bundler/inline"

module Mui
  # Manages plugin lifecycle: loading, initialization, dependency resolution
  class PluginManager
    attr_reader :plugins, :loaded_plugins, :pending_gems

    def initialize
      @plugins = {}           # Registered plugin definitions (DSL/class)
      @loaded_plugins = []    # Loaded plugin names
      @pending_gems = []      # Gems waiting to be installed
      @installed = false
    end

    # Called from Mui.use - register gem (don't install yet)
    def add_gem(gem_name, version = nil)
      @pending_gems << { gem: gem_name, version: version }
    end

    # Register plugin definition (DSL or class)
    def register(name, plugin_class_or_block, dependencies: [])
      @plugins[name.to_sym] = {
        handler: plugin_class_or_block,
        dependencies: dependencies.map(&:to_sym)
      }
    end

    # Called during Editor initialization - install and load all at once
    def install_and_load
      return if @installed

      install_gems unless @pending_gems.empty?
      load_all_plugins
      @installed = true
    end

    def installed?
      @installed
    end

    private

    def install_gems
      gems = @pending_gems
      gemfile do
        source "https://rubygems.org"
        gems.each do |g|
          if g[:version]
            gem g[:gem], g[:version]
          else
            gem g[:gem]
          end
        end
      end
    rescue Bundler::GemNotFound => e
      warn "Plugin gem not found: #{e.message}"
    rescue Gem::MissingSpecError => e
      warn "Plugin gem not found: #{e.message}"
    end

    def load_all_plugins
      # Sort by dependencies and load
      sorted_plugins = topological_sort(@plugins)
      sorted_plugins.each { |name| load_plugin(name) }
    end

    def load_plugin(name)
      return if @loaded_plugins.include?(name)

      plugin_def = @plugins[name]
      return unless plugin_def

      instance = instantiate_plugin(plugin_def[:handler])
      instance.setup if instance.respond_to?(:setup)
      @loaded_plugins << name
    end

    def instantiate_plugin(handler)
      case handler
      when Class
        handler.new
      when Proc
        handler.call
        nil
      end
    end

    def topological_sort(plugins)
      sorted = []
      visited = {}

      visit = lambda do |name|
        return if visited[name]

        visited[name] = true
        plugins[name]&.[](:dependencies)&.each { |dep| visit.call(dep) }
        sorted << name
      end

      plugins.each_key { |name| visit.call(name) }
      sorted
    end
  end
end
