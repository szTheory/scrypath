# Planning retrospective

Living notes across planning milestones. Append new sections at the top.

## Cross-Milestone Trends

| Milestone | Phases | Dominant theme |
|-----------|--------|------------------|
| v1.4 | 24–26 | Hex package parity + narrow hot settings + operator rollups |
| v1.3 | 18–23 | Meilisearch-native depth + release parity + operator honesty |

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
