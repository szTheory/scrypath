# Planning retrospective

Living notes across planning milestones. Append new sections at the top.

## Milestone: v1.6 — Adoption-grade integration and trust

**Shipped (planning):** 2026-04-19  
**Phases:** 7 (29–35) | **Plans:** 7 | **Hex:** `scrypath 0.3.3` (unchanged line; docs + proof + trust)

### What was built

Golden-path guide and README wayfinding; Oban-shaped example proof; CONTRIBUTING ↔ CI contract tests; **`STATE.md`** triage; three gap-closure phases (**33–35**) locking smoke cwd, README ↔ golden path ↔ **`phoenix-example-integration`**, and sync-guide lifecycle vocabulary.

### What worked

**`docs_contract_test.exs`** as a mechanical seam between maintainer docs and repo layout prevented regression on the exact integration-footgun paths the milestone audit called out.

### What was inefficient

`gsd-sdk query milestone.complete` failed in this environment again; archival and roadmap collapse were performed manually with the same checklist as **v1.5**.

### Key lessons

Ship **`audit-open` acknowledgments** into **`STATE.md`** at close when tooling counts disagree with verification truth, so the ledger stays honest without blocking archive.

---

## Cross-Milestone Trends

| Milestone | Phases | Dominant theme |
|-----------|--------|------------------|
| v1.6 | 29–35 | Adoption golden path + doc contracts + verify story for contributors |
| v1.5 | 27–28 | Index contract drift reporting + operator Mix/docs/verify gate |
| v1.4 | 24–26 | Hex package parity + narrow hot settings + operator rollups |
| v1.3 | 18–23 | Meilisearch-native depth + release parity + operator honesty |

---

## Milestone: v1.5 — Operator drift and schema-diff tooling

**Shipped (planning):** 2026-04-18  
**Phases:** 2 | **Plans:** 5 | **Hex:** `scrypath 0.3.3` (in-repo at archive)

### What was built

Structured declared-vs-live index contract drift on **`Scrypath.*`** with optional reconcile attachment; **`mix scrypath.index.contract_drift`**; operator guides and **`mix verify.phase28`** locking ExDoc + focused tests.

### What worked

Reusing **`OperatorTask`** / **`Config.resolve!`** patterns from settings diff kept CLI behavior predictable; a dedicated verify task made the milestone boundary auditable without widening integration scope.

### What was inefficient

`gsd-sdk query milestone.complete` was unavailable in this environment, so archival steps were performed manually once — acceptable for a small milestone, but easy to drift from the canonical GSD automation path.

### Key lessons

Treat **`audit-open` noise** (passed UAT still flagged; missing quick-task stubs) as **defer-at-close** with a dated **`STATE.md`** table so milestone close does not block on historical tooling artifacts.

---

## Milestone: v1.4 — Public package parity & operator depth

**Shipped (planning):** 2026-04-17  
**Phases:** 3 | **Plans:** 8 | **Hex:** `scrypath 0.3.1`

### What was built

Release automation tightened for pre-1.0 semver; post-publish `release_parity` wired on both publish workflows; maintainer docs + README pins; bounded `hot_apply/3` for three live settings keys with Mix integration; failure rollups by `reason_class` with dedicated verify task.

### What worked

Reusing the existing Release Please + Actions path kept the ship mechanical; contract tests on workflow YAML prevented ordering regressions.

### What was inefficient

Milestone bookkeeping briefly lagged the branch (Phases 25–26 landed before Phase 24 SHIP); resolved by explicit SHIP gate + checklist before archive.

### Key lessons

Treat “planning milestone complete” and “Hex artifact live” as separate gates in STATE until both are true, then run **`/gsd-complete-milestone`** immediately after to avoid drift.

---

## Milestone: v1.3 — Search Power That Phoenix Teams Reach For

**Shipped (planning):** 2026-04-17  
**Phases:** 6 | **Plans:** 18 (roadmap accounting)

### What was built (planning + engineering)

Release-parity Mix gates and CI hygiene; relevance tuning and settings drift tools; faceted search and LiveView guide; federated `search_many/2`; operator `FailedWork` depth + drift recovery guide; v1.2 Nyquist validation artifacts.

### What worked

Dedicated terminal phase for VALIDATION closure (Phase 23) kept evidence review separate from feature diffs.

### What was inefficient

`REQUIREMENTS.md` checklist rows lagged traceability until milestone close; resolved during archive sync.

### Key lessons

Keep requirement bullets, traceability table, and roadmap phase status in lockstep to avoid “Executing” table rows after work landed.
