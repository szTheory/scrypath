# Contributing

## Maintainer: B1 evidence

- **B1** library work is **frozen** against the in-repo ledger **`.planning/EVID-01-b1-v1.14.md`**: cite **`EVID-57-*`** row IDs on PRs that touch **`lib/scrypath/`** or implement **LIB-01** / **LIB-02** / **LIB-03** for **v1.14** (see the PR template). The ledger is **append-only after freeze**—do not rewrite shipped rows.

## First hour and canonical docs

- New contributors: follow the README **Quick Path** into [`guides/golden-path.md`](guides/golden-path.md) for the linear **`:inline`** first-hour story.
- Current support/readiness truth lives in [`guides/support-and-compatibility.md`](guides/support-and-compatibility.md). When README, maintainer commands, CI wording, or the example runbook change, keep that guide as the single authority instead of turning this file into a second matrix.
- Use release-backed guidance from [`guides/support-and-compatibility.md`](guides/support-and-compatibility.md) for adopter-facing policy; main may contain unreleased changes.
- For the outside-adopter review workflow, evidence admissibility classes (Class A through D), and the maintainer proof-command family, refer to [`guides/outside-adopter-intake.md`](guides/outside-adopter-intake.md). Do not duplicate the intake checklist or live runbook here.
- The canonical adopter mental-model guide is [`guides/jtbd-and-user-flows.md`](guides/jtbd-and-user-flows.md). Update it when the library adds, removes, or materially changes a user-facing flow.
- **Sync modes, visibility, and operator lifecycle** live in [`guides/sync-modes-and-visibility.md`](guides/sync-modes-and-visibility.md)—update that guide instead of duplicating semantics in README or here.
- Changing published docs should keep **`mix docs --warnings-as-errors`** green. The optional docs contract suite remains available via **`mix test test/scrypath/docs_contract_test.exs`**, but it is no longer part of the default CI and release gates.

## Maintainers: JTBD gap map

- The planning-facing gap and prioritization companion lives in [`docs/jtbd-gap-map.md`](docs/jtbd-gap-map.md). Refresh it when roadmap work changes the shipped flow map, closes a major gap, or new outside adopter evidence changes the ranking.

## Integrators: pitfalls before you file an issue

Skim [`guides/common-mistakes.md`](guides/common-mistakes.md) when search or sync “feels wrong” but the database write succeeded—most first-hour confusion is a mismatch between sync mode expectations and search visibility, not silent data loss.

## Verification

## Release train and merge policy

- Scrypath runs a **release train on `main`**: keep `main` green, let Release Please maintain the release PR, and merge that PR when the next patch is ready to ship.
- **Default release posture is patch-first while Scrypath remains pre-1.0.** The repo already uses Release Please's pre-1.0 knobs, so merged work rolls into patch cadence unless maintainers intentionally open a larger semver conversation.
- **Serious milestone work is PR-first.** Do not land new feature-depth work directly on `main`; shape it as a branch + PR slice that respects the release train.
- **Squash merge only.** The PR title should be treated as the release-facing summary because it becomes the squash commit title that Release Please reads.
- If `main` is green, the release PR is coherent, and there is no approved milestone or bugfix to work, the default maintainer posture is **nothing to do**.

Use the normal fast suite during development:

```sh
mix test --exclude integration --exclude docs_contract
```

For the maintainer-facing adopter proof surface specifically:

```sh
mix verify.adopter
```

That fast path stays service-free and guards the current support/readiness contract. `mix verify.adopter --live` is the canonical Phoenix + Meilisearch proof path and requires `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL` after starting the example services; the detailed runbook lives in [`examples/phoenix_meilisearch/README.md`](examples/phoenix_meilisearch/README.md).

The live branch maps directly to the GitHub Actions **`phoenix-example-integration`** job contract: from `examples/phoenix_meilisearch`, the proof path is `mix deps.get` then `mix test` with `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL` set.

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

The fast pull-request gate for federation and multi-search runtime behavior is the Phase 41 verify alias. It stays free of Meilisearch services. Heavier integration paths, including live Meilisearch verification for backfill, reindex, and operator flows, still live on the Phase 5 verify alias and the dedicated integration jobs in CI.

The Phase 43 verify alias is the complementary fast gate for **per-query Plane B** runtime tests (allowlisted `:per_query` options, `search_many/2` merge semantics). Run that alias when you touch those paths locally; CI enforces the same gate in the **`quality`** job alongside the other phase verify tasks.

The Phase 82 verify alias is the focused gate for the v1.21 request-edge docs/examples contract. Run the shell command **mix verify.phase82** when you change the canonical request-edge guide, Phoenix guides, `Scrypath.QueryParams` / `Scrypath.Phoenix` public docs story, the example README, or the docs-contract / fixture seams that protect those surfaces. It stays narrower than the default fast suite and mirrors the same check CI runs in the **`quality`** job.

The Phase 94 verify alias is the focused gate for the tenant-safety and multitenancy contracts. Run the shell command **mix verify.phase94** when you change `tenant_field:` auto-merge behavior, `schema_capabilities/1` `:tenant` reflection, `tenant_scope:` injection, or the canonical `guides/multitenancy.md` guide anchors. It stays narrower than the default fast suite and mirrors the same check CI runs in the **`quality`** job.

The Phase 96 verify alias is the focused gate for the facet value search verification. Run the shell command **mix verify.phase96** when you change `search_facet_values/4` request/response structures, contract tests, or the associated documentation examples. It stays narrower than the default fast suite and mirrors the same check CI runs in the **`quality`** job.

The Phase 97 verify alias is the focused gate for canonical contract freeze and scope guard coverage. Run the shell command **mix verify.phase97** when you change phase 97 contract artifacts, docs-contract trust anchors, or phase-97 workflow wiring tests. This gate protects milestone trust-hardening coverage only; it does not introduce a new runtime feature gate category.

The Phase 98 verify alias is the focused gate for proof-boundary and outside-adopter intake contract reconciliation. Run the shell command **mix verify.phase98** when you change support/readiness proof routing, example live-proof runbook parity, intake classification/routing guidance, or phase-98 contract tests. This gate protects trust-hardening scope only and does not expand runtime feature coverage.

The Phase 99 verify alias is the focused gate for docs/proof drift contracts and trust-lane wiring parity. Run the shell command <code>mix verify.phase99</code> when you change `test/scrypath/phase99_contract_test.exs`, `test/mix/tasks/verify.phase99_test.exs`, `test/mix/tasks/workflow_wiring_test.exs`, or docs/alias tokens tied to the phase-99 trust-hardening lane. It now also carries Phase-100 install/release contract trust-hardening (`TRUTH-01` and `TRUTH-02`) plus Phase-101 compatibility-truth closure coverage (`TRUTH-03`), and remains trust-hardening scope only without expanding runtime feature coverage.

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
| **`scrypath-ops-path-check` / `scrypath-ops`** | Service: Postgres 16 only (no Meilisearch). Path gate: runs on **`push` to `main`** unconditionally, and on **`pull_request`** when **`scrypath_ops/**`**, **`lib/**`**, **`mix.exs`**, **`mix.lock`**, or **`scrypath_ops/mix.lock`** change. Local contributors should use **`mix verify.opsui`** from the repo root; the dedicated CI job mirrors the same sequence by running **`cd scrypath_ops`**, then **`mix deps.get`**, then **`mix test`**. |

Treat **`main-ci`**, **`repo-hygiene`**, **`release-truth`**, and **`phase99-trust`** as the routine required merge gate blockers for this trust-hardening lane. **`compatibility-truth`** remains advisory evidence coverage, while phase-101 compatibility assertions close through <code>mix verify.phase99</code> rather than introducing a new required trust lane.

The root [`compose.yaml`](compose.yaml) is only for **local** Meilisearch when running smoke tasks; CI uses the workflow **`services:`** block instead.

## Example app (Postgres + Meilisearch)

For a **multi-container-shaped** local stack (Postgres + Meilisearch + Phoenix + **Oban**) and a scripted E2E smoke (**inline** and **`:oban`** paths), see [`examples/phoenix_meilisearch/README.md`](examples/phoenix_meilisearch/README.md) - that file is the **canonical env + command** reference for the example. **CI** under **`phoenix-example-integration`** runs **`cd examples/phoenix_meilisearch`**, then **`mix deps.get`**, then **`mix test`** (see **CI** table); **`./scripts/smoke.sh`** remains a **local** orchestration path, not the GitHub Actions entrypoint.
