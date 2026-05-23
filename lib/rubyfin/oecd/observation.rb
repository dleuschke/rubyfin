require "bigdecimal"
require "date"

module Rubyfin::Oecd
  class Observation
    attr_reader :raw

    def initialize(payload:, requested_dataflow:, requested_key:, headers:)
      @raw = payload || {}
      @requested_dataflow = requested_dataflow
      @requested_key = requested_key
      @headers = headers
    end

    def dataflow
      raw["DATAFLOW"].to_s.empty? ? @requested_dataflow : raw["DATAFLOW"].to_s
    end

    def requested_dataflow
      @requested_dataflow
    end

    def requested_key
      @requested_key
    end

    def period
      raw["TIME_PERIOD"].to_s
    end

    def observed_on
      parse_period_start(period)
    end

    def value
      parse_decimal(raw["OBS_VALUE"])
    end

    def dimensions
      dimension_headers.to_h { |header| [header, raw[header].to_s] }
    end

    def attributes
      attribute_headers.to_h { |header| [header, raw[header].to_s] }
    end

    def series_key
      dimensions.values.join(".")
    end

    def series_id
      key = series_key
      key.empty? ? requested_dataflow : "#{requested_dataflow}/#{key}"
    end

    def natural_key
      [requested_dataflow, series_key, period]
    end

    def to_h
      {
        dataflow:,
        requested_dataflow:,
        requested_key:,
        period:,
        observed_on:,
        value:,
        dimensions:,
        attributes:
      }
    end

    private

    def dimension_headers
      time_index = @headers.index("TIME_PERIOD") || @headers.length
      @headers.take(time_index) - ["DATAFLOW", "ACTION"]
    end

    def attribute_headers
      value_index = @headers.index("OBS_VALUE")
      return [] unless value_index

      @headers.drop(value_index + 1)
    end

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
      when /\A(\d{4})-(\d{2})\z/
        Date.new(Regexp.last_match(1).to_i, Regexp.last_match(2).to_i, 1)
      when /\A(\d{4})-Q([1-4])\z/, /\A(\d{4})Q([1-4])\z/
        Date.new(Regexp.last_match(1).to_i, ((Regexp.last_match(2).to_i - 1) * 3) + 1, 1)
      else
        Date.iso8601(text)
      end
    rescue ArgumentError
      nil
    end
  end
end
