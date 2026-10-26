---
gsd_state_version: "1.0"
milestone: v1.44
milestone_name: Sync correctness
current_phase: 181
current_phase_name: Schema hook contract and no-Oban build
status: completed
stopped_at: Phase 181 warnings fixed; security verified; hosted validation and v1.44 shipping pending
last_updated: "2026-10-26T17:13:02Z"
last_activity: 2026-10-26
last_activity_desc: Phase 181 review warnings fixed and local gates passed; security verified
state_head: c47c1216d0ae2e5c491751551f9aa019c619b3c6
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 17
  completed_plans: 17
  percent: 100
---

# Project State

## v1.44 Sync correctness — started 2026-10-25

All four phases (178–181) and 17 plans are complete locally. Phase 181's three
review warnings are fixed in `ee543836`, `1e2193bc`, `66598ccd` and `c47c1216`;
its five informational findings remain open. The authored security register is
verified at L1 (8/8 threats closed, no new risk acceptance). Validation is audited:
all local coverage passes, but exact-SHA hosted core evidence remains pending,
so `181-VALIDATION.md` retains `nyquist_compliant: false`.

Fresh checks at `c47c1216`: core 953 tests + 5 properties, 0 failures (including
strict docs and isolated no-Oban build); package 81 tests, 0 failures; explicit
docs-contract/package-metadata suite 79 tests, 0 failures. These are local results,
not hosted receipts. See Phase 181's REVIEW-FIX, SECURITY and VALIDATION records.

Continue from `/Users/jon/projects/scrypath`, branch
`planning/v1.44-new-milestone`. The pre-existing `.planning/config.json` edit is
preserved and excluded from fix commits. Next: `$gsd-ship` to reconcile the PR,
push the candidate and collect exact-SHA required gates. Then finish the hosted
validation row and audit/close v1.44. Merges/releases still need maintainer
confirmation. Do not replay completed phases or start v1.45 yet.

## v1.43 closed — 2026-10-25 (historical)

v1.43 is closed out and archived. The root `ROADMAP.md` is now an index of shipped milestones; no phase is active.

- Terminal closeout: [CI run 40204029522](https://github.com/szTheory/scrypath/actions/runs/40204029522) on merged main `ebed49b5` passed the five required jobs, coverage and `closeout-attestation`. Receipt: [reference/v1.43-final-receipt.json](reference/v1.43-final-receipt.json).
- T-177-05 is closed. T-177-06 (medium, below threshold) stays open; the missing container IDs can't be recovered.
- Archive: `milestones/v1.43-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md` and `milestones/v1.43-phases/`. Stray phase 89/95 files, root audits and `tmp_get_data.sh` are tidied; the stale dependency todo is removed.
- **Next: v1.44 sync correctness** (section 2 of [the rolling roadmap](reference/ROLLING-ROADMAP.md)), then v1.45 foundation and CI, then the v1.46–v1.47 UI quality engine, then v1.48 adopter features.

Approved on 2026-10-25: a UI quality engine (fractal stories, adopter-twin fixtures, composable LiveViews, layered checks) as v1.46–v1.47, with adopter features moving to v1.48. Each milestone runs the full GSD lifecycle. See [the recommendations](research/ui-quality-engine/RECOMMENDATIONS.md) and the rolling roadmap.

The 19 standalone `phase173_*` specs still have no automated coverage; this run's `ecommerce-e2e` failed exactly those 19. v1.45 fixes it.

## Rolling roadmap approved — 2026-10-25 (historical)

The 0.3.17 hotfix shipped ([#114](https://github.com/szTheory/scrypath/pull/114), [#115](https://github.com/szTheory/scrypath/pull/115)) and the maintainer approved the rolling roadmap.

## Idle — 2026-10-24 (historical)

No phase or approved work item is active. The 2026-10-22 feedback batch is merged and released:

- [#108](https://github.com/szTheory/scrypath/pull/108): Oban upsert jobs carry document ids and load current records, so Retry never resends stale data.
- [#109](https://github.com/szTheory/scrypath/pull/109): saved searches move into Search and a database table; Sync and index and the cross-schema Failed sync are reworked.
- [#110](https://github.com/szTheory/scrypath/pull/110): the follow-ups (Next try, destructive Delete, dividers, baselines, copyable search errors), plus fixes the full browser lane found (a saved-search crash, the sheet focus trap and `inert`, contrast-manifest drift).
- [#111](https://github.com/szTheory/scrypath/pull/111): `decimal`, `plug_crypto` and `bandit` advisories patched in all four dependency graphs.
- [#112](https://github.com/szTheory/scrypath/pull/112): the ScrypathOps security docs state the real `/ops` boundary.
- Released as **scrypath 0.3.16** ([#100](https://github.com/szTheory/scrypath/pull/100)).

Stale PRs #94, #95 and #97 are closed as superseded. Old worktrees are removed, with their unsaved work kept on local branches. The retained preview runs `ui/next` (tracking `origin/main`) in the canonical checkout, with seeding off and data preserved; see `UI-PREVIEW.json`.

Open, non-blocking:
- `deep-quality (advisory)` is red only on the `scrypath_ops` graph: `cloak`/`cloak_ecto` arrive through the optional `sigra` dependency and have no fixed release. The fix is queued in sigra (make `cloak_ecto` optional); bump sigra here when it ships.
- `make verify-e2e` shows 19 failures, all standalone `phase173_*` specs, because that lane doesn't start `standalone_ops:4003`. (Not covered elsewhere; see the correction above.)
- The maintainer's `examples/scrypath_ecommerce/priv/playbooks/my-search.json` hasn't been imported into the database yet.

Next: the maintainer's next UI feedback round, or a new milestone.

## Resumed — 2026-10-23 (historical)

The pause blocker is resolved. `b069c97e` restored touch-target size for the Sync activity failed-work link and its standalone help link; local `make verify-mounted` passed 4/4, Ops precommit 319 tests + 2 doctests, and every required hosted check passed at that head. [PR #107](https://github.com/szTheory/scrypath/pull/107) merged as `427dd1ab`. The retained preview now runs branch `ui/next-feedback` at that main commit, seed-disabled, with data and the maintainer saved search preserved; `npm run ui:preflight` passed. Next: a bounded UI feedback pass from the maintainer. Open cleanup outside this path: advisory `deep-quality` (decimal 3.1.1 advisory, also failing on main), release PR #100 without CI, stale draft PRs #94/#95/#97 and older worktrees.

## Session paused — 2026-10-22 (historical)

Resume from [the handoff](.continue-here.md) and [structured state](HANDOFF.json) in `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`, branch `fix/ui-iteration-3`. No numbered phase is active. Product implementation is committed through `c6522ea8`; [PR #107](https://github.com/szTheory/scrypath/pull/107) remains draft and unmerged. Its required `ecommerce-mounted` gate failed a `target-size` accessibility assertion in the Variant recovery journey; reproduce that exact gate before claiming PR readiness. The retained web/database/search services are stopped. Pause work changed handoff documents only; existing data and the maintainer's saved file remain intact. Later phase positions and closeout statements below are historical.

## UI iteration 3 — implemented and verified (2026-10-15)

All three requested batches are delivered in canonical branch `fix/ui-iteration-3`. See [results](reference/UI-ITERATION-3-RESULTS.md): 317 Ops tests + 2 doctests, 38 demo tests, 98 affected browser cases plus 16 final shared/contrast checks, and a source-bound 72-view rendered review. All 25 new feedback items have dispositions. The preview and maintainer saved file remain preserved. No numbered phase is reopened; historical frontmatter and chronology below are retained.

## Historical project reference

See PROJECT.md (updated 2026-10-25). Core value: make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding operational reality. Historical focus at this point: PR #98's exact-source closeout, since completed by the 2026-10-25 terminal closeout.

## Current Position

Phase: 181
Plan: 2/2 complete
Status: Review warnings fixed; local gates and security pass; hosted validation/shipping pending
Last activity: 2026-10-26 — Phase 181 post-review follow-up

Progress: [██████████] 100%

## Delivered Evidence

- Phase172:8/8 requirements and plans; independent verification38/38 truths; audit6/6 connections and5/5 flows. Archive: `milestones/v1.42-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md` and `milestones/v1.42-phases/`.
- PR91 merged3ad154a33f99cb200b791577aadc5970adc70ca2. Candidate135517b/run37178388184 passed104 browser,4 mounted, required gates, coverage and attestation. Scoped Ops also passed PR37178390800 and main37180290165. Root657tests+4properties0; Ops233+2doctests0.
- ReleasePR92 merged8dd20e8966acd17a4ef5acec653c00dc31faab49; `scrypath-v0.3.15` published. Run37181522723 passed publish/live Hex/consumer/HexDocs/tag parity; release-mainCI37181522706 passed required and scopedOps.
- Final exact-source closeout [run37183050686](https://github.com/szTheory/scrypath/actions/runs/37183050686) passed at `5ed440954ba70d2b94d8b480d625530e26a809ac`, including required gates, coverage and closeout attestation; the full browser lane passed104 tests and mounted lane4. Planning tag `v1.42` points to this source. PR93 merged the completed archive before this final run.
- All completion/audit/archive records preceded that attestation. Its source and retained preview worktree remain unchanged. The original dated handoff commit was planning-only. Later user-directed local UI follow-ups are recorded separately below; they are not part of the archived Phase172 plans, verification, or exact-source receipt. The archived v1.42 tracker's `state_head` identifies that attested input; the current v1.43 header serves GSD freshness tracking and does not extend the v1.42 receipt. The collected receipt is retained at `reference/v1.42-final-receipt.json`; its immutable artifact IDs/digests remain useful after the hosted artifacts expire.

- Phase177: 5/5 plans complete; verification passed 69/69 truths. Earlier candidate closeout [run38322328937](https://github.com/szTheory/scrypath/actions/runs/38322328937) passed all five required jobs plus coverage and exact-SHA attestation on `e051c3e959953591afdcccaeed5ea11b97a34529`. Latest PR #98 checks [run38338089123](https://github.com/szTheory/scrypath/actions/runs/38338089123) passed all five required jobs and both Ops UI checks on exact head `bebeb863493d1667ffa5f8c9fa3e890b484c5c1a`; the Website build also passed. `deep-quality (advisory)` failed, and `ecommerce-e2e (advisory)` was skipped. Candidate closeout on the final tracking source and merged-main attestation remain pending. The user waived only the formal-review gate; no review is claimed.

## Post-Archive Follow-Up

- Retained preview reconciliation, 2026-10-13: the old preview omitted uncommitted root radio work and later main fixes. The canonical UI checkout is now `/Users/jon/projects/scrypath/.claude/worktrees/ui-experience-reconciliation`, branch `fix/ui-experience-reconciliation`, based on main `f0e05bc8`. `:4002` mounts that checkout, with startup seeding disabled and existing records preserved. See `reference/UI-WORKTREE-RECONCILIATION.md` and `UI-PREVIEW.json`. Root Phase 173 tracking is historical; do not replay completed phases. Scoped control/framing recovery is locally verified; broader UI findings and delivery remain open.

- After the v1.42 receipt, commits `698013c`, `b10ba7d`, `7abb4c9`, and `961ecf4` addressed small operator UI issues: command-palette selection, refresh icon persistence, refresh feedback and breadcrumb cleanup, local hot reload, and theme-aware shared toast colors. These are committed on `planning/next-milestone-handoff`; they do not reopen Phase172.
- The preview at `http://127.0.0.1:4012/admin/search` was used for local browser review. The final toast styling was checked in light and dark themes and assets rebuilt. No hosted CI or milestone-level verification is claimed for these follow-ups.
- This user-requested local follow-up uses `/health` and “Search health” while retaining `/posture` as a compatibility redirect, standardizes refresh buttons, checked-time placement, and success feedback through one shared control, keeps failed-reason counts visible, and removes routine timestamp-copy controls. It also removes the unnecessary summary wrapper panel. The mounted preview rendered the Control Room, Search health, Failed sync work, and Sync and drift refresh controls and their action-specific feedback; the legacy path reached `/admin/search/health`. No automated tests or milestone-level verification were run or claimed for this follow-up.
- The current copy pass uses the Scrypath logo alone in the operator shell, aligns navigation, breadcrumbs, and page titles to “Search health,” “Failed sync work,” “Sync and drift,” and “Search,” and makes links name their actual destinations. The refreshed local preview was reviewed; no automated tests were run.
- On 2026-10-06, direct Search health feedback prompted a local layout correction: removed duplicate Impeccable preview wrappers from the shared panel, restored 24px section spacing, replaced sentence-length action links with concise shared controls and supporting prose, removed redundant section/diagnostic panels, and preserved full module names and readable timestamps. The broader recovery → verification → saved-check refinement sequence is captured in `reference/OPERATOR-UI-REFINEMENT.md`; no active phase was created.
- Local verification for the current changes: Ops `mix precommit` passed 233 tests and 2 doctests with zero failures; token contrast passed with zero AA failures (34 AAA advisory findings). Live desktop and 390px mobile review covered light and dark themes, measured 24px section gaps and 40px action controls, and found no horizontal overflow. Diagnostic subgroups are transparent and full identifiers/timestamps remain readable. The revised browser depth spec parsed/listed 33 tests; the full browser matrix was not executed or the feedback preview reseeded. These local results are not hosted exact-SHA evidence and do not extend the archived Phase172 receipt. The temporary test database was removed after validation; preview data remains intact.
- Later on 2026-10-06, the maintainer identified shared visual defects: shell gradients, broad yellow warning fills/outlines, green zero-error metrics, double theme selection, quiet-action hover colors, and dense last-success timestamps. The refinement brief now puts shared visual foundations first and records concrete acceptance criteria, including human-readable operational times and truthful clipboard/toast feedback. This follow-up edits planning/design context only; no UI implementation, new test run, commit, or milestone activation is claimed.
- On 2026-10-13, the maintainer opened [UI-FEEDBACK.md](UI-FEEDBACK.md) from the live preview with storefront hover/facet feedback, ScrypathOps palette and theme-picker concerns, and operator-guide rendering/link concerns. The maintainer says more issues may follow; append them and keep the review open until each item is checked against current rendered behavior.
- User-directed UI automation pilot on 2026-10-13: [UI-REVIEW-PILOT.md](reference/UI-REVIEW-PILOT.md) records 63/63 observation-only captures of all current screens, new hierarchy/language/rendered-color findings, contradictory legacy visual assertions, and uncovered journey/state proofs. The executable loop is `npm run ui:review` from the demo in the retained preview worktree; AGENTS.md links its review protocol. Active preview is `scrypath_ecommerce-web-1` on `http://127.0.0.1:4002`, mounting this `phase-174-recovery-entry-diagnosis` worktree; older 4012 paragraphs below are historical. Product review remains needs-work. This local follow-up does not reopen completed Phases 173–177 or extend their hosted receipts; next UI work is a coherent repair batch from the whole-app report, not phase replay.

## Durable Defaults

Use shared tokens/components and concise domain terms; preserve schema context and distinguish accepted work from exact task/document evidence. Keep inaccessible/missing/remote/expired evidence unknown and retain failure history. Automate recurring checks in existing economical CI lanes. Direct screenshot review supplements executable layout/focus/contrast checks; no paid judge or routine human UAT. Reopen only for named new evidence. See `reference/OPERATOR-UI-QUALITY.md` and PROJECT.md.

Always finish a phase/milestone handoff with the completed phase, the exact next GSD command, why it advances work, and whether context can be cleared. The persistent policy is PROJECT.md's **GSD handoff default**.

### Historical Boundaries

- v1.41 is archived with 9/9 requirements, 4/4 phases, 6/6 integration paths, and 3/3 end-to-end flows complete. Its audit accepts nonblocking Nyquist validation-record debt for Phases 168–170; Phase 171 is validated.
- The original Phase 170 decision remains **NOT READY** at [issue #86 comment 5940381507](https://github.com/szTheory/scrypath/issues/86#issuecomment-5940381507). The later separate assessment is **READY** at [comment 5955742805](https://github.com/szTheory/scrypath/issues/86#issuecomment-5955742805), within its stated limits; inherited assumptions EA-167-01–EA-167-07 remain unresolved.
- Current GSD tracking records Phase 170 at 8/8 through its authorized planning-side replacement. The frozen `8c271…` snapshot remains historical 17/18 with original bytes preserved. See `milestones/v1.41-phases/170-documentation-and-readiness-closeout/170-08-TRACKING-REPLACEMENT.md` and `170-POST-FREEZE-RECONCILIATION.md`. Do not rerun Phase 170.
- Scrypath 0.3.14 publication/parity and exact-main closeout are recorded in PROJECT.md and the v1.41 archive. Those receipts and older readiness cutoffs remain source-bounded; they do not verify changed v1.42 UI behavior. Historical “What's next” statements describe archive-time posture.

## Deferred Items

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| Product scope | New workflows, core APIs, backend abstraction, host authorization product, broader matrices | Separate concrete evidence and scope required | 2026-10-03 | v1.42 |
| Visual scope | Shared color/surface token revision versus framework replacement/wholesale CSS rewrite | Concrete 2026-10-06 feedback reopens shared visual tokens; framework replacement and unrelated rewrites remain deferred. See the refinement brief. | 2026-10-06 | Post-v1.42 |
| Verification topology | New required CI job or paid visual-judge service | Existing economical lanes are the default | 2026-10-03 | v1.42 |
| Historical planning | Nyquist validation records for Phases 168–170 | Accepted nonblocking v1.41 audit debt; no phase replay | 2026-10-02 | v1.41 |

## Preview and Cleanup

Preview http://127.0.0.1:4012/admin/search remains healthy under Compose `scrypath-ui-v142`, without reseeding. Container `scrypath-ui-v142-web-1` bind-mounts this checkout (`/Users/jon/projects/scrypath` → `/app`), so `:4012` is the correct hot-reloading preview for current source. Stop from `examples/scrypath_ecommerce` with `COMPOSE_PROJECT_NAME=scrypath-ui-v142 WEB_PORT=4012 docker compose -f compose.yaml -f compose.dev.yaml down`; preserve volumes.

Both disposable verification projects and their owned networks/volumes were removed after artifact collection. Unrelated services remain untouched. The previous normal-checkout state at11ab1c9 is preserved on `gsd/v1.38-cleanup-merged`, with its existing2026-10-02 stash. On2026-10-04 the clean normal checkout was safely switched to a new branch from final main for this planning-only handoff; the old branch and stash were not reset or applied.

## Session Continuity

Last session: 2026-10-26T17:13:02Z
Stopped at: Review warnings fixed; security verified; validation awaits hosted core; next $gsd-ship
Resume file: .planning/phases/181-schema-hook-contract-and-no-oban-build/.continue-here.md

Phases 173–177 have complete plan sets and 21 summaries (Phase 173: 4, Phase 174: 3, Phase 175: 4, Phase 176: 5, Phase 177: 5). All five phase verification reports pass. Phase 174 is current-source verified at 19/19 must-haves. Phase 177 verifies 69/69 truths. PR #98 is draft at exact head `bebeb863493d1667ffa5f8c9fa3e890b484c5c1a`; run 38338089123 passed the five required jobs, with `deep-quality (advisory)` failed and `ecommerce-e2e (advisory)` skipped. T-177-05 stays blocking pending final-source closeout and merged-main attestation; T-177-06 remains a separate open medium recordkeeping gap below the configured high threshold.

User-directed follow-up: the mounted ScrypathOps UI links the bundled Scrypath SVG/ICO favicon under its mount path. The focused e-commerce controller suite passed 5/5; current-head hosted required and Ops UI checks passed on the PR #98 head above.

Phase 176 closed with all 75/75 phase truths verified, OPUX-23–OPUX-25 satisfied, and no open review or security findings. At exact source `3cc55bdcf7b6e6bcd06572dd17c9be9ab31d7dd2`, `mix verify.ops_ui` passed 2 doctests and 301 tests; the focused Store/Search/Playbook suite passed 75 tests; the operator browser matrix passed 38/38; asset build, root regression tests, and AA contrast checks passed. Implementation and verification details, including the accepted local-host trust boundary and spec-less Store idempotency/concurrency assumptions, are recorded in the phase artifacts. The disposable Phase 176 browser stack was removed; preview port 4012 was left untouched.

The initial isolated executor could not create its normal per-task commits. The maintainer-approved recovery recorded the already-verified Phase 176 delta without replaying completed implementation. Final source commits are `ec13329`, `3cbbb91`, and `3cc55bd`; phase closeout records preserve the recovery decision, reviews, validation, security posture, and verification result.

Next command after the exact-source candidate and merged-main closeout attestations: `$gsd-secure-phase 177`, from a planning-only successor based on the attested main SHA. It re-audits T-177-05 against immutable terminal evidence without extending the attested source. Run `$gsd-audit-milestone v1.43` only after the high-severity closeout threat is closed. Do not replay Phases 173–177. The archived v1.33 Phase 124 gate remains acknowledged and deferred per the maintainer's earlier choice.

The v1.43 execution order 173 → 174 → 175 → 176 → 177 is complete. Preserve the intentional adaptive model routing in .planning/config.json and do not extend archived source receipts.

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 174 P01 | 6min | 2 tasks | 4 files |
| Phase 174 P02 | 20min | 2 tasks | 3 files |
| Phase 174 P03 | 8min | 2 tasks | 3 files |
| Phase 175 P01 | 21min | 2 tasks | 4 files |
| Phase 175 P02 | 18min | 2 tasks | 6 files |
| Phase 176 P02 | 19min | 2 tasks | 5 files |
| Phase 176 P03 | 30min | 2 tasks | 5 files |
| Phase 176 P04 | 52min | 2 tasks | 4 files |

## Decisions

- [Phase 174]: Keep URL schema identity and the host gate authoritative for recovery actions.
- [Phase 174]: Derive retry eligibility from the existing RecoveryAction and show unsupported work as unavailable.
- [Phase 174]: Keep Control Room fleet-level with one generic health route; schema identity starts at Search health.
- [Phase 174]: Retain the last complete posture snapshot on partial refresh and never announce refresh success without complete observations.
- [Phase 174]: Keep no-schema and missing-backend guidance distinct, with no retry or recovery offer.
- [Phase 174]: Preserve Posture ranking and classification; render the schema-specific handoff only when failed tasks are observed.
- [Phase 174]: Keep each schema as one labelled health article with plain Backend and Queue groups.
- [Phase 175]: Keep document freshness as a distinct receipt-correlated observation rather than inferring it from queue or contract status.
- [Phase 175]: Keep refresh observational and preserve the previous result with its checked time until a new observation succeeds.
- [Phase 175]: Reuse the existing selected-schema failed-sync route for ordinary repair and leave index promotion in its advanced section.
- [Phase 175]: Promotion completion requires exact task identity and fresh selected live-index and contract evidence; task success alone remains unknown.
- [Phase 175]: Check expected document effects only when authoritative prepared-target identity applies; otherwise show not checked.
- [Phase 175]: Refresh reads the retained promotion task UID asynchronously and never resubmits the swap.
- [Phase 176]: Search capture preserves the no-replace policy through the existing Store and collision guard.
- [Phase 176]: Filename-associated save errors retain user fields and show safe actual filesystem reasons with recovery guidance.
- [Phase 176]: Exact Search capture JSON stays in a closed native disclosure; no dependency was needed.
- [Phase 176]: Keep valid-draft saving independent from running; only a successful Store write changes saved provenance.
- [Phase 176]: Keep the historical run snapshot separate from the selected draft so later loads/imports cannot relabel its result or Search handoff.
- [Phase 176]: Hide a multi-query Search handoff when one query cannot faithfully represent the captured run.
- [Phase 176]: Keep file bytes unconsumed until explicit Import submit; phx-change only registers upload state with LiveView.
- [Phase 176]: Render import failures once as an associated inline alert, retain the prior valid preview, and keep submitted paste open for recovery.
- [Phase 176]: Keep the 256,000-byte ceiling and avoid new dependencies or persistence abstractions.
