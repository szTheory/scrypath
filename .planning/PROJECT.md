# Scrypath

## What This Is

Scrypath is an open-source Elixir library for declarative, Ecto-native search indexing and search orchestration. It helps Phoenix and Ecto teams add search to existing schemas with a small amount of code while handling synchronization, reindexing, and operational workflows in a way that feels native to the Elixir ecosystem.

## Core Value

Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Current Milestone

No active milestone. v1.33 Admin UI Insane Polish shipped and archived on 2026-06-03.

## Current Mode: idle release train

**Goal:** Keep `main` green, preserve release/support truth, and avoid inventing new roadmap scope without concrete evidence.

**Recent closed outcomes:**
- v1.30 release train/package truth, support intake routing, advisory proof stability, and public website/docs truth alignment.
- v1.31 adoption-evidence demo pass: richer deterministic Playwright coverage, Docker/dev iteration support, ops UI clarity, evidence summary reporting, and maintainer UAT passed.
- v1.32 admin UI cleanup: ScrypathOps design tokens, shared operator primitives, mounted e-commerce asset contract, screen cleanup, and focused verification.
- Repaired generated `__scrypath__(:fan_outs)` for ordinary `use Scrypath, fan_outs:` schemas.
- Tenant-preserving ecommerce readiness regression proof.
- Aligned roadmap/JTBD truth for the repair closeout.

## Canonical Adopter Contract

**Install and version policy:**
- One canonical install/version statement across root docs and adopter-facing intake surfaces.
- `main` may include unreleased changes; stable adopter instructions must point to release-backed truth.

**Support and proof policy:**
- `mix verify.adopter` is the canonical adopter proof spine.
- Fast proof is required for routine PR confidence; live proof remains explicit and prerequisite-bound.
- Adopter issue intake must request reproducible evidence and flow classification.

**Non-goals:**
- No expansion into autocomplete/suggestions, vector/hybrid, multi-backend broadening, or new public runtime surfaces.
- No Phoenix UI feature expansion beyond contract-surface clarity.
- No relaxing of framework-agnostic runtime boundaries.

## Scope Guard Authority

Source of truth: `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`

Phase 97 through 99 banned capability classes:
- autocomplete/suggestions
- vector or hybrid retrieval
- public backend broadening
- new public runtime API categories

## Current State

**v1.32 — Admin UI/UX Design System Cleanup** shipped + archived in-repo on **2026-06-01** across phases **116-118**.

**What shipped:**
- ScrypathOps shell/theme cleanup with project-owned operator tokens, route-mark logo, improved focus/typography/numeric handling, and shared shell surfaces.
- Shared LiveView primitives now cover operator panels, notices, metrics, empty states, schema selects, buttons, code blocks, and modals.
- Posture, failed sync, sync/drift, search/federation, and playbooks now use clearer content hierarchy and natural workflow ordering.
- Mounted e-commerce admin routes conditionally load ScrypathOps CSS and host-side JS handles theme/diagnostics-copy events without loading a second LiveSocket.
- Focused ScrypathOps LiveView, root OPSUI, and mounted ecommerce admin route tests passed.

**v1.31 — Adoption Evidence Demo Hardening** passed maintainer UAT on **2026-06-01** across phases **113-115**.

**What shipped into the next wedge:**
- Realistic e-commerce demo hardening for tenant isolation, delete sync, no-results state, category propagation, operator triage, and zero-downtime swap browser proof.
- Docker/dev DX with bind-mounted iteration and clearer cache behavior for the demo app.
- Documentation and evidence summaries explaining the demo's advisory status, click-around value, and proof boundaries.

**v1.30 — Release Trust and Evidence Maintenance** shipped + archived in-repo on **2026-06-01** across phases **109-112**.

**What shipped:**
- Release-source agreement and Hex package-shape proof hardened through deterministic `mix verify.phase11` checks.
- Canonical and recovery publish workflows now share one ordered proof chain with release docs aligned to that contract.
- Support/readiness and outside-adopter evidence routing now point to one compatibility authority and one intake vocabulary, pinned by `mix verify.adopter`.
- `phase105-e2e` remains advisory with structured evidence capture, explicit promotion thresholds, and lean trust-lane drift checks.
- Public website/docs truth now routes to README, guides, examples, Hex, GitHub, and the scope/reopen policy without becoming a second docs site.

**v1.28 — Realistic Demo App & Admin UI Proof** shipped + archived in-repo on **2026-05-31** across phases **102–105**.

**What shipped:**
- Mountable `scrypath_ops` router engine for embedding in host Phoenix applications.
- Multi-tenant e-commerce example app under `examples/scrypath_ecommerce`.
- Storefront search proving tenant filtering, category faceting, and related-data propagation.
- Operator E2E proof for failed-sync triage and zero-downtime swap posture.
- Advisory `phase105-e2e` CI lane with real Postgres, Meilisearch, Playwright, health checks, and failure artifacts.

**v1.29 Phase 106 — Fan-Out Reflection Contract Repair** completed on **2026-05-31**.

**What shipped:**
- Ordinary schemas using `use Scrypath, fan_outs:` expose generated `__scrypath__(:fan_outs)` metadata.
- Existing hand-written owner-only fan-out reflection remains compatible.
- Inline and Oban related-sync paths have service-free regression proof through `mix verify.phase106`.

**v1.29 Phase 107 — Ecommerce Readiness Regression Guard** completed on **2026-05-31**.

**What shipped:**
- `/dev/e2e/search-visible` preserves `tenant_id` while applying category readiness filtering.
- A backend-stubbed Phoenix controller regression proves the resulting `%Scrypath.Query.filter` contains both `tenant_id` and `category_id`.
- `mix verify.phase107` provides a focused, service-free contributor gate without promoting `phase105-e2e` or changing CI topology.

**v1.29 Phase 108 — Truth Alignment and Closeout Proof** completed on **2026-05-31**.

**What shipped:**
- Related-data guidance now presents `use Scrypath, fan_outs:` as the ordinary searchable-schema path and keeps hand-written owner-only reflection as a supported low-level escape hatch.
- `mix verify.phase108` provides a focused, service-free closeout proof for bounded truth surfaces.
- Roadmap, requirements, project, and JTBD truth now close v1.29 as repaired contract work and return the repo to maintenance-and-evidence mode.

**v1.27 — Adopter Contract Hardening** shipped + archived in-repo on **2026-05-30** across phases **97–101**.

**What shipped:**
- Canonical contract freeze and scope guard authority.
- Reconciled fast/live proof boundaries across support guides and intake evidence.
- Deterministic CI tuple parity checks and compatibility authority alignment.
- Maintained required-gate stability (`main-ci`, `repo-hygiene`, `release-truth`, `phase99-trust`).

<details>
<summary>Archived milestones</summary>

**v1.26 — Facet Value Vocabulary Search** shipped + archived in-repo on **2026-05-26** across phases **95–96**.

**What shipped:**
- **`Scrypath.search_facet_values/4`** — first-class function for high-cardinality facet search.
- **`Scrypath.FacetSearchResult`** — idiomatic Elixir response struct.
- **LiveView examples** — concrete type-ahead patterns in ExDoc.
- **Verification Gate** — `mix verify.phase96` covering all facet-UX surfaces.

**v1.25 — Tenant-Safe Search Access** shipped + archived in-repo on **2026-05-26** across phases **92–94**.

**What shipped:**
- **Canonical Multitenancy Guide** — `guides/multitenancy.md` with shared-index model, explicit tenant parameter pattern, and filter merge order warnings.
- **Schema Declaration & Reflection** — `tenant_field:` option in `use Scrypath` and `schema_capabilities/1` surfacing `%{tenant: :field_name}`.
- **Runtime Safety & Query Execution** — Immutable filter merging logic enforcing `tenant_id = X AND (user_filters)` and `tenant_scope:` hard-injection on `Scrypath.search/3`.
- **Verification Gate** — `mix verify.phase94` covering all tenant-safety surfaces.

</details>

**The library scope remains effectively complete for its stated mission.** v1.32 is not runtime breadth; it is a bounded UI polish/design-system wedge for the existing operator/admin proof surface. Future work should still focus on maintenance, bug fixes, release-train stability, proof stability, and outside-adopter evidence. Do not keep extending the roadmap just because additional polish is imaginable.

**Release-train posture:** keep `main` green on lean merge gates, ship patch-first while pre-1.0, and land serious milestone work through PRs rather than direct `main` development.

**Unified operating lanes:**
- **Maintenance lane (default):** release follow-through, support/docs truth, outside-adopter evidence loop, and planning-truth reconciliation while `main` stays green.
- **Silence lane:** when there is no release follow-through, support/proof drift, production bug, or outside-adopter evidence, do not manufacture a milestone. Say the release train is idle.
- **Feature lane (evidence-gated):** reopen only as PR-scoped milestone work when a concrete bug, reviewed outside-adopter evidence, or explicit strategic wedge justifies it; merge only after PR CI is green and scope remains bounded to the approved wedge.

**Boundary discipline retained:** Scrypath remains framework-agnostic at the view layer.

**Out of scope remains:** public `%Scrypath.Query{}` or other internal structs as semver-stable API, schema-generated runtime search APIs, Phoenix-dependent runtime core, reusable UI widgets or form-builder layers, automatic Ecto association walking, or any change that hides operational search semantics behind framework magic.

The public website launch surface now exists under `website/` and is deployed to GitHub Pages as a companion front door, not a HexDocs replacement.

Current planning files: **`.planning/{ROADMAP,STATE}.md`** plus archives under **`.planning/milestones/`**.

## Next Milestone Goals

- **Active lane:** none.
- **Goal:** Keep the release train idle unless maintenance, support truth, proof drift, production bug evidence, outside-adopter evidence, or an explicit strategic wedge justifies new scope.
- **Potential targets:** release follow-through, support/readiness truth, outside-adopter evidence, and proof stability.
- **Feature lane remains evidence-gated:** autocomplete/suggestions, broader OPSUI productization, tenant-token helpers, multi-backend, vector/hybrid, and new UI surfaces still require reviewed outside-adopter evidence or a concrete production bug.
- **Done-ness posture:** the stated v1 library scope is effectively done; future milestone discovery should not re-litigate this unless new evidence changes it.

## Last shipped milestone

**v1.33 — Admin UI Insane Polish** (shipped + archived in-repo **2026-06-03**). Owner-initiated next-level admin-UI polish wedge: task-first IA (Recover/Explore nav + front-door), design-system tightening for compounding reuse, restrained brand motion, per-screen polish, and shell coherence — see **`milestones/v1.33-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.32 — Admin UI/UX Design System Cleanup** (shipped + archived in-repo **2026-06-01**). Bounded existing-admin polish wedge for ScrypathOps tokens, shared operator primitives, mounted `/admin/search/*` asset contract, and screen cleanup — see **`milestones/v1.32-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Last shipped milestone:** **v1.31 — Adoption Evidence Demo Hardening** (UAT passed **2026-06-01**). Bounded strategic proof wedge for realistic demo app DX, deterministic browser evidence, docs, and closeout.

**Prior:** **v1.30 — Release Trust and Evidence Maintenance** (shipped + archived in-repo **2026-06-01**). Delivered release/package truth hardening, support intake routing, advisory proof stability policy, and public website/docs truth alignment while keeping product scope closed — see **`milestones/v1.30-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.29 — Contract Repair and Proof Hardening** (shipped + archived in-repo **2026-05-31**). Delivered generated fan-out reflection repair, tenant-preserving ecommerce readiness regression proof, and aligned roadmap/JTBD truth while keeping `phase105-e2e` advisory — see **`milestones/v1.29-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.28 — Realistic Demo App & Admin UI Proof** (shipped + archived in-repo **2026-05-31**). Delivered the mountable admin UI engine, multi-tenant e-commerce example, storefront/operator E2E proof, and advisory real-services CI lane — see **`milestones/v1.28-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.27 — Adopter Contract Hardening** (shipped + archived in-repo **2026-05-30**) — **`milestones/v1.27-{ROADMAP,REQUIREMENTS}.md`**.

**Prior:** **v1.26 — Facet Value Vocabulary Search** (shipped + archived in-repo **2026-05-26**) — **`milestones/v1.26-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.25 — Tenant-Safe Search Access** (shipped + archived in-repo **2026-05-26**) — **`milestones/v1.25-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.24 — Related-Data and Dependency Propagation** (shipped + archived in-repo **2026-05-25**) — **`milestones/v1.24-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

## Planning window

**Active milestone:** none. The release train is idle after v1.33 archive.

## Requirements

### Validated

- [x] **v1.33** (2026-06-03): **HARNESS-01**, **SEED-01**, **AUDIT-01**, **TOKEN-01**, **COMP-01**, **MOTION-01**, **IA-01**, **COPY-01**, **RECOVER-01**, **EXPLORE-01**, **SHELL-01**, **VERIFY-01** — task-first admin-UI IA (Recover/Explore nav + front-door), design-system tightening, restrained micro-animation, per-screen polish, and shell coherence; screenshot-driven audit + 40-shot matrix; live admin smoke green in CI.
- [x] **v1.32** (2026-06-01): **ASSET-01**, **TOKEN-01**, **BRAND-01**, **COMP-01**, **A11Y-01**, **SCREEN-01**, **SCREEN-02**, **VERIFY-01** — mounted admin asset contract, Scrypath operator tokens, shared LiveView primitives, screen hierarchy cleanup, and focused verification.
- [x] **v1.31** (2026-06-01): **DEMO-01**–**DEMO-02**, **E2E-01**–**E2E-03**, **DX-01**, **DOC-01**, **OPS-01**, **CLOSE-01** — realistic seeded demo, deterministic advisory E2E proof, Docker/dev DX, documentation, ops UI clarity, and maintainer closeout.
- [x] **v1.30** (2026-06-01): **REL-01**–**REL-03**, **SUP-01**–**SUP-02**, **STAB-01**–**STAB-02**, **WEB-01**–**WEB-02**, **SCOPE-01** — release/package truth, support intake evidence routing, advisory proof stability, and website/docs claim alignment.
- [x] **Phase 106** (2026-05-31): **FAN-01**–**FAN-02** — generated fan-out reflection for ordinary `use Scrypath, fan_outs:` schemas and compatibility for hand-written owner reflection, verified by `mix verify.phase106`.
- [x] **Phase 107** (2026-05-31): **E2E-01** — ecommerce readiness probes preserve tenant scope when category filtering is present, verified by `mix verify.phase107`.
- [x] **Phase 108** (2026-05-31): **TRUTH-01** — related-data docs and planning/JTBD truth describe the repaired contract and keep deferred breadth out of v1.29, verified by `mix verify.phase108`.
- [x] **Phase 103** (2026-05-30): **APP-01**–**APP-03** — Demo App Foundation (e-commerce, multi-tenant)
- [x] **v1.28** (2026-05-31): **OPS-01**–**OPS-02**, **APP-01**–**APP-03**, **INT-01**–**INT-04**, **E2E-01**–**E2E-06** — mountable admin UI engine, multi-tenant e-commerce example, storefront/operator E2E proof, and advisory real-services CI lane.
- [x] **v1.27** (2026-05-30): Adopter Contract Hardening — requirements TRUTH-01–TRUTH-03, PROOF-01–PROOF-03, SUP-01–SUP-02, TEST-01–TEST-03, GATE-01–GATE-02, SCOPE-01.
- [x] **v1.26** (2026-05-26): **FACET-UX-01**–**FACET-UX-03**, **DOC-01**–**DOC-02**, **TEST-01**–**TEST-02** — `search_facet_values/4`, response parsing, LiveView examples, and `mix verify.phase96` gate.
- [x] **v1.25** (2026-05-26): **TNNT-01**–**TNNT-05** — Multitenancy guide, `tenant_field:` declaration, `tenant_scope:` runtime safety, and `mix verify.phase94` gate.
- [x] **v1.24** (2026-05-25): **DATA-01**–**DATA-03**, **EXEC-01**–**EXEC-02**, **TEST-01**–**TEST-02** — `Scrypath.sync_related/3` public API, `RelatedWorker` actionable error returns, canonical related-data guide rewrite, `mix verify.phase91` hermetic gate, and Phoenix fan-out example.
- [x] **v1.23** (2026-05-24): **TRUTH-01**–**TRUTH-03**, **ADOPT-01**–**ADOPT-03**, **FIX-01**–**FIX-02** — support truth and proof surfaces reconciled, outside-adopter intake reviewed, evidence-backed papercuts closed with regression guards.
- [x] **v1.22** (2026-05-24): **CMP-01**–**CMP-04**, **META-01**–**META-03**, **MSCH-01**–**MSCH-02**, **DOC-01**, **DOC-02**, **VRFY-01** — public plain-data composition, declaration-backed metadata reflection, `search_many/2` lowering parity, canonical real-app guidance, and focused drift-gate verification.
- [x] **v1.21** (2026-05-23): **QTK-01**–**QTK-04**, **PHX-01**–**PHX-02**, **DOC-01**, **VRFY-01** — public plain-data query toolkit, structured edge errors, optional Phoenix wrappers, canonical request-edge docs, and focused drift-gate verification.
- [x] **v1.20** (2026-05-08): **SMOD-01**–**SMOD-08** — archive-corrected historical record of Search Module Foundation. `Scrypath.SearchModule` is not present on current branch tip and is not treated as shipped surface.
- [x] **v1.19** (2026-04-28): **PRDY-01**–**PRDY-08** — canonical readiness contract, defended fast/live proof family, production-shaped Phoenix + Sigra example coverage, bounded adopter-intake path, one evidence-backed papercut fix, and a readiness-checkpoint close.
- [x] **v1.17 — Integration confidence & adopter proof** (2026-04-23) — phases **68–70**; **INTG-01**–**INTG-06**.
- [x] **v1.16 — Playbook execution & operator honesty** (2026-04-22) — phases **65–67**; **OPS3-01**–**OPS3-06**.
- [x] **v1.15 milestone** (2026-04-22): OPSUI second slice — phases **62–64**.
- [x] **v1.14 milestone** (2026-04-22): Evidence-led **B1** QoL + **`scrypath_ops`** operator playbooks — phases **57–61**.
- [x] **Phase 57** (2026-04-22): **EVID-01** B1 evidence ledger, **LIB-01..03** triage, contributor gates.
- [x] **Phase 58** (2026-04-22): Core library + doc QoL **LIB-01..03**.
- [x] **Phase 59** (2026-04-22): Operator playbook **`playbook_format` 1**.
- [x] **Phase 60** (2026-04-22): **`/ops/playbooks`**.
- [x] **Phase 61** (2026-04-22): **`PlaybookLive`** stub tests, **`mix verify.opsui`**, **SHIP-01** planning alignment.
- [x] **v1.13** (2026-04-22): Public polish & narrative coherence — phases **54–56** — **POLISH-01**–**POLISH-05**.
- [x] **Phase 51** (2026-04-21): Adoption path truth and discoverability.
- [x] **Phase 52** (2026-04-22): Actionable **`{:error, _}`** surfaces + **`Scrypath.Search.Error`** bang helpers.
- [x] **Phase 53** (2026-04-22): Contributor **`mix verify.opsui`** spine.
- [x] **v1.11 milestone** (2026-04-21): Operator shell polish — phases **48–50**.
- [x] **v1.10 milestone** (2026-04-21): Operator admin UI (OPSUI) — phases **44–47**.
- [x] **Phase 42** (2026-04-20): **`guides/per-query-tuning-pipeline.md`** + discoverability.
- [x] **Phase 43** (2026-04-20): **Per-query runtime**.
- [x] **v1.9 milestone** (2026-04-20): Per-query pipeline + runtime — phases **42–43**.
- [x] **v1.6 milestone** (2026-04-19): Adoption-grade integration and trust — phases **29–35** archived; **`milestones/v1.6-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**; requirements **ADPT-***, **EXAM-***, **VRFY-***, **AUDT-01** satisfied per audit.
- [x] **Phase 32** (2026-04-18): **`STATE.md`** deferred-row triage (**AUDT-01**) with terminal statuses.
- [x] **Phase 33** (2026-04-18): Root-facing **README** / **CONTRIBUTING** / **`guides/golden-path.md`** agree on **cwd** for Phoenix example **`scripts/smoke.sh`**; **`docs_contract_test.exs`** locks filesystem + ordering — **ADPT-01**, **EXAM-02**, **VRFY-02**, **AUDT-01**.
- [x] **Phase 36** (2026-04-19): **Hierarchical facets**.
- [x] **Phase 37** (2026-04-20): **Disjunctive facet counts**.
- [x] **Phase 38** (2026-04-20): **`search_within_facet/4`** + telemetry metadata.
- [x] **Phase 39** (2026-04-20): **`federation_weight:`** + quad entries.
- [x] **Phase 40** (2026-04-20): **`{:all, …}`** expansion.
- [x] **Phase 41** (2026-04-20): Federation docs + **`docs_contract_test.exs`** anchors.
- [x] **v1.8 milestone** (2026-04-20): Multi-index federation — phases **39–41**.
- [x] **v1.6 milestone** (2026-04-19): Adoption-grade integration and trust — phases **29–35**.
- [x] **Phase 29** (2026-04-18): **`guides/golden-path.md`**.
- [x] **Phase 33** (2026-04-18): Root-facing **README** / **CONTRIBUTING** / **`guides/golden-path.md`** agree on **cwd**.
- [x] **Phase 34** (2026-04-19): README **Quick Path** ↔ **`guides/golden-path.md`**.
- [x] **Phase 35** (2026-04-19): **`guides/sync-modes-and-visibility.md`** **Operator lifecycle**.
- [x] **Phase 30** (2026-04-18): Consumer-shaped **Oban** sync proof.
- [x] **Phase 31** (2026-04-18): CONTRIBUTING verify ↔ guarantee matrix.
- [x] **Phase 32** (2026-04-18): **`STATE.md`** deferred-row triage.
- [x] **v1.5** (2026-04-18): **Phases 27–28** — index contract drift.
- [x] **v1.4** (2026-04-17): Hex **`scrypath 0.3.1`**, `hot_apply/3`, failure rollups.
- [x] **v1.3** (2026-04-17): Search power, release-parity gates, v1.2 closure.
- [x] v1.2 Nyquist validation debt (phases 13–15 evidence) closed in v1.3.
- [x] The first real public release path, operator visibility surface, Mix task ergonomics, and the internal operations seam validated in v1.2.
- [x] Launch-readiness hardening, docs-safety fixes, and milestone-close release evidence validated in v1.1.
- [x] Schema metadata declarations, projection, runtime reflection, and the internal backend seam validated in v1.0.
- [x] Meilisearch-backed sync for insert, update, delete, inline, manual, and Oban-backed workflows validated in v1.0.
- [x] Common search, validated filter/sort/page handling, raw-hit access, and explicit hydration validated in v1.0.
- [x] Backfill, managed reindex, settings application, and recovery guidance validated in v1.0.
- [x] Phoenix docs, examples, release automation, and package trust signals validated in v1.0.

### Active

<!-- Current scope. Building toward these. -->

No active feature or repair requirements. The default lane is idle maintenance-and-evidence mode: release/support truth, proof stability, public claim drift, and outside-adopter evidence only when concrete signal appears.

### Out of Scope

- Postgres-native full-text search as a first-class v1 product surface - it muddies the product boundary and competes with a different problem space.
- Public multi-backend support before real adoption pressure proves the common contract deserves to widen.
- Advanced relevance features such as vector search, hybrid retrieval, personalization, or analytics before the operational core and public release story settle.
- Public `%Scrypath.Query{}` or other internal normalization structs as semver-stable contract - that would freeze implementation detail too early and raise API-regret risk.
- Schema-generated runtime search verbs, controller/LiveView macros, or any helper that turns Scrypath into a framework façade - contexts must remain the application boundary.
- Reusable UI widgets, search-page scaffolds, or broader composition/preset systems - those belong to future potential wedges, not the core mission.

## Context

The project exists to fill a gap in the Elixir ecosystem: there are low-level API clients and partial integrations for search engines, but no category-defining library that gives Ecto and Phoenix developers a Searchkick or Laravel Scout level experience. The strongest initial wedge is Meilisearch because the Elixir ecosystem gap is larger there than for Typesense, while the long-term architecture should still preserve an internal adapter seam so the public API is not painted into a corner.

Scrypath is intended primarily for Phoenix applications using Ecto, with Ecto-first APIs and Phoenix-friendly features layered on top. The library emphasizes least surprise, operational honesty, and high-quality developer experience. Search synchronization acknowledges eventual consistency where it exists, supports Oban naturally, and documents tradeoffs clearly in README and guides so users understand who the library is for and who it is not for.

The repository has shipped planning milestones through **`v1.32`** (**`v1.0`**–**`v1.32`**). Current planning truth lives in **`.planning/ROADMAP.md`**, **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, **`.planning/STATE.md`**, and **`milestones/v*-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`** for shipped arcs.

## Evolution

This document evolves at milestone boundaries.

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-06-01 — v1.32 admin UI/UX design-system cleanup completed*
