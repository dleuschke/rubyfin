require_relative "../../test_helper"
require "rubyfin/fred"

module Rubyfin::Fred
  class ClientTest < Minitest::Test
    test "fetches series metadata observations and search results" do
      http = FakeHttpClient.new(
        "/fred/series" => [
          200,
          {
            "seriess" => [series_payload]
          }.to_json
        ],
        "/fred/series/observations" => [
          200,
          {
            "observations" => [
              {
                "realtime_start" => "2026-05-01",
                "realtime_end" => "2026-05-23",
                "date" => "2026-04-01",
                "value" => "4.33"
              },
              {
                "realtime_start" => "2026-05-01",
                "realtime_end" => "2026-05-23",
                "date" => "2026-05-01",
                "value" => "."
              }
            ]
          }.to_json
        ],
        "/fred/series/search" => [
          200,
          {
            "seriess" => [series_payload.merge("id" => "DFF", "title" => "Federal Funds Effective Rate")]
          }.to_json
        ]
      )
      client = Client.new(api_key: "test-key", http_client: http)

      series = client.series("FEDFUNDS")
      observations = client.observations("FEDFUNDS", observation_start: Date.new(2026, 4, 1))
      results = client.search("fed funds", limit: 1)

      assert_equal "FEDFUNDS", series.id
      assert_equal "This product uses the FRED® API but is not endorsed or certified by the Federal Reserve Bank of St. Louis.", Rubyfin::Fred.attribution_notice
      assert_equal Rubyfin::Fred.attribution_notice, Rubyfin::Fred.source.metadata.fetch(:attribution_notice)
      assert_equal "https://fred.stlouisfed.org/docs/api/terms_of_use.html", Rubyfin::Fred.source.metadata.fetch(:terms_url)
      assert_equal "Federal Funds Effective Rate", results.first.title
      assert_equal Date.new(1954, 7, 1), series.observation_start
      assert_equal Time.new(2026, 5, 1, 10, 15, 0, "-05:00"), series.last_updated_at
      assert_equal BigDecimal("4.33"), observations.first.value
      assert_nil observations.last.value
      assert_equal ["FEDFUNDS", Date.new(2026, 4, 1), Date.new(2026, 5, 1), Date.new(2026, 5, 23)], observations.first.natural_key

      series_request = http.requests.find { |uri| uri.path == "/fred/series" }
      assert_equal "test-key", query(series_request).fetch("api_key")
      assert_equal "json", query(series_request).fetch("file_type")
      assert_equal "FEDFUNDS", query(series_request).fetch("series_id")

      observations_request = http.requests.find { |uri| uri.path == "/fred/series/observations" }
      assert_equal "2026-04-01", query(observations_request).fetch("observation_start")
    end

    test "requires an api key" do
      error = assert_raises(MissingApiKey) do
        Client.new(api_key: "", http_client: FakeHttpClient.new({})).series("FEDFUNDS")
      end

      assert_match(/FRED_API_KEY/, error.message)
    end

    private

    def series_payload
      {
        "id" => "FEDFUNDS",
        "title" => "Federal Funds Effective Rate",
        "observation_start" => "1954-07-01",
        "observation_end" => "2026-05-01",
        "frequency" => "Monthly",
        "frequency_short" => "M",
        "units" => "Percent",
        "units_short" => "%",
        "seasonal_adjustment" => "Not Seasonally Adjusted",
        "seasonal_adjustment_short" => "NSA",
        "last_updated" => "2026-05-01 10:15:00-05",
        "popularity" => "99",
        "notes" => "Monthly average effective federal funds rate."
      }
    end

    def query(uri)
      URI.decode_www_form(uri.query).to_h
    end

    class FakeHttpClient
      attr_reader :requests

      def initialize(responses)
        @responses = responses
        @requests = []
      end

      def get_json(uri, headers:)
        @requests << uri
        raise "missing accept header" unless headers["Accept"] == "application/json"

        @responses.fetch(uri.path)
      end
    end
  end
end
