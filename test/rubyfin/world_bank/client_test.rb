require_relative "../../test_helper"
require "rubyfin/world_bank"

module Rubyfin::WorldBank
  class ClientTest < Minitest::Test
    test "fetches indicator metadata and paginated observations" do
      http = FakeHttpClient.new(
        "/v2/indicator/NY.GDP.MKTP.CD" => [
          200,
          [
            { "page" => 1, "pages" => 1, "per_page" => 50, "total" => 1 },
            [indicator_payload]
          ].to_json
        ],
        "/v2/country/us/indicator/NY.GDP.MKTP.CD?page=1" => [
          200,
          [
            { "page" => 1, "pages" => 2, "per_page" => 1, "total" => 2 },
            [observation_payload("2025", "29184900000000")]
          ].to_json
        ],
        "/v2/country/us/indicator/NY.GDP.MKTP.CD?page=2" => [
          200,
          [
            { "page" => 2, "pages" => 2, "per_page" => 1, "total" => 2 },
            [observation_payload("2024", nil)]
          ].to_json
        ]
      )
      client = Client.new(http_client: http)

      indicator = client.indicator("NY.GDP.MKTP.CD")
      observations = client.observations("US", "NY.GDP.MKTP.CD", date: 2024..2025, per_page: 1)

      assert_equal "NY.GDP.MKTP.CD", indicator.id
      assert_equal "GDP (current US$)", indicator.name
      assert_equal "World Development Indicators", indicator.source_name
      assert_equal [{ id: "3", name: "Economy & Growth" }], indicator.topics

      assert_equal 2, observations.length
      assert_equal Date.new(2025, 1, 1), observations.first.observed_on
      assert_equal BigDecimal("29184900000000"), observations.first.value
      assert_nil observations.last.value
      assert_equal ["US", "NY.GDP.MKTP.CD", "2025"], observations.first.natural_key

      request = http.requests.find { |uri| uri.path == "/v2/country/us/indicator/NY.GDP.MKTP.CD" && query(uri).fetch("page") == "1" }
      assert_equal "json", query(request).fetch("format")
      assert_equal "2024:2025", query(request).fetch("date")
      assert_equal "1", query(request).fetch("per_page")
    end

    test "supports multiple countries" do
      http = FakeHttpClient.new(
        "/v2/country/us;ca/indicator/SP.POP.TOTL?page=1" => [
          200,
          [
            { "page" => 1, "pages" => 1, "per_page" => 20_000, "total" => 0 },
            []
          ].to_json
        ]
      )
      client = Client.new(http_client: http)

      client.observations(["US", "CA"], "SP.POP.TOTL")

      assert_equal "/v2/country/us;ca/indicator/SP.POP.TOTL", http.requests.first.path
    end

    test "maps api message responses to not found" do
      client = Client.new(
        http_client: FakeHttpClient.new(
          "/v2/indicator/BOGUS" => [
            200,
            [
              {
                "message" => [
                  { "id" => "120", "key" => "Invalid value", "value" => "The provided parameter value is not valid" }
                ]
              }
            ].to_json
          ]
        )
      )

      assert_raises(NotFound) do
        client.indicator("BOGUS")
      end
    end

    private

    def indicator_payload
      {
        "id" => "NY.GDP.MKTP.CD",
        "name" => "GDP (current US$)",
        "unit" => "",
        "source" => { "id" => "2", "value" => "World Development Indicators" },
        "sourceNote" => "GDP at purchaser's prices.",
        "sourceOrganization" => "World Bank national accounts data.",
        "topics" => [{ "id" => "3", "value" => "Economy & Growth" }]
      }
    end

    def observation_payload(date, value)
      {
        "indicator" => { "id" => "NY.GDP.MKTP.CD", "value" => "GDP (current US$)" },
        "country" => { "id" => "US", "value" => "United States" },
        "countryiso3code" => "USA",
        "date" => date,
        "value" => value,
        "unit" => "",
        "obs_status" => "",
        "decimal" => 0
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

        key = "#{uri.path}?page=#{URI.decode_www_form(uri.query).to_h.fetch("page", "")}"
        @responses.fetch(key) { @responses.fetch(uri.path) }
      end
    end
  end
end
