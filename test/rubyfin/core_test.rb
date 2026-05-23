require_relative "../test_helper"
require "open3"
require "rbconfig"

class CoreTest < Minitest::Test
  test "core require does not load adapter dependencies" do
    stdout, stderr, status = Open3.capture3(
      RbConfig.ruby,
      "-Ilib",
      "-e",
      "require 'rubyfin'; puts [defined?(Rubyfin::Edgar), defined?(Rubyfin::Fred), defined?(Rubyfin::Stooq)].inspect",
      chdir: File.expand_path("../..", __dir__)
    )

    assert status.success?, stderr
    assert_equal "[nil, nil, nil]", stdout.strip
  end

  test "source exposes stable serialization" do
    source = Rubyfin::Source.new("test", "Test", "https://example.com", { kind: "fixture" })

    assert_equal(
      {
        id: "test",
        name: "Test",
        homepage_url: "https://example.com",
        metadata: { kind: "fixture" }
      },
      source.to_h
    )
  end
end
