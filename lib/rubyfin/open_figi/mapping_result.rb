module Rubyfin::OpenFigi
  class MappingResult
    attr_reader :job, :raw

    def initialize(job:, payload:)
      @job = job
      @raw = payload || {}
    end

    def instruments
      Array(raw["data"]).map { |instrument| Instrument.new(instrument) }
    end

    def error
      raw["error"].to_s
    end

    def warning
      raw["warning"].to_s
    end

    def success?
      !instruments.empty?
    end

    def to_h
      {
        job:,
        instruments: instruments.map(&:to_h),
        error: error.empty? ? nil : error,
        warning: warning.empty? ? nil : warning
      }
    end
  end
end
