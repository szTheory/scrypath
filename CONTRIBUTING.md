# Contributing

## Verification

Use the normal fast suite during development:

```sh
mix test --exclude integration
```

Run the full Phase 5 verification flow when you change backfill, reindex, Meilisearch integration, or the operator docs:

```sh
SCRYPATH_INTEGRATION=1 \
SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 \
mix verify.phase5
```

That command runs:

- focused Phase 5 contract tests
- documentation contract tests
- `mix docs --warnings-as-errors`
- live Meilisearch integration verification

If you do not have a Meilisearch instance running locally, you can still run the non-integration portion:

```sh
mix verify.phase5 --skip-integration
```

## CI

GitHub Actions runs three lanes:

- core test matrix: compile warnings-as-errors and `mix test --exclude integration`
- quality: format, Credo, Dialyzer, docs, and Hex audit
- Phase 5 verification: live Meilisearch service plus `mix verify.phase5`
