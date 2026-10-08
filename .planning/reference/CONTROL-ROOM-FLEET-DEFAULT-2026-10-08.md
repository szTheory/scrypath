# Control Room fleet default — 2026-10-08

The maintainer clarified that Control Room is the entry point for overall health and action items, with deliberate schema drill-in afterward. The previous default rendered the first allowlisted schema as “Selected schema” and silently scoped its navigation, although the health summary already observed the whole fleet.

Control Room and Search health now resolve only explicit URL selections. Without a schema query, they show no selected-schema context and their navigation remains unscoped. The Control Room health link opens both diagnostic rows. Per-schema links still open the matching workflow; explicit allowlisted URLs, browser history, source identity, recovery gates, and workflow schema controls retain their existing behavior. No dependencies or recovery capabilities changed. The summary continues to describe observed sync failures rather than certify search correctness or promotion readiness.

## Verification

- App `mix precommit`: 277 tests and 2 doctests passed; compilation, formatting, and the navigation contract passed.
- Canonical root `mix verify.ops_ui`: 277 tests and 2 doctests passed.
- Native Chromium run: 15 tests, zero failures/errors/skips, no retries. Four new cases cover default fleet navigation and deliberate row drill-in at 1440px and 390px through mounted and standalone entry points. All 11 existing recovery journeys passed, including explicit selections, history, unavailable schemas, source collisions, retained evidence, gating returns, focus, and responsive captures.
- The default ExUnit journey proves a failure on the second allowlisted schema remains visible while neither schema is implicitly selected, including after refresh and the health handoff.
- Native report: [control-room-fleet-default-2026-10-08.browser.xml](control-room-fleet-default-2026-10-08.browser.xml); SHA-256 `d05db00d976f9ed085b57cc71372c47ea84a9baea7493a64c7f2e09d3c7ec10d`.
- The three runtime files matched both preview images by SHA-256. Desktop and mobile captures were inspected together. The disposable port4014 fixture was restored to `all_green` after browser checks.

The earlier Phase174 closeout and UI follow-up receipts remain historical evidence for their respective source revisions. This focused correction has its own test evidence and PR checks. Phase175 remains unstarted; no merge, release, or trust approval is implied.
