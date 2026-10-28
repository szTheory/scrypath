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

Repository-only `mix verify*` tasks live in `dev/mix/tasks/` and are not part of the Hex package; public operator tasks (`mix scrypath.*`) stay in `lib/mix/tasks/`. Command names and focused test paths are unchanged. Verifier tasks compile only under `MIX_ENV=test`, which `preferred_envs` selects automatically; `MIX_ENV=dev mix verify.adopter` (or `mix help verify.adopter` without `MIX_ENV=test`) reports that the task could not be found.

Use capability-named commands for new work. Historical `verify.phase*` commands remain supported for their original focused proof and print/retain their original argument contracts; prefer the corresponding capability command when its scope matches.

| Capability | Canonical command | Preserved proof |
| --- | --- | --- |
| Core library | `mix verify.core` | Standard root maturity gate (`mix verify`) followed by the isolated no-optional-deps compile (`mix verify.no_optional_deps`) |
| Package/release contract | `mix verify.package` | Package, consumer, docs, and release agreement (`mix verify.phase11`) |
| Repository contracts | `mix verify.repository_contracts` | Trust/repository contract gate (<code>mix verify.phase99</code>) |
| Meilisearch backend | `mix verify.backend` | Curated live backend smoke (`mix verify.meilisearch_smoke`) plus the real-Postgres loader suite (`mix verify.postgres`) |
| Compatibility contract | `mix verify.compatibility` | Compatibility-truth contract (<code>mix verify.phase99</code>) |
| Deep quality | `mix verify.deep_quality` | No-optional-deps, namespace, Hex audit, and Dialyzer checks |
| Mounted ecommerce | `mix verify.ecommerce_mounted` | Docker-only mounted proof (`make -C examples/scrypath_ecommerce verify-mounted`) |
| Phoenix example | `mix verify.phoenix_example` / `mix verify.phoenix_example --package` | Live path-backed and package-backed consumer proof (`mix verify.adopter --live`) |
| ScrypathOps | `mix verify.ops_ui` | Optional operator app proof |
| Full ecommerce E2E | `mix verify.ecommerce_e2e` | Advisory Docker/browser proof (`make -C examples/scrypath_ecommerce verify-e2e`) |

Use the normal fast suite during development:

```sh
mix test --exclude integration --exclude docs_contract
```

Quality-baseline commands are capability-named and safe to run locally:

```sh
# Compile the root library into an isolated build (MIX_BUILD_PATH,
# MIX_ENV=prod) without optional dependencies, with warnings as errors. Fails
# if Oban ends up on the code path. Also runs as part of mix verify.core.
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

Milestone and phase closeout use machine authority rather than post-implementation
human verification or UAT. Prepare a candidate commit, then run:

```sh
node scripts/ci_monitor.cjs closeout --push \
  --branch "$(git branch --show-current)" \
  --sha "$(git rev-parse HEAD)"
```

The command dispatches `ci.yml`, selects only a new `workflow_dispatch` run at
the requested SHA, and fails closed unless all five required jobs, coverage, and
`closeout-attestation` succeed and both SHA-bound artifacts have immutable
digests. Closeout uses two stages: attest the pending candidate, commit all final
tracking and verification artifacts, then attest the exact final SHA. Do not
write tracked files after the final successful run. Authentication or product
decisions may still stop work before implementation; they are not acceptance
tests and must never be represented as simulated approval.

### Readiness receipt and terminal record checks

The same maintenance script provides read-only factual collection and record
checks for the Phase 170 closeout. Keep every JSON input and output outside the
source checkout (for example, in a dedicated directory under `/tmp`). The
collector fetches one explicit repository, full source SHA, run ID, and attempt;
it exhausts the attempt's job and artifact pages, downloads only the attestation
artifact, and checks the archive bytes against GitHub's artifact digest. It
accepts one `closeout-attestation.json` ZIP member and stores both the archive
SHA-256 and the JSON member SHA-256. Those hashes refer to different bytes.
The action's run-page artifact URL differs from the artifact API URL; the
collector joins them through the selected run ID and artifact ID.
Temporary downloads are removed when collection finishes.

```sh
node scripts/ci_monitor.cjs collect-readiness \
  --repo OWNER/REPO \
  --sha FULL_40_CHARACTER_SHA \
  --run RUN_ID \
  --attempt RUN_ATTEMPT \
  --output /tmp/scrypath-readiness/receipt.json

node scripts/ci_monitor.cjs validate-readiness \
  --stage inputs \
  --inputs /tmp/scrypath-readiness/inputs.json \
  --source-root "$PWD"

node scripts/ci_monitor.cjs validate-readiness \
  --stage terminal \
  --inputs /tmp/scrypath-readiness/inputs.json \
  --receipt /tmp/scrypath-readiness/receipt.json \
  --record /tmp/scrypath-readiness/terminal.json \
  --source-root "$PWD"

node scripts/ci_monitor.cjs verify-readiness-comment \
  --repo OWNER/REPO \
  --issue ISSUE_NUMBER \
  --comment COMMENT_ID \
  --record /tmp/scrypath-readiness/terminal.json \
  --maintainer LOGIN \
  --source-root "$PWD"
```

`draft` validation permits explicitly reasoned pending issue and delivery
inputs. `inputs` requires a discoverable public issue and permits a reasoned
pending delivery disposition when its next planned action is stated. Terminal
validation requires the actual delivery disposition and may not remain pending.
It also requires all six supplied condition judgments, their dates, rationale,
linked evidence and limits, maintainer provenance, final-source receipt,
delivery identity, blockers, and revisit triggers. The schema is private JSON
version 1 for this closeout and is not a public Scrypath API. Candidate,
squash-main, final planning source, local artifact, and published tag/package
identities remain separate fields even when their SHA values match.

Validation returns `FACTUAL_ONLY_VALID` for structure and identity joins. It
checks the unchanged seven-dimension/24-claim baseline, all six approved
condition texts, pinned historical bytes, supplied exact-SHA receipt, and
comment author/body/issue identity. It does not assess evidence meaning, assign
condition statuses, infer READY, accept risk, or authorize a comment. A
terminal decision and any approval provenance must be supplied by the
maintainer. Corrections are new dated records that identify the assessment they
supersede. No CI lane or workflow topology is added for these checks.

Run test files with warnings promoted to failures when changing test support or
test infrastructure:

```sh
MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors --exclude integration --exclude docs_contract
```

For adopter support verification:

```sh
mix verify.adopter
```

That fast path stays service-free and guards the current support/readiness contract. `mix verify.phoenix_example` runs the existing path-backed Phoenix proof; `mix verify.phoenix_example --package` builds the current checkout's Hex artifact and runs the same consumer integration scenarios against it. Both live modes require `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT`, and `SCRYPATH_MEILISEARCH_URL`, with Postgres and Meilisearch already running; the detailed runbook lives in [`examples/phoenix_meilisearch/README.md`](examples/phoenix_meilisearch/README.md).

The live branch maps directly to the GitHub Actions **`phoenix-example`** job contract. That job runs the path-backed command first, then the package-backed command in the same advisory job and shared service block. The package-backed mode stages an isolated example copy and verifies that Scrypath resolves from the locally tagged artifact; the example's ordinary `path:` dependency remains unchanged.

Run the canonical backend verification (`mix verify.backend`) when you change Meilisearch integration. The historical `mix verify.phase5` remains the focused backfill/reindex/operator-docs wrapper:

```sh
docker compose up -d postgres meilisearch
SCRYPATH_INTEGRATION=1 \
SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 \
SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 \
mix verify.backend
```

That command runs:

- focused backfill/reindex/operator contract tests
- `mix docs --warnings-as-errors`
- live Meilisearch integration verification
- real-Postgres loader/backfill tests (`mix verify.postgres`)

To run only the Postgres loader suite, start the compose Postgres (host port 5434) and run `mix verify.postgres`:

```sh
docker compose up -d postgres
SCRYPATH_POSTGRES_URL=postgres://postgres:postgres@127.0.0.1:5434 mix verify.postgres
```

The suite drops and recreates the `scrypath_test<MIX_TEST_PARTITION>` database on that server, so do not point it at a database you care about. Plain `mix test` excludes the `:postgres` tag unless `SCRYPATH_POSTGRES_URL` is set, so the core lane stays service-free.

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

When you change **`scrypath_ops/docs/*.json`** saved-search fixtures, exported saved searches, or other flat `*.json` catalogs that ship beside **`scrypath_ops`**, also run **`cd scrypath_ops && mix scrypath_ops.saved_searches.validate PATH`** from the repository root, where **`PATH`** is the directory containing those JSON files (non-recursive; same invocation shape as the Mix task **`Mix.Tasks.ScrypathOps.SavedSearches.Validate`**).

## CI

GitHub Actions (see [`.github/workflows/ci.yml`](.github/workflows/ci.yml)) runs these jobs:

| Job | Purpose |
|-----|---------|
| **`core`** | Required merge gate: `mix verify.core --exclude integration --exclude docs_contract` for warning-free compilation, format, workspace cleanliness, Credo, fast tests, the single CI docs build, and the no-Oban compile. |
| **`package`** | Required merge gate: `mix verify.package` for package metadata, consumer, release wiring, and unpacked Hex-package truth. |
| **`repository-contracts`** | Required merge gate: `mix verify.repository_contracts` for deterministic repository and workflow contracts. |
| **`backend`** | Required Meilisearch v1.15 proof: `mix verify.backend` with live integration enabled and failure diagnostics. A Postgres 16 service with `SCRYPATH_POSTGRES_URL` in the same job runs the real-Postgres loader suite (`mix verify.postgres`). |
| **`ecommerce-mounted`** | Required Docker-only proof: `mix verify.ecommerce_mounted` for mounted routing, failed-sync triage, and zero-downtime swap behavior. |
| **`compatibility`** | Advisory Elixir/OTP tuple matrix: `mix verify.compatibility` on 1.17/26, 1.18/27, 1.19/26, and 1.19/28. |
| **`deep-quality`** | Advisory `mix verify.deep_quality`: optional-dependency compile, namespace fence, `mix hex.audit`, and Dialyzer. |
| **`phoenix-example`** | Advisory Postgres 16 + Meilisearch v1.15 proof: `mix verify.phoenix_example` followed by `mix verify.phoenix_example --package`, covering path-backed and package-backed live consumers. |
| **`ops-ui-path` / `ops-ui`** | Path-scoped optional-app proof. `mix verify.ops_ui` delegates to the existing ScrypathOps test orchestration. |
| **`coverage`** | Scheduled/manual advisory, informational, non-blocking coverage evidence: `mix verify.coverage` produces a SHA-bound report artifact retained for seven days. |
| **`ecommerce-e2e`** | Scheduled/manual advisory Docker/browser proof. `mix verify.ecommerce_e2e` runs the full lane and always uploads its bounded evidence bundle. |

Treat **`core`**, **`package`**, **`repository-contracts`**, **`backend`**, and **`ecommerce-mounted`** as required merge gates. The compatibility, deep-quality, Phoenix example, optional operator app, and full E2E lanes remain advisory or path-scoped as labeled.

### Exact-source cache acceptance probes

Manual `ci.yml` dispatches default to `phase182_cache_mode=normal`, which keeps
the existing jobs and commands unchanged. It runs the normal full advisory
browser job and records a Docker warm-cache receipt from that job. Optional
modes reuse the existing jobs:

| Mode | Existing job | Evidence being exercised |
|------|--------------|--------------------------|
| `docker-cold` | `ecommerce-mounted` | A new per-run Buildx builder with every Bake cache import/export removed, followed by `mix verify.ecommerce_mounted`. |
| `beam-cold` | `core` | Cache restore steps are skipped on the fresh hosted runner; `mix deps.get`, `mix compile --warnings-as-errors`, and the canonical core verifier run normally. |
| `beam-fallback` | `core` | Run-unique primary cache keys miss; compatible Hex archive fallback is accepted only when Actions reports the matched key. Resolved build restore is disabled, then normal resolution, compilation, and core verification run. |
| `beam-lock-change` | `core` | A separate temporary checkout receives one comment-only `mix.lock` change and a local probe-only commit. The source checkout stays unchanged. The proof binds the exact before/after lock bytes to canonical cache identities and different natural resolved keys; no forced run suffix supplies the lock-change miss. Compatible Hex fallback, the exact changed-lock miss, and normal Mix commands are recorded. |

`phase182_probe_namespace` accepts a lowercase slug of up to 32 characters.
Leave it empty to use the production cache namespace. Use a distinct slug for
candidate experiments: Docker scopes and BEAM Actions Cache keys then stay in
that namespace. No mode deletes caches. The normal full job remains the trusted
production cache writer. A same-repository candidate-ref `workflow_dispatch`
can export only to an explicitly named probe namespace; candidate refs never
write production Docker scopes. Pull requests and untrusted repositories cannot export. A
`docker-warm` acceptance therefore needs actual GHA import and export log lines;
use a trusted main dispatch or an explicit probe namespace and run again after
it has seeded that namespace.

The exact-source collector dispatches `ci.yml` at the requested branch and full
SHA, then reads that new run's attempt-specific jobs, raw logs, and immutable
artifact bytes. Its existing `gh` identity needs workflow-dispatch permission
for `ci.yml` at the owned candidate ref plus Actions read access to run attempts,
jobs, logs, and artifacts. `gh auth status` and read-only access do not prove
dispatch capability. A denied operation is an authentication/capability gate;
use the already approved identity, without adding secrets or widening workflow
token permissions. The collector never pushes. If a separate push is needed,
it must use existing permission and target only the owned branch.

Keep candidate evidence outside the checkout. The first invocation creates a
session manifest bound to repository, branch, full source SHA, and your explicit
session ID. Repeated modes (including retries of one mode) get fresh
invocation/run-attempt directories and preserve earlier failures. Reuse a root
only for the exact same source/ref/session; a changed SHA needs a new root.
The workflow retains proof artifacts for seven days. Run each required cache
mode in one session, then validate the aggregate:

```sh
repo="OWNER/REPO"
branch="YOUR_OWNED_BRANCH"
sha="$(git rev-parse HEAD)"
session="phase182-$(date -u +%Y%m%dT%H%M%SZ)"
root="/tmp/scrypath-phase182/$session"
namespace="candidate-2026"

# Seed this isolated namespace before collecting warm/fallback evidence. The
# first run may have no import hit; run normal again so it can prove import and
# export from the cache created by the first run.
gh workflow run ci.yml --ref "$branch" --repo "$repo" \
  -f phase182_cache_mode=normal -f "phase182_probe_namespace=$namespace"
# Wait for the seed run to finish, then dispatch normal once more with the same
# command and wait for success before collecting the acceptance receipts.

for mode in docker-warm docker-cold beam-fallback beam-lock-change beam-cold; do
  node scripts/ci/phase182_acceptance.cjs run \
    --mode "$mode" --repo "$repo" --branch "$branch" --sha "$sha" \
    --session-id "$session" --output-dir "$root" \
    --probe-namespace "$namespace"
done

node scripts/ci/phase182_acceptance.cjs run \
  --mode full --repo "$repo" --branch "$branch" --sha "$sha" \
  --session-id "$session" --output-dir "$root" \
  --probe-namespace "$namespace"

node scripts/ci/phase182_acceptance.cjs validate \
  --mode caches --repo "$repo" --branch "$branch" --sha "$sha" \
  --session-id "$session" --input "$root" --probe-namespace "$namespace"

node scripts/ci/phase182_acceptance.cjs validate \
  --mode full --repo "$repo" --branch "$branch" --sha "$sha" \
  --session-id "$session" --input "$root" --probe-namespace "$namespace"
```

`docker-warm` dispatches the default `normal` workflow input. Cache modes require
successful canonical verifier steps and actual BuildKit or Actions Cache log
evidence in addition to their JSON receipts. The executable tests protect the
collector and wiring only; they do not stand in for a real hosted browser or
cache acceptance run. Both validation commands require the session root plus
`--repo`, `--branch`, full `--sha`, `--session-id`, and the same
`--probe-namespace` used for collection (including its empty default); `--input` is not a receipt
file. Run the `full` collection and validation after the cache-mode receipts for
the exact real-acceptance sequence used by the Phase 182-08 executor.

For v1.29 closeout proof, run <code>mix verify.phase108</code> locally when related-data fan-out wording, roadmap/JTBD closeout truth, or contributor verification posture changes. It is a focused service-free truth gate; it does not promote **`phase105-e2e`** to a required merge blocker.

The root [`compose.yaml`](compose.yaml) is only for **local** Meilisearch when running smoke tasks; CI uses the workflow **`services:`** block instead.

## Example app (Postgres + Meilisearch)

For the **canonical environment, service, and command runbook**, see [`examples/phoenix_meilisearch/README.md`](examples/phoenix_meilisearch/README.md). The advisory `phoenix-example` CI job runs `mix verify.phoenix_example` first against the example's `path:` dependency, then `mix verify.phoenix_example --package` against the locally built package artifact. Both commands use real Postgres and Meilisearch services and cover inline, Oban, and related-data scenarios. A passing docs contract proves documentation and wiring assertions; it is not live-service proof. The package command is the live package-backed service proof, and does not establish every adopter deployment or production reliability. For the local orchestration harness, run `cd examples/phoenix_meilisearch` and then `./scripts/smoke.sh`; that script is not the GitHub Actions entrypoint.

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

`ecommerce-mounted` is the required focused Docker proof. It receives a run ID and uploads only that invocation's failure bundle when a run fails. `ecommerce-e2e` is advisory today and runs on scheduled/manual triggers using the canonical `mix verify.ecommerce_e2e` command. Its full Chromium inventory and execution, light screenshot parity, static contrast, diagnostics, cleanup, and strict evidence aggregation run inside an isolated Docker project. The acceptance path does not invoke the dormant paid visual judge or require an API key.

The full job has a 30-minute Actions timeout measured from its first step, before checkout, toolchain setup, dependency fetch, and image build. That step records the job start, exact event/ref/SHA/run/attempt identity, and an inner deadline. The browser verifier initially reserves 300 seconds for evidence finalization and upload; this is provisional until Phase 182-08 confirms or replaces it using the measured maximum finalization/upload time plus at least 60 seconds. The job exposes the raw `ecommerce_verify` step outcome separately from the job conclusion because `continue-on-error` makes the lane advisory. A successful advisory job conclusion alone does not establish a passing browser proof.

Each invocation owns a fresh directory under `examples/scrypath_ecommerce/test-results/docker-full/<run-id>/` (or `docker-focused/<run-id>/` for mounted verification). The full job uploads only its current run directory, always attempts the upload, fails if the required directory is missing, and retains the artifact for seven days. Its outputs preserve the raw verifier outcome and the uploaded artifact ID, URL, and digest. The bundle contains source/run metadata, inventory and execution reports, HTML, retained failure traces, light-parity and contrast results, lifecycle and stage statuses, copy diagnostics, and applicable iteration 3 screenshots. A run's strict receipt is the evidence authority; readiness-only diagnostics and loose directory presence are not acceptance.

Inventory equality covers the selected Playwright cases and rejects skipped or retried execution. Viewport/width checks, screenshot parity, and contrast reports cover their named checks; they do not amount to a complete rendered UX review. A real full-browser and hosted exact-SHA run is still required for the applicable Phase 182 requirements.

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

For rendered UI and content review, follow [the repository UI review loop](https://github.com/szTheory/scrypath/blob/main/examples/scrypath_ecommerce/e2e/UI-REVIEW.md).
`npm run ui:review` in the demo captures the running preview without seeding it;
the output starts pending and includes the complete current screen inventory.
It supplements state/functional proofs and does not add a required CI lane.

Run the canonical focused or full Docker verifier locally:

```sh
mix verify.ecommerce_mounted
mix verify.ecommerce_e2e
```

The verifier prints the unique run directory; inspect the receipt and summary from that directory rather than combining files from earlier runs. To run a readiness-only diagnostic, invoke `examples/scrypath_ecommerce/scripts/verify-e2e.sh full --readiness-only`; it does not run Playwright and is never browser acceptance. The separate `npm run test:e2e:ops-ui-visual-judge` entrypoint remains dormant legacy tooling and is not part of either canonical command.

### Promotion criteria

- Stable job name remains `phase105-e2e`.
- Sustained low flake rate across PR and scheduled runs.
- Runtime stays bounded enough for PR feedback.
- Failure artifacts remain actionable (`playwright-report`, `test-results`, Phoenix log).
- Lane owners respond to failures before required-check escalation.
- Trigger rules stay explicit so PR checks do not sit in ambiguous skipped/pending states.
- Evidence artifacts stay bounded and machine-auditable as `phase105-playwright.json`, `phase105-evidence.ndjson`, `phase105-evidence.json`, and `phase105-evidence-summary.md`.
- Evidence summaries include spec/test/attempt counts, operation counts, failed spec names, runtime, flake signal, and failure classification.
