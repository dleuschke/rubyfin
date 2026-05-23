module Rubyfin::Edgar
  class Company
    attr_reader :cik, :ticker, :name

    def initialize(cik:, ticker:, name:, client:)
      @cik = cik
      @ticker = ticker
      @name = name
      @client = client
    end

    def filings
      FilingCollection.new(company: self, client: @client)
    end

    def filing(accession)
      filings.accession(accession)
    end

    def latest_10k
      filings.form("10-K").latest
    end

    def latest_10q
      filings.form("10-Q").latest
    end

    def latest_8k
      filings.form("8-K").latest
    end

    def facts
      CompanyFacts.new(company: self, client: @client)
    end

    def natural_key
      cik
    end

    def to_h
      {
        cik:,
        ticker:,
        name:
      }
    end

    def inspect
      "#<#{self.class.name} ticker=#{ticker.inspect} cik=#{cik.inspect} name=#{name.inspect}>"
    end
  end
end
