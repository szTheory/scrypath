# Operator Support

This guide is for maintainers supporting early Scrypath production usage.

For **metrics, paging discipline, and Meilisearch cluster footguns** (SRE / platform view), see [Search backend operations](search-backend-sre.md).

For supported versions, readiness posture, and `mix verify.adopter` versus `mix verify.adopter --live`, use [Support and compatibility](../guides/support-and-compatibility.md). For outside-adopter evidence, Class A-D classification, and maintainer routing vocabulary, use [Outside-adopter intake](../guides/outside-adopter-intake.md).

The support contract stays simple:

1. operator code calls the root APIs on `Scrypath.*`
2. terminal operators can use the thin `mix scrypath.*` wrappers over those same APIs
3. **mix verify.phase14** keeps the core Mix task surface, docs contract, package metadata, and docs build aligned
4. **mix verify.phase28** covers the **index contract drift** CLI and operator docs checks (focused tests plus **`mix docs --warnings-as-errors`**)
5. **mix verify.phase11** remains the release-contract gate

## First Response Path

When a team reports drift, failed sync, or uncertain visibility:

1. ask which schema is affected
2. route support/readiness questions to [Support and compatibility](../guides/support-and-compatibility.md)
3. route outside-adopter reports to [Outside-adopter intake](../guides/outside-adopter-intake.md)
4. run `mix scrypath.status` for current visibility
5. run `mix scrypath.failed` for explicit recovery candidates
6. run **`mix scrypath.index.contract_drift YOUR_SCHEMA`** (or **`Scrypath.index_contract_drift/2`**) when the question is **declared schema vs live index contract** (fields, filterables, sortables, faceting, settings families) — distinct from queue failure triage alone
7. run `mix scrypath.reconcile` when you need report-first guidance before changing anything

Use `mix scrypath.retry` only when you already selected a concrete failed-work id.

If a report asks to reopen feature-lane scope, route the decision to [Scope and reopen policy](../guides/scope-and-reopen-policy.md): reopening requires a **concrete production bug**, **reviewed outside-adopter evidence**, or a **deliberate strategic product decision** before proposing new scope.

## Sync Mode Triage

Keep the sync mode in view during support:

- `:inline` means Scrypath waited for terminal backend success, but database and search writes are still not atomic
- `:oban` means the enqueue is durable, not that search visibility is complete
- `:manual` means accepted work was handed back for operator-controlled follow-up

The detailed operator wording lives in [Sync modes and visibility](../guides/sync-modes-and-visibility.md).

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
mix verify.phase28
mix verify.phase11
```

| Command | What it covers (auth-free) |
|---------|----------------------------|
| **mix verify.phase14** | Thin mix scrypath.* task wrappers, docs contract, package metadata, and **mix docs --warnings-as-errors** |
| **mix verify.phase20** | Faceting, Meilisearch settings, faceted-guide docs contract, then **mix docs --warnings-as-errors** |
| **mix verify.phase26** | Failed-work rollups, reconcile output, operator Mix tasks, docs contract with **--warnings-as-errors**, then **mix docs --warnings-as-errors** |
| **mix verify.phase28** | Index contract drift CLI (`mix scrypath.index.contract_drift`), operator docs contracts, focused tests with **--warnings-as-errors**, then **mix docs --warnings-as-errors** |
| **mix verify.phase11** | Release path: package metadata, clean-consumer smoke, release-doc contract, docs build, workflow checks, **mix hex.build --unpack** |

**mix verify.phase11** remains the gate you use before a real publish flow.
