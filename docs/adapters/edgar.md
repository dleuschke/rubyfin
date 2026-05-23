# EDGAR Adapter

The EDGAR adapter exposes SEC EDGAR data through Rubyfin's common record shape
while delegating SEC-specific behavior to Redgar.

Add both gems until Redgar is published to RubyGems:

```ruby
gem "rubyfin", git: "https://github.com/dleuschke/rubyfin.git", branch: "main"
gem "redgar", git: "https://github.com/dleuschke/redgar.git", branch: "main"
```

```ruby
require "rubyfin/adapters/edgar"

edgar = Rubyfin.edgar(user_agent: ENV.fetch("EDGAR_USER_AGENT"))
```

## Source

```ruby
edgar.source
#=> #<data Rubyfin::Source id="edgar", name="SEC EDGAR", ...>
```

## Company Lookup

```ruby
company = edgar.company("AAPL")
company.natural_key
#=> ["edgar", 320193]
company.raw
#=> #<Redgar::Company ...>
```

Unknown tickers and CIKs raise `Rubyfin::NotFound`.

## Filings

```ruby
filings = edgar.filings(
  "AAPL",
  forms: ["8-K"],
  since: Time.utc(2026, 1, 1)
)

filing = filings.first
filing.item_codes
filing.items.map(&:label)
filing.primary_document_url
```

`Rubyfin::Filing#raw` is the original `Redgar::Filing`.

## Company Facts

```ruby
facts = edgar.company_facts("AAPL")
facts.facts.fetch("us-gaap")
facts.raw
#=> #<Redgar::CompanyFacts ...>
```

## SEC User Agent

The SEC requires a descriptive user agent with contact information. Redgar
enforces this requirement, and Rubyfin surfaces the same behavior through the
adapter.

```ruby
Rubyfin.edgar(user_agent: "Jane Doe jane@example.com")
```

## Persistence

Rubyfin records expose stable natural keys:

- Company: `["edgar", cik]`
- Filing: `["edgar", cik, accession]`
- Filing item: `["edgar", cik, accession, code]`
- Company facts: `["edgar", cik, "company_facts"]`

Use these keys when storing records in Rails, SQL, object storage, or event logs.
