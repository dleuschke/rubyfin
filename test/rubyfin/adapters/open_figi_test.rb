require_relative "../../test_helper"
require "rubyfin/adapters/open_figi"

class OpenFigiAdapterTest < Minitest::Test
  test "wraps OpenFIGI instruments in Rubyfin records" do
    adapter = Rubyfin.open_figi(client: client)

    result = adapter.map_ticker("AAPL", exch_code: "US")
    instrument = result.flatten.first

    assert_equal "open_figi", adapter.source.id
    assert_equal ["open_figi", "BBG000B9XRY4"], instrument.natural_key
    assert_equal "BBG001S5N8V8", instrument.share_class_figi
    assert_equal "AAPL", instrument.ticker
    assert_equal "APPLE INC", instrument.name
    assert_equal "Equity", instrument.market_sector
    assert_equal "EQ0010169500001000", instrument.metadata.fetch("uniqueID")
    assert_equal "Multiple matches found", instrument.metadata.fetch(:warning)
    assert_kind_of Rubyfin::OpenFigi::Instrument, instrument.raw
  end

  private

  def client
    Rubyfin::OpenFigi::Client.new(
      api_key: "test-key",
      http_client: FakeHttpClient.new(
        200,
        [
          {
            "data" => [
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
            ],
            "warning" => "Multiple matches found"
          }
        ].to_json
      )
    )
  end

  class FakeHttpClient
    def initialize(code, body)
      @code = code
      @body = body
    end

    def post_json(_uri, body:, headers:)
      raise "missing body" if body.empty?
      raise "missing accept header" unless headers["Accept"] == "application/json"

      [@code, @body]
    end
  end
end
