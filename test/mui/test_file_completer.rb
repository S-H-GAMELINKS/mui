# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

class TestFileCompleter < Minitest::Test
  def setup
    @completer = Mui::FileCompleter.new
    @original_dir = Dir.pwd

    # Create temporary directory for testing
    @test_dir = Dir.mktmpdir("mui_file_completer_test")
    Dir.chdir(@test_dir)

    # Create test files and directories
    FileUtils.touch("file1.txt")
    FileUtils.touch("file2.rb")
    FileUtils.touch("another.txt")
    FileUtils.mkdir("subdir")
    FileUtils.touch("subdir/nested.txt")
    FileUtils.mkdir("subdir/deep")
    FileUtils.touch(".hidden")
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@test_dir)
  end

  class TestCompleteEmptyPath < TestFileCompleter
    def test_complete_with_empty_path_lists_current_directory
      result = @completer.complete("")

      assert_includes result, "file1.txt"
      assert_includes result, "file2.rb"
      assert_includes result, "another.txt"
      assert_includes result, "subdir/"
    end

    def test_complete_with_empty_path_excludes_hidden_files
      result = @completer.complete("")

      refute(result.any? { |f| f.start_with?(".") })
    end

    def test_complete_with_empty_path_adds_slash_to_directories
      result = @completer.complete("")

      assert_includes result, "subdir/"
    end
  end

  class TestCompletePartialFilename < TestFileCompleter
    def test_complete_with_partial_filename
      result = @completer.complete("file")

      assert_includes result, "file1.txt"
      assert_includes result, "file2.rb"
      refute_includes result, "another.txt"
    end

    def test_complete_with_exact_prefix
      result = @completer.complete("another")

      assert_equal ["another.txt"], result
    end

    def test_complete_with_no_match_returns_empty
      result = @completer.complete("nonexistent")

      assert_empty result
    end
  end

  class TestCompleteDirectoryPath < TestFileCompleter
    def test_complete_with_directory_path
      result = @completer.complete("subdir/")

      assert_includes result, "subdir/nested.txt"
      assert_includes result, "subdir/deep/"
    end

    def test_complete_with_directory_and_partial
      result = @completer.complete("subdir/n")

      assert_equal ["subdir/nested.txt"], result
    end

    def test_complete_with_directory_and_subdir_partial
      result = @completer.complete("subdir/d")

      assert_equal ["subdir/deep/"], result
    end
  end

  class TestCompleteNonexistentDirectory < TestFileCompleter
    def test_complete_with_nonexistent_directory_returns_empty
      result = @completer.complete("nonexistent/")

      assert_empty result
    end

    def test_complete_with_nonexistent_nested_path
      result = @completer.complete("foo/bar/baz")

      assert_empty result
    end
  end

  class TestCompleteAbsolutePath < TestFileCompleter
    def test_complete_with_absolute_path
      result = @completer.complete("#{@test_dir}/file")

      assert_includes result, "#{@test_dir}/file1.txt"
      assert_includes result, "#{@test_dir}/file2.rb"
    end

    def test_complete_with_absolute_directory
      result = @completer.complete("#{@test_dir}/subdir/")

      assert_includes result, "#{@test_dir}/subdir/nested.txt"
      assert_includes result, "#{@test_dir}/subdir/deep/"
    end
  end

  class TestCompleteSorting < TestFileCompleter
    def test_results_are_sorted
      result = @completer.complete("")

      assert_equal result.sort, result
    end
  end
end
