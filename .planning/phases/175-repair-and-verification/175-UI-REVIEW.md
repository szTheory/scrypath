# Phase 175 — UI Review

**Audited:** 2026-10-11  
**Baseline:** Approved [175-UI-SPEC.md](175-UI-SPEC.md), inheriting Phase 173 Ops tokens and shell  
**Screenshots:** Not captured for this re-audit. The Sync and drift route returned 404; the only responding candidate, localhost:8080, served Traefik Proxy. The earlier Phase 175 browser review predates the b65effa refresh-state change.  
**Interaction captures:** Off (workflow.ui_interaction_capture is absent; default is false)  
**Registry audit:** Not applicable; shadcn is not initialized and the UI-SPEC lists no third-party registries.

The pending refresh state suppresses prior document evidence while rechecking and shows progress beside the retained task. The prior duplicate generic sentence about live-index/contract evidence remains suppressed when document-observation detail is present. The final failed-read copy now shows a bounded, sanitized reason and says refresh checks the same retained task without submitting another operation. The only remaining review limitation is unavailable browser capture for the updated state.

## Pillar Scores

| Pillar | Score | Key finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Failed task reads preserve a sanitized reason and direct operators to refresh the same task without resubmitting. |
| 2. Visuals | 3/4 | The native advanced disclosure keeps promotion apart from routine evidence, but the updated long result copy could not be captured at desktop or narrow widths. |
| 3. Color | 4/4 | Unknown remains a warning cue on a neutral surface, paired with a visible status title and explanatory text. |
| 4. Typography | 4/4 | Status copy uses the Ops body token, headings remain semibold, and task IDs use the existing inline-code treatment. |
| 5. Spacing | 4/4 | The disclosure keeps the existing 24px section offset and compact internal rhythm; the new detail adds no wrapper or spacing exception. |
| 6. Experience Design | 4/4 | The observer failure retains task identity and refreshes that same task without submitting another swap; no applicable document effect explicitly stays “not checked.” |

**Overall: 23/24**

## Top 3 Priority Fixes

1. **Capture the updated result layout when the Scrypath route is available.** Check the pending, failed-read, expected-document error, and no-applicable-effect states at 320px, 390px, 768px, and 1440px.
2. **Resolved — clarify failed task-read recovery copy.** The result retains the task UID, shows a bounded reason, and directs refresh to the same task without submitting another operation.
3. **Resolved — keep stale document evidence out of the pending state.** The loading copy says it is checking the retained task and current index evidence; prior verified-document copy is hidden until a fresh observation returns.

## Detailed Findings

### Pillar 1: Copywriting (4/4)

The unavailable-read case says, “The swap task succeeded, but its expected-document observation could not be confirmed.” It renders the expected-document reason and retained task UID, and does not claim either that the swap failed or that it completed. The generic sentence claiming the live-index or contract effect could not be confirmed is suppressed for this document-observation state. See [sync_drift_live.ex:1882](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1882) and [sync_drift_live.ex:1911](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1911).

The copy helper exposes the observer reason and directs the operator to refresh the same task. With no applicable receipt, the text explicitly says document freshness was not checked and does not claim documents were observed. The regression assertions cover both cases in [sync_drift_live_test.exs:877](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:877) and [sync_drift_live_test.exs:912](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:912).

**Resolved — failed task-read copy.** The result preserves unknown status and the task UID, renders only a bounded reason (`task_identity_mismatch`, `task_unavailable`, `task_read_failed`, or `task_observation_exit`), and says, “Refresh to inspect this same task; do not submit another operation.” The generic fallback is gated off when that reason exists. This follows the approved unknown-state contract while avoiding a false claim that the remote swap failed. The sanitizing helper and state retention are in [sync_drift_live.ex:1183](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1183) and [sync_drift_live.ex:1196](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1196); the rendered copy is in [sync_drift_live.ex:1911](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1911). Regression coverage asserts the reason, same-task/no-resubmit guidance, and stale-copy suppression in [sync_drift_live_test.exs:1046](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:1046).

### Pillar 2: Visuals (3/4)

**WARNING — render evidence is incomplete for the updated state.** The page keeps “Advanced: index promotion” inside its native disclosure, separate from the sync, contract, document, and ordinary-recovery evidence; the result stays beside its task ID and refresh control in [sync_drift_live.ex:1826](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1826) and [sync_drift_live.ex:1853](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1853). The audit could not confirm how the additional reason copy wraps or how much vertical space it occupies because the target route was unavailable. This is a verification limitation, not an observed layout defect.

### Pillar 3: Color (4/4)

Unknown promotion outcomes use the warning status kind and keep the surface neutral. The title “Index swap outcome unconfirmed” and explanatory text carry the meaning; a restrained semantic cue supplies a second signal. The status component exposes its kind as data and applies the neutral surface treatment in [ops_ui.ex:351](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:351) and [app.css:557](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/assets/css/app.css:557). No status meaning depends on color alone.

### Pillar 4: Typography (4/4)

The result uses the existing Ops body-size token and semibold status title. The task UID remains in the inline-code component, preserving its established technical-value treatment. These styles match the approved 14px body and semibold-label contract; see [ops_ui.ex:363](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex:363) and [sync_drift_live.ex:1861](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1861).

### Pillar 5: Spacing (4/4)

The promotion result remains inside the existing flat disclosure, with the established mt-6, space-y-3, and px-4 pb-4 rhythm. Reason paragraphs use break-words; no nested dashboard panel or new spacing token was added. The markup is in [sync_drift_live.ex:1826](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1826) and [sync_drift_live.ex:1887](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1887).

### Pillar 6: Experience Design (4/4)

The pending state replaces an earlier “verified” document result with “Checking the retained swap task and current index evidence,” and hides the old effect copy until a current observation returns. On task-read failure, the status returns to unknown, clears stale document claims, and keeps the UID. The no-applicable-effect control still says freshness was not checked and does not claim expected documents were observed. Tests cover these states in [sync_drift_live_test.exs:987](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:987), [sync_drift_live_test.exs:1052](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:1052), and [sync_drift_live_test.exs:912](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs:912).

Unknown/accepted updates use role=status; terminal task failures use role=alert, and the status is scoped to the promotion result rather than the whole evidence page. While a refresh is pending, status remains a non-focus-moving progress announcement and the task UID stays visible. The markup and status mapping are in [sync_drift_live.ex:1474](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1474) and [sync_drift_live.ex:1860](/Users/jon/projects/scrypath/.claude/worktrees/phase-174-recovery-entry-diagnosis/scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex:1860); existing tests assert status semantics for accepted and canceled outcomes.

## Verification Evidence

- Final-source evidence on `fdaf9b8`, reported after the copy fix: the updated failed-read regression passed (1/1), focused document + LiveView suites passed (44/44), `mix precommit` and root `mix verify.ops_ui` each passed (266 tests + 2 doctests), and the mounted operator lane passed (4/4).
- My isolated focused `mix test ...:1024` attempt failed before the test body with `DevRouter.verified_route?/2` unavailable during a concurrent build. The final clean reruns above supersede that tooling/parallel-run anomaly; it is not a UI finding.
- Browser screenshots for the updated state remain unavailable because the Sync and drift route was not served on the candidate local ports; this is the sole remaining review limitation.

## Files Audited

- 175-UI-SPEC.md, 175-03-SUMMARY.md, and 175-04-PLAN.md
- scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex
- scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
- scrypath_ops/assets/css/app.css
- scrypath_ops/test/scrypath_ops_web/live/sync_drift_live_test.exs

