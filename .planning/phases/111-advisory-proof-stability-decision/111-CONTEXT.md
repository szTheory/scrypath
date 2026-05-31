# Phase 111: Advisory Proof Stability Decision - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 111 delivers an evidence-backed CI posture decision for `phase105-e2e`: whether it remains advisory, needs hardening, or is ready for future required-check promotion.

This phase may inspect recent GitHub Actions outcomes, improve advisory evidence collection, tighten documentation around promotion criteria, and add lightweight checks that keep the written policy aligned with workflow reality. It must not add runtime APIs, broaden product scope, turn the E2E lane into a new product surface, or promote a heavier live/browser lane into required status without stability evidence.

</domain>

<decisions>
## Implementation Decisions

### Gate Posture
- **D-01:** Keep `phase105-e2e` advisory for Phase 111. Do not promote it to a required merge gate now.
- **D-02:** The reason for staying advisory is evidentiary, not philosophical: recent remote CI history reviewed through `gh` did not show enough `phase105-e2e` job outcomes to prove stable run behavior, likely because the workflow job exists locally ahead of `origin/main`.
- **D-03:** Lock the posture as "harden advisory with evidence collection plus prepare a future promotion path." This preserves the repo's lean required-gate contract while making promotion possible later if the lane earns it.
- **D-04:** Do not remove or replace `phase105-e2e`. It protects true browser/live-services behavior that service-free tests and narrower integration lanes cannot fully prove.

### Evidence Window
- **D-05:** Use a dual-window evidence model when evaluating future promotion:
  - `main` and scheduled workflow runs are the canonical stability source.
  - PR runs are the merge-risk source.
- **D-06:** Evidence must be tied to workflow run, commit SHA, event, job name, conclusion, runtime, retry/flaky signal, and failure classification. Local runs can inform debugging but are not sufficient promotion evidence by themselves.
- **D-07:** If the workflow file or job identity changes, planners must treat pre-change and post-change evidence separately unless the change is explicitly proven equivalent.

### Promotion Thresholds
- **D-08:** Future required-check promotion requires all existing promotion criteria to be satisfied together: stable job name, sustained low flake rate, bounded runtime, actionable artifacts, owner response expectations, and explicit trigger rules.
- **D-09:** Treat Playwright retries as flake detection, not as a way to hide instability. A pass-after-retry should count as a flaky signal for promotion evaluation.
- **D-10:** Prefer a graduated promotion path: advisory evidence collection -> short "shadow required" period with documented owner response and rollback criteria -> required branch-protection promotion only after evidence passes.
- **D-11:** Do not use scoped/path-based required promotion for Phase 111. It creates trigger ambiguity and can miss cross-cutting regressions. If considered later, it needs dedicated trigger-policy proof.

### Failure Artifacts
- **D-12:** Define "actionable artifacts" as enough evidence to classify the failure without an immediate rerun.
- **D-13:** The advisory lane should capture a layered triage bundle on failure:
  - Playwright HTML report, traces, screenshots/videos where available, and `test-results`.
  - Phoenix app log for the example server.
  - Meilisearch `/health` and filtered task state relevant to the run.
  - Readiness/data setup snapshot sufficient to distinguish fixture, queue-drain, search-visibility, and operator-state failures.
- **D-14:** Avoid full diagnostic dumps by default. Artifact collection should be structured and bounded so it improves maintainer triage without creating noisy, sensitive, or expensive uploads.

### Required Gate Discipline
- **D-15:** Routine required gates remain lean: `main-ci`, `repo-hygiene`, `release-truth`, and `phase99-trust`.
- **D-16:** `phase105-e2e` can remain on PR, push, schedule, and manual triggers as advisory evidence, but Phase 111 must not add branch-protection requirements.
- **D-17:** Documentation and tests should make the advisory/required split explicit so contributors are not surprised by what blocks merge.

### the agent's Discretion
- Planner may choose the exact evidence artifact implementation, such as a small shell script, workflow summary step, generated JSON/Markdown evidence record, or focused ExUnit/docs contract assertions.
- Planner may choose exact numeric thresholds if they are explicit, conservative, and easy to audit. Suggested shape: minimum run count or time window, flake classification that treats retry-pass as flaky, p95 runtime envelope within the 20-minute timeout, and owner-response expectation before promotion.
- Planner may add route/documentation checks that ensure `CONTRIBUTING.md`, `.github/workflows/ci.yml`, and any support/readiness surfaces agree on the advisory posture.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 111 goal, STAB-01/STAB-02 requirements, success criteria, and Phase 112 boundary.
- `.planning/REQUIREMENTS.md` - v1.30 proof-stability requirements and out-of-scope constraints.
- `.planning/PROJECT.md` - maintenance-and-evidence mode, lean required-gate posture, current proof policy, scope guard authority, and no-product-expansion boundary.
- `.planning/STATE.md` - active position and prior decisions around `phase105-e2e`, lean gates, and advisory proof posture.

### Prior Decisions
- `.planning/phases/109-release-train-and-package-truth-audit/109-CONTEXT.md` - release-truth decisions, especially lean always-on gates and keeping live/external checks out of routine PR blockers.
- `.planning/phases/110-support-intake-and-evidence-routing/110-CONTEXT.md` - support/evidence routing decisions, especially lightweight evidence discipline and avoiding heavyweight process.
- `.planning/milestones/v1.28-MILESTONE-AUDIT.md` - original `phase105-e2e` advisory debt note, Phase 105 proof status, and prior harness warning.

### CI and Verification Surfaces
- `.github/workflows/ci.yml` - `phase105-e2e` job definition, services, timeout, triggers, artifact upload, and current required/advisory CI topology.
- `CONTRIBUTING.md` - contributor-facing CI table, `phase105-e2e` runbook, advisory status, and promotion criteria.
- `examples/scrypath_ecommerce/playwright.config.ts` - Playwright retries, worker count, reporter, trace behavior, and browser project configuration.
- `examples/scrypath_ecommerce/package.json` - E2E script entrypoints.
- `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` - readiness, seed, drain, search-visible, failed-sync, operator-state, and swap polling helpers.
- `examples/scrypath_ecommerce/e2e/storefront.spec.ts` - storefront proof surface covered by the browser lane.
- `examples/scrypath_ecommerce/e2e/operator.spec.ts` - operator proof surface covered by the browser lane.
- `examples/scrypath_ecommerce/e2e/harness.spec.ts` - harness-level proof surface covered by the browser lane.

### Prompt Research
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - lean required CI, slower optional/advisory matrices, GitHub Actions discipline, Release Please/Hex trust, and docs-as-product expectations.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` - Elixir OSS library expectations around explicit APIs, operational clarity, docs, and low-surprise DX.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - Phoenix/Ecto production guidance, process discipline, observability, and operational failure-mode clarity.
- `prompts/elixir-search-lib-deep-research.md` - search-library lessons around explicit projection/sync proof, zero-downtime workflows, batching, and operational observability.
- `prompts/meileisearch best practices for scrypath deep research.md` - Meilisearch task semantics, health/task observability, async indexing reality, and operator mental model.
- `prompts/scrypath-brand-book.md` - brand posture: calm, exact, technical, trustworthy, and operationally honest.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.github/workflows/ci.yml` already defines `phase105-e2e` with Postgres 16, Meilisearch v1.15, Phoenix readiness checks, Playwright execution, 20-minute timeout, and failure artifact upload.
- `CONTRIBUTING.md` already documents `phase105-e2e` as advisory and lists the promotion criteria: stable job name, sustained low flake rate, bounded runtime, actionable artifacts, owner response, and explicit trigger rules.
- `examples/scrypath_ecommerce/playwright.config.ts` already uses CI-oriented Playwright defaults: one retry in CI, single worker in CI, HTML report in CI, and trace on first retry.
- `examples/scrypath_ecommerce/e2e/helpers/e2e.ts` already has deterministic seed, drain, visibility, and operator polling helpers that can feed a structured readiness/artifact snapshot.

### Established Patterns
- Scrypath keeps routine required gates lean and deterministic where possible; live/external/browser checks remain explicit evidence lanes unless they prove stable enough to block merges.
- Planning and contributor docs prefer route-first truth and focused contract checks over broad process sprawl.
- Existing verification tasks and docs contract tests are acceptable places to assert that docs and workflow posture agree.
- Search sync failures are treated as operational evidence, not cosmetic CI noise; failure artifacts should help classify and route the problem.

### Integration Points
- Harden `.github/workflows/ci.yml` failure steps or scripts so `phase105-e2e` produces promotion-grade evidence without changing branch protection.
- Update `CONTRIBUTING.md` to clarify the Phase 111 decision, evidence window, promotion path, and artifact standard.
- Add focused tests, likely under `test/mix/tasks/workflow_wiring_test.exs` or a new phase-specific contract test, if planner finds a deterministic way to assert job name, advisory posture, artifact paths, and promotion criteria alignment.
- Optionally add a generated workflow summary or evidence artifact for `phase105-e2e` runs, provided it stays lightweight and does not require external credentials.

</code_context>

<specifics>
## Specific Ideas

The user asked that all gray areas be considered with subagent-backed research, ecosystem lessons, prompt-corpus context, DX emphasis, principle of least surprise, and one cohesive recommendation set.

Four advisor researchers independently converged on the same posture:

1. Use a dual-window scorecard: `main`/scheduled runs for canonical stability, PR runs for merge-risk signal.
2. Keep `phase105-e2e` advisory now because promotion evidence is not yet present in recent remote CI history.
3. Harden advisory evidence instead of treating advisory as "best effort."
4. Define a graduated future promotion path and avoid branch-protection changes until thresholds are met.
5. Make artifacts actionable enough to classify failure type without rerun.

Local evidence gathered during discussion:

- `phase105-e2e` exists in `.github/workflows/ci.yml` locally.
- `CONTRIBUTING.md` already says `phase105-e2e` is advisory and documents promotion criteria.
- Recent `gh run list --workflow ci.yml` results from 2026-05-27 through 2026-05-30 showed many CI runs on `origin/main` and PRs, but viewed recent job lists did not include `phase105-e2e`, likely because local `main` is ahead of `origin/main`.
- The lack of visible recent remote `phase105-e2e` outcomes is itself evidence against immediate required promotion.

</specifics>

<deferred>
## Deferred Ideas

- Promoting `phase105-e2e` to a required branch-protection check is deferred until the documented evidence thresholds are met.
- Scoped/path-based required promotion is deferred because trigger ambiguity and skipped-required-check behavior need their own proof.
- Full diagnostic artifact dumps are deferred unless repeated advisory failures prove the layered triage bundle is insufficient.
- Replacing `phase105-e2e` with a different proof lane is deferred; current evidence supports hardening rather than removal.
- New runtime APIs, product-surface changes, public backend broadening, autocomplete/suggestions, vector/hybrid, and broader website truth alignment remain outside Phase 111.

</deferred>

---

*Phase: 111-Advisory Proof Stability Decision*
*Context gathered: 2026-05-31*
