# Phase 147: Ecommerce Mounted-Ops Remediation and Closure Evidence - Context

**Gathered:** 2026-08-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 147 remediates the independent `examples/scrypath_ecommerce` Mix graph
against the fixed-compatible web/client cohort, proves that the host application
actually consumes the remediated root Scrypath and ScrypathOps path sources, and
closes v1.36 with compact, ordered, truthful evidence across all four Mix graphs.

This is a maintenance-only dependency and evidence phase. It adds no product
capability, public Scrypath API, route, schema, search behavior, synchronization
mode, UI or brand change, permanent CI/security subsystem, or package-head
modernization. The existing mounted storefront/operator behavior is a regression
surface, not an implementation surface.

</domain>

<decisions>
## Implementation Decisions

### 1. Ecommerce dependency intent and ownership

- **D-01:** Mirror the approved ScrypathOps-compatible direct bounds in ecommerce:
  Phoenix `~> 1.8.9`, Phoenix LiveView `~> 1.1.33`, Bandit `~> 1.12.1`,
  Swoosh `~> 1.26.3`, Postgrex `~> 0.22.4`, and the already-landed Req
  `~> 0.6.1`. These are fixed-compatible minor-line bounds, not instructions to
  select package heads.
- **D-02:** Leave `phoenix_ecto`, Ecto SQL `~> 3.13`, Oban, and unrelated direct
  requirements unchanged unless the resolver or a focused compatibility failure
  demonstrates a causal need. Keep Plug, Mint, hpax, Finch, Ecto, and Decimal
  transitive; add no direct requirement or override merely to force a reviewed lock.
- **D-03:** Refresh only the causal closure produced by the approved direct bounds
  and the Phase 144 Req handoff. Explain every moved lock row. No unrelated cleanup,
  advisory suppression, broad compatibility refactor, or current-package-head churn.
- **D-04:** The detached ecommerce fresh-resolution matrix must select Phoenix
  `>= 1.8.9 and < 1.9.0`, LiveView `>= 1.1.33 and < 1.2.0`, Bandit
  `>= 1.12.1 and < 1.13.0`, Swoosh `>= 1.26.3 and < 1.27.0`, Postgrex
  `>= 0.22.4 and < 0.23.0`, Req `>= 0.6.1 and < 0.7.0`, Plug
  `>= 1.19.5 and < 2.0.0`, Mint `>= 1.9.3`, and hpax `>= 1.0.4`.
- **D-05:** A production/source compatibility change is allowed only after a
  focused compile or test failure proves it necessary. Keep any such fix inside
  ecommerce, minimal, covered, and behavior-preserving; otherwise stop and re-plan.

### 2. Two-stage mounted-source provenance

- **D-06:** Before the ecommerce remediation commit, run the causal proof in the
  current checkout with fresh temporary `MIX_DEPS_PATH` and `MIX_BUILD_PATH`
  values. Propagate both values through dependency fetch, compile, tests, and
  preparation; an omitted isolation variable invalidates the receipt.
- **D-07:** Directly assert via `Mix.Project.deps_paths/0` or an equivalent public
  Mix seam that ecommerce resolves `:scrypath` to the canonical repository root
  and `:scrypath_ops` to the canonical `scrypath_ops/` directory. Do not infer
  mounted-source identity only from a successful compile.
- **D-08:** The pre-commit provenance receipt records the current HEAD/base,
  source-scoped dirty status, canonical source paths, and SHA-256 values for the
  root and Ops manifests and locks. It must also prove the ecommerce lock did not
  change unexpectedly during checked-lock proof.
- **D-09:** After the atomic ecommerce implementation commit exists, repeat the
  causal proof in a disposable detached worktree at that exact SHA with isolated
  dependency/build paths. This post-commit proof supplements rather than replaces
  the roadmap's before-commit gate.
- **D-10:** Reuse the fail-closed cleanup discipline learned in Phase 146: validate
  the temporary parent and exact worktree child, ownership, non-symlink state,
  registration, and canonical path equivalence before deletion; clean up
  unconditionally; then prove absence and primary-workspace lock/status preservation.
  Never clear a contributor's ordinary `deps/` or `_build/` caches for evidence.

### 3. Required gate bundle and stop policy

- **D-11:** Run the ecommerce-local gate in diagnostic order: inspect/explain the
  manifest and lock diff; `mix deps.get --check-locked`; mounted-source path
  assertions; compile with warnings as errors; the focused existing mounted
  route/asset/link test; then the complete ecommerce `mix precommit` suite.
- **D-12:** Because ecommerce `precommit` includes formatting and
  `deps.unlock --unused`, immediately recheck the ecommerce lock hash, manifest/lock
  diff, formatting status, and source-scoped dirty baseline. Unexplained mutation
  blocks the commit.
- **D-13:** `mix e2e.prepare` is required prerequisite-bound integration
  preparation. It must pass with declared Postgres and Meilisearch services healthy
  before the ecommerce batch is accepted. Missing prerequisites are unavailable
  required evidence and block Phase 147 closure; they are not a pass and are not
  reclassified as service-free deterministic proof.
- **D-14:** After ecommerce-local proof is green, run the named root release-train
  gates once: warning-clean compile; root fast tests including the clean-workspace
  contract; `mix verify --exclude integration`; `mix verify.phase11`; and
  `mix verify.phase99`.
- **D-15:** Do not automatically rerun full standalone `mix verify.opsui` in
  Phase 147. Phase 146 owns that proof. Rerun it only if Phase 147 changes an
  Ops-owned source, manifest, lock, or focused contract file, or if mounted proof
  demonstrates an Ops-owned regression.
- **D-16:** Stop before commit/handoff on an unexplained dependency row, lock or
  dirty-baseline drift, wrong mounted source path, compile warning/error, focused
  route failure, ecommerce full-suite failure, required preparation failure,
  root release-gate failure, out-of-range fresh resolution, non-zero unsuppressed
  audit, unsafe cleanup state, or need for public/runtime/UI scope expansion.

### 4. Proportional browser evidence

- **D-17:** Run the existing focused mounted subset with `e2e/harness.spec.ts` and
  `e2e/operator.spec.ts` through the reusable Docker-only `make verify-mounted`
  lifecycle. The command owns services, assets, readiness, browser execution,
  diagnostics, and teardown without adding new browser specs or requiring host
  Elixir/Node/Postgres/Meilisearch setup.
- **D-18:** If the complete advisory `phase105-e2e` job runs for the exact candidate
  SHA, reference its existing evidence rather than manufacturing a second full local
  run. The full storefront, theme, screenshot, contrast, and visual-judge suite
  remains useful supplemental regression evidence but is not promoted to a required
  merge or Phase 147 gate.
- **D-19:** Browser evidence uses the roadmap's three states: `passed`, `failed`, or
  `unavailable`. Add `flake: true` when a retry changes a first-attempt failure into
  a pass. `unavailable` must name the missing service, asset build, Node/browser,
  server-readiness, or exact-SHA CI prerequisite; skipped/cancelled/unrelated-SHA
  jobs are never passes.
- **D-20:** A browser failure causally attributable to the dependency change or
  mounted functionality blocks closure. A classified non-causal advisory visual,
  infrastructure, or flake failure remains honestly failed/unavailable evidence and
  cannot replace required proof, but it does not silently expand this phase into UI
  remediation.
- **D-21:** Reuse existing Playwright report, trace, `test-results`, Phoenix log,
  and Phase 105 evidence summary behavior. Do not commit generated browser artifacts.
  Current `brandbook/` guidance supersedes older prompt material if a visual result
  needs interpretation, but Phase 147 makes no visual or brand changes.
- **D-33:** Automated evidence replaces human verification for Phase 147. A green
  focused required lane plus the existing deterministic/service/audit gates closes
  mounted behavior without a UAT file. Any proposed human verification item is an
  automation gap to close, not a manual acceptance step.
- **D-34:** Add a distinct required `ecommerce-mounted-smoke` job that invokes the
  same Docker command as local contributors. Keep the complete `phase105-e2e` lane
  advisory; this is a new focused gate, not a promotion or rename of that lane.

### 5. Hybrid four-graph closure ledger

- **D-22:** Use a hybrid provenance ledger. Retain the historical exact-SHA
  lockless resolution/audit evidence for root, legacy, and Ops; add the matching
  exact-SHA ecommerce proof; then collect one same-window final-candidate
  `mix deps.get --check-locked` and unsuppressed `mix hex.audit` row in each of the
  root, legacy, Ops, and ecommerce directories.
- **D-23:** Do not locklessly re-resolve all three completed graphs again solely for
  symmetry. Their historical exact-candidate fresh proofs remain authoritative;
  same-window checked locks and audits establish present-tense all-graph posture
  without confusing registry drift with the historical remediation result.
- **D-24:** The compact closure matrix records graph, candidate SHA, UTC window,
  OS and Elixir/OTP/Mix/Hex versions, tracked lock SHA-256, checked-lock result,
  unsuppressed audit result, relevant selected versions, historical fresh-proof
  reference, and required/service/browser classification. Exclude raw logs,
  disposable locks, dependency trees, advisory snapshots, temporary paths,
  credentials, and generated service/browser state.
- **D-25:** Represent history as four ordered remediation batches, not four literal
  commits: shared cross-graph Req handoff `f711521`; legacy primary `e50fbd5` plus
  Plug recovery `4e2abed`; Ops primary `59d2e6a` plus test-only closure `ff1531c`;
  and the future ecommerce implementation commit. Explain each role and path set;
  never squash, amend, hide, or rewrite the existing history.
- **D-26:** Planning/execution must reconcile roadmap and EVID-02 wording from
  "four graph-local commits" to the truthful "four ordered remediation batches"
  while preserving the one shared handoff and graph-local ownership of later work.
  This is planning-truth correction, not scope expansion.
- **D-27:** Close the folded dependency-advisory todo only after the ecommerce
  implementation commit, required gates, exact-SHA fresh proof, all-four dated rows,
  browser classification, topology ledger, cleanup verification, and unchanged
  protected user-owned files are all accounted for.
- **D-28:** The existing untracked
  `.planning/v1.36-v1.36-MILESTONE-AUDIT.md` is user-owned stale audit input. Preserve
  and hash-check it as part of the dirty baseline; do not stage, edit, delete, or use
  it as current Phase 147 closure truth.

### 6. Maintainer and adopter experience

- **D-29:** Primary maintainer JTBD: remove ecommerce's reproduced advisories,
  know that the exact mounted root/Ops sources compiled and ran, and obtain one short
  ledger showing which dependency, service, browser, or evidence boundary failed.
- **D-30:** Contributor DX remains familiar Mix, Hex, and Playwright commands with
  causal tests first, explicit prerequisites, no cache destruction, no new policy
  language, and no permanent proof subsystem.
- **D-31:** Adopter-facing behavior remains ordinary Phoenix/Ecto integration:
  the storefront and mounted operator routes keep working without exposing lock,
  resolver, commit, or audit mechanics through public APIs or UI.
- **D-32:** The governing quality pillars are security, correctness, compatibility,
  provenance, reproducibility, maintainability, operability, resilience, evidence
  clarity, privacy, least surprise, contributor/adopter DX, bounded runtime/CI cost,
  accessibility regression safety, and strict scope discipline. New visual design,
  microcopy, themes, animation, and brand work are not applicable.

### the agent's Discretion

- Exact temporary-directory names, the public Mix expression used to assert path
  equality, and the compact evidence-table formatting may vary if all locked
  provenance, cleanup, and redaction semantics are preserved.
- The focused browser command may use direct Playwright spec paths or an equivalent
  non-persistent invocation; do not add a new script unless execution proves the
  existing CLI form unusable.
- Root gate ordering may follow `CONTRIBUTING.md` where dependencies require it,
  provided every named gate runs after ecommerce-local proof and before closure.

### Folded Todos

- **Remediate reproduced dependency security advisories** — fold the remaining
  ecommerce remediation and all-four-graph closure into Phase 147. The todo began
  with advisories reproduced across four independent Mix projects; Phases 144-146
  completed the shared/root, legacy, and Ops portions. It remains open until D-27's
  full closure chain passes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, requirements, and advisory authority

- `.planning/ROADMAP.md` — Phase 147 goal, success criteria, ordering, and current
  four-commit wording that must be reconciled to remediation-batch truth.
- `.planning/REQUIREMENTS.md` — SEC-04, COMPAT-01, COMPAT-03, EVID-01, EVID-02,
  exclusions, and traceability.
- `.planning/PROJECT.md` — maintenance-only milestone boundary, green-main posture,
  adopter contract, and public-scope exclusions.
- `.planning/STATE.md` — Phase 146 handoff and current Phase 147 position.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`
  — authority preventing runtime/public capability expansion.
- `.planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md`
  — original four-batch intake, fixed minima, gates, and todo closure condition.
- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-RESEARCH.md`
  — reproduced four-graph advisories, exposure analysis, minima, and sequencing.
- `.planning/quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md`
  — dated package/advisory ledger and ecommerce risk classification.

### Prior-phase handoff and evidence

- `.planning/phases/144-root-http-client-dependency-remediation/144-CONTEXT.md`
  — shared Req-floor, cross-graph handoff, fresh-proof, and no-suppression rules.
- `.planning/phases/144-root-http-client-dependency-remediation/144-03-SUMMARY.md`
  — root exact-SHA fresh resolution, deterministic gates, audit, and cleanup evidence.
- `.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-CONTEXT.md`
  — graph-local dependency ownership and proof conventions.
- `.planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-02-SUMMARY.md`
  — legacy primary/recovery topology and exact-SHA audit evidence.
- `.planning/phases/146-scrypathops-web-client-remediation/146-CONTEXT.md`
  — immediately preceding fixed-compatible cohort, range matrix, Swoosh proof, and
  Phase 147 handoff.
- `.planning/phases/146-scrypathops-web-client-remediation/146-03-SUMMARY.md`
  — Ops exact-SHA fresh proof and fail-closed worktree cleanup pattern.
- `.planning/phases/146-scrypathops-web-client-remediation/146-04-SUMMARY.md`
  — test-only closure topology and final green Ops/root gates.
- `.planning/phases/146-scrypathops-web-client-remediation/146-VERIFICATION.md`
  — verified Phase 146 truths consumed by mounted ecommerce closure.

### Ecommerce dependency and mounted runtime surfaces

- `examples/scrypath_ecommerce/mix.exs` — direct dependency intent, path sources,
  aliases, precommit behavior, and required preparation command.
- `examples/scrypath_ecommerce/mix.lock` — independent deterministic ecommerce
  resolution and causal lock-diff surface.
- `examples/scrypath_ecommerce/README.md` — canonical demo prerequisites,
  mounted-Ops behavior, browser runbook, and advisory posture.
- `examples/scrypath_ecommerce/config/config.exs` — root/Ops runtime configuration,
  Ecto Repo, Oban, backend, and asset configuration.
- `examples/scrypath_ecommerce/config/runtime.exs` — E2E server versus preparation
  database/sandbox boundary.
- `examples/scrypath_ecommerce/config/test.exs` — test endpoint, Repo, and service
  configuration.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce_web/router.ex` — storefront,
  mounted `/admin/search`, and E2E route boundaries.
- `examples/scrypath_ecommerce/lib/mix/tasks/e2e.prepare_search.ex` — live search
  preparation owned by `mix e2e.prepare`.
- `examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs`
  — existing mounted route, nested-link, Ops asset, and storefront-bleed contract.

### Browser proof and evidence capture

- `examples/scrypath_ecommerce/playwright.config.ts` — retries, trace behavior,
  base URL, and browser configuration.
- `examples/scrypath_ecommerce/package.json` — existing E2E and visual commands.
- `examples/scrypath_ecommerce/e2e/harness.spec.ts` — focused mounted route smoke.
- `examples/scrypath_ecommerce/e2e/operator.spec.ts` — focused mounted operator flow.
- `examples/scrypath_ecommerce/e2e/storefront.spec.ts` — broader storefront proof
  included by the full advisory lane, not the focused Phase 147 subset.
- `examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts` — current full-lane
  mounted visual/accessibility contract; regression reference only.
- `scripts/ci/phase105_evidence.sh` — existing structured browser evidence summary.
- `brandbook/README.md` — current brand authority if an advisory visual result needs
  interpretation; no Phase 147 design changes.
- `brandbook/notes/accessibility-checks.md` — current accessibility reference for
  existing browser checks; no new accessibility surface.

### Repository gates and release policy

- `CONTRIBUTING.md` — exact root gates, ecommerce browser prerequisites, required
  versus advisory evidence policy, and green-main contributor workflow.
- `.github/workflows/ci.yml` — `phase105-e2e` service/assets/server/evidence topology
  and existing root/Ops jobs.
- `lib/mix/tasks/verify.ex` — root repository-hygiene gate.
- `lib/mix/tasks/verify.opsui.ex` — standalone Ops proof retained from Phase 146 and
  rerun only on an Ops-owned change.
- `lib/mix/tasks/verify.phase11.ex` — release/package/consumer truth gate.
- `lib/mix/tasks/verify.phase99.ex` — trust-lane compatibility gate.

### Local expert research

- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — host resolution,
  path/dependency contracts, bounds, public-library DX, and least surprise.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — warning-clean
  compilation, Hex audit, reproducible CI, release evidence, and bounded gates.
- `prompts/elixir-best-practices-deep-research.md` — idiomatic Mix/ExUnit and
  maintainable Elixir boundaries.
- `prompts/ecto-best-practices-deep-research.md` — real-Postgres testing, migrations,
  Sandbox ownership, and data correctness.
- `prompts/phoenix-best-practices-deep-research.md` — router, endpoint, ConnCase,
  LiveView, and Phoenix-native testing conventions.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — mounted LiveView and
  browser interaction guidance.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
  — Phoenix/Bandit/Ecto operational, security, telemetry, and SRE boundaries.

### Current primary external references used during discussion

- `https://hexdocs.pm/mix/Mix.Tasks.Deps.html` — Mix path dependencies and automatic
  recompilation behavior.
- `https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html` — checked-lock dependency fetching.
- `https://mix.hexdocs.pm/Mix.Project.html` — build/dependency paths and
  `deps_paths/1` provenance seam.
- `https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html` — retirement/advisory reporting
  and non-zero failure semantics.
- `https://playwright.dev/docs/test-retries` — clean, flaky, and failed browser outcomes.
- `https://playwright.dev/docs/trace-viewer` — CI trace collection and diagnosis.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Ecommerce `mix` aliases already provide checked dependency setup, warning-clean
  compile via precommit, full Postgres-backed ExUnit, and `mix e2e.prepare`.
- `page_controller_test.exs` already proves mounted Ops routes, nested links, asset
  inclusion, and absence of Ops stylesheet bleed on the storefront.
- `harness.spec.ts` and `operator.spec.ts` already provide a focused mounted browser
  smoke without inventing a new test surface.
- The `phase105-e2e` job already owns services, assets, server boot, browser retries,
  failure artifacts, and structured evidence summaries.
- `make verify-mounted` and `make verify-e2e` provide the approved reusable
  Docker-only orchestration layer; the focused command is required and the full
  deterministic visual/browser command remains advisory.
- Phase 144-146 summaries already contain exact-SHA fresh proof that the final hybrid
  ledger can reference rather than rerun locklessly.

### Established Patterns

- Root, legacy, Ops, and ecommerce are four independent Mix graphs with tracked
  locks; root and Ops are consumed by ecommerce as local path dependencies.
- Reviewed locks provide deterministic contributor/CI resolution; detached lockless
  probes prove the manifest contract; unsuppressed audits prove current advisory posture.
- Service-free deterministic gates, required prerequisite-bound preparation, and
  advisory browser evidence are classified separately. Unavailable is never pass.
- Dependency batches use bounded direct requirements, targeted solver closure,
  exact candidate SHAs, compact receipts, and fail-closed stop conditions.

### Integration Points

- Dependency implementation: `examples/scrypath_ecommerce/mix.exs` and
  `examples/scrypath_ecommerce/mix.lock` only unless a demonstrated causal
  ecommerce compatibility fix is required.
- Mounted proof: ecommerce path declarations, router mount, controller contract,
  and focused Playwright specs.
- Required live preparation: ecommerce Repo migrations plus Meilisearch index setup
  through the existing `e2e.prepare` alias.
- Closure: one Phase 147 compact evidence ledger referencing prior summaries and
  recording final same-window four-graph checked-lock/audit rows.

</code_context>

<specifics>
## Specific Ideas

- Evidence should read like an operator/release receipt: exact source, exact lock,
  exact command class, exact result, and explicit stop status—not a terminal dump.
- Causal proof runs from cheapest and most diagnostic to broadest: source identity,
  compile, mounted route, full host suite, live preparation, root regression, browser,
  then final four-graph closure.
- UI/UX quality remains user-facing and mounted-flow focused, but backend dependency
  mechanics stay out of the public API and interface.

</specifics>

<deferred>
## Deferred Ideas

Package-head modernization, promotion of the complete `phase105-e2e` lane, and
UI/brand changes remain outside v1.36. The owner explicitly approved reusable
Docker-only mounted verification and a separate focused required CI check for
Phase 147; those are no longer deferred.

</deferred>

---

*Phase: 147-ecommerce-mounted-ops-remediation-and-closure-evidence*
*Context gathered: 2026-08-25*
