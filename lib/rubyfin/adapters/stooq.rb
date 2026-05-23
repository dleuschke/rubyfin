require "rubyfin/stooq"

module Rubyfin
  module Adapters
    class Stooq
      attr_reader :client

      def initialize(api_key: ENV["STOOQ_API_KEY"], client: nil, client_options: {})
        @client = client || Rubyfin::Stooq.client(api_key:, **client_options)
      end

      def source
        Rubyfin::Stooq.source
      end

      def prices(symbol, start_date: nil, end_date: nil, interval: :daily)
        client.prices(symbol, start_date:, end_date:, interval:).map { |bar| wrap_price_bar(bar) }
      rescue Rubyfin::Stooq::NotFound => e
        raise NotFound, e.message
      end

      private

      def wrap_price_bar(bar)
        Rubyfin::PriceBar.new(
          source,
          bar.symbol,
          bar.traded_on,
          bar.open,
          bar.high,
          bar.low,
          bar.close,
          bar.volume,
          bar.interval,
          {},
          bar
        )
      end
    end
  end

  def self.stooq(**options)
    Adapters::Stooq.new(**options)
  end
end
