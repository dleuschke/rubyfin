# OECD Adapter

Rubyfin includes an OECD adapter for generic data queries against the OECD Data
Explorer SDMX API.

OECD dataflows vary widely in dimensions and metadata. Rubyfin keeps the first
adapter intentionally generic: it retrieves CSV data for an OECD dataflow,
parses `TIME_PERIOD` and `OBS_VALUE`, and preserves all other SDMX dimensions
and attributes in metadata.

The adapter is runtime-only and does not include Rails persistence or ingestion
helpers.

```ruby
require "rubyfin/oecd"

observations = Rubyfin::Oecd.data(
  "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I",
  start_period: "2022",
  end_period: "2022"
)
```

## API Key

The OECD Data Explorer API does not require an API key. OECD says the APIs are
free of charge and subject to the OECD Terms and Conditions. OECD has also
introduced rate limiting, so keep queries narrow and avoid pulling entire large
dataflows unnecessarily.

## Dataflow and Keys

Pass the OECD dataflow id exactly as shown by the OECD Data Explorer Developer
API query builder:

```ruby
Rubyfin::Oecd.data("OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I")
```

You may also pass an SDMX key filter:

```ruby
Rubyfin::Oecd.data(
  "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I",
  key: "<sdmx-key-from-query-builder>",
  start_period: "2020",
  end_period: "2022"
)
```

For reliable keys, use the Developer API query builder in OECD Data Explorer.

## Observations

```ruby
observation = Rubyfin::Oecd.data(
  "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I",
  start_period: "2022",
  end_period: "2022"
).first

observation.dataflow
observation.requested_dataflow
observation.requested_key
observation.period
observation.observed_on
observation.value
observation.dimensions
observation.attributes
observation.series_key
observation.series_id
observation.natural_key
observation.to_h
observation.raw
```

Observation values are returned as `BigDecimal` when present. Missing values are
returned as `nil`.

## Provider-Style Records

Use `rubyfin/adapters/oecd` when you want normalized Rubyfin observation records
with source IDs:

```ruby
require "rubyfin/adapters/oecd"

oecd = Rubyfin.oecd

observations = oecd.observations(
  "OECD.SDD.NAD,DSD_NAAG@DF_NAAG_I",
  start_period: "2022",
  end_period: "2022"
)
```

Natural key:

- Observation: `["oecd", series_id, observed_on, nil, nil]`

The normalized `series_id` is the requested dataflow plus the dot-joined SDMX
dimension values for that observation. The original dataflow, requested key,
period, dimensions, and attributes are kept in observation metadata.

## Terms Notes

The OECD API page says these APIs are free of charge and subject to OECD Terms
and Conditions. OECD asks API users to use the service responsibly and notes
rate limiting. Some large datasets have additional parameter restrictions to
protect service performance.

## Endpoint

Rubyfin uses the OECD SDMX REST data endpoint:

- `https://sdmx.oecd.org/public/rest/data/<dataflow>/<key>`

Rubyfin requests `format=csvfile`. Optional date filters are sent as
`startPeriod` and `endPeriod`.
