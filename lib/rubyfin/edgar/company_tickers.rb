module Rubyfin::Edgar
  class CompanyTickers
    Entry = Data.define(:cik, :ticker, :name)

    def self.parse(payload)
      new(payload).entries
    end

    def initialize(payload)
      @payload = payload || {}
    end

    def entries
      @payload.values.filter_map do |entry|
        cik = integer(entry["cik_str"])
        ticker = entry["ticker"].to_s.upcase.strip
        name = entry["title"].to_s.strip
        next if cik.nil? || ticker.empty? || name.empty?

        Entry.new(cik, ticker, name)
      end
    end

    private

    def integer(value)
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
