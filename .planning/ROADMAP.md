# Roadmap: Scrypath

## Milestones

- [x] **v1.26 shipped + archived in-repo** (**2026-05-26**) — *Facet Value Vocabulary Search* — phases **95–96** — [archive](milestones/v1.26-ROADMAP.md)
- [x] **v1.25 shipped + archived in-repo** (**2026-05-26**) — *Tenant-Safe Search Access* — phases **92–94** — [archive](milestones/v1.25-ROADMAP.md)

*(For older milestones v1.0 through v1.24, see the `.planning/milestones/` directory.)*

## Current Milestone

**v1.27 — Adopter Contract Hardening** (opened 2026-05-27)

**Goal:** make install/support/proof surfaces coherent and enforceable without widening runtime feature scope.

**Requirements mapped:** 14/14 (0 unmapped)

## Phases

### Phase 97 — Canonical Contract Freeze and Scope Guard

**Goal:** lock authoritative contract wording and explicit non-goals before broad docs reconciliation.

[PHASE97-SCOPE-GUARD] Phase 97/98/99 reject runtime breadth expansion unless reopen policy conditions are met.

**Requirements:**

- TRUTH-01
- TRUTH-02
- TRUTH-03
- SCOPE-01

**Success criteria:**

1. Canonical install/version/support/proof contract statements are written and approved in planning artifacts.
2. Non-goals are explicit and block runtime feature-breadth drift.
3. Requirement-to-phase mapping is stable and reviewable before surface edits begin.

### Phase 98 — Surface Reconciliation and Adopter Flow Clarity

**Goal:** align all high-risk adopter-facing surfaces to canonical contract wording and proof boundaries.

**Requirements:**

- PROOF-01
- PROOF-02
- PROOF-03
- SUP-01
- SUP-02

**Success criteria:**

1. Primary contract surfaces reconcile to one consistent install/support/proof story.
2. Fast vs live proof boundaries are explicit and non-contradictory.
3. Intake and escalation wording is evidence-oriented and actionable for maintainers.

### Phase 99 — Drift Gates and CI Enforcement

**Goal:** convert the reconciled contract into durable verification gates and required PR CI expectations.

**Requirements:**

- TEST-01
- TEST-02
- TEST-03
- GATE-01
- GATE-02

**Success criteria:**

1. Docs-contract and proof-boundary checks enforce canonical anchors.
2. Milestone verify gates are defined and mapped to expected CI behavior.
3. Required PR checks for trust-hardening are documented and bounded to avoid release-train noise.

### Phase 100 — Install/Release Contract Reconciliation

**Goal:** restore install-version and release-truth coherence across canonical and intake surfaces, then lock parity with targeted contract assertions.

**Requirements:**

- TRUTH-01
- TRUTH-02

**Gap Closure:** closes milestone-audit requirement, integration, and adopter-truth flow gaps tied to install/release contract divergence.

**Success criteria:**

1. Install/version guidance is consistent across mapped high-risk adopter surfaces.
2. Release-backed versus `main` branch truth wording is coherent across canonical and intake entry points.
3. Drift checks assert install/version parity for these contract tokens.

### Phase 101 — CI Compatibility Truth and Drift Guard Completion

**Goal:** align support compatibility claims with actual CI lanes and complete CI-version parity assertions in drift guards.

**Requirements:**

- TRUTH-03
- TEST-01

**Gap Closure:** closes milestone-audit requirement, integration, and support-proof flow gaps tied to CI/runtime claim drift.

**Success criteria:**

1. Support authority compatibility claims match the CI matrix (or the matrix is updated to match policy).
2. Contract tests assert CI-version parity across mapped trust surfaces.
3. Verification evidence proves support/proof surfaces reference the same canonical CI truth.

## Gate Strategy (v1.27)

- **Gate aliases:** `mix verify.phase97`, `mix verify.phase98`, `mix verify.phase99`
- **Canonical adopter proof spine:** `mix verify.adopter` (fast required; live explicit/prerequisite-bound)
- **Required PR checks during feature-lane execution:** `main-ci`, `repo-hygiene`, `release-truth`, plus milestone gate check coverage for phases 97-99
- **Heavy live/advisory checks:** keep non-blocking unless explicitly promoted by maintainers

## Requirement Coverage

| Requirement | Phase | Notes |
|-------------|-------|-------|
| TRUTH-01 | 100 | Canonical install/version contract reconciliation |
| TRUTH-02 | 100 | Release-backed vs `main` truth reconciliation |
| TRUTH-03 | 101 | Support/compatibility authority parity with CI lanes |
| SCOPE-01 | 97 | No runtime breadth expansion |
| PROOF-01 | 98 | Canonical proof command discoverability |
| PROOF-02 | 98 | Fast/live proof boundary clarity |
| PROOF-03 | 98 | Example-app proof alignment |
| SUP-01 | 98 | Intake evidence contract |
| SUP-02 | 98 | Escalation contract |
| TEST-01 | 101 | Docs-contract drift anchors including CI/version parity |
| TEST-02 | 99 | Proof-boundary contract assertions |
| TEST-03 | 99 | CI/verify alias consistency assertions |
| GATE-01 | 99 | Phase verify gate strategy |
| GATE-02 | 99 | Required PR check strategy |

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 97 | 3/3 | Complete    | 2026-05-27 |
| 98 | 4/4 | Complete    | 2026-05-27 |
| 99 | 3/3 | Complete    | 2026-05-27 |
| 100 | 3/3 | Complete    | 2026-05-27 |
| 101 | 3/3 | Complete    | 2026-05-27 |
