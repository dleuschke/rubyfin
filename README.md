# Rubyfin

Rubyfin helps Ruby applications use public finance data without stitching
together one-off scripts for every source.

It is designed around a simple rule:

```ruby
require "rubyfin"        # core records only
require "rubyfin/edgar"  # SEC EDGAR only
```

Start with the adapter you need. Add more later.

## Install

From GitHub:

```ruby
gem "rubyfin", git: "https://github.com/dleuschke/rubyfin.git", branch: "main"
```

Then:

```bash
bundle install
```

## Use SEC EDGAR

The EDGAR adapter is built into Rubyfin.

```ruby
require "rubyfin/edgar"

company = Rubyfin::Edgar.company(
  "AAPL",
  user_agent: "Your Name you@example.com"
)

company.name
#=> "Apple Inc."

filing = company.filings.form("8-K").latest
filing.accession
filing.index_url
filing.primary_document&.url
filing.items.map { |item| [item.code, item.label] }
```

The SEC requires a descriptive `User-Agent` with contact information. Rubyfin
raises `Rubyfin::Edgar::MissingUserAgent` when it is blank.

For application config:

```ruby
company = Rubyfin::Edgar.company(
  "MSFT",
  user_agent: ENV.fetch("EDGAR_USER_AGENT")
)
```

## Provider-Style Adapter

When you want all sources to look like records with source IDs and natural keys,
use the adapter wrapper:

```ruby
require "rubyfin/adapters/edgar"

edgar = Rubyfin.edgar(user_agent: ENV.fetch("EDGAR_USER_AGENT"))

company = edgar.company("AAPL")
company.natural_key
#=> ["edgar", 320193]

filing = edgar.filings("AAPL", forms: ["8-K"]).first
filing.natural_key
#=> ["edgar", 320193, "0000320193-26-000001"]
```

Common Rubyfin records:

- `Rubyfin::Source`
- `Rubyfin::Company`
- `Rubyfin::Filing`
- `Rubyfin::FilingItem`
- `Rubyfin::CompanyFacts`

Each record exposes:

- `natural_key` for persistence.
- `to_h` for serialization.
- `raw` for the adapter-native object when useful.

## Rails: Persist EDGAR Data

Rubyfin keeps Rails optional. Plain `require "rubyfin"` and
`require "rubyfin/edgar"` do not require Active Record.

For Rails persistence:

```ruby
gem "rubyfin", git: "https://github.com/dleuschke/rubyfin.git", branch: "main"
```

Install the EDGAR tables:

```bash
bin/rails generate rubyfin:edgar:install
bin/rails db:migrate
```

Require the Rails integration, for example in `config/initializers/rubyfin.rb`:

```ruby
require "rubyfin/rails/edgar"
```

Ingest EDGAR data idempotently:

```ruby
result = Rubyfin::Rails::Edgar::Ingestor.new(
  user_agent: ENV.fetch("EDGAR_USER_AGENT")
).ingest_company(
  "AAPL",
  forms: ["8-K"],
  since: 30.days.ago,
  include_facts: true
)

result.counts
```

The generator creates:

- `rubyfin_edgar_companies`
- `rubyfin_edgar_filings`
- `rubyfin_edgar_filing_items`
- `rubyfin_edgar_company_facts`
- `rubyfin_edgar_ingestion_runs`

The Rails integration persists neutral public-source records. It does not model
trading signals, theses, alerts, portfolios, or app-specific interpretation.

## Current Adapters

- EDGAR: `require "rubyfin/edgar"`

Planned adapter shape:

```ruby
require "rubyfin/fred"
require "rubyfin/stooq"
require "rubyfin/world_bank"
require "rubyfin/oecd"
```

## Testing

```bash
bundle exec rake test
```

Tests use fake HTTP clients and do not make live provider requests.

## Documentation

- [EDGAR adapter](docs/adapters/edgar.md)
- [Contributing](CONTRIBUTING.md)
