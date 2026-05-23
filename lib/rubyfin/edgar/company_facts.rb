module Rubyfin::Edgar
  class CompanyFacts
    attr_reader :company

    def initialize(company:, client:)
      @company = company
      @client = client
    end

    def raw
      @raw ||= @client.company_facts(company.cik)
    end

    def facts
      raw.fetch("facts", {})
    end

    def taxonomies
      facts.keys
    end

    def taxonomy(name)
      facts.fetch(name.to_s, {})
    end

    def us_gaap(tag = nil)
      data = taxonomy("us-gaap")
      tag ? data[tag.to_s] : data
    end

    def dei(tag = nil)
      data = taxonomy("dei")
      tag ? data[tag.to_s] : data
    end

    def to_h
      raw
    end
  end
end
