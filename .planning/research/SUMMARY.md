# Project Research Summary

**Project:** Scrypath
**Domain:** Phoenix LiveView operator admin over Scrypath (Meilisearch-first)
**Researched:** 2026-04-20
**Confidence:** HIGH

## Executive Summary

**v1.10** adds an **optional OPSUI**—a Phoenix LiveView application **outside** the core Hex package—that prioritizes **operator jobs-to-be-done** and **least surprise** for experienced Phoenix teams. The recommended approach is a **thin LiveView client** over existing **`Scrypath.*`** visibility and **`search_many/2`** federation shapes, with **explicit security boundaries** and **SRE-aligned telemetry discipline** (`docs/search-backend-sre.md`). The main risks are **misrepresenting merge order or sync timing** and **telemetry cardinality**; both are mitigated by **struct-faithful rendering**, **clear labeling**, and **aggregates-only** dashboards.

## Key Findings

### Recommended Stack

Phoenix + LiveView + path dependency on `scrypath`; Elixir/OTP floors match the library. No second frontend stack.

**Core technologies:**
- **Phoenix LiveView** — interactive operator screens without heavy SPA complexity.
- **Scrypath (path)** — single source of truth for operator behavior.

### Expected Features

**Must have (table stakes):**
- Posture landing and failed-work triage grounded in library APIs.
- Read-only posture; actions remain in documented operator paths.

**Should have (competitive):**
- Federation-honest multi-search visualization.
- JTBD-driven navigation and persona notes in-repo.

**Defer (v2+):**
- Meilisearch cluster admin clone, arbitrary production query logging.

### Architecture Approach

Separate Phoenix app (or umbrella child) with context modules adapting `Scrypath` structs for LiveView; **no** parallel business logic.

**Major components:**
1. **Router / auth** — explicit model for who may use OPSUI.
2. **LiveViews** — one primary flow per JTBD cluster.
3. **Presentation** — reusable components for federation and failure envelopes.

### Critical Pitfalls

1. **Lying about federation merge semantics** — use library projections and documented ordering.
2. **High-cardinality telemetry** — aggregate; never key dashboards on raw queries by default.
3. **Shipping UI in core Hex** — keep OPSUI optional and packaged separately.
4. **Under-specified auth** — document and enforce dev vs prod expectations up front.

## Implications for Roadmap

### Phase 44: OPSUI foundations

**Rationale:** Security, packaging, and IA must land before data-heavy screens.
**Delivers:** App shell, persona/JTBD nav, convention baseline, README for run.
**Addresses:** OPSUI-06, OPSUI-07, OPSUI-08, OPSUI-09.

### Phase 45: Posture & failure triage

**Rationale:** Highest-frequency operator value; proves adapter pattern to `Scrypath`.
**Delivers:** Landing posture, failed sync work views, sync status / read-only reconcile context.
**Addresses:** OPSUI-01, OPSUI-02, OPSUI-03.

### Phase 46: Search & federation honesty

**Rationale:** Depends on trusted read patterns; hardest UX risk.
**Delivers:** Bounded search exploration + federation inspector.
**Addresses:** OPSUI-04, OPSUI-05.

### Phase 47: Verification & hardening

**Rationale:** Lock conventions and prevent drift.
**Delivers:** LiveView/ExUnit (or agreed) CI slice, copy tweaks, pitfall guards.
**Addresses:** OPSUI-10.

### Research Flags

- **Phase 46:** Highest need for **struct-accurate** UI review during planning.
- **Phase 44:** **Auth** choice may need org-specific input during discuss-phase.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Phoenix-native path |
| Features | HIGH | Grounded in backlog + SRE doc |
| Architecture | HIGH | Thin-client pattern |
| Pitfalls | MEDIUM–HIGH | Federation edge cases need plan-phase detail |

**Overall confidence:** HIGH

### Gaps to Address

- Exact **repo layout** (umbrella vs `examples/ops_ui` vs separate repo): decide in Phase 44 planning.
- **Auth** mechanism (BasicAuth stub vs dev-only vs OIDC): org-specific; document minimum bar in Phase 44.

## Sources

### Primary

- `.planning/PROJECT.md`
- `docs/search-backend-sre.md`
- Milestone archives **v1.8–v1.9** (federation + per-query)

---
*Research completed: 2026-04-20*
*Ready for roadmap: yes*
