# frozen_string_literal: true

require "test_helper"

class TestVersion < Minitest::Test
  class TestVersionConstant < Minitest::Test
    def test_version_is_defined
      assert Mui.const_defined?(:VERSION)
    end

    def test_version_is_string
      assert_instance_of String, Mui::VERSION
    end

    def test_version_is_not_empty
      refute_empty Mui::VERSION
    end

    def test_version_follows_semver_format
      # Should match x.y.z format
      assert_match(/\A\d+\.\d+\.\d+\z/, Mui::VERSION)
    end

    def test_version_can_be_compared
      parts = Mui::VERSION.split(".")

      assert_equal 3, parts.size
      parts.each do |part|
        assert_match(/\A\d+\z/, part)
      end
    end
  end

  class TestVersionValue < Minitest::Test
    def test_major_version_is_non_negative
      major = Mui::VERSION.split(".")[0].to_i

      assert_operator major, :>=, 0
    end

    def test_minor_version_is_non_negative
      minor = Mui::VERSION.split(".")[1].to_i

      assert_operator minor, :>=, 0
    end

    def test_patch_version_is_non_negative
      patch = Mui::VERSION.split(".")[2].to_i

      assert_operator patch, :>=, 0
    end
  end
end
