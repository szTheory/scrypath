# Phase 101 Research: CI Compatibility Truth and Drift Guard Completion

**Researched:** 2026-05-27  
**Phase:** 101 - CI Compatibility Truth and Drift Guard Completion  
**Confidence:** High (repo-grounded across support authority, CI workflow lanes, trust-gate tests, and phase-101 context decisions)

## Planning Answer

Plan Phase 101 as a **targeted compatibility-truth closure + semantic parity enforcement** focused on `TRUTH-03` and `TEST-01` only:

1. Reconcile canonical compatibility claims in `guides/support-and-compatibility.md` to an explicit range-plus-evidence model.
2. Align executable CI lane evidence to every compatibility tuple claimed in that canonical surface (especially floor/head tuples), without expanding required-check contract names.
3. Extend phase-99 trust assertions from route/presence checks to normalized compatibility parity checks across support authority, CI lanes, and `mix.exs` floor policy.

This phase should not reopen install/release token reconciliation (`TRUTH-01`/`TRUTH-02`) and should not broaden runtime scope.

## Scope Guard Carry-Forward

Phase 101 inherits the active v1.27 scope guard:

- No runtime feature breadth expansion.
- No backend breadth expansion.
- No new public runtime API categories.
- No generalized manifest/codegen engine work in this phase.

Relevant authorities:

- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`
- `.planning/phases/101-ci-compatibility-truth-and-drift-guard-completion/101-CONTEXT.md`
- `.planning/ROADMAP.md` (phase 101 `TRUTH-03`/`TEST-01` closure)

## Explicit Compatibility Contract (TRUTH-03 + TEST-01)

The planner should treat these as the **phase-101 compatibility truth contract**.

| Contract area | Token / fact | Owner surface | Enforcement surface |
|---|---|---|---|
| Declared floor policy | Elixir `~> 1.17` | `mix.exs` | `test/scrypath/phase99_contract_test.exs` |
| Canonical compatibility authority | Support lifecycle + compatibility boundaries in one place | `guides/support-and-compatibility.md` | `phase99_contract_test.exs` route/parity assertions |
| CI-verified runtime tuples | Explicit Elixir/OTP tuples under "GitHub Actions exercises" | `guides/support-and-compatibility.md` | `.github/workflows/ci.yml` + semantic tuple parity assertions |
| Required-check stability | Required checks stay `main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust` | `CONTRIBUTING.md` + `.github/workflows/ci.yml` | `test/mix/tasks/workflow_wiring_test.exs` |
| Ownership boundary | Non-owner surfaces route to support authority; no competing matrix values | `README.md`, `CONTRIBUTING.md`, intake guide | Existing docs/phase99 contract assertions |

Current blocker to close (audit-grounded):

- `guides/support-and-compatibility.md` claims CI exercises Elixir `1.17.3` + OTP `26.2.5`, but `.github/workflows/ci.yml` currently has no such lane.

## Current Repo Patterns To Reuse

Phase 101 should reuse existing trust-hardening seams rather than inventing a new enforcement subsystem:

- Semantic/token assertions in `test/scrypath/phase99_contract_test.exs`.
- CI/check-name wiring assertions in `test/mix/tasks/workflow_wiring_test.exs`.
- Existing deterministic trust entrypoint `mix verify.phase99`:
  - `lib/mix/tasks/verify.phase99.ex`
  - `.github/workflows/ci.yml` (`phase99-trust`)

Planning implication: the lowest-risk path is to keep compatibility parity enforcement under the existing `verify.phase99` trust lane while adding CI evidence lanes in workflow config without changing required-check names.

## Likely Files Affected

### Primary truth surfaces

- `guides/support-and-compatibility.md` (canonical compatibility range + explicit CI-evidence tuples)
- `.github/workflows/ci.yml` (compatibility evidence lane topology and runtime tuple alignment)

### Enforcement surfaces

- `test/scrypath/phase99_contract_test.exs` (normalized support-vs-CI-vs-floor parity assertions)
- `test/mix/tasks/workflow_wiring_test.exs` (required-check stability and compatibility lane token expectations)
- `lib/mix/tasks/verify.phase99.ex` (likely message/help text updates only if phase description needs to mention compatibility truth closure)
- `test/mix/tasks/verify.phase99_test.exs` (only if verify task messaging or focused test list changes)

### Possible doc-routing touchpoints (only if needed for parity clarity)

- `CONTRIBUTING.md` (if compatibility lane naming/intent needs explicit maintainer routing)
- `README.md` (route-only reference; no compatibility matrix duplication)

## Implementation Constraints and Edge Cases

- Keep required merge-check tokens stable; do not create branch-protection churn by renaming required jobs.
- Prefer a dedicated compatibility-evidence lane (or equivalent isolated lane scope) so tuple parsing/assertions are deterministic and do not accidentally read unrelated jobs.
- Keep compatibility semantics explicit:
  - declared support boundary (policy)
  - currently CI-verified tuples (evidence)
  - avoid implying "declared range" equals "full Cartesian CI verification".
- Keep semantic checks in `phase99_contract_test.exs`; keep wiring/check-name tests in `workflow_wiring_test.exs` per ownership boundary in phase-101 context.
- Avoid brittle paragraph snapshots; parse and compare normalized tuple facts with clear expected-vs-actual failure output.
- Preserve release-backed versus unreleased-`main` truth wording already locked in phase 100; phase 101 should not reopen those tokens.

## Sequencing Advice for Planning Tasks

1. **Freeze compatibility fact model** from phase-101 context decisions: declared support boundary, CI-verified tuples, and owner/non-owner boundaries.
2. **Select CI lane topology** that proves floor/head tuples while preserving required-check stability (recommended: add compatibility truth evidence lane without altering required-check contract set).
3. **Update canonical support authority** (`guides/support-and-compatibility.md`) to reflect the final range-plus-evidence wording and exact tuple list.
4. **Update CI workflow lanes** (`.github/workflows/ci.yml`) so executable tuples match the canonical claims exactly.
5. **Add normalized parity assertions** in `test/scrypath/phase99_contract_test.exs` to compare support-guide tuples, CI tuples, and `mix.exs` floor semantics.
6. **Adjust wiring assertions/docs** only as needed (`workflow_wiring_test.exs`, optionally `CONTRIBUTING.md`) to keep required-vs-advisory contract explicit.
7. **Close with existing trust commands** (`mix test` focused trust suites + `mix verify.phase99`) and capture evidence in phase verification artifacts.

Do not add broad CI matrix expansion beyond the tuples needed to satisfy canonical compatibility truth for this phase.

## Validation Architecture

Use a layered validation architecture so Nyquist follow-on planning can map checks cleanly.

### Layer 0: Canonical compatibility facts

- `mix.exs` declares floor policy (`elixir: "~> 1.17"`).
- `guides/support-and-compatibility.md` declares support boundary and explicit CI-verified tuples.
- `.github/workflows/ci.yml` defines executable runtime lanes.

### Layer 1: Fact extraction and normalization

Normalize compatibility facts into comparable tuples:

- `support_claimed_tuples = [{elixir, otp}, ...]` extracted from support guide CI-evidence section.
- `ci_executed_tuples = [{elixir, otp}, ...]` extracted from CI compatibility lane configuration.
- `declared_floor = "~> 1.17"` extracted from `mix.exs`.

Normalization should compare semantically (version tuple identity and floor/head coverage), not prose shape.

### Layer 2: Parity assertions (TEST-01 closure)

Primary assertions:

- Every tuple claimed in support authority exists in CI executed tuples.
- CI tuple set does not silently diverge from canonical support claims.
- At least one CI tuple proves floor policy intent (1.17.x line) and one proves current stable head tuple.
- Support authority remains canonical (non-owner surfaces route rather than duplicate competing matrix values).

Primary assertion home: `test/scrypath/phase99_contract_test.exs`.

### Layer 3: Wiring and gate stability

- Required check names remain stable (`main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust`).
- Compatibility truth evidence lane (if added) does not alter required-check contract unexpectedly.
- Wiring assertions remain in `test/mix/tasks/workflow_wiring_test.exs`.

### Layer 4: Execution and maintainers' proof path

Recommended command set:

- `mix test test/scrypath/phase99_contract_test.exs`
- `mix test test/mix/tasks/workflow_wiring_test.exs`
- `mix verify.phase99`

Phase pass condition:

- Canonical support compatibility claims and CI runtime evidence are semantically aligned.
- Drift assertions fail with actionable mismatch diagnostics.
- Required-check surface remains lean and unchanged.

## Risk Register

| Risk | Severity | Why it matters | Mitigation |
|---|---|---|---|
| Required-check contract drift while adding compatibility lanes | High | Branch protection and contributor expectations can silently break | Keep required-check token set unchanged; add explicit wiring assertions for stability |
| Support guide and CI tuples diverge again after closure | High | Reopens `TRUTH-03` and weakens trust posture | Add normalized tuple parity assertions in `phase99_contract_test.exs` with expected-vs-actual output |
| Over-brittle tuple parsing in tests | Medium | Creates false failures and high maintenance churn | Use stable tuple extraction format and semantic comparison helpers instead of paragraph snapshots |
| Scope bleed into broader CI matrix or runtime work | Medium | Delays closure and violates v1.27 guardrails | Keep task scope pinned to floor/head evidence and `TRUTH-03`/`TEST-01` only |
| Authority inversion (matrix duplicated on non-owner docs) | Medium | Increases long-term drift risk | Keep full compatibility semantics in support guide; route-only wording elsewhere |
| Docs-only reconciliation without executable CI evidence | High | Leaves policy ahead of proof and fails audit intent | Require CI lane evidence parity as part of phase completion, not optional follow-up |

## Planning Inputs

- [ ] Lock canonical compatibility tuple policy in `guides/support-and-compatibility.md` (range + explicit CI evidence).
- [ ] Decide CI topology that proves floor/head tuples without expanding required-check contract surface.
- [ ] Enumerate exact workflow changes in `.github/workflows/ci.yml` for tuple parity.
- [ ] Define normalized parity helpers/assertions in `test/scrypath/phase99_contract_test.exs`.
- [ ] Define wiring-stability assertions in `test/mix/tasks/workflow_wiring_test.exs` for required-check invariants.
- [ ] Keep plan bounded to `TRUTH-03` and `TEST-01` with explicit v1.27 scope-guard carry-forward.
