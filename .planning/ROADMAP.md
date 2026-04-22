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
- [x] **`v1.14` shipped + archived in-repo** (**2026-04-22**) — *Library QoL and operator playbooks* — phases **57–61**, **10** requirements — [archive](milestones/v1.14-ROADMAP.md) · [requirements](milestones/v1.14-REQUIREMENTS.md) · [audit](milestones/v1.14-MILESTONE-AUDIT.md)
- [x] **`v1.15` shipped + archived in-repo** (**2026-04-22**) — *OPSUI second slice* — phases **62–64**, **8** requirements — [archive](milestones/v1.15-ROADMAP.md) · [requirements](milestones/v1.15-REQUIREMENTS.md) · [audit](milestones/v1.15-MILESTONE-AUDIT.md)
- [ ] **`v1.16` in progress** (opened **2026-04-22**) — *Playbook execution & operator honesty* — phases **65–67** (planned), **6** requirements — [requirements](REQUIREMENTS.md)

## Phases (milestone v1.16 — in progress)

**Opened:** 2026-04-22 — **OPS3-01**–**OPS3-06** — canonical list: [`.planning/REQUIREMENTS.md`](REQUIREMENTS.md)

### Phase 65: Playbook run lifecycle (OPSUI)

- [x] **Phase 65: Playbook run lifecycle (OPSUI)** — **OPS3-01**, **OPS3-02** — operator can **run** a saved **`playbook_format: 1`** playbook from catalog or detail with explicit **idle / running / success / failure** UI; failures surface **structured** errors with **canonical doc links** within two hops. Completed 2026-04-22.

**Success criteria (observable):**

1. Starting a run from **catalog** and from **detail** both enter **running**, then resolve to **success** or **failure** without ambiguous stuck states on stubbed adapters used in CI.
2. A **forced failure** fixture shows a **non-empty** error class/message and **at least one** working outbound link to maintainer or adopter documentation.
3. **`mix verify.opsui`** stays green for the default contributor path after Phase 65 changes land.

### Phase 66: Runner–library contract

- [x] **Phase 66: Runner–library contract** — **OPS3-03** — **`Playbook.Runner`** (and adjacent code) uses **documented** result and **`{:error, _}`** shapes consistent with **`Scrypath`** / Mix operator paths; **automated tests** lock representative success and failure parity.

**Success criteria (observable):**

1. A maintainer can point to a **single doc section** (guide, operator doc, or **`@moduledoc`**) that states the **contract** exercised by playbook runs.
2. Tests fail if OPSUI runner code maps or wraps errors **differently** from the library reference path for the same fixture input.
3. No new **silent** rescue paths that swallow **`{:error, term}`** without telemetry or user-visible attribution.

**Plans:** 2 plans

Plans:
- [x] `66-01-PLAN.md` — Freeze the canonical runner contract in `Runner` and keep schema docs linked, not duplicated.
- [x] `66-02-PLAN.md` — Add the representative parity matrix and downstream raw-reason regression coverage.

### Phase 67: Verification, JTBD examples, milestone bookkeeping

- [ ] **Phase 67: Verification, JTBD examples, milestone bookkeeping** — **OPS3-04**, **OPS3-05**, **OPS3-06** — extend **`mix verify.opsui`** / **`docs_contract_test`** for execution surfaces; ship **≥ two** JTBD **`examples/playbooks/`** fixtures aligned with docs; prepare **`milestones/v1.16-*`** freeze + rolling traceability (and **Hex** / **`mix.exs`** narrative **only** if a release is in scope for close).

**Success criteria (observable):**

1. **`mix verify.opsui`** fails if execution UI strings, doc anchors, or contributor instructions drift from implementation (within the bounded anchors chosen in planning).
2. **`examples/playbooks/`** contains **≥ two** named fixtures referenced from operator or contributor documentation with matching **on-disk** JSON.
3. **`REQUIREMENTS.md`** traceability shows **Complete** for **OPS3-01**–**OPS3-06** at milestone close; **`milestones/v1.16-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`** exists (audit may follow **`/gsd-complete-milestone`** discipline).

## Phases (history)

<details>
<summary>✅ v1.15 — Phases 62–64 — SHIPPED + archived 2026-04-22 · Hex <code>scrypath 0.3.4</code> (in-repo line) · <em>OPSUI second slice</em></summary>

- [x] **Phase 62: Playground capture and playbook catalog** (2026-04-22) — **OPS2-01**–**OPS2-03** — capture, catalog rename/duplicate/metadata on **`playbook_format: 1`**.
- [x] **Phase 63: Bounded team persistence and security posture** (2026-04-22) — **OPS2-04**, **OPS2-07** — **`team-playbook-persistence.md`**, **`mix scrypath_ops.playbooks.validate`**, **`examples/playbooks/`**, security tests.
- [x] **Phase 64: IA, verification, and milestone bookkeeping** (2026-04-22) — **OPS2-05**, **OPS2-06**, **OPS2-08** — **`operator-ia.md`** + nav contract; **`mix verify.opsui`** / doc contracts; milestone **`v1.15-*`** freeze.

Full detail: [milestones/v1.15-ROADMAP.md](milestones/v1.15-ROADMAP.md).

</details>

<details>
<summary>✅ v1.14 — Phases 57–61 — SHIPPED + archived 2026-04-22 · Hex <code>scrypath 0.3.4</code> · <em>Library QoL and operator playbooks</em></summary>

- [x] **Phase 57: Evidence triage and B1 scope lock** — **EVID-01** frozen ledger **`.planning/EVID-01-b1-v1.14.md`**, contributor gates (**PR template**, **CODEOWNERS**), planning mirrors — **EVID-01**.
- [x] **Phase 58: Core library and doc QoL (B1)** — **`Scrypath.Errors`**, search/sync doc hops, **`Query`** boundary clarity, **`docs_contract_test`** anchors — **LIB-01**–**LIB-03**.
- [x] **Phase 59: Playbook schema and persistence MVP** — **`ScrypathOps.Playbook.V1`**, **`playbook-schema-v1.md`**, portable JSON export/import — **OPS-PB-01**, **OPS-PB-03**.
- [x] **Phase 60: Playbook LiveView and IA** — **`/ops/playbooks`**, **`Playbook.Store`** / **`Playbook.Runner`**, **`SCRYPATH_OPS_PLAYBOOK_DIR`**, **`operator-ia.md`** — **OPS-PB-02**, **OPS-PB-04**.
- [x] **Phase 61: Verification and milestone bookkeeping** — **`PlaybookLive`** stub tests, **`mix verify.opsui`**, **SHIP-01** planning alignment — **OPS-PB-05**, **SHIP-01**.

Full detail: [milestones/v1.14-ROADMAP.md](milestones/v1.14-ROADMAP.md).

</details>

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

**Current milestone:** **TBD** — next arc not opened — see **`/gsd-new-milestone`**.

**`v1.15` archived (in-repo)** — **2026-04-22** shipped + archived — **3** phases (**62–64**), **8** requirements (**OPS2-01**–**OPS2-08**); see **`milestones/v1.15-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**`v1.14` archived (in-repo)** — **2026-04-22** shipped + archived — **5** phases (**57–61**), **10** requirements; see **`milestones/v1.14-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**`v1.13` archived (in-repo)** — **2026-04-22** shipped — **2026-04-21** archived — **3** phases (**54–56**), **5** requirements (**POLISH-01**–**POLISH-05**); see **`milestones/v1.13-REQUIREMENTS.md`**.

**`v1.12` archived (in-repo)** — **2026-04-22** shipped — **2026-04-21** archived — **3** phases (**51–53**), **9** plans, **8** requirements (**ONBD-01**..**ONBD-06**, **VRFY-03**..**VRFY-04**); see **`milestones/v1.12-REQUIREMENTS.md`**.

**`v1.11` archived (in-repo)** — **2026-04-21** — **3** phases (**48–50**), **7** requirements (**OPSUX-01**–**OPSUX-07**); see **`milestones/v1.11-REQUIREMENTS.md`**.

**`v1.10` archived (in-repo)** — **2026-04-21** — phases **44–47** delivered against **OPSUI-01**–**OPSUI-10** (see **`milestones/v1.10-REQUIREMENTS.md`**).

## Backlog (post–v1.14 ideas)

- **`OPSUI-FUT-02`** — vendor-style cluster observability — remains **[milestones/v1.10-REQUIREMENTS.md](milestones/v1.10-REQUIREMENTS.md)** § v2+.
- **Tier C** — heavy browser CI, Meilisearch-in-OPSUI CI — **`.planning/milestone-candidates.md`** until proven need.
- **Tier D** — maintainer-only planning hygiene — same file; do not headline consumer milestones.

---
*Last updated: 2026-04-22 — **`v1.15`** milestone shipped + archived; next milestone **TBD***
