# Phase 97 Research: Canonical Contract Freeze and Scope Guard

**Researched:** 2026-05-27  
**Phase:** 97 - Canonical Contract Freeze and Scope Guard  
**Confidence:** High (repo-grounded, current branch surfaces inspected)

## Planning Answer

To plan Phase 97 well, treat it as a **contract-hardening control phase** with two outputs:

1. A frozen, reviewable canonical contract statement set for install/version/support/proof truth.
2. An explicit scope guard that blocks runtime breadth expansion during v1.27.

This phase should not widen runtime behavior, backend surface, or public API categories. It should make Phase 98 and 99 mechanically easier and safer.

## Non-Negotiable Scope Boundary

Phase 97 is limited to contract freeze + scope guard:

- Must cover: `TRUTH-01`, `TRUTH-02`, `TRUTH-03`, `SCOPE-01`
- Must not include: new runtime features, new backend promises, public API expansion, or Phoenix/UI breadth work
- Should prefer planning artifacts and narrow contract-anchor edits over broad docs rewrites

If a change proposal adds runtime capability classes (autocomplete/suggestions, vector/hybrid retrieval, backend broadening, new public runtime API categories), reject it as out of scope for this phase.

## Current Canonical Surface Findings (What Matters for Planning)

## Contract Truth Status

- `guides/support-and-compatibility.md` already declares itself as single support/readiness authority and is a good canonical wording host.
- `README.md` routes to support and intake guides, which aligns with one-hop discoverability goals.
- `CONTRIBUTING.md` routes to support/intake and keeps maintainer execution details.
- `lib/mix/tasks/verify.adopter.ex` cleanly encodes fast vs live proof boundary and live prerequisites.

## Drift and Risk Signals

- **Install/version mismatch risk:** `README.md` uses `{:scrypath, "~> 0.3"}`, while `guides/outside-adopter-intake.md` currently says `{:scrypath, "~> 1.0"}`. This is a direct trust-surface inconsistency against `TRUTH-01` / `TRUTH-02`.
- **Contract-check granularity risk:** `test/scrypath/docs_contract_test.exs` is broad and high-churn; Phase 97 should avoid brittle prose snapshots and freeze via stable statement IDs / anchors.
- **Required-check interpretation risk:** CI has many jobs, but release-train required checks are intentionally lean (`main-ci`, `repo-hygiene`, `release-truth`). Phase planning must avoid unintentionally promoting heavy checks.
- **Authority duplication risk:** policy prose can drift if repeated in `README.md`, `CONTRIBUTING.md`, and intake instead of linking back to canonical support-guide anchors.

## Requirement-Focused Planning Implications

| Requirement | Planning implication for Phase 97 | Primary artifacts to freeze |
|---|---|---|
| `TRUTH-01` | Freeze one install/version contract statement set and reference points before surface reconciliation | canonical statement ledger + support-guide anchor map |
| `TRUTH-02` | Freeze exact release-backed vs `main` wording and labels used by all entry surfaces | support-guide canonical phrasing + mapping row |
| `TRUTH-03` | Freeze canonical support authority and one-hop routing contract | authority statement + routing rules for README/CONTRIBUTING/intake |
| `SCOPE-01` | Freeze explicit non-goal classes and evidence-gated reopening policy | scope guard section + change-control rule |

## Recommended Plan Slices

Use small, ordered slices so each artifact can be reviewed independently.

### Slice 1: Canonical Statement Freeze (authoritative wording)

**Goal:** Define stable canonical statement IDs and text for install/version/support/proof policy.  
**Likely files touched:**
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTEXT.md`
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-RESEARCH.md` (carry-forward references)
- `.planning/PROJECT.md` (if canonical contract wording or non-goal policy needs explicit alignment)

### Slice 2: Requirement-to-Statement Traceability Freeze

**Goal:** Lock mapping shape `Requirement -> Canonical Statement -> Surfaces -> Verify/Test Anchor`.  
**Likely files touched:**
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-TRACEABILITY.md` (new; recommended)
- `.planning/REQUIREMENTS.md` (only if row notes need normalization)
- `.planning/ROADMAP.md` (only if success criteria language needs precision)

### Slice 3: Scope Guard + Reopen Policy

**Goal:** Make runtime non-goals explicit and enforce evidence-gated reopening policy.  
**Likely files touched:**
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTEXT.md`

### Slice 4: Minimal Contract-Seam Alignment Fixes (only if required for freeze coherence)

**Goal:** Resolve immediate contradictions that break the freeze (for example install/version mismatch) without broad reconciliation.  
**Likely files touched:**
- `README.md`
- `guides/support-and-compatibility.md`
- `guides/outside-adopter-intake.md`
- `CONTRIBUTING.md`

Keep this slice narrow: only edits required to make freeze statements coherent now. Defer broad wording harmonization to Phase 98.

### Slice 5: Phase 97 Verification Spine

**Goal:** Create a focused gate that proves the freeze exists and scope guard is present.  
**Likely files touched:**
- `lib/mix/tasks/verify.phase97.ex` (new)
- `mix.exs` (register alias)
- `test/scrypath/docs_contract_test.exs` (or a new focused phase97 docs/contract test file)
- `CONTRIBUTING.md` (gate discoverability)

## Dependency Ordering (Do This In Order)

1. Freeze canonical statements first (no enforcement before source statements exist).
2. Freeze traceability map second (ties requirements to statements and target surfaces).
3. Apply scope guard and reopen policy third (locks execution boundary before edits fan out).
4. Perform only contradiction-fix docs edits needed for freeze coherence.
5. Add Phase 97 verify gate last to lock the frozen contract and guardrails.

Do not invert this order; adding assertions before statement IDs are stable will cause churn and false failures.

## Verification Strategy (Phase 97)

## Automated Checks

- Add `mix verify.phase97` as the focused local/CI-ready gate for this phase.
- Keep checks text-anchor based (statement IDs / stable section anchors), not brittle full-paragraph snapshots.
- Ensure at least one assertion checks each requirement ID (`TRUTH-01`, `TRUTH-02`, `TRUTH-03`, `SCOPE-01`) through the mapping ledger.

## Manual Review Checklist

- Confirm one canonical install/version contract statement and no contradictory version snippets remain in freeze-critical surfaces.
- Confirm release-backed vs `main` boundary language is explicit.
- Confirm support authority points to support guide and other surfaces reference it.
- Confirm banned capability classes and reopen policy are explicit.

## Exit Evidence for Phase Completion

- Frozen statement ledger exists and is review-approved.
- Requirement-to-statement traceability row(s) exist for all four phase requirements.
- Scope guard is explicit in planning truth surfaces.
- `mix verify.phase97` passes (or equivalent focused verification if gate addition is intentionally deferred with rationale).

## Validation Architecture

This architecture is designed so downstream Nyquist strategy can consume Phase 97 outputs without reinterpretation.

### Layer 0: Source-of-Truth Artifacts

- Canonical contract statements (with stable IDs)
- Scope guard policy and banned capability classes
- Requirement traceability mapping rows

### Layer 1: Static Contract Assertions

- Assertions that canonical statement IDs are present where expected
- Assertions that `TRUTH-01/02/03` and `SCOPE-01` have non-empty mapping rows
- Assertions that freeze-critical surfaces do not contain contradictory install/version truth

### Layer 2: Phase Gate Execution

- `mix verify.phase97` runs focused tests plus docs build checks as needed
- Gate remains narrow to avoid release-train noise

### Layer 3: Milestone Continuity Hooks

- Phase 98 consumes frozen statement IDs for surface reconciliation
- Phase 99 consumes mapping ledger + anchors for drift-gate automation (`TEST-*`, `GATE-*`)

### Nyquist-Oriented Validation Units

- **Unit A (Truth statements):** canonical statement IDs and wording hash/anchor checks
- **Unit B (Traceability):** each requirement has mapped statement, surfaces, verification anchor
- **Unit C (Scope guard):** banned capability classes and reopen criteria present and discoverable
- **Unit D (Execution spine):** verify alias exists, is documented, and runs focused assertions

## Architecture Patterns

### Pattern: Canonical Guide Authority + Reference-Only Entry Surfaces

Keep normative prose in `guides/support-and-compatibility.md`; keep `README.md`, `CONTRIBUTING.md`, and intake as routing/reference surfaces.

### Pattern: Requirement-to-Statement Ledger

Use a compact, stable mapping table rather than ad-hoc prose for traceability.

### Pattern: Narrow Mix Verify Gate Per Phase

Follow existing `verify.phaseNN` task shape (`run focused tests`, `ensure no args`, `docs --warnings-as-errors` when needed).

## Standard Stack (for this phase)

- Elixir `Mix.Task` for phase gate (`verify.phase97`)
- ExUnit assertion seams (prefer focused tests over broad snapshot checks)
- Existing docs-contract infrastructure as extension point (not replacement)
- Planning artifacts under `.planning/` as governance truth

## Don't Hand-Roll

- Do not create custom parser infrastructure for markdown policy checking; use stable string/anchor assertions.
- Do not invent a new verification framework parallel to `mix verify.phaseNN`.
- Do not introduce runtime feature scaffolding while "touching docs for coherence."

## Common Pitfalls

- Turning Phase 97 into Phase 98 by attempting broad surface rewrites too early.
- Freezing wording without stable statement IDs, causing later drift and ambiguous reviews.
- Using full paragraph snapshots in tests that fail on harmless editorial edits.
- Quietly changing required CI check posture while introducing phase gates.
- Allowing install/version truth to remain split between release-backed and speculative snippets.

## Code/Artifact Examples (Planning-Level)

### Example statement ID shape

- `CST-TRUTH-01-INSTALL`
- `CST-TRUTH-02-RELEASE-MAIN`
- `CST-TRUTH-03-SUPPORT-AUTHORITY`
- `CST-SCOPE-01-NON-GOALS`

### Example traceability row shape

`TRUTH-02 -> CST-TRUTH-02-RELEASE-MAIN -> README.md, guides/support-and-compatibility.md, guides/outside-adopter-intake.md -> test anchor in verify.phase97 / docs contract`

### Example scope-guard rejection rule

If a proposed change adds autocomplete/suggestions, vector/hybrid retrieval, public backend broadening, or new public runtime API categories, it is auto-rejected in Phase 97 unless milestone requirements and roadmap are explicitly reopened with evidence.

## Planning Recommendation (Final)

Plan Phase 97 as a **contract governance slice**, not a product slice:

- Freeze canonical statement IDs and requirement mapping first.
- Fix only contradictions needed to make the freeze coherent now.
- Lock scope guard policy with explicit reopen criteria.
- Add a narrow verification seam so Phase 98/99 can build on stable contract anchors.

This keeps v1.27 aligned with Elixir OSS docs ergonomics (concise README entry, guide authority, explicit operational honesty) while preventing scope creep.
