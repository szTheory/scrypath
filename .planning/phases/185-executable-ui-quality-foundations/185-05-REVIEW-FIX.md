---
phase: 185-executable-ui-quality-foundations
plan: "05"
fixed_at: 2026-10-31T19:44:33Z
review_path: .planning/phases/185-executable-ui-quality-foundations/185-05-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 7
partial: 1
skipped: 0
status: partial
implementation_head: 174adc54efdd349de275d4f4932649d6a9c76f7c
---

# Phase 185 Plan 05 Review Fix Report

The six blocker findings and WR-01 are repaired. WR-02 is partially repaired: expected entry fixtures now have assertions, and a verified same-source before/candidate pair preserved its database/search state, but server-generated timestamps and LiveView accessibility selectors remain nondeterministic. Therefore the required repeatability gate is still blocked. This report does not claim parity, design approval, phase completion, or user risk acceptance.

## Findings addressed

### BL-01 — Independent session and teardown authority

**Status:** Fixed. The session is checked against a separate creation record, retained identity is reread, Docker resources and binds are checked against exact names/IDs, and teardown uses the authorized inventory. Follow-up fixes cover Docker Desktop host paths, the read-only Postgres bootstrap bind, legacy authority records, full Docker IDs, and the service inventory lookup.

**Commits:** `f1c0cbf2`, `0e30a606`, `885b24f1`, `bc4cec0a`, `d47b774b`, `0a61f61d`, `8b7b52d5`, `42e7c458`.

### BL-02 — Manifest integrity bound to independent source identity

**Status:** Fixed. Manifest bytes and their checksum/source/tree/environment are checked against independent session authority; Git reads use a clean authority environment and canonical origin.

**Commit:** `f1c0cbf2`.

### BL-03 — Canonical matrix metadata and artifact dimensions

**Status:** Fixed. IDs bind to route, surface, deployment, theme, width and viewport; PNG dimensions and per-entry environment/copy metadata are checked. A later route correction binds standalone Saved searches to `/ops/search?saved=manage`.

**Commits:** `793dcd86`, `9b92fe10`.

### BL-04 — Stable, complete database/search identity

**Status:** Fixed. PostgreSQL transport nonce lines are normalized only as a matched pair; Meilisearch settings and paginated documents are covered with bounded progress checks. Regressions prove equivalent unchanged dump content produces the same normalized identity and meaningful document/settings changes produce a different identity. The successful candidate run also proved the digest unchanged across app replacement and browser capture.

**Commit:** `a86de23e` (pagination support was added earlier in `98ce59db`).

### BL-05 — Candidate preserves state and cleans up on failure

**Status:** Fixed. Candidate services start without prepare, seed or migration entrypoints. The lifecycle checks data identity before and after replacement and tears down only independently owned resources after failure. A real run exposed a Compose interpolation error in the shell asset check; the `$asset` variable is now escaped so it reaches the container shell.

**Commits:** `f1c0cbf2`, `174adc54`.

### BL-06 — Bounded source and artifact transport

**Status:** Fixed. Git/process/build/browser calls have finite bounds and clean Git authority; Buildx metadata and new disposable evidence use the stable external session root. The build timeout reflects the measured locked build duration.

**Commits:** `17f719e0`, `cab4d076`, `8f076463`.

### WR-01 — Browser environment metadata

**Status:** Fixed. Session and captures record the browser platform/version rather than presenting the host platform as browser provenance, and manifest validation binds those fields.

**Commit:** `f1c0cbf2`.

## WR-02 — Entry fixtures pass; repeatability remains blocked

**Status:** Partial. The entry fixture checks distinguish the seeded host incident state from standalone Ops' configured empty-schema state. The final source-pinned run completed all 135 captures before and after with the same full source SHA (`174adc54efdd349de275d4f4932649d6a9c76f7c`), tree fingerprint, Chromium `148.0.7778.0`, `linux-arm64`, and database/search digest (`36a4a7761da621792cac129e01a215820023d9106c6a67d846abfad6d2f9487d`). The digest stayed identical after startup and browser capture.

The comparison contains 546 image/copy pairs. Copy differs in 54 of 135 unique observations. The raw copy shows changing server-rendered `Checked` timestamps and changing `data-phx-id` values in Axe target selectors. Viewport, full-page, hover and focus comparisons each show 54 changed images; the largest pixel ratio is `0.0002401`. All six navigation images are identical. The diff images and raw copy remain unmodified; no timestamp/data region was masked. The comparison stays `pending-review`.

Evidence:

- Before manifest: `/private/tmp/scrypath-phase185-execution/ui-review-artifacts/phase185/before-174adc54efdd-470bd0c7e251a1ff/capture.json`
- Candidate manifest: `/private/tmp/scrypath-phase185-execution/ui-review-artifacts/phase185/after-174adc54efdd-470bd0c7e251a1ff/capture.json`
- Comparison and diff images: `/private/tmp/scrypath-phase185-execution/ui-review-artifacts/phase185/comparison-470bd0c7e251a1ff/comparison.json`
- Session after teardown: `/private/tmp/scrypath-phase185-execution/ui-session.json` (`torn-down`)
- Earlier failed candidate session and transport record: `/private/tmp/scrypath-phase185-execution/ui-review-artifacts/phase185/failed-candidate-compose-interpolation-653f47819b867c27/`
- Regression RED transcript for the Compose interpolation failure: `/private/tmp/scrypath-phase185-execution/ui-review-artifacts/phase185/candidate-compose-interpolation-red.tap`

### Minimal follow-up proposal

The existing `page.clock.install()` seam in `examples/scrypath_ecommerce/e2e/phase173_copy.spec.ts` controls browser time only. The rendered `Checked` values come from server-side clock reads in `scrypath_ops/lib/scrypath_ops/posture.ex`, `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex`, `scrypath_ops/lib/scrypath_ops_web/live/control_room_live.ex`, `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex`, `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex`, `scrypath_ops/lib/scrypath_ops/document_observation.ex`, and the fallback in `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`. A browser clock cannot make those values repeatable.

For parent review, add internal `ScrypathOps.Clock.utc_now/0`, defaulting to UTC system time with a compile-time-only test instant configured in `scrypath_ops/config/test.exs`. Route the rendered checked-time producers above through that adapter. This is test-build configuration, not an environment flag or public API. Preserve unrelated operational event timestamps as real time.

The Axe copy also contains unstable LiveView-generated `data-phx-id` selectors. Keep all Axe findings and failure summaries; do not delete or mask targets. Add a stable DOM identity for the affected Ops navigation item in `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`, or use a stable role/name locator in the capture adapter at `examples/scrypath_ecommerce/e2e/ui-review.mjs`. Verify the selector still points to the reported node.

Add `scrypath_ops/test/scrypath_ops/clock_test.exs` and focused assertions in `scrypath_ops/test/scrypath_ops_web/live/posture_live_test.exs`, `failed_sync_live_test.exs`, and `sync_drift_live_test.exs`, plus a stable identity for the affected navigation item in `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`. Keep every Axe finding/failure summary and verify that the stable target still identifies the same node. Add a regression in `examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs`. Then run two captures of the same committed source and a same-source before/candidate pair on the locked browser image. Require all 135 copy files and visible timestamp pixels to match, all 546 comparison pairs to have no unexplained differences, source/browser/platform/data identities to match, and existing entry-fixture and Axe checks to remain active. Keep the review pending until this automated evidence passes. These production internals and the navigation template are outside this repair checkout's allowed edit scope; the parent owns any follow-up scope decision.

## Verification and evidence limits

- `node --test scripts/ci/ui_preservation.test.cjs examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs` — passed 38 tests.
- `node --check scripts/ci/ui_preservation.cjs`, `node --check scripts/ci/ui_preservation.test.cjs`, `node --check examples/scrypath_ecommerce/e2e/ui-review.mjs`, `node --check examples/scrypath_ecommerce/e2e/ui-review.selftest.mjs`, and `git diff --check` — passed.
- `docker compose config --format json` retained the escaped shell variable; the captured regression fails against the previous command and passes with the fix.
- The corrected source-pinned baseline, candidate, comparison, and teardown completed. The disposable project had no containers, volumes, or network after teardown. The retained preview container ID remained unchanged and healthy on its recorded loopback port.
- Existing archived pre-fix RED evidence covers BL-03/BL-04; the new RED transcript covers the candidate startup interpolation bug. Pre-fix RED output is not available for every earlier finding, so this report does not claim that evidence requirement was fully met.
- Earlier raw captures and manifests were preserved byte-for-byte. The initial unseeded-state diagnosis remains retracted; no old digest was relabeled as stable.

---

_Fixed: 2026-10-31_
_Fixer: Codex review-fix continuation_
_Iteration: 1_
