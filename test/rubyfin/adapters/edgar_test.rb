require_relative "../../test_helper"
require "rubyfin/adapters/edgar"

class EdgarAdapterTest < Minitest::Test
  test "wraps EDGAR companies filings items and facts" do
    adapter = Rubyfin.edgar(database:)

    company = adapter.company("AAPL")
    filings = adapter.filings("AAPL", forms: ["8-K"], since: Time.utc(2026, 5, 1))
    facts = adapter.company_facts("AAPL")

    assert_equal "edgar", adapter.source.id
    assert_equal ["edgar", 320193], company.natural_key
    assert_equal "AAPL", company.to_h.fetch(:ticker)
    assert_kind_of Rubyfin::Edgar::Company, company.raw

    filing = filings.first
    assert_equal ["edgar", 320193, "0000320193-26-000001"], filing.natural_key
    assert_equal "8-K", filing.form
    assert_equal ["2.02", "9.01"], filing.item_codes
    assert_equal "https://www.sec.gov/Archives/edgar/data/320193/000032019326000001/aapl-20260522.htm", filing.primary_document_url
    assert_equal "Results of Operations and Financial Condition", filing.items.first.label
    assert_equal ["edgar", 320193, "0000320193-26-000001", "2.02"], filing.items.first.natural_key
    assert_equal "Results of Operations and Financial Condition", filing.to_h.fetch(:items).first.fetch(:label)

    assert_equal ["edgar", 320193, "company_facts"], facts.natural_key
    assert_equal "Revenues", facts.facts.fetch("us-gaap").fetch("Revenues").fetch("label")
    assert_kind_of Rubyfin::Edgar::CompanyFacts, facts.raw
  end

  test "maps EDGAR not found errors to Rubyfin not found errors" do
    adapter = Rubyfin.edgar(
      database: Rubyfin::Edgar::Database.new(
        client: Rubyfin::Edgar::Client.new(
          user_agent: "Windfall test contact@example.com",
          http_client: FakeHttpClient.new("/files/company_tickers.json" => [200, "{}"])
        )
      )
    )

    assert_raises(Rubyfin::NotFound) do
      adapter.company("NOPE")
    end
  end

  private

  def database
    Rubyfin::Edgar::Database.new(
      client: Rubyfin::Edgar::Client.new(
        user_agent: "Windfall test contact@example.com",
        http_client: FakeHttpClient.new(
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
      )
    )
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
