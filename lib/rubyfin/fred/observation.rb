require "bigdecimal"
require "date"

module Rubyfin::Fred
  class Observation
    attr_reader :series_id, :raw

    def initialize(series_id:, payload:)
      @series_id = series_id
      @raw = payload || {}
    end

    def observed_on
      parse_date(raw["date"])
    end

    def value
      parse_decimal(raw["value"])
    end

    def realtime_start
      parse_date(raw["realtime_start"])
    end

    def realtime_end
      parse_date(raw["realtime_end"])
    end

    def natural_key
      [series_id, observed_on, realtime_start, realtime_end]
    end

    def to_h
      {
        series_id:,
        observed_on:,
        value:,
        realtime_start:,
        realtime_end:
      }
    end

    private

    def parse_date(value)
      text = value.to_s.strip
      return if text.empty?

      Date.iso8601(text)
    rescue ArgumentError
      nil
    end

    def parse_decimal(value)
      text = value.to_s.strip
      return if text.empty? || text == "."

      BigDecimal(text)
    rescue ArgumentError
      nil
    end
  end
end
