# Stooq Adapter

Rubyfin includes a Stooq adapter for historical OHLCV price bars. Stooq provides
free historical market data through CSV downloads.

The adapter is runtime-only and does not include Rails persistence or ingestion
helpers.

```ruby
require "rubyfin/stooq"

bars = Rubyfin::Stooq.prices(
  "aapl.us",
  start_date: Date.new(2026, 1, 1),
  end_date: Date.new(2026, 1, 31),
  api_key: ENV.fetch("STOOQ_API_KEY")
)
```

## API Key

Stooq's CSV download endpoint currently requires an `apikey` query parameter.
Rubyfin reads `STOOQ_API_KEY` by default or accepts `api_key:` explicitly.

```ruby
Rubyfin::Stooq.prices("spy.us", api_key: "your-key")
```

Blank keys raise `Rubyfin::Stooq::MissingApiKey`. Stooq may also return an API
key prompt for missing or expired keys; Rubyfin maps that response to the same
error.

## Symbols

Pass Stooq-native symbols. U.S. listed securities commonly use the `.us`
suffix:

```ruby
Rubyfin::Stooq.prices("spy.us", api_key: ENV.fetch("STOOQ_API_KEY"))
Rubyfin::Stooq.prices("aapl.us", api_key: ENV.fetch("STOOQ_API_KEY"))
Rubyfin::Stooq.prices("^spx", api_key: ENV.fetch("STOOQ_API_KEY"))
```

Rubyfin normalizes symbols to lowercase for stable keys.

## Intervals

The client supports the intervals exposed by the Stooq historical download
form:

- `:daily`
- `:weekly`
- `:monthly`
- `:quarterly`
- `:yearly`

```ruby
Rubyfin::Stooq.prices("spy.us", interval: :weekly, api_key: ENV.fetch("STOOQ_API_KEY"))
```

## Price Bars

```ruby
bar = Rubyfin::Stooq.prices("spy.us", api_key: ENV.fetch("STOOQ_API_KEY")).last

bar.symbol
bar.traded_on
bar.open
bar.high
bar.low
bar.close
bar.volume
bar.interval
bar.natural_key
bar.to_h
bar.raw
```

Numeric prices are returned as `BigDecimal`. Volume is returned as an integer
when present.

## Provider-Style Records

Use `rubyfin/adapters/stooq` when you want normalized Rubyfin records with
source IDs:

```ruby
require "rubyfin/adapters/stooq"

stooq = Rubyfin.stooq(api_key: ENV.fetch("STOOQ_API_KEY"))
bars = stooq.prices("spy.us", start_date: "2026-01-01")
```

Natural key:

- Price bar: `["stooq", symbol, interval, traded_on]`

These keys identify records for runtime reconciliation. Check Stooq's terms and
any licensed-data restrictions before storing, caching, archiving, or
redistributing Stooq data.

## Terms Notes

Stooq's terms state that data may contain errors, continuous access is not
guaranteed, and redistribution is not allowed without Stooq's consent. Some
licensed datasets, including S&P Dow Jones indices and London Metal Exchange
data, carry additional restrictions.

## Endpoint

Rubyfin uses Stooq's historical CSV download endpoint:

- `https://stooq.com/q/d/l/?s=<symbol>&i=<interval>`

Optional date filters are sent as `d1=YYYYMMDD` and `d2=YYYYMMDD`.
