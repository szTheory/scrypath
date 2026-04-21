---
phase: 47
slug: verification-hardening
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-04-21
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution (OPSUI-10).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Phoenix **`ConnCase`**, **`Phoenix.LiveViewTest`**) |
| **Config file** | `scrypath_ops/config/test.exs` |
| **Quick run command** | `cd scrypath_ops && mix test test/path/to/single_test.exs` |
| **Full suite command** | `cd scrypath_ops && mix test` |
| **Estimated runtime** | ~2–5 minutes (local), CI similar without Meilisearch |

---

## Sampling Rate

- **After every task commit:** Run the **narrowest** `cd scrypath_ops && mix test …` covering changed tests or live modules.
- **After every plan wave:** `cd scrypath_ops && mix test` exits **0**; after **`verify.opsui`** exists, `mix verify.opsui` from repo root exits **0**.
- **Before `/gsd-verify-work`:** Full ops suite green; root `mix test --exclude integration` still green if library files touched.
- **Max feedback latency:** Under 5 minutes for OPSUI CI job (single matrix row).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 47-01-01 | 01 | 1 | OPSUI-10 | T-47-01 | CI always exercises ops on `main` push | config | `grep -n "scrypath_ops" .github/workflows/ci.yml` | ⬜ pending |
| 47-01-02 | 01 | 1 | OPSUI-10 | — | Postgres wait before tests | integration | `cd scrypath_ops && mix test` in CI | ⬜ pending |
| 47-02-01 | 02 | 1 | OPSUI-10 | T-47-02 | Formatter inputs do not widen secret paths | unit | `mix verify.opsui` | ⬜ pending |
| 47-02-02 | 02 | 1 | OPSUI-10 | — | Ops format check passes | unit | `mix format --check-formatted` (scope per plan) | ⬜ pending |
| 47-03-01 | 02 | 2 | OPSUI-10 | T-47-03 | No credential leakage in test HTML | unit | `cd scrypath_ops && mix test test/.../operator_ia_contract_test.exs` | ⬜ pending |
| 47-03-02 | 03 | 2 | OPSUI-10 | T-47-04 | Fail-closed `/ops` auth | unit | `cd scrypath_ops && mix test test/scrypath_ops_web/live/` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements: **`scrypath_ops`** already has Ecto test pipeline, **`ConnCase`**, and LiveView tests under **`test/scrypath_ops_web/live/`**.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GitHub Actions YAML path filters on real fork PR | OPSUI-10 | Needs GitHub UI / `act` | Open test PR touching only `docs/` — OPSUI job skipped; touch `lib/` — job runs |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands listed in PLAN.md
- [ ] Sampling continuity: no three consecutive tasks without `mix test` slice
- [ ] Wave 0: N/A (covered above)
- [ ] No watch-mode flags in CI
- [ ] Feedback latency under 5 minutes for OPSUI job
- [ ] `nyquist_compliant: true` set in frontmatter when execution completes

**Approval:** pending
