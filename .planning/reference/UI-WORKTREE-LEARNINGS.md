---
project: Scrypath
scope: UI recovery and preview continuity follow-ups
phase: null
generated: "2026-10-14"
counts:
  decisions: 3
  lessons: 8
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

### Stateful verification needs a fresh owned search history
Use a disposable backend per full mutation run. Re-seeding catalog records does not erase Meilisearch task history. Repeated suites can legitimately exceed the bounded history window and block promotion; reset only the owned test service rather than raising limits, fabricating evidence or weakening the guard.

**Context:** During baseline verification, accumulated test history exceeded the 1000-task bound. The guard correctly refused promotion; a fresh owned search service supported the full 168-case inventory, with the separate transition-timing recheck recorded in the results. Retained preview data stayed untouched.
**Source:** [Baseline results](UI-BASELINE-RESULTS.md), evidence receipts.

### Verify diagnostic setup before another owned build
Two Phase 185 diagnostic attempts stopped before any browser capture: a copied expected hash omitted characters, and host/browser code both created the same directory through a shared artifact mount. These were setup failures, not behavioral RED evidence or product failures. Derive hashes from committed bytes, syntax-check the generated overlay and serialized runner, and simulate the shared-directory creation/copy protocol locally with one creator before launching the next owned stack. Keep every failed attempt and its actual status. If diagnostic machinery keeps adding failures, return to the maintained runner rather than extending the wrapper indefinitely.

**Context:** The corrected driver verified both Git/worktree bytes and generated code, then used a temporary shared-path simulation to establish browser-only directory creation and hash-checked host transport. No cache, concurrency, dependency or resource-limit change supplied this improvement. Required verification and bounded retests remain included in the approved phase; an elapsed runtime is not another approval boundary.
**Source:** [Phase 185 continuity](../milestones/v1.45-phases/185-executable-ui-quality-foundations/.continue-here.md); external `font-session-diagnostic-e25fac89-2226/driver-record.json`, `font-session-diagnostic-e25fac89-r2-20261031T2235/driver-record.json`, and `font-session-diagnostic-e25fac89-r3-265a7ad66ecc/mount-protocol-simulation/simulation-record.json` under `/private/tmp/scrypath-phase185-execution/`. The current workaround still requires actual runtime proof; this lesson establishes setup efficiency only.

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

### Inspection derivatives do not belong inside strict raw capture directories
Phase185 qualification correctly rejected unmatched review JSON and contact sheets placed alongside raw screenshots. Keep immutable captures and their exact manifest directory untouched; write observation records and derivatives in a sibling under the ignored evidence root. If placement must be repaired, move only task-added review files byte-identically, preserve original observer records, and record explicit original/new paths and hashes in a transport manifest. Do not loosen the raw-directory validator or recapture solely to repair review bookkeeping.

**When to use:** Disposable source-paired captures and their factual inspection records.
**Source:** [Phase185 qualified baseline](../milestones/v1.45-phases/185-executable-ui-quality-foundations/185-05-SUMMARY.md), evidence placement correction and pinned transport record.

## Keeping these lessons useful

The maintainer/agent making a workflow change updates the matching rule and its evidence here, then reruns the affected executable guard. New mount layouts, artifact locations, startup behavior or evidence rules must trigger that review. Keep incident history dated; update operational instructions in AGENTS.md and the review runbook together. Do not create competing copies of the role/job model or claim outside-adopter evidence from this maintainer incident.

These controls prevent known failure modes and expose mismatches; they do not guarantee every future design decision is good. Broader experience findings remain in the feedback ledger.

### Isolate image probes from Compose lifecycle labels

A container created with `docker run` inherits labels from its image. A read-only, network-isolated probe of a Compose-built image can therefore inherit a live verification project's labels. During Phase185 r9, Compose's `--abort-on-container-exit` observed the probe exit and stopped the actual browser, leaving an incomplete failed receipt despite the probe itself succeeding.

Give auxiliary probes a distinct explicit Compose project/service and one-off label, and run runtime fingerprint probes after canonical stacks have finished cleanup. Use immutable image IDs. Never launch a probe with a live stack's inherited labels. Preserve the interrupted invocation and diagnose it before the bounded retry; read-only filesystem/network isolation does not establish lifecycle isolation.

Evidence: `/private/tmp/scrypath-phase185-execution/heldout-before-r9-diagnosis.json`, original run log and `before-r9-runtime-precheck.json`. No retained data or source was changed, and the original failure was not recast as a pass.

### Read the supervisor outcome before reporting a buffered verifier

The canonical Mix capability may buffer its child command output until it returns. Empty host stdout and no running Compose containers do not establish that an image build is still running: the invocation may have already completed and cleaned up. Poll the owned supervisor/session or read its exclusive result record first, then inspect only its recorded project for stage detail. Report a browser/build outcome only from that current evidence. Phase185r11 exposed this reporting lag; its failed reset and clean teardown remain preserved.

### Replay real producer inputs before repeating a long collector run

When a browser run succeeds but its collector fails on a metadata-shape mismatch, preserve the original failed receipt and first reproduce the consumer against an isolated, hash-pinned copy of the actual raw inputs. Synthetic unit fixtures must model the real producer's nesting and required fields. During Phase185r13, the interaction target existed inside captured state; a synthetic top-level duplicate hid the consumer mismatch. The corrected real-input replay validated all61cases/213observations/426images before the fresh canonical r14 run.

A replay is diagnostic only: it cannot replace the original failed command, rewrite that receipt or supply canonical acceptance. It can expose another consumer error before another full browser invocation. Keep the current immutable source and explicit unchanged-input reconciliation, then obtain the required fresh canonical receipt within the existing budget.

Evidence: `r13-offline-collector-replay-r2-result.json`, `actual-target-shape-GREEN.log` and `accepted-before-r14.json` below `/private/tmp/scrypath-phase185-execution/`.

### Verify the actual invocation before hosted dispatch

Focused source tests can pass while the standard contributor command fails earlier on formatting, strict lint, workflow syntax or a default output path. For changes to verifiers or CI, run the canonical required core/repository commands and installed actionlint before dispatch, after all integration edits. Check the ordinary invocation as well as explicit external-artifact wrappers. Test doubles must clear ambient artifact-path configuration unless a case intentionally supplies it.

**Evidence:** Phase185's first hosted candidate exposed an ordinary-default containment conflict, token lint/type findings and missing prebuild clock transport. A later job-level runner context was rejected before dispatch; exporting the path through the existing runner initialization step fixed it. Narrow negative tests now retain explicit/before-only containment. Strict lint, full focused token tests, type analysis, canonical core and repository checks, formatting and actionlint passed on the repaired source. Runtime length alone did not require renewed permission, and prior failed results were preserved.

**Consequence:** Keep existing lean CI and dependencies. Use checks already available locally to find invocation errors before spending a hosted run; refresh source-bound runtime evidence when a harness input actually changes, and reuse actual image inspection only through complete byte/state identity.

### Verify CI identity across shell-step boundaries before rebuilding

A local `export` ends with its workflow step. When a prebuild and later handoff/runtime must resolve the same strict Compose source identity, publish the source SHA, product tree and fixture overlay through the existing environment file as well as exporting them locally. Reproduce the actual Compose model in separate step environments before another full build; matching one shell is insufficient. Keep identity fields strict rather than normalizing them away.

**Context:** Phase185 prebuild computed the right three values but the next handoff step lost them and correctly failed. The read-only model reproduction established exactly three missing fields and identical model/recipe digests after environment-file transport. No build, browser, package or resource-limit change was needed for that diagnosis. Evidence: external `ci-step-env-model-reproduction.json` under `/private/tmp/scrypath-phase185-execution/`.

### Diagnose full-lane elapsed time before changing the pipeline

Separate startup cost from actual per-test durations before choosing a timing remedy. In Phase185, startup was only a few seconds while accessibility scans dominated the timeout; moving startup alone would not solve it. Compare affected real scenarios and reversed order, preserve every rule/scope/result group and frame fallback, then run one bounded current-source canonical successor. A prototype or scoped speedup does not itself establish full-lane acceptance.

### Separate measured runtime fields from build identity, and inspect every caller

A prebuild model cannot equal its post-inspection model when newly measured image/layer/runtime fields are treated as build configuration. Normalize only the named browser metadata values, then verify supplied values independently against actual images/runtime. Keep source, fixture, data, profile, graph, recipe and cache values strict. Review every shared-helper caller first: the global capture runner legitimately requests image-only verification without the optional browser fields. A focused real-helper positive plus missing/forged-field negatives protects both contracts. Supersede an attributable stale dispatch through the existing workflow concurrency policy rather than letting obsolete verification consume its whole lane.
