require_relative "../../test_helper"
require "rubyfin/stooq"

module Rubyfin::Stooq
  class ClientTest < Minitest::Test
    test "fetches daily price bars from csv" do
      http = FakeHttpClient.new(
        200,
        <<~CSV
          Date,Open,High,Low,Close,Volume
          2026-05-01,210.12,213.58,209.50,212.34,50012300
          2026-05-04,212.50,214.00,211.10,213.20,46111000
        CSV
      )
      client = Client.new(api_key: "test-key", http_client: http)

      bars = client.prices("AAPL.US", start_date: Date.new(2026, 5, 1), end_date: "2026-05-04")

      assert_equal 2, bars.length
      assert_equal "aapl.us", bars.first.symbol
      assert_equal "daily", bars.first.interval
      assert_equal Date.new(2026, 5, 1), bars.first.traded_on
      assert_equal BigDecimal("210.12"), bars.first.open
      assert_equal BigDecimal("213.58"), bars.first.high
      assert_equal BigDecimal("209.50"), bars.first.low
      assert_equal BigDecimal("212.34"), bars.first.close
      assert_equal 50_012_300, bars.first.volume
      assert_equal ["aapl.us", "daily", Date.new(2026, 5, 1)], bars.first.natural_key

      request = http.requests.first
      query = URI.decode_www_form(request.query).to_h
      assert_equal "aapl.us", query.fetch("s")
      assert_equal "d", query.fetch("i")
      assert_equal "20260501", query.fetch("d1")
      assert_equal "20260504", query.fetch("d2")
      assert_equal "test-key", query.fetch("apikey")
    end

    test "supports weekly monthly quarterly and yearly intervals" do
      http = FakeHttpClient.new(200, "Date,Open,High,Low,Close,Volume\n2026-05-01,1,2,0.5,1.5,10\n")
      client = Client.new(api_key: "test-key", http_client: http)

      client.prices("spy.us", interval: :weekly)
      client.prices("spy.us", interval: "m")
      client.prices("spy.us", interval: :quarterly)
      client.prices("spy.us", interval: "yearly")

      codes = http.requests.map { |uri| URI.decode_www_form(uri.query).to_h.fetch("i") }
      assert_equal ["w", "m", "q", "y"], codes
    end

    test "raises not found for no data responses" do
      client = Client.new(api_key: "test-key", http_client: FakeHttpClient.new(200, "No data"))

      assert_raises(NotFound) do
        client.prices("missing.us")
      end
    end

    test "requires an api key" do
      client = Client.new(api_key: "", http_client: FakeHttpClient.new(200, ""))

      assert_raises(MissingApiKey) do
        client.prices("spy.us")
      end
    end

    test "detects api key prompts returned by Stooq" do
      client = Client.new(api_key: "expired-key", http_client: FakeHttpClient.new(200, "Get your apikey: https://stooq.com/q/d/?s=spy.us&get_apikey"))

      assert_raises(MissingApiKey) do
        client.prices("spy.us")
      end
    end

    test "rejects unsupported intervals" do
      client = Client.new(api_key: "test-key", http_client: FakeHttpClient.new(200, ""))

      assert_raises(InvalidInterval) do
        client.prices("spy.us", interval: :minute)
      end
    end

    class FakeHttpClient
      attr_reader :requests

      def initialize(code, body)
        @code = code
        @body = body
        @requests = []
      end

      def get_text(uri, headers:)
        @requests << uri
        raise "missing csv accept header" unless headers["Accept"].include?("text/csv")

        [@code, @body]
      end
    end
  end
end
