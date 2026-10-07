# Phase 174-08 RED Evidence

The focused standalone palette test failed on the intended rendered recovery-manifest assertion before a production change. The page settled on `ScrypathOps.Test.OpsPostB`: the URL, checked radio, selected-schema evidence and recovery handoff all identified B. The server-owned manifest had no validated target, its health destination was `/ops/phase174/health`, and the ignored palette anchor retained that same unscoped path.

- Test commit: `c9f8c239f6243658673c3662428307407559d9a6`
- Source HEAD used for the run: `c9f8c239f6243658673c3662428307407559d9a6`
- Source diff SHA-256 used for the run: `3d3c0046342c4e955a94777d020fcc0db9b27c8b7f7089e368d2dfc6d84cc537`
- Command: task-owned `scrypath_phase174_42b342e_recovery_tdd` Compose browser container, `E2E_SCOPE=phase174-standalone-palette`, one Chromium test, no retries.
- Native result: 1 test, 0 passed, 1 failed, 0 skipped; Playwright exit 1.
- JUnit: `examples/scrypath_ecommerce/test-results/phase174-recovery-c9f8c239f6/red/phase174-standalone-palette.xml` (modified `2026-10-07T19:30:56Z`, after run start `2026-10-07T19:30:51Z`).
- Machine classifier: `gsd_run check tdd-red-evidence ... --raw` returned `RED_EVIDENCE_OK`, reason `target_test_failed`.
- Semantic assessment: valid behavior failure. The target executed, the test-only allowlisted selector settled to B, and the actual server manifest and ignored palette DOM remained unscoped.

The initial mounted palette baseline was already green (1/1) because Plan 174-07 had already wired `Layouts.app` to render the server-owned manifest and forward `recovery_target`. The standalone failure is separate: `Live.OnMount` resolved against the global schema allowlist while the test-only phase fixture had supplied its own allowlist to the LiveView.

## Prominent Control Room action

The final actual browser matrix exposed a second valid acceptance failure. Both mounted and standalone Control Room views rendered `#control-room-health-link` at 40px, below the UI-SPEC's 44px minimum for prominent actions. The specific browser assertion was added to the existing mounted and standalone geometry matrix. Native JUnit reported 4 tests, 2 passed, 2 failed, 0 skipped; both failing tests were the expected 40px target-height assertions at the first desktop Control Room capture. The target mounted test executed its broader journey before reaching the geometry assertion. The trace and JUnit are under `examples/scrypath_ecommerce/test-results/phase174-recovery-54d8244d5e/`; the machine classifier returned `RED_EVIDENCE_OK` (`target_test_failed`) for the unchanged JUnit.

- Test commit: `54c623e`
- Source HEAD used for the run: `54d8244d5ebb89d7fceb6f1a8afaa9ddb02e2393`
- Command: isolated Phase 174 Compose project `scrypath_phase174_54d8244d5e_recovery_ctared`, full Chromium dual-entrypoint matrix, no retries.
- Expected: prominent Control Room action height >=44px; actual: 40px on mounted and standalone desktop views.
- Machine record: `examples/scrypath_ecommerce/test-results/phase174-recovery-54d8244d5e/red/cta-evidence.json` (ignored task evidence; classifier verdict `RED_EVIDENCE_OK`).
- Semantic assessment: valid behavior failure. Both production entrypoints rendered the named primary health action, and the actual computed browser box was 40px; the focused assertion did not depend on a generic action locator or setup failure.
