# Rubyfin

Rubyfin is a Ruby toolkit for a la carte adapters over free and public financial
data sources. It provides a small common record shape while keeping provider
logic in focused adapters.

The first adapter is SEC EDGAR through [Redgar](https://github.com/dleuschke/redgar).

```ruby
require "rubyfin/adapters/edgar"

edgar = Rubyfin.edgar(user_agent: "Your Name you@example.com")

company = edgar.company("AAPL")
company.to_h
#=> { source_id: "edgar", cik: 320193, ticker: "AAPL", name: "Apple Inc." }

filing = edgar.filings("AAPL", forms: ["8-K"]).first
filing.natural_key
#=> ["edgar", 320193, "0000320193-26-000001"]
```

## Design

Rubyfin is intentionally not one giant finance client. Adapters are loaded only
when requested:

```ruby
require "rubyfin"                 # core records only
require "rubyfin/adapters/edgar"  # SEC EDGAR adapter backed by Redgar
```

Core records:

- `Rubyfin::Source`
- `Rubyfin::Company`
- `Rubyfin::Filing`
- `Rubyfin::FilingItem`
- `Rubyfin::CompanyFacts`

Every record exposes:

- `natural_key` for persistence.
- `to_h` for app-level serialization.
- `raw` when there is a provider-native object worth preserving.

## Installation

From GitHub:

```ruby
gem "rubyfin", git: "https://github.com/dleuschke/rubyfin.git", branch: "main"
```

For the EDGAR adapter, also include Redgar:

```ruby
gem "redgar", git: "https://github.com/dleuschke/redgar.git", branch: "main"
```

During local development:

```ruby
gem "rubyfin", path: "../rubyfin"
gem "redgar", path: "../redgar"
```

## EDGAR Adapter

```ruby
require "rubyfin/adapters/edgar"

edgar = Rubyfin.edgar(user_agent: ENV.fetch("EDGAR_USER_AGENT"))

company = edgar.company("MSFT")
filings = edgar.filings("MSFT", forms: ["8-K", "10-Q"], since: Time.utc(2026, 1, 1))
facts = edgar.company_facts("MSFT")
```

The EDGAR adapter delegates SEC-specific behavior to Redgar. Rubyfin keeps only
the provider-agnostic record wrapper.

See [docs/adapters/edgar.md](docs/adapters/edgar.md).

## Testing

```bash
bundle exec rake test
```

Tests use fake HTTP clients and do not make live SEC requests.
