module Rubyfin::WorldBank
  class Indicator
    attr_reader :raw

    def initialize(payload)
      @raw = payload || {}
    end

    def id
      raw["id"].to_s
    end

    def name
      raw["name"].to_s
    end

    def unit
      raw["unit"].to_s
    end

    def source_id
      raw.dig("source", "id").to_s
    end

    def source_name
      raw.dig("source", "value").to_s
    end

    def source_note
      raw["sourceNote"].to_s
    end

    def source_organization
      raw["sourceOrganization"].to_s
    end

    def topics
      Array(raw["topics"]).map do |topic|
        {
          id: topic["id"].to_s,
          name: topic["value"].to_s
        }
      end
    end

    def natural_key
      id
    end

    def to_h
      {
        id:,
        name:,
        unit:,
        source_id:,
        source_name:,
        source_note:,
        source_organization:,
        topics:
      }
    end
  end
end
