require "rubyfin/world_bank"

module Rubyfin
  module Adapters
    class WorldBank
      attr_reader :client

      def initialize(client: nil, client_options: {})
        @client = client || Rubyfin::WorldBank.client(**client_options)
      end

      def source
        Rubyfin::WorldBank.source
      end

      def series(indicator_id)
        wrap_indicator(client.indicator(indicator_id))
      rescue Rubyfin::WorldBank::NotFound => e
        raise NotFound, e.message
      end

      def observations(country, indicator_id, date: nil, per_page: nil)
        options = {}
        options[:date] = date if date
        options[:per_page] = per_page if per_page

        client.observations(country, indicator_id, **options).map { |observation| wrap_observation(observation) }
      rescue Rubyfin::WorldBank::NotFound => e
        raise NotFound, e.message
      end

      private

      def wrap_indicator(indicator)
        Rubyfin::Series.new(
          source,
          indicator.id,
          indicator.name,
          "Annual",
          indicator.unit,
          nil,
          nil,
          nil,
          nil,
          {
            source_id: indicator.source_id,
            source_name: indicator.source_name,
            source_note: indicator.source_note,
            source_organization: indicator.source_organization,
            topics: indicator.topics
          },
          indicator
        )
      end

      def wrap_observation(observation)
        Rubyfin::Observation.new(
          source,
          observation_series_id(observation),
          observation.observed_on,
          observation.value,
          nil,
          nil,
          {
            country_id: observation.country_id,
            country_name: observation.country_name,
            country_iso3_code: observation.country_iso3_code,
            period: observation.date,
            unit: observation.unit,
            status: observation.status,
            decimal: observation.decimal
          },
          observation
        )
      end

      def observation_series_id(observation)
        country = observation.country_iso3_code.empty? ? observation.country_id : observation.country_iso3_code
        "#{country}:#{observation.indicator_id}"
      end
    end
  end

  def self.world_bank(**options)
    Adapters::WorldBank.new(**options)
  end
end
