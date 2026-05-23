require "rubyfin/edgar"

module Rubyfin
  module Adapters
    class Edgar
      attr_reader :database

      def initialize(user_agent: nil, database: nil, client_options: {})
        @database = database || Rubyfin::Edgar.database(user_agent:, **client_options)
      end

      def source
        Rubyfin::Edgar.source
      end

      def company(identifier)
        wrap_company(database.company(identifier))
      rescue Rubyfin::Edgar::NotFound => e
        raise NotFound, e.message
      end

      def filings(identifier, forms: [], since: nil)
        edgar_company = database.company(identifier)
        edgar_company.filings.forms(forms).since(since).map { |filing| wrap_filing(filing) }
      rescue Rubyfin::Edgar::NotFound => e
        raise NotFound, e.message
      end

      def company_facts(identifier)
        edgar_company = database.company(identifier)
        wrap_company_facts(edgar_company, edgar_company.facts)
      rescue Rubyfin::Edgar::NotFound => e
        raise NotFound, e.message
      end

      private

      def wrap_company(company)
        Company.new(
          source,
          company.cik,
          company.ticker,
          company.name,
          company
        )
      end

      def wrap_filing(filing)
        items = filing.items.map { |item| wrap_filing_item(item) }
        Filing.new(
          source,
          filing.company.cik,
          filing.company.ticker,
          filing.company_name,
          filing.accession,
          filing.form,
          filing.filed_at,
          filing.item_codes,
          filing.index_url,
          filing.primary_document_name,
          filing.primary_document_url,
          items,
          filing
        )
      end

      def wrap_filing_item(item)
        FilingItem.new(
          source,
          item.company.cik,
          item.company.ticker,
          item.accession,
          item.form,
          item.filed_at,
          item.code,
          item.label,
          item
        )
      end

      def wrap_company_facts(company, facts)
        CompanyFacts.new(
          source,
          company.cik,
          company.ticker,
          facts.facts,
          facts
        )
      end
    end
  end

  def self.edgar(**options)
    Adapters::Edgar.new(**options)
  end
end
