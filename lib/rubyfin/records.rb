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

  Series = Data.define(
    :source,
    :id,
    :title,
    :frequency,
    :units,
    :seasonal_adjustment,
    :observation_start,
    :observation_end,
    :last_updated_at,
    :metadata,
    :raw
  ) do
    def natural_key
      [source.id, id]
    end

    def to_h
      {
        source_id: source.id,
        id:,
        title:,
        frequency:,
        units:,
        seasonal_adjustment:,
        observation_start:,
        observation_end:,
        last_updated_at:,
        metadata:
      }
    end
  end

  Observation = Data.define(
    :source,
    :series_id,
    :observed_on,
    :value,
    :realtime_start,
    :realtime_end,
    :metadata,
    :raw
  ) do
    def natural_key
      [source.id, series_id, observed_on, realtime_start, realtime_end]
    end

    def to_h
      {
        source_id: source.id,
        series_id:,
        observed_on:,
        value:,
        realtime_start:,
        realtime_end:,
        metadata:
      }
    end
  end

  PriceBar = Data.define(
    :source,
    :symbol,
    :traded_on,
    :open,
    :high,
    :low,
    :close,
    :volume,
    :interval,
    :metadata,
    :raw
  ) do
    def natural_key
      [source.id, symbol, interval, traded_on]
    end

    def to_h
      {
        source_id: source.id,
        symbol:,
        traded_on:,
        open:,
        high:,
        low:,
        close:,
        volume:,
        interval:,
        metadata:
      }
    end
  end

  Instrument = Data.define(
    :source,
    :figi,
    :composite_figi,
    :share_class_figi,
    :ticker,
    :name,
    :exchange_code,
    :market_sector,
    :security_type,
    :security_type2,
    :security_description,
    :metadata,
    :raw
  ) do
    def natural_key
      [source.id, figi]
    end

    def to_h
      {
        source_id: source.id,
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
