# OpenFIGI Adapter

Rubyfin includes an OpenFIGI adapter for identifier resolution. OpenFIGI maps
security identifiers such as tickers, ISINs, CUSIPs, and FIGIs to FIGI
instrument metadata.

OpenFIGI is not a market-data source. It does not provide prices,
fundamentals, filings, or macroeconomic data. Use it to build stable instrument
identity across providers.

The adapter is runtime-only and does not include Rails persistence or ingestion
helpers.

```ruby
require "rubyfin/open_figi"

results = Rubyfin::OpenFigi.map_ticker(
  "AAPL",
  exch_code: "US",
  api_key: ENV["OPENFIGI_API_KEY"]
)
```

## API Key

OpenFIGI can be used without an API key at lower rate limits. Rubyfin reads
`OPENFIGI_API_KEY` by default or accepts `api_key:` explicitly. Blank keys are
allowed.

```ruby
Rubyfin::OpenFigi.map_ticker("AAPL", exch_code: "US")
Rubyfin::OpenFigi.map_ticker("AAPL", exch_code: "US", api_key: "your-key")
```

## Mapping Jobs

Pass one or more mapping jobs:

```ruby
results = Rubyfin::OpenFigi.map([
  {
    id_type: "TICKER",
    id_value: "AAPL",
    exch_code: "US"
  },
  {
    id_type: "ID_ISIN",
    id_value: "US0378331005"
  }
])
```

Ruby-style option keys are converted to OpenFIGI's JSON fields:

- `id_type` -> `idType`
- `id_value` -> `idValue`
- `exch_code` -> `exchCode`
- `mic_code` -> `micCode`
- `market_sec_des` -> `marketSecDes`
- `security_type` -> `securityType`
- `security_type2` -> `securityType2`
- `include_unlisted_equities` -> `includeUnlistedEquities`

## Mapping Results

```ruby
result = Rubyfin::OpenFigi.map_ticker("AAPL", exch_code: "US").first

result.job
result.instruments
result.error
result.warning
result.success?
result.to_h
```

OpenFIGI returns one mapping result per submitted job. A result can contain
multiple instruments, warnings, or an error.

## Instruments

```ruby
instrument = result.instruments.first

instrument.figi
instrument.composite_figi
instrument.share_class_figi
instrument.ticker
instrument.name
instrument.exchange_code
instrument.market_sector
instrument.security_type
instrument.security_type2
instrument.security_description
instrument.natural_key
instrument.to_h
instrument.raw
```

## Provider-Style Records

Use `rubyfin/adapters/open_figi` when you want normalized Rubyfin instrument
records with source IDs:

```ruby
require "rubyfin/adapters/open_figi"

open_figi = Rubyfin.open_figi(api_key: ENV["OPENFIGI_API_KEY"])
instrument = open_figi.map_ticker("AAPL", exch_code: "US").flatten.first

instrument.natural_key
#=> ["open_figi", "BBG000B9XRY4"]
```

The provider wrapper returns one array of instruments per submitted mapping
job. Use `flatten` when you want a single instrument list.

## Terms Notes

OpenFIGI's API documentation describes API-key and non-key rate limits. FIGI
identifiers are dedicated to the public domain, but Bloomberg and OpenFIGI
marks must not be used to imply endorsement. Review the OpenFIGI terms before
redistribution or branding use.

## Endpoint

Rubyfin uses the OpenFIGI mapping endpoint:

- `POST https://api.openfigi.com/v3/mapping`

Requests send JSON and, when configured, the `X-OPENFIGI-APIKEY` header.
