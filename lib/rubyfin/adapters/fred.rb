require "rubyfin/fred"

module Rubyfin
  module Adapters
    class Fred
      attr_reader :client

      def initialize(api_key: ENV["FRED_API_KEY"], client: nil, client_options: {})
        @client = client || Rubyfin::Fred.client(api_key:, **client_options)
      end

      def source
        Rubyfin::Fred.source
      end

      def series(series_id)
        wrap_series(client.series(series_id))
      rescue Rubyfin::Fred::NotFound => e
        raise NotFound, e.message
      end

      def search(search_text, limit: nil, offset: nil)
        client.search(search_text, limit:, offset:).map { |series| wrap_series(series) }
      end

      def observations(series_id, observation_start: nil, observation_end: nil, realtime_start: nil, realtime_end: nil)
        client.observations(
          series_id,
          observation_start:,
          observation_end:,
          realtime_start:,
          realtime_end:
        ).map { |observation| wrap_observation(observation) }
      end

      private

      def wrap_series(series)
        Rubyfin::Series.new(
          source,
          series.id,
          series.title,
          series.frequency,
          series.units,
          series.seasonal_adjustment,
          series.observation_start,
          series.observation_end,
          series.last_updated_at,
          {
            frequency_short: series.frequency_short,
            units_short: series.units_short,
            seasonal_adjustment_short: series.seasonal_adjustment_short,
            popularity: series.popularity,
            notes: series.notes
          },
          series
        )
      end

      def wrap_observation(observation)
        Rubyfin::Observation.new(
          source,
          observation.series_id,
          observation.observed_on,
          observation.value,
          observation.realtime_start,
          observation.realtime_end,
          {},
          observation
        )
      end
    end
  end

  def self.fred(**options)
    Adapters::Fred.new(**options)
  end
end
