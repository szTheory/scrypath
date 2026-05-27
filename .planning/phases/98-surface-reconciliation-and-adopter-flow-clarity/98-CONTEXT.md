# Phase 98: Surface Reconciliation and Adopter Flow Clarity - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 98 reconciles high-risk adopter-facing surfaces so install/version/support/proof wording is coherent, fast-vs-live proof boundaries are explicit, and intake/escalation guidance is actionable for maintainers.

This phase is contract-surface hardening only. It does not add runtime features, backend breadth, or new public runtime API categories.

</domain>

<decisions>
## Implementation Decisions

### Surface Wording Strictness and Authority
- **D-01:** Use a layered-authority model. `guides/support-and-compatibility.md` remains the only canonical owner for normative support/compatibility/proof policy wording.
- **D-02:** `README.md`, `CONTRIBUTING.md`, and `guides/outside-adopter-intake.md` keep concise, fixed "micro-contract" restatements plus one-hop routing to canonical authority. No broad policy restatement on these surfaces.
- **D-03:** `examples/phoenix_meilisearch/README.md` owns live-runbook operational detail (env vars, service assumptions, command sequence) and routes back to support guide for policy semantics.

### Proof Boundary Placement (Fast vs Live)
- **D-04:** Adopt a two-tier canonical model: policy authority in support guide, runbook authority in example README, and executable truth in `lib/mix/tasks/verify.adopter.ex`.
- **D-05:** Fast vs live boundary must remain explicit and non-contradictory across all primary surfaces: `mix verify.adopter` is fast/service-free; `mix verify.adopter --live` is explicit/prerequisite-bound.
- **D-06:** Root entry surfaces (README, CONTRIBUTING) provide one-hop proof discoverability and identity, not full env matrix duplication.

### Intake Evidence and Escalation Contract
- **D-07:** Outside-adopter intake must require deterministic evidence fields: runtime matrix, Scrypath ref/version, proof path, ordered commands, expected vs actual, first failure point, and logs.
- **D-08:** Keep Class A-D admissibility and add explicit class-to-maintainer-routing language so triage outcomes are predictable (bug vs docs-gap vs app-side error vs environment issue).
- **D-09:** Include explicit security-report carve-out and "needs information" follow-up wording to avoid indefinite ambiguous issue churn.

### Phase 98 Drift Gate Shape
- **D-10:** `mix verify.phase98` should be a focused, service-free hard gate for phase-98 contract surfaces and proof-boundary consistency.
- **D-11:** Assertions should be shape/token based (anchors, command names, env var keys, routing semantics, CI/example sequence parity), not brittle full-paragraph snapshots.
- **D-12:** Gate scope is bounded to high-risk surfaces from the v1.27 contract-surface map; avoid generic wording-police across unrelated docs.

### Cross-Area Coherence Locks
- **D-13:** Preserve phase-97 canonical statement IDs (`CST-TRUTH-01-INSTALL`, `CST-TRUTH-02-RELEASE-MAIN`, `CST-TRUTH-03-SUPPORT-AUTHORITY`) as immutable inputs for all phase-98 edits and tests.
- **D-14:** Keep release-backed vs unreleased-`main` distinction explicit where adopters make install/proof decisions.
- **D-15:** Apply least-surprise DX: first-hop docs answer "what to do now," deeper guides own full policy or runbook detail.

### Claude's Discretion
- Exact section names/anchor names and micro-contract phrasing in each surface, provided D-01 through D-15 remain intact.
- Exact split of assertions between `test/scrypath/docs_contract_test.exs`, `test/scrypath/readiness_contract_test.exs`, and any new focused phase-98 tests.
- Exact implementation location for intake-form or template refinements, provided guide authority boundaries remain unchanged.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Requirement Authority
- `.planning/ROADMAP.md` — Phase 98 goal, requirement mapping, and success criteria.
- `.planning/REQUIREMENTS.md` — `PROOF-01`, `PROOF-02`, `PROOF-03`, `SUP-01`, `SUP-02`.
- `.planning/PROJECT.md` — v1.27 canonical contract and non-goal posture.
- `.planning/STATE.md` — active scope and trust-hardening lane context.

### Phase 97 Locked Inputs
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-STATEMENTS.md` — frozen canonical statement IDs and wording.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-TRACEABILITY.md` — requirement-to-statement ledger and no-orphan-surface framing.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md` — scope guard and reopen policy.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTEXT.md` — prior locked decisions and canonical surface boundaries.

### Phase 98 Surface and Gate Planning Inputs
- `.planning/research/v1.27-contract-surface-map.md` — high-risk surface inventory and acceptance rule.
- `.planning/research/v1.27-gate-strategy.md` — verify alias and required-check strategy framing.

### Current High-Risk Surface Files
- `README.md` — primary adopter entrypoint and one-hop contract/proof routing.
- `CONTRIBUTING.md` — maintainer/contributor verification and CI contract wording.
- `guides/support-and-compatibility.md` — canonical support/proof policy authority.
- `guides/outside-adopter-intake.md` — intake evidence and classing authority.
- `examples/phoenix_meilisearch/README.md` — canonical live proof runbook details.
- `docs/templates/outside-adopter-evidence.md` — required evidence bundle shape.
- `lib/mix/tasks/verify.adopter.ex` — executable proof-boundary contract.
- `test/scrypath/readiness_contract_test.exs` — fast-path support/proof contract assertions.
- `test/scrypath/docs_contract_test.exs` — cross-surface docs contract assertions.
- `lib/mix/tasks/verify.phase97.ex` — focused verify alias pattern for milestone-scoped gating.

### Prompt Guidance to Apply
- `prompts/elixir-best-practices-deep-research.md` — explicit APIs, stable return-shape discipline, least surprise.
- `prompts/ecto-best-practices-deep-research.md` — context boundary and explicit operational semantics.
- `prompts/phoenix-best-practices-deep-research.md` — thin entry surfaces and clear boundary ownership.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS API/doc ergonomics and anti-drift guidance.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — focused, low-noise CI gate design.
- `prompts/scrypath-brand-book.md` — voice and positioning constraints for adopter-facing copy.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/verify.adopter.ex`: already codifies fast/live split and required live env variables.
- `test/scrypath/readiness_contract_test.exs`: already checks support/proof discoverability and env/prereq truth.
- `test/scrypath/docs_contract_test.exs`: already enforces many cross-surface anchor and phrase contracts.
- `lib/mix/tasks/verify.phase97.ex`: proven pattern for scoped milestone verify task orchestration.

### Established Patterns
- Keep required gates service-free and deterministic; preserve explicit heavier live path (`--live`) for deeper proof.
- Use docs-contract assertions for high-risk anchors and command/routing truth, not broad prose snapshots.
- Preserve one canonical owner surface with concise route-and-context entry surfaces.

### Integration Points
- Phase 98 edits should reconcile wording across `README.md`, `CONTRIBUTING.md`, `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`, and `examples/phoenix_meilisearch/README.md`.
- Phase 98 verification should add/adjust focused checks in `verify.phase98` and tests without widening unrelated test scope.
- Intake refinements should align `guides/outside-adopter-intake.md` with `docs/templates/outside-adopter-evidence.md`.

</code_context>

<specifics>
## Specific Ideas

- Use a fixed micro-contract phrase set across root entry surfaces for release-backed vs `main` truth and proof-spine discoverability.
- Keep policy-vs-runbook boundary explicit: support guide explains policy; example README explains how to run live proof.
- Encode "what changed" checks as contract tokens (command identity, env var keys, one-hop links), not paragraph-equality checks.
- Lessons carried from successful libraries: thin quickstart + deeper canonical guides (Searchkick/Scout style) and strict anti-drift boundaries to avoid doc entropy.

</specifics>

<deferred>
## Deferred Ideas

- Full automation-heavy intake triage bots and advanced workflow automation are deferred beyond phase 98 (not required to satisfy `SUP-01`/`SUP-02`).
- Monolithic wording lint over all docs is deferred; keep phase-98 gate bounded to high-risk contract surfaces.
- Any runtime feature breadth or backend-surface expansion remains deferred under the active scope guard.

</deferred>

---

*Phase: 98-surface-reconciliation-and-adopter-flow-clarity*
*Context gathered: 2026-05-27*
