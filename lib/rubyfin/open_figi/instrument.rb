module Rubyfin::OpenFigi
  class Instrument
    attr_reader :raw

    def initialize(payload)
      @raw = payload || {}
    end

    def figi
      raw["figi"].to_s
    end

    def composite_figi
      raw["compositeFIGI"].to_s
    end

    def share_class_figi
      raw["shareClassFIGI"].to_s
    end

    def ticker
      raw["ticker"].to_s
    end

    def name
      raw["name"].to_s
    end

    def exchange_code
      raw["exchCode"].to_s
    end

    def market_sector
      raw["marketSector"].to_s
    end

    def security_type
      raw["securityType"].to_s
    end

    def security_type2
      raw["securityType2"].to_s
    end

    def security_description
      raw["securityDescription"].to_s
    end

    def metadata
      raw.reject do |key, _value|
        %w[
          figi
          compositeFIGI
          shareClassFIGI
          ticker
          name
          exchCode
          marketSector
          securityType
          securityType2
          securityDescription
        ].include?(key)
      end
    end

    def natural_key
      figi
    end

    def to_h
      {
        figi:,
        composite_figi:,
        share_class_figi:,
        ticker:,
        name:,
        exchange_code:,
        market_sector:,
        security_type:,
        security_type2:,
        security_description:,
        metadata:
      }
    end
  end
end
