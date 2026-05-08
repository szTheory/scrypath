# Scrypath

## What This Is

Scrypath is an open-source Elixir library for declarative, Ecto-native search indexing and search orchestration. It helps Phoenix and Ecto teams add search to existing schemas with a small amount of code while handling synchronization, reindexing, and operational workflows in a way that feels native to the Elixir ecosystem.

## Core Value

Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Current State

**v1.20 — Search Module Foundation** opened on **2026-05-07** and continues phase numbering at **77**.

**Why this milestone now:** the active **Batteries-Included Search Modules** arc is a narrow, leverage-positive follow-up to the defended core. It builds a thin, explicit Phoenix/Ecto ergonomics layer that is already in motion in the worktree, while keeping the **`v1.19`** broader-adoption verdict intact and avoiding a return to broad speculative feature expansion.

**Target features:**

- **Context-owned search modules** — app-level modules declare schema, backend, repo, preload, and browser-param rules without generating runtime verbs on schemas.
- **Stable param normalization** — one thin boundary for text, filter, sort, page, facets, and facet-filter request shapes before delegating into **`Scrypath.search/3`**.
- **Structured param errors** — invalid request input fails with explicit, field-scoped error details instead of ad hoc controller or LiveView branching.
- **Phoenix/Ecto ergonomics docs** — guides and examples show the context boundary, request-param story, and non-goals clearly enough that teams can adopt the layer without guessing at hidden runtime semantics.

**Boundary discipline:** this milestone is about a thin app-facing ergonomics layer over the existing runtime, not callback magic or public backend expansion. `scrypath` core stays Meilisearch-first, Ecto-first, and auth-agnostic. `use Scrypath` remains metadata-only on schemas, Phoenix stays optional, and sync / reindex / visibility semantics remain explicit rather than hidden.

**Out of scope for v1.20:** public Phoenix helpers, reusable composition presets beyond the foundation, schema-generated runtime search APIs, public multi-backend expansion, deeper OPSUI breadth, or any change that hides operational search semantics behind framework magic.

Canonical REQ IDs: **`.planning/REQUIREMENTS.md`** (**SMOD-***).

## Current Milestone Outcome

- Milestone opened from the active **Batteries-Included Search Modules** arc on **2026-05-07**.
- Scope is intentionally narrow: normalize browser-shaped params once, keep contexts as the application boundary, and reuse the existing **`Scrypath.search/3`** engine.
- The broader-adoption checkpoint from **`milestones/v1.19-MILESTONE-AUDIT.md`** remains canonical and should not be restated as outside validation.
- The first planned slice starts at **Phase 77**.

## Last shipped milestone

**v1.19 — Production adoption proof and hardening** (shipped + archived in-repo **2026-04-28** as a readiness checkpoint). Canonical readiness truth, one defended fast/live proof family, production-shaped core and optional example coverage, a bounded adopter-intake path, and one evidence-backed hardening fix — see **`milestones/v1.19-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.18 — Sigra integration** (shipped + archived in-repo **2026-04-26**) — **`milestones/v1.18-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**. **v1.17 — Integration confidence & adopter proof** (shipped + archived in-repo **2026-04-23** as a readiness checkpoint) — **`milestones/v1.17-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**. **v1.16 — Playbook execution & operator honesty** (shipped + archived in-repo **2026-04-22**) — **`milestones/v1.16-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**. **OPSUI** arc: **`milestones/v1.10-{ROADMAP,REQUIREMENTS}.md`**.

## Planning window

**v1.20 — Search Module Foundation** opened on **2026-05-07**. Phases **77–79** are planned; rolling milestone truth now lives in **`.planning/{PROJECT,REQUIREMENTS,ROADMAP,STATE}.md`** until the archive trio exists.

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
- [x] **Phase 51** (2026-04-21): Adoption path truth and discoverability — README / **`guides/golden-path.md`** / **CONTRIBUTING** / example README + **`docs_contract_test`** for sync authority and **`phoenix-example-integration`** Mix ordering (**ONBD-01**..**ONBD-03**).
- [x] **Phase 52** (2026-04-22): Actionable **`{:error, _}`** surfaces + **`Scrypath.Search.Error`** bang helpers, **`guides/common-mistakes.md`**, lobby **`@moduledoc`** and operator **`mix scrypath.*`** Read-next links, doc contracts (**ONBD-04**..**ONBD-06**).
- [x] **Phase 53** (2026-04-22): Contributor **`mix verify.opsui`** spine — Mix **`@moduledoc`**, README wayfinding, **`docs_contract_test`** locks for **`scrypath-ops`** vs **CONTRIBUTING** / **`ci.yml`** (**VRFY-03**, **VRFY-04**).
- [x] **v1.13** (2026-04-22): Public polish & narrative coherence — phases **54–56** — **POLISH-01**–**POLISH-05** (guide voice, Hex **0.3.4** narrative, **`AGENTS.md`**, **`milestone-candidates.md`**, pitfalls ledger gate).
- [x] **Phase 57** (2026-04-22): **EVID-01** B1 evidence ledger (`.planning/EVID-01-b1-v1.14.md`), **LIB-01..03** triage, contributor gates (**CONTRIBUTING**, PR template, **CODEOWNERS**), planning mirrors — **EVID-01**.
- [x] **Phase 58** (2026-04-22): Core library + doc QoL **LIB-01..03** — **`Scrypath.Errors`**, **`Query`** boundary, **`docs_contract_test`** anchors — **`.planning/phases/58-core-library-and-doc-qol-b1/`**.
- [x] **Phase 59** (2026-04-22): Operator playbook **`playbook_format` 1** — **`ScrypathOps.Playbook.V1`**, **`scrypath_ops/docs/playbook-schema-v1.md`**, IA link, **REQUIREMENTS** persistence note — **OPS-PB-01**, **OPS-PB-03** — **`.planning/phases/59-playbook-schema-and-persistence-mvp/`**.
- [x] **Phase 60** (2026-04-22): **`/ops/playbooks`** — **`Playbook.Store`**, **`Playbook.Runner`**, **`PlaybookLive`**, **`SCRYPATH_OPS_PLAYBOOK_DIR`**, **`operator-ia.md`** — **OPS-PB-02**, **OPS-PB-04** — **`.planning/phases/60-playbook-liveview-and-ia/`**.
- [x] **Phase 61** (2026-04-22): **`PlaybookLive`** stub tests, **`mix verify.opsui`**, **SHIP-01** planning alignment — **OPS-PB-05**, **SHIP-01** — **`.planning/phases/61-verification-and-milestone-bookkeeping/`**.
- [x] **v1.14 milestone** (2026-04-22): Evidence-led **B1** QoL + **`scrypath_ops`** operator playbooks — phases **57–61**; **`milestones/v1.14-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.
- [x] **Phase 62** (2026-04-22): Playground capture + playbook catalog — **`V1`** metadata, **`Store`** rename/duplicate, **`SearchLive`** save-as-playbook, **`PlaybookLive`** catalog UX — **OPS2-01**–**OPS2-03** — **`.planning/phases/62-playground-capture-and-playbook-catalog/`**.
- [x] **Phase 63** (2026-04-22): Bounded team persistence + security posture — **`team-playbook-persistence.md`**, **`mix scrypath_ops.playbooks.validate`**, **`examples/playbooks/`**, schema threat-model copy, **`V1`** / **`PlaybookLive`** hardening tests — **OPS2-04**, **OPS2-07** — **`.planning/phases/63-bounded-team-persistence-and-security-posture/`**.
- [x] **Phase 64** (2026-04-22): IA + verification + milestone bookkeeping — **`operator-ia.md`** team persistence pointers, **`mix verify.opsui`** / **`docs_contract_test`** / **`guides/meilisearch-operations.md`**, frozen **`v1.15-*`** — **OPS2-05**, **OPS2-06**, **OPS2-08** — **`.planning/phases/64-ia-verification-and-milestone-bookkeeping/`**.
- [x] **v1.15 milestone** (2026-04-22): OPSUI second slice — phases **62–64**; **`milestones/v1.15-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

### Active

- [ ] **SMOD-01**–**SMOD-08** — open **v1.20 Search Module Foundation**: context-owned search-module declarations, stable request-param normalization, structured param errors, thin delegation over **`Scrypath.search/3`**, and Phoenix/Ecto-facing docs plus regression coverage.

### Recently completed

- [x] **v1.19** (2026-04-28): **PRDY-01**–**PRDY-08** — canonical readiness contract, defended fast/live proof family, production-shaped Phoenix + Sigra example coverage, bounded adopter-intake path, one evidence-backed papercut fix, and a readiness-checkpoint close archived in **`milestones/v1.19-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.
- [x] **v1.17 — Integration confidence & adopter proof** (2026-04-23) — phases **68–70**; **INTG-01**–**INTG-06** — **`milestones/v1.17-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.
- [x] **v1.16 — Playbook execution & operator honesty** (2026-04-22) — phases **65–67**; **OPS3-01**–**OPS3-06** — **`milestones/v1.16-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

### Out of Scope

- Postgres-native full-text search as a first-class v1 product surface - it muddies the product boundary and competes with a different problem space.
- Public multi-backend support before real adoption pressure proves the common contract deserves to widen.
- Advanced relevance features such as vector search, hybrid retrieval, personalization, or analytics before the operational core and public release story settle.

## Context

The project exists to fill a gap in the Elixir ecosystem: there are low-level API clients and partial integrations for search engines, but no category-defining library that gives Ecto and Phoenix developers a Searchkick or Laravel Scout level experience. The strongest initial wedge is Meilisearch because the Elixir ecosystem gap is larger there than for Typesense, while the long-term architecture should still preserve an internal adapter seam so the public API is not painted into a corner.

Scrypath is intended primarily for Phoenix applications using Ecto, with Ecto-first APIs and Phoenix-friendly features layered on top. The library emphasizes least surprise, operational honesty, and high-quality developer experience. Search synchronization acknowledges eventual consistency where it exists, supports Oban naturally, and documents tradeoffs clearly in README and guides so users understand who the library is for and who it is not for.

The repository has **twenty-one** shipped planning milestones through **`v1.19`** (**`v1.0`**–**`v1.19`**). Current planning truth lives in **`.planning/ROADMAP.md`**, **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, **`.planning/STATE.md`**, and **`milestones/v*-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`** for shipped arcs.

- `v1.0` shipped the Meilisearch-first Ecto-native indexing core, search/hydration path, Oban support, reindex workflows, public Phoenix docs, and release automation baseline.
- `v1.1` shipped release hardening, docs-safety fixes, `mix verify.phase10`, and the launch-readiness evidence chain.
- `v1.2` shipped the first live public release as `scrypath 0.3.0`, the internal operations seam, operator visibility APIs, thin Mix tasks, and milestone-close verification/bookkeeping repairs.
- `v1.3` shipped planning-track delivery of relevance tuning, faceted search, multi-index search, operator polish + drift recovery guide, release-parity gates, and v1.2 Nyquist validation closure (archived 2026-04-17).
- `v1.4` shipped **Hex `scrypath 0.3.1`**, the bounded live-index `hot_apply/3` path, and operator failure rollups — archived 2026-04-17 (`milestones/v1.4-ROADMAP.md`, `milestones/v1.4-REQUIREMENTS.md`).

The current public line on Hex is **`scrypath 0.3.4`**. **v1.8** closed the federation loop (**weights**, **`:all` expansion**, **docs/contracts**) on top of prior depth (**v1.3–v1.7**) and operator tooling (**v1.4–v1.5**).

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
| **v1.12** — Onboarding and QoL before OPSUI “second slice” | Adopters and contributors should not pay a tax of doc drift, vague errors, or scattered verify commands | ✓ Good — shipped in-repo **2026-04-22** (phases **51–53**); see **`milestones/v1.12-REQUIREMENTS.md`** |
| **v1.13** — Public polish & narrative coherence | Adopter docs stay product-shaped; Hex line + README + planning agree; contributor entry stays approachable | ✓ Good — shipped in-repo **2026-04-22** (phases **54–56**); see **`milestones/v1.13-REQUIREMENTS.md`** |
| **v1.14** — Library QoL + operator playbooks | Evidence-led **B1** core changes; bounded **OPSUI** second slice for saved searches without widening vendor-dashboard scope | ✓ Good — shipped + archived in-repo **2026-04-22** (phases **57–61**); formal audit **`tech_debt`** — see **`milestones/v1.14-MILESTONE-AUDIT.md`** |
| **v1.15** — OPSUI second slice | **OPSUI-FUT-01** depth after playbook MVP: capture from playground, catalog/metadata, bounded team persistence | ✓ Good — shipped + archived in-repo **2026-04-22** (phases **62–64**); see **`milestones/v1.15-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`** |
| **v1.16** — Playbook execution & operator honesty | Close the operator loop after capture/catalog/persist: **run lifecycle**, **actionable errors**, **runner–library alignment**, **verify/contracts**, **JTBD examples** | ✓ Shipped + archived in-repo |
| **v1.17** — Integration confidence & adopter proof | Freeze breadth; prove the shipped surface lands cleanly in real Phoenix/Ecto apps through one example, one support contract, one adoption verify path, and a short list of evidence-backed papercuts | ✓ Shipped + archived in-repo as a readiness checkpoint |
| **v1.18** — Sigra integration (in-repo, optional) | Optional in-repo Sigra integration for `scrypath_ops`; keeps `scrypath` core auth-agnostic and Sigra unaware while giving hosts a canonical operator-attribution + sudo + audit story for sensitive ops actions | ✓ Shipped + archived in-repo |
| **v1.19** — Production adoption proof and hardening | After the readiness checkpoint and Sigra add-on, prioritize defended production proof, support-contract clarity, and evidence-backed papercut closure before widening product scope again | ✓ Shipped + archived in-repo as a readiness checkpoint; canonical verdict: ready to seek broader outside production adoption on the defended surface, with external validation still pending |
| Post-v1.19 pause on internal feature work | Do not open another build-more milestone unless real outside adopter evidence identifies concrete friction or a release/distribution need justifies the work | — Pending external validation |
| **v1.20** — Search Module Foundation | A narrow, already-started ergonomics layer that removes repeated Phoenix/Ecto request-param boilerplate without changing the core runtime or hiding operational search semantics | — Active |

## Historical Context

**Hex:** `scrypath` **`0.3.4`** on Hex; default-branch **`mix.exs`** matches unless a release PR is mid-flight. Shipped surfaces include the v1.3-era Meilisearch-native path (relevance, facets, multi-index, operator polish), v1.4 **hot_apply** / failure rollups, v1.5 **index contract drift** tooling, v1.6 **adoption-grade** docs and verification clarity, **v1.7** facet-depth APIs with **`mix verify.phase36`..`38`**, **v1.8** federation weights / **`:all`** expansion / **`mix verify.phase41`**, **v1.9** per-query pipeline spec + **`:per_query`** runtime with **`mix verify.phase43`**, **v1.10** optional **`scrypath_ops`** operator LiveView UI, **v1.11** operator-shell polish (**IA contract**, **theming**, **Phoenix shell tests**, **`opsui.test_a11y`**), **v1.12** first-hour onboarding (**adoption path contracts**, **actionable errors + pitfalls**, **contributor `mix verify.opsui` spine**), **v1.13** public polish (**guide voice**, **Hex narrative**, **`AGENTS.md`**), **v1.14** (**`Scrypath.Errors`**, **`ScrypathOps.Playbook.V1`**, **`/ops/playbooks`**, **`SCRYPATH_OPS_PLAYBOOK_DIR`**, stub-backed **`PlaybookLive`** tests), **v1.15** (**playground → playbook capture**, **team playbook persistence docs + `mix scrypath_ops.playbooks.validate`**, **nav + verify contracts** for the second OPSUI slice), and **v1.16**, which completed the saved-playbook execution loop with bounded lifecycle/error contracts, canonical JTBD fixtures, and truthful milestone-close bookkeeping.

**Planning:** **v1.19 — Production adoption proof and hardening** is now closed and archived as a readiness checkpoint. Future milestone selection should treat **`milestones/v1.19-MILESTONE-AUDIT.md`** as the canonical source for whether to seek outside adopter evidence next and should not infer stronger production validation than that audit claims.

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
*Last updated: 2026-04-28 — closed **v1.19 Production adoption proof and hardening** as a readiness checkpoint and archived the canonical verdict in **`milestones/v1.19-MILESTONE-AUDIT.md`***
