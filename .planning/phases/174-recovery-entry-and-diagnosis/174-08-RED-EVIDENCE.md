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
