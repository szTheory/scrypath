---
project: Scrypath
scope: UI recovery and preview continuity follow-ups
phase: null
generated: "2026-10-14"
counts:
  decisions: 3
  lessons: 6
  patterns: 4
  surprises: 3
source_artifacts:
  - UI-WORKTREE-RECONCILIATION.md
  - ../UI-FEEDBACK.md
  - ../../examples/scrypath_ecommerce/e2e/UI-REVIEW.md
delivery:
  recovery: https://github.com/szTheory/scrypath/pull/102
  artifact_preservation: https://github.com/szTheory/scrypath/pull/103
---

# Lessons from the UI worktree incident

The radio change was stranded as an uncommitted edit in one checkout while the preview served another checkout that also omitted later merged fixes. During recovery, ordinary Playwright cleanup deleted review captures stored in its output directory. Source edits were preserved; some raw review artifacts were lost and were disclosed rather than relabelled as current evidence.

These are project-level lessons from follow-up PRs, not a replacement for completed phase verification. The operational entry point is AGENTS.md; the current preview pointer is `UI-PREVIEW.json`. The detailed dated evidence is in [the reconciliation report](UI-WORKTREE-RECONCILIATION.md).

## Decisions

### Verify the running source before treating a preview as current
Use the actual Docker bind mount, published URL/port, branch, source fingerprint and refreshed main ref. A familiar directory name or working URL is insufficient.

**Rationale:** The old preview was functional while serving incomplete source. `ui:preflight`, capture and review checks reuse the source/port/main guards; preflight also exposes pending local work before edits.
**Source:** [Reconciliation report](UI-WORKTREE-RECONCILIATION.md), “What happened”; [review runner](../../examples/scrypath_ecommerce/e2e/ui-review.mjs).

### Reconcile intended changes without replacing newer safeguards
Inventory local deltas, preserve originals, carry only owned changes, and compare the destination against current main. Recover presentation intent while keeping newer scope, provenance and recovery behavior.

**Rationale:** Wholesale copying the older Posture template or schema helper would undo later protections. The radio recovery deliberately omitted the old first-option fallback.
**Source:** [Reconciliation report](UI-WORKTREE-RECONCILIATION.md), “Local-delta disposition”.

### Give visual evidence a separate storage lifecycle
Keep captures and review records together in ignored `ui-review-artifacts/`, outside Playwright's `test-results/` cleanup boundary. Archive or remove evidence deliberately.

**Rationale:** Test cleanup must not delete the evidence needed for later review or context restoration. No dependency was added.
**Source:** [PR #103](https://github.com/szTheory/scrypath/pull/103); [cleanup regression](../../examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs).

## Lessons

### Dirty work is local to a checkout
Creating a worktree from a commit does not transport uncommitted edits. Before isolation, checkpoint the intended source in an owned commit or a scoped patch with an inventory; verify each delta's disposition after transport.

**Context:** The visible-radio edit remained in the root checkout while phase work branched from committed source. Preserve unrelated local notes/settings rather than committing or stashing everything indiscriminately.
**Source:** [Reconciliation report](UI-WORKTREE-RECONCILIATION.md), “What happened” and “Local-delta disposition”.

### The shell, preview and planning snapshot can describe different states
Anchor every edit and command to an explicit absolute working directory. Resolve the preview pointer and actual mount before using local source or old phase metadata as authority.

**Context:** Port 4002 served a different worktree; the root still displayed a historical Phase 173 execution position. Completed phases must not be replayed to repair that mismatch.
**Source:** [Reconciliation report](UI-WORKTREE-RECONCILIATION.md), “What happened”; [current handoff](../STATE.md).

### A squash merge changes commit identity without losing content
Read the actual merged commit, refresh main, then compare relevant files or the complete tree. Reconcile history without resetting dirty checkouts.

**Context:** PR #102's candidate and squash commit had different SHAs; after incorporating main, the preview tree matched it exactly. Source comparisons, not SHA equality alone, established delivery.
**Source:** [Reconciliation report](UI-WORKTREE-RECONCILIATION.md), “Continue”.

### Native form state may differ from server-rendered attributes
Use the live checked property, form values and resulting route/state when verifying radios. Do not treat an unchanged HTML `checked` attribute on an unsent draft as proof that selection failed.

**Context:** Search updates its server state on submit, while the other picker consumers use change events. A test initially confused these behaviors.
**Source:** [Reconciliation report](UI-WORKTREE-RECONCILIATION.md), “Runtime preservation and verification”; [browser regression](../../examples/scrypath_ecommerce/e2e/ui_reconciliation.spec.ts).

### Functional passes and old review scores do not establish current design quality
Review current screenshots, copy, task flow and states against the maintained role/job model. Keep unknown coverage and broader findings visible; do not promote disputed UI into a golden baseline.

**Context:** The first whole-app pilot found hierarchy, terminology and palette issues beyond the maintainer's examples. Captures can be mechanically clean while the experience remains unfinished.
**Source:** [Feedback ledger](../UI-FEEDBACK.md), AUTO-01/02, UI-07/08 and CONTENT-03; [review loop](../../examples/scrypath_ecommerce/e2e/UI-REVIEW.md).

### Preserve original evidence when making corrections
Keep captures bound to the source they observed. If files disappear or become stale, disclose the gap, preserve surviving material and make a new capture; never silently overwrite its source identity.

**Context:** The missing confirmation matrix was disclosed. Historical pilot files were copied unchanged, surviving contact sheets were kept separately, and a fresh matrix remained pending design review.
**Source:** [Reconciliation report](UI-WORKTREE-RECONCILIATION.md), final artifact check.

## Patterns

### Worktree handoff with explicit delta accounting
Record source/destination checkout and branch, current main ref, owned pending changes, transport method and destination disposition. Verify preserved originals. Update the preview pointer only when its actual runtime mount is established.

**When to use:** Before branch/worktree isolation, after a restart or compaction, and when a preview appears to regress.
**Source:** [Reconciliation report](UI-WORKTREE-RECONCILIATION.md), backup inventory and disposition table.

### Preview identity preflight before editing
Read `UI-PREVIEW.json`, refresh the known main ref, run `npm run ui:preflight` in the named demo checkout, and anchor subsequent commands to the printed checkout. Resolve mount, port, main or pending-work discrepancies before proceeding.

**When to use:** Before editing, restarting or collecting evidence for a retained preview. Preflight is read-only and launches no browser.
**Source:** [Review loop](../../examples/scrypath_ecommerce/e2e/UI-REVIEW.md); [review runner](../../examples/scrypath_ecommerce/e2e/ui-review.mjs).

### Test artifact ownership with real cleanup
Exercise the test runner's deletion boundary and compare review file hashes before and after an ordinary run. A directory naming convention alone does not prove preservation.

**When to use:** When screenshots, traces or review records must outlive disposable verification outputs.
**Source:** [PR #103](https://github.com/szTheory/scrypath/pull/103): 7 tooling tests and 324 files preserved byte-for-byte after Playwright cleanup.

### Fix shared causes in a bounded, whole-experience batch
Inspect the current inventory before narrowing to known feedback. Group defects by shared component or task cause, preserve behavior, repair coherently and confirm once. Carry remaining issues forward explicitly.

**When to use:** UI/content refinement where isolated cosmetic fixes risk inconsistent screens or repeated redesign.
**Source:** [Review loop](../../examples/scrypath_ecommerce/e2e/UI-REVIEW.md); [feedback ledger](../UI-FEEDBACK.md), UI-11 and AUTO-01.

## Surprises

### Playwright owned the directory that held the review evidence
An ordinary regression run removed captures under `test-results/` even though the capture command itself never deleted them.

**Impact:** Evidence storage moved outside that boundary; the regression now exercises cleanup directly.
**Source:** [PR #103](https://github.com/szTheory/scrypath/pull/103).

### Restarting the preview could reseed its data
The normal startup entrypoint seeded unconditionally before the retained-preview override was added.

**Impact:** Recreate only the intended web service with `compose.preview.yaml` and `DEMO_SEED_ON_START=0`; preserve volumes and verify relevant data when switching a populated preview.
**Source:** [Reconciliation report](UI-WORKTREE-RECONCILIATION.md), “Runtime preservation”; [preview override](../../examples/scrypath_ecommerce/compose.preview.yaml).

### Repository-only guidance crossed the Hex documentation boundary
The initial review guide placement and relative link failed the package allowlist and warning-free ExDoc build.

**Impact:** The guide lives beside the demo runner; packaged CONTRIBUTING links to its repository page. Keep optional-app tooling outside the core artifact unless intentionally changing that contract.
**Source:** [PR #102](https://github.com/szTheory/scrypath/pull/102); [reconciliation report](UI-WORKTREE-RECONCILIATION.md), CI repair.

## Keeping these lessons useful

The maintainer/agent making a workflow change updates the matching rule and its evidence here, then reruns the affected executable guard. New mount layouts, artifact locations, startup behavior or evidence rules must trigger that review. Keep incident history dated; update operational instructions in AGENTS.md and the review runbook together. Do not create competing copies of the role/job model or claim outside-adopter evidence from this maintainer incident.

These controls prevent known failure modes and expose mismatches; they do not guarantee every future design decision is good. Broader experience findings remain in the feedback ledger.
