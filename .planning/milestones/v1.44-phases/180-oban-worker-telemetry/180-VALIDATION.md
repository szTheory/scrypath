---
phase: "180"
slug: "oban-worker-telemetry"
status: validated
nyquist_compliant: true
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
| **Quick run command** | `mix test --warnings-as-errors --exclude integration --exclude docs_contract test/scrypath/oban/worker_telemetry_test.exs test/scrypath/telemetry_contract_test.exs test/scrypath/telemetry_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync/related_worker_test.exs test/scrypath/loader_test.exs` |
| **Full suite command** | `mix verify.core --exclude integration --exclude docs_contract` + `mix test --warnings-as-errors test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs --include docs_contract` + `mix docs --warnings-as-errors` |
| **Estimated runtime** | ~30 seconds (quick), ~3 minutes (full) |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Quick run plus `mix compile --warnings-as-errors`, `mix credo --strict`, `mix format --check-formatted`, `mix verify.no_optional_deps`, `mix docs --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite green locally, then hosted PR checks green on the exact SHA (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`)
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

All nine tasks declare automated verification. The existing test files cover the
three phase requirements and D-18; no new test files or Wave 0 work are needed.

| Task ID | Plan | Wave | Requirements | Automated coverage | Status |
|---------|------|------|--------------|--------------------|--------|
| 180-01-01 | 01 | 1 | OBS-01 | `worker_telemetry_test.exs`: delete span, empty/chunked/repeated IDs, final attempt; `mix verify.no_optional_deps` | COVERED |
| 180-01-02 | 01 | 1 | OBS-01 | `worker_telemetry_test.exs`, `telemetry_test.exs`, `worker_test.exs`, `loader_test.exs`: upsert facts, error/cancel/raise/decode, metadata mapping, independence | COVERED |
| 180-01-03 | 01 | 1 | OBS-02 | `worker_telemetry_test.exs`: confirmed missing-ID removals, chunk failures, legacy/zero cases, cardinality | COVERED |
| 180-02-01 | 02 | 1 | OBS-03 | `package_metadata_test.exs`, `docs_contract_test.exs` with `--include docs_contract`; `mix docs --warnings-as-errors` | COVERED |
| 180-02-02 | 02 | 1 | OBS-03 | `docs_contract_test.exs` with `--include docs_contract`, `telemetry_contract_test.exs`: linked guide and single catalog; docs build | COVERED |
| 180-02-03 | 02 | 1 | OBS-03 / D-18 | `related_worker_test.exs`: exact body-free 4xx cancel and unchanged 5xx error | COVERED |
| 180-03-01 | 03 | 2 | OBS-03 | `telemetry_contract_test.exs`: bidirectional event equality, adjacency, empty/malformed inputs, ordering; runs under core exclude flags | COVERED |
| 180-03-02 | 03 | 2 | OBS-03 | `telemetry_contract_test.exs`: computed-name rejection, stale allowlist, single catalog | COVERED |
| 180-03-03 | 03 | 2 | OBS-03 | `telemetry_contract_test.exs`: real worker keys across nine scenarios, all event phases observed, negative key-drift proofs | COVERED |

Commands below resolve these test files under `test/scrypath/`,
`test/scrypath/oban/`, `test/scrypath/sync/`, or `test/release/`.

### Behavior-to-Command Map

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| OBS-01 | upsert/delete start+stop carry schema, backend, index, `sync_mode: :oban`, attempt, max_attempts, document_count; stop has `outcome` | unit | `mix test test/scrypath/oban/worker_telemetry_test.exs` | ✅ | ✅ green |
| OBS-01 | `{:error, _}` → `outcome: :error` + `error_kind`; in-boundary cancel → `cancel_reason` atom; decode failure → no Scrypath event | unit | same | ✅ | ✅ green |
| OBS-01 | raising backend → `:exception` with start metadata + kind/reason/stacktrace | unit | same | ✅ | ✅ green |
| OBS-01 | `job_stop_metadata/1` mapping incl. `{:invalid_job, {:invalid_arg, "x"}}` → `:invalid_arg` | unit | `mix test test/scrypath/telemetry_test.exs` | ✅ | ✅ green |
| OBS-02 | missing ids → one `missing_removed` with distinct `count`; 1,500 → one event; failed chunk/legacy/zero missing → none | unit | `mix test test/scrypath/oban/worker_telemetry_test.exs` | ✅ | ✅ green |
| OBS-03 | guide event set == AST-scanned `lib/` set (both directions); literal-name guard; key contract for new events | contract | `mix test test/scrypath/telemetry_contract_test.exs` | ✅ | ✅ green |
| OBS-03 | guide in extras + Operations group; hygiene bans `OBS-NN` | contract | `mix test test/release/package_metadata_test.exs test/scrypath/docs_contract_test.exs --include docs_contract` | ✅ | ✅ green |
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

### Revalidation Evidence — 2026-10-26

Re-audited all three PLAN/SUMMARY pairs, the existing behavior tests and the
documented review-fix deltas against current source. OBS-01, OBS-02 and OBS-03
are COVERED across all nine tasks; no PARTIAL or MISSING coverage was found.
The previous `nyquist_compliant: false` contradicted the green map and sign-off;
it is now reconciled to `true`. No implementation changes, generated tests,
manual-only items or auditor escalation were needed.

Fresh local checks used `ASDF_ELIXIR_VERSION=1.19.5-otp-28`,
`ASDF_ERLANG_VERSION=28.5` and `MIX_ENV=test` (the shell has no default BEAM
version selected):

- `mix do compile --warnings-as-errors + test` with the quick-run flags and six
  files above: **124 tests, 0 failures**, 3.4 seconds; the untagged telemetry
  contract executes with `--exclude integration --exclude docs_contract`.
- `mix test --warnings-as-errors test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs --include docs_contract`:
  **79 tests, 0 failures**, 1.0 second.
- `mix verify.no_optional_deps`: exit 0; **Verified optional dependencies absent
  from isolated build: oban**.
- `mix docs --warnings-as-errors`: exit 0.

These are local phase-validation checks. The full core suite was not rerun for
this planning-only correction. Historical hosted receipts retain their original
source identities; this audit does not extend them or supply maintainer approval.

## Validation Audit 2026-10-26

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
