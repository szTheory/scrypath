---
phase: 145
slug: legacy-phoenix-and-ecto-decimal-remediation
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-22
---

# Phase 145 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Phoenix `ConnCase` and Ecto SQL Sandbox `DataCase` |
| **Config file** | `examples/phoenix_meilisearch/config/test.exs` |
| **Quick run command** | `cd examples/phoenix_meilisearch && mix test test/scrypath_demo/ecto_compatibility_test.exs test/scrypath_demo_web/endpoint_compatibility_test.exs` |
| **Full suite command** | `cd examples/phoenix_meilisearch && mix deps.get --check-locked && mix test && MIX_ENV=test mix ecto.migrate --quiet && mix precommit`, followed from the repository root by `mix test --exclude integration --exclude docs_contract` |
| **Estimated runtime** | Focused feedback under 60 seconds after dependencies and Postgres are ready; deterministic full gates several minutes |

---

## Sampling Rate

- **After every task commit:** Run the narrowest applicable focused test or manifest/lock assertion from the map below.
- **After every plan wave:** Run `cd examples/phoenix_meilisearch && mix deps.get --check-locked && mix test && MIX_ENV=test mix ecto.migrate --quiet && mix precommit`, then the root fast regression suite when the wave changes the candidate graph.
- **Before `$gsd-verify-work`:** The D-17 deterministic sequence must be green before the detached exact-candidate fresh-resolution and unsuppressed advisory audit; live Postgres/Meilisearch smoke remains separately classified supplemental evidence.
- **Max feedback latency:** 60 seconds for task-level source assertions or focused ExUnit checks once dependencies and Postgres are available.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 145-01-01 | 01 | 1 | SEC-02 | T-145-01, T-145-02, T-145-03, T-145-04 | The bounded legacy graph keeps Ecto and Decimal transitive while real Postgres, Phoenix error/cookie, and supervised loopback Bandit telemetry behavior remains compatible | manifest/lock plus Postgres/HTTP integration | `cd examples/phoenix_meilisearch && mix deps.get --check-locked && mix test test/scrypath_demo/ecto_compatibility_test.exs test/scrypath_demo_web/endpoint_compatibility_test.exs && mix format --check-formatted mix.exs test/scrypath_demo/ecto_compatibility_test.exs test/scrypath_demo_web/endpoint_compatibility_test.exs` | ✅ manifest/lock and both focused test files | ✅ green |
| 145-02-01 | 02 | 2 | SEC-02 | T-145-10, T-145-11 | The manifest directly owns Plug `~> 1.19.5`, the checked lock remains within all ten recovery bounds, and no direct Ecto/Decimal dependency or override is introduced | manifest/lock boundary contract | Plan 145-02 Task 1 `<automated>` command: checked-lock, precommit, actual-version assertions, direct-Plug assertion, scoped diff check | ✅ manifest/lock command surface | ✅ green |
| 145-02-02 | 02 | 2 | SEC-02 | T-145-12, T-145-13, T-145-14, T-145-16 | Deterministic gates pass on the recovery candidate; the detached lockless resolution compiles, satisfies the boundary matrix, audits cleanly, reports live smoke separately, and cleans up without mutating the primary lock | deterministic regression plus isolated live-registry proof | Plan 145-02 Task 2 `<automated>` command; durable results recorded in `145-02-SUMMARY.md` | ✅ command surface and execution evidence | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `examples/phoenix_meilisearch/test/scrypath_demo/ecto_compatibility_test.exs` — private `DataCase` coverage for changesets, required errors, inserts, queries, Author/Post association, timestamps, and persisted values under SEC-02.
- [x] `examples/phoenix_meilisearch/test/scrypath_demo_web/endpoint_compatibility_test.exs` — `ConnCase` error/cookie coverage plus one `async: false` supervised loopback HTTP/1/Bandit telemetry contract for SEC-02.
- [x] Compact plan summary evidence — candidate SHA, timestamp, environment, commands/statuses, selected versions, causal lock rows, audit result, and hard-versus-supplemental classification without raw logs or disposable artifacts.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Re-run exact-candidate fresh legacy resolution against current registry/advisory state | SEC-02 | The mutable registry/advisory result cannot be made a stable unit test; Phase 145 execution evidence is automated and recorded in `145-02-SUMMARY.md` | At the exact candidate SHA in a detached disposable worktree, isolate dependency/build paths, remove only the example lock, run `mix deps.get`, inspect every D-05 target range and the local path dependency, run unsuppressed `mix hex.audit`, and record command statuses plus environment and timestamp. Treat network/feed outage as unavailable proof. |
| Re-run existing Postgres + Meilisearch inline/Oban/fan-out live lane | SEC-02 | Supplemental service-dependent evidence; Phase 145's observed pass is recorded separately and does not replace deterministic coverage | Start the documented Compose/CI-shaped services and run the existing example live command from `CONTRIBUTING.md`/the example README. Report it separately; absence or failure cannot be replaced by deterministic causal checks. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or completed Wave 0 dependencies.
- [x] Sampling continuity: no three consecutive tasks without automated verification.
- [x] Wave 0 covers all focused-test and evidence references.
- [x] No watch-mode flags.
- [x] Task-level feedback latency is under 60 seconds after prerequisites are ready.
- [x] `nyquist_compliant: true` set in frontmatter after validation.

**Approval:** validated 2026-08-24

---

## Validation Audit 2026-08-24

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Current audit evidence:

- Checked-lock resolution plus the two focused compatibility files: 4 tests, 0 failures.
- Legacy example full deterministic suite and precommit: 6 tests, 0 failures (4 integration tests excluded).
- Root fast regression suite: 537 tests and 2 properties, 0 failures (79 excluded).
- No test files generated: all SEC-02 behaviors already had executable automated coverage and passing execution evidence.
