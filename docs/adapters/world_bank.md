# World Bank Adapter

Rubyfin includes a World Bank adapter for indicator metadata and country-level
indicator observations from the World Bank Indicators API.

The adapter is runtime-only and does not include Rails persistence or ingestion
helpers.

```ruby
require "rubyfin/world_bank"

indicator = Rubyfin::WorldBank.indicator("NY.GDP.MKTP.CD")

observations = Rubyfin::WorldBank.observations(
  "us",
  "NY.GDP.MKTP.CD",
  date: "2020:2025"
)
```

## API Key

The World Bank Indicators API does not require an API key.

## Indicator Metadata

```ruby
indicator = Rubyfin::WorldBank.indicator("NY.GDP.MKTP.CD")

indicator.id
indicator.name
indicator.unit
indicator.source_id
indicator.source_name
indicator.source_note
indicator.source_organization
indicator.topics
indicator.to_h
indicator.raw
```

## Observations

Pass a World Bank country code, `all`, or multiple countries:

```ruby
Rubyfin::WorldBank.observations("us", "NY.GDP.MKTP.CD")
Rubyfin::WorldBank.observations("all", "SP.POP.TOTL", date: "2020")
Rubyfin::WorldBank.observations(["us", "ca"], "NY.GDP.MKTP.CD", date: "2020:2025")
```

Date ranges may be strings, arrays, or Ruby ranges:

```ruby
Rubyfin::WorldBank.observations("us", "NY.GDP.MKTP.CD", date: "2020:2025")
Rubyfin::WorldBank.observations("us", "NY.GDP.MKTP.CD", date: [2020, 2025])
Rubyfin::WorldBank.observations("us", "NY.GDP.MKTP.CD", date: 2020..2025)
```

```ruby
observation = Rubyfin::WorldBank.observations("us", "NY.GDP.MKTP.CD").first

observation.indicator_id
observation.indicator_name
observation.country_id
observation.country_name
observation.country_iso3_code
observation.date
observation.observed_on
observation.value
observation.unit
observation.status
observation.decimal
observation.natural_key
observation.to_h
observation.raw
```

Observation values are returned as `BigDecimal` when present. Missing values are
returned as `nil`.

## Provider-Style Records

Use `rubyfin/adapters/world_bank` when you want normalized Rubyfin records with
source IDs:

```ruby
require "rubyfin/adapters/world_bank"

world_bank = Rubyfin.world_bank

series = world_bank.series("NY.GDP.MKTP.CD")
observations = world_bank.observations("us", "NY.GDP.MKTP.CD", date: "2020:2025")
```

Natural keys:

- Series: `["world_bank", indicator_id]`
- Observation: `["world_bank", "<country>:<indicator_id>", observed_on, nil, nil]`

Country and original period fields are included in observation metadata.

## Terms Notes

World Bank open data is broadly reusable, and the World Bank Data Catalog says
World Bank-produced open datasets default to CC BY 4.0 with additional terms
unless labeled otherwise. Terms can vary by dataset, so check the Data Catalog
license and source-specific metadata before redistribution or commercial use.

## Endpoints

Rubyfin uses these official World Bank API v2 endpoints:

- `indicator/<indicator_id>`
- `country/<country>/indicator/<indicator_id>`

Rubyfin requests JSON by sending `format=json` and follows paginated responses.
