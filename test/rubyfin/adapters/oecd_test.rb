require_relative "../../test_helper"
require "rubyfin/adapters/oecd"

class OecdAdapterTest < Minitest::Test
  test "wraps OECD observations in Rubyfin records" do
    adapter = Rubyfin.oecd(client: client)

    observations = adapter.observations(
      "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I",
      start_period: "2022",
      end_period: "2022"
    )

    assert_equal "oecd", adapter.source.id
    assert_equal 1, observations.length

    observation = observations.first
    assert_equal ["oecd", "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I/A.AUS.B1GQ_R.USD_PPP", Date.new(2022, 1, 1), nil, nil], observation.natural_key
    assert_equal BigDecimal("1577.79477985503"), observation.value
    assert_equal "2022", observation.metadata.fetch(:period)
    assert_equal "AUS", observation.metadata.fetch(:dimensions).fetch("REF_AREA")
    assert_kind_of Rubyfin::Oecd::Observation, observation.raw
  end

  private

  def client
    Rubyfin::Oecd::Client.new(
      http_client: FakeHttpClient.new(
        200,
        <<~CSV
          DATAFLOW,FREQ,REF_AREA,MEASURE,UNIT_MEASURE,TIME_PERIOD,OBS_VALUE,CONF_STATUS,DECIMALS
          OECD.SDD.NAD:DSD_NAAG@DF_NAAG_I(1.0),A,AUS,B1GQ_R,USD_PPP,2022,1577.79477985503,F,2
        CSV
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
