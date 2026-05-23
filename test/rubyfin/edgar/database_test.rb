require_relative "../../test_helper"
require "rubyfin/edgar"

module Rubyfin::Edgar
  class DatabaseTest < Minitest::Test
    test "exposes yfinance-style company filing and facts access" do
      http = FakeHttpClient.new(
        "/files/company_tickers.json" => [
          200,
          {
            "0" => { "cik_str" => 320193, "ticker" => "AAPL", "title" => "Apple Inc." }
          }.to_json
        ],
        "/submissions/CIK0000320193.json" => [
          200,
          {
            "name" => "Apple Inc.",
            "filings" => {
              "recent" => {
                "accessionNumber" => ["0000320193-26-000001"],
                "acceptanceDateTime" => ["2026-05-22T21:04:00.000Z"],
                "filingDate" => ["2026-05-22"],
                "form" => ["8-K"],
                "primaryDocument" => ["aapl-20260522.htm"],
                "items" => ["2.02,9.01"]
              }
            }
          }.to_json
        ],
        "/api/xbrl/companyfacts/CIK0000320193.json" => [
          200,
          {
            "facts" => {
              "us-gaap" => {
                "Revenues" => {
                  "label" => "Revenues"
                }
              }
            }
          }.to_json
        ]
      )

      company = Rubyfin::Edgar.company("AAPL", user_agent: "Windfall test contact@example.com", http_client: http)
      filing = company.filings.form("8-K").since(Time.utc(2026, 5, 1)).latest

      assert_equal 320193, company.cik
      assert_equal "AAPL", company.ticker
      assert_equal "Apple Inc.", company.name
      assert_equal "0000320193-26-000001", filing.accession
      assert_equal "8-K", filing.form
      assert_equal ["2.02", "9.01"], filing.items.map(&:code)
      assert_equal "Results of Operations and Financial Condition", filing.items.first.label
      assert_equal "https://www.sec.gov/Archives/edgar/data/320193/000032019326000001/aapl-20260522.htm", filing.primary_document.url
      assert_equal "Revenues", company.facts.us_gaap("Revenues").fetch("label")

      assert_equal 320193, company.natural_key
      assert_equal [320193, "0000320193-26-000001"], filing.natural_key
      assert_equal [320193, "0000320193-26-000001", "2.02"], filing.items.first.natural_key
      assert_equal [320193, "0000320193-26-000001", "aapl-20260522.htm"], filing.primary_document.natural_key
      assert_equal "AAPL", company.to_h.fetch(:ticker)
      assert_equal "https://www.sec.gov/Archives/edgar/data/320193/000032019326000001/0000320193-26-000001-index.htm", filing.to_h.fetch(:index_url)
      assert_equal "Results of Operations and Financial Condition", filing.items.first.to_h.fetch(:label)
      assert_equal "aapl-20260522.htm", filing.primary_document.to_h.fetch(:name)
    end

    test "raises not found for unknown tickers" do
      http = FakeHttpClient.new("/files/company_tickers.json" => [200, "{}"])

      assert_raises(NotFound) do
        Rubyfin::Edgar.company("NOPE", user_agent: "Windfall test contact@example.com", http_client: http)
      end
    end

    class FakeHttpClient
      def initialize(responses)
        @responses = responses
      end

      def get_json(uri, headers:)
        raise "missing user agent" if headers["User-Agent"].to_s.empty?

        @responses.fetch(uri.path)
      end
    end
  end
end
