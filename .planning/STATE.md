---
gsd_state_version: "1.0"
milestone: v1.41
milestone_name: Readiness Gate Follow-Through
current_phase: 170
current_phase_name: documentation-and-readiness-closeout
current_plan: 8
status: executing
stopped_at: Completed Phase 170 Plan 07; Plan 08 is pending external attestation and maintainer decision
last_updated: "2026-10-01T13:02:35.741Z"
last_activity: 2026-10-01
last_activity_desc: Phase 170 learnings were extracted, including validator dependency-closure and pre-freeze privacy checks; Plan 08 remains pending external attestation and the maintainer decision.
state_head: 3d552cd634cbacdd09a570bc19d43baadd5e8218
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 18
  completed_plans: 17
  percent: 67
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** Phase 170 — Documentation and Readiness Closeout

## Current Position

Phase: 170 (documentation-and-readiness-closeout) — IN PROGRESS
Total Phases: 3
Current Plan: 8
Total Plans in Phase: 8
Status: Plan 07 tracked bookkeeping and cleanup are complete; the exact source snapshot is being frozen for Plan 08. PR #83 remains authorized but blocked at its required review gate. Issue #86 is the terminal decision authority; no terminal comment exists yet.
Last Activity Description: Plan 06 reconciled current inputs and preterminal reports. PR #83 remains blocked: live policy requires one actual approving GitHub review, and none exists as of 2026-10-01 02:05 UTC.
Last activity: 2026-10-01

## v1.41 Upstream Review

- Current input: `research/v1.41/SUMMARY.md` (also routed from `research/SUMMARY.md`). Three requested GPT-6 Astra xhigh reviews found material security, proof, delivery and closeout scope corrections; this is research, not software verification.
- Phase 168 is complete: the mounted-readiness correction shipped in PR #82 and the four-graph security/proof work shipped in PR #84. All five plans and four mapped requirements have passing verification. No candidate package was published to Hex.
- Phase 169: PR #85's tenant/facet corrections and coherent proof are merged and verified; Plan 05 records the complete owned delta and finite frozen-cohort decisions. No cohort PR mutation was authorized or performed.
- Phase 170: preserve first-hour docs context while consolidating duplication; deliver final docs and warranted patch; freeze tracked inputs, attest final source, then issue a durable terminal six-condition record outside the tested tree.
- The maintainer approved the review's revised scope and phase mapping on 2026-09-28. Requirement IDs now continue existing numbering: DOC-03, GATE-05, CLOSE-04; MINT-03 captures recurring prevention. Phase 168 CONTEXT carries those approvals and canonical research references. Phase 168 completed with all five plans summarized and verified against source-specific delivery evidence. Phase 169 completed with all five plans and passed goal verification on 2026-09-30. Phase 170 Plans 01–07 are complete; Plan 08 owns exact-source attestation and the actual maintainer's terminal decision. Historical outcomes remain unchanged.

## Last Milestone Context — v1.40 (Archived)

**Goal:** Close decision-relevant adopter evidence gaps for tenant-safe search and bounded repair, reuse valid delete and release receipts, and make a fresh six-condition readiness decision without starting operator UI work.

**Scope boundary:** Verify existing public tenant-scope and facet-value input contracts, correct only confirmed compatible defects, prove one representative host-owned tenant search workflow and one bounded manual repair-to-visible-search workflow, and reconcile condition 3/6 evidence. Host authentication, membership policy, trusted tenant selection, and database response scoping remain application-owned. No public backend abstraction, broad endpoint/version matrix, operator UI, new required CI lane, or forced Hex release is included.

**Gate:** Preserve the Phase 164 assessment unchanged: it records conditions 3 and 6 as UNKNOWN and readiness as **NOT READY**. The new assessment is separately dated, evaluates all six conditions independently, and may truthfully remain **NOT READY**. A passing assessment only recommends a later ScrypathOps focus.

## Recent Evidence

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
- [Phase 170]: Authorize the normal protected release path for the exact PR #83 0.3.14 candidate at head 64963c7042c451f9d4932fee7850d8bf7ca93684, conditional on all current repository gates. — On 2026-10-01 the user instructed: “resolve a checkpoint or whatever do it automatically follow your recommendations.” Scope is the exact candidate and normal Release Please/Hex chain; this does not supply or waive the actual protected GitHub review.
- [Phase 170]: Keep GATE-05 and CLOSE-04 pending until the frozen source is attested and the accountable maintainer supplies and publishes the six-condition terminal decision; factual CI and the still-blocked PR #83 cannot supply that judgment.

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 167] The assessment is NOT READY: Phoenix consumer Mint 1.9.3 has an unresolved High advisory with no owner acceptance; condition 6 was UNKNOWN at the assessment cutoff.
- Historical evidence can be reused only after source-identity and relevant-path comparisons; unavailable or invalidated evidence is recorded with its precise limit rather than inferred.
- [Phase 167] Release-reference mismatch and three accepted archived planning debts remain bounded carry-forwards. Seven Phase 167 assumptions, eleven inherited Phase 166 probes, and six descriptor-less prohibitions remain unresolved constraints.
- The phase-tracking final-source receipt is external and source-bound to `343e20be66ab0c17f62b95138203c86e868bd1ee`. The later milestone archive records planning history; it does not change the implementation or dated readiness outcome.
- PR #83 0.3.14 is authorized but blocked before merge. The 2026-10-01 11:08 UTC refresh still shows no actual approving GitHub review and a `BLOCKED` merge state. An authorized Scrypath reviewer must approve unchanged head 64963c7042c451f9d4932fee7850d8bf7ca93684; if it clears before freeze, refresh the facts and route back through Plan 05.
- Phase 170's final exact-source attestation and six maintainer judgments remain pending at issue #86. The real maintainer must provide PASS/FAIL/UNKNOWN and rationale for each condition, then approve the exact terminal record before it is posted.

### Maintainer Direction and Repository Check — 2026-09-28

- The maintainer wants evidence-gated near/mid/long horizons refreshed at each milestone; no calendar-driven or Dependabot-only milestones; releases when warranted; PR-first work, green post-merge `main`, exact-SHA evidence, and tidy task-owned branches/worktrees/artifacts.
- Default to zero human UAT: automate acceptance at the cheapest reliable layer and add recurring CI only when its confidence justifies GitHub Actions time and maintenance. Keep tests high-signal across happy paths, errors, and boundaries; use property testing and digital-twin adopters only for named risks that benefit from them. Measure performance before optimizing. Keep APIs, architecture, and docs readable, maintainable, user-job-focused, privacy-safe, and grounded in 12-factor configuration.
- Durable guide: `prompts/scrypath-milestone-ratchet-roadmap.txt`. Candidate horizons: `reference/milestone-candidates.md` and `reference/MILESTONE-ARC.md`. v1.41 scope is approved; its README/JTBD consolidation is narrow and evidence-backed. ScrypathOps remains gated on a fresh READY assessment, maintainer availability, and a separate scope decision.
- Hex 0.3.13 was published 2026-09-25. Privacy PR [#81](https://github.com/szTheory/scrypath/pull/81) merged the current-tree cleanup; a later authorized history rewrite moved all 12 public branch refs and 28 tags to sanitized history. Public `main` is now `40c9978c975dbfb42db75511f44ff0369c8d7d88`. A fresh mirror scan found no personal home-directory value in branch or tag history. Tree comparisons across 128 fetched refs preserved file paths and modes; the only file-content edits were path substitutions in planning documents, with no source-code changes. First changed commit: `0dcc97790c00fa360e72555ddf08609cc9203794` → `bec129bc8494d54a0cd4c598d4c44202290050cf`.
- GitHub's separate PR refs still expose the old path: 68 affected PRs across 88 fetched PR refs. The owner declined a Support request and accepts this residual because the exposure is a personal name/path. Public branch and tag refs and this local repository's refs are clean. Do not repeat the personal path in artifacts.
- Branch protection was restored after the rewrite: force pushes are disabled, linear-history protection remains enabled, and the same five required checks are configured. GitHub reported that an existing merge commit violates the linear-history rule; commit topology was preserved. Run `36419998362` failed twice on required `ecommerce-mounted`, while the earlier `36390328588` passed before the path-only rewrite. Investigation found no relevant source differences and identified an application startup-readiness race. Newer exact-SHA run `36439562644` passed all five required jobs, coverage, and attestation on the rewritten public SHA; advisory `deep-quality` still failed on Mint advisories. A narrow local fix is verified but uncommitted. Do not push the current 137-commit-ahead branch.
- This workspace is on `gsd/v1.38-cleanup-merged` at rewritten commit `830aacf383457c6e4a74eda0141235f1ab85c102`, 137 commits ahead of sanitized public `main` (`40c9978c975dbfb42db75511f44ff0369c8d7d88`) and not behind. All local branches and tags were rewritten; verification retained 1,884 commits, their parent links, and every historical file version, with no source-code changes. The local v1.39/v1.40 work remains unpublished; scope it into reviewed PRs before release claims. Current uncommitted planning edits and the untracked cache were preserved.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| product scope | Operator UI, brand/design work, authentication product, public backend abstraction, and broad compatibility matrices | Deferred; requires a separate evidence-backed scope decision |
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

Last session: 2026-10-01T11:22:30.153Z
Stopped at: Completed Phase 170 Plan 07; Plan 08 is pending external attestation and maintainer decision
Resume file: .planning/phases/170-documentation-and-readiness-closeout/170-08-PLAN.md
Next command: $gsd-execute-phase 170 (Plan 08 exact-source attestation; stop at the actual maintainer decision checkpoint)

## Operator Next Steps

- Phase 168 is complete with all five plans and source-specific verification; do not rerun it.
- Phase 169 is complete and goal verification passed (41/41, with the review-first plan wording recorded as an explicit user-authorized override; no GitHub review is claimed). Its regression gate passed 66 tests. PR #85 is merged and post-merge CI is green; detailed source and cohort evidence is owned by [169-05-SUMMARY.md](phases/169-library-fix-delivery-and-pr-triage/169-05-SUMMARY.md), delivery receipts by [169-04-SUMMARY.md](phases/169-library-fix-delivery-and-pr-triage/169-04-SUMMARY.md), and verification by [169-VERIFICATION.md](phases/169-library-fix-delivery-and-pr-triage/169-VERIFICATION.md). Cohort close/update decisions remain pending because only PR #85 was authorized for external mutation.
- The Plan 05 release path is authorized for exact PR #83/head 64963c7042c451f9d4932fee7850d8bf7ca93684, conditional on repository gates. The actual GitHub approving review remains outstanding; do not merge or publish until it is submitted and checks are refreshed. Plan 07 has refreshed the gate and is finishing the source freeze. Plan 08 owns the exact-source attestation and requires the actual maintainer's six judgments and approval of the exact public record; issue #86 remains the authority.
- Preserve the unrelated dirty working-tree state; do not push the accumulated maintainer branch as a delivery unit.
- Phase 170 owns final documentation, warranted release evaluation, and the terminal six-condition readiness record. Existing attestations certify jobs, not all six semantic judgments. Plan 08 must stop at its human decision checkpoint if judgments or exact-body approval are missing.
- The progress audit found zero pending todos, zero current-milestone UAT debt, zero open windows, and no active debug sessions. The only UAT entries are two covered tests in resolved archived Phase 65.
- v1.40 Phases 165–167 and historical assessments remain archived. Preserve the accepted privacy residual and unrelated local state. UI requires a passing fresh gate, maintainer availability and separate scope approval.
