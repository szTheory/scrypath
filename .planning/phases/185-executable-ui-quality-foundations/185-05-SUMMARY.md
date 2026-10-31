---
phase: 185-executable-ui-quality-foundations
plan: "05"
subsystem: ui
tags: [playwright, docker, provenance, image-comparison, accessibility]
requires:
  - phase: 185-02
    provides: ["pinned UI literal baseline and committed bootstrap history"]
provides:
  - "Source-pinned disposable UI capture, verification, teardown, and pixel/copy comparison"
  - "Frozen pre-change matrix for 72 host and 63 standalone operator observations"
affects: ["185-06", "185-07", "185-08", "185-09"]
actuals:
  tokens: 16234
  tasks: 2
  commits: 8
  plan_head_before: 7cc6035a6e277312b8f6237dade6d1972b87f4b9
  plan_head_after: 174adc54efdd349de275d4f4932649d6a9c76f7c
  review_continuation_commits: 17
tech-stack:
  added: []
  patterns:
    - "Separate retained-preview provenance from owner-labeled disposable Compose provenance"
    - "Bind each capture to committed source, image/container labels, browser, platform, and synthetic data identity"
    - "Keep automated image/copy comparisons pending for review"
key-files:
  created:
    - scripts/ci/ui_preservation.cjs
    - scripts/ci/ui_preservation.test.cjs
  modified:
    - examples/scrypath_ecommerce/e2e/ui-review.mjs
    - examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs
    - examples/scrypath_ecommerce/e2e/UI-REVIEW.md
key-decisions:
  - "Retained preview capture and preflight continue to require their existing source, mount, main, and loopback checks."
  - "Disposable captures use a unique, source-pinned full Compose stack with owned volumes, loopback ports, and label-scoped teardown."
  - "Capture manifests and comparisons remain pending review; completeness and pixel differences do not grant design approval."
  - "No CSS, controller, or template changes were made in this plan."
requirements-completed: []
coverage:
  - id: D1
    description: "Disposable capture orchestration independently verifies source and resource ownership, captures paired artifacts, and reports pixel/copy differences while preserving the guarded retained path."
    requirement: UIF-02
    verification:
      - kind: unit
        ref: "node --test scripts/ci/ui_preservation.test.cjs examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs"
        status: pass
      - kind: other
        ref: "node --check scripts/ci/ui_preservation.cjs; node --check examples/scrypath_ecommerce/e2e/ui-review.mjs; git diff --check"
        status: pass
    human_judgment: false
  - id: D2
    description: "A source-pinned 135-entry pre-change matrix contains viewport, full-page, hover, focus, copy, and verified compact-navigation evidence for host and standalone surfaces."
    requirement: UIF-03
    verification:
      - kind: e2e
        ref: "node scripts/ci/ui_preservation.cjs capture-before --session /private/tmp/scrypath-phase185-execution/ui-session.json"
        status: pass
      - kind: other
        ref: "artifactErrors(capture.json, capture_directory) returned no errors; all 135 captures and six open-drawer states are source/browser/platform/data-bound"
        status: pass
    human_judgment: true
    rationale: "The before images and copy were inspected, but rendered quality and any future before/candidate differences still require human review; this baseline is not design approval."
duration: 48min
original_execution_completed: 2026-10-31
status: review_fixes_partial
---

# Phase 185 Plan 05: Disposable UI Preservation Summary

## Corrective continuation — 2026-10-31

**Current status: partial; WR-02 remains blocked on repeatable rendered time/accessibility metadata.** The initial plan record below is historical. Parent review found that its 135-entry inventory did not prove matched visual/copy parity. Its original "unseeded" diagnosis was retracted after tracing startup to `e2e.prepare` and `demo.seed`; host incident copy is seeded fixture data and standalone Ops' empty schema state is configured behavior.

The review repairs now validate independent session and manifest authority, canonical matrix metadata, stable database/search identity, bounded source/build/artifact transport, and owner-scoped teardown. The candidate lifecycle preserves its existing database and search state. A follow-up Compose interpolation bug discovered during the required same-source run was fixed in `174adc54`.

The final run used source `174adc54efdd349de275d4f4932649d6a9c76f7c` (tree `c1a9896f9c94cb2b0ead7ccc702db7b6408f56bb`, fingerprint `ea7ebba3ba711eb24668c497190b6a32d2c0e22d6ec7aa7a85a55bfa1cced004`) and current remote `main` `c1be269ec202deed8602c74683c1b9ce5e42eaa9`. Before and candidate each contain 135 observations (72 host, 63 standalone), with 546 image/copy comparisons. Both manifests report the same Chromium `148.0.7778.0`, `linux-arm64`, and data digest `36a4a7761da621792cac129e01a215820023d9106c6a67d846abfad6d2f9487d`; the digest also remained unchanged after candidate startup and browser capture. This proves the preservation path retained the tested state.

The comparison remains pending. Fifty-four of 135 observation IDs have changed copy: the displayed server-side `Checked` time advances, and Axe targets include process-generated LiveView `data-phx-id` selectors. The viewport/full/hover/focus images report corresponding small changes (54 of 135 each, maximum differing-pixel ratio `0.0002401`); all six navigation images are identical. These changes are preserved without timestamp or image masking. The existing Playwright `page.clock` tests do not control server-side Elixir clock reads. See [185-05-REVIEW-FIX.md](185-05-REVIEW-FIX.md) for the exact test-only clock/selector proposal and evidence paths.

The corrected session was torn down after comparison: its containers, volumes, and network are absent. The retained preview still has its recorded container ID and remains healthy on its recorded loopback port. No CSS, controller, template, generator, product API, or runtime-flag changes were made. Subjective critique remains pending; no design approval or phase completion is claimed.

The corrective continuation spans 17 commits after `2f163d87`, including the review-scope note and code fixes; implementation changes end with `174adc54`. The source review's historical pre-fix RED evidence covers BL-03/BL-04, and the Compose interpolation regression has its own captured RED transcript. RED evidence is not available for every earlier repair, so the report does not claim that evidence requirement is complete.

## Original plan execution (historical, before parent review)

Parent review found blocking ownership/integrity/matrix/data-state/lifecycle gaps. The initial entry captures are historical observations, not accepted paired preservation evidence. They were archived unchanged; the owned old stack was verified and removed. The initial unseeded diagnosis was retracted: the existing full startup seeds incident data. This fresh corrective checkout owns tooling fixes and a qualified recapture. Read 185-05-REVIEW.md before relying on the earlier execution record below.

**Source-pinned disposable UI capture with 135 host and standalone observations, interaction evidence, and pending pixel/copy comparison**

## Performance

- **Duration:** 48 min, measured from the first task commit through the final baseline capture
- **Started:** 2026-10-31T15:32:35Z (first task commit)
- **Completed:** 2026-10-31T16:20:27Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added an owned disposable capture path with independent source/tree, image/container, project, port, volume, mount, route, browser, platform, and data-state checks. Retained preview guards remain on the default path.
- Captured 72 host and 63 standalone observations across three themes and widths, including viewport/full-page, hover/focus, visible copy, and six mobile navigation states. The final manifest has no missing artifacts, capture errors, or mechanical findings.
- Inspected the final light, dark, and system-dark contact sheets and copy across all host and standalone surfaces. The runbook documents the new path and keeps all review pending.
- Preserved the 45-entry UI literal baseline: the local full-source scan matched all 45 identities and occurrences, and the approved bootstrap commit is an ancestor of this plan branch.

## Original Frozen Before Evidence (historical; not the repaired comparison pair)

- **Source:** `b029e13130575c411280ff3376f042202515f560`
- **Tree fingerprint:** `eaef73f64e16bbff7413e4cdbc81cc7f1167ef710f67b3354c2eb424d7659ee0`
- **Main baseline:** local and remote `main` both resolved to `c1be269ec202deed8602c74683c1b9ce5e42eaa9`; the captured source includes that ref.
- **Browser/platform:** Chromium `148.0.7778.0`, `linux-arm64`
- **Synthetic database/search identity:** `054d265ab715e34cab47ce1d9a74a9154181bc4f3fc4500d4366ed43e330bd90`
- **Evidence manifest:** [capture.json](../../../examples/scrypath_ecommerce/ui-review-artifacts/phase185/before-b029e1313057-68f11bdc451747c7/capture.json)
- **Session:** `/private/tmp/scrypath-phase185-execution/ui-session.json` (`before-captured`)
- **Artifacts:** `examples/scrypath_ecommerce/ui-review-artifacts/phase185/before-b029e1313057-68f11bdc451747c7/`

The manifest contains 135 entries: 72 host and 63 standalone. Every entry has copy plus viewport, full-page, hover, and focus evidence; the six 390px Control Room captures also prove the navigation drawer opened with visible links. The session remains available for a later candidate capture. Its disposable stack is separate from the retained preview.

## Task Commits

1. **Task 1 RED:** `bebc01ca` — `test(185-05): reject retained resources in disposable provenance`
2. **Task 1 implementation:** `cc7885d4` — `feat(185-05): add source-pinned disposable UI capture`
3. **Task 2 matrix gate:** `cb1bc3e4` — `test(185-05): require complete frozen UI matrix`
4. **Task 2 Compose identity fix:** `54e7350b` — `fix(185-05): inspect services with full disposable Compose model`
5. **Task 2 Meilisearch digest fix:** `98ce59db` — `fix(185-05): hash paginated Meilisearch state`
6. **Task 2 capture interaction fix:** `6ac1d24d` — `fix(185-05): capture compact nav and modal interactions`
7. **Task 2 navigation state proof:** `a5ea026b` — `fix(185-05): verify compact navigation capture state`
8. **Task 2 mobile viewport scope:** `b029e131` — `fix(185-05): scope navigation proof to mobile width`

**Plan metadata:** committed with this summary.

## TDD Gate Compliance

- The retained-resource test failed on its intended assertion before implementation. `gsd-tools.cjs check tdd-red-evidence` returned `RED_EVIDENCE_OK`; the exact TAP output and evidence record are preserved at `examples/scrypath_ecommerce/ui-review-artifacts/phase185/185-05-red.tap` and `185-05-red-evidence.json`.
- The `test(185-05)` RED commit precedes the `feat(185-05)` GREEN commit. The final combined self-tests passed 19 tests; the focused preservation suite passed 11 tests.

## Files Created/Modified

- `scripts/ci/ui_preservation.cjs` — disposable stack lifecycle, provenance validation, artifact checks, and paired image/copy comparison.
- `scripts/ci/ui_preservation.test.cjs` — ownership, mismatch, matrix, interaction-state, teardown, and image-comparison tests.
- `examples/scrypath_ecommerce/e2e/ui-review.mjs` — explicit disposable adapter; it verifies compact drawer state and targets hover/focus within an open sheet.
- `examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs` — retained-path and pending-review regressions.
- `examples/scrypath_ecommerce/e2e/UI-REVIEW.md` — disposable capture instructions and pending review requirements.

## Observations for Downstream Review

- The host storefront’s captured entry state says “Results unavailable” and “Search unavailable” (for example, `host--storefront--light--390`).
- The standalone Ops surfaces show the configured empty state “No search schemas configured” (for example, `standalone--control-room--light--390`). Those captures preserve a configuration-empty state rather than the host fixture’s populated operator state.
- Host Ops shows the seeded sync-failure and retry states. These are synthetic observations. No browser errors or capture-time mechanical findings were recorded; that does not establish aesthetic acceptance or future parity.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Inspect services with the complete Compose graph**
- **Found during:** Task 2
- **Issue:** Container identity lookup omitted the base Compose files and could not resolve the owned services.
- **Fix:** Reused the full documented Compose graph for service inspection and teardown.
- **Files modified:** `scripts/ci/ui_preservation.cjs`
- **Verification:** The final source-pinned capture identified and validated the complete stack.
- **Committed in:** `54e7350b`

**2. [Rule 1 - Bug] Hash paginated Meilisearch state**
- **Found during:** Task 2
- **Issue:** The helper assumed index and document responses were arrays, while this Meilisearch version returns paginated `results` objects.
- **Fix:** Accept both response shapes, page through all documents, and hash the canonical document contents.
- **Files modified:** `scripts/ci/ui_preservation.cjs`, `scripts/ci/ui_preservation.test.cjs`
- **Verification:** Response-shape tests and the final data identity capture passed.
- **Committed in:** `98ce59db`

**3. [Rule 1 - Bug] Capture modal interactions and prove mobile navigation state**
- **Found during:** Task 2 visual inspection
- **Issue:** The navigation artifact key did not match the validator, an open saved-search sheet intercepted the underlying theme control, and the first mobile navigation screenshot did not prove that the drawer had opened. An initial state check also applied to desktop widths where that trigger is hidden.
- **Fix:** Align the `navigation.png` key, target a control inside an open sheet, wait for the drawer’s expanded/open state and visible links, and limit that check to 390px captures.
- **Files modified:** `examples/scrypath_ecommerce/e2e/ui-review.mjs`, `scripts/ci/ui_preservation.cjs`, `scripts/ci/ui_preservation.test.cjs`
- **Verification:** The final capture contains six verified mobile drawer states and passes artifact validation.
- **Committed in:** `6ac1d24d`, `a5ea026b`, `b029e131`

**Total deviations:** 3 auto-fixed (Rule 1 bugs). **Impact:** All fixes support the planned capture contract; no new dependencies or product UI changes were added.

## Issues Encountered

- The first Docker Buildx attempt could not write its user-level metadata in the sandbox. The approved elevated retry completed the build; no install or lockfile change was made.
- The canonical UI literal policy command attempted a remote Git fetch and failed because it could not write the worktree-specific `FETCH_HEAD`. This was not treated as passing evidence. A direct local scan matched the entire 45-entry baseline, and the approved bootstrap commit ancestry check passed.
- Earlier disposable captures failed their new runtime checks. Their owned containers and volumes were cleaned up, and their artifacts were preserved. Only the final `b029e131` capture is the frozen baseline.

## User Setup Required

None. The capture used the installed Docker and browser tooling; no package or host installation was performed.

## Original Next Phase Readiness (historical; superseded by parent review)

At the end of the original plan execution, the frozen baseline was considered ready for a later committed candidate. Parent review superseded that conclusion because inventory completeness did not prove matched parity. This historical statement does not authorize downstream UI edits.

## Original Plan Self-Check (historical)

- All five declared source/runbook files exist.
- All eight task commits are ancestors of the plan branch head recorded above.
- The final capture manifest passed artifact validation with 135 entries and six open-drawer states.
- Plan verification commands passed; no `STATE.md`, `ROADMAP.md`, or `REQUIREMENTS.md` changes were made.

---
*Phase: 185-executable-ui-quality-foundations*
*Original execution recorded: 2026-10-31*
