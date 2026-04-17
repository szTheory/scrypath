# Operator Support

This guide is for maintainers supporting early Scrypath production usage.

For **metrics, paging discipline, and Meilisearch cluster footguns** (SRE / platform view), see `docs/search-backend-sre.md`.

The support contract stays simple:

1. operator code calls the root APIs on `Scrypath.*`
2. terminal operators can use the thin `mix scrypath.*` wrappers over those same APIs
3. **mix verify.phase14** keeps the Mix task surface, docs contract, package metadata, and docs build aligned
4. **mix verify.phase11** remains the release-contract gate

## First Response Path

When a team reports drift, failed sync, or uncertain visibility:

1. ask which schema is affected
2. run `mix scrypath.status` for current visibility
3. run `mix scrypath.failed` for explicit recovery candidates
4. run `mix scrypath.reconcile` when you need report-first guidance before changing anything

Use `mix scrypath.retry` only when you already selected a concrete failed-work id.

## Sync Mode Triage

Keep the sync mode in view during support:

- `:inline` means Scrypath waited for terminal backend success, but database and search writes are still not atomic
- `:oban` means the enqueue is durable, not that search visibility is complete
- `:manual` means accepted work was handed back for operator-controlled follow-up

The detailed operator wording lives in `guides/sync-modes-and-visibility.md`.

## Boundary Checks

Support docs should keep two boundaries explicit:

- operator visibility and recovery live on `Scrypath.*`
- backend-native search power stays under `Scrypath.Meilisearch.*`

Do not document the Mix tasks as a replacement for the root API, and do not widen `Scrypath.search/3` with Meilisearch-native flags.

## Verification

Before merge or release handoff, run:

```bash
mix verify.phase14
mix verify.phase20
mix verify.phase26
mix verify.phase11
```

| Command | What it covers (auth-free) |
|---------|----------------------------|
| **mix verify.phase14** | Thin mix scrypath.* task wrappers, docs contract, package metadata, and **mix docs --warnings-as-errors** |
| **mix verify.phase20** | Faceting, Meilisearch settings, faceted-guide docs contract, then **mix docs --warnings-as-errors** |
| **mix verify.phase26** | Failed-work rollups, reconcile output, operator Mix tasks, docs contract with **--warnings-as-errors**, then **mix docs --warnings-as-errors** |
| **mix verify.phase11** | Release path: package metadata, clean-consumer smoke, release-doc contract, docs build, workflow checks, **mix hex.build --unpack** |

**mix verify.phase11** remains the gate you use before a real publish flow.
