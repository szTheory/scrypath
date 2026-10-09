# Quiet Search health follow-up — 2026-10-09

User feedback: zero issue counts and all-zero schema cards distract from the work
operators came to investigate; “signals” is vague user-facing language.

## Result

- Incomplete checks, failed backend tasks, and failed queue jobs appear only with
  positive counts. Schema coverage is quiet metadata beside **Per-schema health**.
- Schemas with no pending or failed work start compact. Native Details controls
  reveal last-success history, exact timestamps, copy feedback, and recovery links.
- Pending, retrying, failing, and unavailable checks open by default and sort ahead
  of quiet schemas. Zero Pending/Failed/Retrying counters are omitted in details.
- Unused queues in inline/manual mode remain distinct from unavailable queue checks.
  Last-success retention and backend classification are unchanged.
- Failed sync work omits zero reason counts and its duplicate healthy rollup.
  The adjacent sync table uses **Check** and **Sync status** instead of “Signal.”
- Stable module-based DOM IDs keep row/action identity during refresh and reorder.
  No dependencies, theme preference, recovery permissions, or gated workflows changed.

## Executable evidence

`mix precommit` and root `mix verify.ops_ui` each passed **281 tests + 2 doctests**.
Focused compilation/tests with warnings as errors passed **42 tests**.

Final native Chromium coverage is **57 passing cases**, with retries disabled:

| Scope | Passing cases | Machine report |
| --- | ---: | --- |
| Timestamp copy and feedback | 14 | `combined.browser.xml`, copy suite only |
| Health help (both entries, desktop/mobile, light/dark) | 8 | `combined.browser.xml`, help suite only |
| Quiet health, keyboard details, refresh and state visibility | 8 | `matrix.browser.xml` |
| Exact times, both entries, four widths/two themes and edge states | 24 | `time.browser.xml` |
| Reordering/focus, retained evidence, pending response | 3 | `refresh.browser.xml` |

The original combined report is **not** an all-green run: it retains 8 quiet-test
assertion failures and 2 timeouts. The earlier `initial.browser.xml` preserves 8
quiet-test selector failures; the first matrix and time reruns each preserve one
timeout in their `*-timeout.browser.xml` reports. Corrections selected the outer
schema summary (instead of nested timestamp summaries), checked timestamp
retention directly after a successful check, gave the eight-refresh matrix a
bounded 60-second timeout, and split the old timestamp monolith into separate
viewport/theme and evidence-state cases. All affected cases then passed; failed
reports are preserved unchanged rather than overwritten or counted as successes.

One batched visual review covered healthy, failing, and unavailable states across
both entry points, desktop/mobile, and light/dark (24 captures). Healthy schemas
are compact; nonzero work and unknown information remain visible. No horizontal
overflow or clipped schema identities appeared. No further visual edits were needed.

## Runtime and boundaries

Seven edited runtime/fixture files match both rebuilt preview containers by
SHA-256. The table below binds this evidence to the implementation bytes:

| File | SHA-256 |
| --- | --- |
| `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` | `ce8a3278512700c75ede55cc2ce353fab2c93a3767fd1ca89f8256ce6a96dc42` |
| `scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex` | `b35042d1fa41d58e5ea2409452adf794b19ada1bcbfaca777d18bec1f0d565aa` |
| `scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex` | `e5b825dc3da0c02cc2bfe600c892b51718eb447c01de6a83fec652e416a2d0bd` |
| `scrypath_ops/assets/css/app.css` | `e6c87a4c8417be0e4b20afa3b585bd3c5c90eac1504f96fdc67e06f4c193c509` |
| `scrypath_ops/assets/js/ops_hooks.js` | `f2a3adb8bec068c45283cb4d92b7fc505698167dd2bc370acee5f144896f02d1` |
| `scrypath_ops/test/support/phase173_fixture_source.ex` | `2de96fc7c44e10a2ac11b4824df976c9143caf792c89e169dbea93a39879f742` |
| `examples/scrypath_ecommerce/test/support/phase173_fixture_source.ex` | `98a0bb78b165bd40b5f031bac3cbe0a26c52c7355ac61d945a45233cd4aac7f8` |

Reports share this document's filename prefix. Captures and command logs remain
under `/private/tmp/scrypath-phase173-20261006-155750/ui-quiet-health-*`.
Review preview: <http://127.0.0.1:4014/admin/search/health>.

This is an authorized UI follow-up on draft PR95, stacked on PR94. It does not
reopen Phase175 or supersede historical Phase174 closeout/CI receipts. Current
hosted checks must be tied separately to the final pushed source. No merge or
release is requested. The original 15 dirty paths and frozen Phase173 source
remain unchanged; the preview database was not reseeded by this read-only pass.
