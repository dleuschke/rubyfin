require_relative "../../test_helper"
require "rubyfin/open_figi"

module Rubyfin::OpenFigi
  class ClientTest < Minitest::Test
    test "maps ticker jobs to instruments" do
      http = FakeHttpClient.new(
        200,
        [
          {
            "data" => [instrument_payload],
            "warning" => "Multiple matches found"
          }
        ].to_json
      )
      client = Client.new(api_key: "test-key", http_client: http)

      results = client.map_ticker("AAPL", exch_code: "US")

      assert_equal 1, results.length
      assert_equal({ "idType" => "TICKER", "idValue" => "AAPL", "exchCode" => "US" }, results.first.job)
      assert_equal "Multiple matches found", results.first.warning
      assert_predicate results.first, :success?

      instrument = results.first.instruments.first
      assert_equal "BBG000B9XRY4", instrument.figi
      assert_equal "BBG000B9XRY4", instrument.natural_key
      assert_equal "BBG000B9XRY4", instrument.composite_figi
      assert_equal "BBG001S5N8V8", instrument.share_class_figi
      assert_equal "AAPL", instrument.ticker
      assert_equal "APPLE INC", instrument.name
      assert_equal "US", instrument.exchange_code
      assert_equal "Equity", instrument.market_sector
      assert_equal "Common Stock", instrument.security_type
      assert_equal "Common Stock", instrument.security_type2
      assert_equal "AAPL", instrument.security_description

      request = http.requests.first
      assert_equal "/v3/mapping", request.fetch(:uri).path
      assert_equal "test-key", request.fetch(:headers).fetch("X-OPENFIGI-APIKEY")
      assert_equal "application/json", request.fetch(:headers).fetch("Content-Type")
      assert_equal([{ "idType" => "TICKER", "idValue" => "AAPL", "exchCode" => "US" }], JSON.parse(request.fetch(:body)))
    end

    test "supports missing api key" do
      http = FakeHttpClient.new(200, [{ "data" => [instrument_payload] }].to_json)
      client = Client.new(api_key: "", http_client: http)

      client.map([{ id_type: "TICKER", id_value: "MSFT" }])

      refute_includes http.requests.first.fetch(:headers), "X-OPENFIGI-APIKEY"
    end

    test "preserves job errors" do
      client = Client.new(
        http_client: FakeHttpClient.new(
          200,
          [{ "error" => "No identifier found." }].to_json
        )
      )

      result = client.map([{ id_type: "TICKER", id_value: "MISSING" }]).first

      assert_equal "No identifier found.", result.error
      refute_predicate result, :success?
      assert_empty result.instruments
    end

    test "maps bad requests to not found" do
      client = Client.new(http_client: FakeHttpClient.new(400, "bad job"))

      error = assert_raises(NotFound) do
        client.map([{ id_type: "TICKER", id_value: "AAPL" }])
      end

      assert_match(/bad job/, error.message)
    end

    private

    def instrument_payload
      {
        "figi" => "BBG000B9XRY4",
        "compositeFIGI" => "BBG000B9XRY4",
        "shareClassFIGI" => "BBG001S5N8V8",
        "ticker" => "AAPL",
        "name" => "APPLE INC",
        "exchCode" => "US",
        "marketSector" => "Equity",
        "securityType" => "Common Stock",
        "securityType2" => "Common Stock",
        "securityDescription" => "AAPL",
        "uniqueID" => "EQ0010169500001000"
      }
    end

    class FakeHttpClient
      attr_reader :requests

      def initialize(code, body)
        @code = code
        @body = body
        @requests = []
      end

      def post_json(uri, body:, headers:)
        @requests << { uri:, body:, headers: }
        [@code, @body]
      end
    end
  end
end
