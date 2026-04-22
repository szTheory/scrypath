# Roadmap: Scrypath

## Milestones

- [x] `v1.0` shipped on 2026-04-16 — 7 phases, 25 plans — [archive](milestones/v1.0-ROADMAP.md)
- [x] `v1.1` shipped on 2026-04-16 — 3 phases, 9 plans — [archive](milestones/v1.1-ROADMAP.md)
- [x] `v1.2` shipped on 2026-04-17 — 7 phases, 13 plans — [archive](milestones/v1.2-ROADMAP.md)
- [x] `v1.3` shipped on 2026-04-17 — 6 phases (18–23), 18 plans — [archive](milestones/v1.3-ROADMAP.md) · [requirements](milestones/v1.3-REQUIREMENTS.md)
- [x] **`v1.4` shipped on 2026-04-17** — 3 phases (24–26), 8 plans — [archive](milestones/v1.4-ROADMAP.md) · [requirements](milestones/v1.4-REQUIREMENTS.md)
- [x] **`v1.5` shipped in-repo** (2026-04-18) — 2 phases (27–28), 5 plans — [archive](milestones/v1.5-ROADMAP.md) · [requirements](milestones/v1.5-REQUIREMENTS.md) — *Operator drift and schema-diff tooling*
- [x] **`v1.6` shipped in-repo** (2026-04-19) — 7 phases (29–35), 7 plans — [archive](milestones/v1.6-ROADMAP.md) · [requirements](milestones/v1.6-REQUIREMENTS.md) · [audit](milestones/v1.6-MILESTONE-AUDIT.md) — *Adoption-grade integration and trust*
- [x] **`v1.7` shipped in-repo** (2026-04-20) — 3 phases (36–38), 7 plans — [archive](milestones/v1.7-ROADMAP.md) · [requirements](milestones/v1.7-REQUIREMENTS.md) · [audit](milestones/v1.7-MILESTONE-AUDIT.md) — *Facet depth and catalog search UX*
- [x] **`v1.8` shipped in-repo** (2026-04-20) — *Multi-index federation* — phases **39–41**, **6** plans — [archive](milestones/v1.8-ROADMAP.md) · [requirements](milestones/v1.8-REQUIREMENTS.md) · [audit](milestones/v1.8-MILESTONE-AUDIT.md)
- [x] **`v1.9` shipped in-repo** (2026-04-20) — *Per-query relevance & tuning pipeline* — phases **42–43**, **5** plans — [archive](milestones/v1.9-ROADMAP.md) · [requirements](milestones/v1.9-REQUIREMENTS.md) · [audit](milestones/v1.9-MILESTONE-AUDIT.md)
- [x] **`v1.10` shipped in-repo** (2026-04-21) — *Operator admin UI (OPSUI)* — phases **44–47**, **14** plans — [archive](milestones/v1.10-ROADMAP.md) · [requirements](milestones/v1.10-REQUIREMENTS.md) · [research summary](research/SUMMARY.md)
- [x] **`v1.11` shipped in-repo** (2026-04-21) — *Operator shell polish and JTBD verification* — phases **48–50**, **11** plans — [archive](milestones/v1.11-ROADMAP.md) · [requirements](milestones/v1.11-REQUIREMENTS.md)
- [x] **`v1.12` shipped in-repo** (2026-04-22) — *Developer onboarding & first-hour QoL* — phases **51–53**, **9** plans — [archive](milestones/v1.12-ROADMAP.md) · [requirements](milestones/v1.12-REQUIREMENTS.md)
- [x] **`v1.13` shipped + archived in-repo** (2026-04-22 shipped · 2026-04-21 archived) — *Public polish & narrative coherence* — phases **54–56**, **5** requirements — [archive](milestones/v1.13-ROADMAP.md) · [requirements](milestones/v1.13-REQUIREMENTS.md)

## Phases (next milestone)

Open **`/gsd-new-milestone`** when you are ready; phase numbering continues from **57** unless you pass **`--reset-phase-numbers`**.

## Phases (history)

<details>
<summary>✅ v1.13 — Phases 54–56 — SHIPPED 2026-04-22 · archived 2026-04-21 · Hex <code>scrypath 0.3.4</code> · <em>Public polish & narrative coherence</em></summary>

- [x] **Phase 54: Guide voice and pitfalls ledger** — Remove internal planning phase vocabulary from adopter **`guides/`** (canonical: **`guides/per-query-tuning-pipeline.md`**); keep **`guides/common-mistakes.md`** grounded (**≥3** pitfalls, evidence-only growth) — **POLISH-01**, **POLISH-05**.
  - **Success criteria:** (1) No “Phase N” / internal milestone-process strings remain in **`guides/`** consumer prose. (2) Per-query pipeline reads in product/API terms and still links Plane A authority. (3) Pitfalls doc still lists **≥3** items with authority + evidence pattern.
- [x] **Phase 55: Version and planning truth** — **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, **ROADMAP** Hex callouts where “current line” is stated match **Hex `0.3.4`** and **`mix.exs`**; **README** “Versioning” explains checkout vs published — **POLISH-02**.
  - **Success criteria:** (1) Any “current Hex” claim in active planning files matches **hex.pm** latest (**0.3.4** at milestone open). (2) **README** points to Hex for latest published. (3) **PROJECT** *Current State* matches **`mix.exs`**.
- [x] **Phase 56: Contributor entry and backlog refresh** — **`AGENTS.md`** contributor-first workflow without GSD slash-command noise; **`milestone-candidates.md`** reflects **v1.12** closure (**Tier A** done), **v1.13** theme, and next-tier pulls — **POLISH-03**, **POLISH-04**.
  - **Success criteria:** (1) **`AGENTS.md`** readable by OSS contributors without internal tool commands as required reading. (2) **`milestone-candidates.md`** “where things stand” matches shipped **v1.12** and ranks **B1** next. (3) **REQUIREMENTS** traceability table matches phases.

Full detail: [milestones/v1.13-ROADMAP.md](milestones/v1.13-ROADMAP.md).

</details>

<details>
<summary>✅ v1.12 — Phases 51–53 — SHIPPED 2026-04-22 · in-repo · Hex line <code>0.3.3</code> at archive (no mandated bump; latest Hex may be newer) · <em>Developer onboarding and first-hour QoL</em></summary>

- [x] **Phase 51: Adoption path truth and discoverability** (2026-04-21) — README ↔ **`guides/golden-path.md`** ↔ integration-example story stay **contract-true**; **`CONTRIBUTING`** first-hour pointers and sync authority links (**ONBD-01**..**ONBD-03**).
  - **Success criteria:** (1) A reader can install and reach a working **`Scrypath.search/3`** path using only README + golden path without hitting a known doc lie. (2) Doc-contract tests (or equivalent) fail when canonical snippets, cwd, or CI-integration expectations drift. (3) **`CONTRIBUTING`** names the happy path and where sync modes / operator lifecycle live.
- [x] **Phase 52: Actionable errors and onboarding pitfalls** (2026-04-22) — Bounded **`{:error, _}`** / raise messages for high-friction paths; pitfalls / common-mistakes slice; **`Scrypath`** **`@moduledoc`** “start here” pointers (**ONBD-04**..**ONBD-06**).
  - **Success criteria:** (1) Each targeted error path names the failure and the **next doc** to read. (2) Pitfalls doc lists **≥ 3** grounded mistakes with fixes. (3) Module doc (and task help if touched) links to golden path + sync authority within two hops.
- [x] **Phase 53: Contributor OPSUI verify spine** (2026-04-22) — Root-level **`mix verify.opsui`** registered, documented in **README** / **CONTRIBUTING**, and aligned with verify matrix text via **`docs_contract_test`** (**VRFY-03**, **VRFY-04**).
  - **Success criteria:** (1) One command from repo root runs OPSUI checks with documented prereqs. (2) Contributor docs surface the command without burying it. (3) CI / default verify story references the command where appropriate.

Full detail: [milestones/v1.12-ROADMAP.md](milestones/v1.12-ROADMAP.md).

</details>

<details>
<summary>✅ v1.11 — Phases 48–50 — SHIPPED 2026-04-21 · in-repo · Hex <code>scrypath 0.3.3</code> · <em>Operator shell polish and JTBD verification</em></summary>

- [x] **Phase 48: IA and JTBD alignment** (2026-04-21) — **`scrypath_ops/docs/operator-ia.md`** ↔ **`router.ex`** ↔ **`operator_ia_contract_test`** (or equivalent) (**OPSUX-01**). On-call **job 1** path: posture landing shows state with **explicit next checks** / links (**OPSUX-02**).
  - **Success criteria:** (1) CI fails if nav labels, order, or **`/ops`** routes drift from **`operator-ia.md`** table without a doc update. (2) A new on-call operator can answer “what do I check next?” from the posture view alone plus linked docs/Mix paths.
- [x] **Phase 49: Visual hierarchy, theming, and Phoenix ergonomics** (2026-04-21) — Consistent page chrome and scan-friendly panels on all **`/ops`** LiveViews (**OPSUX-03**). **System / light / dark** coherent and readable, including first load and persistence (**OPSUX-04**). Fix LiveView/layout/component inconsistencies vs Phoenix norms (**OPSUX-05**).
  - **Success criteria:** (1) Checklist passes for all four operator surfaces in **light and dark**. (2) No critical contrast or “orphan” default-shell paths on **`/ops`**. (3) Flash, titles, and primary actions read clearly on laptop and narrow widths.
- [x] **Phase 50: Accessibility and verification hardening** (2026-04-21) — Heading order, landmarks, control labels on triage and playground paths (**OPSUX-06**). Extend automated tests for any new contracts or critical LiveView flows (**OPSUX-07**).
  - **Success criteria:** (1) Spot keyboard + screen-reader pass on posture → failed-sync → sync/drift → search. (2) CI suite updated; **`mix test`** (or documented **`verify.opsui`** path) green with new cases.

Full detail: [milestones/v1.11-ROADMAP.md](milestones/v1.11-ROADMAP.md).

</details>

<details>
<summary>✅ v1.10 — Phases 44–47 — SHIPPED 2026-04-21 · in-repo · Hex <code>scrypath 0.3.3</code> · <em>Operator admin UI (OPSUI)</em></summary>

- [x] **Phase 44: OPSUI foundations** — **`scrypath_ops`** packaging + docs, **`operator-ia.md`** personas/JTBD + primary nav, conventional Phoenix LiveView routing/layout, **`SECURITY.md`** + prod boot **`OPSUI_AUTH_MODE`** guard — **OPSUI-06**..**OPSUI-09**.
- [x] **Phase 45: Posture & failure triage** — dashboard posture from **`Scrypath.*`** visibility APIs, **`failed_sync_work/2`**-aligned triage, read-only sync/drift with links to Mix/docs operator paths — **OPSUI-01**..**OPSUI-03**.
- [x] **Phase 46: Search & federation honesty** — bounded search playground (warnings, ceilings), multi-search inspector (merge order, weights, partial failures, **`:all`**) — **OPSUI-04**, **OPSUI-05**.
- [x] **Phase 47: Verification & hardening** — **`LiveViewTest`** + **`SearchPlaygroundStubAdapter`**, **`operator_ia_contract_test`**, auth boot contract tests, CI coverage — **OPSUI-10**.

Full detail: [milestones/v1.10-ROADMAP.md](milestones/v1.10-ROADMAP.md).

</details>

<details>
<summary>✅ v1.9 — Phases 42–43 — SHIPPED 2026-04-20 · in-repo · Hex <code>scrypath 0.3.3</code></summary>

- [x] **Phase 42: Per-query tuning pipeline spec** — **`guides/per-query-tuning-pipeline.md`**, precedence vs defaults, Meilisearch mapping, non-goals, implementation checklist, **`docs_contract_test`** anchors, **`Scrypath.search/3`** / **`search_many/2`** `@doc` — **TUNE-PIPE-01**..**TUNE-PIPE-04**.
- [x] **Phase 43: Per-query relevance runtime** — Allowlisted **`:per_query`**, **`%Query{}`**, Meilisearch projection (ranking score knobs), **`search_many/2`** inner merge, telemetry metadata, **`mix verify.phase43`** in CI — **TUNE-PQ-01**..**TUNE-PQ-03** / backlog **`TUNE-01`**.

Full detail: [milestones/v1.9-ROADMAP.md](milestones/v1.9-ROADMAP.md).

</details>

<details>
<summary>✅ v1.8 — Phases 39–41 — SHIPPED 2026-04-20 · in-repo · Hex <code>scrypath 0.3.3</code></summary>

- [x] **Phase 39: Federation scoring & weights** — **`federation_weight:`**, Meilisearch **`federationOptions.weight`**, **`merge_hit_order`** / **`Scrypath.MultiSearchResult.merge_projection/1`**, guide **`## Federation weights`**, tests — **FED-01**.
- [x] **Phase 40: `:all` expansion** — **`Scrypath.MultiSearch.AllExpansion`**, **`global_schemas:`** / **`:scrypath_global_search_schemas`**, post-expansion **`max_schemas`**, explicit **`{:invalid_options, {:all_expansion, _}}`** — **FED-02**.
- [x] **Phase 41: Federation docs & contracts** — **`guides/multi-index-search.md`**, README / golden-path pointers, **`docs_contract_test.exs`**, **`mix verify.phase41`** in CI — **FED-03**.

Full detail: [milestones/v1.8-ROADMAP.md](milestones/v1.8-ROADMAP.md).

</details>

<details>
<summary>✅ v1.7 — Phases 36–38 — SHIPPED 2026-04-20 · in-repo · Hex <code>scrypath 0.3.3</code></summary>

- [x] **Phase 36: Hierarchical facets** — Declarative nested facet paths, Meilisearch settings alignment, stable dotted facet keys in **`%SearchResult{}`**, **`mix verify.phase36`**; **FACET-01**.
- [x] **Phase 37: Disjunctive facet counts** — **`Scrypath.Facets.Disjunctive.merge_distributions/2`**, guide **`## Disjunctive facet counts`**, **`mix verify.phase37`** + regression **`mix verify.phase36`**; **FACET-02**.
- [x] **Phase 38: Search within facet + docs** — **`search_within_facet/4`**, telemetry metadata, LiveView guide sections for scoped search + composition, **`mix verify.phase38`**, README / module-doc pointers; **FACET-03**, **FACET-04**.

Full detail: [milestones/v1.7-ROADMAP.md](milestones/v1.7-ROADMAP.md).

</details>

<details>
<summary>✅ v1.6 — Phases 29–35 — SHIPPED 2026-04-19 · in-repo · Hex <code>scrypath 0.3.3</code></summary>

- [x] **Phase 29: Golden path and adoption documentation** — `guides/golden-path.md`, README adoption wayfinding, sync-mode authority, versioning cross-links; ADPT-01..03.
- [x] **Phase 30: Consumer example and smoke depth** — Oban-shaped integration proof, example smoke runbook / env / CI mapping; EXAM-01..02.
- [x] **Phase 31: Verification story for adopters** — CONTRIBUTING verify matrix ↔ guarantees, default vs integration CI story; VRFY-01..02.
- [x] **Phase 32: Planning and state hygiene** — v1.5 deferred `STATE.md` rows triaged; AUDT-01.
- [x] **Phase 33: Example smoke paths and doc contracts** — Root vs example `smoke.sh` cwd, `docs_contract_test.exs`; ADPT-01, EXAM-02, VRFY-02, AUDT-01.
- [x] **Phase 34: Golden path, README, and CI alignment** — Canonical first-schema story, `phoenix-example-integration` parity; ADPT-01..03, VRFY-01.
- [x] **Phase 35: Sync guide lifecycle parity** — README authority ↔ `guides/sync-modes-and-visibility.md` operator lifecycle; ADPT-02..03.

Full detail: [milestones/v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md).

</details>

<details>
<summary>✅ v1.5 — Phases 27–28 — SHIPPED 2026-04-18 · in-repo · Hex <code>scrypath 0.3.3</code></summary>

- [x] **Phase 27: Schema–index drift report (read-only)** — `Scrypath.index_contract_drift/2`, `IndexContractDrift.Report`, optional reconcile attachment; DRIFT15-01..02, OPS15-01.
- [x] **Phase 28: Operator CLI, docs, and verify gate** — `mix scrypath.index.contract_drift`, drift-recovery + operator-support refresh, **`mix verify.phase28`**; OPS15-02..04.

Full detail: [milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md).

</details>

<details>
<summary>✅ v1.4 — Phases 24–26 — SHIPPED 2026-04-17 · Hex <code>scrypath 0.3.1</code></summary>

- [x] **Phase 24: Public Hex release & parity gates** — Release Please, publish + post-publish verify gates, README/docs contract (SHIP-01..03).
- [x] **Phase 25: Settings hot apply (narrow)** — `hot_apply/3`, `mix scrypath.settings.hot_apply`, guides + smoke CI.
- [x] **Phase 26: Operator failure rollups** — `failed_sync_work/2` rollups, `%Reconcile{}`, `mix verify.phase26`.

Full detail: [milestones/v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md).

</details>

<details>
<summary>✅ v1.3 — Phases 18–23 — SHIPPED 2026-04-17</summary>

- [x] Phase 18: Release-Parity Gate + Node 20 CI Cleanup — 7/7 plans
- [x] Phase 19: Relevance Tuning — 7/7 plans
- [x] Phase 20: Faceted Search + LiveView Guide — 4/4 plans
- [x] Phase 21: Multi-Index Search — 4/4 plans
- [x] Phase 22: Operator Polish + Drift Recovery Guide — 2/2 plans
- [x] Phase 23: v1.2 VALIDATION.md Closure — 1/1 plan

Details: [milestones/v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md).

</details>

## Progress

**`v1.13` archived (in-repo)** — **2026-04-22** shipped — **2026-04-21** archived — **3** phases (**54–56**), **5** requirements (**POLISH-01**–**POLISH-05**); see **`milestones/v1.13-REQUIREMENTS.md`**.

**`v1.12` archived (in-repo)** — **2026-04-22** shipped — **2026-04-21** archived — **3** phases (**51–53**), **9** plans, **8** requirements (**ONBD-01**..**ONBD-06**, **VRFY-03**..**VRFY-04**); see **`milestones/v1.12-REQUIREMENTS.md`**.

**`v1.11` archived (in-repo)** — **2026-04-21** — **3** phases (**48–50**), **7** requirements (**OPSUX-01**–**OPSUX-07**); see **`milestones/v1.11-REQUIREMENTS.md`**.

**`v1.10` archived (in-repo)** — **2026-04-21** — phases **44–47** delivered against **OPSUI-01**–**OPSUI-10** (see **`milestones/v1.10-REQUIREMENTS.md`**).

## Backlog (post–v1.13 ideas)

- **`OPSUI-FUT-*`** — saved operator playbooks, deeper Meilisearch vendor-style panels — see **[milestones/v1.10-REQUIREMENTS.md](milestones/v1.10-REQUIREMENTS.md)** § v2+ until promoted.
- **Tier B+ / C / D themes** — see **`.planning/milestone-candidates.md`** (library QoL from evidence, heavy CI/E2E, maintainer hygiene).
- **Core library features** — continue to follow **`.planning/PROJECT.md`** *Out of Scope* until a future milestone explicitly widens the contract.

---
*Last updated: 2026-04-21 — between milestones; **`milestones/v1.13-*`** archived; no active **`.planning/REQUIREMENTS.md`** until **`/gsd-new-milestone`***
