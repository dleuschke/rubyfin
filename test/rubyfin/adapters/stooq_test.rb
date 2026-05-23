require_relative "../../test_helper"
require "rubyfin/adapters/stooq"

class StooqAdapterTest < Minitest::Test
  test "wraps Stooq prices in Rubyfin records" do
    adapter = Rubyfin.stooq(client: client)

    bars = adapter.prices("SPY.US", start_date: "2026-05-01")

    assert_equal "stooq", adapter.source.id
    assert_equal 1, bars.length

    bar = bars.first
    assert_equal ["stooq", "spy.us", "daily", Date.new(2026, 5, 1)], bar.natural_key
    assert_equal BigDecimal("512.34"), bar.close
    assert_kind_of Rubyfin::Stooq::PriceBar, bar.raw
  end

  private

  def client
    Rubyfin::Stooq::Client.new(
      api_key: "test-key",
      http_client: FakeHttpClient.new(
        200,
        "Date,Open,High,Low,Close,Volume\n2026-05-01,510.00,515.00,509.25,512.34,71300000\n"
      )
    )
  end

  class FakeHttpClient
    def initialize(code, body)
      @code = code
      @body = body
    end

    def get_text(_uri, headers:)
      raise "missing accept header" unless headers["Accept"]

      [@code, @body]
    end
  end
end
