# Contributing to Rubyfin

Rubyfin adapters should stay small, composable, and documented.

## Local Setup

```bash
bundle install
bundle exec rake test
```

## Adapter Rules

- Load provider-specific code only from the adapter require path.
- Keep core `require "rubyfin"` dependency-light.
- Preserve provider-native objects in `raw` when useful.
- Provide stable `natural_key` values for persistence.
- Document source-specific rate limits, keys, freshness, and backfill behavior.
- Use fake clients in tests; live provider smoke tests should be explicit.
- For Rails support, keep integrations optional and adapter-specific, such as
  `require "rubyfin/rails/edgar"` or `require "rubyfin/rails/fred"`.

## Documentation

When adding an adapter, add:

- README mention.
- `docs/adapters/<name>.md`.
- Tests for records, natural keys, and error mapping.
