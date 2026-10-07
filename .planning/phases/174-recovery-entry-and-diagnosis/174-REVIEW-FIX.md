---
phase: 174
status: fixed
fixed: 2
skipped: 0
source_commit: 973813d
---

# Phase 174: Review Fixes

Parent-applied fixes following the independent review; no simulated reviewer or host approval.

## Fixed Issues

### CR-01: Collision-safe retry identity is lost during status verification

Receipt construction and sanitizer retain the original source. Expected-effect lookup requires source plus full ID; supersession also distinguishes sources. The existing same-ID Backend/Queue journey regression now traverses the rendered Check sync status URL, the real telemetry collector, authoritative queue/task reads, and returns running for the actual replacement. A source-free lookup mutation fails this assertion (native 4 tests, 1 failure; scratch `174-review-collision-red.log`); restoring the source-qualified lookup passes. Observation tests cover distinct same-ID source handles.

### WR-01: Shell navigation validates against a stale allowlist snapshot

OnMount resolves normal routes from current configuration; test-only phase174 routes obtain the allowlist from the current server fixture scenario. Control Room re-resolves stored URL selection on params and refresh, preserving explicit invalid selections as unavailable. A connected patch regression checks all four recovery surfaces' palette and both navigation shells; refresh regression excludes removed Control Room targets. Native RED: 30 tests, 3 failures; native Ops precommit and root verify.ops_ui after fixes: 275 tests + 2 doctests, zero failures. Logs are retained outside checkout under the task scratch root.

## Limits

No new dependency, persistent configuration change, Phase 175 work, trust approval, merge or release. Browser/hosted final-source evidence is reconciled separately; this record does not attest them.

Post-fix fixture correction e286962 keeps shell configuration resolution separate from consuming scenario observations. The latest native 11-case browser lane passes, and prior mounted recovery verifies its exact accepted replacement task and document. Earlier failed cached/spec and fixture-sequence runs are retained separately.
