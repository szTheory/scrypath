# Scrypath

## What This Is

Scrypath is an open-source Elixir library for declarative, Ecto-native search indexing and search orchestration. It helps Phoenix and Ecto teams add search to existing schemas with a small amount of code while handling synchronization, reindexing, and operational workflows in a way that feels native to the Elixir ecosystem.

## Core Value

Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Verification Default

Shift verification left by default. Turn recurring user paths, seams, integrations, smoke checks, and failure cases into deterministic executable proof, and run it in CI when its repeat confidence is worth its runtime and maintenance cost. Keep expensive or lower-frequency evidence scheduled or advisory when that is the better tradeoff. Aim for zero routine human verification or UAT; hand off only semantic product or risk judgments, external credentials or permissions, and physical-world checks that cannot be automated. Reuse passing evidence within its stated source and scenario boundaries, and rerun only when a named invalidator changes. Record decisions and revisit triggers so completed work does not restart without new evidence. For GSD phase closeout, list each completed roadmap requirement ID in that phase’s `VERIFICATION.md` with its evidence and result, and run the milestone audit before archive or freeze.

**Freeze and GSD tracking:** Before a terminal source freeze, define where GSD will record the later plan summary, phase verification, and milestone audit. Keep the attested source ref immutable. If the external terminal workflow is complete but its frozen planning bytes cannot represent that outcome, preserve those original bytes and create an explicitly authorized, dated tracking replacement in the separate planning checkout. The current tracker must distinguish its later bookkeeping from the attested source identity. Do not replay completed terminal work to satisfy an index, infer semantic completion from an addendum, or use a verification override without maintainer authorization. This workflow was applied to Phase 170 on 2026-10-02; see its `170-08-TRACKING-REPLACEMENT.md` record.

**Operator UI default:** Use the existing design system and established interaction patterns; maintain a coherent token/component vocabulary and translate internal concepts into concise user-facing language without erasing operational distinctions. The curated, evidence-labeled role/JTBD model and internal-to-user terminology map live in `reference/OPERATOR-UI-QUALITY.md`; review only affected assumptions when evidence changes. Keep a live preview available for optional feedback, inspect before/after screenshots, and automate meaningful layout, keyboard, state and service checks without recurring paid AI review. Record decisions and revisit triggers to avoid redesign churn.

**Operator visual revision evidence (2026-10-06):** The maintainer's concrete feedback opens the shared page background, warning/metric/schema coloration, theme selection, quiet-action states, and operational timestamp/copy patterns for revision. Begin the approved v1.43 UI refinement milestone with representative light/dark comps and shared token work, then propagate the chosen patterns across the six operator surfaces. Preserve product truth and the Scrypath identity; the exploratory brand book is not a binding color contract. See `reference/OPERATOR-UI-REFINEMENT.md`. The v1.43 requirements and Phases 173–177 are approved; no shipped improvement is claimed by milestone setup.

**UI refinement workflow:** The v1.43 milestone consumes `MILESTONE-CONTEXT.md`; its original input and scope decisions are preserved in `research/v1.43/MILESTONE-CONTEXT.md` and `research/v1.43/SCOPE.md`. Use the installed Impeccable skill with the existing root `PRODUCT.md`, `DESIGN.md`, and comp-first configuration for scoped visual work. Carry selected decisions into the frontend phase's GSD `UI-SPEC.md` before planning and into delivered token/component documentation. GSD lifecycle bookkeeping and Impeccable design guidance must share the same decisions; do not repeat initialization or assume Impeccable is invoked automatically.

**Operator audience and automation direction (maintainer direction, 2026-10-06):** Treat Ecto/Phoenix integrators and the people who keep their search healthy after launch as co-primary user roles. ScrypathOps remains optional to mount and outside the Hex package, but a browser-based operator surface is expected to be a practical need for most production adopters; the UI, CLI, and library APIs should support one coherent inspect/recover/verify job. This is a maintainer expectation, not measured adopter data. Today the host team operates Meilisearch infrastructure such as provisioning, capacity, backups, and restores. Scrypath's long-term north star is to shift operational toil left and automate more as real adopter feedback shows what is safe and useful, while retaining manual paths and making state and outcomes transparent. This is direction, not a shipped claim or approved new milestone scope.

**Saved search storage (maintainer decision, 2026-10-22, SEED-003 / UI-FEEDBACK Q14–Q17):** ScrypathOps stores saved searches in a `scrypath_ops_saved_searches` table in the host Repo passed to `scrypath_ops_routes/2` (optional `prefix:`), created by the versioned, Oban-style `ScrypathOps.Migration.up/down(version: 1)` called from a one-line host migration. This is the first table ScrypathOps owns, so adopters now run one migration. Folder-based storage (`playbook_workspace_dir`, read-only examples mode, storage-folder disclosure) is removed; the v1 saved-search JSON (`playbook_format: 1`) remains the import/export interchange. “Playbook” is retired in code and docs in favor of “saved search” (`ScrypathOps.SavedSearches.*`, `mix scrypath_ops.saved_searches.validate`); the `/playbooks` URL is kept until the Search-toolbar restructure (UX-11).

**GSD handoff default (maintainer direction, 2026-10-04):** At every phase or milestone boundary, name the phase and milestone just completed, then give the exact next GSD command with its phase number when applicable and explain how it advances approved work. Do not substitute a generic progress/next dispatcher when the concrete command is known. Before recommending a context reset, persist the scope, decisions, verification evidence, unresolved items, working directory/branch, and next action in `.planning/`. Keep the normal project checkout ready for that action when safe; preserve other branches, stashes, and attested source refs. If no work is approved, say so and route to `$gsd-new-milestone` for scope selection without inventing or executing a phase. Never replay completed work merely to refresh context. A handoff after final attestation belongs in a clearly separate planning-only successor; its metadata does not extend the prior exact-SHA evidence.

## Current Milestone: v1.45 Foundation and CI

**Goal:** Make browser verification complete and reliable, keep maintainer tooling out of the Hex package, reduce dependency overhead, and establish executable UI quality foundations for v1.46.

**Target features:**
- Restore the full standalone browser lane and run the currently skipped follow-up scenarios using an audited inventory and correct port guards.
- Move repository-only verification tasks and their support modules to `dev/mix/tasks`, preserving contributor commands and enforcing built-package parity.
- Declare Telemetry directly, admit the approved Req version ranges, trim ScrypathOps dependencies, consolidate applicable Dependabot changes, and improve CI caches.
- Establish the shrink-only L1 token ratchet, Tailwind colour-namespace reset, required contrast/focus checks, DTCG Ops tokens and drift proof; remove unused generator markup and the paid visual-judge path.

**Scope and provenance:** The maintainer confirmed section 3 of `reference/ROLLING-ROADMAP.md` on 2026-10-26 through `$gsd-new-milestone`. Phase numbering continues at 182 after completed Phases 178–181. The UI engine and pilot remain v1.46, surfaces/polish v1.47, and adopter features v1.48. Preserve current visible UI, retained-preview data, the five lean required gates and existing advisory lane posture. No manual UAT or paid visual judge is introduced.

**Definition decisions (2026-10-26):** The maintainer selected reuse of existing research and explicitly confirmed all 21 requirements in `REQUIREMENTS.md`. The maintainer separately approved the four-phase roadmap (182–185). Phase 182 completed on 2026-10-27 with all five browser/cache requirements verified; Phase 183 is ready for discussion. The remaining v1.45 phases are not implemented by this result.

**Delivery context:** Planning starts on `planning/v1.45-foundation-ci` from the local v1.44 archive commit `5ac5045f`. PR #122 merge and Hex publication remain separate pending work as recorded at this planning boundary; prior source-bound evidence is unchanged. The unrelated `.planning/config.json` edit is preserved and excluded from milestone commits.

## Most Recent Milestone: v1.44 Sync correctness (archived locally)

**Goal:** Every sync path (inline, Oban, backfill and reindex) builds the same documents through one loader, pages through every row, and reports what it did, so no path silently skips or drops work.

**Target features:**
- Backfill and reindex load records through `Scrypath.Loader` (`preload:`, `search_records/2`), matching inline and Oban sync.
- Keyset paging covers the full primary key, so composite keys no longer skip rows (maintainer decision, 2026-10-25: page on the full key rather than reject composite keys).
- `sync_related` resolvers always receive records, under both inline and Oban sync.
- The Oban workers emit telemetry with stable metadata, including deletes for ids that no longer exist.
- Id lists are chunked (about 1000 per call) for loads and backend calls.
- `RelatedEnqueue` matches the main enqueue path (`unique:`), and job-arg atom decoding fails safely.
- Schema hooks are declared as `@optional_callbacks`.
- A loader test runs against a real database.
- The real no-Oban type warning is fixed through the shared runtime-guarded job builder, with no blanket warning suppression.

Scope source: section 2 of `reference/ROLLING-ROADMAP.md`. Scope covers the core library, examples, tests, docs and existing CI lanes; no visible UI work or new required job was added. Completed phases are 178–181.

## Current State

**Current as of 2026-10-28 — v1.45 Phase 182 complete (2026-10-27):** all eight plans and five browser/cache requirements have executable verification and source-bound local/hosted acceptance. Three milestone phases remain. Continue with `$gsd-discuss-phase 183`; the unrelated config edit and retained preview remain preserved. This result does not merge PR #122 or publish to Hex.

**Historical cutoff, 2026-10-26 — v1.44 local archive:** 4 phases, 17 plans,
45 tasks and all 15 requirements are implemented and verified. The
[audit](milestones/v1.44-MILESTONE-AUDIT.md) remains `tech_debt`: 8/8
connections, 7/7 required flows, all Nyquist records compliant. Fresh core
953 tests + 5 properties, targeted 405 + 1 and Postgres 15 + 1 passed with zero
failures. All four GSD verification reads pass before phase relocation.

All 19 audit-debt items are carried forward for this milestone archive; this
is not a blanket security-risk acceptance. The global artifact scan is clear
only with two explicit historical acknowledgments: the unresolved Phase 124
owner gate and Phase 173 shell-test note. The latter could not be tested
locally because cached dependencies disagree with its lockfile. The earlier
`ops-ui-path` success is a selector result, not an Ops test run.

PR #122 merge and Hex publication remain pending. The existing candidate
receipt at `433c8343` remains source-bound. Final archive/tracking edits precede
a terminal exact-source check; its receipt stays outside the tested checkout.
No phase is active, no independent review is claimed, and the unrelated
config edit remains preserved.

## Next Milestone Goals

v1.45 Foundation and CI has 21 confirmed requirements and an approved four-phase roadmap. Phase 182 is complete (8/8 plans; BROW-01–03 and CACHE-01–02 verified). Run `$gsd-discuss-phase 183` to clarify the package/tooling boundary before planning. v1.46–v1.47 cover the UI quality engine, followed by v1.48 adopter features. Merge/release handling of PR #122 remains separate.

**Current as of 2026-10-25:** v1.43 **ScrypathOps UI refinement** is complete and archived: 20/20 requirements (OPUX-09–OPUX-28), Phases 173–177, 21/21 plans and five passing phase verifications. Its work first shipped in `scrypath` 0.3.16; 0.3.17 followed as a sync hotfix. The terminal merged-main closeout passed in [CI run 40204029522](https://github.com/szTheory/scrypath/actions/runs/40204029522) at `ebed49b5199d369306527caa7bb69aa0b1db5a36` and is recorded in `reference/v1.43-final-receipt.json`. That run closed T-177-05; T-177-06 stays open as a medium recordkeeping gap below the blocking threshold. The maintainer waived only the formal-review gate; no formal review is claimed. The next approved work is the rolling roadmap in `reference/ROLLING-ROADMAP.md` (v1.44 sync correctness next). Archive: `milestones/v1.43-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md` and `milestones/v1.43-phases/`.

**Historical, 2026-10-13:** Phase 174, Recovery Entry and Diagnosis, is complete locally: 3/3 plans, all 19/19 must-haves verified, and current-source Ops/UI and mounted checks passed. All five v1.43 phase plan sets and verification reports are complete. PR [#98](https://github.com/szTheory/scrypath/pull/98) is draft at exact head `bebeb863493d1667ffa5f8c9fa3e890b484c5c1a`; [CI run 38338089123](https://github.com/szTheory/scrypath/actions/runs/38338089123) passed all five required checks and both Ops UI checks on that exact source. The Website build passed. `deep-quality (advisory)` failed and `ecommerce-e2e (advisory)` was skipped; the dependency-audit follow-up remains disclosed in the Phase 177 trace. Candidate closeout on the final tracking source and terminal merged-main attestation remain outstanding, so T-177-05 still blocks the milestone audit. The maintainer waived only the formal-review gate; no formal review is claimed. Do not audit or archive v1.43 until terminal closeout evidence is recorded. The retained feedback preview remains at `http://127.0.0.1:4012/admin/search`.

This branch also adds the bundled Scrypath favicon to the mounted e-commerce operator UI under its mount path. SVG/ICO routes and rendered links are covered by focused tests; the exact PR source above passed the required mounted and Ops UI CI checks.

**Current as of 2026-10-10:** Phase 173, Shared Visual Foundation and Operational Time, is complete locally at `b12a7c47157b4fb88b05237b7e2525d11896fd59`: 4/4 plans, OPUX-09–OPUX-15, 41/41 plan truths, final Ops/UI checks, code and UI review, and security audit are recorded in its phase artifacts. No hosted source receipt is claimed. Phase 174, Recovery Entry and Diagnosis, is next to discuss and plan; Phases 174–177 remain in the approved execution order. The retained feedback preview remains at `http://127.0.0.1:4012/admin/search`.

**Current as of 2026-10-06:** v1.43 **ScrypathOps UI refinement** has an approved 20-requirement roadmap across Phases 173–177 and has four independently checked Phase 173 implementation plans ready to execute. The maintainer approved the saved scope and the recommendation to reuse existing UI inventories rather than run fresh ecosystem research. The maintainer explicitly approved the detailed requirements and phase boundaries on 2026-10-06. The first phase is 173; no implementation phase has started. Current uncommitted UI/design work and the feedback preview remain preserved. v1.42 and its exact-source receipts remain archived and source-bounded.

**Current as of 2026-10-04:** v1.42 ScrypathOps operator/admin UI is complete: Phase172, eight plans and all eight OPUX requirements. PR [#91](https://github.com/szTheory/scrypath/pull/91) delivered the UI and core correctness fixes as `3ad154a33f99cb200b791577aadc5970adc70ca2`; main CI37180290165 passed. Scrypath **0.3.15** is published as `scrypath-v0.3.15` at `8dd20e8966acd17a4ef5acec653c00dc31faab49` through Release Please PR [#92](https://github.com/szTheory/scrypath/pull/92). [Publish run 37181522723](https://github.com/szTheory/scrypath/actions/runs/37181522723) passed publication, live Hex/HexDocs/consumer verification and tag parity. Candidate CI37178388184 passed104 browser tests and4 mounted tests with retries disabled; PR CI37178390800 also passed scoped Ops. The GSD archive preserves requirement, visual, review/security and delivery evidence. Completion records precede final exact-source attestation, whose receipt is external to the frozen final source. No active phase or additional approved work remains; preview4012 is retained for optional feedback.

The following paragraphs preserve earlier dated source/release/readiness baselines. They do not certify changed v1.42 UI source.

**Current as of 2026-10-02:** Scrypath 0.3.14 is published as `scrypath-v0.3.14` at `9909756f25f3891548690c6b26d74e2b2f3bcb13`; [run 36915979826](https://github.com/szTheory/scrypath/actions/runs/36915979826) verified Hex/tag parity. The original Phase 170 decision remains **NOT READY** at its 2026-10-01 cutoff ([issue #86 comment 5940381507](https://github.com/szTheory/scrypath/issues/86#issuecomment-5940381507)); a fresh maintainer assessment is **READY** at [issue #86 comment 5955742805](https://github.com/szTheory/scrypath/issues/86#issuecomment-5955742805). Conditions 1–5 were carried forward within their recorded limits; condition 6 passed on the post-freeze tracker reconciliation, validator correction, release/package parity, and current source evidence. Inherited assumptions EA-167-01 through EA-167-07 remain unresolved, so this is not a blanket adopter or deployment guarantee. Validator fix PR [#89](https://github.com/szTheory/scrypath/pull/89) merged as `eb9233cfc60fa027f2fab5bccff00e46f9c7a69f`; exact-main closeout run [36930660896](https://github.com/szTheory/scrypath/actions/runs/36930660896) passed required jobs, coverage, E2E, and closeout attestation. Planning-only PR [#90](https://github.com/szTheory/scrypath/pull/90) merged at `161d5bd0a360fd1951aa3a0e66f5c6297857ce01`; its exact-tree PR run [37023495862](https://github.com/szTheory/scrypath/actions/runs/37023495862) passed all five required jobs. v1.41 is complete across Phases 168–171 and 19 plans. The frozen `8c271…` source snapshot remains a historical 17/18 snapshot; the separate authorized tracking replacement records Plan 08 complete without changing those frozen bytes or rerunning Phase 170. The v1.41 audit accepts visible, nonblocking Nyquist validation-record debt. See `milestones/v1.41-phases/170-documentation-and-readiness-closeout/170-08-TRACKING-REPLACEMENT.md` and `milestones/v1.41-phases/170-documentation-and-readiness-closeout/170-POST-FREEZE-RECONCILIATION.md`.

The paragraph below preserves the prior dated baseline; later v1.41 evidence and the current release facts above supersede its then-current release and readiness claims.

Scrypath 0.3.13 remains the published package; v1.40 was a planning milestone and made no package release. The tenant-option and facet-filter corrections identified in v1.40 have since been merged to public `main` through PR #85 and verified at exact merge SHA `933ad30645c41df9f21dd4ddfd2d5b93fbd48620` (CI run [36644133759](https://github.com/szTheory/scrypath/actions/runs/36644133759)); this is source delivery, not a Hex release. v1.40 Readiness Evidence Closure is archived locally across Phases 165–167. Its audit records all 11 requirements, three phase verifications, 11 integration paths, and five end-to-end flows as passing, with bounded `tech_debt` carried forward. The separate assessment at `2026-09-27T19:39:00Z` remains **NOT READY**: conditions 1/3/4/5 PASS, condition 2 FAIL because the Phoenix consumer lock retains Mint 1.9.3 with an unresolved High advisory, and condition 6 UNKNOWN at that cutoff. The final phase-tracking source `343e20be66ab0c17f62b95138203c86e868bd1ee` passed exact-SHA run [36361116862](https://github.com/szTheory/scrypath/actions/runs/36361116862), and archive closeout later passed on the v1.40 tag; neither changes the dated assessment. v1.41 begins a fresh evidence-backed follow-through while preserving that historical result. See `milestones/v1.40-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`.

The prior v1.39 planning milestone shipped and was archived on 2026-09-26; it added no runtime, public API, dependency, backend, or operator UI changes. Its dated readiness decision remains **NOT READY** because conditions 3 and 6 were unknown at assessment. Its accepted audit debt records three Phase 164 cross-references and Nyquist metadata follow-up for Phases 163–164. Final exact-SHA run [36257182675](https://github.com/szTheory/scrypath/actions/runs/36257182675) passed for `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`; the annotated `v1.39` tag resolves to that commit. This receipt can support a newly dated condition 6 assessment but does not change the historical result.

## Archived Milestone: v1.43 ScrypathOps UI refinement (2026-10-25)

**Goal:** Make the existing six-surface operator workspace calmer and easier to scan and act on across inspect → recover → verify, while preserving operational truth and supported behavior.

**Target features:**
- Establish shared visual foundations with realistic light/dark comps: flat neutral backgrounds, restrained local status cues, neutral zero-error metrics, one selected theme preference, coherent action states, and readable operational timestamps with truthful copy feedback.
- Clarify state, affected work/schema, and the next safe action across Control Room, Search health, and Failed sync work; keep exact identifiers, evidence, and selected-schema handoffs.
- Separate observation, contract drift, document freshness, repair, and advanced promotion on Sync and drift; preserve existing confirmation, eligibility, and accepted/terminal/unknown boundaries.
- Refine Search and Playbooks form/result structure, preview versus execution, and common versus occasional action priority.
- Consolidate demonstrated shared patterns, delivered design documentation, and economical automated/visual evidence through PR-first delivery.

**Scope agreement:** 2026-10-06 — maintainer accepted the recommended scope/version and inventory reuse. The maintainer explicitly approved all 20 requirements and the five-phase roadmap on 2026-10-06. Numbering continues after archived Phase 172; GSD milestone numbering is separate from Hex package versions.

**Design lifecycle:** Discuss the first frontend phase, use Impeccable Operate guidance and representative light/dark comps to settle visual direction, capture it in `UI-SPEC.md` via `$gsd-ui-phase`, then plan. Keep comp selection before broad visual implementation; phase closeout uses executable proof and direct agent image inspection without pending routine UAT.

**Basis:** `reference/OPERATOR-UI-REFINEMENT.md`, `reference/OPERATOR-UI-QUALITY.md`, root `PRODUCT.md` / `DESIGN.md`, and `research/v1.42/UI-{SYSTEM,STRUCTURE,AUTOMATION}.md`. Historical findings are orientation, not new passing evidence or an instruction to replay completed fixes. Recheck touched source during phase preparation. Preserve adaptive routing, existing UI gates, the current working tree, and preview data.

## Archived Milestone: v1.42 ScrypathOps operator/admin UI (2026-10-04)

**Goal:** Make the existing operator UI consistent, legible, and conventional, anchored by a clear incident-recovery path across Control Room, Posture, Failed Sync, and Sync/Drift with recovery verified from authoritative task/index state.

**Target features:**
- Inventory existing flows, states, and shared components across all six operator surfaces; repair demonstrated typography, layout, keyboard, and content-hierarchy gaps through the existing token/component system.
- Use coherent domain copy, visible common actions, and an incident path that retains schema context and distinguishes accepted work, terminal outcomes, and retained failure history.
- Add deterministic browser proof for the cross-screen recovery journey, correlated to new work and the expected indexed document; retain truthful status instead of requiring a universally green dashboard.
- Keep recurring proof in existing CI lanes where its confidence justifies the runtime and maintenance cost, with direct screenshot inspection, zero routine human UAT, and no paid visual-judge API by default.

**Context:** The maintainer's 2026-10-03 UI cleanup direction expands the earlier incident-only proposal to evidence-backed consistency repairs across the six existing surfaces. Existing design-system work from v1.32–v1.34 remains the baseline. Current Playwright coverage exercises failed-sync triage and sync/drift promotion separately; its fixtures/oracles need correction before they prove recovery. No new Scrypath core API, backend capability, auth model, component framework, or unrelated UI surface is in scope. Existing-project research and captured baseline findings are in `research/v1.42/SUMMARY.md`; completed requirements are in `milestones/v1.42-REQUIREMENTS.md`.

## Future Work

Keep `main` green and release only when a package change warrants it. v1.44 is archived locally; PR #122 merge/publication remain pending. The approved rolling roadmap in `reference/ROLLING-ROADMAP.md` sets the next order (v1.45 foundation and CI, v1.46–v1.47 UI quality engine, v1.48 adopter features). Runtime, backend, authentication, infrastructure automation, and new workflow/surface scope still require separate evidence and decisions. Retain the Phase 170 freeze/tracker rule and historical record as archived.

## Archived Milestone: v1.41 Readiness Gate Follow-Through (2026-10-02)

**Goal:** Deliver evidenced security and existing contract corrections, improve economical recurring verification and adopter guidance, and reach a current, source-bounded non-UI readiness decision.

**Approved outcomes after review:**
- Mint 1.11.0+ (rechecked against current advisories) in root, Phoenix, ecommerce and standalone Ops graphs, including necessary HPAX updates; audit every maintained graph in the existing advisory lane and prove effective path/package dependency identities.
- Deliver the mounted-readiness correction early with security verification, then merge the known tenant-option/facet-filter corrections with their coherent regression/adopter evidence on clean public-main PR bases.
- Freeze and disposition the Phase 169 bot cohort by value; account for remaining owned local work without importing every historical planning commit or silently deferring selected fixes.
- Preserve first-hour context and operational caveats while consolidating README/JTBD detail/routes and directly related stale canonical wording/assertions.
- Complete the warranted Release Please patch after final docs delivery, then join the six condition judgments to final source/attestation and delivery evidence in one durable terminal record outside the tested tree.

**Boundaries:** No new public API/backend capability, operator UI implementation, direct dependency-policy expansion, blanket upgrades, required CI job or broad matrix. Ops dependency maintenance is in scope. Selected delivery/release blocked by external prerequisites remains explicit; an owner deferral is never inferred. Preserve unrelated worktree state and historical assessments. When a new scope is approved, review the current project context and research before downstream GSD planning. The completed v1.41 requirements and roadmap are preserved under `.planning/milestones/`.

## Archived Milestone: v1.40 Readiness Evidence Closure

**Archived:** 2026-09-27 as a planning milestone, with no Hex release. The full roadmap, requirement outcomes, audit, and phase records are in `milestones/v1.40-*`. Its audit accepts bounded tech debt; the dated assessment remains NOT READY.

**Goal:** Close decision-relevant adopter evidence gaps for tenant-safe search and bounded repair, reuse valid delete and release receipts, and make a fresh six-condition readiness decision without starting operator UI work.

**Target features:**
- Reproduce the existing public tenant-scope and facet-value input contracts; correct only confirmed compatible defects.
- Prove one representative host-owned tenant authorization/search workflow and one bounded manual repair through terminal task success to visible search, reusing existing test and CI harnesses.
- Reuse the exact-SHA delete and v1.39 closeout/publication receipts within their recorded limits; create a separately dated condition 3/6 assessment and reconcile task-owned cleanup and release-reference truth.

**Boundaries:** Host applications retain ownership of authentication, membership policy, trusted tenant selection, and database response scoping. Do not add an auth framework, public backend abstraction, broad endpoint/version matrix, operator UI, or forced Hex release. A fresh readiness assessment may remain **NOT READY** if a condition is not evidenced.

**Research:** `.planning/research/v1.40/SUMMARY.md` and its four claim-specific reports record the source evidence, tradeoffs, and proof limits that inform this scope.

<details>
<summary>Archived v1.39 planning context</summary>

**Goal:** Assess Scrypath's non-UI quality and adopter readiness, close evidence-backed critical, high, and medium-leverage gaps in bounded milestones, and establish an auditable gate for when ScrypathOps can become the next strategic focus.

**Target features:**
- Whole-product baseline across the readiness program's named dimensions, reusing current v1.37 and v1.38 evidence where relevant.
- Evidence-ranked disposition and bounded closure of confirmed critical, high, and medium-leverage non-UI gaps.
- Automated acceptance evidence and an auditable readiness decision; operator UI implementation stays out of scope.

**Pre-UI quality readiness:** `.planning/reference/PRE-OPERATOR-UI-READINESS.md` remains the durable program and exit-gate authority. The v1.39 assessment is complete and NOT READY; the historical decision is preserved. A new **READY FOR OPERATOR UI** decision requires evidence for every area and no unresolved critical, high, or medium-leverage non-UI gap. Evidence-backed API/runtime gaps still require explicit scope-guard review.

**Prior completed scope:** v1.38 proved package-backed Phoenix adoption against real services and closed with exact-SHA CI, green post-merge main, Hex/HexDocs publication, consumer compilation, and package-to-tag parity. It preserved the public API and advisory service-lane posture.

</details>

**Automation-first verification policy:** Post-implementation acceptance must be
machine-verifiable, with a standing goal of zero human verification or UAT. For GSD
verification, first map each acceptance claim to explicit passing automated evidence;
when every claim is covered, record the evidence and complete UAT without presenting
a blanket human checkpoint. Hand off only irreducible external actions such as
credentials, permissions, unresolved product decisions, or physical-world checks.
Shift verification left: cover behavior with the cheapest reliable layer that proves
it (unit, contract, or seam tests first, then integration, smoke, and E2E where those
exercise real boundaries). Run checks during implementation and automate them in CI
when their repeat frequency and risk reduction justify their runtime and maintenance
cost. Keep expensive or service-backed checks advisory or scheduled when that gives
recurring confidence without burdening every change; promote checks to required gates
only when their evidence warrants it. CI should own repeatable service setup, health
checks, isolation, timeouts, diagnostics, and teardown whenever practical.

Incomplete plans may not require post-implementation human verification,
`human_needed` disposition, verification backstops, or pending UAT. Convert acceptance
claims to deterministic tests, browser/accessibility automation, API probes, or
exact-SHA hosted evidence. Use human handoffs only for irreducible external actions
such as credentials, permissions, a real product decision, or physical-world checks;
never route routine software acceptance to a user when automation can prove it.
Resolve subjective product decisions before implementation or keep them nonblocking;
do not simulate approvals.

**Recent closed outcomes:**
- v1.39 Phase 164 readiness reconciliation: six dated conditions, explicit NOT READY outcome, bounded source reconciliation, 36 structural contract fixtures, clean code review, 8/8 goal verification, and successful exact-final-SHA closeout; tag `v1.39` points to the final commit. See `milestones/v1.39-phases/164-readiness-gate-and-reconciliation/164-01-SUMMARY.md`.
- v1.38 package-backed Phoenix adopter proof and Scrypath 0.3.13 release: exact-SHA CI, path/package integration, green post-merge main, Hex publication, versioned HexDocs, clean consumer compile, and package/tag parity all passed. See `milestones/v1.38-MILESTONE-AUDIT.md`.
- Phase 159 automated v1.37 audit/provenance closure: reconciled the 31-requirement audit, preserved the bounded TEST-01 chronology waiver, added a fail-closed candidate/final exact-SHA CI authority, and prohibited new post-implementation human verification or UAT debt.
- Phase 147 ecommerce mounted-Ops remediation and closure: bounded the ecommerce web/client graph, added hermetic focused/full Docker E2E verification and an always-running focused CI gate, passed exact-SHA service/browser proof, and closed the four-graph audit ledger with no human UAT.
- Phase 146 ScrypathOps web/client remediation: bounded Phoenix, LiveView, Bandit, Swoosh, Postgrex, and Req; proved the real Req-backed Swoosh client with a discriminating raw-JSON contract; passed standalone Ops and root release gates, detached fresh resolution, live Postgrex/Plug predicates, unsuppressed audit, and security verification.
- Phase 145 legacy Phoenix and Ecto/Decimal remediation: bounded Phoenix, Bandit, Ecto SQL, Postgrex, and Plug to the fixed-compatible cohort; preserved transitive Ecto/Decimal ownership; passed deterministic, detached fresh-resolution, Hex audit, root regression, and Docker-backed Postgres/Meilisearch proof.
- Phase 144 root HTTP client dependency remediation: bounded Req 0.6.3 and Plug 1.19.5 handoff across four checked locks, focused Req.Test/telemetry compatibility proof, full root release-train verification, and clean fresh-resolution Hex audit.
- v1.35 brand system and logo identity: self-contained `brandbook/`, copper `/` `scry/path` logo, subset fonts/tokens, README/ScrypathOps/website adoption, direct-completion archive.
- v1.34 both-themes perfection: ScrypathOps dark signature, light parity, AA hard gate, browser proof, 40-shot matrix, and Human UAT passed.
- v1.33 admin UI polish: task-first IA, design-system tightening, restrained motion, per-screen polish, and shell coherence.
- v1.32 admin UI cleanup: ScrypathOps design tokens, shared operator primitives, mounted e-commerce asset contract, screen cleanup, and focused verification.
- v1.31 adoption-evidence demo pass: richer deterministic Playwright coverage, Docker/dev iteration support, ops UI clarity, evidence summary reporting, and maintainer UAT passed.
- v1.30 release train/package truth, support intake routing, advisory proof stability, and public website/docs truth alignment.
- Repaired generated `__scrypath__(:fan_outs)` for ordinary `use Scrypath, fan_outs:` schemas.
- Tenant-preserving ecommerce readiness regression proof.
- Aligned roadmap/JTBD truth for the repair closeout.

## Canonical Adopter Contract

**Install and version policy:**
- One canonical install/version statement across root docs and adopter-facing intake surfaces.
- `main` may include unreleased changes; stable adopter instructions must point to release-backed truth.

**Support and proof policy:**
- `mix verify.adopter` is the canonical adopter proof spine.
- Fast proof is required for routine PR confidence; repeatable live proof should run in CI when its recurring confidence justifies the cost, and must remain prerequisite-bound and explicit.
- Prefer exact-commit CI evidence for service-backed acceptance so maintainers do not have to repeat routine UAT locally.
- Adopter issue intake must request reproducible evidence and flow classification.

**Non-goals:**
- No expansion into autocomplete/suggestions, vector/hybrid, multi-backend broadening, or new public runtime surfaces.
- No Phoenix UI feature expansion beyond contract-surface clarity.
- No relaxing of framework-agnostic runtime boundaries.

## Scope Guard Authority

Source of truth: `.planning/milestones/v1.27-phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md`

Phase 97 through 99 banned capability classes:
- autocomplete/suggestions
- vector or hybrid retrieval
- public backend broadening
- new public runtime API categories

## Recent Milestone Outcomes

**v1.40 — Readiness Evidence Closure** completed and archived on **2026-09-27** across Phases **165–167**. Public tenant and facet contracts were verified and two compatible defects were corrected; a named Phoenix host proved persisted-membership isolation through path and fresh-package dependencies; an ID-bounded repair reached terminal Meilisearch success and became visible through the same search. The dated assessment remains **NOT READY** (condition 2 FAIL, condition 6 UNKNOWN at its original cutoff). The audit accepts bounded tech debt with all requirements, integration paths, end-to-end flows, phase verifications, and Nyquist checks accounted for. Exact-SHA phase-tracking run [36361116862](https://github.com/szTheory/scrypath/actions/runs/36361116862) passed on `343e20be66ab0c17f62b95138203c86e868bd1ee`; this was a planning close, not a package release. See `milestones/v1.40-MILESTONE-AUDIT.md`.

**v1.39 Phase 164 — Readiness Gate and Reconciliation** completed on **2026-09-26**. The dated decision records conditions 1, 2, 4, and 5 as PASS and conditions 3 and 6 as UNKNOWN, leaving readiness NOT READY. The structural checker and 36 fixtures validate the record contract only; Phase 163's zero-finding result is not promoted to readiness proof. Final exact-SHA closeout run [36257182675](https://github.com/szTheory/scrypath/actions/runs/36257182675) passed on the final archive commit, and tag `v1.39` resolves to that SHA.

**v1.39 Phase 163 — Findings and Bounded Follow-up** completed on **2026-09-25**. All 24 baseline claims have bounded triage; no material Scrypath-owned finding or qualifying follow-up candidate was established. The structural fixture suite, full findings checker, and baseline full-coverage checker pass. An independent bounded source review confirmed the result without simulating owner approval; Phase 164 independently evaluated readiness.

**v1.38 Packaged Adopter Proof** completed and was archived on **2026-09-25** across Phases **160–161**. All eight requirements passed, exact-SHA CI and post-merge main were green, and Scrypath 0.3.13 passed Hex publication, HexDocs, clean-consumer compilation, and package-to-tag parity. No human verification or UAT remains pending.

**v1.36 Dependency Security Remediation** completed on **2026-08-25**. All four Mix graphs are independently audit-clean; the final ecommerce batch passed exact-SHA mounted-source, service, and focused browser proof. A reusable Docker-only verifier now owns focused/full E2E setup and teardown, the focused lane is an always-running merge check, the full Phase 105 lane stays advisory, and no separate human UAT is required when automated evidence is green.

**v1.35 - Brand System & Logo Identity** shipped directly on **2026-06-24** and was archived in-repo on **2026-07-11** across phases **137-143**. It delivered the copper `/` **scry/path** identity, full transparent SVG family, self-contained `brandbook/` package, subset woff2 fonts, portable tokens, accessibility notes, examples, and adoption across README, ScrypathOps, website, favicon, and OG surfaces.

**What shipped:**
- `brandbook/` static brand book, examples, notes, tokens, font assets, and SVG identity family.
- Final owner-selected logo direction C: copper `/` path separator; routed-S concepts rejected.
- Root README logo header, ScrypathOps logo/favicon/inline mark, and website brand mark/OG adoption.
- Archive files now live at `milestones/v1.35-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`.
- Direct-completion caveat: phases 138-143 intentionally have no GSD plan artifacts; do not reopen them.

**v1.34 — Both-Themes Perfection (Dark Signature + AA Gate)** shipped on **2026-06-29** and was archived in-repo on **2026-07-11** across phases **128–136**. DUALVERIFY-01 passed with source-backed automated proof, zero AA failures, recaptured 40-shot matrix, v1.33→v1.34 before/after gallery, milestone audit, clean code review, and approved Human UAT.

**What shipped:**
- WCAG AA became a hard proof gate for ScrypathOps via fast token-pair checks and browser axe coverage across light, dark, and system-dark.
- Dark elevation now uses a true four-step midnight ramp, with light parity controlled by scoped tokens and proof gates.
- Shell chrome, command palette, flash, theme toggle, path motion, Search, Sync/Drift, and Playbooks received dual-theme polish without runtime scope expansion.
- The milestone archive now lives at `milestones/v1.34-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`.

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

**The library scope remains effectively complete for its stated mission.** v1.34 and v1.35 were bounded UI/brand polish wedges, not runtime breadth. Future work should still focus on maintenance, bug fixes, release-train stability, proof stability, and outside-adopter evidence. Do not keep extending the roadmap just because additional polish is imaginable.

**Release-train posture:** keep `main` green on lean merge gates, ship patch-first while pre-1.0, and land serious milestone work through PRs rather than direct `main` development.

**Unified operating lanes:**
- **Maintenance lane (default):** release follow-through, support/docs truth, outside-adopter evidence loop, and planning-truth reconciliation while `main` stays green.
- **Silence lane:** when there is no release follow-through, support/proof drift, production bug, or outside-adopter evidence, do not manufacture a milestone. Say the release train is idle.
- **Feature lane (evidence-gated):** reopen only as PR-scoped milestone work when a concrete production bug, reviewed outside-adopter evidence, or explicit strategic wedge justifies it; merge only after PR CI is green and scope remains bounded to the approved wedge.

**Boundary discipline retained:** Scrypath remains framework-agnostic at the view layer.

**Out of scope remains:** public `%Scrypath.Query{}` or other internal structs as semver-stable API, schema-generated runtime search APIs, Phoenix-dependent runtime core, reusable UI widgets or form-builder layers, automatic Ecto association walking, or any change that hides operational search semantics behind framework magic.

The public website launch surface now exists under `website/` and is deployed to GitHub Pages as a companion front door, not a HexDocs replacement.

Current planning files: **`.planning/{PROJECT,REQUIREMENTS,ROADMAP,STATE}.md`** plus milestone archives under **`.planning/milestones/`**. Current research is routed from **`.planning/research/SUMMARY.md`**.

## Release Train Posture

- **Active milestone:** v1.45 Foundation and CI — Phase 182 complete; Phase 183 next. v1.44 Sync correctness is archived locally with debt carried forward; PR #122 remains open. The approved rolling roadmap names v1.45 foundation and CI next. v1.43 is archived with closeout run 40204029522. The maintainer waived only the v1.43 formal-review gate; no formal review is claimed. v1.42 and v1.41 are complete and archived. The original Phase 170 NOT READY decision is preserved at its historical cutoff; the fresh 2026-10-02 issue #86 decision is READY within its recorded limits.
- **Policy:** Keep `main` green on the lean required gates and prefer PR-first execution for serious milestone or feature-depth work.
- **Current goals:** Refine the existing six operator surfaces from the concrete 2026-10-06 visual feedback while maintaining green main and the completed recovery contract. Preserve the attested Phase 170 source and do not restart it. The authorized tracking replacement is separate from the frozen source identity.
- **Scope guard:** Autocomplete/suggestions, tenant-token helpers, public multi-backend support, vector/hybrid retrieval, new core APIs, new auth models, new UI surfaces, and unrelated workflow expansion remain out of scope.

**v1.37 implementation outcome (2026-08-26):** runtime input and secret
boundaries hardened; runtime xref cycles reduced to zero; write/search/settings/
failed-work responsibilities extracted behind compatible facades; canonical
verification capabilities and a lean SHA-pinned CI graph established; live
Meilisearch, package, release, static-analysis, and compatibility proof passed;
measured pure hot paths did not justify speculative optimization.

## Last shipped milestone

**v1.42 — ScrypathOps operator/admin UI** (2026-10-04): Phase172, eight plans, eight OPUX requirements. Consistent shared controls/copy, accessible dialogs and schema selection, exact-work recovery and guarded promotion, 104 passing hosted browser tests and the warranted Scrypath0.3.15 release. See `milestones/v1.42-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`.

**v1.41 — Readiness Gate Follow-Through** (archived **2026-10-02**; Scrypath 0.3.14 published during the milestone). Completed Phases 168–171 with 9/9 requirements, 19/19 plans, 6/6 integration paths, and 3/3 end-to-end flows. Its audit accepts visible, nonblocking Nyquist validation-record debt in Phases 168–170. Phase 170's original dated NOT READY decision remains historical; the fresh current READY assessment is at [issue #86 comment 5955742805](https://github.com/szTheory/scrypath/issues/86#issuecomment-5955742805). The post-freeze tracker replacement preserves the attested historical snapshot. See `milestones/v1.41-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`.

**v1.40 — Readiness Evidence Closure** (planning milestone shipped and archived **2026-09-27**; no package release). Reproduced and corrected tenant/facet contract defects, proved one persisted-membership Phoenix workflow through path and fresh-package dependencies, and demonstrated bounded repair to visible search. Its audit records 11/11 requirements, 3/3 phase verifications, 11/11 integration paths, and 5/5 flows; `tech_debt` remains explicit. The assessment is **NOT READY** because the consumer lock's Mint 1.9.3 advisory is unresolved and condition 6 was UNKNOWN at its cutoff. Final tracked phase source `343e20be66ab0c17f62b95138203c86e868bd1ee` passed exact-SHA run [36361116862](https://github.com/szTheory/scrypath/actions/runs/36361116862). See `milestones/v1.40-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`.

**v1.39 — Pre-Operator UI Quality Readiness Ratchet** (planning milestone shipped and archived **2026-09-26**). Established a 24-claim non-UI evidence baseline, dispositioned all claims without inventing a product defect or follow-up candidate, and recorded a six-condition **NOT READY** decision because conditions 3 and 6 remain unknown. The accepted audit debt is documented in `milestones/v1.39-MILESTONE-AUDIT.md`; no library package version changed.

**v1.38 — Packaged Adopter Proof** (shipped **2026-09-25** and archived). Added a package-artifact Phoenix proof across inline, Oban, and related-data flows; confirmed exact-SHA CI, post-merge main, Hex 0.3.13, versioned HexDocs, consumer compile, and package/tag parity. The milestone audit found no blockers; advisory Phoenix CI and the absence of GitHub review objects for explicitly authorized merges remain recorded process notes. See **`milestones/v1.38-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**v1.37 — Code Quality Ratchet** (shipped and archived **2026-08-26**). Runtime safety and architecture hardening, capability-named verification, lean CI and release trust, evidence-based performance, scheduled coverage, and candidate/final exact-SHA zero-human closeout — see **`milestones/v1.37-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.36 — Dependency Security Remediation** (shipped and archived **2026-08-25**). Four audit-clean Mix graphs, behavior-preserving Req/Phoenix/Ecto/Ops proof, a zero-touch mounted ecommerce verifier, and strict required `ecommerce-mounted-smoke` enforcement — see **`milestones/v1.36-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.35 - Brand System & Logo Identity** (shipped **2026-06-24**, archived in-repo **2026-07-11**). Owner-initiated brand wedge: copper `/` `scry/path` identity, transparent SVG family, self-contained brandbook, subset fonts/tokens, README/ScrypathOps/website adoption, and direct-completion archive - see **`milestones/v1.35-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.34 - Both-Themes Perfection (Dark Signature + AA Gate)** (shipped **2026-06-29**, archived in-repo **2026-07-11**). Owner-initiated both-theme ScrypathOps polish wedge: dark signature, light parity, AA hard gate, browser proof, 40-shot matrix, before/after gallery, milestone audit, and approved Human UAT - see **`milestones/v1.34-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.33 — Admin UI Insane Polish** (shipped + archived in-repo **2026-06-03**). Owner-initiated next-level admin-UI polish wedge: task-first IA (Recover/Explore nav + front-door), design-system tightening for compounding reuse, restrained brand motion, per-screen polish, and shell coherence — see **`milestones/v1.33-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.32 — Admin UI/UX Design System Cleanup** (shipped + archived in-repo **2026-06-01**). Bounded existing-admin polish wedge for ScrypathOps tokens, shared operator primitives, mounted `/admin/search/*` asset contract, and screen cleanup — see **`milestones/v1.32-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.31 — Adoption Evidence Demo Hardening** (UAT passed **2026-06-01**). Bounded strategic proof wedge for realistic demo app DX, deterministic browser evidence, docs, and closeout.

**Prior:** **v1.30 — Release Trust and Evidence Maintenance** (shipped + archived in-repo **2026-06-01**). Delivered release/package truth hardening, support intake routing, advisory proof stability policy, and public website/docs truth alignment while keeping product scope closed — see **`milestones/v1.30-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.29 — Contract Repair and Proof Hardening** (shipped + archived in-repo **2026-05-31**). Delivered generated fan-out reflection repair, tenant-preserving ecommerce readiness regression proof, and aligned roadmap/JTBD truth while keeping `phase105-e2e` advisory — see **`milestones/v1.29-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.28 — Realistic Demo App & Admin UI Proof** (shipped + archived in-repo **2026-05-31**). Delivered the mountable admin UI engine, multi-tenant e-commerce example, storefront/operator E2E proof, and advisory real-services CI lane — see **`milestones/v1.28-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.27 — Adopter Contract Hardening** (shipped + archived in-repo **2026-05-30**) — **`milestones/v1.27-{ROADMAP,REQUIREMENTS}.md`**.

**Prior:** **v1.26 — Facet Value Vocabulary Search** (shipped + archived in-repo **2026-05-26**) — **`milestones/v1.26-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.25 — Tenant-Safe Search Access** (shipped + archived in-repo **2026-05-26**) — **`milestones/v1.25-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

**Prior:** **v1.24 — Related-Data and Dependency Propagation** (shipped + archived in-repo **2026-05-25**) — **`milestones/v1.24-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**.

## Key Decisions

| Decision | Outcome |
|----------|---------|
| Preserve complete first-attempt inventory and raw source/artifact/cleanup authority; advisory workflow status alone cannot certify browser stability. | ✓ Phase 182 — current local 189/189 and two hosted warm/full runs at the assertion-corrected source, with retained unchanged cache scenarios at 0b7 and explicit parity. |
| Separate legitimate import-only Docker observations from strict warm acceptance. Keep actual imports, useful hits and exports mandatory for warm-cache acceptance. | ✓ Phase 182 — regression and ordinary default-policy closeout, without widening trusted writers. |
| Reuse only compatible BEAM download archives; bind compiled outputs to toolchain, graph, profile and lock identity. | ✓ Phase 182 — real fallback, changed-lock invalidation and restore-disabled cold receipts. |
| Oban worker telemetry is search semantics on `[:scrypath, :oban, ...]`; queue lifecycle stays on Oban's `[:oban, :job, ...]`. Decode/config failures emit no Scrypath event. One canonical event table in `guides/telemetry.md`, guarded by a guide-vs-AST contract test in the core lane. | ✓ Phase 180 (2026-10-25) — 13 review findings closed before verification (12 fixed, IN-06 accepted per D-18); exact-SHA hosted CI due at the PR. |
| Oban upsert jobs carry document ids and load current records when they run (`Scrypath.Loader`: default query plus `preload:`, or the schema's `search_records/2`); missing rows become deletes. Supersedes Phase 4 D-07/D-09 (jobs carried projected snapshots). | 2026-10-22 — snapshots let operator and automatic retries overwrite newer index data. Matches Searchkick, Laravel Scout and Hibernate Search; reasoning in `.planning/research/SYNC-RELOAD-PROPOSAL.md`. Delete jobs still carry ids only (D-08 kept). |
| Scope v1.43 around the saved UI refinement brief and reuse existing UI inventories; keep research defaults and adaptive model routing intact. | Scope, inventory reuse, all 20 requirements, and Phases 173–177 approved 2026-10-06. |
| Settle shared light/dark visual direction in Impeccable comps and GSD UI contracts before broad implementation. | ✓ Phase 173 — the neutral foundation, single theme preference, and operational time/copy contract are implemented and verified locally; later phases extend the demonstrated patterns. |
| Preserve complete observations through partial refreshes, and derive recovery actions from existing eligibility, allowlist, and host authorization rules. | ✓ Phase 174 — current-source tests verify truthful success states, retained evidence, and fail-closed selected-schema recovery. |
| Use the bundled Scrypath favicon for the mounted operator UI while leaving host storefront identity alone. | Maintainer direction, 2026-10-12 — mount-aware SVG/ICO links and static routes use existing assets; focused route/render tests pass without a new dependency. |
| Reuse shared tokens/components and explicit domain vocabulary; fix demonstrated friction. | ✓ v1.42 — six surfaces, narrow reflow and accessible modal controls covered by existing lanes. |
| Join recovery to new work, exact terminal task and expected active-index document. | ✓ v1.42 — deterministic rendered journey retains original failure history and reports unknown observation honestly. |
| Keep visual checks deterministic and economically scoped. | ✓ v1.42 — geometry, focus, contrast and screenshot inspection; no paid judge or new required CI lane. |
| Keep evidence claims bounded by source, result, freshness, environment, and limitations; missing proof stays unknown. | ✓ Good — prevents unsupported pass or defect claims. |
| Distinguish behavior defects, evidence gaps, and product opportunities; severity is not averaged with cost. | ✓ Good — all 24 claims received an explicit triage outcome. |
| Require evidence, scope authority, and automated acceptance before creating follow-up work. | ✓ Good — no candidate met the qualification criteria. |
| Keep dated readiness decisions source-bounded and append-only. | ✓ Good — the original Phase 170 NOT READY cutoff remains intact; the fresh 2026-10-02 READY decision supports only its stated claims and authorized the bounded v1.42 UI wedge. |
| Treat structural checker results as artifact-shape evidence only. | ✓ Good — source truth and semantic readiness remain bounded by linked evidence. |
| Derive host tenant scope from persisted membership and keep authentication and policy host-owned. | ✓ Phase 166 — the example proves its named membership path without claiming generic Scrypath authentication. |
| Keep raw search output separate from database hydration and constrain hydration by tenant plus returned IDs. | ✓ Phase 166 — raw hits, counts, facets, and hydrated records are checked independently. |
| Bound manual repair by an explicit Ecto ID predicate and require exact task success plus the same raw-search oracle. | ✓ Phase 166 — selected scope, task state/index, visible projection, and controls are separate assertions. |
| Distinguish fresh local package-artifact use from Hex publication and keep historical deletion reuse source-bounded. | ✓ Phase 166 — package and C-09 claims retain their explicit limits. |
| Preserve the dated assessment independently of later candidate/final acceptance. | ✓ Phase 167 — the consumer Mint High finding and condition 6 UNKNOWN remain visible at the original cutoff. |
| Finish every tracked completion artifact before final-source attestation. | ✓ Phase 167 — final receipt is external; any later tracked edit requires a new exact-SHA run. |
| Keep upstream scoping distinct from phase implementation plans. | v1.41 requested review: current requirements/roadmap and linked research hold outcomes; downstream GSD owns PR partition, tests and final-record implementation. |
| Validate evidence structure without treating parser success as source truth or owner risk acceptance. | ✓ Phase 167 — 22 behavioral fixtures, resolved code review, and separate semantic evidence dispositions. |

## Planning window

v1.41 delivered Phase 168 four-graph security and proof, Phase 169 tenant/facet fixes and finite PR/path accounting, and Phase 170 docs/tooling plus published 0.3.14. Phase 171 closed the DOC-03/GATE-05/CLOSE-04 verification traceability gaps. The original issue #86 NOT READY assessment remains unchanged at its cutoff; the fresh 2026-10-02 READY assessment is separately recorded at comment 5955742805. The audit accepts visible, nonblocking Nyquist validation-record debt in Phases 168–170; all nine requirements, four phases, six integration paths, and three end-to-end flows passed. Current tracking records Phase 170 at 8/8 after its authorized post-freeze replacement; original bytes and the attested 17/18 snapshot remain preserved. v1.41 is archived locally. v1.42 completed the cross-screen ScrypathOps recovery journey and shared UI repairs in Phase172. In v1.43, Phases 173–177 and all 21 plans are locally complete; Phase174 verification passes 19/19 must-haves. The terminal merged-main closeout passed on 2026-10-25 (run 40204029522) and v1.43 is archived. v1.40 and v1.39 assessments remain immutable historical results.


### v1.44 decision provenance

These are implementation-time decisions from all plan summaries. Current
phase verification documents later review corrections and takes precedence
over superseded summary wording (for example, the removed id-taking resolver
clause and the Multi uniqueness exception).

| Source | Decision | Outcome |
|---|---|---|
| 178-01-SUMMARY.md | PostgresRepo supplies a placeholder database path when SCRYPATH_POSTGRES_URL has none, because Ecto.Repo.Supervisor.parse_url/1 rejects server-only URLs; the database is still forced to scrypath_test<partition> | Implemented or superseded by the documented phase review delta |
| 178-01-SUMMARY.md | postgrex kept runtime: false; setup_repo!/1 calls Application.ensure_all_started(:ecto_sql) and (:postgrex) for the Postgres adapter, resolving RESEARCH Assumption A1 without widening the dep | Implemented or superseded by the documented phase review delta |
| 178-01-SUMMARY.md | Both test repos set log: false so shared-case query logs do not flood test output | Implemented or superseded by the documented phase review delta |
| 178-02-SUMMARY.md | The Postgres lane lives inside the existing backend (required) job; no new job or check name (required-job count stays 5) | Implemented or superseded by the documented phase review delta |
| 178-02-SUMMARY.md | verify.postgres always passes --include postgres because the test helper exclude list is evaluated once per VM | Implemented or superseded by the documented phase review delta |
| 178-02-SUMMARY.md | verify.postgres treats an empty SCRYPATH_POSTGRES_URL the same as unset | Implemented or superseded by the documented phase review delta |
| 178-03-SUMMARY.md | The internal paging cursor lives under the state key `keyset` (list of {col, value} pairs); the public batch field stays `last_primary_key` and no `:cursor` key is added (D-09) | Implemented or superseded by the documented phase review delta |
| 178-03-SUMMARY.md | Fan-out dedupe keeps the first occurrence per key tuple, so the last DB-ordered row (the cursor source) is unchanged | Implemented or superseded by the documented phase review delta |
| 178-03-SUMMARY.md | The not-nil guard is added only when the schema has no Ecto primary key, so single-column Ecto-PK SQL is unchanged | Implemented or superseded by the documented phase review delta |
| 178-03-SUMMARY.md | LoaderBackfillCases is split into harness/composite_paging_cases/query_scope_cases quote blocks to satisfy credo --strict | Implemented or superseded by the documented phase review delta |
| 178-04-SUMMARY.md | Backfill writes go through one private write/5 (:upsert \| :delete) that skips empty lists and normalizes the backend result; the batch result is built once from both results | Implemented or superseded by the documented phase review delta |
| 178-04-SUMMARY.md | Batch index now falls back to the resolved index when the backend result metadata has a nil :index (previously Map.get/3 default only applied to a missing key) | Implemented or superseded by the documented phase review delta |
| 178-04-SUMMARY.md | Managed reindex takes no :query, so the reindex search_records/2 proof runs over the whole table and asserts omitted == all unpublished rows | Implemented or superseded by the documented phase review delta |
| 178-05-SUMMARY.md | The backfill @doc names reconcile_sync/2 as the drift-recovery path for rows outside the visited scope and names no internal module, option or hidden function | Implemented or superseded by the documented phase review delta |
| 178-05-SUMMARY.md | The :query fan-out guidance states the actual consequence (duplicates take batch slots and are dropped within a batch) rather than claiming incorrect paging | Implemented or superseded by the documented phase review delta |
| 178-05-SUMMARY.md | The contract test also refutes _scrypath_fresh_target and prepare_records in the backfill @doc | Implemented or superseded by the documented phase review delta |
| 179-01-SUMMARY.md | Empty-trigger sync_related returns noop_result for every sync mode (guard sits before the mode case, as the plan specified), so oban with [] no longer enqueues | Implemented or superseded by the documented phase review delta |
| 179-01-SUMMARY.md | Loader.preload_for/1 only swallows FunctionClauseError raised by the schema's own __scrypath__/1; any other FunctionClauseError is re-raised | Implemented or superseded by the documented phase review delta |
| 179-01-SUMMARY.md | Multi-chunk combined metadata keeps only :index from the last chunk; a chunk result that is not a Result (fake backend id list) counts as a chunk with no task, using the chunk's ids and length | Implemented or superseded by the documented phase review delta |
| 179-02-SUMMARY.md | Backfill write chunks keep the page's primary-key order: Enum.chunk_every(Chunks.max_ids()) instead of Chunks.by_id/ids, whose string-form sort would reorder a keyset page (rows are already deduped by key) | Implemented or superseded by the documented phase review delta |
| 179-02-SUMMARY.md | Reindex replaces a waited batch's task with the last waited chunk task and tasks with the waited list; batches with no or empty tasks keep the single-task wait | Implemented or superseded by the documented phase review delta |
| 179-03-SUMMARY.md | An empty id list still enqueues one empty job (at_least_one_chunk/1), preserving pre-chunking behaviour for RecoveryAction.retry/2 payloads without ids | Implemented or superseded by the documented phase review delta |
| 179-03-SUMMARY.md | Combined enqueue metadata :index comes from the first changeset's args["index"] (same value as before), merged with %{oban: %{queue, max_attempts, name}} | Implemented or superseded by the documented phase review delta |
| 179-03-SUMMARY.md | Real-Oban test uses a `use Oban, otp_app: :scrypath` facade module named Scrypath.TestSupport.ObanSQLite.TestOban, because Config.validate_oban_module!/1 requires oban: to be a loaded module | Implemented or superseded by the documented phase review delta |
| 179-04-SUMMARY.md | A module name resolves only when Atom.to_string(module) == name, so "Scrypath.TestSupport.FakeRepo" (no Elixir. prefix) decodes as unknown even though Module.safe_concat would resolve it | Implemented or superseded by the documented phase review delta |
| 179-04-SUMMARY.md | A non-binary, non-nil "repo" on an upsert job, or a non-binary allowlisted related opt, returns {:invalid_arg, key} | Implemented or superseded by the documented phase review delta |
| 179-04-SUMMARY.md | A non-map args value returns {:invalid_arg, "args"} so perform/1 never raises a FunctionClauseError | Implemented or superseded by the documented phase review delta |
| 179-05-SUMMARY.md | The stop event's document_count is the resolved target count (from the sync result), as before; the trigger count is document_count in start metadata, and missing_count is the only new stop key | Implemented or superseded by the documented phase review delta |
| 179-05-SUMMARY.md | Loader :repo_required / :search_records_required in the related worker cancel as {:cancel, {:invalid_job, reason}}; other loader errors retry as {:error, reason} | Implemented or superseded by the documented phase review delta |
| 179-05-SUMMARY.md | RelatedEnqueue keeps the empty-trigger guard (noop Result in the configured mode) even though Sync.sync_related/3 short-circuits first | Implemented or superseded by the documented phase review delta |
| 179-06-SUMMARY.md | The guide's :oban sync_related example now passes repo: MyApp.Repo, because 179-05 made related enqueue raise without a repo or search_records/2 | Implemented or superseded by the documented phase review delta |
| 179-06-SUMMARY.md | The :oban failure table gains an all-triggers-missing row (:ok, resolver not called) and widens the cancel row to undecodable job args | Implemented or superseded by the documented phase review delta |
| 179-06-SUMMARY.md | CHANGELOG.md is not edited (resolved OQ6); the upgrade sentence lives in this SUMMARY's Release note | Implemented or superseded by the documented phase review delta |
| 179-07-SUMMARY.md | Category.search_records/2 uses ScrypathEcommerce.Repo directly (the context :repo is nil because the app configures no :scrypath repo) | Implemented or superseded by the documented phase review delta |
| 179-07-SUMMARY.md | Ecommerce keeps the [_id \| _] clause of resolve_products_for_categories/1 (catalog_test.exs calls it with ids); phoenix example removes its [_id \| _] clause because no test or caller passes ids | Implemented or superseded by the documented phase review delta |
| 180-01-SUMMARY.md | Upsert stop keeps source/upserted_count/missing_count when the load planned work but the backend write failed (D-06: counts describe the plan, outcome is authoritative); only cancel and load-error outcomes omit them | Implemented or superseded by the documented phase review delta |
| 180-01-SUMMARY.md | cancel_reason/1 keeps the atom head of a cancel tag, drops the detail, and falls back to :other; no atom is ever created from job input | Implemented or superseded by the documented phase review delta |
| 180-01-SUMMARY.md | oban_telemetry_scenarios.ex requires telemetry_capture.ex itself because test_helper loads support files alphabetically | Implemented or superseded by the documented phase review delta |
| 180-02-SUMMARY.md | Existing-event rows list keys from current lib behavior; keys that only appear conditionally (common_metadata sync_mode/repo, result-derived stop keys, request extras) are marked (optional) | Implemented or superseded by the documented phase review delta |
| 180-02-SUMMARY.md | Stop-only columns omit keys that already appear in start metadata (for example document_count on sync spans, schema_count on search_many); the Reading the table section says stop can repeat start keys with final values | Implemented or superseded by the documented phase review delta |
| 180-02-SUMMARY.md | CHANGELOG.md not hand-edited (Release Please owns it); release-note lines recorded below for the squash commit | Implemented or superseded by the documented phase review delta |
| 180-03-SUMMARY.md | Guide keys are converted with String.to_atom/1, not to_existing_atom: lazy module loading made to_existing_atom seed-dependent (search_scope was not yet loaded in one order). Keys come from the repo's own guide, not user input. | Implemented or superseded by the documented phase review delta |
| 180-03-SUMMARY.md | Added compare/2 and resolve_event/2 beyond the planned interface: compare/2 owns the non-vacuous rule and the sorted failure message; resolve_event/2 maps captured names to {row, phase} | Implemented or superseded by the documented phase review delta |
| 180-03-SUMMARY.md | Key contract scenarios are the plan's nine (upsert_missing/ok/legacy/error/cancel/raise, delete_ok/error/raise); a coverage assertion requires start/stop/exception for both spans plus the missing_removed event | Implemented or superseded by the documented phase review delta |
| 181-01-SUMMARY.md | Isolated no-Oban compile runs under MIX_ENV=prod in _build/no_optional_deps (A2; reversible) | Implemented or superseded by the documented phase review delta |
| 181-01-SUMMARY.md | verify.core composes verify then verify.no_optional_deps; deep-quality keeps its own copy; ci.yml unchanged | Implemented or superseded by the documented phase review delta |
| 181-01-SUMMARY.md | RelatedEnqueue builds jobs via the shared runtime-guarded Enqueue.job_changeset/4 instead of a compile-time Oban branch | Implemented or superseded by the documented phase review delta |
| 181-02-SUMMARY.md | A1: wrong-arity hooks produce a compiler warning (IO.warn), never a raise, so only --warnings-as-errors builds fail (reversible) | Implemented or superseded by the documented phase review delta |
| 181-02-SUMMARY.md | Hooks live on Scrypath.Schema (the module use Scrypath delegates to); no separate Hooks module; no guide/README edits this phase | Implemented or superseded by the documented phase review delta |

## Requirements

### Validated

- [x] **v1.45 Phase 182** (2026-10-27): **BROW-01–03**, **CACHE-01–02** — full disposable browser graph, complete first-attempt inventory, exact-source artifact authority, checked Docker cache reuse/cold execution and compatible BEAM download/strict resolved-cache boundaries. See Phase 182 VERIFICATION and acceptance records; no public release or outside-adopter claim.

- [x] **v1.44** (local archive 2026-10-26; merge/publication pending): **LOAD-01–03**, **PAGE-01–03**, **FAN-01–03**, **OBS-01–03**, **HYG-01–02**, **TEST-06** — loader parity, full-key paging/cursors, bounded loads and writes, loaded related resolvers/shared queue policy/safe args, worker telemetry and drift contract, documented optional hooks and actual no-Oban proof. Scope and debt limits remain in the milestone audit.

- [x] **v1.42 / Phase172** (2026-10-04): **OPUX-01–OPUX-08** — shared readability, accessibility, domain copy, schema-preserving recovery, exact work/document outcome, economical automated acceptance and reviewed release/cleanup closure.
- [x] **v1.43 / Phase 173** (2026-10-10): **OPUX-09–OPUX-15** — shared neutral theme foundation, truthful local status, snapshot-stable operational time and accessible timestamp copy. Verified locally at `b12a7c4`; no hosted source receipt is claimed.
- [x] **v1.43 / Phase 174** (2026-10-12): **OPUX-16–OPUX-19** — recovery entry, safe failed-work action hierarchy, worst-first Search health, and preserved allowed-schema context. Current-source verification passed 19/19 must-haves; see the phase validation and verification artifacts.
- [x] **v1.43 / Phases 175–176** (2026-10-12): **OPUX-20–OPUX-25** — repair/promotion evidence boundaries and Search/Playbook workflows. Their phase verification reports pass; terminal v1.43 delivery attestation remains separate.
- [x] **v1.43 / Phase 177** (2026-10-12): **OPUX-26–OPUX-27** — shared visual patterns and six-surface interaction evidence. Phase verification passes 69/69 must-haves.

- [x] **v1.40 Phase 167** (2026-09-27): **GATE-04**, **CLOSE-03**, **VERIFY-02** — separately dated NOT READY assessment, eight bounded software-claim joins, release/debt reconciliation, and final exact-SHA closeout at `343e20be66ab0c17f62b95138203c86e868bd1ee`.
- [x] **v1.40 Phases 165–166** (2026-09-27): **API-01**–**API-02**, **HOST-01**–**HOST-02**, **PKG-04**, **REPAIR-01**–**REPAIR-02**, **DELETE-01** — public tenant/facet contracts, bounded host-owned tenant search and manual repair, path/local-artifact receipts, and source-bounded C-09 reuse.
- [x] **v1.39** (2026-09-26): **BASE-01**–**BASE-03**, **FIND-01**–**FIND-03**, **CLOSE-01**–**CLOSE-02**, **GATE-01**–**GATE-03** — 24-claim non-UI readiness baseline, evidence-led triage with zero qualifying follow-up candidates, and a six-condition **NOT READY** assessment. The archive audit retains documented metadata/Nyquist tech debt; see `milestones/v1.39-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`.
- [x] **v1.38** (2026-09-25): **PKG-01**–**PKG-03**, **PROOF-01**, **DOC-01**, **HYGIENE-01**, **REL-01**, **CLOSE-01** — package-backed Phoenix integration proof, machine-checked documentation, exact-SHA CI, green main, Hex/HexDocs 0.3.13 publication, consumer compile, and package/tag parity.
- [x] **Phase 147** (2026-08-25): **SEC-04**, **COMPAT-01**, **COMPAT-03**, **EVID-01**, **EVID-02** — ecommerce aligned to the fixed-compatible mounted web/client cohort; exact-SHA resolution, canonical path, deterministic/service, Docker-focused browser, cleanup, same-window four-graph audit, and ordered batch-topology verification passed with no human UAT.
- [x] **Phase 146** (2026-08-24): **SEC-03**, **EVID-03** — ScrypathOps aligned to the approved fixed-compatible web/client/data cohort; real `Swoosh.ApiClient.Req` behavior, raw JSON precedence, standalone Ops, root release gates, detached fresh resolution, live Postgrex/Plug eligibility, unsuppressed audit, cleanup, code review, and threat verification passed.
- [x] **Phase 145** (2026-08-22): **SEC-02** — legacy Phoenix example aligned to the bounded fixed-compatible Phoenix/Bandit/Ecto SQL/Postgrex/Plug cohort with transitive Ecto 3.14 and Decimal 3; deterministic compatibility checks, detached fresh resolution, unsuppressed Hex audit, root regression, and Docker-backed service proof passed.
- [x] **Phase 144** (2026-08-22): **SEC-01**, **COMPAT-02** — root and checked path-consumer Req floors aligned at fixed-compatible versions; focused Req-backed behavior, deterministic release gates, detached fresh resolution, and unsuppressed root advisory audit passed. Configured Swoosh runtime proof remains Phase 146's explicit responsibility.
- [x] **v1.35** (2026-06-24): **BRAND-AUDIT-01**, **LOGO-DIRECTIONS-01**, **LOGO-SYSTEM-01**, **TOKENS-PKG-01**, **BRANDBOOK-HTML-01**, **BRAND-ADOPT-01**, **BRAND-VERIFY-01** — brand system and logo identity closed by direct evidence: copper `/` `scry/path` identity, transparent SVG family, self-contained brandbook, subset fonts/tokens, accessibility notes, README/ScrypathOps/website adoption, and direct-completion archive. No phase artifacts should be synthesized for phases 138-143.
- [x] **Phase 132** (2026-06-04): **A11Y-TOKEN-01** — both-theme AA hard gate green for muted text and selected violet fills; browser contrast proof covers light, dark, and system-dark; AAA body/long-form status remains advisory/report-only.
- [x] **v1.34** (2026-06-29): **CONTRAST-HARNESS-01**, **DARKAUDIT-01**, **DARKTOKEN-01**, **GLOW-01**, **COPPER-01**, **A11Y-TOKEN-01**, **DARKMOTION-01**, **SCREEN-DARK-01**, **SHELL-DARK-01**, **DUALVERIFY-01** — both-themes perfection wedge closed with dark signature, light parity, AA hard gate, browser proof, screenshot matrix recapture, before/after gallery, milestone audit, and approved Human UAT.
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

v1.45 scope and all 21 detailed requirements are confirmed in `REQUIREMENTS.md`; the four-phase roadmap is approved:

- [ ] Repository-only verification tooling excluded from Hex with contributor-command parity.
- [ ] Explicit, lean dependencies and reconciled dependency/audit results (Phase 184); cache boundaries are validated in Phase 182.
- [ ] Executable token, contrast and drift foundations for the v1.46 UI engine.

Completed v1.44 requirements remain archived in `milestones/v1.44-REQUIREMENTS.md`. These active goals are not implementation or verification claims.

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

The repository has shipped planning milestones through **`v1.43`** (**`v1.0`**-**`v1.43`**). Current planning truth lives in **`.planning/ROADMAP.md`**, **`.planning/PROJECT.md`**, **`.planning/MILESTONES.md`**, **`.planning/STATE.md`**, and `milestones/v*-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md` for shipped arcs.

## Evolution

This document evolves at milestone boundaries.

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-10-28 after Phase 182 completion on 2026-10-27; Phase 183 discussion is next.*
