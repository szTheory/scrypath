# Phase 136 Dual Verify Report

**Requirement:** DUALVERIFY-01
**Plans:** 136-01 through 136-03
**Evidence started:** 2026-06-28T22:39:59Z
**Last updated:** 2026-06-29T19:18:18Z
**Final status:** PASSED

DUALVERIFY-01 is verified with source-backed Mix, ScrypathOps, browser,
contrast, motion, shell, mounted smoke, screenshot evidence, and approved
Human UAT. Phase 136 closeout artifacts now agree that no D-18 must-fix blocker
remains.

## Source-Backed Lane

| Field | Value |
| --- | --- |
| Source commit | `0494d92385c242da2fbb2c0bb0abd8775456639c` |
| Starting git status | Dirty working tree with pre-existing UI/demo changes; see `Starting Dirty Tree Transcript` below. |
| PLAYWRIGHT_BASE_URL | `http://127.0.0.1:4012` |
| Boot method | Host Phoenix dev server from current checkout: `MIX_ENV=dev PHX_SERVER=true PORT=4012 PGHOST=localhost PGPORT=5432 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix phx.server` |
| Port | `4012` |
| Seed method | `MIX_ENV=dev PORT=4012 PGHOST=localhost PGPORT=5432 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix do ecto.create, ecto.migrate, scrypath.demo.seed, phx.server`; seed completed before the first server process was aborted for failing to expose HTTP. |
| Asset build command | `cd scrypath_ops && mix assets.build` |
| Stale-server safeguard | Existing `http://127.0.0.1:4002` container was not used for proof. A separate host process from this checkout serves `http://127.0.0.1:4012`, after rebuilding ScrypathOps assets and seeding the demo. |

## Task 1 Automated Gate Results

| Gate | Command | Result |
| --- | --- | --- |
| ScrypathOps asset build | `cd scrypath_ops && mix assets.build` | PASS: compiled ScrypathOps app, Tailwind 4.1.12, daisyUI 5.0.35, esbuild output `../priv/static/assets/js/app.js 307.3kb`. |
| Ecommerce Meilisearch lane | `cd examples/scrypath_ecommerce && make infra` | PASS: Meilisearch exposed at `http://127.0.0.1:7700`; `/health` returned `{"status":"available"}`. |
| Source-backed ecommerce server | `MIX_ENV=dev PHX_SERVER=true PORT=4012 ... mix phx.server` | PASS: `curl http://127.0.0.1:4012/` returned the Scrypath Ecommerce demo page. |
| Root ops UI gate | `mix verify.opsui` | PASS: 2 doctests, 147 tests, 0 failures. |
| App ops UI gate | `cd scrypath_ops && mix verify.opsui` | PASS: 2 doctests, 147 tests, 0 failures. |
| App precommit gate | `cd scrypath_ops && mix precommit` | PASS: 2 doctests, 147 tests, 0 failures. |

## Task 1 Notes

- No package install or upgrade was performed.
- No lockfile changes were introduced.
- `mix precommit` produced formatter-only diffs in two files that were clean at task start: `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` and `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`. Those command side effects were restored by explicit path before any commit.
- Generated ScrypathOps static outputs remain untracked/generated evidence and are not staged.

## Browser Gate Results

Task 2 ran the contrast, depth, motion, shell, and operator gates against the
source-backed server at `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012`.

| Gate | Command | Result |
| --- | --- | --- |
| Static token contrast | `CONTRAST_REPORT_DIR=test-results/contrast/phase136-review-fix2-token make contrast` | PASS: AA failures: 0; AAA advisory: 35. |
| Browser axe contrast | `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012 CONTRAST_REPORT_DIR=test-results/contrast/phase136-review-fix2 npm run test:e2e:admin-contrast -- --reporter=line` | PASS: 3/3 scenarios. Incident AA 0 / AAA advisory 24; all_green AA 0 / AAA advisory 48; empty AA 0 / AAA advisory 12. Covers light, dark, and system-dark. |
| Surface depth | `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012 npm run test:e2e:admin-depth -- --reporter=line` | PASS: 33/33 tests. |
| Path motion | `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012 npm run test:e2e:path-motion -- --reporter=line` | PASS: 7/7 tests, including reduced-motion and active Playbook glow end-state. |
| Shell chrome | `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012 npm run test:e2e:admin-shell -- --reporter=line` | PASS: 33/33 tests across light, dark, and system-dark mobile/desktop shell states. |
| Operator smoke | `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012 npm run test:e2e -- e2e/operator.spec.ts --reporter=line` | PASS: 2/2 tests. |
| Contrast suppression guard | `for term in "exclude\\(" "disableRules" "color-contrast.*disabled"; do rg -n -- "$term" e2e/admin_contrast_matrix.spec.ts && exit 1; done` | PASS: no forbidden axe contrast suppression patterns. |

Task 2 assertions covered:

- AA failures: 0 for both static token contrast and browser axe contrast.
- AAA advisory counts are recorded as advisory-only evidence, not gate failures.
- `system-dark` is represented in browser contrast, shell chrome, and motion proof.
- `reduced-motion` is covered by `admin_path_motion.spec.ts`.
- `admin_surface_depth`, `admin_path_motion`, `admin_shell_chrome`, and `operator.spec.ts`
  all ran against the Phase 136 source-backed server.
- Execute-post code review is clean in `136-REVIEW.md` after the post-review fixes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Proof Coverage] Added missing muted-token rows**
- **Found during:** Task 2 static token contrast.
- **Issue:** The D-15 contrast lockstep guard could not verify current muted text consumers
  because several selectors in `app.css` had no manifest entries.
- **Fix:** Added manifest rows for current sidebar, timestamp, schema option, nav, and
  posture signal muted text consumers.
- **Files modified:** `scrypath_ops/assets/css/contrast-pairs.mjs`
- **Verification:** `CONTRAST_REPORT_DIR=test-results/contrast/phase136-token make contrast`
  passed with AA failures: 0 and AAA advisory: 27.

**2. [Rule 1 - Proof Selector Drift] Updated posture depth proof to current UI**
- **Found during:** Task 2 surface depth run.
- **Issue:** The depth spec still targeted the removed posture table selector while the
  current posture UI renders signal cards.
- **Fix:** Replaced the stale posture table assertion with signal-card, signal-group, and
  metric assertions; extended the OKLCH parser to handle `none` hue values emitted by the
  browser for neutral colors.
- **Files modified:** `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts`
- **Verification:** `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012 npm run test:e2e:admin-depth -- --reporter=line`
  passed with 33/33 tests.

**3. [Rule 1 - Flaky Proof Timing] Waited for active Playbook glow end-state**
- **Found during:** Task 2 path-motion run.
- **Issue:** The dark Playbook active-row assertion sampled `box-shadow` immediately after
  the active class appeared, before the CSS transition settled to the violet glow end-state.
- **Fix:** Added a polling helper so the test proves the computed end-state instead of a
  single transition frame.
- **Files modified:** `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts`
- **Verification:** `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012 npm run test:e2e:path-motion -- --reporter=line`
  passed with 7/7 tests.

**4. [D-18 Code Review Blocker] Corrected muted small-text contrast thresholds**
- **Found during:** Execute-post code review.
- **Issue:** Several small uppercase muted labels were classified as WCAG large text in
  `contrast-pairs.mjs`, letting the static gate apply the relaxed 3.0 AA threshold.
- **Fix:** Classified `.ops-nav-group__label`, `.ops-signal-group__title`,
  `.ops-signal-metrics dt`, and `.ops-handoff__eyebrow` as normal text; raised or reused
  the 64% muted text treatment in the current source lane.
- **Files modified:** `scrypath_ops/assets/css/contrast-pairs.mjs`,
  `scrypath_ops/assets/css/app.css`.
- **Verification:** `CONTRAST_REPORT_DIR=test-results/contrast/phase136-review-fix2-token make contrast`
  passed with AA failures: 0 and AAA advisory: 35; browser contrast rerun passed 3/3 with
  AA failures: 0.

**5. [D-18 Code Review Warning] Tightened merge-trace line-draw proof**
- **Found during:** Execute-post code review.
- **Issue:** The hover line-draw assertion only checked that the computed transform was not
  `none`, which could pass at the resting `scaleX(0)` matrix state.
- **Fix:** Added a numeric pseudo-element scale probe and asserted `scaleX(0)` before hover
  and `scaleX(1)` after hover.
- **Files modified:** `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts`.
- **Verification:** `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012 npm run test:e2e:path-motion -- --reporter=line`
  passed with 7/7 tests.

## Screenshot Matrix

Task 3 recaptured the historical 40-shot light/dark admin screenshot matrix against the
same source-backed server.

| Gate | Command | Result |
| --- | --- | --- |
| Screenshot matrix | `ADMIN_SCREENSHOT_DIR=test-results/admin-screenshots/phase136 PLAYWRIGHT_BASE_URL=http://127.0.0.1:4012 npm run test:e2e:admin-matrix -- --reporter=line` | PASS: 3/3 scenario tests; 40 PNGs generated. |
| Screenshot count | `find test-results/admin-screenshots/phase136 -type f -name '*.png' \| wc -l` | PASS: 40. |
| Screenshot checksums | `find test-results/admin-screenshots/phase136 -type f -name '*.png' \| sort \| xargs shasum -a 256` | PASS: checksums recorded in `136-ARTIFACT-MANIFEST.json`. |

Verification initially found the generated screenshot artifact root empty after later browser
runs cleaned `test-results`. The 40-shot matrix was recaptured on 2026-06-29 against
`http://127.0.0.1:4012`, and the manifest checksums now match the restored files.

The matrix preserves the historical 10 screen/state lanes across light and dark desktop/mobile:
control room incident, posture incident, failed sync populated, sync drift, control room
all-green, posture all-green, search results, failed sync empty, search zero-results, and
playbooks empty workspace. This is broader visual capture evidence for Phase 136 and does
not replace the Task 2 focused browser gates for contrast, depth, shell chrome, reduced-motion,
or operator workflows.

## Human UAT

Phase 136 Plan 03 created the bounded UAT checklist and paused for human review. The
reviewer response was `approved`.

| Field | Result |
| --- | --- |
| UAT artifact | `.planning/phases/136-milestone-verification-uat-s-g/136-UAT.md` |
| Reviewer response | `approved` |
| Status | PASS |
| Required surfaces | PASS: Control Room, Posture, Failed Sync, Sync/Drift, Search, Playbooks |
| Theme sequence | PASS: dark first, light parity, system-dark evidence |
| D-18 must-fix blockers | 0 |
| D-19 accepted follow-ups from UAT | 0 |
| Blocked status | No pending blocker |

## Final Defect And Follow-Up Decisions

- No D-18 must-fix blocker was reported during Human UAT.
- Execute-post code review found contrast-gate and test-proof defects after UAT approval.
  Those were fixed in the smallest scoped files and rerun with `make contrast`, browser
  contrast, path-motion, and `mix verify.opsui`.
- No new accepted follow-up was created by UAT. The existing D-19 categories in
  `136-MILESTONE-AUDIT.md` remain nonblocking release-policy or supplemental-evidence
  options, not hidden closeout defects.

## Artifact Hygiene

Generated-artifact hygiene: generated PNGs, traces, `.tmp` content, raw browser JSON, and
built `scrypath_ops/priv/static/**` outputs stayed out of git staging. Phase 136 committed
or will commit only source/report metadata:

- `.planning/phases/136-milestone-verification-uat-s-g/136-DUALVERIFY-REPORT.md`
- `.planning/phases/136-milestone-verification-uat-s-g/136-ARTIFACT-MANIFEST.json`
- `.planning/phases/136-milestone-verification-uat-s-g/136-BEFORE-AFTER.md`
- `.planning/phases/136-milestone-verification-uat-s-g/136-MILESTONE-AUDIT.md`
- `.planning/phases/136-milestone-verification-uat-s-g/136-UAT.md`
- `scrypath_ops/assets/css/contrast-pairs.mjs`
- `scrypath_ops/assets/css/app.css`
- `examples/scrypath_ecommerce/e2e/admin_surface_depth.spec.ts`
- `examples/scrypath_ecommerce/e2e/admin_path_motion.spec.ts`
- `.planning/phases/136-milestone-verification-uat-s-g/136-REVIEW.md`

## Starting Dirty Tree Transcript

The working tree was dirty before Task 1. Phase 136 commits must not stage these unrelated
source/demo changes unless a D-18 must-fix defect is identified and documented.

```text
 M .planning/STATE.md
 M examples/scrypath_ecommerce/.env.example
 M examples/scrypath_ecommerce/Makefile
 M examples/scrypath_ecommerce/README.md
 M examples/scrypath_ecommerce/assets/js/app.js
 M examples/scrypath_ecommerce/compose.dev.yaml
 M examples/scrypath_ecommerce/compose.yaml
 M examples/scrypath_ecommerce/docker-entrypoint.sh
 M examples/scrypath_ecommerce/e2e/admin_screenshot_matrix.spec.ts
 M examples/scrypath_ecommerce/e2e/admin_screenshots.spec.ts
 M examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts
 M examples/scrypath_ecommerce/e2e/helpers/theme-grid.ts
 M examples/scrypath_ecommerce/e2e/operator.spec.ts
 M examples/scrypath_ecommerce/test/scrypath_ecommerce_web/controllers/page_controller_test.exs
 M scrypath_ops/assets/css/app.css
 M scrypath_ops/assets/js/app.js
 M scrypath_ops/docs/operator-ia.md
 M scrypath_ops/lib/scrypath_ops/posture.ex
 M scrypath_ops/lib/scrypath_ops_web/components/layouts.ex
 M scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
 M scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex
 M scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex
 M scrypath_ops/lib/scrypath_ops_web/live/on_mount.ex
 M scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex
 M scrypath_ops/test/scrypath_ops_web/live/control_room_live_test.exs
 M scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs
 M scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
?? .planning/research/.cache/
?? .tmp/
?? docs/local-demo-docker-dx.md
?? examples/scrypath_ecommerce/.tmp/
?? examples/scrypath_ecommerce/compose.host-ports.yaml
?? examples/scrypath_ecommerce/e2e/p124_after.spec.ts
?? scrypath_ops/priv/static/assets/
?? scrypath_ops/priv/static/favicon-91f37b602a111216f1eef3aa337ad763.ico
?? scrypath_ops/priv/static/images/logo-353b3ad0b84cf978826c53e7a3ea537f.svg
?? scrypath_ops/priv/static/images/logo-353b3ad0b84cf978826c53e7a3ea537f.svg.gz
?? scrypath_ops/priv/static/images/logo.svg.gz
?? scrypath_ops/priv/static/robots-9e2c81b0855bbff2baa8371bc4a78186.txt
?? scrypath_ops/priv/static/robots-9e2c81b0855bbff2baa8371bc4a78186.txt.gz
?? scrypath_ops/priv/static/robots.txt.gz
?? test_e2e_plan.md
?? update_plans.py
?? update_plans2.py
```
