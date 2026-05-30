# Contributing

## First hour and canonical docs

- New contributors: follow the README **Quick Path** into [`guides/golden-path.md`](guides/golden-path.md) for the linear **`:inline`** first-hour story.
- Current support/readiness truth lives in [`guides/support-and-compatibility.md`](guides/support-and-compatibility.md). When README, maintainer commands, CI wording, or the example runbook change, keep that guide as the single authority instead of turning this file into a second matrix.
- Use release-backed guidance from [`guides/support-and-compatibility.md`](guides/support-and-compatibility.md) for adopter-facing policy; main may contain unreleased changes.
- For the outside-adopter review workflow, evidence classes (Class A through D), and verification commands, refer to [`guides/outside-adopter-intake.md`](guides/outside-adopter-intake.md). Do not duplicate the intake checklist or live runbook here.
- The canonical adopter mental-model guide is [`guides/jtbd-and-user-flows.md`](guides/jtbd-and-user-flows.md). Update it when the library adds, removes, or materially changes a user-facing flow.
- **Sync modes, visibility, and operator lifecycle** live in [`guides/sync-modes-and-visibility.md`](guides/sync-modes-and-visibility.md)—update that guide instead of duplicating semantics in README or here.
- Changing published docs should keep **`mix docs --warnings-as-errors`** green. The optional docs contract suite remains available via **`mix test test/scrypath/docs_contract_test.exs`**, but it is no longer part of the default CI and release gates.

## Integrators: pitfalls before you file an issue

Skim [`guides/common-mistakes.md`](guides/common-mistakes.md) when search or sync “feels wrong” but the database write succeeded—most first-hour confusion is a mismatch between sync mode expectations and search visibility, not silent data loss.

## Release train and merge policy

- Scrypath runs a **release train on `main`**: keep `main` green, let Release Please maintain the release PR, and merge that PR when the next patch is ready to ship.
- **Default release posture is patch-first while Scrypath remains pre-1.0.** The repo already uses Release Please's pre-1.0 knobs, so merged work rolls into patch cadence unless maintainers intentionally open a larger semver conversation.
- **Serious feature-depth work is PR-first.** Do not land it directly on `main`; shape it as a branch + PR slice that respects the release train.
- **Squash merge only.** The PR title should be treated as the release-facing summary because it becomes the squash commit title that Release Please reads.
- If `main` is green, the release PR is coherent, and there is no approved feature slice or bugfix to work, the default maintainer posture is **nothing to do**.

Use the normal fast suite during development:

```sh
mix test --exclude integration --exclude docs_contract
```

For adopter support verification:

```sh
mix verify.adopter
```

That fast path stays service-free and guards the current support/readiness contract. `mix verify.adopter --live` is the Phoenix + Meilisearch live check and requires `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL` after starting the example services; the detailed runbook lives in [`examples/phoenix_meilisearch/README.md`](examples/phoenix_meilisearch/README.md).

The live branch maps directly to the GitHub Actions **`phoenix-example-integration`** job contract: from `examples/phoenix_meilisearch`, the command path is `mix deps.get` then `mix test` with `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL` set.

Run the full integration verification (`mix verify.phase5`) when you change backfill, reindex, Meilisearch integration, or the operator docs:

```sh
SCRYPATH_INTEGRATION=1 \
SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 \
mix verify.phase5
```

That command runs:

- focused backfill/reindex/operator contract tests
- `mix docs --warnings-as-errors`
- live Meilisearch integration verification

If you do not have a Meilisearch instance running locally, you can still run the non-integration portion:

```sh
mix verify.phase5 --skip-integration
```

Some focused Mix tasks keep historical names. Choose them by scope:

| Scope | Local command | When to run |
| ----- | ------------- | ----------- |
| Federation and multi-search | <code>mix verify.phase41</code> | `search_many/2`, federation weights, `:all` expansion, or merged ordering semantics. |
| Per-query tuning | <code>mix verify.phase43</code> | `:per_query` options, search option merging, ranking score knobs, or related docs. |
| request-edge docs/examples contract | <code>mix verify.phase82</code> | Request-edge guide, Phoenix guides, `Scrypath.QueryParams`, `Scrypath.Phoenix`, or example request-shape fixtures. |
| Tenant safety | <code>mix verify.phase94</code> | `tenant_field:`, `schema_capabilities/1` tenant reflection, `tenant_scope:`, or the multitenancy guide. |
| Facet value search | <code>mix verify.phase96</code> | `search_facet_values/4`, facet-search result structures, contract tests, or associated examples. |
| Release/support trust gates | <code>mix verify.phase97</code>, <code>mix verify.phase98</code>, <code>mix verify.phase99</code> | Support/readiness routing, install/release contract checks, compatibility assertions, or workflow wiring tests. |

Run **`mix verify.opsui`** from the repository root when you change the optional **`scrypath_ops`** operator Phoenix app or its path dependency on the core library. It runs **`cd scrypath_ops && mix deps.get && mix test`**, and the dedicated **`scrypath-ops`** CI job now invokes this same root task (Postgres-backed Ecto setup, no Meilisearch service).

When you change **`scrypath_ops/docs/*.json`** playbook fixtures, golden workspace playbooks, or other flat `*.json` catalogs that ship beside **`scrypath_ops`**, also run **`cd scrypath_ops && mix scrypath_ops.playbooks.validate PATH`** from the repository root, where **`PATH`** is the directory containing those JSON files (non-recursive; same invocation shape as the Mix task **`Mix.Tasks.ScrypathOps.Playbooks.Validate`**).

## CI

GitHub Actions (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs these jobs:

| Job | Purpose |
|-----|---------|
| **`main-ci`** | Required merge gate: `mix compile --warnings-as-errors`, then `mix test --exclude integration --exclude docs_contract --include requires_clean_workspace` on Elixir 1.19 / OTP 28. |
| **`repo-hygiene`** | Required merge gate: `mix verify --exclude integration` for format, workspace cleanliness, Credo, fast tests, and docs build. |
| **`release-truth`** | Required merge gate: `mix verify.phase11` to keep package metadata, docs, Release Please wiring, and Hex packaging truth aligned. |
| **`phase99-trust`** | Required merge gate: <code>mix verify.phase99</code> for deterministic phase 99 trust-hardening contract and wiring checks. |
| **`compatibility-truth`** | Advisory compatibility-evidence lane: validates floor/head Elixir + OTP support truth using the canonical tuple authority in `guides/support-and-compatibility.md`. |
| **`deep-quality`** | Advisory quality sweep: optional-deps compile for `scrypath_ops`, namespace fence, `mix hex.audit`, and Dialyzer. |
| **`phase5-verification`** | Service: Meilisearch v1.15. `SCRYPATH_INTEGRATION=1`, `mix verify.phase5` (live integration + docs slice for backfill/reindex) |
| **`phase13-verification`** | Service: Meilisearch. `SCRYPATH_INTEGRATION=1`, `mix verify.phase13` (operator integration path) |
| **`meilisearch-smoke`** | Service: Meilisearch. `mix verify.meilisearch_smoke` (curated live suites: `live_meilisearch_verification`, `live_operator_verification`, `search_many_integration`, `settings_hot_apply_integration`) |
| **`phoenix-example-integration`** | Services: Postgres 16 + Meilisearch v1.15. `SCRYPATH_EXAMPLE_INTEGRATION=1`, `PGPORT=5433`, `SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700`. **CI** runs **`cd examples/phoenix_meilisearch`**, then **`mix deps.get`**, then **`mix test`** (same sequence as `.github/workflows/ci.yml`) - **not** `./scripts/smoke.sh`. **`./scripts/smoke.sh`** is a **local DX harness** under `examples/phoenix_meilisearch/` (Compose + env defaults aligned to CI); use it for interactive runs, not as the Actions test driver. See the example README for env tables. |
| **`phase105-e2e`** | Advisory browser lane with Postgres 16 + Meilisearch v1.15 for `examples/scrypath_ecommerce`; uses explicit `pg_isready` and `/health` checks and uploads failure artifacts (`playwright-report`, `test-results`, Phoenix log). |
| **`scrypath-ops-path-check` / `scrypath-ops`** | Service: Postgres 16 only (no Meilisearch). Path gate: runs on **`push` to `main`** unconditionally, and on **`pull_request`** when **`scrypath_ops/**`**, **`lib/**`**, **`mix.exs`**, **`mix.lock`**, or **`scrypath_ops/mix.lock`** change. Local contributors should use **`mix verify.opsui`** from the repo root; the dedicated CI job mirrors the same sequence by running **`cd scrypath_ops`**, then **`mix deps.get`**, then **`mix test`**. |

Treat **`main-ci`**, **`repo-hygiene`**, **`release-truth`**, and **`phase99-trust`** as the routine required merge gate blockers for this trust-hardening lane. **`compatibility-truth`** remains advisory evidence coverage, while phase-101 compatibility assertions close through <code>mix verify.phase99</code> rather than introducing a new required trust lane.

The root [`compose.yaml`](compose.yaml) is only for **local** Meilisearch when running smoke tasks; CI uses the workflow **`services:`** block instead.

## Example app (Postgres + Meilisearch)

For a **multi-container-shaped** local stack (Postgres + Meilisearch + Phoenix + **Oban**) and a scripted E2E smoke (**inline** and **`:oban`** paths), see [`examples/phoenix_meilisearch/README.md`](examples/phoenix_meilisearch/README.md) - that file is the **canonical env + command** reference for the example. **CI** under **`phoenix-example-integration`** runs **`cd examples/phoenix_meilisearch`**, then **`mix deps.get`**, then **`mix test`** (see **CI** table); **`./scripts/smoke.sh`** remains a **local** orchestration path, not the GitHub Actions entrypoint.

## `phase105-e2e` local runbook

`phase105-e2e` is advisory today (not a required merge gate). It exists to continuously exercise the full browser/operator proof while we track flake and runtime behavior.

Run locally:

```sh
mix deps.get
cd examples/scrypath_ecommerce
mix deps.get
mix e2e.prepare
npm ci
npx playwright install --with-deps chromium
MIX_ENV=test PHX_SERVER=true mix phx.server
# second shell
cd examples/scrypath_ecommerce
npm run test:e2e
```

### Promotion criteria

- Stable job name remains `phase105-e2e`.
- Sustained low flake rate across PR and scheduled runs.
- Runtime stays bounded enough for PR feedback.
- Failure artifacts remain actionable (`playwright-report`, `test-results`, Phoenix log).
- Lane owners respond to failures before required-check escalation.
- Trigger rules stay explicit so PR checks do not sit in ambiguous skipped/pending states.
