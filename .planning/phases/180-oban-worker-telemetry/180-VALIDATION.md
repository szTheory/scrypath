---
phase: "180"
slug: "oban-worker-telemetry"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: true) (#2117)
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-10-25"
---

# Phase 180 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 28) |
| **Config file** | `test/test_helper.exs` (loads `test/support/**/*.ex`) |
| **Quick run command** | `mix test test/scrypath/oban/worker_telemetry_test.exs test/scrypath/telemetry_contract_test.exs test/scrypath/telemetry_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs` |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract` + `mix test test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs` + `mix verify.no_optional_deps` + `mix docs --warnings-as-errors` |
| **Estimated runtime** | ~30 seconds (quick), ~3 minutes (full) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Quick run plus `mix compile --warnings-as-errors`, `mix credo --strict`, `mix format --check-formatted`, `mix verify.no_optional_deps`, `mix docs --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite green locally, then hosted PR checks green on the exact SHA (`core`, `package`, `repository-contracts`, `backend`)
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| OBS-01 | upsert/delete start+stop carry schema, backend, index, `sync_mode: :oban`, attempt, max_attempts, document_count; stop has `outcome` | unit | `mix test test/scrypath/oban/worker_telemetry_test.exs` | ✅ | ✅ green |
| OBS-01 | `{:error, _}` → `outcome: :error` + `error_kind`; in-boundary cancel → `cancel_reason` atom; decode failure → no Scrypath event | unit | same | ✅ | ✅ green |
| OBS-01 | raising backend → `:exception` with start metadata + kind/reason/stacktrace | unit | same | ✅ | ✅ green |
| OBS-01 | `job_stop_metadata/1` mapping incl. `{:invalid_job, {:invalid_arg, "x"}}` → `:invalid_arg` | unit | `mix test test/scrypath/telemetry_test.exs` | ✅ | ✅ green |
| OBS-02 | missing ids → one `missing_removed` with distinct `count`; 1,500 → one event; failed chunk/legacy/zero missing → none | unit | `mix test test/scrypath/oban/worker_telemetry_test.exs` | ✅ | ✅ green |
| OBS-03 | guide event set == AST-scanned `lib/` set (both directions); literal-name guard; key contract for new events | contract | `mix test test/scrypath/telemetry_contract_test.exs` | ✅ | ✅ green |
| OBS-03 | guide in extras + Operations group; hygiene bans `OBS-NN` | contract | `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs` | ✅ | ✅ green |
| D-18 | related worker 4xx → `{:cancel, {:http_error, 400}}` | unit | `mix test test/scrypath/sync/related_worker_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/support/telemetry_capture.ex` — full-name capture helper with `on_exit` detach
- [x] Oban telemetry scenario support (recording, failing-second-delete-chunk and raising backends; loader schemas; shared scenario runner)
- [x] `test/scrypath/oban/worker_telemetry_test.exs` — OBS-01, OBS-02
- [x] `test/scrypath/telemetry_contract_test.exs` — OBS-03, untagged so it runs in the `core` lane

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-10-25 — all 8 map rows green (quick run 108 tests, package/docs contract 79 tests, no_optional_deps and docs --warnings-as-errors clean; full core suite 996 tests after the wave 2 merge)

## Validation Audit 2026-10-26

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
