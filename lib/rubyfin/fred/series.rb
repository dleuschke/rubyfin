require "date"
require "time"

module Rubyfin::Fred
  class Series
    attr_reader :raw

    def initialize(payload, client:)
      @raw = payload || {}
      @client = client
    end

    def id
      raw["id"].to_s
    end

    def title
      raw["title"].to_s
    end

    def frequency
      raw["frequency"].to_s
    end

    def frequency_short
      raw["frequency_short"].to_s
    end

    def units
      raw["units"].to_s
    end

    def units_short
      raw["units_short"].to_s
    end

    def seasonal_adjustment
      raw["seasonal_adjustment"].to_s
    end

    def seasonal_adjustment_short
      raw["seasonal_adjustment_short"].to_s
    end

    def observation_start
      parse_date(raw["observation_start"])
    end

    def observation_end
      parse_date(raw["observation_end"])
    end

    def last_updated_at
      parse_time(raw["last_updated"])
    end

    def popularity
      Integer(raw["popularity"])
    rescue ArgumentError, TypeError
      nil
    end

    def notes
      raw["notes"].to_s
    end

    def observations(observation_start: nil, observation_end: nil, realtime_start: nil, realtime_end: nil)
      @client.observations(
        id,
        observation_start:,
        observation_end:,
        realtime_start:,
        realtime_end:
      )
    end

    def natural_key
      id
    end

    def to_h
      {
        id:,
        title:,
        frequency:,
        frequency_short:,
        units:,
        units_short:,
        seasonal_adjustment:,
        seasonal_adjustment_short:,
        observation_start:,
        observation_end:,
        last_updated_at:,
        popularity:,
        notes:
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

    def parse_time(value)
      text = value.to_s.strip
      return if text.empty?

      Time.parse(text)
    rescue ArgumentError
      nil
    end
  end
end
