module Rubyfin::Edgar
  class Database
    def initialize(client:)
      @client = client
    end

    def company(identifier)
      entry = company_entry(identifier)
      raise NotFound, "SEC company not found for #{identifier.inspect}" unless entry

      Company.new(cik: entry.cik, ticker: entry.ticker, name: entry.name, client: @client)
    end

    def companies
      company_tickers.map do |entry|
        Company.new(cik: entry.cik, ticker: entry.ticker, name: entry.name, client: @client)
      end
    end

    def company_tickers(refresh: false)
      @company_tickers = nil if refresh
      @company_tickers ||= CompanyTickers.parse(@client.company_tickers)
    end

    private

    def company_entry(identifier)
      normalized = identifier.to_s.upcase.strip
      return company_tickers.find { |entry| entry.cik == normalized.to_i } if normalized.match?(/\A\d+\z/)

      variants = [normalized, normalized.tr(".", "-")].uniq
      company_tickers.find { |entry| variants.include?(entry.ticker) }
    end
  end
end
