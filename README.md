# Rubyfin

Rubyfin helps Ruby applications use public finance data without stitching
together one-off scripts for every source.

It is designed around a simple rule:

```ruby
require "rubyfin"        # core records only
require "rubyfin/edgar"  # SEC EDGAR only
require "rubyfin/fred"   # FRED only
require "rubyfin/stooq"  # Stooq only
require "rubyfin/world_bank" # World Bank
require "rubyfin/oecd"   # OECD only
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
- `Rubyfin::Series`
- `Rubyfin::Observation`
- `Rubyfin::PriceBar`

Each record exposes:

- `natural_key` for deduplication or persistence where source terms allow.
- `to_h` for serialization.
- `raw` for the adapter-native object when useful.

## Use FRED

FRED requires an API key from the Federal Reserve Bank of St. Louis.
Applications using the FRED API must display the required attribution notice:

```ruby
Rubyfin::Fred.attribution_notice
#=> "This product uses the FRED® API but is not endorsed or certified by the Federal Reserve Bank of St. Louis."
```

Rubyfin's FRED adapter is runtime-only. It intentionally does not ship Rails
persistence, caching, archiving, or database-ingestion helpers because the FRED
terms restrict storing, caching, archiving, redistributing, and incorporating
FRED content into databases. Review the FRED API terms and the terms for each
series before using FRED data outside personal/internal research.

```ruby
require "rubyfin/fred"

series = Rubyfin::Fred.series(
  "FEDFUNDS",
  api_key: ENV.fetch("FRED_API_KEY")
)

series.title
#=> "Federal Funds Effective Rate"

observations = series.observations(
  observation_start: Date.new(2020, 1, 1)
)

observations.first.observed_on
observations.first.value
```

For provider-style records:

```ruby
require "rubyfin/adapters/fred"

fred = Rubyfin.fred(api_key: ENV.fetch("FRED_API_KEY"))

series = fred.series("FEDFUNDS")
series.natural_key
#=> ["fred", "FEDFUNDS"]

observation = fred.observations("FEDFUNDS").first
observation.natural_key
#=> ["fred", "FEDFUNDS", #<Date ...>, #<Date ...>, #<Date ...>]
```

## Use Stooq

Stooq provides free historical market data through CSV downloads. Rubyfin's
Stooq adapter is runtime-only and does not ship Rails persistence helpers.
Review Stooq's terms and licensed-data restrictions before storing or
redistributing data. Stooq's CSV endpoint currently requires an API key;
Rubyfin reads `STOOQ_API_KEY` by default.

```ruby
require "rubyfin/stooq"

bars = Rubyfin::Stooq.prices(
  "spy.us",
  start_date: Date.new(2026, 1, 1),
  end_date: Date.new(2026, 1, 31),
  api_key: ENV.fetch("STOOQ_API_KEY")
)

bars.last.close
```

For provider-style records:

```ruby
require "rubyfin/adapters/stooq"

stooq = Rubyfin.stooq(api_key: ENV.fetch("STOOQ_API_KEY"))

bar = stooq.prices("spy.us", start_date: "2026-01-01").last
bar.natural_key
#=> ["stooq", "spy.us", "daily", #<Date ...>]
```

## Use World Bank

The World Bank Indicators API provides free country-level macro and development
indicator data without an API key. Rubyfin's World Bank adapter is runtime-only
and does not ship Rails persistence helpers.

```ruby
require "rubyfin/world_bank"

indicator = Rubyfin::WorldBank.indicator("NY.GDP.MKTP.CD")

observations = Rubyfin::WorldBank.observations(
  "us",
  "NY.GDP.MKTP.CD",
  date: "2020:2025"
)

observations.first.value
```

For provider-style records:

```ruby
require "rubyfin/adapters/world_bank"

world_bank = Rubyfin.world_bank

series = world_bank.series("NY.GDP.MKTP.CD")
observation = world_bank.observations("us", "NY.GDP.MKTP.CD", date: "2025").first

series.natural_key
#=> ["world_bank", "NY.GDP.MKTP.CD"]

observation.metadata[:country_iso3_code]
#=> "USA"

observation.natural_key
#=> ["world_bank", "USA:NY.GDP.MKTP.CD", #<Date ...>, nil, nil]
```

## Use OECD

The OECD Data Explorer API provides free SDMX-based access to OECD datasets
without an API key. Rubyfin's OECD adapter is runtime-only and generic because
OECD dataflows vary widely in dimensions and metadata.

```ruby
require "rubyfin/oecd"

observations = Rubyfin::Oecd.data(
  "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I",
  start_period: "2022",
  end_period: "2022"
)

observations.first.value
observations.first.dimensions
```

For provider-style records:

```ruby
require "rubyfin/adapters/oecd"

oecd = Rubyfin.oecd

observation = oecd.observations(
  "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I",
  start_period: "2022",
  end_period: "2022"
).first

observation.natural_key
#=> ["oecd", "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I/<dimension-key>", #<Date ...>, nil, nil]
```

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
- FRED: `require "rubyfin/fred"`
- Stooq: `require "rubyfin/stooq"`
- World Bank: `require "rubyfin/world_bank"`
- OECD: `require "rubyfin/oecd"`

Additional adapters should follow the same a la carte require pattern.

## Testing

```bash
bundle exec rake test
```

Tests use fake HTTP clients and do not make live provider requests.

## Adapter Docs

- [EDGAR adapter](docs/adapters/edgar.md)
- [FRED adapter](docs/adapters/fred.md)
- [Stooq adapter](docs/adapters/stooq.md)
- [World Bank adapter](docs/adapters/world_bank.md)
- [OECD adapter](docs/adapters/oecd.md)

## Documentation

- [EDGAR adapter](docs/adapters/edgar.md)
- [FRED adapter](docs/adapters/fred.md)
- [Contributing](CONTRIBUTING.md)
