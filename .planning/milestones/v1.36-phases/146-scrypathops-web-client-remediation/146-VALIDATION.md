---
phase: 146
slug: scrypathops-web-client-remediation
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-24
---

# Phase 146 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Phoenix LiveViewTest, Ecto SQL Sandbox, Req.Test |
| **Config file** | `scrypath_ops/test/test_helper.exs` and `scrypath_ops/mix.exs` aliases |
| **Quick run command** | `cd scrypath_ops && mix test test/scrypath_ops/swoosh_api_client_req_test.exs` |
| **Full suite command** | `mix verify.opsui` from the repository root |
| **Estimated runtime** | Quick: <30 seconds; full Ops gate: environment-dependent Postgres run |

---

## Sampling Rate

- **After the focused Swoosh contract task:** Run `cd scrypath_ops && mix test test/scrypath_ops/swoosh_api_client_req_test.exs`
- **After the dependency/lock task:** Run `cd scrypath_ops && mix deps.get --check-locked && mix compile --warnings-as-errors`
- **After every plan wave:** Run `mix verify.opsui`
- **Before `$gsd-verify-work`:** `mix verify.opsui`, the named root release gates, and detached fresh-resolution/audit evidence must be green or truthfully marked unavailable/failed under the phase stop policy
- **Max feedback latency:** 30 seconds for focused tests; full gates are allowed longer because they create/migrate Postgres and run the complete suite

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 146-01-01 | 01 | 1 | SEC-03 | T-146-01 | Swoosh-owned request options override conflicting caller options; response body stays raw; transport errors propagate | service-free unit contract | `cd scrypath_ops && mix test test/scrypath_ops/swoosh_api_client_req_test.exs` | ✅ focused test | ✅ green |
| 146-01-02 | 01 | 1 | SEC-03, EVID-03 | T-146-02 | Direct requirements use the approved fixed-compatible floors and the lock moves only causal rows | source + resolver | `cd scrypath_ops && mix deps.get --check-locked && mix compile --warnings-as-errors` | ✅ manifest/lock | ✅ green |
| 146-02-01 | 02 | 2 | SEC-03 | T-146-03 | Standalone Ops Phoenix/LiveView/Postgres behavior remains green on the remediated graph | integration suite | `mix verify.opsui` | ✅ | ✅ green |
| 146-02-02 | 02 | 2 | SEC-03 | T-146-04 | Required root release-train behavior remains green after the Ops-only change | regression gates | `mix compile --warnings-as-errors && mix test --exclude integration --exclude docs_contract --include requires_clean_workspace && mix verify --exclude integration && mix verify.phase11 && mix verify.phase99` | ✅ | ✅ green |
| 146-02-03 | 02 | 2 | SEC-03, EVID-03 | T-146-05 | Exact-candidate lockless resolution stays in approved ranges, Postgrex 0.22.4 remains dual-source valid, and the unsuppressed Ops audit exits zero | detached network evidence | Exact-SHA disposable-worktree fresh resolution, version assertions, and `cd scrypath_ops && mix hex.audit` | ✅ recorded procedure | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `scrypath_ops/test/scrypath_ops/swoosh_api_client_req_test.exs` — real Req client initialization, request precedence/raw response tuple, and transport-error contract for SEC-03.
- [x] Exact-candidate detached fresh-resolution procedure — isolated dependency/build directories, disposable Ops lock removal, target-range assertions, dual-source Postgrex check, and unsuppressed audit for SEC-03/EVID-03.
- [x] No new framework or package is required.

---

## Manual-Only Verifications

None. The detached fresh-resolution and live advisory/registry checks are network-dependent but command-driven; unavailable external evidence is recorded as unavailable and blocks completion rather than being manually waived as passing.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or completed Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all previously missing references
- [x] No watch-mode flags
- [x] Focused feedback latency < 30s; full-gate latency is explicitly classified
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-08-25

---

## Validation Audit 2026-08-25

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Current audit evidence:

- Live Hex and EEF CNA Postgrex predicates passed for stable, unretired 0.22.4 and the `< 0.22.4` affected boundary.
- The direct Swoosh Req contract passed with 2 tests and 0 failures.
- Checked-lock resolution, warnings-as-errors compilation, and unsuppressed `mix hex.audit` passed.
- `mix verify.opsui` passed with 2 doctests, 154 tests, and 0 failures.
- `mix verify.phase99` passed with 60 tests and 0 failures, then built documentation with warnings as errors.
