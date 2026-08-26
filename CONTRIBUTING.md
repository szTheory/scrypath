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
- Keep release mechanics centralized in [`docs/releasing.md`](docs/releasing.md): `mix verify.package` is the always-on auth-free gate, while `mix verify.release_publish` and `mix verify.release_parity` stay on post-publish and scheduled monitor paths.
- **Default release posture is patch-first while Scrypath remains pre-1.0.** The repo already uses Release Please's pre-1.0 knobs, so merged work rolls into patch cadence unless maintainers intentionally open a larger semver conversation.
- **Serious feature-depth work is PR-first.** Do not land it directly on `main`; shape it as a branch + PR slice that respects the release train.
- **Squash merge only.** The PR title should be treated as the release-facing summary because it becomes the squash commit title that Release Please reads.
- If `main` is green, the release PR is coherent, and there is no approved feature slice or bugfix to work, the default maintainer posture is **nothing to do**.

## Canonical verification commands

Use capability-named commands for new work. Historical `verify.phase*` commands remain supported for their original focused proof and print/retain their original argument contracts; prefer the corresponding capability command when its scope matches.

| Capability | Canonical command | Preserved proof |
| --- | --- | --- |
| Core library | `mix verify.core` | Standard root maturity gate (`mix verify`) |
| Package/release contract | `mix verify.package` | Package, consumer, docs, and release agreement (`mix verify.phase11`) |
| Repository contracts | `mix verify.repository_contracts` | Trust/repository contract gate (<code>mix verify.phase99</code>) |
| Meilisearch backend | `mix verify.backend` | Curated live backend smoke (`mix verify.meilisearch_smoke`) |
| Compatibility contract | `mix verify.compatibility` | Compatibility-truth contract (<code>mix verify.phase99</code>) |
| Deep quality | `mix verify.deep_quality` | No-optional-deps, namespace, Hex audit, and Dialyzer checks |
| Mounted ecommerce | `mix verify.ecommerce_mounted` | Docker-only mounted proof (`make -C examples/scrypath_ecommerce verify-mounted`) |
| Phoenix example | `mix verify.phoenix_example` | Live consumer-shaped example proof (`mix verify.adopter --live`) |
| ScrypathOps | `mix verify.ops_ui` | Optional operator app proof |
| Full ecommerce E2E | `mix verify.ecommerce_e2e` | Advisory Docker/browser proof (`make -C examples/scrypath_ecommerce verify-e2e`) |

Use the normal fast suite during development:

```sh
mix test --exclude integration --exclude docs_contract
```

Quality-baseline commands are capability-named and safe to run locally:

```sh
# Ensure the root library does not accidentally require optional dependencies.
mix verify.no_optional_deps

# Produce a built-in line-coverage report for the fast suite. This is
# informational; Scrypath does not enforce a coverage percentage.
mix verify.coverage
```

The **`coverage`** CI job is a scheduled/manual, advisory, informational, and
non-blocking lane. To reproduce it locally, run `mix verify.coverage`. If a
maintainer needs fresh hosted evidence, redispatch [`.github/workflows/ci.yml`](.github/workflows/ci.yml)
with `workflow_dispatch`, then download the SHA-bound `coverage-report-<sha>`
artifact from that run. GitHub retains the report for seven days; it is evidence
only, not a merge gate or coverage-percentage threshold.

Run test files with warnings promoted to failures when changing test support or
test infrastructure:

```sh
MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract
```

For adopter support verification:

```sh
mix verify.adopter
```

That fast path stays service-free and guards the current support/readiness contract. `mix verify.adopter --live` is the Phoenix + Meilisearch live check and requires `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL` after starting the example services; the detailed runbook lives in [`examples/phoenix_meilisearch/README.md`](examples/phoenix_meilisearch/README.md).

The live branch maps directly to the GitHub Actions **`phoenix-example`** job contract. The canonical root command validates `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL`, then runs `mix deps.get` and `mix test` from `examples/phoenix_meilisearch`.

Run the canonical backend verification (`mix verify.backend`) when you change Meilisearch integration. The historical `mix verify.phase5` remains the focused backfill/reindex/operator-docs wrapper:

```sh
SCRYPATH_INTEGRATION=1 \
SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 \
mix verify.backend
```

That command runs:

- focused backfill/reindex/operator contract tests
- `mix docs --warnings-as-errors`
- live Meilisearch integration verification

If you do not have a Meilisearch instance running locally, you can still run the non-integration portion:

```sh
mix verify.backend --skip-integration
```

Some focused Mix tasks keep historical names. Choose them by scope:

| Scope | Local command | When to run |
| ----- | ------------- | ----------- |
| Federation and multi-search | <code>mix verify.phase41</code> (historical focused wrapper) | `search_many/2`, federation weights, `:all` expansion, or merged ordering semantics. |
| Per-query tuning | <code>mix verify.phase43</code> | `:per_query` options, search option merging, ranking score knobs, or related docs. |
| request-edge docs/examples contract | <code>mix verify.phase82</code> | Request-edge guide, Phoenix guides, `Scrypath.QueryParams`, `Scrypath.Phoenix`, or example request-shape fixtures. |
| Tenant safety | <code>mix verify.phase94</code> | `tenant_field:`, `schema_capabilities/1` tenant reflection, `tenant_scope:`, or the multitenancy guide. |
| Facet value search | <code>mix verify.phase96</code> | `search_facet_values/4`, facet-search result structures, contract tests, or associated examples. |
| Release/support trust gates | <code>mix verify.phase97</code>, <code>mix verify.phase98</code>, <code>mix verify.phase99</code> | Support/readiness routing, install/release contract checks, compatibility assertions, or workflow wiring tests. |
| v1.29 closeout truth | <code>mix verify.phase108</code> | Related-data fan-out wording, planning/JTBD closeout truth, and advisory `phase105-e2e` posture. |
| Public website/docs truth alignment | <code>mix verify.phase112</code> | README, `website/`, `guides/scope-and-reopen-policy.md`, or other public truth-copy updates that affect claim envelope, route-map depth, or reopen-policy wording. |

Run **`mix verify.ops_ui`** from the repository root when you change the optional **`scrypath_ops`** operator Phoenix app or its path dependency on the core library. It runs **`cd scrypath_ops && mix deps.get && mix test`**. The path-scoped **`ops-ui`** CI job invokes the same canonical command (Postgres-backed Ecto setup, no Meilisearch service).

When you change **`scrypath_ops/docs/*.json`** playbook fixtures, golden workspace playbooks, or other flat `*.json` catalogs that ship beside **`scrypath_ops`**, also run **`cd scrypath_ops && mix scrypath_ops.playbooks.validate PATH`** from the repository root, where **`PATH`** is the directory containing those JSON files (non-recursive; same invocation shape as the Mix task **`Mix.Tasks.ScrypathOps.Playbooks.Validate`**).

## CI

GitHub Actions (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs these jobs:

| Job | Purpose |
|-----|---------|
| **`core`** | Required merge gate: `mix verify.core --exclude integration --exclude docs_contract` for warning-free compilation, format, workspace cleanliness, Credo, fast tests, and the single CI docs build. |
| **`package`** | Required merge gate: `mix verify.package` for package metadata, consumer, release wiring, and unpacked Hex-package truth. |
| **`repository-contracts`** | Required merge gate: `mix verify.repository_contracts` for deterministic repository and workflow contracts. |
| **`backend`** | Required Meilisearch v1.15 proof: `mix verify.backend` with live integration enabled and failure diagnostics. |
| **`ecommerce-mounted`** | Required Docker-only proof: `mix verify.ecommerce_mounted` for mounted routing, failed-sync triage, and zero-downtime swap behavior. |
| **`compatibility`** | Advisory Elixir/OTP tuple matrix: `mix verify.compatibility` on 1.17/26, 1.18/27, 1.19/26, and 1.19/28. |
| **`deep-quality`** | Advisory `mix verify.deep_quality`: optional-dependency compile, namespace fence, `mix hex.audit`, and Dialyzer. |
| **`phoenix-example`** | Advisory Postgres 16 + Meilisearch v1.15 proof: `mix verify.phoenix_example`, which runs the live consumer-shaped example. |
| **`ops-ui-path` / `ops-ui`** | Path-scoped optional-app proof. `mix verify.ops_ui` delegates to the existing ScrypathOps test orchestration. |
| **`coverage`** | Scheduled/manual advisory, informational, non-blocking coverage evidence: `mix verify.coverage` produces a SHA-bound report artifact retained for seven days. |
| **`ecommerce-e2e`** | Scheduled/manual advisory Docker/browser proof. `mix verify.ecommerce_e2e` runs the full lane and always uploads its bounded evidence bundle. |

Treat **`core`**, **`package`**, **`repository-contracts`**, **`backend`**, and **`ecommerce-mounted`** as required merge gates. The compatibility, deep-quality, Phoenix example, optional operator app, and full E2E lanes remain advisory or path-scoped as labeled.

For v1.29 closeout proof, run <code>mix verify.phase108</code> locally when related-data fan-out wording, roadmap/JTBD closeout truth, or contributor verification posture changes. It is a focused service-free truth gate; it does not promote **`phase105-e2e`** to a required merge blocker.

The root [`compose.yaml`](compose.yaml) is only for **local** Meilisearch when running smoke tasks; CI uses the workflow **`services:`** block instead.

## Example app (Postgres + Meilisearch)

For a **multi-container-shaped** local stack (Postgres + Meilisearch + Phoenix + **Oban**) and a scripted E2E smoke (**inline** and **`:oban`** paths), see [`examples/phoenix_meilisearch/README.md`](examples/phoenix_meilisearch/README.md) - that file is the **canonical env + command** reference for the example. **CI** runs the same proof through **`mix verify.phoenix_example`**. For the local orchestration harness, run `cd examples/phoenix_meilisearch` and then `./scripts/smoke.sh`; that script is not the GitHub Actions entrypoint.

## `phase105-e2e` local runbook

The required mounted subset has a zero-touch Docker entrypoint:

```sh
make -C examples/scrypath_ecommerce verify-mounted
```

That command is the local/CI parity surface for `ecommerce-mounted`. It
requires only Docker Compose, publishes no host ports, and tears down its
uniquely named containers, network, and volumes after collecting diagnostics.
Set `KEEP_E2E_STACK=1` only when intentionally preserving a failed stack for
debugging. Run the complete advisory lane with:

```sh
make -C examples/scrypath_ecommerce verify-e2e
```

`ecommerce-e2e` is advisory today (not a required merge gate). It preserves the full Phase 105 browser/operator proof on scheduled and manual runs through one Docker-owned command, including deterministic browser checks, light screenshot parity, static contrast, optional visual judgment, cleanup, and bounded artifacts.

Phase 111 freezes a dual-window evidence model for any future promotion decision:

- Canonical stability evidence comes from push-to-main and scheduled runs.
- Merge-risk evidence comes from `pull_request` runs.
- Treat pre-change and post-change job identity evidence separately.
- Retry-as-flake rule: a pass after retry counts as flaky evidence, not clean stability proof.
- Owner response expectation for lane failures is 1 business day.
- Path-scoped promotion of the full `phase105-e2e` lane was not part of Phase 111. Phase 147 adds a separate focused deterministic check; the full lane remains advisory.

For the human-facing tour of what this lane protects, including the storefront,
operator routes, demo tenants, and Compose launch path, see
[`examples/scrypath_ecommerce/README.md`](examples/scrypath_ecommerce/README.md).
That demo README also documents the bind-mounted Compose dev mode for fast UI
iteration without rebuilding dependency layers after every HEEx/CSS change.

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
npm run test:e2e:admin-light-parity
make contrast
# optional advisory review, skipped in CI unless OPS_UI_LLM_JUDGE=1 and OPENAI_API_KEY exist
OPS_UI_LLM_JUDGE=1 OPENAI_API_KEY=... npm run test:e2e:ops-ui-visual-judge
```

### Promotion criteria

- Stable job name remains `phase105-e2e`.
- Sustained low flake rate across PR and scheduled runs.
- Runtime stays bounded enough for PR feedback.
- Failure artifacts remain actionable (`playwright-report`, `test-results`, Phoenix log).
- Lane owners respond to failures before required-check escalation.
- Trigger rules stay explicit so PR checks do not sit in ambiguous skipped/pending states.
- Evidence artifacts stay bounded and machine-auditable as `phase105-playwright.json`, `phase105-evidence.ndjson`, `phase105-evidence.json`, and `phase105-evidence-summary.md`.
- Evidence summaries include spec/test/attempt counts, operation counts, failed spec names, runtime, flake signal, and failure classification.
