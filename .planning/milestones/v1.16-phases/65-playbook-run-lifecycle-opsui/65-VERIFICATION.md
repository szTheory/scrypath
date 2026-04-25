---
phase: 65-playbook-run-lifecycle-opsui
verified: 2026-04-22T20:07:31Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 4/4 must-haves verified
  gaps_closed:
    - "Explicit lifecycle coverage now asserts visible running state and terminal success for both preview `run` and catalog `run_now`."
    - "Failure-panel coverage now asserts the exact anchored primary doc URL plus bounded related doc links, replacing the prior docs-usability uncertainty with objective checks."
    - "Superseded-run race coverage now proves stale async exits cannot overwrite the newer run result."
  gaps_remaining: []
  regressions: []
---

# Phase 65: Playbook run lifecycle (OPSUI) Verification Report

**Phase Goal:** operator can run a saved `playbook_format: 1` playbook from catalog or detail with explicit idle/running/success/failure UI; failures surface structured errors with canonical doc links within two hops.
**Verified:** 2026-04-22T20:07:31Z
**Status:** passed
**Re-verification:** Yes - prior `human_needed` report rechecked after added automation

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Operator can start a saved `playbook_format: 1` playbook from catalog and from detail/preview. | ✓ VERIFIED | Catalog `run_now` loads, validates, previews, and calls the shared async scheduler in [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:152) and [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:729); preview `run` uses the same scheduler at [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:189). Rendered-path tests cover preview `run` and catalog `run_now` at [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:67) and [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:256). |
| 2 | Starting a run from catalog and from detail both enter explicit running state and resolve to success or failure without stale-result ambiguity on CI stub adapters. | ✓ VERIFIED | Running state is rendered directly from `@run_ui.phase == :running` with run-id wording in [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:1044); terminal success and failure panels render from `:ok` and `:error` in [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:1051) and [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:1091). Per-run async keys and `active_run?/2` gating prevent stale callbacks from applying newer results in [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:378), [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:772), and [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:778). Tests assert visible running state and terminal success for preview `run` and catalog `run_now`, and cover the superseded-run race where the newer run must win at [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:88), [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:296), and [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:364). |
| 3 | Failed runs show a structured, copy-friendly error surface with canonical documentation links within two hops. | ✓ VERIFIED | Failures are normalized through [run_failure.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex:1) and resolved through [doc_resolver.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex:1), which caps related links with `Enum.take(2)` at [doc_resolver.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex:50). The LiveView renders `failure_class`, message, primary and related doc anchors, plus `Copy diagnostics` from an allowlisted payload in [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:198), [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:817), and [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:1051). The failure test now asserts the exact anchored primary URL and bounded related links at [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:137), and the doc anchors exist in [playbook-schema-v1.md](/Users/jon/projects/scrypath/scrypath_ops/docs/playbook-schema-v1.md:94). |
| 4 | `mix verify.opsui` stays green for the default contributor path after Phase 65 changes. | ✓ VERIFIED | The root verification task shells into `scrypath_ops` non-interactively in [verify.opsui.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:1). Behavioral spot-checks run during this verification passed: `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` reported `14 tests, 0 failures`; `mix verify.opsui` reported `81 tests, 0 failures`. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` | Shared async run scheduler, explicit lifecycle UI, stale-run protection, diagnostics copy | ✓ VERIFIED | Substantive LiveView with per-run async keys, timeout/cancel handling, success/failure panels, and copy event wiring. |
| `scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex` | Stable structured failure enrichment | ✓ VERIFIED | Registry-backed normalization with allowlisted copy fields and deterministic messages. |
| `scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex` | Canonical doc URL resolution with bounded related links | ✓ VERIFIED | Primary and related docs resolve from config-backed base; related links are capped to two. |
| `scrypath_ops/docs/playbook-schema-v1.md` | Troubleshooting anchors for failure-panel primary links | ✓ VERIFIED | `#troubleshooting`, `#no_schema`, `#invalid_query`, and `#page_size_out_of_range` anchors exist and match resolver targets. |
| `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | Async lifecycle, failure panel, doc link, telemetry, and supersede-race coverage | ✓ VERIFIED | 14 focused LiveView tests passed, including running-state assertions, exact link assertions, and superseded-run result protection. |
| `lib/mix/tasks/verify.opsui.ex` | Root contributor verification command | ✓ VERIFIED | Implements the root CI-equivalent verification path used in spot-checks. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Preview `run` event | `schedule_playbook_run/1` | `handle_event("run", ...)` | ✓ WIRED | Preview runs call the shared scheduler directly. |
| Catalog `run_now` event | `schedule_playbook_run/1` | validated load path | ✓ WIRED | Catalog runs decode, validate, stage preview state, then call the same scheduler as preview runs. |
| `schedule_playbook_run/1` | `Runner.run_validated/3` | `start_async(run_async_key(run_id), fn -> ... end)` | ✓ WIRED | Runner execution only happens inside the async task, not inline in event handlers. |
| Async run callbacks | terminal UI state | `handle_async/3` + `active_run?/2` | ✓ WIRED | Only the active run id can write success or error UI, blocking stale callback overwrite. |
| Failure reason path | rendered doc links | `RunFailure.enrich/2` + `DocResolver.resolve/1` | ✓ WIRED | Error and timeout paths enrich failures before rendering the panel. |
| Failure panel | clipboard copy | `push_event("copy_run_diagnostics")` + browser listener | ✓ WIRED | Allowlisted JSON is encoded server-side and copied client-side in [app.js](/Users/jon/projects/scrypath/scrypath_ops/assets/js/app.js:1). |
| Root `mix verify.opsui` | `scrypath_ops` test suite | `System.cmd("bash", ["-lc", ...])` | ✓ WIRED | Root task invokes the same package-local test flow contributors use. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Running banner | `@run_ui` | `schedule_playbook_run/1`, `handle_async/3`, `handle_info/2`, supersede/cancel paths | Yes | ✓ FLOWING |
| Success panel | `@run_result` | `Runner.run_validated/3` result returned through `start_async` | Yes | ✓ FLOWING |
| Failure panel | `@run_failure_enriched` | `RunFailure.enrich/2` + `DocResolver.resolve/1` fed by async error/exit/timeout paths | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused PlaybookLive lifecycle suite passes from repo root | `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | `14 tests, 0 failures` | ✓ PASS |
| Root contributor verification path stays green | `mix verify.opsui` | `81 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `OPS3-01` | `65-02-PLAN.md`, `65-04-PLAN.md` | Operator can start a saved playbook from catalog or detail and observe an explicit idle → running → success or failure lifecycle without ambiguous intermediate states. | ✓ SATISFIED | Shared async scheduler for both entry points, rendered running and terminal states, plus passing preview/catalog/race-condition tests. |
| `OPS3-02` | `65-01-PLAN.md`, `65-03-PLAN.md`, `65-04-PLAN.md` | Failed runs show a structured, copy-friendly error surface with canonical docs within two hops. | ✓ SATISFIED | Registry-backed enrichment, resolver-backed primary and related docs, exact anchored URL assertions, and copy diagnostics behavior. |

### Anti-Patterns Found

No blocker anti-patterns found in the phase implementation files scanned. The only grep hits were ordinary HTML `placeholder=` attributes in form inputs, not stub markers.

### Gaps Summary

No code, wiring, data-flow, or coverage gaps remain against the phase goal or requirement IDs `OPS3-01` and `OPS3-02`. The previous `human_needed` status is cleared because the added automation now verifies the explicit lifecycle presentation and exact documentation-link contract as observable behavior rather than subjective intent.

---

_Verified: 2026-04-22T20:07:31Z_
_Verifier: Claude (gsd-verifier)_
