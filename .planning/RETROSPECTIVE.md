# Planning retrospective

Living notes across planning milestones. Append new sections at the top.

## Milestone: v1.34 — Both-Themes Perfection

**Shipped (planning):** 2026-06-29
**Archived:** 2026-07-11
**Phases:** 9 (128-136) | **Plans:** 27 | **Requirements:** 10

### What was built

ScrypathOps now has a proven both-theme polish layer: AA contrast hard gates, a true dark surface ramp, seated dark depth, restrained glow/copper accents, purposeful path motion, polished Search/Sync/Playbooks/shell surfaces, and final DUALVERIFY-01 evidence through automated gates, screenshot matrix, before/after gallery, audit, and approved Human UAT.

### What worked

The milestone worked because it made visual quality measurable before tuning pixels. Phase 128's contrast harness and Phase 129's ranked dark audit gave later token and screen work a concrete target, and the final Phase 136 proof avoided stale-server false positives by running source-backed browser lanes.

### What was inefficient

The closeout was manual because the root `REQUIREMENTS.md` had already advanced to v1.35 while v1.34 still needed archival. The generic milestone helper would have archived the wrong requirements file, so the archive had to be reconstructed from the v1.34 appendix, roadmap section, phase summaries, and Phase 136 audit.

### Patterns established

- Treat AA contrast as a hard gate and AAA body text as advisory unless product policy changes.
- Keep dark-theme polish scoped through explicit tokens and browser proof instead of broad light-theme redesign.
- Record generated screenshot evidence with manifest checksums rather than committing bulky browser artifacts.
- Run final browser proof against source-backed servers when stale containers could hide local changes.

### Key lessons

Milestone close tooling assumes the root planning files still describe the milestone being archived. When work interleaves, archive the older milestone before advancing the root requirements file, or explicitly use a targeted closeout that preserves the newer requirements state.

---

## Milestone: v1.32 — Admin UI/UX Design System Cleanup

**Shipped (planning):** 2026-06-01
**Archived:** 2026-06-01
**Phases:** 3 (116-118) | **Plans:** 3 | **Requirements:** 8

### What was built

The existing ScrypathOps `/ops` shell and mounted `/admin/search/*` surface now use project-owned operator tokens, explicit mounted asset hooks, shared LiveView UI primitives, posture-first screen hierarchy, clearer search/playbook workflow ordering, and focused route/component verification.

### What worked

Keeping v1.32 framed as bounded admin proof polish prevented runtime product-scope drift. The final audit was able to trace every requirement through requirements, phase summaries, verification artifacts, and focused test evidence.

### What was inefficient

Earlier phase verification hit local Postgres connection pressure, which made the closeout depend on later sequential reruns. The final focused suites passed, but long-lived local DB pressure remains a recurring verification friction point.

### Key lessons

Mounted admin UI work needs explicit host asset contracts and route-level smoke tests; visual cleanup alone is not enough when the surface is embedded in another Phoenix application.

---

## Milestone: v1.28 — Realistic Demo App & Admin UI Proof

**Shipped (planning):** 2026-05-31
**Archived:** 2026-05-31
**Phases:** 4 (102-105) | **Plans:** 15 | **Requirements:** 15

### What was built

`scrypath_ops` became a mountable router engine, a multi-tenant Phoenix e-commerce example app landed under `examples/`, product search now demonstrates tenant filtering and related category propagation, and the example includes deterministic Playwright coverage for storefront search, operator failed-sync triage, and zero-downtime swap posture against real Postgres and Meilisearch services.

### What worked

Using the realistic demo app as a proof harness exposed integration seams that unit-only work would not have found: router-engine mount configuration, dev/test-only E2E endpoints, related-data visibility in rendered search results, and sanitized operator-state probes.

### What was inefficient

The milestone audit still found process debt: partial Nyquist metadata in older phase validation files, an advisory rather than required E2E lane, and one harness warning where category-filtered readiness probes can replace tenant filters. Those are follow-up hygiene items, not unsatisfied v1.28 requirements.

### Key lessons

Browser proof should stay service-orchestrated by Mix/CI while Playwright owns assertions only. That boundary kept the E2E suite debuggable and avoided hiding operational startup failures inside the browser test runner.

---

## Milestone: v1.24 — Related-Data and Dependency Propagation

**Shipped (planning):** 2026-05-25
**Archived:** 2026-05-25
**Phases:** 3 (89–91) | **Plans:** 9 | **Requirements:** 7 (**DATA-01**–**DATA-03**, **EXEC-01**–**EXEC-02**, **TEST-01**–**TEST-02**) | **Hex:** `scrypath 0.3.4` (in-repo milestone close; no dedicated Hex bump)

### What was built

`Scrypath.sync_related/3` public API with `fan_outs:` metadata validation, inline execution, and `RelatedWorker.enqueue/4` for Oban fan-out. `RelatedWorker.perform/1` with a clear HTTP 4xx/5xx/invalid-args decision matrix. `guides/related-data-and-reindexing.md` rewritten from "temporary workaround" to canonical fan-out story. `mix verify.phase91` hermetic gate (73 tests). Phoenix example app with `Author` schema, arity-safe `Blog.update_author/3`, and inline + Oban smoke tests. One gap-closure plan (91-04) fixed the `use Scrypath, fan_outs:` macro limitation with hand-written accessors and docs-contract regression locks.

### What worked

**Shift-left audit gate** — adding `mix verify.phase91` to the CI `quality` job during the audit pass (rather than as a separate cleanup) meant the milestone closed with zero remaining human UAT items. The audit genuinely found the gap and closed it in the same pass.

**Option A deviation documented quickly** — when the `use Scrypath, fan_outs:` macro limitation surfaced in 91-03, the team moved immediately to hand-written accessors (Option A) rather than debating fixes. Locking it with a docs-contract test and a prose note in the guide means future adopters don't hit the `ArgumentError` silently.

**Arity-safe resolver pattern** — the "records + ids + empty clauses" resolver shape from 91-03 is a reusable pattern worth lifting into guides for future related-data depth.

### What was inefficient

**`gsd-sdk query milestone.complete` still unavailable** — archive + git rm REQUIREMENTS + tag bookkeeping remained manual again (v1.10–v1.24 pattern). The close is reliable but takes deliberate manual steps.

**Phase 89 and 90 VERIFICATION.md produced retroactively** — the audit found both phases had been executed but never formally verified. Producing them from code + CI evidence during the audit works, but the pattern of skipping verification artifacts then reconstructing them costs extra audit time. Prefer creating VERIFICATION.md at plan completion, not at milestone close.

### Patterns established

- **Explicit fan-out contract**: `sync_related/3` is the canonical entry point; contexts invoke it, library executes it. This "contexts own orchestration / library owns execution" line should be maintained in all future related-data depth.
- **Oban error taxonomy**: 4xx → permanent cancel, 5xx/generic → transient retry. Apply this pattern to any future Oban workers in the library.

### Key lessons

When a guide contains "temporary workaround" language, treat it as a milestone-scope signal: that language should ship with a plan to replace it, not carry forward indefinitely. The v1.24 explicit decision to make the workaround a supported default rather than patching around it was the right call.

---

## Milestone: v1.15 — OPSUI second slice

**Shipped (planning):** 2026-04-22  
**Archived:** 2026-04-22  
**Phases:** 3 (62–64) | **Requirements:** 8 (**OPS2-01**–**OPS2-08**) | **Hex:** `scrypath` **0.3.4** (in-repo OPSUI depth; no mandated publish for this planning milestone)

### What was built

Playground **capture → preview → save** into **`playbook_format: 1`**, catalog **rename/duplicate/metadata**, optional **`V1`** title/description/tags, **(A)** team persistence (**`team-playbook-persistence.md`**, **`examples/playbooks/`**, **`mix scrypath_ops.playbooks.validate`**), **`V1` / `PlaybookLive`** security tests, **`operator-ia.md`** alignment for saved playbooks, **`mix verify.opsui`** + doc-contract anchors (**including** playbook validate in contributor docs), and frozen **`milestones/v1.15-*`** close bookkeeping.

### What worked

Choosing **explicit (A) file + GitOps** for **OPS2-04** kept shared playbooks shippable without an **Ecto** catalog fork while still tightening validation and threat-model copy.

### What was inefficient

**`gsd-sdk query milestone.complete`** still errors (**`version required for phases archive`**), so archive + **`git rm` REQUIREMENTS** + tag bookkeeping remained **manual** again (**v1.10–v1.15** pattern).

### Key lessons

After **`audit-open`** is green and **`milestones/v*-MILESTONE-AUDIT.md`** is **`passed`**, finish close with **`git tag v{N}`** in the same pass so planning markers do not lag **`MILESTONES.md`**.

---

## Milestone: v1.14 — Library QoL and operator playbooks

**Shipped (planning):** 2026-04-22  
**Archived:** 2026-04-22  
**Phases:** 5 (57–61) | **Requirements:** 10 (**EVID-01**, **LIB-01**–**LIB-03**, **OPS-PB-01**–**OPS-PB-05**, **SHIP-01**) | **Hex:** `scrypath` **0.3.4** (in-repo playbook surface; no mandated publish)

### What was built

**B1** evidence discipline (**`.planning/EVID-01-b1-v1.14.md`**), **`Scrypath.Errors`**-shaped actionable failures, **`ScrypathOps.Playbook.V1`** JSON codec with **`SearchPlayground`** ceilings, portable playbook files, **`/ops/playbooks`** operator UX, and stub-backed LiveView proof of **save → list → load → run** plus **`search_many`** runs.

### What worked

Keeping **OPSUI-FUT-01** bounded to **export/import** + explicit env (**`SCRYPATH_OPS_PLAYBOOK_DIR`**) avoided a premature **Ecto** catalog while still shipping replay value.

### What was inefficient

**`gsd-sdk query milestone.complete`** still fails (**`version required for phases archive`**), so milestone close remained **manual** again.

### Key lessons

When the audit verdict is **`tech_debt`**, ship the milestone but keep the audit file attached to **`milestones/`** so hygiene gaps (copy, optional **`docs_contract_test`** anchors, SUMMARY frontmatter) stay discoverable without blocking the archive.

---

## Milestone: v1.13 — Public polish & narrative coherence

**Shipped (planning):** 2026-04-22  
**Archived:** 2026-04-21  
**Phases:** 3 (54–56) | **Requirements:** 5 (**POLISH-01**–**POLISH-05**) | **Hex:** `scrypath` **0.3.4** (narrative + doc polish; no mandated publish)

### What was built

Adopter-facing **`guides/`** voice cleanup (**`guides/per-query-tuning-pipeline.md`**, pitfalls ledger discipline), **Hex `0.3.4`** alignment across **README** and planning files, contributor-first **`AGENTS.md`**, and **`milestone-candidates.md`** refresh toward **Tier B1**.

### What worked

**`audit-open`** stayed green without inventing new stub directories; requirements stayed small and fully traceable to phases **54–56**.

### What was inefficient

**`gsd-sdk query milestone.complete`** still fails (**`version required for phases archive`**), so **`milestones/v1.13-*`**, **`ROADMAP`** collapse, and **`git rm` REQUIREMENTS** were **manual** again (**v1.10–v1.12** pattern).

### Key lessons

When the SDK milestone automation is broken, keep the **manual archive + `docs_contract_test` fallback chain** honest so **AUDT-01** rows remain discoverable without a live root **`.planning/REQUIREMENTS.md`**.

---

## Milestone: v1.12 — Developer onboarding & first-hour QoL

**Shipped (planning):** 2026-04-22  
**Archived:** 2026-04-21  
**Phases:** 3 (51–53) | **Plans:** 9 | **Hex:** `scrypath` **0.3.3** (doc truth, actionable errors, contributor OPSUI verify path in-repo)

### What was built

Contract-true adoption path across README, **`guides/golden-path.md`**, **CONTRIBUTING**, and Phoenix example CI; bounded actionable **`{:error, _}`** messages and **`guides/common-mistakes.md`**; root **`mix verify.opsui`** documented and pinned in **`docs_contract_test`**.

### What worked

Resolving **`audit-open`** with **[R]** surfaced a pure naming mismatch: **`audit.cjs`** only reads **`SUMMARY.md`**, while historical quick tasks only had **`260416-*-SUMMARY.md`**. Adding **`SUMMARY.md`** cleared the gate without re-litigating completed work.

### What was inefficient

`gsd-sdk query milestone.complete` still fails (**`version required for phases archive`** — **`milestoneComplete` → `phasesArchive([])`**), so **`milestones/v1.12-*`**, **`ROADMAP`** collapse, and **`git rm` REQUIREMENTS** were **manual** again.

### Key lessons

When **`audit-open`** and on-disk artifacts disagree, verify the scanner’s expected filenames before treating rows as missing work.

---

## Milestone: v1.11 — Operator shell polish and JTBD verification

**Shipped (planning):** 2026-04-21  
**Phases:** 3 (48–50) | **Plans:** 11 | **Hex:** `scrypath` **0.3.3** (OPSUX polish in-repo **`scrypath_ops`**)

### What was built

**`operator-ia.md`** ↔ **`router.ex`** maintainer contracts, posture **JTBD** next-check list, shared **`/ops`** page scaffold with **system/light/dark** coherence, Phoenix **`ops_shell_contract_test`**, and **`ops_a11y_contract_test`** + **`mix scrypath_ops.opsui.test_a11y`** slice.

### What worked

Reconciling **`.planning/REQUIREMENTS.md`** checkboxes and the traceability table **before** close avoided “pending” rows that phase summaries already satisfied.

### What was inefficient

`gsd-sdk query milestone.complete` failed again (**`version required for phases archive`**), so **`milestones/v1.11-*`**, **`ROADMAP`** collapse, and **`git rm` REQUIREMENTS** were **manual** like **v1.5–v1.10**.

### Key lessons

Treat **REQUIREMENTS.md** as a living contract with **SUMMARY.md** metadata: when **`requirements-completed`** appears in YAML, update the traceability table in the same session.

---

## Milestone: v1.10 — Operator admin UI (OPSUI)

**Shipped (planning):** 2026-04-21  
**Phases:** 4 (44–47) | **Plans:** 14 | **Hex:** `scrypath` **0.3.3** (OPSUI as in-repo **`scrypath_ops`**)

### What was built

Optional **`scrypath_ops`** Phoenix app with JTBD **`operator-ia.md`**, conventional LiveView structure, prod **`OPSUI_AUTH_MODE`** fail-closed boot, posture + **`failed_sync_work/2`** triage + read-only sync/drift, bounded search playground with stubbed backend for CI, federation-honest multi-search inspector, and contract tests pinning IA routes and security copy.

### What worked

Reusing **library-owned structs and guides** as the source of truth kept the UI from inventing merge semantics; **stub adapter** tests gave fast CI without Meilisearch.

### What was inefficient

`gsd-sdk query milestone.complete` still throws **`version required for phases archive`** ( **`milestoneComplete` → `phasesArchive([])`** bug), so **`milestones/v1.10-*`**, **`MILESTONES.md`**, **`ROADMAP`** collapse, and **`git rm` REQUIREMENTS** were **manual** again (**v1.5–v1.9** pattern).

### Key lessons

When **`audit-open`** repeats the same **missing quick-task** rows across milestone closes, **append an explicit v1.N acknowledgment** so **`STATE.md`** stays auditable without pretending the stubs were fixed.

---

## Milestone: v1.9 — Per-query relevance & tuning pipeline

**Shipped (planning):** 2026-04-20  
**Phases:** 2 (42–43) | **Plans:** 5 | **Hex:** `scrypath 0.3.3` (unchanged line; per-query spec + runtime in-repo)

### What was built

Locked **`guides/per-query-tuning-pipeline.md`** plus **Plane B** **`:per_query`** overrides on **`%Query{}`**, Meilisearch projection for ranking-score knobs, **`search_many/2`** inner merge rules, telemetry metadata, focused tests, **`mix verify.phase43`**, and **`docs_contract_test.exs`** pins mirroring the federation gate pattern.

### What worked

Reusing the **spec-first gate** (**TUNE-PIPE-***) before runtime work kept precedence and error shapes legible; **`verify.phase43`** gave **`TUNE-PQ-02`** a named CI home without widening **`verify.phase41`**.

### What was inefficient

`gsd-sdk query milestone.complete` failed again (**`version required for phases archive`**), so **`milestones/v1.9-*`** and **`ROADMAP.md`** collapse were **manual** like **v1.5–v1.8**.

### Key lessons

Sync **`.planning/REQUIREMENTS.md`** checkboxes and the traceability table when phases close so close does not fight “pending” rows that verification already satisfied.

---

## Milestone: v1.8 — Multi-index federation

**Shipped (planning):** 2026-04-20  
**Phases:** 3 (39–41) | **Plans:** 6 | **Hex:** `scrypath 0.3.3` (unchanged line; federation behavior + verify slice in-repo)

### What was built

Weighted **`search_many/2`** rows with Meilisearch **`federationOptions.weight`**, deterministic **`merge_hit_order`**, and **`MultiSearchResult.merge_projection/1`**; **`:all`** expansion with env/config allowlists and explicit **`{:invalid_options, {:all_expansion, _}}`** errors; **`guides/multi-index-search.md`**, **`mix verify.phase41`**, and **`docs_contract_test.exs`** anchors.

### What worked

Tight coupling between **public opts**, **wire JSON**, and **contract tests** kept federation semantics explainable without a UI milestone.

### What was inefficient

`gsd-sdk query milestone.complete` failed again (**`phasesArchive`** / version argument), so archival stayed **manual** like **v1.5–v1.7**.

### Key lessons

Keep **`audit-open`** hygiene items **acknowledged in `STATE.md`** when UAT is **passed** but tooling still counts the row, so close stays honest without inventing new work.

---

## Milestone: v1.7 — Facet depth and catalog search UX

**Shipped (planning):** 2026-04-20  
**Phases:** 3 (36–38) | **Plans:** 7 | **Hex:** `scrypath 0.3.3` (unchanged line; facet APIs + verify gates in-repo)

### What was built

Hierarchical facet declaration and decode path with **`mix verify.phase36`**; disjunctive distribution merge helper + guide + **`mix verify.phase37`**; public **`search_within_facet/4`** with integration tests, LiveView guide sections, **`mix verify.phase38`**, and README / module-doc discoverability.

### What worked

Focused per-phase verify tasks (**36**–**38**) kept CI slices small while encoding the regression coupling (**37** calling **`verify.phase36`**).

### What was inefficient

`gsd-sdk query milestone.complete` still fails (`phasesArchive` invoked without a version argument in the installed SDK), so roadmap/requirements archival remained a manual checklist — same class of issue as **v1.5**/**v1.6**.

### Key lessons

Treat **`audit-open`** totals that include **passed** UAT files and **missing** historical quick-task dirs as **ack-and-close** ledger entries so hygiene tooling does not block shipping real verification.

---

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

## Milestone: v1.30 — Release Trust and Evidence Maintenance

**Shipped:** 2026-06-01
**Phases:** 4 (109-112) | **Plans:** 11

### What Was Built

Release-source agreement and package-shape proof were hardened in `mix verify.phase11`; support intake and outside-adopter evidence routing were pinned through `mix verify.adopter`; `phase105-e2e` stayed advisory with explicit promotion thresholds; public website/docs truth was aligned around route-first pages and the canonical scope/reopen policy.

### What Worked

Focused service-free verification kept the milestone auditable without widening required CI. The release/support/proof/public-truth work stayed inside the maintenance lane and preserved the post-v1.29 done posture.

### What Was Inefficient

The closeout audit passed requirements and flows but still surfaced metadata/process debt, especially Phase 111 validation frontmatter and standalone public-truth proof that depends on maintainer discipline rather than required CI.

### Patterns Established

- Maintenance milestones should pin drift-prone public truth with small direct-file contract tests.
- Advisory browser proof can be useful when promotion thresholds, artifact names, and owner-response rules are explicit.
- Website pages should route to canonical authorities instead of becoming a second docs site.

### Key Lessons

Do not reopen feature scope to make proof feel more complete. Accept non-blocking proof/process debt explicitly at close, then require concrete adoption or drift signal before starting another milestone.

---

## Cross-Milestone Trends

| Milestone | Phases | Dominant theme |
|-----------|--------|------------------|
| v1.30 | 109-112 | Release/package truth, support intake routing, advisory proof stability, and website/docs truth alignment |
| v1.15 | 62–64 | OPSUI second slice: playground capture, playbook catalog/metadata, bounded team persistence + validate Mix |
| v1.14 | 57–61 | B1 evidence gate + operator playbooks: **`Playbook.V1`**, **`/ops/playbooks`**, portable JSON |
| v1.9 | 42–43 | Per-query tuning: locked pipeline spec, `:per_query` runtime, verify.phase43 |
| v1.8 | 39–41 | Multi-index federation: weights, `:all` expansion, docs + verify.phase41 |
| v1.7 | 36–38 | Meilisearch facet depth: hierarchy, disjunctive counts, scoped text search |
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
