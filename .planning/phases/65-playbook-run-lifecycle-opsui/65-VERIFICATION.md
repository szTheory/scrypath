---
phase: 65-playbook-run-lifecycle-opsui
verified: 2026-04-22T19:08:52Z
status: human_needed
score: 4/4 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Run a saved playbook from both catalog and preview in the browser"
    expected: "Catalog 'Run now' and preview 'Run saved playbook' each show an obvious running state, then a persistent success or failure panel with no confusing intermediate UI."
    why_human: "The state machine and tests are wired, but clarity of the idle/running/success/failure presentation is ultimately a UX judgment."
  - test: "Click failure-panel documentation links for representative failures"
    expected: "The primary link lands on an actionable doc section and any related links keep the fix within two hops for an operator."
    why_human: "Automated tests confirm HTTPS links and anchors exist, but only a human can confirm the docs are actually easy to navigate and useful."
---

# Phase 65: Playbook run lifecycle (OPSUI) Verification Report

**Phase Goal:** operator can run a saved `playbook_format: 1` playbook from catalog or detail with explicit idle/running/success/failure UI; failures surface structured errors with canonical doc links within two hops.
**Verified:** 2026-04-22T19:08:52Z
**Status:** human_needed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Operator can start a saved `playbook_format: 1` playbook from catalog and from detail/preview. | ✓ VERIFIED | Catalog `run_now` loads, validates, stages preview, and calls the shared scheduler in [scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:151); preview `run` calls the same scheduler at [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:189); tests cover saved-playbook load+run and catalog `run_now` at [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:93) and [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:247). |
| 2 | Runs move through an explicit idle/running/success/failure lifecycle without stale-result ambiguity on stubbed adapters. | ✓ VERIFIED | `run_ui` is initialized in mount and transitions through `:running`, `:ok`, and `:error` with `run_id` gating, timeout, cancel, and supersede handling in [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:378), [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:432), and [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:731); rendered running/success/failure UI exists in [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:1009); tests cover success, forced failure, and superseding load behavior in [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:71), [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:148), and [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:247). |
| 3 | Failed runs show a structured, copy-friendly error surface with canonical documentation links within two hops. | ✓ VERIFIED | Failure reasons normalize through the registry-backed `RunFailure.enrich/2` in [run_failure.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex:10) and URL mapping in [doc_resolver.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex:8); the LiveView renders `failure_class`, `message`, primary/related links, and `Copy diagnostics` from an allowlisted payload in [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:205) and [playbook_live.ex](/Users/jon/projects/scrypath/scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex:1041); troubleshooting anchors exist in [playbook-schema-v1.md](/Users/jon/projects/scrypath/scrypath_ops/docs/playbook-schema-v1.md:94); tests assert failure panel content, HTTPS doc links, and copy action at [playbook_live_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs:148) and [run_failure_test.exs](/Users/jon/projects/scrypath/scrypath_ops/test/scrypath_ops/playbook/run_failure_test.exs:6). |
| 4 | `mix verify.opsui` stays green for the default contributor path after Phase 65 changes. | ✓ VERIFIED | Root verification task mirrors CI in [lib/mix/tasks/verify.opsui.ex](/Users/jon/projects/scrypath/lib/mix/tasks/verify.opsui.ex:1); behavioral spot-check `mix verify.opsui` passed during verification with 80 tests and 0 failures. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` | Async run lifecycle, terminal UI, copy action, telemetry | ✓ VERIFIED | Substantive LiveView with async scheduling, stale-run guards, failure enrichment, and rendered lifecycle panels. |
| `scrypath_ops/lib/scrypath_ops/playbook/run_failure.ex` | Stable JSON-serializable failure enrichment | ✓ VERIFIED | Registry-backed normalization with allowlisted copy and doc resolution. |
| `scrypath_ops/lib/scrypath_ops/playbook/doc_resolver.ex` | Canonical doc URL resolution with primary + related links | ✓ VERIFIED | Resolver maps doc refs to absolute URLs and caps related links to two. |
| `scrypath_ops/docs/playbook-schema-v1.md` | Troubleshooting anchors for primary links | ✓ VERIFIED | `Troubleshooting`, `no_schema`, `invalid_query`, and `page_size_out_of_range` sections exist. |
| `scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | Async success/failure/catalog/telemetry coverage | ✓ VERIFIED | 13 focused LiveView tests passed. |
| `lib/mix/tasks/verify.opsui.ex` | Root contributor verification command | ✓ VERIFIED | Implements non-interactive `cd scrypath_ops && mix deps.get && mix test` flow. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `PlaybookLive` | `Runner.run_validated/3` | `start_async` shared scheduler | ✓ WIRED | `schedule_playbook_run/1` wraps `Runner.run_validated/3` in `start_async` and both `run` and `run_now` reach it. |
| Catalog row UI | `run_now` event | `phx-click="run_now"` | ✓ WIRED | Catalog button and event handler are present and tested. |
| `PlaybookLive` failure path | `RunFailure.enrich/2` + `DocResolver.resolve/1` | `enrich_run_failure/2` | ✓ WIRED | Async error and timeout paths set `run_failure_enriched` before rendering the panel. |
| Failure panel | Clipboard copy | `push_event("copy_run_diagnostics")` + browser listener | ✓ WIRED | LiveView sends encoded allowlisted JSON and `scrypath_ops/assets/js/app.js` writes it to `navigator.clipboard` when available. |
| Root `mix verify.opsui` | `scrypath_ops` test suite | `System.cmd("bash", ["-lc", ...])` | ✓ WIRED | Root task shells into `scrypath_ops` and runs the same commands documented in CONTRIBUTING. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `PlaybookLive` success panel | `@run_result` | `Runner.run_validated/3` returned from `start_async` into `handle_async` | Yes | ✓ FLOWING |
| `PlaybookLive` failure panel | `@run_failure_enriched` | `RunFailure.enrich/2` + `DocResolver.resolve/1` from async error/timeout paths | Yes | ✓ FLOWING |
| `PlaybookLive` lifecycle banner | `@run_ui` | `schedule_playbook_run/1`, `handle_async/3`, `handle_info/2`, supersede/cancel paths | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused LiveView lifecycle tests pass from repo root | `mix test scrypath_ops/test/scrypath_ops_web/live/playbook_live_test.exs` | `13 tests, 0 failures` | ✓ PASS |
| Contributor verification path stays green | `mix verify.opsui` | `80 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `OPS3-01` | `65-02-PLAN.md`, `65-04-PLAN.md` | Operator can start a saved playbook from catalog or detail and observe explicit lifecycle UI. | ✓ SATISFIED | Shared scheduler, `run_ui` state machine, running/success/error rendering, and passing catalog/detail tests. |
| `OPS3-02` | `65-01-PLAN.md`, `65-03-PLAN.md`, `65-04-PLAN.md` | Failed runs show structured, copy-friendly errors with canonical docs within two hops. | ✓ SATISFIED | Registry-backed failure maps, resolver-backed links, troubleshooting anchors, copy diagnostics action, and passing forced-failure tests. |

### Anti-Patterns Found

No blocker anti-patterns found in the phase implementation files scanned. Placeholder UI, empty handlers, and stub-only run paths were not present in the verified artifacts.

### Human Verification Required

### 1. Lifecycle Clarity

**Test:** Run a saved playbook from a catalog row and from the preview panel in a browser session.
**Expected:** Each path clearly shows idle → running → success or failure, and the terminal panel remains understandable without relying on flash timing.
**Why human:** The code and tests prove the state machine, but not whether the visual hierarchy and wording are obvious to operators.

### 2. Documentation Usability

**Test:** Force a representative failure from the UI and click the primary and related doc links.
**Expected:** The primary doc is actionable on arrival, and any needed follow-up reference is reachable within one more click.
**Why human:** Static verification confirms canonical HTTPS links and anchors, but only a human can judge whether the documentation path is genuinely useful in context.

### Gaps Summary

No code or wiring gaps were found against the phase goal or requirement IDs `OPS3-01` and `OPS3-02`. Automated verification passed; remaining work is human UX confirmation.

---

_Verified: 2026-04-22T19:08:52Z_
_Verifier: Claude (gsd-verifier)_
