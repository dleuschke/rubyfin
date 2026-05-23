require_relative "../../test_helper"
require "rubyfin/edgar"

module Rubyfin::Edgar
  class CompanyTickersTest < Minitest::Test
    test "parses SEC company ticker payload into normalized entries" do
      entries = CompanyTickers.parse(
        "0" => { "cik_str" => 320193, "ticker" => "aapl", "title" => "Apple Inc." },
        "1" => { "cik_str" => "1067983", "ticker" => "BRK-B", "title" => "Berkshire Hathaway Inc." },
        "2" => { "cik_str" => nil, "ticker" => "", "title" => "Bad Row" }
      )

      assert_equal 2, entries.length
      assert_equal 320193, entries.first.cik
      assert_equal "AAPL", entries.first.ticker
      assert_equal "Apple Inc.", entries.first.name
      assert_equal "BRK-B", entries[1].ticker
    end
  end
end
