require_relative "../../test_helper"
require "rubyfin/oecd"

module Rubyfin::Oecd
  class ClientTest < Minitest::Test
    test "fetches and parses oecd csv observations" do
      http = FakeHttpClient.new(
        200,
        <<~CSV
          DATAFLOW,FREQ,REF_AREA,MEASURE,UNIT_MEASURE,TIME_PERIOD,OBS_VALUE,CONF_STATUS,DECIMALS
          OECD.SDD.NAD:DSD_NAAG@DF_NAAG_I(1.0),A,AUS,B1GQ_R,USD_PPP,2022,1577.79477985503,F,2
          OECD.SDD.NAD:DSD_NAAG@DF_NAAG_I(1.0),A,AUT,B1GQ_R,USD_PPP,2022,,F,2
        CSV
      )
      client = Client.new(http_client: http)

      observations = client.data(
        "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I",
        key: ".AUS.B1GQ_R.USD_PPP",
        start_period: "2022",
        end_period: "2022"
      )

      assert_equal 2, observations.length

      observation = observations.first
      assert_equal "OECD.SDD.NAD:DSD_NAAG@DF_NAAG_I(1.0)", observation.dataflow
      assert_equal "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I", observation.requested_dataflow
      assert_equal ".AUS.B1GQ_R.USD_PPP", observation.requested_key
      assert_equal "2022", observation.period
      assert_equal Date.new(2022, 1, 1), observation.observed_on
      assert_equal BigDecimal("1577.79477985503"), observation.value
      assert_nil observations.last.value
      assert_equal(
        {
          "FREQ" => "A",
          "REF_AREA" => "AUS",
          "MEASURE" => "B1GQ_R",
          "UNIT_MEASURE" => "USD_PPP"
        },
        observation.dimensions
      )
      assert_equal({ "CONF_STATUS" => "F", "DECIMALS" => "2" }, observation.attributes)
      assert_equal "A.AUS.B1GQ_R.USD_PPP", observation.series_key
      assert_equal ["OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I", "A.AUS.B1GQ_R.USD_PPP", "2022"], observation.natural_key

      request = http.requests.first
      assert_equal "/public/rest/data/OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I/.AUS.B1GQ_R.USD_PPP", request.path
      query = URI.decode_www_form(request.query).to_h
      assert_equal "csvfile", query.fetch("format")
      assert_equal "2022", query.fetch("startPeriod")
      assert_equal "2022", query.fetch("endPeriod")
    end

    test "supports observation limit options" do
      http = FakeHttpClient.new(
        200,
        "DATAFLOW,FREQ,TIME_PERIOD,OBS_VALUE\nOECD.TEST:FLOW(1.0),A,2022,1\n"
      )
      client = Client.new(http_client: http)

      client.data("OECD.TEST,FLOW", first_n_observations: 1, last_n_observations: 2)

      query = URI.decode_www_form(http.requests.first.query).to_h
      assert_equal "1", query.fetch("firstNObservations")
      assert_equal "2", query.fetch("lastNObservations")
    end

    test "rejects unsupported csv formats" do
      client = Client.new(http_client: FakeHttpClient.new(200, ""))

      assert_raises(Error) do
        client.data("OECD.TEST,FLOW", format: :jsondata)
      end
    end

    test "maps http not found responses" do
      client = Client.new(http_client: FakeHttpClient.new(404, "missing dataflow"))

      error = assert_raises(NotFound) do
        client.data("OECD.TEST,MISSING")
      end

      assert_match(/missing dataflow/, error.message)
    end

    private

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
