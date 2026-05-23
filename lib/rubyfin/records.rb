module Rubyfin
  Source = Data.define(:id, :name, :homepage_url, :metadata) do
    def to_h
      {
        id:,
        name:,
        homepage_url:,
        metadata:
      }
    end
  end

  Company = Data.define(:source, :cik, :ticker, :name, :raw) do
    def natural_key
      [source.id, cik]
    end

    def to_h
      {
        source_id: source.id,
        cik:,
        ticker:,
        name:
      }
    end
  end

  Filing = Data.define(
    :source,
    :cik,
    :ticker,
    :company_name,
    :accession,
    :form,
    :filed_at,
    :item_codes,
    :index_url,
    :primary_document_name,
    :primary_document_url,
    :items,
    :raw
  ) do
    def natural_key
      [source.id, cik, accession]
    end

    def to_h
      {
        source_id: source.id,
        cik:,
        ticker:,
        company_name:,
        accession:,
        form:,
        filed_at:,
        item_codes:,
        index_url:,
        primary_document_name:,
        primary_document_url:,
        items: items.map(&:to_h)
      }
    end
  end

  FilingItem = Data.define(:source, :cik, :ticker, :accession, :form, :filed_at, :code, :label, :raw) do
    def natural_key
      [source.id, cik, accession, code]
    end

    def to_h
      {
        source_id: source.id,
        cik:,
        ticker:,
        accession:,
        form:,
        filed_at:,
        code:,
        label:
      }
    end
  end

  CompanyFacts = Data.define(:source, :cik, :ticker, :facts, :raw) do
    def natural_key
      [source.id, cik, "company_facts"]
    end

    def to_h
      {
        source_id: source.id,
        cik:,
        ticker:,
        facts:
      }
    end
  end
end
