# EDGAR Adapter

Rubyfin includes a SEC EDGAR adapter for company lookup, filings, 8-K filing
items, primary filing documents, and XBRL company facts.

```ruby
require "rubyfin/edgar"

company = Rubyfin::Edgar.company(
  "AAPL",
  user_agent: ENV.fetch("EDGAR_USER_AGENT")
)
```

## SEC User Agent

The SEC requires automated clients to send a descriptive `User-Agent` with
contact information.

```ruby
Rubyfin::Edgar.company(
  "AAPL",
  user_agent: "Jane Doe jane@example.com"
)
```

Blank user agents raise `Rubyfin::Edgar::MissingUserAgent`.

## Company Lookup

```ruby
company = Rubyfin::Edgar.company("AAPL", user_agent: ENV.fetch("EDGAR_USER_AGENT"))

company.cik
company.ticker
company.name
company.to_h
company.natural_key
```

Unknown tickers and CIKs raise `Rubyfin::Edgar::NotFound`.

## Filings

```ruby
filings = company.filings
  .forms("8-K", "10-Q")
  .since(Time.utc(2026, 1, 1))
  .to_a

filing = filings.first
filing.accession
filing.form
filing.filed_at
filing.index_url
filing.primary_document&.url
filing.items.map(&:label)
```

Convenience methods:

```ruby
company.latest_8k
company.latest_10q
company.latest_10k
company.filing("0000320193-26-000001")
```

## Company Facts

```ruby
facts = company.facts

facts.taxonomies
facts.us_gaap("Revenues")
facts.dei("EntityRegistrantName")
facts.to_h
```

## Provider-Style Records

Use `rubyfin/adapters/edgar` when you want normalized Rubyfin records with
source IDs:

```ruby
require "rubyfin/adapters/edgar"

edgar = Rubyfin.edgar(user_agent: ENV.fetch("EDGAR_USER_AGENT"))

company = edgar.company("AAPL")
filing = edgar.filings("AAPL", forms: ["8-K"]).first
facts = edgar.company_facts("AAPL")
```

Natural keys:

- Company: `["edgar", cik]`
- Filing: `["edgar", cik, accession]`
- Filing item: `["edgar", cik, accession, code]`
- Company facts: `["edgar", cik, "company_facts"]`

## Rails Persistence

Install tables:

```bash
bin/rails generate rubyfin:edgar:install
bin/rails db:migrate
```

Require the integration:

```ruby
require "rubyfin/rails/edgar"
```

Run ingestion:

```ruby
Rubyfin::Rails::Edgar::Ingestor.new(
  user_agent: ENV.fetch("EDGAR_USER_AGENT")
).ingest_company(
  "AAPL",
  forms: ["8-K"],
  since: 30.days.ago,
  include_facts: true
)
```

Models:

- `Rubyfin::Rails::Edgar::Company`
- `Rubyfin::Rails::Edgar::Filing`
- `Rubyfin::Rails::Edgar::FilingItem`
- `Rubyfin::Rails::Edgar::CompanyFact`
- `Rubyfin::Rails::Edgar::IngestionRun`

Tables:

- `rubyfin_edgar_companies`
- `rubyfin_edgar_filings`
- `rubyfin_edgar_filing_items`
- `rubyfin_edgar_company_facts`
- `rubyfin_edgar_ingestion_runs`

Repeated ingestion updates existing rows by natural key instead of creating
duplicates.
