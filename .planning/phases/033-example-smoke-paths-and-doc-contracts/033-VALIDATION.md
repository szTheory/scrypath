---
phase: 33
slug: example-smoke-paths-and-doc-contracts
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-18
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for **cwd-correct smoke documentation** and **`docs_contract_test.exs`** extensions (gap closure from **`v1.6-MILESTONE-AUDIT.md`**).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Config file** | `mix.exs` (test paths only; no new config required) |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test` (or `mix verify.phase11` per maintainer habit) |
| **Estimated runtime** | ~30–90 seconds for contract file alone |

---

## Sampling Rate

- **After every task commit:** `mix test test/scrypath/docs_contract_test.exs`
- **After every plan wave:** same + spot-check `mix format --check-formatted`
- **Before `/gsd-verify-work`:** Contract file green; docs grep gates from plan acceptance criteria
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | ADPT-01, EXAM-02, VRFY-02, AUDT-01 | T-33-DOC-01 / — | N/A — docs only | ExUnit | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 33-01-02 | 01 | 1 | ADPT-01, EXAM-02, VRFY-02, AUDT-01 | T-33-DOC-01 | N/A | ExUnit | same | ✅ | ⬜ pending |
| 33-01-03 | 01 | 1 | ADPT-01, EXAM-02, VRFY-02, AUDT-01 | — | N/A | ExUnit | same | ✅ | ⬜ pending |

*T-33-DOC-01: Misleading shell cwd causes adopters to hit missing paths (ASVS L1 documentation integrity).*

---

## Wave 0 Requirements

- [x] **Existing infrastructure** — `docs_contract_test.exs` + `mix test` cover doc contracts; no Wave 0 stubs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reader walkthrough from fresh clone | EXAM-02 | Human judgment of clarity | Clone repo; follow README integration paragraph only; confirm no step implies `./scripts/smoke.sh` from repo root without `cd` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter after wave 0 + map verified

**Approval:** pending
