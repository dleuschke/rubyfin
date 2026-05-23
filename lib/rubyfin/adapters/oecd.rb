require "rubyfin/oecd"

module Rubyfin
  module Adapters
    class Oecd
      attr_reader :client

      def initialize(client: nil, client_options: {})
        @client = client || Rubyfin::Oecd.client(**client_options)
      end

      def source
        Rubyfin::Oecd.source
      end

      def observations(dataflow, **options)
        client.data(dataflow, **options).map { |observation| wrap_observation(observation) }
      rescue Rubyfin::Oecd::NotFound => e
        raise NotFound, e.message
      end

      private

      def wrap_observation(observation)
        Rubyfin::Observation.new(
          source,
          observation.series_id,
          observation.observed_on,
          observation.value,
          nil,
          nil,
          {
            dataflow: observation.dataflow,
            requested_dataflow: observation.requested_dataflow,
            requested_key: observation.requested_key,
            period: observation.period,
            dimensions: observation.dimensions,
            attributes: observation.attributes
          },
          observation
        )
      end
    end
  end

  def self.oecd(**options)
    Adapters::Oecd.new(**options)
  end
end
