require_relative "../../test_helper"
require "rubyfin/rails/edgar"

class EdgarRailsIngestorTest < Minitest::Test
  def setup
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    create_schema
  end

  def teardown
    ActiveRecord::Base.remove_connection
  end

  def test_ingests_company_filings_items_and_facts_idempotently
    ingestor = Rubyfin::Rails::Edgar::Ingestor.new(
      database: database,
      clock: -> { Time.utc(2026, 5, 23, 12, 0, 0) }
    )

    result = ingestor.ingest_company(
      "AAPL",
      forms: ["8-K"],
      since: Time.utc(2026, 5, 1),
      include_facts: true
    )

    assert_equal "succeeded", result.run.status
    assert_equal(
      {
        "companies" => 1,
        "filings" => 1,
        "filing_items" => 2,
        "company_facts" => 1
      },
      result.counts
    )
    assert_equal 1, Rubyfin::Rails::Edgar::Company.count
    assert_equal 1, Rubyfin::Rails::Edgar::Filing.count
    assert_equal 2, Rubyfin::Rails::Edgar::FilingItem.count
    assert_equal 1, Rubyfin::Rails::Edgar::CompanyFact.count

    company = Rubyfin::Rails::Edgar::Company.find_by!(cik: 320193)
    filing = Rubyfin::Rails::Edgar::Filing.find_by!(accession: "0000320193-26-000001")
    item = Rubyfin::Rails::Edgar::FilingItem.find_by!(code: "2.02")
    fact = Rubyfin::Rails::Edgar::CompanyFact.find_by!(taxonomy: "us-gaap", tag: "Revenues")

    assert_equal "AAPL", company.ticker
    assert_equal company, filing.company
    assert_equal "8-K", filing.form
    assert_equal "https://www.sec.gov/Archives/edgar/data/320193/000032019326000001/aapl-20260522.htm", filing.primary_document_url
    assert_equal filing, item.filing
    assert_equal "Results of Operations and Financial Condition", item.label
    assert_equal company, fact.company
    assert_equal "Revenues", fact.payload.fetch("label")

    ingestor.ingest_company("AAPL", forms: ["8-K"], since: Time.utc(2026, 5, 1), include_facts: true)

    assert_equal 1, Rubyfin::Rails::Edgar::Company.count
    assert_equal 1, Rubyfin::Rails::Edgar::Filing.count
    assert_equal 2, Rubyfin::Rails::Edgar::FilingItem.count
    assert_equal 1, Rubyfin::Rails::Edgar::CompanyFact.count
    assert_equal 2, Rubyfin::Rails::Edgar::IngestionRun.where(status: "succeeded").count
  end

  def test_records_failed_ingestion_runs
    client = Rubyfin::Edgar::Client.new(
      user_agent: "Windfall test contact@example.com",
      http_client: FakeHttpClient.new("/files/company_tickers.json" => [200, "{}"])
    )
    ingestor = Rubyfin::Rails::Edgar::Ingestor.new(
      database: Rubyfin::Edgar::Database.new(client:),
      clock: -> { Time.utc(2026, 5, 23, 12, 0, 0) }
    )

    assert_raises(Rubyfin::Edgar::NotFound) do
      ingestor.ingest_company("NOPE")
    end

    run = Rubyfin::Rails::Edgar::IngestionRun.last
    assert_equal "failed", run.status
    assert_equal "Rubyfin::Edgar::NotFound", run.error_class
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

  def create_schema
    ActiveRecord::Schema.verbose = false
    ActiveRecord::Schema.define do
      create_table :rubyfin_edgar_companies, force: true do |t|
        t.bigint :cik, null: false
        t.string :ticker, null: false
        t.string :name
        t.datetime :last_seen_at
        t.timestamps
      end
      add_index :rubyfin_edgar_companies, :cik, unique: true

      create_table :rubyfin_edgar_filings, force: true do |t|
        t.references :rubyfin_edgar_company, null: false
        t.bigint :cik, null: false
        t.string :accession, null: false
        t.string :form
        t.datetime :filed_at
        t.string :company_name
        t.string :primary_document_name
        t.string :index_url
        t.string :primary_document_url
        t.timestamps
      end
      add_index :rubyfin_edgar_filings, [:cik, :accession], unique: true

      create_table :rubyfin_edgar_filing_items, force: true do |t|
        t.references :rubyfin_edgar_filing, null: false
        t.bigint :cik, null: false
        t.string :accession, null: false
        t.string :code, null: false
        t.string :label
        t.timestamps
      end
      add_index :rubyfin_edgar_filing_items, [:cik, :accession, :code], unique: true

      create_table :rubyfin_edgar_company_facts, force: true do |t|
        t.references :rubyfin_edgar_company, null: false
        t.bigint :cik, null: false
        t.string :taxonomy, null: false
        t.string :tag, null: false
        t.json :payload
        t.datetime :fetched_at
        t.timestamps
      end
      add_index :rubyfin_edgar_company_facts, [:cik, :taxonomy, :tag], unique: true

      create_table :rubyfin_edgar_ingestion_runs, force: true do |t|
        t.datetime :started_at
        t.datetime :finished_at
        t.string :status, null: false
        t.string :scope, null: false
        t.json :options
        t.json :counts
        t.string :error_class
        t.text :error_message
        t.timestamps
      end
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
