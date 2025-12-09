# frozen_string_literal: true

module Mui
  # Provides file path completion
  class FileCompleter
    def complete(partial_path)
      return list_current_directory if partial_path.empty?

      dir, prefix = split_path(partial_path)
      entries = list_directory(dir)

      entries.select { |entry| entry.start_with?(prefix) }
             .map { |entry| join_path(dir, entry) }
             .map { |path| format_path(path) }
    end

    private

    def split_path(path)
      if path.end_with?("/")
        [path, ""]
      else
        dir = File.dirname(path)
        dir = "" if dir == "."
        [dir, File.basename(path)]
      end
    end

    def list_directory(dir)
      target = dir.empty? ? "." : dir
      return [] unless Dir.exist?(target)

      Dir.entries(target)
         .reject { |e| e.start_with?(".") }
         .sort
    end

    def list_current_directory
      list_directory("").map { |entry| format_path(entry) }
    end

    def join_path(dir, entry)
      dir.empty? ? entry : File.join(dir, entry)
    end

    def format_path(path)
      full_path = path.start_with?("/") ? path : File.join(".", path)
      File.directory?(full_path) ? "#{path}/" : path
    end
  end
end
