require "bigdecimal"
require "date"

module Rubyfin::Stooq
  class PriceBar
    attr_reader :symbol, :interval, :raw

    def initialize(symbol:, interval:, payload:)
      @symbol = symbol
      @interval = interval
      @raw = payload || {}
    end

    def traded_on
      parse_date(raw["Date"])
    end

    def open
      parse_decimal(raw["Open"])
    end

    def high
      parse_decimal(raw["High"])
    end

    def low
      parse_decimal(raw["Low"])
    end

    def close
      parse_decimal(raw["Close"])
    end

    def volume
      parse_integer(raw["Volume"])
    end

    def natural_key
      [symbol, interval, traded_on]
    end

    def to_h
      {
        symbol:,
        traded_on:,
        open:,
        high:,
        low:,
        close:,
        volume:,
        interval:
      }
    end

    private

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue ArgumentError
      nil
    end

    def parse_decimal(value)
      text = value.to_s.strip
      return if text.empty?

      BigDecimal(text)
    rescue ArgumentError
      nil
    end

    def parse_integer(value)
      text = value.to_s.strip
      return if text.empty?

      Integer(text)
    rescue ArgumentError
      nil
    end
  end
end
