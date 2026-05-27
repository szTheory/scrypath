# Phase 100: Install/Release Contract Reconciliation - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 100 restores install/version and release-truth coherence across high-risk adopter surfaces (`README.md`, support authority, intake, and maintainer routing surfaces), then locks parity with targeted drift assertions.

This phase is trust-surface hardening only. It does not add runtime features, backend breadth, or new public runtime API classes.

</domain>

<decisions>
## Implementation Decisions

### Install/version contract token policy
- **D-01:** `guides/support-and-compatibility.md` is the canonical owner of the literal Hex install/version token policy.
- **D-02:** The canonical install token must reflect current release reality (currently `{:scrypath, "~> 0.3"}`), not speculative major-version wording.
- **D-03:** Non-owner surfaces (`README.md`, `guides/outside-adopter-intake.md`, `CONTRIBUTING.md`) must route to the canonical owner and must not introduce conflicting install/version literals.
- **D-04:** Intake evidence language must explicitly require either the exact Hex package version or exact git ref/commit, preserving package-vs-repo truth boundaries.

### Release-backed versus `main` truth wording
- **D-05:** Adopt a fixed micro-contract wording pattern on entry surfaces: release-backed guidance is the default adopter path; `main` may include unreleased branch-tip behavior.
- **D-06:** Keep full normative policy text in the support guide only; other surfaces use concise route-first wording.
- **D-07:** Keep repo-clone live proof (`mix verify.adopter --live`) explicit and separate from Hex-package install guidance.

### Surface ownership and routing boundaries
- **D-08:** `guides/support-and-compatibility.md` remains the single normative authority for install/support/proof policy.
- **D-09:** `README.md` remains the first-hop onboarding surface: concise install + authority routing, not full policy duplication.
- **D-10:** `guides/outside-adopter-intake.md` owns evidence admissibility and triage workflow, not independent support/install policy restatement.
- **D-11:** `CONTRIBUTING.md` owns maintainer CI/verification workflow; it must not evolve into a second adopter contract authority.

### Drift assertion strategy (Phase 100 scope)
- **D-12:** Extend trust-contract coverage from token presence toward semantic parity for install/version and release-truth claims.
- **D-13:** Use centralized canonical token/value expectations in tests and assert per-surface parity with actionable failure messages.
- **D-14:** Add owner/reference guard assertions so conflicting install/version claims on non-owner surfaces fail deterministically.
- **D-15:** Keep checks deterministic and low-noise (no network/service dependence) and aligned with `mix verify.phase99` trust-lane posture.
- **D-16:** Do not pull TRUTH-03 compatibility-matrix parity into this phase; CI lane/runtime-version parity remains Phase 101 scope.

### Claude's Discretion
- Exact micro-contract sentence wording and anchor names, as long as D-05 through D-07 semantics remain intact.
- Exact helper naming and assertion organization in contract tests, as long as D-12 through D-15 are enforced.
- Exact placement of short route lines in non-owner docs, as long as authority boundaries in D-08 through D-11 remain intact.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone authority and phase scope
- `.planning/ROADMAP.md` — Phase 100 goal, requirements mapping, and success criteria.
- `.planning/REQUIREMENTS.md` — `TRUTH-01` and `TRUTH-02` requirement definitions and traceability.
- `.planning/v1.27-v1.27-MILESTONE-AUDIT.md` — blocker evidence proving current install/release-truth divergence.
- `.planning/PROJECT.md` — v1.27 canonical adopter contract and non-goal boundaries.
- `.planning/STATE.md` — active trust-hardening posture and blocker context.

### Locked prior decisions and contract maps
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTEXT.md` — canonical authority and scope-guard carry-forward.
- `.planning/phases/98-surface-reconciliation-and-adopter-flow-clarity/98-CONTEXT.md` — layered authority and strict-core drift posture.
- `.planning/phases/99-drift-gates-and-ci-enforcement/99-CONTEXT.md` — phase-99 gate philosophy and trust-lane contracts.
- `.planning/research/v1.27-contract-surface-map.md` — high-risk surface inventory and verification anchor map.
- `.planning/research/v1.27-gate-strategy.md` — required/advisory gate strategy and trust-lane intent.

### Contract surfaces to reconcile
- `README.md` — install snippet, entry-wayfinding, and release/main truth routing.
- `guides/support-and-compatibility.md` — canonical support/install/proof authority.
- `guides/outside-adopter-intake.md` — intake evidence and classification flow.
- `CONTRIBUTING.md` — maintainer verification and CI check mapping.
- `docs/templates/outside-adopter-evidence.md` — required evidence fields and artifact-truth expectations.

### Enforcement seams and wiring
- `test/scrypath/phase99_contract_test.exs` — milestone trust-contract assertions to extend for parity.
- `test/scrypath/docs_contract_test.exs` — broader docs-contract guardrails and existing install token invariant.
- `lib/mix/tasks/verify.phase99.ex` — deterministic trust gate execution path.
- `lib/mix/tasks/verify.adopter.ex` — canonical fast/live proof-boundary command family.
- `.github/workflows/ci.yml` — required-check and trust-lane wiring context.
- `mix.exs` — release truth (`@version`, elixir floor) and verify alias wiring context.

### Research and ecosystem guidance inputs
- `prompts/elixir-best-practices-deep-research.md` — idiomatic Elixir API and docs explicitness guidance.
- `prompts/ecto-best-practices-deep-research.md` — boundary ownership and context-first conventions.
- `prompts/phoenix-best-practices-deep-research.md` — route-first docs and least-surprise integration guidance.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — UX clarity principles for entry surfaces where applicable.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — system boundary and contract ownership discipline.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS documentation and API trust patterns.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — deterministic gate and release-train CI posture.
- `prompts/elixir-search-lib-deep-research.md` — search-library contract and adoption lessons.
- `prompts/search-lib-use-cases-deep-research.md` — adopter expectation and DX tradeoff guidance.
- `prompts/scrypath-brand-book.md` — voice, positioning, and trust-surface consistency guardrails.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/scrypath/phase99_contract_test.exs`: focused trust-contract suite already targeting high-risk surfaces and required-check tokens.
- `test/scrypath/docs_contract_test.exs`: existing install token invariant (`~> 0.3`) and broad docs parity helper patterns.
- `lib/mix/tasks/verify.phase99.ex`: deterministic focused-gate pattern (`ensure_no_args!`, scoped tests, docs build).
- `lib/mix/tasks/verify.adopter.ex`: explicit fast/live proof boundary language already aligned with trust posture.

### Established Patterns
- Token/anchor assertions with actionable failure messages over broad prose snapshots.
- One canonical authority surface with thin root routing surfaces.
- Service-free required trust gates; heavier proof paths stay explicit and prerequisite-bound.

### Integration Points
- Reconcile wording across `README.md`, `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`, and `CONTRIBUTING.md`.
- Extend contract assertions in `test/scrypath/phase99_contract_test.exs` (and narrowly in docs contract tests where appropriate) to enforce install/release parity.
- Keep `mix verify.phase99` as the required deterministic enforcement entrypoint.

</code_context>

<specifics>
## Specific Ideas

- Canonical micro-contract template to reuse across non-owner surfaces:
  - "Adopter guidance is release-backed by default."
  - "`main` may contain unreleased changes and is branch-tip guidance."
  - "Normative support/install policy lives in `guides/support-and-compatibility.md`."
- Preserve explicit package-versus-repo boundary language in intake and evidence template surfaces.
- Favor semantic parity assertions (extracted values/markers) over fragile paragraph snapshots.

</specifics>

<deferred>
## Deferred Ideas

- TRUTH-03/CI-lane compatibility parity work is Phase 101 scope.
- Generalized manifest/snippet generation for contract tokens is deferred beyond v1.27 trust-hardening needs.
- Any runtime capability expansion remains deferred under active scope guard policy.

</deferred>

---

*Phase: 100-install-release-contract-reconciliation*
*Context gathered: 2026-05-27*
