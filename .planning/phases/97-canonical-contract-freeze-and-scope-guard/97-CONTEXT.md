# Phase 97: Canonical Contract Freeze and Scope Guard - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 97 freezes Scrypath's canonical adopter contract wording and explicit non-goals so phase 98 can reconcile surfaces without reopening product scope. This phase covers install/version truth, release-backed vs `main` truth, support/proof authority, and requirement traceability stability.

Phase 97 does not add runtime feature breadth, backend breadth, new public runtime APIs, or new Phoenix/UI runtime surfaces.

</domain>

<decisions>
## Implementation Decisions

### Canonical Contract Authority
- **D-01:** `guides/support-and-compatibility.md` is the single adopter-facing canonical wording authority for install/version policy, release-vs-`main` truth, support/compatibility posture, and proof-boundary posture.
- **D-02:** `README.md`, `CONTRIBUTING.md`, and `guides/outside-adopter-intake.md` must reference canonical support-guide anchors for normative contract text instead of independently restating policy prose.
- **D-03:** Planning docs remain governance authority for requirement mapping and scope guard enforcement, but they do not replace the support guide as adopter-facing contract authority.

### Install and Version Truth Policy
- **D-04:** Release-backed install guidance is the default adopter path. Any guidance tied to `main` must be explicitly marked as unreleased branch-tip behavior.
- **D-05:** Version examples across high-risk surfaces must remain coherent with current release reality; no speculative major-version snippets in adopter-facing install guidance.
- **D-06:** Outside-adopter intake must require exact artifact evidence: Hex version for package reports or exact git ref/commit for repo-clone reports.

### Scope Guard and Non-goal Enforcement
- **D-07:** v1.27 phases 97-99 are contract-hardening-only and must not expand runtime capability classes.
- **D-08:** Explicit banned capability classes for this milestone: autocomplete/suggestions, vector or hybrid retrieval, public multi-backend broadening, and new public runtime API categories.
- **D-09:** Scope reopening requires evidence-gated change control: reviewed outside-adopter signal or concrete reproducible production bug, plus explicit requirement and roadmap updates before execution.

### Traceability Freeze Format
- **D-10:** Freeze requirement mapping using a requirement-plus-contract-statement ledger that maps each requirement to canonical statement IDs, owner surfaces, and planned verification anchors.
- **D-11:** Use one stable mapping shape for phase 98 and 99 consumption: `Requirement -> Canonical Statement -> Surfaces -> Verify/Test Anchor`.
- **D-12:** No high-risk surface in the contract map may remain orphaned without at least one requirement mapping row and at least one planned verification consumer.

### Developer Experience and Least-Surprise Calibration
- **D-13:** Favor one-hop discoverability of canonical proof command family (`mix verify.adopter` fast, `--live` explicit prerequisites) and avoid ambiguous "do everything" guidance.
- **D-14:** Preserve Elixir-idiomatic docs shape: concise README entry path, deeper guide authority, explicit operational semantics, and no hidden behavior claims.

### Claude's Discretion
- Exact anchor names and section ordering inside `guides/support-and-compatibility.md`, provided authority and one-hop discoverability remain explicit.
- Exact ledger filename and column ordering for traceability freeze, provided mapping semantics from D-10 through D-12 are preserved.
- Exact docs-contract assertion wording in later phases, provided checks enforce contract anchors and avoid brittle prose snapshotting.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Contract and Scope Sources
- `.planning/ROADMAP.md` — Phase 97 boundary, goals, and success criteria.
- `.planning/REQUIREMENTS.md` — TRUTH-01, TRUTH-02, TRUTH-03, and SCOPE-01 requirements.
- `.planning/PROJECT.md` — v1.27 canonical adopter contract and explicit non-goals.
- `.planning/STATE.md` — active milestone posture and drift concerns.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-STATEMENTS.md` — frozen canonical statement IDs for TRUTH requirements.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-TRACEABILITY.md` — requirement-to-statement mapping ledger for phase 98/99 consumers.
- `.planning/research/v1.27-contract-surface-map.md` — high-risk surface inventory and acceptance rule.
- `.planning/research/v1.27-gate-strategy.md` — verify alias and PR check strategy framing.

### Current Contract Surfaces and Enforcement Anchors
- `README.md` — install entrypoint, contract wayfinding, and proof routing.
- `guides/support-and-compatibility.md` — canonical support and proof authority target.
- `guides/outside-adopter-intake.md` — intake evidence contract and classing.
- `CONTRIBUTING.md` — maintainer/contributor verification routing.
- `guides/golden-path.md` — first-hour install and proof handoff surface.
- `examples/phoenix_meilisearch/README.md` — live proof runbook anchor.
- `.github/workflows/ci.yml` — required PR check and live-proof CI mapping.
- `lib/mix/tasks/verify.adopter.ex` — canonical adopter proof command family behavior.
- `test/scrypath/docs_contract_test.exs` — docs-contract drift enforcement seam.
- `docs/releasing.md` — release-backed artifact truth for maintainers.

### Prior Decision Context Carry-forward
- `.planning/milestones/v1.17-phases/68-example-proof-and-support-contract/68-CONTEXT.md` — support guide authority and bounded docs-contract posture.
- `.planning/milestones/v1.17-phases/69-adopter-verify-spine/69-CONTEXT.md` — `mix verify.adopter` fast/live contract and CI parity.
- `.planning/phases/92-guide-and-schema-declaration/92-CONTEXT.md` — compile-time/doc authority and bounded scope discipline precedent.
- `.planning/phases/94-verification-gate/94-CONTEXT.md` — phase-scoped verify-gate precedent.

### Ecosystem and Architecture Research Inputs
- `prompts/elixir-best-practices-deep-research.md` — Elixir idioms and least-surprise patterns.
- `prompts/ecto-best-practices-deep-research.md` — Ecto-native contract and boundary patterns.
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix docs and integration ergonomics.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — interaction and UX guardrails where applicable.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — architecture and boundary discipline.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS contract/documentation patterns.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — gate and release-truth verification patterns.
- `prompts/elixir-search-lib-deep-research.md` — search-library product and scope lessons.
- `prompts/search-lib-use-cases-deep-research.md` — adopter expectations and DX priorities.
- `prompts/scrypath-brand-book.md` — positioning and voice constraints.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `guides/support-and-compatibility.md`: already structured as a single support/readiness authority and can be used as the canonical wording host.
- `lib/mix/tasks/verify.adopter.ex`: already codifies fast vs live proof boundary and prerequisite honesty.
- `test/scrypath/docs_contract_test.exs`: already contains drift-assertion patterns and can absorb phase 97/98/99 contract anchor checks.
- `.planning/research/v1.27-contract-surface-map.md`: already lists high-risk surfaces and planned verification anchors.

### Established Patterns
- Bounded contract tests over broad prose snapshots are an established repository pattern.
- Semantic maintainer verify aliases (`mix verify.*`) are the normal verification integration seam.
- README stays concise while guides carry deeper authority; this aligns with Elixir OSS docs expectations.

### Integration Points
- Phase 98 surface reconciliation should consume D-01 through D-06 as immutable contract statements.
- Phase 99 drift gates should consume D-10 through D-12 as machine-checkable mapping requirements.
- Any wording update to canonical support-guide anchors must be treated as contract change and reflected in mapping and tests.

### Frozen statement inputs for downstream phases
- `CST-TRUTH-01-INSTALL`
- `CST-TRUTH-02-RELEASE-MAIN`
- `CST-TRUTH-03-SUPPORT-AUTHORITY`

These IDs are frozen for phase 98 and phase 99 implementation work. Downstream artifacts should reference the IDs and mapping ledger rows rather than re-stating policy text.

</code_context>

<specifics>
## Specific Ideas

- Candidate policy phrase to keep consistent across surfaces: "release-backed guidance by default; `main` may contain unreleased changes."
- Keep one-hop path explicit in root docs: install in README, authority in support guide, evidence submission in outside-adopter intake, proof commands in verify.adopter family.
- Use a compact "decision calibration rubric" for phase 98/99 reviews: canonicality, release alignment, least surprise, verifiability, scope safety.

</specifics>

<deferred>
## Deferred Ideas

- Machine-generated contract manifest and snippet generation can be revisited after v1.27 if drift checks prove insufficient.
- Any runtime capability expansion discussions (autocomplete/suggestions, vector/hybrid, backend broadening, new public runtime APIs) are deferred beyond v1.27 and require evidence-gated reopening.
- Full semantic-policy linting beyond targeted anchor checks is deferred to avoid false-positive CI noise.

</deferred>

---

*Phase: 97-canonical-contract-freeze-and-scope-guard*
*Context gathered: 2026-05-27*
