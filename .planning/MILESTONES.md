# Milestones

## v1.24 Related-Data and Dependency Propagation (Shipped + archived: 2026-05-25)

**Phases completed:** **3** (**89–91**), **9** plans, **7** requirements (**DATA-01**–**DATA-03**, **EXEC-01**–**EXEC-02**, **TEST-01**–**TEST-02**)

**Hex:** **`scrypath 0.3.4`** on Hex; **in-repo milestone close only** — no dedicated Hex bump claimed for this planning milestone.

**Key accomplishments:**

- `Scrypath.sync_related/3` public API with `fan_outs:` metadata validation, inline execution mode, and `RelatedWorker.enqueue/4` for Oban fan-out — eliminating the prior "temporary workaround" pattern — **Phase 89**
- `RelatedWorker.perform/1` actionable error decision matrix: HTTP 4xx → `{:cancel, _}` (permanent), 5xx/generic → `{:error, _}` (transient retry), invalid args → `{:cancel, {:invalid_job, reason}}`; full test coverage for every branch — **Phase 90**
- `guides/related-data-and-reindexing.md` rewritten with `sync_related/3` as canonical; inline vs Oban mapped to blast radius + latency; `mix verify.phase91` hermetic gate (73 tests, 0 failures); Phoenix example with Author/Post fan-out smoke tests (inline + Oban) — **Phase 91**

**Milestone audit:** ✅ Passed — 7/7 requirements, 3/3 phases, 12/12 cross-phase connections, 3/3 E2E flows — see `milestones/v1.24-MILESTONE-AUDIT.md`

**Archives:** `milestones/v1.24-ROADMAP.md`, `milestones/v1.24-REQUIREMENTS.md`, `milestones/v1.24-MILESTONE-AUDIT.md` · **Git tag:** `v1.24` (planning milestone marker)

---

## v1.23 Outside-Adopter Evidence And Support-Truth Reconciliation (Shipped + archived: 2026-05-24)

**Phases completed:** **3** (**86–88**), **8** requirements (**TRUTH-01**–**TRUTH-03**, **ADOPT-01**–**ADOPT-03**, **FIX-01**–**FIX-02**)

**Hex:** **`scrypath 0.3.4`** on Hex; **in-repo milestone close only** — no dedicated Hex bump claimed for this planning milestone.

**Key accomplishments:**

- Support truth and proof surfaces reconciled to ensure README, CONTRIBUTING, guides, and proof paths match the current tree truth without relying on removed docs or stale claims — **Phase 86**
- Real outside-adopter intake path refreshed and reviewed against evidence; repo clone boundaries, example assumptions, and support scope for the core library explicitly established — **Phase 87**
- Evidence-backed papercuts fixed with regression guards; rolled the active milestone out with a locked verdict (related-data propagation is the next major product wedge) — **Phase 88**

**Pre-close audit:** Passed via `verify-before-complete` principles (no formal `v1.23-MILESTONE-AUDIT.md` produced since it was an evidence/reconciliation sprint).

**Automation note:** `gsd-sdk query milestone.complete` remained unavailable for this repo, so the `v1.23-*` archive files and rolling planning updates were completed manually.

**Archives:** `milestones/v1.23-ROADMAP.md`, `milestones/v1.23-REQUIREMENTS.md` · **Git tag:** `v1.23` (planning milestone marker)

---

## v1.22 Composition And Real-App Depth (Shipped + archived: 2026-05-24)

**Phases completed:** **3** (**83–85**), **12** requirements (**CMP-01**–**CMP-04**, **META-01**–**META-03**, **MSCH-01**–**MSCH-02**, **DOC-01**, **DOC-02**, **VRFY-01**)

**Hex:** **`scrypath 0.3.4`** on Hex; **in-repo milestone close only** — no dedicated Hex bump claimed for this planning milestone.

**Key accomplishments:**

- Public `Scrypath.Composition` plain-data seam with deterministic preset/scope merging, explicit fixed conflicts, stable visibility buckets, and a focused `mix verify.phase83` contract gate — **Phase 83**
- Declaration-backed `Scrypath.Metadata` capability/reflection surface plus `compose_many/2` lowering over the existing `search_many/2` tuple/shared-option contract — **Phase 84**
- One canonical real-app composition guide, aligned single-schema and multi-schema proof guides, and a focused `mix verify.phase85` drift gate for the public story — **Phase 85**

**Pre-close audit:** **`milestones/v1.22-MILESTONE-AUDIT.md`** (**`passed`** — `requirements: 12/12`, `phases: 3/3`, `integration: 4/4`, `flows: 3/3`, `nyquist: compliant`).

**Automation note:** `gsd-sdk query milestone.complete` remained unavailable for this repo, so the `v1.22-*` archive trio and rolling planning updates were completed manually.

**Archives:** `milestones/v1.22-ROADMAP.md`, `milestones/v1.22-REQUIREMENTS.md`, `milestones/v1.22-MILESTONE-AUDIT.md` · **Git tag:** `v1.22` (planning milestone marker)

---

## v1.21 Query Toolkit And Phoenix Edge Helpers (Shipped + archived: 2026-05-23)

**Phases completed:** **3** (**80–82**), **8** requirements (**QTK-01**–**QTK-04**, **PHX-01**–**PHX-02**, **DOC-01**, **VRFY-01**)

**Hex:** **`scrypath 0.3.4`** on Hex; **in-repo milestone close only** — no dedicated Hex bump claimed for this planning milestone.

**Key accomplishments:**

- Public `Scrypath.QueryParams` plain-data contract plus runtime and Meilisearch payload parity over the canonical `Scrypath.search/3` path, without exposing internal query structs or creating a second runtime — **Phase 80**
- One-time request-edge normalization, structured field-scoped errors, and optional pure `Scrypath.Phoenix` wrappers for controller, URL, form, and LiveView flows while keeping contexts canonical — **Phase 81**
- One canonical request-edge guide, Phoenix-guide rewrites, example/runbook alignment, and a focused `mix verify.phase82` drift gate wired into CI and contributor guidance — **Phase 82**

**Pre-close audit:** **`milestones/v1.21-MILESTONE-AUDIT.md`** (**`passed`** — `requirements: 8/8`, `phases: 3/3`, `integration: 8/8`, `flows: 3/3`, `nyquist: compliant`).

**Automation note:** `gsd-sdk query milestone.complete` remained unavailable for this repo, so the `v1.21-*` archive trio and rolling planning updates were completed manually.

**Archives:** `milestones/v1.21-ROADMAP.md`, `milestones/v1.21-REQUIREMENTS.md`, `milestones/v1.21-MILESTONE-AUDIT.md` · **Git tag:** `v1.21` (planning milestone marker)

---

## v1.20 Search Module Foundation (Shipped + archived: 2026-05-08)

Historical note: the `v1.20` archive records milestone-close `Scrypath.SearchModule` claims, but the current checked-out branch tip does not expose that layer, its guide, or its tests. Treat the bullets below as archive history, not present-day shipped surface.

**Phases completed:** **3** (**77–79**), **8** requirements (**SMOD-01**–**SMOD-08**)

**Hex:** **`scrypath 0.3.4`** on Hex; **in-repo milestone close only** — no dedicated Hex bump claimed for this planning milestone.

**Key accomplishments:**

- The archive records a context-owned `Scrypath.SearchModule` declaration layer with `search/2`, `search!/2`, and `search_args/2` over the existing `Scrypath.search/3` runtime, while keeping schemas metadata-only and merge precedence explicit (**SMOD-01**–**SMOD-03**) — **Phase 77**
- The archive records browser-shaped param normalization for text, filters, sort, page, facets, and facet filters, with structured `Scrypath.SearchModule.ParamError` entries (**SMOD-04**–**SMOD-06**) — **Phase 78**
- The archive records one canonical search-module guide, README / overview / moduledoc / Phoenix guide routing, and bounded doc-contract plus thin-parity regression coverage (**SMOD-07**, **SMOD-08**) — **Phase 79**

**Pre-close audit:** **`milestones/v1.20-MILESTONE-AUDIT.md`** (**`passed`** — `requirements: 8/8`, `phases: 3/3`, `integration: 8/8`, `flows: 4/4`, `nyquist: compliant`).

**Automation note:** `gsd-sdk query milestone.complete` remained unavailable for this repo, so the `v1.20-*` archive trio and rolling planning updates were completed manually.

**Archives:** `milestones/v1.20-ROADMAP.md`, `milestones/v1.20-REQUIREMENTS.md`, `milestones/v1.20-MILESTONE-AUDIT.md` · **Git tag:** `v1.20` (planning milestone marker)

---

## v1.18 Sigra integration (Shipped + archived: 2026-04-27)

**Phases completed:** **3** (**71–73**), **10** requirements (**SIGRA-01**–**SIGRA-10**)

**Hex:** **`scrypath 0.3.4`** on Hex; **in-repo only** — `scrypath_ops` is path-loaded and not Hex-published. **No Hex bump claimed for this planning milestone.**

**Key accomplishments:**

- Optional Sigra dependency boundary, auth allowlist, compile guards, operator context contract, mount hook, and sensitive-action gate in Phase 71 (**SIGRA-01**–**SIGRA-05**, **SIGRA-07**, **SIGRA-08**).
- Four sensitive OPSUI LiveView handlers wired through `gate_sensitive_action/3` while preserving the ungated async playbook paths in Phase 72 (**SIGRA-06**).
- Canonical Sigra guide, working Phoenix example, and CI smoke proof in Phase 73 (**SIGRA-09**, **SIGRA-10**).

**Pre-close audit:** **`milestones/v1.18-MILESTONE-AUDIT.md`** (**`passed`** — `requirements: 10/10`, `phases: 3/3`, `integration: 3/3`, `flows: 4/4`).

**Automation note:** `gsd-sdk query milestone.complete` remained unavailable for this close path, so the `v1.18-*` archive trio and rolling planning updates were completed manually.

**Archives:** `milestones/v1.18-ROADMAP.md`, `milestones/v1.18-REQUIREMENTS.md`, `milestones/v1.18-MILESTONE-AUDIT.md` · **Git tag:** `v1.18` (planning milestone marker)

---

## v1.17 Integration confidence & adopter proof (Shipped + archived: 2026-04-23)

**Phases completed:** **3** (**68–70**), **6** requirements (**INTG-01**–**INTG-06**)

**Hex:** **`scrypath 0.3.4`** on Hex; **in-repo readiness checkpoint; Hex publish tracked separately** — no dedicated Hex bump claimed for this planning milestone.

**Key accomplishments:**

- Canonical Phoenix adopter proof: **`examples/phoenix_meilisearch/`** covers **`:inline`**, **`:manual`**, and **`:oban`** plus the support / compatibility contract, with bounded docs-contract coverage so README / CONTRIBUTING / guides / example wayfinding cannot drift (**INTG-01**, **INTG-03**, **INTG-04**) — **Phase 68**
- Maintainer-facing **`mix verify.adopter`** spine with documented fast-vs-live modes, README / CONTRIBUTING / example README / docs contracts / CI all aligned to it (**INTG-02**) — **Phase 69**
- Exactly three bounded adopter-friction papercuts closed with regression / contract / example assertions, plus rolling planning truth and frozen **`v1.17-*`** archive trio with an explicit *outside-integration-feedback-next* verdict (**INTG-05**, **INTG-06**) — **Phase 70**

**Pre-close audit:** **`milestones/v1.17-MILESTONE-AUDIT.md`** (**`passed`** — `requirements: 6/6`, `phases: 3/3`, `integration: 4/4`, `flows: 4/4`, `nyquist: compliant`, `outside_feedback_next: true`).

**Automation note:** **`gsd-sdk query milestone.complete`** remained unavailable for this repo, so **`milestones/v1.17-*`** and rolling-file updates were completed manually.

**Archives:** `milestones/v1.17-ROADMAP.md`, `milestones/v1.17-REQUIREMENTS.md`, `milestones/v1.17-MILESTONE-AUDIT.md` · **Git tag:** `v1.17` (planning milestone marker)

---

## v1.16 Playbook execution & operator honesty (Shipped + archived: 2026-04-22)

**Phases completed:** **3** (**65–67**), **6** requirements (**OPS3-01**–**OPS3-06**)

**Hex:** **`scrypath 0.3.4`** on Hex; **in-repo milestone; Hex publish tracked separately** — no dedicated Hex bump claimed for this planning milestone.

**Key accomplishments:**

- Explicit saved-playbook run lifecycle plus structured failure surfaces with canonical doc links (**OPS3-01**, **OPS3-02**) — **Phase 65**
- Runner/library contract parity, raw-reason preservation, and representative regression coverage (**OPS3-03**) — **Phase 66**
- Bounded execution/doc contracts, canonical JTBD fixtures, and truthful `v1.16-*` milestone bookkeeping (**OPS3-04**–**OPS3-06**) — **Phase 67**

**Pre-close audit:** **`milestones/v1.16-MILESTONE-AUDIT.md`** (**`passed`**).

**Automation note:** **`gsd-sdk query milestone.complete`** remains unavailable for this repo, so **`milestones/v1.16-*`** and rolling-file updates were completed manually.

**Archives:** `milestones/v1.16-ROADMAP.md`, `milestones/v1.16-REQUIREMENTS.md`, `milestones/v1.16-MILESTONE-AUDIT.md` · **Git tag:** `v1.16` (planning milestone marker)

---

## v1.15 OPSUI second slice (Shipped + archived: 2026-04-22)

**Phases completed:** **3** (**62–64**), **8** requirements (**OPS2-01**–**OPS2-08**)

**Hex:** **`scrypath 0.3.4`** (matches root **`mix.exs`** **`@version`** at close); **in-repo milestone; Hex publish tracked separately** — no dedicated Hex bump claimed for this planning milestone.

**Key accomplishments:**

- Playground → playbook capture, catalog rename/duplicate/metadata (**OPS2-01**–**OPS2-03**) — **Phase 62**
- Team workspace authority, **`mix scrypath_ops.playbooks.validate`**, examples + security posture (**OPS2-04**, **OPS2-07**) — **Phase 63**
- **`operator-ia.md`** persistence pointers, **`mix verify.opsui`** + doc contracts including **`mix scrypath_ops.playbooks.validate`**, **`guides/meilisearch-operations.md`** restoration, frozen **`v1.15-*`** trio (**OPS2-05**, **OPS2-06**, **OPS2-08**) — **Phase 64**

**Pre-close audit:** **`milestones/v1.15-MILESTONE-AUDIT.md`** (**`passed`**).

**Automation note:** **`gsd-sdk query milestone.complete`** failed again (**`version required for phases archive`**), so **`milestones/v1.15-*`**, **`ROADMAP`** collapse, and rolling **`REQUIREMENTS.md`** updates were **manual** (same pattern as **v1.10–v1.14**).

**Archives:** `milestones/v1.15-ROADMAP.md`, `milestones/v1.15-REQUIREMENTS.md`, `milestones/v1.15-MILESTONE-AUDIT.md` · **Git tag:** `v1.15` (planning milestone marker)

---

## v1.14 Library QoL and operator playbooks (Shipped + archived: 2026-04-22)

**Phases completed:** **5** (**57–61**), **10** requirements (**EVID-01**, **LIB-01**–**LIB-03**, **OPS-PB-01**–**OPS-PB-05**, **SHIP-01**)

**Hex:** **`scrypath 0.3.4`** (B1 QoL + **`scrypath_ops`** playbooks in-repo; no mandated Hex bump for this planning milestone)

**Key accomplishments:**

- **EVID-01** frozen B1 evidence ledger + contributor gates (**PR template**, **CODEOWNERS**) — **Phase 57**
- **`Scrypath.Errors`** + doc hops + **`Query`** boundary clarity + **`docs_contract_test`** anchors — **LIB-01**–**LIB-03** / **Phase 58**
- **`ScrypathOps.Playbook.V1`** + **`playbook-schema-v1.md`** + portable JSON export/import — **OPS-PB-01**, **OPS-PB-03** / **Phase 59**
- **`/ops/playbooks`** LiveView + **`Playbook.Store`** / **`Runner`** + **`SCRYPATH_OPS_PLAYBOOK_DIR`** + IA contract — **OPS-PB-02**, **OPS-PB-04** / **Phase 60**
- Stub-backed **`PlaybookLive`** save/list/load/run tests + **`mix verify.opsui`** + **SHIP-01** alignment — **OPS-PB-05**, **SHIP-01** / **Phase 61**

**Pre-close audit:** **`audit-open`** cleared at milestone close. Formal milestone audit: **`milestones/v1.14-MILESTONE-AUDIT.md`** (**`tech_debt`** — traceability / copy / Nyquist hygiene; see audit YAML for residual items).

**Automation note:** **`gsd-sdk query milestone.complete`** failed again (**`version required for phases archive`**), so **`milestones/v1.14-*`**, **`ROADMAP`** collapse, and **`git rm` REQUIREMENTS** were **manual** (same pattern as **v1.10–v1.13**).

**Archives:** `milestones/v1.14-ROADMAP.md`, `milestones/v1.14-REQUIREMENTS.md`, `milestones/v1.14-MILESTONE-AUDIT.md` · **Git tag:** `v1.14` (planning milestone marker)

---

## v1.13 Public polish & narrative coherence (Shipped + archived: 2026-04-22)

**Phases completed:** **3** (**54–56**), **5** requirements (**POLISH-01**–**POLISH-05**)

**Hex:** **`scrypath 0.3.4`** on Hex at close; root **`mix.exs`** **`@version`** matches. **No** new Hex publish required for this planning milestone.

**Key accomplishments:**

- **`guides/per-query-tuning-pipeline.md`** — product/API language; no internal “Phase N” identifiers in **`guides/`** prose — **POLISH-01**, **POLISH-05**
- Planning + **README** version narrative aligned to **0.3.4** / **hex.pm** — **POLISH-02**
- **`AGENTS.md`** contributor-first workflow; **`milestone-candidates.md`** refreshed (**Tier A** marked shipped, **B1** next) — **POLISH-03**, **POLISH-04**

**Pre-close audit:** **`audit-open`** cleared at milestone close. No formal **`milestones/v1.13-MILESTONE-AUDIT.md`**.

**Archives:** `milestones/v1.13-ROADMAP.md`, `milestones/v1.13-REQUIREMENTS.md` · **Git tag:** `v1.13` (planning milestone marker)

**Automation note:** **`gsd-sdk query milestone.complete`** failed again (**`version required for phases archive`**), so **`milestones/v1.13-*`**, **`ROADMAP`** collapse, and **`git rm` REQUIREMENTS** were **manual** (same pattern as **v1.10–v1.12**).

---

## v1.12 Developer onboarding & first-hour QoL (Shipped + archived: 2026-04-21)

**Phases completed:** 3 phases (**51–53**), **9** plans

**Hex:** **`scrypath 0.3.3`** (onboarding + contributor **`mix verify.opsui`** spine in-repo; no mandated Hex bump in this planning milestone)

**Key accomplishments:**

- README / **`guides/golden-path.md`** / **CONTRIBUTING** / example + CI wiring locked with **`docs_contract_test`** — **ONBD-01**..**ONBD-03**
- Actionable **`{:error, _}`** surfaces, **`guides/common-mistakes.md`**, **`Scrypath`** lobby **`@moduledoc`** and **`mix scrypath.*`** read-next links — **ONBD-04**..**ONBD-06**
- Root **`mix verify.opsui`** with README / **CONTRIBUTING** / CI contract coverage — **VRFY-03**, **VRFY-04**

**Pre-close audit:** **`audit-open`** cleared after adding canonical **`SUMMARY.md`** under each legacy **`.planning/quick/`** task directory (scanner expected **`SUMMARY.md`**; completed work lived in **`260416-*-SUMMARY.md`**). No formal **`milestones/v1.12-MILESTONE-AUDIT.md`**.

**Archives:** `milestones/v1.12-ROADMAP.md`, `milestones/v1.12-REQUIREMENTS.md` · **Git tag:** `v1.12` (planning milestone marker)

---

## v1.11 Operator shell polish and JTBD verification (Shipped + archived: 2026-04-21)

**Phases completed:** 3 phases (**48–50**), **11** plans

**Hex:** **`scrypath 0.3.3`** (polish in-repo **`scrypath_ops`**; no mandated Hex bump in this planning milestone)

**Key accomplishments:**

- **`operator-ia.md`** ↔ **`router.ex`** nav contract (**`mix scrypath_ops.check_nav_contract`**, **`operator_ia_contract_test`**) — **OPSUX-01**
- Posture **JTBD** clarity with bounded **next checks** list — **OPSUX-02**
- Shared **`/ops`** page scaffold, **system/light/dark** coherence, Phoenix **`ops_shell_contract_test`** — **OPSUX-03**–**OPSUX-05**
- Accessibility DOM contracts + **`mix scrypath_ops.opsui.test_a11y`** focused slice — **OPSUX-06**, **OPSUX-07**

**Known deferred items at close:** **`audit-open`** reported **2** missing quick-task stubs — **acknowledged** at close — see **`STATE.md`** § **Deferred Items** (**Acknowledged at v1.11 milestone close**). No formal **`milestones/v1.11-MILESTONE-AUDIT.md`**.

**Archives:** `milestones/v1.11-ROADMAP.md`, `milestones/v1.11-REQUIREMENTS.md` · **Git tag:** `v1.11` (planning milestone marker)

---

## v1.10 Operator admin UI (OPSUI) (Shipped + archived: 2026-04-21)

**Phases completed:** 4 phases (**44–47**), **14** plans

**Hex:** **`scrypath 0.3.3`** (OPSUI ships as the in-repo **`scrypath_ops`** Phoenix app; no mandated Hex bump in this planning milestone)

**Key accomplishments:**

- **`scrypath_ops`** as optional operator surface with **`operator-ia.md`** personas/JTBD, nav order, and maintainer boot/run docs — **OPSUI-06**..**OPSUI-09**
- Prod **`OPSUI_AUTH_MODE`** fail-closed boot guard, **`SECURITY.md`**, and config contract tests — **OPSUI-08**
- LiveView posture landing, **`failed_sync_work/2`**-honest triage, read-only sync/drift with operator-doc and Mix links — **OPSUI-01**..**OPSUI-03**
- Bounded search playground + **`SearchPlaygroundStubAdapter`**, federation-honest multi-search inspector (merge trace, weights, partial failures, **`:all`**) — **OPSUI-04**, **OPSUI-05**
- **`LiveViewTest`** + **`operator_ia_contract_test`** / auth boot pins and CI wiring so OPSUI cannot drift silently — **OPSUI-10**

**Known deferred items at close:** **`audit-open`** reported **2** missing quick-task stubs (same historical rows as **v1.9** close); **acknowledged** at close — see **`STATE.md`** § **Deferred Items** (**Acknowledged at v1.10 milestone close**). No formal **`milestones/v1.10-MILESTONE-AUDIT.md`**.

**Archives:** `milestones/v1.10-ROADMAP.md`, `milestones/v1.10-REQUIREMENTS.md` · **Git tag:** `v1.10` (planning milestone marker)

---

## v1.9 Per-query relevance & tuning pipeline (Shipped + archived: 2026-04-20)

**Phases completed:** 2 phases (**42–43**), **5** plans

**Hex:** **`scrypath 0.3.3`** (per-query pipeline spec + runtime shipped in-repo at archive; no mandated Hex bump in this planning milestone)

**Key accomplishments:**

- Authoritative **`guides/per-query-tuning-pipeline.md`** with **TUNE-PIPE** traceability, discoverability cross-links, **`docs_contract_test`** spine anchors, and public **`Scrypath.search/3`** / **`search_many/2`** `@doc` (**Phase 42**, **TUNE-PIPE-01..04**)
- Allowlisted **`:per_query`** options carried on **`%Scrypath.Query{}`**, Meilisearch JSON projection for ranking-score knobs, telemetry when details are enabled, and regression tests (**Phase 43**, **TUNE-PQ-01**)
- **`search_many/2`** inner-merge semantics for per-query payloads, federation-safe composition, and integration coverage (**Phase 43**, **TUNE-PQ-01**)
- **`mix verify.phase43`** thin composer registered in **`mix.exs`**, **`docs_contract_test`** **`@verify_phase43`** pin, **CI `quality`** step, and **CONTRIBUTING** guidance (**Phase 43**, **TUNE-PQ-02..03**)

**Known deferred items at close:** **`audit-open`** reported **3** rows (Phase 18 UAT listing + two missing quick-task stubs); **acknowledged** at close — see **`STATE.md`** § **Deferred Items**. Post-close ledger: **`milestones/v1.9-MILESTONE-AUDIT.md`** (status **`passed`**).

**Archives:** `milestones/v1.9-ROADMAP.md`, `milestones/v1.9-REQUIREMENTS.md`, `milestones/v1.9-MILESTONE-AUDIT.md` · **Git tag:** `v1.9` (planning milestone marker)

---

## v1.8 Multi-index federation (Shipped + archived: 2026-04-20)

**Phases completed:** 3 phases (**39–41**), **6** plans

**Hex:** **`scrypath 0.3.3`** (federation scoring, `:all` expansion, and doc/contract gates shipped in-repo; no mandated Hex bump in this planning milestone)

**Key accomplishments:**

- Meilisearch-aligned **`federation_weight:`** / **`federationOptions.weight`**, **`merge_hit_order`**, **`MultiSearchResult.merge_projection/1`**, and guide **`## Federation weights`** with tests (**Phase 39**, **FED-01**)
- **`Scrypath.MultiSearch.AllExpansion`** for **`{:all, …}`**, **`global_schemas:`** / env allowlist, cardinality rails, and explicit **`{:invalid_options, {:all_expansion, _}}`** errors (**Phase 40**, **FED-02**)
- **`guides/multi-index-search.md`**, README / golden-path pointers, **`docs_contract_test.exs`** anchors, and **`mix verify.phase41`** in CI (**Phase 41**, **FED-03**)

**Known deferred items at close:** **`audit-open`** reported **3** rows (Phase 18 UAT listing + two missing quick-task stubs); **acknowledged** at close — see **`STATE.md`** §**Deferred Items**. Formal milestone audit added post-close: **`milestones/v1.8-MILESTONE-AUDIT.md`** (status **`tech_debt`**).

**Archives:** `milestones/v1.8-ROADMAP.md`, `milestones/v1.8-REQUIREMENTS.md`, `milestones/v1.8-MILESTONE-AUDIT.md` · **Git tag:** `v1.8` (planning milestone marker)

---

## v1.7 Facet depth and catalog search UX (Shipped + archived: 2026-04-20)

**Phases completed:** 3 phases (**36–38**), **7** plans

**Hex:** **`scrypath 0.3.3`** (facet-depth APIs and verify slices in-repo; no mandated Hex bump in this planning milestone)

**Key accomplishments:**

- Hierarchical facet paths with settings alignment, dotted facet keys in results, **`mix verify.phase36`**, and guide coverage (**Phase 36**, **FACET-01**)
- Disjunctive facet count merge helper, LiveView guide contract, **`mix verify.phase37`** with regression **`mix verify.phase36`** (**Phase 37**, **FACET-02**)
- Public **`search_within_facet/4`**, telemetry metadata, scoped-search guide sections, **`mix verify.phase38`**, README / **`Scrypath`** doc pointers (**Phase 38**, **FACET-03**, **FACET-04**)

**Known deferred items at close:** **`audit-open`** again reported **3** historical rows (Phase 18 UAT listing + two missing quick-task stubs); **acknowledged** at close — see **`STATE.md`** §**Acknowledged at v1.7 milestone close**. Milestone audit status **`tech_debt`** (Nyquist drafts, disjunctive wiring expectations, validation table drift) — see **`milestones/v1.7-MILESTONE-AUDIT.md`**.

**Archives:** `milestones/v1.7-ROADMAP.md`, `milestones/v1.7-REQUIREMENTS.md`, `milestones/v1.7-MILESTONE-AUDIT.md` · **Git tag:** `v1.7` (planning milestone marker)

---

## v1.6 Adoption-grade integration and trust (Shipped + archived: 2026-04-19)

**Phases completed:** 7 phases (29–35), 7 numbered plans (`*-PLAN.md`; phases **30–31** verification-led without separate plan directories)

**Hex:** **`scrypath 0.3.3`** (no new package version in this planning milestone; docs, proof, and verification clarity)

**Key accomplishments:**

- **`guides/golden-path.md`** and README adoption wayfinding — single install → inline sync → **`Scrypath.search/3`** story (**Phase 29**)
- Oban-shaped consumer proof and example smoke runbook / env / CI mapping (**Phase 30**)
- CONTRIBUTING verify ↔ guarantee matrix + default vs integration CI documentation (**Phase 31**)
- **`STATE.md`** deferred-row triage (**AUDT-01**) (**Phase 32**)
- Doc contracts for **`scripts/smoke.sh`** cwd, **`docs_contract_test.exs`** depth (**Phase 33**)
- README Quick Path ↔ golden path canonical schema + **`phoenix-example-integration`** CI alignment (**Phase 34**)
- README sync authority ↔ **`guides/sync-modes-and-visibility.md`** operator lifecycle parity (**Phase 35**)

**Known deferred items at close:** **`audit-open`** reported **3** rows (Phase 18 UAT listing + two missing quick-task stubs); **acknowledged** at close — see **`STATE.md`** §**Acknowledged at v1.6 milestone close**. Milestone audit status **`tech_debt`** (Nyquist hygiene + optional **`getting-started`** vs golden-path `status` note) — see **`milestones/v1.6-MILESTONE-AUDIT.md`**.

**Archives:** `milestones/v1.6-ROADMAP.md`, `milestones/v1.6-REQUIREMENTS.md`, `milestones/v1.6-MILESTONE-AUDIT.md` · **Git tag:** `v1.6` (planning milestone marker)

---

## v1.5 Operator drift and schema-diff tooling (Shipped + archived: 2026-04-18)

**Phases completed:** 2 phases (27–28), 5 plans

**Hex:** **`scrypath 0.3.3`** (line on Hex at archive; milestone delivered in-repo with planning artifacts)

**Key accomplishments:**

- Read-only **index contract drift** report (`Scrypath.index_contract_drift/2`, `IndexContractDrift.Report`) with bounded dimensions (Phase 27)
- Optional **`include_index_contract_drift`** on reconcile for operator opt-in without new recovery verbs (Phase 27)
- **`mix scrypath.index.contract_drift`** with **`--json`**, parity/drift exit semantics aligned with settings diff (Phase 28)
- Operator docs refresh (**`guides/drift-recovery.md`**, **`docs/operator-support.md`**, **`guides/operator-mix-tasks.md`**) plus auth-free **`mix verify.phase28`** / CI (Phase 28)

**Known deferred items at close:** At milestone archive, three `audit-open` rows were acknowledged (Phase 18 UAT listing noise + two quick_task stubs). **Triaged phase 32 (AUDT-01); see `STATE.md` §Deferred Items.**

**Archives:** `milestones/v1.5-ROADMAP.md`, `milestones/v1.5-REQUIREMENTS.md` · **Git tag:** `v1.5` (planning milestone marker)

---

## v1.3 Search Power That Phoenix Teams Reach For (Shipped: 2026-04-17)

**Phases completed:** 6 phases (18–23), 18 plans

**Key accomplishments:**

- Release-parity mechanization: `mix verify.workspace_clean`, `mix verify.release_parity`, Node pin hygiene, and scheduled published-release drift checks (Phase 18)
- Declarative relevance tuning (synonyms, typo tolerance, ranking rules, distinct, stop words) with managed reindex pipeline, drift read-back, and `mix scrypath.settings.{diff,read}` (Phase 19)
- Faceted search on `Scrypath.search/3` with `%SearchResult.Facets{}`, validated facet filters, and a Phoenix LiveView guide (Phase 20)
- Federated `Scrypath.search_many/2` with native `/multi-search`, partial-failure envelope, telemetry, and multi-index guide (Phase 21)
- Operator polish on `%FailedWork{}` (`reason_class`, attempts, telemetry) plus `guides/drift-recovery.md` (Phase 22)
- v1.2 Nyquist validation closure: evidence under `milestones/v1.2/` and `v1.2-MILESTONE-AUDIT.md` → `compliant` (Phase 23)

**Known deferred items at close:** At v1.3 close, two quick-task stubs were referenced by `audit-open` (since superseded on disk). **Triaged phase 32 (AUDT-01); see `STATE.md` §Deferred Items.**

**Archives:** `milestones/v1.3-ROADMAP.md`, `milestones/v1.3-REQUIREMENTS.md`

---

## v1.4 Public package parity & operator depth (Shipped + archived: 2026-04-17)

**Phases completed:** 3 phases (24–26), 8 plans

**Hex:** **`scrypath 0.3.1`** — https://hex.pm/packages/scrypath/0.3.1 — Release Please PR **#5**, Actions publish run **24589910084** (`release_publish` + `release_parity` green).

**Key accomplishments:** Release Please + post-publish parity on both publish workflows; README / `docs/releasing.md` / contract tests aligned; **`hot_apply/3`** + `mix scrypath.settings.hot_apply` + integration smoke; **`failed_sync_work/2`** rollups + `%Reconcile{}` + **`mix verify.phase26`**.

**Known deferred items at close:** At milestone archive, three `audit-open` rows were acknowledged (two quick_task stubs + Phase 18 UAT noise). **Triaged phase 32 (AUDT-01); see `STATE.md` §Deferred Items.**

**Archives:** `milestones/v1.4-ROADMAP.md`, `milestones/v1.4-REQUIREMENTS.md`, `milestones/v1.4-MILESTONE-AUDIT.md` · **Git tag:** `v1.4` (planning milestone marker; package release tag is **`scrypath-v0.3.1`**).

---

## v1.2 Public Release Trust and Operator Visibility (Shipped: 2026-04-17)

**Phases completed:** 7 phases, 13 plans, 22 tasks

**Key accomplishments:**

- Version-anchored Hex package links and a canonical `mix verify.phase11` gate for Release Please, manifest, and local package alignment
- Clean-consumer compile proof and maintainer recovery runbooks enforced through the Phase 11 release gate
- Scrypath-owned task and result seam contracts for Meilisearch and Oban normalization without runtime rewiring
- Seam-owned Meilisearch and Oban operation references wired through sync while preserving the public Meilisearch-first sync contract
- Seam-owned backfill and reindex workflow references with the Meilisearch-first public boundary locked in docs and telemetry
- Root-level sync status reporting with Scrypath-owned backend and queue visibility across manual, inline, and Oban workflows
- Canonical Phase 13 operator verification evidence plus roadmap and requirement repairs grounded in a fresh `mix verify.phase13 --skip-integration` pass
- Canonical Phase 14 verification evidence, repaired milestone bookkeeping, and plan-index aliases grounded in a fresh `mix verify.phase14` pass
- Shipped the first real public Scrypath release as `0.3.0`, then verified the live GitHub release, Hex package, and HexDocs path

---

| Version | Date | Phases | Plans | Status | Notes |
|---------|------|--------|-------|--------|-------|
| `v1.0` | 2026-04-16 | 7 | 25 | Archived | Ecto-native Meilisearch-first indexing core, search, Oban, reindex, Phoenix docs, and repaired verification history. |
| `v1.1` | 2026-04-16 | 3 | 9 | Archived | Release hardening, docs-safety fixes, and launch-readiness evidence chain archived in `.planning/milestones/v1.1-ROADMAP.md`. |
| `v1.2` | 2026-04-17 | 7 | 13 | Archived | Public release trust, operator visibility, internal operations seam, and the first live public release proof archived in `.planning/milestones/v1.2-ROADMAP.md`. |
| `v1.3` | 2026-04-17 | 6 | 18 | Archived | Search power (relevance, facets, multi-index), operator polish + drift recovery, release-parity gates, v1.2 validation closure — `v1.3-ROADMAP.md` + `v1.3-REQUIREMENTS.md`. |
| `v1.4` | 2026-04-17 | 3 | 8 | Archived | Hex **0.3.1**; `v1.4-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`; milestone tag **`v1.4`**. |
| `v1.5` | 2026-04-18 | 2 | 5 | Archived | Index contract drift + Mix + docs + **`mix verify.phase28`**; `v1.5-{ROADMAP,REQUIREMENTS}.md`; milestone tag **`v1.5`**. |
| `v1.6` | 2026-04-19 | 7 | 7 | Archived | Adoption golden path, consumer proof, verify story, **`STATE`** triage, doc contracts **33–35**; `v1.6-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`; tag **`v1.6`**. |
| `v1.7` | 2026-04-20 | 3 | 7 | Archived | Facet depth (hierarchical, disjunctive counts, `search_within_facet/4`); `v1.7-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`; tag **`v1.7`**. |
| `v1.8` | 2026-04-20 | 3 | 6 | Archived | Multi-index federation (weights, `:all` expansion, docs/contracts); `v1.8-{ROADMAP,REQUIREMENTS}.md`; tag **`v1.8`**. |
| `v1.9` | 2026-04-20 | 2 | 5 | Archived | Per-query relevance & tuning pipeline — phases **42–43**; `v1.9-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`; tag **`v1.9`**. |
| `v1.10` | 2026-04-21 | 4 | 14 | Archived | Operator admin UI (OPSUI) — phases **44–47**; Hex **0.3.3** at archive; `v1.10-*` archives. |
| `v1.11` | 2026-04-21 | 3 | 11 | Archived | Operator shell polish — phases **48–50**; `v1.11-*` archives. |
| `v1.12` | 2026-04-22 | 3 | 9 | Archived | Developer onboarding & first-hour QoL — phases **51–53**; `v1.12-*` archives. |
| `v1.13` | 2026-04-22 | 3 | 5 req | Archived | Public polish & narrative coherence — phases **54–56**; Hex **`scrypath 0.3.4`**; `v1.13-*` archives. |
| `v1.14` | 2026-04-22 | 5 | 10 req | Archived | B1 evidence + **LIB-*** QoL + operator playbooks (**57–61**); Hex **`scrypath 0.3.4`**; `v1.14-*` archives. |
| `v1.15` | 2026-04-22 | 3 | 8 req | Archived | OPSUI second slice — phases **62–64**; `v1.15-*` archives. |
| `v1.16` | 2026-04-22 | 3 | 6 req | Archived | Playbook execution & operator honesty — phases **65–67**; `v1.16-*` archives. |
| `v1.17` | 2026-04-23 | 3 | 6 req | Archived | Integration confidence & adopter proof — phases **68–70**; `v1.17-*` archives. |
| `v1.18` | 2026-04-27 | 3 | 10 req | Archived | Sigra integration — phases **71–73**; `v1.18-*` archives. |
| `v1.19` | 2026-04-28 | 3 | 8 req | Archived | Production adoption proof and hardening — phases **74–76**; `v1.19-*` archives. |
| `v1.20` | 2026-05-08 | 3 | 8 req | Archived | Search Module Foundation — phases **77–79**; `v1.20-*` archives. |
| `v1.21` | 2026-05-23 | 3 | 8 req | Archived | Query Toolkit And Phoenix Edge Helpers — phases **80–82**; `v1.21-*` archives. |
| `v1.22` | 2026-05-24 | 3 | 12 req | Archived | Composition And Real-App Depth — phases **83–85**; `v1.22-*` archives. |
| `v1.23` | 2026-05-24 | 3 | 8 req | Archived | Outside-Adopter Evidence And Support-Truth Reconciliation — phases **86–88**; `v1.23-*` archives. |
