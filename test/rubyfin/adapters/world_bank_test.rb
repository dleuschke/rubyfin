require_relative "../../test_helper"
require "rubyfin/adapters/world_bank"

class WorldBankAdapterTest < Minitest::Test
  test "wraps World Bank indicators and observations in Rubyfin records" do
    adapter = Rubyfin.world_bank(client: client)

    series = adapter.series("NY.GDP.MKTP.CD")
    observations = adapter.observations("us", "NY.GDP.MKTP.CD", date: "2025")

    assert_equal "world_bank", adapter.source.id
    assert_equal ["world_bank", "NY.GDP.MKTP.CD"], series.natural_key
    assert_equal "GDP (current US$)", series.title
    assert_equal "World Development Indicators", series.metadata.fetch(:source_name)
    assert_kind_of Rubyfin::WorldBank::Indicator, series.raw

    observation = observations.first
    assert_equal ["world_bank", "USA:NY.GDP.MKTP.CD", Date.new(2025, 1, 1), nil, nil], observation.natural_key
    assert_equal BigDecimal("29184900000000"), observation.value
    assert_equal "USA", observation.metadata.fetch(:country_iso3_code)
    assert_equal "2025", observation.metadata.fetch(:period)
    assert_kind_of Rubyfin::WorldBank::Observation, observation.raw
  end

  private

  def client
    Rubyfin::WorldBank::Client.new(
      http_client: FakeHttpClient.new(
        "/v2/indicator/NY.GDP.MKTP.CD" => [
          200,
          [
            { "page" => 1, "pages" => 1, "per_page" => 50, "total" => 1 },
            [
              {
                "id" => "NY.GDP.MKTP.CD",
                "name" => "GDP (current US$)",
                "unit" => "",
                "source" => { "id" => "2", "value" => "World Development Indicators" },
                "sourceNote" => "GDP at purchaser's prices.",
                "sourceOrganization" => "World Bank national accounts data.",
                "topics" => []
              }
            ]
          ].to_json
        ],
        "/v2/country/us/indicator/NY.GDP.MKTP.CD" => [
          200,
          [
            { "page" => 1, "pages" => 1, "per_page" => 20_000, "total" => 1 },
            [
              {
                "indicator" => { "id" => "NY.GDP.MKTP.CD", "value" => "GDP (current US$)" },
                "country" => { "id" => "US", "value" => "United States" },
                "countryiso3code" => "USA",
                "date" => "2025",
                "value" => "29184900000000",
                "unit" => "",
                "obs_status" => "",
                "decimal" => 0
              }
            ]
          ].to_json
        ]
      )
    )
  end

  class FakeHttpClient
    def initialize(responses)
      @responses = responses
    end

    def get_json(uri, headers:)
      raise "missing accept header" unless headers["Accept"] == "application/json"

      [@responses.fetch(uri.path).first, @responses.fetch(uri.path).last]
    end
  end
end
