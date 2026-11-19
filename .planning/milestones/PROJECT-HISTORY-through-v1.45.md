# PROJECT.md history through v1.45

Sections moved verbatim from `.planning/PROJECT.md` on 2026-11-18 to keep that file small for agents (it had reached 103 KB). Nothing was rewritten. The current-state and contract sections stay in PROJECT.md.

## Historical Milestone Setup: v1.45 Foundation and CI

**Goal:** Make browser verification complete and reliable, keep maintainer tooling out of the Hex package, reduce dependency overhead, and establish executable UI quality foundations for v1.46.

**Target features:**
- Restore the full standalone browser lane and run the currently skipped follow-up scenarios using an audited inventory and correct port guards.
- Move repository-only verification tasks and their support modules to `dev/mix/tasks`, preserving contributor commands and enforcing built-package parity.
- Declare Telemetry directly, admit the approved Req version ranges, trim ScrypathOps dependencies, consolidate applicable Dependabot changes, and improve CI caches.
- Establish the shrink-only L1 token ratchet, Tailwind colour-namespace reset, required contrast/focus checks, DTCG Ops tokens and drift proof; remove unused generator markup and the paid visual-judge path.

**Scope and provenance:** The maintainer confirmed section 3 of `reference/ROLLING-ROADMAP.md` on 2026-10-26 through `$gsd-new-milestone`. Phase numbering continues at 182 after completed Phases 178–181. The UI engine and pilot remain v1.46, surfaces/polish v1.47, and adopter features v1.48. Preserve current visible UI, retained-preview data, the five lean required gates and existing advisory lane posture. No manual UAT or paid visual judge is introduced.

**Definition decisions (2026-10-26):** The maintainer selected reuse of existing research and explicitly confirmed all 21 requirements in `REQUIREMENTS.md`. The maintainer separately approved the four-phase roadmap (182–185). Phases 182–184 now have executable goal verification: browser/cache, packaged maintainer-tooling boundaries and explicit/lean dependency graphs. Phase 185 now has executable goal verification for all six UI-foundation requirements. Its final acceptance uses the separate terminal source receipt after tracking writes; prior phase evidence retains its original source.

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

## Historical State

**Current as of 2026-11-01 — v1.45 Phases 182–185 goal-verified:** all 21 confirmed requirements have implementation evidence. Phase 185 enforces shrink-only literals, live contrast/focus and typed tokens in the existing repository lane; actual both-bundle/routes and exact source-paired UI proof pass. [Goal verification](v1.45-phases/185-executable-ui-quality-foundations/185-VERIFICATION.md) preserves source identities, flags and inherited limits. Candidate [run 41318243156](https://github.com/szTheory/scrypath/actions/runs/41318243156) passed required checks, coverage/attestation and full browser verification at `fa42d99ee3ad5290ea7d8ab089ba076c5e25558c`. The later final tracking successor still requires its external terminal receipt. The unrelated config edit and stopped source-stale retained preview are preserved; no merge or publication follows.

**Historical cutoff, 2026-10-26 — v1.44 local archive:** 4 phases, 17 plans,
45 tasks and all 15 requirements are implemented and verified. The
[audit](v1.44-MILESTONE-AUDIT.md) remains `tech_debt`: 8/8
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

## Historical Next Steps

v1.45 Foundation and CI has 21 confirmed requirements, all implemented and goal-verified across Phases 182–185. After the final Phase 185 source attestation, stop at the selected phase boundary. Milestone audit/archive and delivery are separate next actions; do not start them automatically. v1.46–v1.47 cover the UI quality engine and planned product polish, followed by v1.48 adopter features. PR #122 merge/release handling remains separate.

**Current as of 2026-10-25:** v1.43 **ScrypathOps UI refinement** is complete and archived: 20/20 requirements (OPUX-09–OPUX-28), Phases 173–177, 21/21 plans and five passing phase verifications. Its work first shipped in `scrypath` 0.3.16; 0.3.17 followed as a sync hotfix. The terminal merged-main closeout passed in [CI run 40204029522](https://github.com/szTheory/scrypath/actions/runs/40204029522) at `ebed49b5199d369306527caa7bb69aa0b1db5a36` and is recorded in `reference/v1.43-final-receipt.json`. That run closed T-177-05; T-177-06 stays open as a medium recordkeeping gap below the blocking threshold. The maintainer waived only the formal-review gate; no formal review is claimed. The next approved work is the rolling roadmap in `reference/ROLLING-ROADMAP.md` (v1.44 sync correctness next). Archive: `milestones/v1.43-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md` and `milestones/v1.43-phases/`.

**Historical, 2026-10-13:** Phase 174, Recovery Entry and Diagnosis, is complete locally: 3/3 plans, all 19/19 must-haves verified, and current-source Ops/UI and mounted checks passed. All five v1.43 phase plan sets and verification reports are complete. PR [#98](https://github.com/szTheory/scrypath/pull/98) is draft at exact head `bebeb863493d1667ffa5f8c9fa3e890b484c5c1a`; [CI run 38338089123](https://github.com/szTheory/scrypath/actions/runs/38338089123) passed all five required checks and both Ops UI checks on that exact source. The Website build passed. `deep-quality (advisory)` failed and `ecommerce-e2e (advisory)` was skipped; the dependency-audit follow-up remains disclosed in the Phase 177 trace. Candidate closeout on the final tracking source and terminal merged-main attestation remain outstanding, so T-177-05 still blocks the milestone audit. The maintainer waived only the formal-review gate; no formal review is claimed. Do not audit or archive v1.43 until terminal closeout evidence is recorded. The retained feedback preview remains at `http://127.0.0.1:4012/admin/search`.

This branch also adds the bundled Scrypath favicon to the mounted e-commerce operator UI under its mount path. SVG/ICO routes and rendered links are covered by focused tests; the exact PR source above passed the required mounted and Ops UI CI checks.

**Current as of 2026-10-10:** Phase 173, Shared Visual Foundation and Operational Time, is complete locally at `b12a7c47157b4fb88b05237b7e2525d11896fd59`: 4/4 plans, OPUX-09–OPUX-15, 41/41 plan truths, final Ops/UI checks, code and UI review, and security audit are recorded in its phase artifacts. No hosted source receipt is claimed. Phase 174, Recovery Entry and Diagnosis, is next to discuss and plan; Phases 174–177 remain in the approved execution order. The retained feedback preview remains at `http://127.0.0.1:4012/admin/search`.

**Current as of 2026-10-06:** v1.43 **ScrypathOps UI refinement** has an approved 20-requirement roadmap across Phases 173–177 and has four independently checked Phase 173 implementation plans ready to execute. The maintainer approved the saved scope and the recommendation to reuse existing UI inventories rather than run fresh ecosystem research. The maintainer explicitly approved the detailed requirements and phase boundaries on 2026-10-06. The first phase is 173; no implementation phase has started. Current uncommitted UI/design work and the feedback preview remain preserved. v1.42 and its exact-source receipts remain archived and source-bounded.

**Current as of 2026-10-04:** v1.42 ScrypathOps operator/admin UI is complete: Phase 172, eight plans and all eight OPUX requirements. PR [#91](https://github.com/szTheory/scrypath/pull/91) delivered the UI and core correctness fixes as `3ad154a33f99cb200b791577aadc5970adc70ca2`; main CI37180290165 passed. Scrypath **0.3.15** is published as `scrypath-v0.3.15` at `8dd20e8966acd17a4ef5acec653c00dc31faab49` through Release Please PR [#92](https://github.com/szTheory/scrypath/pull/92). [Publish run 37181522723](https://github.com/szTheory/scrypath/actions/runs/37181522723) passed publication, live Hex/HexDocs/consumer verification and tag parity. Candidate CI37178388184 passed104 browser tests and4 mounted tests with retries disabled; PR CI37178390800 also passed scoped Ops. The GSD archive preserves requirement, visual, review/security and delivery evidence. Completion records precede final exact-source attestation, whose receipt is external to the frozen final source. No active phase or additional approved work remains; preview4012 is retained for optional feedback.

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


</details>

