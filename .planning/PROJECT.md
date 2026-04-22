# Scrypath

## What This Is

Scrypath is an open-source Elixir library for declarative, Ecto-native search indexing and search orchestration. It helps Phoenix and Ecto teams add search to existing schemas with a small amount of code while handling synchronization, reindexing, and operational workflows in a way that feels native to the Elixir ecosystem.

## Core Value

Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Current milestone

**Next — v1.12+** (not opened). Run **`/gsd-new-milestone`** when you want a fresh requirements pass and numbered roadmap slice.

## Last shipped milestone

**v1.11 — Operator shell polish and JTBD verification** (archived **2026-04-21**). Tightened **`scrypath_ops`** so **`operator-ia.md`**, **`router.ex`**, and maintainer tests agree; clarified posture **JTBD** and **next checks**; unified **`/ops`** page scaffold with **system/light/dark** readability; added Phoenix shell contract coverage plus accessibility and **`opsui.test_a11y`** verification — **`OPSUX-01`..`OPSUX-07`** (see **`milestones/v1.11-REQUIREMENTS.md`**).

**Prior:** **v1.10 — Operator admin UI (OPSUI)** — **`milestones/v1.10-{ROADMAP,REQUIREMENTS}.md`**.

## Planning window

**Between milestones.** **`v1.11`** snapshot: **`milestones/v1.11-{ROADMAP,REQUIREMENTS}.md`**. **`v1.10`**: **`milestones/v1.10-{ROADMAP,REQUIREMENTS}.md`**. A fresh **`.planning/REQUIREMENTS.md`** is created by **`/gsd-new-milestone`**. Research notes may remain under **`.planning/research/`**.

## Requirements

### Validated

- [x] Schema metadata declarations, projection, runtime reflection, and the internal backend seam validated in v1.0.
- [x] Meilisearch-backed sync for insert, update, delete, inline, manual, and Oban-backed workflows validated in v1.0.
- [x] Common search, validated filter/sort/page handling, raw-hit access, and explicit hydration validated in v1.0.
- [x] Backfill, managed reindex, settings application, and recovery guidance validated in v1.0.
- [x] Phoenix docs, examples, release automation, and package trust signals validated in v1.0.
- [x] Launch-readiness hardening for Meilisearch edge cases, copied Phoenix docs safety, and milestone-close release evidence validated in v1.1.
- [x] The first real public release path, operator visibility surface, Mix task ergonomics, and the internal operations seam validated in v1.2.
- [x] Meilisearch-native search depth for growth-stage Phoenix teams — relevance tuning, faceted search, multi-index `search_many/2`, plus operator polish and drift recovery guidance — validated in planning milestone **v1.3** (2026-04-17).
- [x] Release-parity gates (`verify.workspace_clean`, `verify.release_parity`) and CI runtime hygiene (Node pin uplift) validated in v1.3.
- [x] v1.2 Nyquist validation debt (phases 13–15 evidence) closed in v1.3.
- [x] **v1.4** (2026-04-17): Hex **`scrypath 0.3.1`** with Release Please + post-publish `release_publish` / `release_parity` gates; narrow `hot_apply/3` for synonyms / stop words / typo tolerance; operator failure rollups by `reason_class` (`mix verify.phase26`).
- [x] **v1.5** (2026-04-18): **Phases 27–28** — read-only **index contract drift** (`Scrypath.index_contract_drift/2`, `IndexContractDrift.Report`), optional **`include_index_contract_drift`** on `reconcile_sync/2`, **`mix scrypath.index.contract_drift`**, operator doc refresh, auth-free **`mix verify.phase28`** — satisfies **DRIFT15-01..02**, **OPS15-01..04** (see **`milestones/v1.5-REQUIREMENTS.md`**).
- [x] **Phase 29** (2026-04-18): **`guides/golden-path.md`** (install → inline sync → `Scrypath.search/3`), ExDoc registration, README adoption wayfinding (sync heuristics + **`guides/sync-modes-and-visibility.md`** authority, **Versioning and upgrades**, `{:scrypath, "~> 0.3"}`), releasing + CHANGELOG cross-links — **ADPT-01, ADPT-02, ADPT-03**.
- [x] **Phase 33** (2026-04-18): Root-facing **README** / **CONTRIBUTING** / **`guides/golden-path.md`** agree on **cwd** for Phoenix example **`scripts/smoke.sh`**; **`docs_contract_test.exs`** locks filesystem + ordering — **ADPT-01**, **EXAM-02**, **VRFY-02**, **AUDT-01** (gap-closure slice).
- [x] **Phase 34** (2026-04-19): README **Quick Path** ↔ **`guides/golden-path.md`** canonical **`field :status, :string`**; golden path **Integration smoke** matches **`phoenix-example-integration`** on PRs + **`main`**; contract tests — **ADPT-01**, **ADPT-02**, **ADPT-03**, **VRFY-01** (audit gap-closure slice).
- [x] **Phase 35** (2026-04-19): **`guides/sync-modes-and-visibility.md`** **Operator lifecycle** subsection + README authority precision + **`docs_contract_test.exs`** lifecycle locks — **ADPT-02**, **ADPT-03** (`INT-SYNC-GUIDE-AUTHORITY`).
- [x] **Phase 30** (2026-04-18): Consumer-shaped **Oban** sync proof + example smoke depth / runbook — **EXAM-01**, **EXAM-02**.
- [x] **Phase 31** (2026-04-18): CONTRIBUTING verify ↔ guarantee matrix + default vs integration CI documentation — **VRFY-01**, **VRFY-02**.
- [x] **Phase 32** (2026-04-18): **`STATE.md`** deferred-row triage (**AUDT-01**) with terminal statuses.
- [x] **v1.6 milestone** (2026-04-19): Adoption-grade integration and trust — phases **29–35** archived; **`milestones/v1.6-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**; requirements **ADPT-***, **EXAM-***, **VRFY-***, **AUDT-01** satisfied per audit.
- [x] **Phase 36** (2026-04-19): **Hierarchical facets** — opt-in `nested_facet_paths`, optional `hierarchy:` expansion, Meilisearch settings + drift alignment, `SearchResult` dotted keys, guide **`## Hierarchical facets`**, **`mix verify.phase36`** — **FACET-01**.
- [x] **Phase 37** (2026-04-20): **Disjunctive facet counts** — `Scrypath.Facets.Disjunctive.merge_distributions/2`, guide **`## Disjunctive facet counts`**, **`mix verify.phase37`**, docs contract anchors — **FACET-02**.
- [x] **Phase 38** (2026-04-20): **`search_within_facet/4`** + telemetry metadata, guide sections (**`## Searching within a facet selection`**, **`## Composing facet filters with scoped search`**), **`mix verify.phase38`**, README / ExDoc pointers — **FACET-03**, **FACET-04**.
- [x] **Phase 39** (2026-04-20): **`federation_weight:`** + quad entries, Meilisearch **`federationOptions.weight`**, **`merge_hit_order`** / **`Scrypath.MultiSearchResult.merge_projection/1`**, guide **`## Federation weights`** — **FED-01**.
- [x] **Phase 40** (2026-04-20): **`{:all, …}`** expansion via **`Scrypath.MultiSearch.AllExpansion`**, **`global_schemas:`** / **`:scrypath_global_search_schemas`**, post-expansion **`max_schemas`**, explicit **`{:invalid_options, {:all_expansion, _}}`** errors — **FED-02**.
- [x] **Phase 41** (2026-04-20): Federation docs + **`docs_contract_test.exs`** anchors, **`mix verify.phase41`**, README / golden-path / **`guides/multi-index-search.md`** (`:all`, merge semantics), **`search_many/2`** `@doc` score invariant — **FED-03**.
- [x] **v1.8 milestone** (2026-04-20): Multi-index federation — phases **39–41** archived; **`milestones/v1.8-{ROADMAP,REQUIREMENTS}.md`**; requirements **FED-01..03** satisfied per archives and verify slices.
- [x] **Phase 42** (2026-04-20): **`guides/per-query-tuning-pipeline.md`** + discoverability (README, guides map, golden path, relevance + multi-index pointers), ExDoc extras, **`docs_contract_test`** spine anchors, **`Scrypath.search/3`** / **`search_many/2`** `@doc` — **TUNE-PIPE-01**..**TUNE-PIPE-04**.
- [x] **Phase 43** (2026-04-20): **Per-query runtime** — allowlisted **`:per_query`**, **`%Query{}`**, Meilisearch projection, **`search_many/2`** merge, telemetry, **`mix verify.phase43`**, doc pins — **TUNE-PQ-01**..**TUNE-PQ-03** / **`TUNE-01`** (v1.7 sense).
- [x] **v1.9 milestone** (2026-04-20): Per-query pipeline + runtime — phases **42–43** archived; **`milestones/v1.9-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.
- [x] **v1.10 milestone** (2026-04-21): Operator admin UI (OPSUI) — phases **44–47** archived; **`scrypath_ops`** LiveView app; **`milestones/v1.10-{ROADMAP,REQUIREMENTS}.md`**; **`OPSUI-01`..`OPSUI-10`**.
- [x] **v1.11 milestone** (2026-04-21): Operator shell polish — phases **48–50** archived; **`milestones/v1.11-{ROADMAP,REQUIREMENTS}.md`**; **`OPSUX-01`..`OPSUX-07`** (IA + router contract, posture JTBD, **`/ops`** scaffold and themes, Phoenix shell tests, a11y + CI slice).

### Active

- [ ] **v1.12+** — Open with **`/gsd-new-milestone`** when scope is chosen (fresh **`.planning/REQUIREMENTS.md`**).

### Out of Scope

- Postgres-native full-text search as a first-class v1 product surface - it muddies the product boundary and competes with a different problem space.
- Public multi-backend support before real adoption pressure proves the common contract deserves to widen.
- Advanced relevance features such as vector search, hybrid retrieval, personalization, or analytics before the operational core and public release story settle.

## Context

The project exists to fill a gap in the Elixir ecosystem: there are low-level API clients and partial integrations for search engines, but no category-defining library that gives Ecto and Phoenix developers a Searchkick or Laravel Scout level experience. The strongest initial wedge is Meilisearch because the Elixir ecosystem gap is larger there than for Typesense, while the long-term architecture should still preserve an internal adapter seam so the public API is not painted into a corner.

Scrypath is intended primarily for Phoenix applications using Ecto, with Ecto-first APIs and Phoenix-friendly features layered on top. The library emphasizes least surprise, operational honesty, and high-quality developer experience. Search synchronization acknowledges eventual consistency where it exists, supports Oban naturally, and documents tradeoffs clearly in README and guides so users understand who the library is for and who it is not for.

The repository has **twelve** archived planning milestones (**`v1.0`**–**`v1.11`**). Current planning truth lives in **`.planning/ROADMAP.md`**, **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, **`.planning/STATE.md`**, and **`milestones/v*-{ROADMAP,REQUIREMENTS}.md`** for shipped arcs. A living **`.planning/REQUIREMENTS.md`** returns when **`/gsd-new-milestone`** opens the next version.

- `v1.0` shipped the Meilisearch-first Ecto-native indexing core, search/hydration path, Oban support, reindex workflows, public Phoenix docs, and release automation baseline.
- `v1.1` shipped release hardening, docs-safety fixes, `mix verify.phase10`, and the launch-readiness evidence chain.
- `v1.2` shipped the first live public release as `scrypath 0.3.0`, the internal operations seam, operator visibility APIs, thin Mix tasks, and milestone-close verification/bookkeeping repairs.
- `v1.3` shipped planning-track delivery of relevance tuning, faceted search, multi-index search, operator polish + drift recovery guide, release-parity gates, and v1.2 Nyquist validation closure (archived 2026-04-17).
- `v1.4` shipped **Hex `scrypath 0.3.1`**, the bounded live-index `hot_apply/3` path, and operator failure rollups — archived 2026-04-17 (`milestones/v1.4-ROADMAP.md`, `milestones/v1.4-REQUIREMENTS.md`).

The current public line on Hex is **`scrypath 0.3.3`**. **v1.8** closed the federation loop (**weights**, **`:all` expansion**, **docs/contracts**) on top of prior depth (**v1.3–v1.7**) and operator tooling (**v1.4–v1.5**).

## Constraints

- **Tech stack**: Elixir OSS library with Ecto-first APIs and Phoenix-friendly integrations - the ecosystem fit is central to adoption.
- **Backend strategy**: Public v1 should target Meilisearch first, while preserving an internal adapter seam - avoid premature public abstraction without causing API damage later.
- **Write-path support**: v1 should support inline, Oban-backed, and manual synchronization flows - different apps need different consistency and operational tradeoffs.
- **Developer experience**: Minimal setup and great Phoenix ergonomics are the top priority, with correctness close behind - product decisions should optimize for low friction without hiding reality.
- **Operational clarity**: Eventual consistency, delete semantics, backfills, and reindex workflows must be explicit - search sync failures are operational issues, not minor edge cases.
- **Release quality**: Public release is now proven, but future milestone choices should still favor product coherence over breadth for its own sake.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use `Scrypath` as the project and package identity | The name is available on Hex and matches the intended brand posture | Retained through v1.2 public release |
| Position the product as the missing Searchkick or Scout for Ecto and Phoenix | The real gap is the integration and sync layer, not another thin HTTP client | Reinforced by shipped API, docs, and first public release |
| Start with Meilisearch as the public v1 backend | The market gap is stronger and it keeps v1 focused while preserving an internal adapter seam | Validated across v1.0-v1.2 |
| Keep the core Ecto-first and Phoenix-friendly | Ecto is the stable architectural center, while Phoenix ergonomics are critical for adoption | Validated in shipped API and docs |
| Support inline, Oban, and manual sync modes in v1 | Teams need a simple local path, a production queue path, and an explicit escape hatch | Validated in v1.0 and clarified in v1.2 operator guides |
| Expose operator visibility through Scrypath-owned APIs and thin Mix tasks, not a dashboard product | Early adopters need explicit operational visibility without a second product surface | Shipped and validated in v1.2 |
| Defer public multi-backend support and advanced relevance features until real adoption pressure appears | Premature abstraction and feature breadth would increase API risk before the core is proven | Still deferred after the first public release |
| Ship v1.4 as additive Hex + ops depth (`0.3.1`) without widening backend or reconcile forks | Keeps the public story honest while closing the package parity gap | ✓ Good — shipped 2026-04-17 |
| Narrow `hot_apply/3` to synonym / stop-word / typo-tolerance keys only | Prevents silent widening into ranking rules and other managed-pipeline settings | ✓ Good — TUNE14-01/02 |
| Operator rollups as additive metadata on `failed_sync_work/2` | Report-first discipline; no new recovery verbs | ✓ Good — OPS14-01 / `mix verify.phase26` |
| Ship facet depth as composable Meilisearch primitives + verify slices | Keeps OR-count story explicit (merge helper); avoids premature “catalog page” facade | ✓ Good — **v1.7** audit notes operator wiring burden as documented tradeoff |
| Ship federation as explicit opts + expansion + doc contracts (not a dashboard) | Keeps cross-index ordering honest in library code before any **OPSUI** surface | ✓ Good — **v1.8** (**FED-01..03**) with **`mix verify.phase41`** |
| Spec-first per-query tuning (**`TUNE-PIPE-*`**) then bounded **Plane B** runtime (**`TUNE-PQ-*`**) | Prevents silent ranking drift; keeps Meilisearch wire and merge semantics explicit | ✓ Good — **v1.9** with **`guides/per-query-tuning-pipeline.md`** + **`mix verify.phase43`** |
| **v1.10** — OPSUI outside core Hex; JTBD-first admin LiveView | Preserves library boundary while giving operators a conventional, honest UI over shipped APIs | ✓ Good — **`scrypath_ops`** shipped **2026-04-21**; see **`milestones/v1.10-REQUIREMENTS.md`** |
| **v1.11** — Operator shell polish before widening OPSUI feature set | JTBD-first shell must *feel* finished: IA truth, scanability, themes, a11y basics, CI locks | ✓ Good — shipped **2026-04-21**; see **`milestones/v1.11-REQUIREMENTS.md`** |

## Current State

**Hex:** `scrypath` **`0.3.3`**. Shipped surfaces include the v1.3-era Meilisearch-native path (relevance, facets, multi-index, operator polish), v1.4 **hot_apply** / failure rollups, v1.5 **index contract drift** tooling, v1.6 **adoption-grade** docs and verification clarity, **v1.7** facet-depth APIs with **`mix verify.phase36`..`38`**, **v1.8** federation weights / **`:all`** expansion / **`mix verify.phase41`**, **v1.9** per-query pipeline spec + **`:per_query`** runtime with **`mix verify.phase43`**, **v1.10** optional **`scrypath_ops`** operator LiveView UI, and **v1.11** operator-shell polish (**IA contract**, **theming**, **Phoenix shell tests**, **`opsui.test_a11y`**).

**Planning:** **v1.11** archived **2026-04-21**; next milestone not opened.

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-21 after **`/gsd-complete-milestone`** — archived **v1.11** Operator shell polish and JTBD verification; Hex **`scrypath 0.3.3`** current**
