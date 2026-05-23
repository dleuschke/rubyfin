# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "rubyfin"

class Minitest::Test
  def self.test(name, &block)
    method_name = "test_#{name.gsub(/\W+/, "_")}"
    define_method(method_name, &block)
  end
end
