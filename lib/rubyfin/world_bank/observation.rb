require "bigdecimal"
require "date"

module Rubyfin::WorldBank
  class Observation
    attr_reader :raw

    def initialize(payload)
      @raw = payload || {}
    end

    def indicator_id
      raw.dig("indicator", "id").to_s
    end

    def indicator_name
      raw.dig("indicator", "value").to_s
    end

    def country_id
      raw.dig("country", "id").to_s
    end

    def country_name
      raw.dig("country", "value").to_s
    end

    def country_iso3_code
      raw["countryiso3code"].to_s
    end

    def date
      raw["date"].to_s
    end

    def observed_on
      parse_period_start(date)
    end

    def value
      parse_decimal(raw["value"])
    end

    def unit
      raw["unit"].to_s
    end

    def status
      raw["obs_status"].to_s
    end

    def decimal
      Integer(raw["decimal"])
    rescue ArgumentError, TypeError
      nil
    end

    def natural_key
      [country_id, indicator_id, date]
    end

    def to_h
      {
        indicator_id:,
        indicator_name:,
        country_id:,
        country_name:,
        country_iso3_code:,
        date:,
        observed_on:,
        value:,
        unit:,
        status:,
        decimal:
      }
    end

    private

    def parse_decimal(value)
      return if value.nil?

      text = value.to_s.strip
      return if text.empty?

      BigDecimal(text)
    rescue ArgumentError
      nil
    end

    def parse_period_start(value)
      text = value.to_s.strip
      case text
      when /\A(\d{4})\z/
        Date.new(Regexp.last_match(1).to_i, 1, 1)
      when /\A(\d{4})M(\d{2})\z/
        Date.new(Regexp.last_match(1).to_i, Regexp.last_match(2).to_i, 1)
      when /\A(\d{4})Q([1-4])\z/
        Date.new(Regexp.last_match(1).to_i, ((Regexp.last_match(2).to_i - 1) * 3) + 1, 1)
      else
        Date.iso8601(text)
      end
    rescue ArgumentError
      nil
    end
  end
end
