---
phase: 97
slug: canonical-contract-freeze-and-scope-guard
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 97 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/docs_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/scrypath/docs_contract_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 97-01-01 | 01 | 1 | TRUTH-01 | T-97-01 | Canonical install/version statement IDs are frozen and discoverable in one authority map | docs-contract | `rg "CST-TRUTH-01-INSTALL|CST-TRUTH-02-RELEASE-MAIN|CST-TRUTH-03-SUPPORT-AUTHORITY" .planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-STATEMENTS.md` | ✅ | ⬜ pending |
| 97-01-02 | 01 | 1 | TRUTH-02 | T-97-02 | Release-backed vs `main` language is explicit and traceable through frozen requirement rows | docs-contract | `rg "^\\| TRUTH-01 \\||^\\| TRUTH-02 \\||^\\| TRUTH-03 \\|" .planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-TRACEABILITY.md` | ✅ | ⬜ pending |
| 97-01-03 | 01 | 1 | TRUTH-03 | T-97-03 | Validation/context artifacts consume frozen statement IDs and mapping rows, not prose snapshots | docs-contract | `rg "CST-TRUTH-01-INSTALL|CST-TRUTH-02-RELEASE-MAIN|CST-TRUTH-03-SUPPORT-AUTHORITY|TRUTH-01|TRUTH-02|TRUTH-03" .planning/phases/97-canonical-contract-freeze-and-scope-guard/97-VALIDATION.md` | ✅ | ⬜ pending |
| 97-03-01 | 03 | 2 | SCOPE-01 | T-97-04 | Explicit banned capability classes and scope-reopen policy are present in planning truth | static-check | `rg "autocomplete|vector|multi-backend|new public runtime API|evidence-gated" .planning/PROJECT.md .planning/STATE.md` | ✅ | ⬜ pending |
| 97-04-01 | 04 | 2 | TRUTH-01,TRUTH-02,TRUTH-03 | T-97-05 | Freeze-critical docs contradictions are resolved without widening to full reconciliation | targeted-tests | `mix test test/scrypath/docs_contract_test.exs` | ✅ | ⬜ pending |
| 97-05-01 | 05 | 3 | TRUTH-01,TRUTH-02,TRUTH-03,SCOPE-01 | T-97-06 | `mix verify.phase97` exists, is documented, and enforces focused contract guardrails | gate-test | `mix test test/mix/tasks/verify.phase97_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/verify.phase97_test.exs` — focused gate behavior and no-args contract
- [ ] `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-TRACEABILITY.md` — requirement to statement mapping artifact
- [ ] `lib/mix/tasks/verify.phase97.ex` — phase verification entrypoint

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Canonical wording remains precise and non-ambiguous for adopters | TRUTH-01, TRUTH-02, TRUTH-03 | Semantic wording quality and ambiguity detection are hard to prove with exact-string automation alone | Read `README.md`, `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`, and `CONTRIBUTING.md` end-to-end; confirm one-hop routing and no contradictory policy prose |

---

## Canonical freeze anchor commands (TRUTH map)

| Task | Command |
|------|---------|
| 97-01-01 | `rg "CST-TRUTH-01-INSTALL|CST-TRUTH-02-RELEASE-MAIN|CST-TRUTH-03-SUPPORT-AUTHORITY" .planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-STATEMENTS.md` |
| 97-01-02 | `rg "^\\| TRUTH-01 \\||^\\| TRUTH-02 \\||^\\| TRUTH-03 \\|" .planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTRACT-TRACEABILITY.md` |
| 97-01-03 | `rg "97-CONTRACT-STATEMENTS\\.md|97-CONTRACT-TRACEABILITY\\.md|CST-TRUTH-01-INSTALL|TRUTH-01" .planning/phases/97-canonical-contract-freeze-and-scope-guard/97-CONTEXT.md .planning/phases/97-canonical-contract-freeze-and-scope-guard/97-VALIDATION.md` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
