---
gsd_state_version: "1.0"
milestone: v1.42
milestone_name: ScrypathOps operator/admin UI
status: planning
last_updated: "2026-10-02T16:40:10.034Z"
last_activity: 2026-10-02
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** v1.42 is active. The maintainer's 2026-10-03 direction authorizes automated UI inventory, conventional shared-system cleanup, coherent domain copy, and verified incident recovery while a live preview is available for feedback. OPUX-01–OPUX-08 supersede the earlier four proposed requirements. Preserve the original Phase 170 NOT READY cutoff and its later READY assessment; do not rerun Phase 170.

## Current Position

Phase: Not started (creating roadmap beginning at 172)
Plan: —
Status: Creating roadmap
Last activity: 2026-10-03 — Current UI preview, three specialist reviews, and revised v1.42 requirements recorded

## v1.41 Upstream Review

- Current input: `research/v1.41/SUMMARY.md` (also routed from `research/SUMMARY.md`). Three requested GPT-6 Astra xhigh reviews found material security, proof, delivery and closeout scope corrections; this is research, not software verification.
- Phase 168 is complete: the mounted-readiness correction shipped in PR #82 and the four-graph security/proof work shipped in PR #84. All five plans and four mapped requirements have passing verification. No candidate package was published to Hex.
- Phase 169: PR #85's tenant/facet corrections and coherent proof are merged and verified; Plan 05 records the complete owned delta and finite frozen-cohort decisions. No cohort PR mutation was authorized or performed.
- Phase 170 external outcomes are complete: docs delivery, 0.3.14 publication/parity, exact-main closeout, and its original dated NOT READY decision are recorded. The maintainer authorized a planning-side summary/verifier replacement on 2026-10-02 after byte-identical preservation of the original preterminal files. Current GSD indexing reports 8/8 plans complete; the attested `8c271…` snapshot remains historical 17/18. A separate fresh READY assessment was later posted at issue #86 comment 5955742805 within its stated limits. Do not rerun Phase 170.
- The maintainer approved the revised scope and phase mapping on 2026-09-28. Phase 171 adds traceability rows for DOC-03, GATE-05, and CLOSE-04; its original preservation check remains represented by the retained sidecars and its report was updated to time-bound that check. Phases 168–171 and all 19 plans are complete. The v1.41 audit accepts nonblocking Nyquist validation-record debt; no product gap or pending UAT remains. The milestone is archived locally; the fresh readiness decision and separate maintainer scope approval now authorize bounded v1.42 work, beginning at Phase 172.

## Preceding Milestone Context — v1.40 (Archived)

**Goal:** Close decision-relevant adopter evidence gaps for tenant-safe search and bounded repair, reuse valid delete and release receipts, and make a fresh six-condition readiness decision without starting operator UI work.

**Scope boundary:** Verify existing public tenant-scope and facet-value input contracts, correct only confirmed compatible defects, prove one representative host-owned tenant search workflow and one bounded manual repair-to-visible-search workflow, and reconcile condition 3/6 evidence. Host authentication, membership policy, trusted tenant selection, and database response scoping remain application-owned. No public backend abstraction, broad endpoint/version matrix, operator UI, new required CI lane, or forced Hex release is included.

**Gate:** Preserve the Phase 164 assessment unchanged: it records conditions 3 and 6 as UNKNOWN and readiness as **NOT READY**. The new assessment is separately dated, evaluates all six conditions independently, and may truthfully remain **NOT READY**. A passing assessment only recommends a later ScrypathOps focus.

## Recent Evidence

Entries in this section predate the Phase 170 release and terminal decision. Treat the current Phase 170 state in the header and [post-freeze reconciliation](milestones/v1.41-phases/170-documentation-and-readiness-closeout/170-POST-FREEZE-RECONCILIATION.md) as authoritative; the historical receipts below remain scoped to their recorded sources.

- Phase 167's dated assessment at `2026-09-27T19:39:00Z` is NOT READY: conditions 1/3/4/5 PASS, 2 FAIL, 6 UNKNOWN. The consumer Mint 1.9.3 High advisory is unresolved; later CI does not revise this cutoff.
- Phase 167 candidate `441a7e75367e3d354a2da66261850530363cf1f4` passed run `36347716269`; named advisory Phoenix path/package scenarios each passed 16 tests. One earlier mounted-readiness failure remains recorded.
- Final phase-tracking SHA `343e20be66ab0c17f62b95138203c86e868bd1ee` passed exact-SHA run `36361116862`; all required jobs, coverage, closeout attestation, and the advisory suites passed. Same-SHA run `36360456437` failed only the mounted-service consecutive-readiness check and was followed by the successful retry without source changes.
- Phase 167 verification passed all three roadmap criteria; 22 focused tests, complete structural checker, L1 mitigation audit, and Nyquist coverage pass. Local Elixir regression passed 4 properties/591 tests with 84 exclusions. These checks do not claim readiness; final-source CI passed separately as recorded above.
- v1.39's final exact-SHA closeout run `36257182675` passed on `dc400b2b57aec0ca6b0ef16c9477d266fd41a433`; annotated tag `v1.39` resolves to that commit. This receipt supports only its recorded claims and source.
- Scrypath 0.3.13 has package-backed Phoenix, exact-SHA, post-merge, Hex/HexDocs, consumer-compilation, and parity receipts from v1.38. They do not broaden the selected v1.40 workflow claims.
- v1.40 research began with C10-R1 and C11-R1 as unexecuted hypotheses; Phase 165 independently reproduced the bounded tenant/runtime and facet-serialization defects and corrected them.
- Phase 165 Plan 02 at `a883958c73d7f102a7404a317e0d13b7c15ccbd9` corrected raw keyword-filter tuple serialization through the existing renderer. Phase 166 subsequently proved the named live path/package scenario at its measured source.
- Phase 165 candidate `384c8839db2f021db421d0dbeff096ee439fd721` passed exact-SHA hosted closeout run `36277023698`; the five required jobs, advisory coverage, and closeout attestation succeeded with immutable artifacts. The later refreshed final phase-tracking SHA and its successful exact-source closeout are recorded above.
- C-16 requires one representative ID-scoped manual repair through terminal task success to visible search. C-09 can be reused only after a relevant-path freshness comparison; otherwise its bounded claim needs targeted evidence or UNKNOWN.
- Phase 166 candidate `50d5c12d36ec560525e245bcb992c40e5927854f` passed exact-SHA workflow-dispatch closeout run `36321613553` at attempt 1. Required jobs, coverage, and closeout attestation succeeded; Phoenix advisory job `108626420623` and backend job `108626420717` both contain the named successful Phase 166 scenario receipts.
- Phase 166's historical C-09 receipt is reusable only for its bounded ecommerce raw-hit hard-delete claim; the receipt-to-assessment comparison accounts for all 16 changed relevant paths.
- Phase 170 Plan 07 refreshed public `main` at `87d74259a9f569c6b11c8d9481f5465a172c70ba`. PR #87 is merged and exact-main run `36795877117` succeeded; its path-scoped workflow skipped ecommerce E2E, so no fresh full E2E pass is claimed. PR #83 remains open on unchanged head `64963c7042c451f9d4932fee7850d8bf7ca93684`, with no reviews and `BLOCKED` merge state. GitHub Releases and Hex still show 0.3.13 as latest; 0.3.14 is unpublished. Issue #86 has no terminal decision comment as of 2026-10-01 11:08 UTC.
- Phase 170 Plan 07 created and retained a clean final evidence worktree from refreshed public `main`, removed the merged PR #87 delivery worktree and local branch after confirming its tree matched `main`, and preserved all unrelated dirty files, cache and existing services. The exact snapshot inventory and external digest protocol are recorded in `170-CLOSEOUT.md`; Plan 07 Task 2 will finish tracking and freeze it.
- Debug follow-up: no newer run superseded the two failures in `36419998362` before investigation. The older passing run `36390328588` and failing SHA `40c9978c975dbfb42db75511f44ff0369c8d7d88` had identical relevant source/configuration/dependency blobs, so the history-only rewrite was not a source regression. The confirmed cause was `PHX_SERVER=true` leaking into finite setup processes: Compose could mark the temporary endpoint healthy, then the endpoint exited before the persistent server was ready. Exact-SHA closeout `36439562644` restored all five required jobs, coverage, and attestation to green on the unchanged public SHA; advisory `deep-quality` still reports the known Mint advisories. A local two-file readiness fix passes the focused mounted verifier (four browser checks) and its contract test (3 tests), but is uncommitted and was not part of that hosted run. See `.planning/debug/resolved/ecommerce-mounted-readiness.md`.

## Accumulated Context

### Decisions

- Keep missing evidence, a confirmed defect, and a successful contract reproduction distinct.
- Preserve host ownership of actor authentication, membership policy, trusted tenant derivation, and response scoping; Scrypath evidence proves supplied-scope composition within the named workflow only.
- Use the existing Phoenix path/package harness and current advisory scenario posture. A required advisory scenario pass is acceptance evidence for its exact SHA; it does not become a required merge gate.
- Bound manual repair by an Ecto ID predicate, never by a query limit, and await the returned backend task before claiming visible repair.
- Keep release/package/support identities distinct from the v1.39 planning tag. Reconcile named metadata and release-reference debt explicitly without silently rewriting historical records or deleting unrelated local state.
- Keep the current task's exact-final-SHA closeout separate from reused historical receipts, and do not edit tracked planning files merely to record that external final receipt.
- Keep validated tenant_scope predicates in search options while excluding the search-only key from strict runtime configuration in Single, Many, and FacetValues.
- Treat recorder evidence as library filter-composition proof; host identity, membership, trusted tenant selection, authorization, and database response scoping remain host-owned.
- [Phase 165]: Keep tenant_scope in the validated filter and remove it from all three runtime configuration inputs. — Public recorder probes reproduced strict runtime-config rejection in Single, Many, and FacetValues after schema-aware validation had composed the declared tenant field into filter. Dropping only this search-only key preserves strict runtime validation and the public input shape.
- [Phase 165]: Treat recording-backend tenant evidence as filter-composition proof only. — The tests prove supplied-scope composition and rejection before backend dispatch. Actor identity, membership, trusted tenant derivation, authorization, and database response scoping remain host-owned; this is not live-service or package evidence.
- [Phase 165]: Keep defaults and keyword-filter outcomes separate; retain a targeted live/package follow-up for the reproduced facet serializer defect. — Defaults passed their encoded request probe without correction. The keyword probe failed in Jason before HTTP; the correction now emits the existing filter grammar. This local proof does not establish live parser behavior or package loading. It also does not claim interruption or parallel execution semantics (EA-02).
- [Phase 166]: Derive tenant scope from the persisted host membership before search or facet dispatch. — A host-owned persisted authorization boundary prevents caller-supplied tenant selections from becoming trusted library scope.
- [Phase 166]: Keep raw search output and host hydration distinct; constrain hydration by tenant and returned IDs. — Separate assertions make raw-hit privacy visible and prevent database filtering from concealing foreign search results.
- [Phase 166]: Use a fixed paginated live query and explicit primary key for exact counts and deterministic Meilisearch setup. — The live evidence requires an exact count and tenant_id makes automatic Meilisearch primary-key inference ambiguous.
- [Phase 166]: Treat the repair report's mismatch as a known fixture precondition. — reconcile_sync reports task and reindex visibility; request telemetry and complete task snapshots establish its read-only behavior without claiming source-row/index-row discovery.
- [Phase 167]: Keep the eight milestone software claims separate by named scenario and measured source; workflow success is not blanket evidence.
- [Phase 167]: Keep planning tag v1.39, closeout run, published release scrypath-v0.3.13, and the Phase 166 local artifact as distinct identities.
- [Phase 167]: Reuse C-09 only for its bounded claim after every relevant changed path has a semantic disposition; the checker does not decide whether those reasons are true.
- [Phase 167]: Phase 167 Plan 02: keep readiness NOT READY because the Phoenix consumer lock has an unresolved High Mint advisory; no owner acceptance or dependency change is inferred.
- [Phase 167]: Phase 167 Plan 02: preserve unresolved inherited probes and keep final tracking/attestation pending at the dated cutoff.
- [Phase 169]: PR #85 was normally squash-merged only after the user's explicit authorization and passing required CI; GitHub records no review.
- [Phase 169]: Phase 169's frozen PR cohort decisions are record-first; no PR #65 or #68–#76 mutation was authorized or performed.
- [Phase 170]: Phase 170-01: Keep first-hour inline guidance prominent; canonical sync return semantics remain owned by Scrypath.sync_record/3 and the sync guide.
- [Phase 170]: Phase 170-01: Consolidate README and JTBD navigation while retaining every useful original route, six numbered jobs, the adoption progression, and explicit product limits.
- [Phase 170]: Phase 170-01: Route assertions establish structure only; P-170-DOC and EA-170-01 remain unresolved for bounded semantic review and interruption guarantees.
- [Phase 170]: Phase 170 Plan 02: Reuse the existing command surface and add no dependency, lane, or dispatch contract.
- [Phase 170]: Phase 170 Plan 02: Keep collection read-only, attempt-specific, bounded, and explicit about archive versus member hashes.
- [Phase 170]: Phase 170 Plan 02: Require supplied judgments and provenance; factual validation cannot authorize posting or semantic approval.
- [Phase 170]: Phase 170 Plan 02: Preserve the seven inherited edge probes as unresolved user-level assumptions.
- [Phase 170, historical delivery authorization]: The maintainer authorized the normal Release Please/Hex path for the candidate subject to then-current gates. Later live policy review and merge facts are recorded in the dated issue updates; PR #83 merged and 0.3.14 parity passed.
- [Phase 170, preterminal gate contract; superseded for GATE-05/CLOSE-04]: The frozen source receipt and NOT READY decision are published at issue #86 comment 5940381507. Later validator and release/closeout receipts are separate post-freeze evidence; they do not change the frozen Plan 08 summary or the original decision.

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 167, historical] The assessment was NOT READY: Phoenix consumer Mint 1.9.3 had an unresolved High advisory and condition 6 was UNKNOWN at its cutoff. This remains historical and is not a current v1.41 blocker.
- Historical evidence can be reused only after source-identity and relevant-path comparisons; unavailable or invalidated evidence is recorded with its precise limit rather than inferred.
- [Phase 167, historical] Release-reference mismatch and accepted archived planning debts remain bounded carry-forwards; they do not change the current v1.41 record.
- Phase 170's exact-source closeout and original six-condition judgment are recorded on issue #86. That dated result remains NOT READY (conditions 1–5 PASS, condition 6 FAIL) at its original cutoff. A fresh, separately dated READY assessment is recorded at [issue #86 comment 5955742805](https://github.com/szTheory/scrypath/issues/86#issuecomment-5955742805), within its stated assumptions and evidence limits. GSD Plan 08 tracking is complete through the explicitly authorized replacement recorded in `170-08-TRACKING-REPLACEMENT.md`; neither record authorizes replaying Phase 170.

### Maintainer Direction and Repository Check — 2026-09-28

- The maintainer wants evidence-gated near/mid/long horizons refreshed at each milestone; no calendar-driven or Dependabot-only milestones; releases when warranted; PR-first work, green post-merge `main`, exact-SHA evidence, and tidy task-owned branches/worktrees/artifacts.
- Default to zero human UAT: automate acceptance at the cheapest reliable layer and add recurring CI only when its confidence justifies GitHub Actions time and maintenance. Keep tests high-signal across happy paths, errors, and boundaries; use property testing and digital-twin adopters only for named risks that benefit from them. Measure performance before optimizing. Keep APIs, architecture, and docs readable, maintainable, user-job-focused, privacy-safe, and grounded in 12-factor configuration.
- Durable guide: `prompts/scrypath-milestone-ratchet-roadmap.txt`. Candidate horizons: `reference/milestone-candidates.md` and `reference/MILESTONE-ARC.md`. v1.41 scope is archived. The fresh READY assessment, maintainer availability, and separate scope approval were recorded on 2026-10-02; v1.42 is limited to the approved ScrypathOps incident-recovery journey.
- Hex 0.3.13 was published 2026-09-25. Privacy PR [#81](https://github.com/szTheory/scrypath/pull/81) merged the current-tree cleanup; a later authorized history rewrite moved all 12 public branch refs and 28 tags to sanitized history. Public `main` is now `40c9978c975dbfb42db75511f44ff0369c8d7d88`. A fresh mirror scan found no personal home-directory value in branch or tag history. Tree comparisons across 128 fetched refs preserved file paths and modes; the only file-content edits were path substitutions in planning documents, with no source-code changes. First changed commit: `0dcc97790c00fa360e72555ddf08609cc9203794` → `bec129bc8494d54a0cd4c598d4c44202290050cf`.
- GitHub's separate PR refs still expose the old path: 68 affected PRs across 88 fetched PR refs. The owner declined a Support request and accepts this residual because the exposure is a personal name/path. Public branch and tag refs and this local repository's refs are clean. Do not repeat the personal path in artifacts.
- Branch protection was restored after the rewrite: force pushes are disabled, linear-history protection remains enabled, and the same five required checks are configured. GitHub reported that an existing merge commit violates the linear-history rule; commit topology was preserved. Run `36419998362` failed twice on required `ecommerce-mounted`, while the earlier `36390328588` passed before the path-only rewrite. Investigation found no relevant source differences and identified an application startup-readiness race. Newer exact-SHA run `36439562644` passed all five required jobs, coverage, and attestation on the rewritten public SHA; advisory `deep-quality` still failed on Mint advisories. A narrow local fix is verified but uncommitted. Do not push the current 137-commit-ahead branch.
- This workspace is on `gsd/v1.38-cleanup-merged` at rewritten commit `830aacf383457c6e4a74eda0141235f1ab85c102`, 137 commits ahead of sanitized public `main` (`40c9978c975dbfb42db75511f44ff0369c8d7d88`) and not behind. All local branches and tags were rewritten; verification retained 1,884 commits, their parent links, and every historical file version, with no source-code changes. The local v1.39/v1.40 work remains unpublished; scope it into reviewed PRs before release claims. Current uncommitted planning edits and the untracked cache were preserved.

### Roadmap Evolution

- Phase 171 added: Create a focused closure phase for the Phase 170 verification coverage gaps identified by the v1.41 milestone audit.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| product scope | Follow-on operator UI, authentication product, public backend abstraction, and broad compatibility matrices | Deferred; requires concrete evidence and separate scope approval |
| release | Hex publication, retagging, and version bump | Only if a confirmed compatible code fix warrants the existing release train |
| verification topology | New required service lane | Deferred; retain the existing required/advisory split |

## Performance Metrics

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 165. Public Tenant and Facet Contracts | 2/2 | 25 min | 12.5 min |
| 166. Host Tenant and Repair Evidence | 3/3 | Duration unmeasured | - |
| 167. Dated Readiness and Closeout | 3/3 | 125 min executor work; orchestrator/final CI separate | - |
| 167 | 3 | - | - |
| 168 | 5 | - | - |
| 169 | 5 | - | - |
| 171 | 1 | - | - |
| 170 | 8 | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 165 P01 | 9 min | 2 tasks | 4 files |
| Phase 165 P02 | 16 min | 2 tasks | 3 files |
| Phase 166 P01 | 24 min | 2 tasks | 6 files |
| Phase 166 P02 | 14 min | 2 tasks | 1 files |
| Phase 166 P03 | Unmeasured | 2 tasks | 11 files |
| Phase 167 P01 | 36min | 2 tasks | 4 files |
| Phase 167 P02 | 47min | 2 tasks | 6 files |
| Phase 167 P03 | 42min | 2 tasks | 7 files |
| Phase 169 P05 | Unmeasured | 3 tasks | 5 files |
| Phase 170-documentation-and-readiness-closeout P01 | 29 min | 2 tasks | 4 files |
| Phase 170 P02 | 37m | 3 tasks | 3 files |
| Phase 170 P04 | not measured | 3 tasks | 1 files |
| Phase 170 P5 | not measured | 3 tasks | 2 files |
| Phase 170 P6 | unmeasured | 2 tasks | 12 files |

## Session Continuity

Last session: 2026-10-03 — v1.42 UI baseline and direction
Stopped at: Revised requirements and three specialist findings recorded; creating the roadmap and UI design contract under the maintainer's instruction to automate this cleanup
Resume file: .planning/research/v1.42/SUMMARY.md
Next action: Create the focused roadmap beginning at Phase 172, then a checked UI contract and implementation plans. Preview remains at http://127.0.0.1:4012/admin/search in Compose project scrypath-ui-v142. Keep automated seed/reset tests isolated from that preview. Do not rerun Phase 170 or its passing release/adopter checks.

## Operator Next Steps

- v1.41 is archived locally with 9/9 requirements, 4/4 phases, 6/6 integration paths, and 3/3 end-to-end flows complete. Three Nyquist validation records from Phases 168–170 remain disclosed nonblocking planning debt.
- The original Phase 170 decision remains **NOT READY** at its historical cutoff; the later fresh decision is **READY** within its stated limits and, together with the maintainer's approval, authorizes the bounded v1.42 scope.
- The v1.41 closeout requires no routine human UAT, product tests, or release checks. v1.42 aims to replace routine UAT with a deterministic browser journey and authoritative state assertions, placing recurring proof in CI when its value justifies its cost.
