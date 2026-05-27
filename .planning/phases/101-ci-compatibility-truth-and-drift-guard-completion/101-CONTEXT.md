# Phase 101: ci-compatibility-truth-and-drift-guard-completion - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 101 aligns compatibility/support claims with the CI runtime lanes that are actually executed, then closes drift-guard coverage so CI/version parity is enforced across canonical trust surfaces.

This phase remains trust-surface hardening only. It does not add runtime search capability breadth, backend breadth, or new public runtime API categories.

</domain>

<decisions>
## Implementation Decisions

### Compatibility Truth Resolution Path
- **D-01:** Resolve the mismatch by aligning executable CI evidence with canonical support claims, not by leaving policy statements ahead of proof.
- **D-02:** Keep required merge blockers lean (`main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust`) while adding a compatibility-truth lane strategy that proves floor/head claims without expanding the required-check contract surface.
- **D-03:** If compatibility tuples are claimed in the support authority, those tuples must be present in CI lane configuration and asserted by contract tests.

### Supported-Range Semantics
- **D-04:** Adopt a tiered range-plus-evidence model in `guides/support-and-compatibility.md`: declared support boundary plus explicit CI-verified tuples.
- **D-05:** Keep `mix.exs` floor (`elixir: "~> 1.17"`) and CI tuple evidence semantically coherent; avoid implying that floor declaration alone equals full CI verification.
- **D-06:** Preserve explicit release-backed vs unreleased-`main` language on routing surfaces to keep first-hop adopter guidance least-surprise and audit-safe.

### Drift Guard Assertion Strategy
- **D-07:** Extend trust-lane assertions with normalized semantic parity checks (not prose snapshots) between support authority claims, CI workflow lanes, and Mix floor policy.
- **D-08:** Keep CI/version parity ownership in focused phase trust contract tests (`test/scrypath/phase99_contract_test.exs`) with actionable failure messages that show expected vs actual lane/value mismatches.
- **D-09:** Keep job-name/check wiring assertions in `test/mix/tasks/workflow_wiring_test.exs`; keep semantic compatibility truth assertions in phase contract tests to avoid mixed responsibilities.

### Surface Ownership and Routing
- **D-10:** `guides/support-and-compatibility.md` remains the only normative owner of compatibility matrix semantics.
- **D-11:** `README.md`, `CONTRIBUTING.md`, and intake surfaces remain route-first micro-contract surfaces; they should not carry competing matrix prose/value tables.
- **D-12:** Non-owner surfaces may carry stable routing tokens, but compatibility tuple/value truth must be centralized and parity-tested against the owner surface.

### Claude's Discretion
- Exact CI lane topology (single job matrix vs dedicated compatibility lane job) as long as required-check contract tokens remain stable and trust claims stay evidence-backed.
- Exact assertion helper implementation shape (inline helper functions vs small shared helper module) as long as semantic parity and failure diagnostics remain explicit.
- Exact wording of micro-contract route lines on non-owner surfaces, provided canonical ownership boundaries and release/main truth tokens remain intact.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Scope Authority
- `.planning/ROADMAP.md` — Phase 101 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — `TRUTH-03` and `TEST-01` requirement definitions and traceability.
- `.planning/PROJECT.md` — v1.27 contract posture, trust-hardening lane, and non-goal boundaries.
- `.planning/STATE.md` — active phase focus and drift concern context.
- `.planning/v1.27-v1.27-MILESTONE-AUDIT.md` — blocker evidence proving CI/runtime compatibility claim drift.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md` — active scope guard and reopen policy.

### Prior Locked Context Inputs
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTEXT.md` — canonical authority model and scope-guard carry-forward.
- `.planning/phases/98-surface-reconciliation-and-adopter-flow-clarity/98-CONTEXT.md` — layered authority and proof-surface reconciliation pattern.
- `.planning/phases/99-drift-gates-and-ci-enforcement/99-CONTEXT.md` — trust-gate structure and low-noise CI philosophy.
- `.planning/phases/100-install-release-contract-reconciliation/100-CONTEXT.md` — token parity and owner/reference contract carry-forward.
- `.planning/research/v1.27-contract-surface-map.md` — mapped high-risk trust surfaces.
- `.planning/research/v1.27-gate-strategy.md` — required/advisory gate expectations.

### Implementation Surfaces and Enforcement Seams
- `guides/support-and-compatibility.md` — canonical compatibility/support authority surface.
- `.github/workflows/ci.yml` — executable CI runtime lane truth.
- `mix.exs` — Elixir floor declaration and verify alias wiring.
- `README.md` — route-first adopter entrypoint.
- `CONTRIBUTING.md` — maintainer CI contract and verification routing.
- `guides/outside-adopter-intake.md` — intake flow routing and trust-surface references.
- `test/scrypath/phase99_contract_test.exs` — focused trust contract assertions.
- `test/scrypath/docs_contract_test.exs` — evergreen docs-contract guardrails.
- `test/mix/tasks/workflow_wiring_test.exs` — required-check/wiring token parity assertions.
- `lib/mix/tasks/verify.phase99.ex` — canonical trust gate entrypoint.
- `test/mix/tasks/verify.phase99_test.exs` — verify-phase99 task contract coverage.

### Prompt Research Inputs
- `prompts/elixir-best-practices-deep-research.md` — explicit contracts and least-surprise Elixir API posture.
- `prompts/ecto-best-practices-deep-research.md` — boundary ownership and context discipline.
- `prompts/phoenix-best-practices-deep-research.md` — route-first docs ergonomics and thin edge surfaces.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — interaction/UX clarity constraints.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — system-boundary and architecture tradeoffs.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS trust-surface and docs authority patterns.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — deterministic CI gate and noise-control strategy.
- `prompts/elixir-search-lib-deep-research.md` — search-library trust and adoption lessons.
- `prompts/search-lib-use-cases-deep-research.md` — adopter expectations and support-path implications.
- `prompts/scrypath-brand-book.md` — voice, positioning, and contract clarity constraints.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/scrypath/phase99_contract_test.exs`: already contains trust-token parity checks and is the correct seam to add CI/version semantic parity assertions.
- `test/scrypath/docs_contract_test.exs`: provides evergreen route/token guardrails for high-risk docs.
- `test/mix/tasks/workflow_wiring_test.exs`: already enforces check-name and task-wiring contracts (`phase99-trust`, `mix verify.phase99`).
- `lib/mix/tasks/verify.phase99.ex`: deterministic trust-gate task already wired as canonical entrypoint.

### Established Patterns
- Trust hardening favors token/shape assertions over brittle prose snapshots.
- Canonical owner + route-only satellite surfaces is already the adopted model from phases 97-100.
- Required gates stay lean; heavy or live checks remain explicit/advisory unless intentionally promoted.

### Integration Points
- Compatibility truth must be synchronized across `guides/support-and-compatibility.md`, `.github/workflows/ci.yml`, and `mix.exs`.
- Route-only surfaces (`README.md`, `CONTRIBUTING.md`, intake docs) should reference canonical authority without carrying competing matrix values.
- Phase-101 checks should run through existing `mix verify.phase99` trust lane to preserve required-check stability.

</code_context>

<specifics>
## Specific Ideas

- Use a tiered compatibility narrative: declared support boundary, explicitly CI-verified tuples, and clear wording for in-range-but-not-currently-exercised scenarios.
- Keep required check identity stable while making compatibility truth executable (avoid introducing branch-protection churn).
- Cross-ecosystem lesson: successful libraries centralize policy ownership and keep entry surfaces thin; failed patterns usually duplicate version matrices across docs and drift quickly.

</specifics>

<deferred>
## Deferred Ideas

- Full contract-manifest generation system (single machine-readable source that emits docs/tests) is deferred beyond this phase.
- Broad CI matrix expansion across many tuples/lanes is deferred; phase intent is truth parity, not exhaustive runtime cartesian coverage.
- Any runtime feature or backend breadth work remains deferred under active scope guard.

</deferred>

---

*Phase: 101-ci-compatibility-truth-and-drift-guard-completion*
*Context gathered: 2026-05-27*
