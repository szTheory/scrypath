---
phase: 144
slug: root-http-client-dependency-remediation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-22
---

# Phase 144 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with existing `Req.Test` stubs |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/meilisearch/client_test.exs test/scrypath/telemetry_test.exs --exclude integration --exclude docs_contract` |
| **Full suite command** | `mix deps.get && mix compile --warnings-as-errors && mix test --exclude integration --exclude docs_contract && mix verify --exclude integration && mix verify.phase11 && mix verify.phase99` |
| **Estimated runtime** | Quick feedback under 60 seconds; full gate bundle several minutes |

---

## Sampling Rate

- **After every task commit:** Run the narrowest applicable automated command from the map below.
- **After every plan wave:** Run `mix test --exclude integration --exclude docs_contract` plus `mix deps.get --check-locked` in every graph touched by that wave.
- **Before `$gsd-verify-work`:** The full root gate bundle must be green, every touched graph must pass `mix deps.get --check-locked`, and the exact-candidate fresh-resolution/audit proof must be recorded.
- **Max feedback latency:** 60 seconds for task-level source or focused-test checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 144-01-01 | 01 | 1 | SEC-01, COMPAT-02 | T-144-01 | All three direct Req constraints use `~> 0.6.1`; root Plug uses `~> 1.19.5`; all four locks resolve one compatible Req closure without unrelated upgrades | manifest/lock contract | `mix deps.get --check-locked` in root, `scrypath_ops`, `examples/phoenix_meilisearch`, and `examples/scrypath_ecommerce` | ✅ manifests/locks | ⬜ pending |
| 144-01-02 | 01 | 1 | COMPAT-02 | T-144-02, T-144-03 | Req 0.6 preserves tagged errors, caller/default header merging, unique task-filter encoding, and error telemetry redaction | focused ExUnit/Req.Test | `mix test test/scrypath/meilisearch/client_test.exs test/scrypath/telemetry_test.exs --exclude integration --exclude docs_contract` | ❌ Wave 0 causal cases | ⬜ pending |
| 144-02-01 | 02 | 2 | SEC-01, COMPAT-02 | T-144-01, T-144-02, T-144-03 | Deterministic compile, fast-test, verify, phase-11, and phase-99 gates pass on the checked locks | root verification bundle | `mix deps.get && mix compile --warnings-as-errors && mix test --exclude integration --exclude docs_contract && mix verify --exclude integration && mix verify.phase11 && mix verify.phase99` | ✅ existing tasks | ⬜ pending |
| 144-02-02 | 02 | 2 | SEC-01 | T-144-01 | A detached exact-candidate root resolution selects Req `>= 0.6.1` and `< 0.7.0`, Plug `>= 1.19.5` and `< 1.20.0`, Mint `>= 1.9.3`, hpax `>= 1.0.4`, and `mix hex.audit` exits zero without suppression | isolated network proof | Disposable-worktree `mix deps.get` followed by `mix hex.audit` and version/path inspection | ❌ execution procedure | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `test/scrypath/meilisearch/client_test.exs` (or one focused equivalent) with retry-disabled transport-error normalization, default/caller header merging, and unique task-filter encoding coverage for COMPAT-02.
- [ ] Extend `test/scrypath/telemetry_test.exs` with error-event assertions proving headers, bodies, and API keys are absent for COMPAT-02.
- [ ] Define the disposable detached-worktree command sequence for the exact-candidate fresh-resolution and `mix hex.audit` evidence required by SEC-01; do not add a permanent script or CI lane.
- [ ] Add no test framework or dependency; reuse ExUnit and `Req.Test`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Exact-candidate fresh root resolution and current Hex advisory result | SEC-01 | Depends on live registry/advisory state and must run against a detached candidate commit without mutating the primary lock | Create a detached worktree at the candidate SHA, isolate dependency/build paths, remove only its root `mix.lock`, run `mix deps.get` and `mix hex.audit`, then record the SHA, timestamp, environment versions, selected Req/Mint/hpax/Plug versions and paths, and command exit statuses. Treat network/feed outage as unavailable proof, never a pass. |
| Live Meilisearch smoke | COMPAT-02 | Supplemental service-dependent evidence; the service may be unavailable | When Meilisearch is available, run `SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix verify.meilisearch_smoke` and report it separately from required service-free gates. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Task-level feedback latency is under 60 seconds.
- [ ] `nyquist_compliant: true` set in frontmatter after validation.

**Approval:** pending
