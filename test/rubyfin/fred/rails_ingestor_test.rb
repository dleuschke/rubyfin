require_relative "../../test_helper"
require "rubyfin/rails/fred"

class FredRailsIngestorTest < Minitest::Test
  def setup
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    create_schema
  end

  def teardown
    ActiveRecord::Base.remove_connection
  end

  def test_ingests_series_and_observations_idempotently
    ingestor = Rubyfin::Rails::Fred::Ingestor.new(
      client: client,
      clock: -> { Time.utc(2026, 5, 23, 12, 0, 0) }
    )

    result = ingestor.ingest_series("FEDFUNDS", observation_start: Date.new(2026, 4, 1))

    assert_equal "succeeded", result.run.status
    assert_equal({ "series" => 1, "observations" => 2 }, result.counts)
    assert_equal 1, Rubyfin::Rails::Fred::Series.count
    assert_equal 2, Rubyfin::Rails::Fred::Observation.count

    series = Rubyfin::Rails::Fred::Series.find_by!(series_id: "FEDFUNDS")
    observation = Rubyfin::Rails::Fred::Observation.find_by!(observed_on: Date.new(2026, 4, 1))

    assert_equal "Federal Funds Effective Rate", series.title
    assert_equal "M", series.frequency_short
    assert_equal BigDecimal("4.33"), observation.value
    assert_equal series, observation.series

    ingestor.ingest_series("FEDFUNDS", observation_start: Date.new(2026, 4, 1))

    assert_equal 1, Rubyfin::Rails::Fred::Series.count
    assert_equal 2, Rubyfin::Rails::Fred::Observation.count
    assert_equal 2, Rubyfin::Rails::Fred::IngestionRun.where(status: "succeeded").count
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
              },
              {
                "realtime_start" => "2026-05-01",
                "realtime_end" => "2026-05-23",
                "date" => "2026-05-01",
                "value" => "."
              }
            ]
          }.to_json
        ]
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

  def create_schema
    ActiveRecord::Schema.verbose = false
    ActiveRecord::Schema.define do
      create_table :rubyfin_fred_series, force: true do |t|
        t.string :series_id, null: false
        t.string :title
        t.string :frequency
        t.string :frequency_short
        t.string :units
        t.string :units_short
        t.string :seasonal_adjustment
        t.string :seasonal_adjustment_short
        t.date :observation_start
        t.date :observation_end
        t.datetime :last_updated_at
        t.integer :popularity
        t.text :notes
        t.json :raw
        t.datetime :last_seen_at
        t.timestamps
      end
      add_index :rubyfin_fred_series, :series_id, unique: true

      create_table :rubyfin_fred_observations, force: true do |t|
        t.references :rubyfin_fred_series, null: false
        t.string :series_id, null: false
        t.date :observed_on, null: false
        t.decimal :value, precision: 30, scale: 10
        t.date :realtime_start
        t.date :realtime_end
        t.json :raw
        t.datetime :fetched_at
        t.timestamps
      end
      add_index :rubyfin_fred_observations,
        [:series_id, :observed_on, :realtime_start, :realtime_end],
        unique: true,
        name: "idx_rubyfin_fred_obs_natural_key"

      create_table :rubyfin_fred_ingestion_runs, force: true do |t|
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
      @responses.fetch(uri.path)
    end
  end
end
