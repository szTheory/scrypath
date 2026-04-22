# Project Research Summary

**Project:** Scrypath

**Domain:** Ecto-native Meilisearch indexing + optional **`scrypath_ops`** operator UI

**Researched:** 2026-04-21

**Confidence:** MEDIUM overall (ecosystem scan + repo architecture); B1 delivery confidence depends on locking an evidence list in **REQUIREMENTS.md**.

## Executive Summary

Milestone **v1.14** intentionally pairs two themes already ranked in **`milestone-candidates.md`**: **Tier B1** (small, **evidence-backed** improvements to the core library and docs) and **Tier B2** (**OPSUI-FUT-01** — saved queries / operator playbooks for **replay and learning**, especially multi-index and per-query shapes). Comparable ecosystems (Searchkick’s repeatable console workflows, Scout’s explicit Meilisearch option pass-through and testing doubles) reinforce that **repeatability**, **honest query contracts**, and **testability without production logging** are table stakes — not nice-to-haves.

The recommended approach is to **sequence**: (1) freeze an evidence list for **B1** and prefer doc/error fixes before API changes; (2) decide a **playbook persistence MVP** (export/import-first vs database) before large LiveView work; (3) implement playbooks against the existing **`SearchPlayground`** adapter seam so CI stays free of live Meilisearch. **OPSUI-FUT-02** and Tier-C CI remain out of scope.

## Key Findings

### Recommended Stack

No stack pivot. Optional **`scrypath_ops`** Postgres only if multi-user durable playbooks are required in v1.14; otherwise export/import or session-scoped storage reduces operational burden. See **STACK.md**.

**Core technologies:**

- **Elixir / Phoenix LiveView** — OPSUI continues outside Hex (**OPSUI-09**).
- **Meilisearch via `Scrypath`** — single integration path for playground runs.
- **Stub adapter** — preserve fast CI for playbook flows.

### Expected Features

**Must have (table stakes):**

- Bounded replay of search / multi-search — users expect the same caps and warnings as manual playground use.
- Evidence linkage for **B1** — prevents mindless churn.

**Should have (competitive):**

- Playbook metadata that plays well with **federation** (weights, partial failures, `:all` expansion visibility) — aligns with shipped differentiator (**OPSUI-05**).

**Defer (v2+):**

- **OPSUI-FUT-02** vendor-style cluster dashboard.
- Heavy browser E2E / Meilisearch-in-OPSUI CI (**Tier C**) until a proven gap.

### Architecture Approach

Extend **`SearchLive`** + **`SearchPlayground`** with versioned playbook payloads; keep mutations and recovery out of the UI. See **ARCHITECTURE.md**.

**Major components:**

1. **Evidence triage (planning + issues)** — gates B1 scope.
2. **Playbook model + normalizer** — stable JSON schema.
3. **LiveView UX + contracts** — nav / IA / tests.

### Critical Pitfalls

1. **Speculative B1** — require citation per change (**PITFALLS.md**).
2. **Playbooks as prod logging** — explicit warnings + scrubbed export.
3. **IA drift** — update **`operator-ia.md`** with nav contract tests.

## Implications for Roadmap

### Phase 57: Evidence triage and B1 scope lock

**Rationale:** Research flags ungrounded core changes as the top risk.

**Delivers:** Frozen list of **B1** items with evidence pointers; quick wins where doc/error only.

**Addresses:** B1 table stakes from **FEATURES.md**.

**Avoids:** Speculative API pitfall.

### Phase 58: Core library / doc QoL (B1 execution)

**Rationale:** Ship trust improvements before larger UI surface.

**Delivers:** Merged PRs for each **LIB-*** requirement; verification via existing `mix verify.*` slices.

### Phase 59: Playbook design and persistence MVP

**Rationale:** Persistence choice affects migrations and auth.

**Delivers:** Decision record in plan or guide; schema or export format **`v1`**.

### Phase 60: Playbook LiveView + integration

**Rationale:** Depends on normalized payload and persistence path.

**Delivers:** Save / list / load / run; stub adapter tests; nav contract.

### Phase 61: Milestone verification and narrative

**Rationale:** Close with contributor-visible verify story.

**Delivers:** `mix verify.opsui` / doc contract updates; **MILESTONES.md** / **PROJECT.md** current state.

### Phase Ordering Rationale

B1 before deep B2 reduces merge risk; playbook persistence decision before UI prevents rework.

### Research Flags

- **Phase 59:** May need product call on export-first vs DB — mark in discuss-phase.
- **Phase 57:** If no GitHub evidence, use maintainer dogfood log as interim evidence source (document in REQUIREMENTS).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Repo already matches |
| Features | MEDIUM | B1 list must be evidence-bound |
| Architecture | MEDIUM–HIGH | Hinges on persistence MVP |
| Pitfalls | HIGH | Bounded playground precedent exists |

**Overall confidence:** MEDIUM — execution-ready after REQ freeze.

### Gaps to Address

- **Concrete B1 issue list:** Populate during phase 57 from GitHub + support notes.
- **Playbook ACL:** If skipped in v1.14, state limitation in REQUIREMENTS Out of Scope.

## Sources

### Primary

- **`milestones/v1.10-REQUIREMENTS.md`**, **`milestone-candidates.md`**
- **`scrypath_ops`** Search playground modules (see ARCHITECTURE.md)

### Secondary

- Searchkick / Scout / Meilisearch Laravel docs (comparative patterns only)

---
*Research completed: 2026-04-21*

*Ready for roadmap: yes*
