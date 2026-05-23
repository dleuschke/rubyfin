module Rubyfin::Edgar
  class Filing
    attr_reader :company

    def initialize(company:, record:, client:)
      @company = company
      @record = record
      @client = client
    end

    def accession
      @record.accession
    end

    def form
      @record.form
    end

    def filed_at
      @record.filed_at
    end

    def company_name
      @record.company_name || @company.name
    end

    def primary_document_name
      @record.primary_document
    end

    def item_codes
      @record.item_codes
    end

    def items
      item_codes.map { |code| FilingItem.new(code:, filing: self) }
    end

    def index_url
      @client.filing_index_url(cik: company.cik, accession:)
    end

    def primary_document
      return unless primary_document_name

      Document.new(name: primary_document_name, url: primary_document_url, filing: self)
    end

    def primary_document_url
      @client.primary_document_url(cik: company.cik, accession:, document: primary_document_name)
    end

    def natural_key
      [company.cik, accession]
    end

    def to_h
      {
        cik: company.cik,
        ticker: company.ticker,
        accession:,
        form:,
        filed_at:,
        company_name:,
        item_codes:,
        primary_document_name:,
        index_url:,
        primary_document_url:
      }
    end

    def inspect
      "#<#{self.class.name} ticker=#{company.ticker.inspect} form=#{form.inspect} accession=#{accession.inspect}>"
    end
  end
end
