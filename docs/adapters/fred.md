# FRED Adapter

Rubyfin includes a FRED adapter for economic time series metadata, search, and
observations. FRED is provided by the Federal Reserve Bank of St. Louis.

```ruby
require "rubyfin/fred"

series = Rubyfin::Fred.series(
  "FEDFUNDS",
  api_key: ENV.fetch("FRED_API_KEY")
)
```

## API Key

FRED requires an API key for API requests. Rubyfin reads `FRED_API_KEY` by
default or accepts `api_key:` explicitly.

```ruby
Rubyfin::Fred.series("GDP", api_key: "your-key")
```

Blank keys raise `Rubyfin::Fred::MissingApiKey`.

## Series Metadata

```ruby
series = Rubyfin::Fred.series("FEDFUNDS", api_key: ENV.fetch("FRED_API_KEY"))

series.id
series.title
series.frequency
series.units
series.seasonal_adjustment
series.observation_start
series.observation_end
series.last_updated_at
series.to_h
series.raw
```

## Observations

```ruby
observations = series.observations(
  observation_start: Date.new(2020, 1, 1),
  observation_end: Date.new(2026, 1, 1)
)

observation = observations.first
observation.observed_on
observation.value
observation.realtime_start
observation.realtime_end
observation.natural_key
```

FRED missing values are returned as `nil` when FRED sends `"."`.

## Search

```ruby
results = Rubyfin::Fred.search(
  "federal funds",
  api_key: ENV.fetch("FRED_API_KEY")
)

results.map(&:id)
```

## Provider-Style Records

Use `rubyfin/adapters/fred` when you want normalized Rubyfin records with source
IDs:

```ruby
require "rubyfin/adapters/fred"

fred = Rubyfin.fred(api_key: ENV.fetch("FRED_API_KEY"))

series = fred.series("FEDFUNDS")
observations = fred.observations("FEDFUNDS", observation_start: "2020-01-01")
```

Natural keys:

- Series: `["fred", series_id]`
- Observation: `["fred", series_id, observed_on, realtime_start, realtime_end]`

## Rails Persistence

Install tables:

```bash
bin/rails generate rubyfin:fred:install
bin/rails db:migrate
```

Require the integration:

```ruby
require "rubyfin/rails/fred"
```

Run ingestion:

```ruby
Rubyfin::Rails::Fred::Ingestor.new(
  api_key: ENV.fetch("FRED_API_KEY")
).ingest_series(
  "FEDFUNDS",
  observation_start: Date.new(2020, 1, 1)
)
```

Models:

- `Rubyfin::Rails::Fred::Series`
- `Rubyfin::Rails::Fred::Observation`
- `Rubyfin::Rails::Fred::IngestionRun`

Tables:

- `rubyfin_fred_series`
- `rubyfin_fred_observations`
- `rubyfin_fred_ingestion_runs`

Repeated ingestion updates existing rows by natural key instead of creating
duplicates.

## Endpoints

Rubyfin uses these official FRED API endpoints:

- `fred/series`
- `fred/series/search`
- `fred/series/observations`

Rubyfin requests JSON by sending `file_type=json`.
