require "rubyfin/open_figi"

module Rubyfin
  module Adapters
    class OpenFigi
      attr_reader :client

      def initialize(api_key: ENV["OPENFIGI_API_KEY"], client: nil, client_options: {})
        @client = client || Rubyfin::OpenFigi.client(api_key:, **client_options)
      end

      def source
        Rubyfin::OpenFigi.source
      end

      def map(jobs)
        client.map(jobs).map { |result| wrap_result(result) }
      rescue Rubyfin::OpenFigi::NotFound => e
        raise NotFound, e.message
      end

      def map_ticker(ticker, **options)
        client.map_ticker(ticker, **options).map { |result| wrap_result(result) }
      rescue Rubyfin::OpenFigi::NotFound => e
        raise NotFound, e.message
      end

      private

      def wrap_result(result)
        result.instruments.map { |instrument| wrap_instrument(instrument, result:) }
      end

      def wrap_instrument(instrument, result:)
        Rubyfin::Instrument.new(
          source,
          instrument.figi,
          instrument.composite_figi,
          instrument.share_class_figi,
          instrument.ticker,
          instrument.name,
          instrument.exchange_code,
          instrument.market_sector,
          instrument.security_type,
          instrument.security_type2,
          instrument.security_description,
          instrument.metadata.merge(
            job: result.job,
            warning: result.warning.empty? ? nil : result.warning
          ),
          instrument
        )
      end
    end
  end

  def self.open_figi(**options)
    Adapters::OpenFigi.new(**options)
  end
end
