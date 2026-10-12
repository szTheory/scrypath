---
phase: 177-shared-patterns-and-delivery-proof
plan: 02
subsystem: operator-ui
tags: [phoenix-live-view, css-tokens, accessibility, contrast, visual-regression]
requires: []
provides:
  - Cascade-safe shared muted-text and neutral-link contrast rules for the operator shell.
  - Updated token catalog and contract coverage for the shared rules.
  - Source-bound before/after contrast evidence across three surfaces, three themes, and three viewport widths.
affects: [phase-177-plan-03, phase-177-plan-04, phase-177-plan-05]
actuals:
  tokens: 6818
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns:
    - Place shared role overrides after Tailwind layers when generated utilities otherwise win the cascade.
    - Keep neutral operator links on the base-content token while retaining explicit primary link roles.
key-files:
  created: []
  modified:
    - scrypath_ops/assets/css/app.css
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
    - scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs
    - .planning/phases/177-shared-patterns-and-delivery-proof/177-UI-AUDIT.md
requirements-completed: [OPUX-26, OPUX-27]
coverage:
  - id: P177-02-A
    description: Shared muted text and neutral operator-guide links meet their intended contrast roles without changing task-specific hierarchy or primary link treatment.
    requirement: OPUX-26
    verification:
      - kind: unit
        ref: "test/scrypath_ops_web/design_tokens_contract_test.exs — 9 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "mix precommit — 2 doctests, 302 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: P177-02-B
    description: Corrected contrast is retained and verified across Control Room, Search health, and Sync and drift, including supported themes and viewport widths.
    requirement: OPUX-27
    verification:
      - kind: automated_ui
        ref: "177-UI-AUDIT.md — 27 direct before/after pairs across three slices; 90-image matrix retained and inspected"
        status: pass
      - kind: automated_ui
        ref: "make contrast and rendered axe contrast matrix — 0 AA failures"
        status: pass
    human_judgment: false
completed: 2026-10-12
status: complete
---

# Phase 177 Plan 02: Shared contrast roles follow the correct CSS cascade

**Shared muted labels and neutral operator links now render with accessible contrast in the existing shell, backed by contract, full test, and matched visual evidence.**

## Accomplishments

- Fixed the muted-text cascade so Tailwind opacity utilities no longer override the shared shell’s intended token color. The failing Light rendering improved from `4.19:1` to the intended accessible token treatment.
- Removed inherited 55% opacity from neutral operator links, including Control Room’s “Read the operator guide”; explicit primary links keep their existing role.
- Updated the token catalog and added a focused contract assertion for cascade placement and primary-role exclusions.
- Recorded and inspected 27 matched image pairs across Control Room, Search health, and Sync and drift, with the full 90-image before/after matrix preserved. Corrected the audit’s dark-theme image targets and validated all 212 local Markdown links.

## Task Commits

- **Task 1: Correct an audited shared-component or token mismatch** — `6f227c0` (`fix(177-02): correct shared text contrast`).
- **Task 2: Verify the shared roles across existing admin paths** — automated checks and visual evidence recorded in the plan metadata commit.

The audit and summary are committed together after the product change; the source change remains independently reviewable.

## Files Created/Modified

- `scrypath_ops/assets/css/app.css` — moved the two shared muted-role rules after Tailwind layers and gave neutral shell links an explicit base-content color.
- `scrypath_ops/assets/css/DESIGN-TOKENS.md` — documented the implemented shared roles.
- `scrypath_ops/test/scrypath_ops_web/design_tokens_contract_test.exs` — protects the cascade placement and role exclusions.
- `.planning/phases/177-shared-patterns-and-delivery-proof/177-UI-AUDIT.md` — records diagnosis, source identity, before/after paths, verification, and cleanup.

## Decisions Made

- Correct the shared CSS seam instead of adding markup or a new component; the mismatch came from Tailwind layer order, while the existing OpsUi structure and task semantics were already appropriate.
- Keep neutral and primary links distinct through their existing role selectors rather than changing every link or adding a dependency.
- Treat direct images, executable contrast results, and behavior tests as separate evidence; do not infer a visual pass from a test result alone.

## Deviations from Plan

- Plan 177-02 permitted either a scoped correction or a no-change audit. The render audit established two concrete shared contrast defects, so the CSS/catalog/contract correction was necessary and remained within the planned files.
- The rendered axe matrix completed one full 3/3 run with zero AA failures. Repeated runs were intermittent in native Chromium at the original 180-second timeout, stalling in axe `runPartial` or final empty-state navigation; no timeout change was retained. The final three scenario reports all show zero AA failures.

**Total deviations:** 1 scope outcome (audited correction instead of no-source-change).
**Impact on plan:** No new routes, dependencies, markup, page ordering, action semantics, or abstractions were introduced.

## Verification

- Focused token contract — 9 tests, 0 failures.
- `mix precommit` — 2 doctests, 302 tests, 0 failures.
- `mix assets.build` — passed.
- `make contrast` — 0 AA failures; 43 AAA findings remain advisory.
- Admin screenshot matrix — 3 scenario groups and 90 after images across Light, Dark, and unoverridden System-dark at 390, 768, and 1440 pixels.
- Admin surface-depth suite — 38 tests, 0 failures; 60 supplementary images.
- Rendered axe contrast matrix — one complete 3-scenario run, 0 AA failures; all three retained reports show 0 AA findings.
- Audit link validation — 212 local links checked, 0 missing.

## Issues Encountered

Native Chromium contrast reruns were intermittent under the repository’s existing timeout. A full run passed with unchanged assertions, so the timeout was not changed and no product workaround was added. The task-owned Compose project was stopped without deleting its retained volume; the preview at port 4012 was not contacted.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan 177-02 is complete. The shared contrast roles are in place; continue with Plan 177-03, which checks whether the four operational LiveViews preserve their approved hierarchy, identity, and truthful states. It may leave production code unchanged when the audit and existing tests show no drift.

---
*Phase: 177-shared-patterns-and-delivery-proof*
*Completed: 2026-10-12*
