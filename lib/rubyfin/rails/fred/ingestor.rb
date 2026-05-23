require "time"

module Rubyfin::Rails::Fred
  class Ingestor
    Result = Data.define(:run, :series, :counts)

    def initialize(api_key: ENV["FRED_API_KEY"], client: nil, client_options: {}, clock: -> { Time.now.utc })
      @client = client || ::Rubyfin::Fred.client(api_key:, **client_options)
      @clock = clock
    end

    def ingest_series(series_id, observation_start: nil, observation_end: nil, realtime_start: nil, realtime_end: nil)
      run = IngestionRun.create!(
        started_at: now,
        status: "running",
        scope: "series",
        options: run_options(series_id:, observation_start:, observation_end:, realtime_start:, realtime_end:)
      )
      counts = empty_counts
      persisted_series = nil

      ApplicationRecord.transaction do
        fred_series = @client.series(series_id)
        persisted_series = persist_series(fred_series)
        counts["series"] += 1

        @client.observations(
          fred_series.id,
          observation_start:,
          observation_end:,
          realtime_start:,
          realtime_end:
        ).each do |observation|
          persist_observation(persisted_series, observation)
          counts["observations"] += 1
        end
      end

      run.update!(finished_at: now, status: "succeeded", counts:)
      Result.new(run, persisted_series, counts)
    rescue StandardError => e
      run&.update!(
        finished_at: now,
        status: "failed",
        error_class: e.class.name,
        error_message: e.message,
        counts: counts || empty_counts
      )
      raise
    end

    private

    def persist_series(fred_series)
      Series.find_or_initialize_by(series_id: fred_series.id).tap do |record|
        record.assign_attributes(
          title: fred_series.title,
          frequency: fred_series.frequency,
          frequency_short: fred_series.frequency_short,
          units: fred_series.units,
          units_short: fred_series.units_short,
          seasonal_adjustment: fred_series.seasonal_adjustment,
          seasonal_adjustment_short: fred_series.seasonal_adjustment_short,
          observation_start: fred_series.observation_start,
          observation_end: fred_series.observation_end,
          last_updated_at: fred_series.last_updated_at,
          popularity: fred_series.popularity,
          notes: fred_series.notes,
          raw: fred_series.raw,
          last_seen_at: now
        )
        record.save!
      end
    end

    def persist_observation(series, observation)
      Observation.find_or_initialize_by(
        series_id: observation.series_id,
        observed_on: observation.observed_on,
        realtime_start: observation.realtime_start,
        realtime_end: observation.realtime_end
      ).tap do |record|
        record.assign_attributes(
          series:,
          value: observation.value,
          raw: observation.raw,
          fetched_at: now
        )
        record.save!
      end
    end

    def empty_counts
      {
        "series" => 0,
        "observations" => 0
      }
    end

    def run_options(series_id:, observation_start:, observation_end:, realtime_start:, realtime_end:)
      {
        "series_id" => series_id.to_s,
        "observation_start" => serialize_date(observation_start),
        "observation_end" => serialize_date(observation_end),
        "realtime_start" => serialize_date(realtime_start),
        "realtime_end" => serialize_date(realtime_end)
      }
    end

    def serialize_date(value)
      return if value.nil?
      return value.strftime("%Y-%m-%d") if value.respond_to?(:strftime)

      value.to_s
    end

    def now
      @clock.call
    end
  end
end
