# Phase 100 Research: Install/Release Contract Reconciliation

**Researched:** 2026-05-27  
**Phase:** 100 - Install/Release Contract Reconciliation  
**Confidence:** High (repo-grounded across current docs, trust-gate tests, and phase 97-99 artifacts)

## Planning Answer

Plan Phase 100 as a **targeted trust-surface reconciliation + parity-assertion expansion** focused on `TRUTH-01` and `TRUTH-02` only:

1. Reconcile install/version and release-vs-`main` wording on high-risk adopter surfaces.
2. Keep canonical ownership in `guides/support-and-compatibility.md`, with route-first wording on non-owner surfaces.
3. Extend existing phase-99 trust assertions to enforce semantic parity (not just presence tokens), so drift fails deterministically in the already-required trust lane.

This phase should not reopen runtime/product scope and should not absorb `TRUTH-03` CI matrix parity work (explicitly deferred to Phase 101).

## Scope Guard Carry-Forward

Phase 100 inherits phase-97/98/99 guardrails:

- No runtime feature breadth expansion.
- No backend/API widening.
- No generalized docs-lint engine work.
- No CI compatibility matrix parity closure (`TRUTH-03`, `TEST-01` CI-version parity) in this phase.

Relevant authorities:

- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`
- `.planning/phases/100-install-release-contract-reconciliation/100-CONTEXT.md`
- `.planning/ROADMAP.md` (Phase 100 and 101 separation)

## Explicit Contract Tokens (Install + Release Truth)

The planner should treat these as the **phase-100 token contract**.

| Contract area | Token / phrase | Owner surface | Reference surfaces that must match intent |
|---|---|---|---|
| Install constraint series | `{:scrypath, "~> 0.3"}` (current release-series reality from `mix.exs` `@version "0.3.8"`) | `guides/support-and-compatibility.md` | `README.md`, `guides/outside-adopter-intake.md` |
| Release default posture | "release-backed guidance is the default adopter path" (or equivalent fixed micro-contract) | `guides/support-and-compatibility.md` | `README.md`, `guides/outside-adopter-intake.md`, `CONTRIBUTING.md` |
| `main` truth | "`main` may include unreleased branch-tip behavior" (explicitly non-release) | `guides/support-and-compatibility.md` | `README.md`, `guides/outside-adopter-intake.md`, `CONTRIBUTING.md` |
| Canonical authority routing | "normative install/support policy lives in support guide" | `guides/support-and-compatibility.md` | `README.md`, `guides/outside-adopter-intake.md`, `CONTRIBUTING.md` |
| Package vs repo evidence boundary | "exact Hex version" or "exact git ref/commit" | `guides/outside-adopter-intake.md` | `docs/templates/outside-adopter-evidence.md` |

Current hard drift to close:

- `README.md` uses `{:scrypath, "~> 0.3"}`.
- `guides/outside-adopter-intake.md` currently uses `{:scrypath, "~> 1.0"}`.

## Current Repo Patterns To Reuse

Phase 100 should reuse phase-98/99 enforcement style instead of inventing a new framework.

- Token-based test assertions with helper functions:
  - `test/scrypath/phase98_contract_test.exs`
  - `test/scrypath/phase99_contract_test.exs`
  - `test/scrypath/docs_contract_test.exs`
- Focused verification gate pattern:
  - `lib/mix/tasks/verify.phase98.ex`
  - `lib/mix/tasks/verify.phase99.ex`
- Existing required trust lane already executes `mix verify.phase99`:
  - `.github/workflows/ci.yml` (`phase99-trust`)
  - `CONTRIBUTING.md` required-check table and token list

Planning implication: the lowest-risk path is to **extend phase99 contract assertions** for install/release parity so enforcement stays in the current required lane.

## Likely Files Affected

### Primary reconciliation surfaces

- `guides/support-and-compatibility.md` (canonical owner; currently lacks explicit literal install token policy section)
- `README.md` (entry install snippet and routing micro-contract)
- `guides/outside-adopter-intake.md` (currently contains conflicting `~> 1.0` token)
- `CONTRIBUTING.md` (maintainer-facing release/main wording parity; route-first, not policy-duplicate)
- `docs/templates/outside-adopter-evidence.md` (ensure exact Hex version vs exact git ref/commit capture remains explicit)

### Enforcement surfaces

- `test/scrypath/phase99_contract_test.exs` (best fit for new parity assertions)
- `test/scrypath/docs_contract_test.exs` (existing install-token check seam; keep evergreen and bounded)
- `lib/mix/tasks/verify.phase99.ex` (likely unchanged; only if focused test list must include a new file)
- `test/mix/tasks/verify.phase99_test.exs` (likely unchanged unless gate file list changes)

### Usually unaffected in Phase 100

- `.github/workflows/ci.yml` (trust job already exists)
- `mix.exs` verify alias wiring (already includes `verify.phase99`)

## Implementation Constraints and Edge Cases

- Canonical owner rule is strict: install/version literal policy must live in `guides/support-and-compatibility.md`; other surfaces should route and stay concise.
- Pre-1.0 semantics matter: avoid speculative major-series snippets (`~> 1.0`) unless release reality actually changes.
- Release-truth wording must not imply that branch-tip docs equal published Hex artifact truth.
- Keep package-vs-repo boundary explicit:
  - Hex-package issues must carry exact package version.
  - Repo-clone issues must carry exact git ref/commit.
- Avoid paragraph snapshot testing; use token/ordering/parity checks for low-noise maintenance.
- Do not let Phase 100 absorb Phase 101 CI-version matrix parity (`TRUTH-03`) even though the audit lists it as unsatisfied.

## Sequencing Advice for Planning Tasks

1. **Freeze phase-100 token matrix** from phase-100 context decisions (D-01..D-16), including canonical install token and release/main micro-contract phrases.
2. **Update canonical owner first** in `guides/support-and-compatibility.md` (install token policy + release-backed vs `main` truth wording).
3. **Reconcile non-owner surfaces** (`README.md`, `guides/outside-adopter-intake.md`, `CONTRIBUTING.md`) to route-first, non-conflicting language.
4. **Align intake evidence boundary** between `guides/outside-adopter-intake.md` and `docs/templates/outside-adopter-evidence.md` for exact version/ref requirements.
5. **Extend drift checks** in `test/scrypath/phase99_contract_test.exs` (and minimally in `docs_contract_test.exs` if needed) to enforce install/version parity + release-truth tokens.
6. **Run only existing trust lane commands** for closure evidence (`mix verify.phase99` plus focused tests), avoiding new gate proliferation.

Do not stage test expansions before the canonical owner wording is finalized; this phase is sensitive to churn if assertions land first.

## Validation Architecture

Use a layered validation design that maps cleanly to planning verification tasks.

### Layer 0: Canonical token source

- Source of release truth and version series:
  - `mix.exs` (`@version`)
  - `guides/support-and-compatibility.md` (canonical wording owner)
- Source of phase boundaries:
  - `.planning/phases/100-install-release-contract-reconciliation/100-CONTEXT.md`
  - `.planning/ROADMAP.md` (Phase 100 vs 101 split)

### Layer 1: Surface parity assertions (content-level)

Recommended assertions (token-based):

- Install token parity:
  - `README.md` and `guides/outside-adopter-intake.md` must match canonical series token.
  - Non-owner surfaces must not contain conflicting `{:scrypath, "~> X.Y"}` literals.
- Release-truth parity:
  - Entry/intake/maintainer surfaces include explicit release-backed default + `main` unreleased distinction.
- Authority routing:
  - Non-owner surfaces point to `guides/support-and-compatibility.md` for normative policy.
- Evidence boundary:
  - Intake + template preserve exact Hex-version vs exact git-ref/commit language.

Primary home: `test/scrypath/phase99_contract_test.exs`.

### Layer 2: Gate execution parity

- Keep enforcement in existing required lane:
  - `lib/mix/tasks/verify.phase99.ex`
  - `.github/workflows/ci.yml` (`phase99-trust`)
- If a new focused test file is created, include it in `verify.phase99` focused test list and cover in `test/mix/tasks/verify.phase99_test.exs`.

### Layer 3: Maintainer verification commands

Minimum recommended verification command set:

- `mix test test/scrypath/phase99_contract_test.exs`
- `mix test test/scrypath/docs_contract_test.exs` (if touched)
- `mix verify.phase99`

Pass condition for Phase 100:

- No install-version drift across mapped high-risk surfaces.
- Release-backed vs `main` wording coherent across canonical + intake + entry surfaces.
- Failures identify missing/conflicting token and file clearly.

## Risk Register

| Risk | Severity | Why it matters | Mitigation |
|---|---|---|---|
| Reintroducing version drift on non-owner docs | High | Reopens `TRUTH-01` failure quickly | Add explicit cross-surface parity assertions and conflicting-token refutes in phase99 contract tests |
| Ambiguous release/main language despite token fixes | High | `TRUTH-02` can still fail semantically | Tokenize fixed micro-contract phrases for release-backed default and `main` unreleased status |
| Phase 100 scope bleed into TRUTH-03/CI matrix parity | Medium | Delays closure and creates noisy scope | Keep Phase 100 checks limited to install/release tokens; route CI matrix parity to Phase 101 |
| Over-brittle prose snapshots | Medium | High maintenance churn, low signal | Use token/order checks (`assert_contains_all`, `ordered?`) instead of paragraph snapshots |
| Canonical-owner inversion (policy duplicated in README/CONTRIBUTING) | Medium | Drift probability increases over time | Keep full normative wording in support guide and route from non-owner surfaces |

## Planning Inputs

- [ ] Confirm canonical install token source (`mix.exs` release series) and exact wording authority in `guides/support-and-compatibility.md`.
- [ ] Lock a short release/main micro-contract phrase set for owner + non-owner surfaces.
- [ ] Enumerate exact surface edits (`README.md`, support guide, intake, contributing, evidence template).
- [ ] Define phase99 assertion additions for install/version parity and release-truth coherence.
- [ ] Keep verification in existing required lane (`mix verify.phase99`) with no new gate proliferation.
- [ ] Explicitly mark `TRUTH-03`/CI-version parity as deferred to Phase 101 in plan tasks.
