---
phase: 109
slug: release-train-and-package-truth-audit
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-31
---

# Phase 109 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/mix/tasks/workflow_wiring_test.exs -x` |
| **Full suite command** | `mix verify.phase11` |
| **Estimated runtime** | Local runtime depends on Hex/package build checks; keep per-task quick checks focused and run the full gate per wave. |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mix/tasks/workflow_wiring_test.exs -x` or the narrow release test named by the task.
- **After every plan wave:** Run `mix verify.phase11`.
- **Before `$gsd-verify-work`:** `mix verify.phase11` must be green.
- **Max feedback latency:** One task commit for narrow release wiring checks; one wave for full package and parity checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 109-01-01 | 01 | 1 | REL-01 | T-109-01 | Release contract agreement cannot drift silently | integration | `mix test test/mix/tasks/workflow_wiring_test.exs -x` | yes | pending |
| 109-01-02 | 01 | 1 | REL-02 | T-109-02 | Hex package excludes non-library and generated outputs | integration | `mix test test/release/package_metadata_test.exs test/release/consumer_smoke_test.exs -x` | yes | pending |
| 109-01-03 | 01 | 1 | REL-03 | T-109-03 | Publish proof chain remains canonical and auditable | integration | `mix test test/mix/tasks/workflow_wiring_test.exs test/mix/tasks/verify_release_parity_test.exs -x` | yes | pending |
| 109-01-04 | 01 | 1 | REL-01, REL-03 | T-109-04 | Release docs match implemented workflow gates | docs/source | `mix verify.phase11` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Phase 109 should extend release workflow wiring, package metadata, consumer smoke, and parity tests rather than introduce a new test framework.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hex visibility and HexDocs reachability after public publish | REL-03 | Requires a published Hex package and network access; should not run in deterministic local gates. | Use the canonical publish or post-publish workflow and verify `mix verify.release_publish` and `mix verify.release_parity` report the expected public package state. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or existing Wave 0 coverage.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Feedback latency is bounded by narrow per-task checks plus `mix verify.phase11` per wave.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
