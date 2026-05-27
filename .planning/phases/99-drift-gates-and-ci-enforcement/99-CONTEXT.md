# Phase 99: Drift Gates and CI Enforcement - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 99 converts the v1.27 reconciled adopter contract into durable, low-noise enforcement gates across docs, proof-boundary, and CI wiring surfaces.

This phase is trust-hardening only. It does not add runtime feature breadth, new backend/runtime API classes, or Phoenix/UI runtime expansion.

</domain>

<decisions>
## Implementation Decisions

### Gate shape (`mix verify.phase99`)
- **D-01:** Add a focused, dedicated `mix verify.phase99` gate (not CI-only and not a broad umbrella that reruns all prior phase gates).
- **D-02:** Keep the gate service-free and deterministic: focused phase-99 test slices plus `mix docs --warnings-as-errors`.
- **D-03:** Follow existing phase-gate task ergonomics (`ensure_no_args!`, focused test list markers, `cli.preferred_envs` registration).

### Required PR checks contract
- **D-04:** During v1.27 feature-lane execution, required checks are explicitly: `main-ci`, `repo-hygiene`, `release-truth`, and one stable phase-99 trust check job running `mix verify.phase99` (recommended name: `phase99-trust`).
- **D-05:** Heavy/live/advisory checks remain non-blocking by default (`mix verify.adopter --live`, service-backed integration suites, deep-quality sweeps), unless maintainers intentionally promote them.
- **D-06:** Required-check names are contract tokens: docs, workflow wiring, and tests must stay in sync to prevent branch-protection drift.

### Assertion placement and ownership
- **D-07:** Create `test/scrypath/phase99_contract_test.exs` as the primary owner for phase-99 trust assertions (`TEST-01`, `TEST-02`, `TEST-03`) using token/anchor/command checks.
- **D-08:** Keep `test/scrypath/docs_contract_test.exs` for evergreen cross-milestone invariants only; avoid adding phase-specific noise there by default.
- **D-09:** Keep task/wiring assertions in `test/mix/tasks/verify.phase99_test.exs` and `test/mix/tasks/workflow_wiring_test.exs` (job/check name parity, preferred env wiring, command routing).

### Strictness and noise calibration
- **D-10:** Enforce stable contract tokens and anchors (commands, env keys, check names, canonical links), not full-paragraph snapshot equality.
- **D-11:** Required-gate failures must be actionable: identify the failing surface/check token and point to local reproduction via `mix verify.phase99`.
- **D-12:** Avoid path-conditional required-check logic for this milestone to prevent ambiguous/skipped-pending check states.

### Coherent architecture
- **D-13:** Use a layered trust-rings architecture: (1) content contract assertions, (2) gate/task wiring assertions, (3) required-check policy assertions, executed through one canonical command.
- **D-14:** Treat phase-97 and phase-98 outcomes as locked upstream inputs; phase-99 enforces drift protection over those inputs without redefining them.
- **D-15:** Keep release-train posture: lean, predictable required gates with clear required-vs-advisory boundaries.

### Claude's Discretion
- Final required trust-job name (`phase99-trust` vs `phase99-contract`) as long as it is stable and consistently reflected in workflow, docs, and tests.
- Exact split of assertions between `phase99_contract_test.exs` and existing suites, provided ownership boundaries in D-07 through D-09 stay intact.
- Exact assertion helper shape (shared test helpers or inline helpers) as long as failure messages stay high-signal and reproducible.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone authority and scope
- `.planning/ROADMAP.md` — phase 99 goal, requirements mapping, gate strategy, and success criteria.
- `.planning/REQUIREMENTS.md` — `TEST-01`, `TEST-02`, `TEST-03`, `GATE-01`, `GATE-02`.
- `.planning/PROJECT.md` — v1.27 canonical adopter contract and non-goal boundaries.
- `.planning/STATE.md` — active milestone posture and trust-hardening lane context.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTEXT.md` — locked contract authority and scope guard carry-forward.
- `.planning/phases/98-surface-reconciliation-and-adopter-flow-clarity/98-CONTEXT.md` — layered strict-core enforcement philosophy and surface-boundary decisions.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md` — active scope guard and reopen policy.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-STATEMENTS.md` — frozen canonical statement IDs consumed by downstream gates.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-TRACEABILITY.md` — requirement-to-statement ledger expectations.
- `.planning/research/v1.27-gate-strategy.md` — required/advisory check intent and milestone gate framing.
- `.planning/research/v1.27-contract-surface-map.md` — high-risk contract surfaces and planned verification anchors.

### Existing enforcement seams and surfaces
- `lib/mix/tasks/verify.phase97.ex` — focused phase-gate task pattern.
- `lib/mix/tasks/verify.phase98.ex` — focused service-free gate and docs build pattern.
- `lib/mix/tasks/verify.adopter.ex` — canonical adopter proof spine and live-boundary execution semantics.
- `test/mix/tasks/verify.phase98_test.exs` — verify-task contract test pattern.
- `test/mix/tasks/workflow_wiring_test.exs` — CI/wiring parity assertion seam.
- `test/scrypath/phase98_contract_test.exs` — focused phase-scoped contract assertions.
- `test/scrypath/docs_contract_test.exs` — evergreen docs-contract baseline seam.
- `.github/workflows/ci.yml` — current required check jobs and job naming surface.
- `mix.exs` — `cli.preferred_envs` verify-alias wiring contract.
- `CONTRIBUTING.md` — documented required-vs-advisory CI contract for contributors.
- `README.md` — root proof/install wayfinding and canonical command references.
- `guides/support-and-compatibility.md` — policy authority for support/proof boundaries.
- `guides/outside-adopter-intake.md` — evidence and escalation contract surface.
- `examples/phoenix_meilisearch/README.md` — live-proof runbook parity surface.

### Ecosystem research inputs (apply during planning)
- `prompts/elixir-best-practices-deep-research.md` — idiomatic Elixir API and operational contract guidance.
- `prompts/ecto-best-practices-deep-research.md` — Ecto-native boundary and explicitness patterns.
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix integration and least-surprise guidance.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — UX/interaction consistency constraints where relevant.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — system boundary and architecture guidance.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS contract ergonomics and anti-footgun practices.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — CI gate design and release-train tradeoffs.
- `prompts/elixir-search-lib-deep-research.md` — search-library contract and maintenance posture lessons.
- `prompts/search-lib-use-cases-deep-research.md` — adopter expectations and DX implications.
- `prompts/scrypath-brand-book.md` — product voice and positioning constraints.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/verify.phase97.ex` and `lib/mix/tasks/verify.phase98.ex`: established focused verify-task scaffold (no args, focused tests, docs build).
- `test/scrypath/phase98_contract_test.exs`: proven token-based, bounded contract assertion style.
- `test/mix/tasks/workflow_wiring_test.exs`: existing place to lock workflow/check-name and `mix.exs` parity.
- `.github/workflows/ci.yml`: existing lean required-check baseline (`main-ci`, `repo-hygiene`, `release-truth`) to extend with one milestone trust job.

### Established Patterns
- Service-free required gates; heavier service-backed checks are separate and usually advisory.
- Token/anchor/command-shape assertions preferred over brittle prose snapshots.
- One canonical command per verification intent (`mix verify.phase*`, `mix verify.adopter`) for local/CI parity.

### Integration Points
- New task: `lib/mix/tasks/verify.phase99.ex`.
- New task tests: `test/mix/tasks/verify.phase99_test.exs`.
- New focused phase contract suite: `test/scrypath/phase99_contract_test.exs`.
- Wiring/contract parity updates: `test/mix/tasks/workflow_wiring_test.exs`, `mix.exs`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`.

</code_context>

<specifics>
## Specific Ideas

- Keep a single stable required trust-job name and treat it as a contract token to avoid branch-protection ambiguity.
- Make phase99 failures explicit and user-friendly: indicate file/surface and missing token/check name, plus `mix verify.phase99` reproduce command.
- Apply cross-ecosystem lesson from successful libraries: keep required lanes deterministic and fast; keep heavy integration evidence explicit/advisory unless intentionally promoted.
- Avoid the common docs-gate footgun seen in many ecosystems: broad prose snapshots that create recurring false-positive CI churn.

</specifics>

<deferred>
## Deferred Ideas

- Manifest-driven contract engine for generalized policy linting (valuable later, overkill for current milestone scope).
- Path-conditional required-check escalation policy (adds complexity and pending-check edge cases; revisit only if CI pressure materially increases).
- Promotion of live/service-heavy proof checks to required status without explicit maintainer policy change and evidence.

</deferred>

---

*Phase: 99-drift-gates-and-ci-enforcement*
*Context gathered: 2026-05-27*
