module Rubyfin::Edgar
  class Document
    attr_reader :name, :url, :filing

    def initialize(name:, url:, filing:)
      @name = name
      @url = url
      @filing = filing
    end

    def natural_key
      [filing.company.cik, filing.accession, name]
    end

    def to_h
      {
        cik: filing.company.cik,
        accession: filing.accession,
        name:,
        url:
      }
    end

    def inspect
      "#<#{self.class.name} name=#{name.inspect} url=#{url.inspect}>"
    end
  end
end
