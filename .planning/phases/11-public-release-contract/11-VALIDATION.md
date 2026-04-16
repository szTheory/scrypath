---
phase: 11
slug: public-release-contract
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-16
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix tasks + GitHub Actions workflow checks |
| **Config file** | `mix.exs`, `.github/workflows/release-please.yml`, `release-please-config.json`, `.release-please-manifest.json` |
| **Quick run command** | `mix verify.phase10` |
| **Full suite command** | `mix test && mix verify.phase10` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.phase10` or the task-specific focused command
- **After every plan wave:** Run `mix test && mix verify.phase10`
- **Before `$gsd-verify-work`:** Full suite plus clean-consumer smoke path must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | REL-01 | T-11-01 / — | Release metadata, tag, workflow, and package version stay aligned from repo state through publish path | integration | `mix verify.phase10` | ✅ | ⬜ pending |
| 11-01-02 | 01 | 1 | REL-02 | T-11-02 / — | Published artifact is installable from a clean consumer flow and documented quick-start path compiles | smoke | `mix test test/release/package_metadata_test.exs` | ✅ | ⬜ pending |
| 11-02-01 | 02 | 2 | REL-03 | T-11-03 / — | Maintainer recovery docs cover tag/version drift, failed publish, and artifact mismatch with concrete commands | docs-contract | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/release/package_metadata_test.exs` — existing package metadata contract coverage
- [x] `test/scrypath/docs_contract_test.exs` — existing release-doc contract coverage
- [x] `lib/mix/tasks/verify.phase10.ex` — existing auth-free release-confidence gate

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real public Hex publish against the maintainer-owned publisher account | REL-01 | Requires live publisher credentials and irreversible external side effects | Run the canonical GitHub release flow on the selected version, confirm Hex package page and GitHub release exist, then record results in the phase verification artifact |
| Clean consumer smoke against the actually published Hex artifact and HexDocs | REL-02 | Depends on public artifact propagation timing and a fresh consumer app environment | Create a throwaway Mix app, install `{:scrypath, "~> <published version>"}`, run `mix deps.get`, compile a minimal `use Scrypath` schema, and verify the versioned HexDocs page loads |

---

## Validation Sign-Off

- [x] All tasks have an automated verify path or an explicit manual-only boundary
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
