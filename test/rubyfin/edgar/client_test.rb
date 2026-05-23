require_relative "../../test_helper"
require "rubyfin/edgar"

module Rubyfin::Edgar
  class ClientTest < Minitest::Test
    test "builds SEC endpoint URLs and sends required user agent" do
      http = FakeHttpClient.new(
        "/files/company_tickers.json" => [200, "{}"],
        "/submissions/CIK0000320193.json" => [200, "{}"],
        "/api/xbrl/companyfacts/CIK0000320193.json" => [200, "{}"]
      )
      client = Client.new(user_agent: "Windfall test contact@example.com", http_client: http)

      assert_equal({}, client.company_tickers)
      assert_equal({}, client.submissions(320193))
      assert_equal({}, client.company_facts(320193))
      assert_equal "https://www.sec.gov/Archives/edgar/data/320193/000032019326000001/0000320193-26-000001-index.htm",
        client.filing_index_url(cik: 320193, accession: "0000320193-26-000001")
      assert_equal "https://www.sec.gov/Archives/edgar/data/320193/000032019326000001/aapl-20260522.htm",
        client.primary_document_url(cik: 320193, accession: "0000320193-26-000001", document: "aapl-20260522.htm")
      assert_equal ["Windfall test contact@example.com"], http.headers.map { |header| header.fetch("User-Agent") }.uniq
    end

    test "requires user agent before SEC requests" do
      error = assert_raises(MissingUserAgent) do
        Client.new(user_agent: "", http_client: FakeHttpClient.new({})).company_tickers
      end

      assert_match(/EDGAR_USER_AGENT/, error.message)
    end

    class FakeHttpClient
      attr_reader :requests, :headers

      def initialize(responses)
        @responses = responses
        @requests = []
        @headers = []
      end

      def get_json(uri, headers:)
        @requests << uri
        @headers << headers
        @responses.fetch(uri.path)
      end
    end
  end
end
