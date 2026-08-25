---
phase: 132-a11y-contrast-remediation-both-themes-hard-gate-g
plan: 02
subsystem: ui
tags: [accessibility, wcag-aa, contrast, playwright, axe, scrypath-ops]

requires:
  - phase: 132-01
    provides: Named muted AA token, scoped primary-strong token, checker support, and token docs
provides:
  - Rebuilt static-asset proof before contrast evidence
  - Zero-AA static token contrast evidence
  - Zero-AA Playwright axe evidence for light, dark, and system-dark
  - AAA body/long-form advisory evidence as report-only
  - Light baseline recapture evidence for the intentional Phase 132 light-token change
affects: [phase-132, phase-136-dualverify, admin-contrast-gate, scrypath_ops]

tech-stack:
  added: []
  patterns:
    - Rebuild source CSS before static/browser proof so generated assets are not stale
    - Treat AAA body contrast as advisory while AA remains the hard gate
    - Keep generated Playwright reports, screenshots, and built static outputs out of git

key-files:
  created:
    - .planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTRAST-REPORT.md
    - .planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-02-SUMMARY.md
  modified:
    - .planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTRAST-REPORT.md

key-decisions:
  - "AA failures are zero for light, dark, and system-dark; AA is the hard closeout gate."
  - "AAA body/long-form findings remain advisory/report-only and do not affect exit status."
  - "The expected light-token visual change is handled by recapturing the local light baseline."
  - "Generated `test-results/`, `.tmp/`, and untracked `scrypath_ops/priv/static/**` artifacts are evidence-only and not committed."

patterns-established:
  - "Phase contrast reports should include the exact asset-build command before proof output when built CSS is part of the evidence chain."
  - "Browser contrast evidence should name explicit light, explicit dark, and system-dark outcomes separately."

requirements-completed: [A11Y-TOKEN-01]

duration: ~10min
completed: 2026-06-04
---

# Phase 132 Plan 02: Contrast Hard Gate Evidence Summary

**Rebuilt-asset contrast proof with zero AA failures across light, dark, and system-dark, plus AAA advisory and light-baseline recapture evidence**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-06-04T21:08:18Z
- **Completed:** 2026-06-04T21:14:20Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `132-CONTRAST-REPORT.md` with the required sections for static token proof, ops UI regression proof, browser AA matrix proof, AAA advisory status, light baseline recapture, and scope guard.
- Ran `mix assets.build` before proof commands, then verified `mix verify.opsui` and the fast token checker with `Contrast check: PASS`, `AA failures:  0`, and `AAA advisory: 19` after the post-review named-token guard fix added the two shell/header muted consumers.
- Prepared the ecommerce E2E environment, ran the Playwright axe matrix against `http://127.0.0.1:4002`, and recorded zero AA failures for light, dark, and system-dark.
- Recorded AAA body/long-form advisory status as report-only: browser reports had 12 advisory findings in the empty scenario, all non-blocking.
- Recaptured 20 light PNGs into the local baseline and verified `Light pixel-diff: PASS` with `Failed pairs: 0 / 20`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Run rebuilt static gates and start the evidence report** - `644f840` (`docs`)
2. **Task 2: Run browser AA matrix, attach AAA advisory, and refresh light baseline** - `8c91c7b` (`docs`)

## Files Created/Modified

- `.planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTRAST-REPORT.md` - Records exact command evidence for rebuilt assets, static/token contrast, ops UI tests, browser AA matrix, AAA advisory status, light baseline recapture, and scope guard.
- `.planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-02-SUMMARY.md` - Captures this plan closeout, commits, deviations, and self-check.

## Decisions Made

- Preserved D-04: AA is the hard gate; AAA body/long-form status is advisory/report-only.
- Treated `test-results/`, `.tmp/`, and untracked `scrypath_ops/priv/static/**` outputs as local evidence artifacts only.
- Used the existing ecommerce `make infra` target to satisfy the local Meilisearch prerequisite for browser proof, then stopped that container after proof completed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Started the local Meilisearch proof dependency**
- **Found during:** Task 2 (browser proof environment preparation)
- **Issue:** The first `MIX_ENV=test mix e2e.prepare` attempt failed with `{:transport_error, %Req.TransportError{reason: :econnrefused}}` while creating the Product index because Meilisearch was not running on `127.0.0.1:7700`.
- **Fix:** Ran the existing `examples/scrypath_ecommerce` `make infra` target, verified `/health` returned `{"status":"available"}`, reran `MIX_ENV=test mix e2e.prepare`, and stopped the Meilisearch container after proof.
- **Files modified:** None.
- **Verification:** `MIX_ENV=test mix e2e.prepare` exited 0 and prepared `ecommerce__product` and `ecommerce__variant`; the subsequent Playwright matrix exited 0.
- **Committed in:** `8c91c7b` (evidence recorded in the Task 2 report commit)

---

**Total deviations:** 1 auto-fixed (Rule 3 blocking environment prerequisite)
**Impact on plan:** The fix only started an existing local service required by the planned browser proof. No product code, package manifests, or proof thresholds changed.

## Issues Encountered

- `mix verify.opsui` and `MIX_ENV=test mix e2e.prepare` emitted transient Postgrex `too_many_connections` logs in the local environment, but both commands exited 0.
- Existing untracked generated/static files were present before execution. The plan kept staging scoped to planning evidence files and did not commit generated `test-results/`, `.tmp/`, or untracked `scrypath_ops/priv/static/**` outputs.

## Verification

- `cd scrypath_ops && mix assets.build` - exit 0.
- `cd scrypath_ops && mix verify.opsui` - `2 doctests, 129 tests, 0 failures`.
- `cd examples/scrypath_ecommerce && CONTRAST_REPORT_DIR=test-results/contrast/phase132-token node contrast-checker.mjs` - `Contrast check: PASS`, `AA failures:  0`, `AAA advisory: 19`.
- `cd examples/scrypath_ecommerce && MIX_ENV=test mix e2e.prepare` - exit 0 after starting local Meilisearch.
- `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 CONTRAST_REPORT_DIR=test-results/contrast/phase132 npm run test:e2e:admin-contrast` - `3 passed (1.2m)`.
- `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 ADMIN_SCREENSHOT_DIR=.tmp/pixel-diff-fresh npm run test:e2e:admin-matrix` - `3 passed (18.8s)`.
- `cd examples/scrypath_ecommerce && PIXEL_DIFF_FRESH_DIR=.tmp/pixel-diff-fresh node e2e/light-pixel-diff.mjs` - `Light pixel-diff: PASS`, `Failed pairs: 0 / 20`.
- `cd examples/scrypath_ecommerce && rg "exclude\(|disableRules|color-contrast.*disabled" e2e/admin_contrast_matrix.spec.ts` - no matches.
- `git diff --name-only -- scrypath_ops/lib examples/scrypath_ecommerce/package.json examples/scrypath_ecommerce/package-lock.json package.json package-lock.json` - empty.

## Known Stubs

None. Stub-pattern scan found no placeholders or UI-rendered empty/mock data introduced by this proof plan.

## Threat Flags

None. The plan introduced no new network endpoints, auth paths, file-access trust boundaries, or schema changes. Generated reports and screenshots contain local seeded demo evidence only.

## User Setup Required

None - no external service configuration required. The local Meilisearch proof dependency was started and stopped through the repository's existing ecommerce Makefile.

## Next Phase Readiness

Phase 132 is ready to close. Phase 136 can consume `132-CONTRAST-REPORT.md` for the dual-theme AA hard-gate evidence and AAA body advisory attachment.

## Self-Check: PASSED

- Files found: `132-CONTRAST-REPORT.md`, `132-02-SUMMARY.md`.
- Commits found: `644f840`, `8c91c7b`.
- Evidence found: `Contrast check: PASS`, `AA failures:  0`, `AA failures: 0 for light, dark, and system-dark`, `AAA advisory findings did not affect the Playwright exit status`, and `Failed pairs: 0 / 20`.

---
*Phase: 132-a11y-contrast-remediation-both-themes-hard-gate-g*
*Completed: 2026-06-04*
