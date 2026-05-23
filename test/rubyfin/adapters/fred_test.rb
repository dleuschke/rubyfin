require_relative "../../test_helper"
require "rubyfin/adapters/fred"

class FredAdapterTest < Minitest::Test
  test "wraps FRED series and observations in Rubyfin records" do
    adapter = Rubyfin.fred(client: client)

    series = adapter.series("FEDFUNDS")
    observations = adapter.observations("FEDFUNDS", observation_start: "2026-04-01")
    results = adapter.search("fed funds", limit: 1)

    assert_equal "fred", adapter.source.id
    assert_equal ["fred", "FEDFUNDS"], series.natural_key
    assert_equal "Federal Funds Effective Rate", series.title
    assert_equal "M", series.metadata.fetch(:frequency_short)
    assert_kind_of Rubyfin::Fred::Series, series.raw
    assert_equal "FEDFUNDS", results.first.id

    observation = observations.first
    assert_equal ["fred", "FEDFUNDS", Date.new(2026, 4, 1), Date.new(2026, 5, 1), Date.new(2026, 5, 23)], observation.natural_key
    assert_equal BigDecimal("4.33"), observation.value
    assert_kind_of Rubyfin::Fred::Observation, observation.raw
  end

  private

  def client
    Rubyfin::Fred::Client.new(
      api_key: "test-key",
      http_client: FakeHttpClient.new(
        "/fred/series" => [200, { "seriess" => [series_payload] }.to_json],
        "/fred/series/observations" => [
          200,
          {
            "observations" => [
              {
                "realtime_start" => "2026-05-01",
                "realtime_end" => "2026-05-23",
                "date" => "2026-04-01",
                "value" => "4.33"
              }
            ]
          }.to_json
        ],
        "/fred/series/search" => [200, { "seriess" => [series_payload] }.to_json]
      )
    )
  end

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

  class FakeHttpClient
    def initialize(responses)
      @responses = responses
    end

    def get_json(uri, headers:)
      @responses.fetch(uri.path)
    end
  end
end
