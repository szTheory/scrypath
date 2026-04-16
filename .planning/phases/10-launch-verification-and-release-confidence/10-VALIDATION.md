---
phase: 10
slug: launch-verification-and-release-confidence
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-16
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit plus repo-local artifact contract checks |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs -x` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~15 seconds for quick checks, excluding maintainer-owned publish dry-run |

---

## Sampling Rate

- **After every task commit:** Run the task-level `<automated>` command listed below.
- **After every plan wave:** Run `mix verify.phase10` once Plan `10-01` has landed; for Wave 3, also run the milestone artifact grep checks from Plan `10-03`.
- **Before `$gsd-verify-work`:** `mix verify.phase10` must be green, the credentialed publish dry-run evidence must be recorded, and the milestone audit/status files must point at the final evidence chain.
- **Max feedback latency:** keep automated checks under ~15 seconds unless the task explicitly uses the full `mix verify.phase10` gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | SHIP-01 | T-10-01 | `mix verify.phase10` stays auth-free while mirroring the CI release-confidence gate, including release workflow/config validation | command | `mix verify.phase10` | ➜ task output | ⬜ pending |
| 10-01-02 | 01 | 1 | SHIP-01 | T-10-02 / T-10-03 | Release runbook and docs contracts keep `mix verify.phase10` canonical and keep `HEX_API_KEY` outside the always-on gate | unit | `mix test test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs -x` | ✅ | ⬜ pending |
| 10-02-01 | 02 | 2 | SHIP-01 / SHIP-02 | T-10-04 / T-10-06 | Nyquist coverage exists for every Phase 10 task and records which steps are automated versus maintainer-owned | artifact | `rg -n '^## Per-Task Verification Map$|SHIP-01|SHIP-02|mix verify.phase10|HEX_API_KEY=\\.\\.\\. mix hex.publish --dry-run --yes' .planning/phases/10-launch-verification-and-release-confidence/10-VALIDATION.md` | ✅ | ⬜ pending |
| 10-02-02 | 02 | 2 | SHIP-01 / SHIP-02 | T-10-04 / T-10-06 | Phase proof artifact records the auth-free gate run, links prior evidence, and keeps manual/live boundaries explicit | command | `mix verify.phase10` | ➜ task output | ⬜ pending |
| 10-02-03 | 02 | 2 | SHIP-01 | T-10-05 | Credentialed Hex publish proof is documented without exposing the token or moving the step into CI | artifact | `rg -n '^## Credentialed Publish Evidence$|HEX_API_KEY=\\.\\.\\. mix hex.publish --dry-run --yes' .planning/phases/10-launch-verification-and-release-confidence/10-VERIFICATION.md` | ➜ task output | ⬜ pending |
| 10-03-01 | 03 | 3 | SHIP-02 | T-10-07 / T-10-08 | Milestone audit indexes Phase 08, 09, and 10 evidence without stealing ownership from earlier phases | artifact | `rg -n '^# Milestone v1\\.1 Audit$|10-VALIDATION\\.md|10-VERIFICATION\\.md|08-VALIDATION\\.md|09-VALIDATION\\.md|Deferred / Carry-Forward' .planning/v1.1-MILESTONE-AUDIT.md` | ➜ task output | ⬜ pending |
| 10-03-02 | 03 | 3 | SHIP-02 | T-10-08 / T-10-09 | Active milestone bookkeeping points at the final audit and verification chain with `SHIP-01` and `SHIP-02` marked complete | artifact | `rg -n 'SHIP-01|SHIP-02|10-VALIDATION\\.md|10-VERIFICATION\\.md|v1\\.1-MILESTONE-AUDIT\\.md' .planning/STATE.md .planning/ROADMAP.md .planning/REQUIREMENTS.md` | ➜ task output | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No additional test scaffolding is required before execution.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Maintainer-owned publish dry-run on the same candidate commit | SHIP-01 | Requires a real publisher `HEX_API_KEY`, which must not enter the auth-free CI gate or shared local automation | On the candidate commit recorded in `10-VERIFICATION.md`, run `HEX_API_KEY=... mix hex.publish --dry-run --yes`, confirm the command exit status, and record the result in `## Credentialed Publish Evidence` |
| First real tagged release as production confirmation path | SHIP-01 | D-06 keeps final production confirmation on the real release path rather than a synthetic rehearsal | After the first real release, confirm the published Hex package/tag path matches `docs/releasing.md` and link that outcome from the next milestone/archive artifact if needed |

---

## Evidence Chain

- Phase 10 automated and manual proof lives in `10-VERIFICATION.md`.
- Milestone-close indexing will live in `.planning/v1.1-MILESTONE-AUDIT.md`.
- Phase 08 and Phase 09 keep ownership of their shipped hardening work; this contract only defines how Phase 10 verifies and links that evidence.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or explicit artifact checks
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s for quick checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
