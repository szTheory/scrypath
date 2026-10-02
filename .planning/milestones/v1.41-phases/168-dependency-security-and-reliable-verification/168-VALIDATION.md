---
phase: "168"
slug: "dependency-security-and-reliable-verification"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-28"
---

# Phase 168 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing ExUnit and repository shell/CI harnesses |
| **Config file** | `mix.exs`, `test/test_helper.exs`, `.github/workflows/ci.yml` |
| **Quick run command** | `mix test test/mix/tasks/verify_phoenix_example_package_test.exs test/mix/tasks/verify_adopter_test.exs test/mix/tasks/verify_capability_test.exs test/scrypath/phase147_e2e_contract_test.exs` plus the new focused audit tests selected in the plan |
| **Full suite command** | `mix test --exclude integration --exclude docs_contract` |
| **Estimated runtime** | Not measured; record focused and full-suite duration during execution |

The host Elixir and Mix shims currently lack a selected runtime. Use an installed compatible toolchain or the repository's existing Docker tooling; do not change global runtime configuration to make this phase pass.

---

## Sampling Rate

- **After every task commit:** Run the focused service-free tests for the changed seam.
- **After every plan wave:** Run the full suite command above when source changes are present.
- **Before `$gsd-verify-work`:** Relevant required and named advisory/path-selected hosted checks must be green for the actual candidate source; post-merge evidence must identify public `main`.
- **Max feedback latency:** Measure the focused suite in Wave 0 and keep it service-free; no fixed latency target has been established.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Assign in PLAN | Dependency update | Assign in PLAN | MINT-01 | T-168-01 | Each of the four maintained locks resolves patched Mint and only the necessary compatible closure | Resolver + audit | In each project: `mix deps.update mint`, inspect lock diff, then `mix hex.audit` | Existing locks; commands are planned | ⬜ pending |
| Assign in PLAN | Phoenix graph proof | Assign in PLAN | MINT-02 | T-168-02 | Package staging preserves every source Hex entry while allowing only Scrypath provenance substitution; malformed or unexpected graph changes fail | ExUnit contract | Focused package and adopter tests from the quick command, plus task-owned comparator cases | Existing package/adopter tests; comparator cases to add | ⬜ pending |
| Assign in PLAN | Four-graph audit | Assign in PLAN | MINT-03 | T-168-03 | Explicit inventory cannot omit a maintained graph; each graph reports ignored, incomplete, fetch, or affected results; failures aggregate after all graphs are attempted; locks remain unchanged | ExUnit + command proof | Task-owned audit tests with injected subprocess runner; run the existing advisory lane once on the candidate | Audit tests/wiring are plan outputs | ⬜ pending |
| Assign in PLAN | Mounted readiness delivery | Assign in PLAN | DELIV-01 | T-168-04 | Setup processes cannot advertise transient endpoint readiness; final persistent server remains the sole persistent launch | ExUnit contract + mounted integration | `mix test --no-start test/scrypath/phase147_e2e_contract_test.exs`; `mix verify.ecommerce_mounted` | Existing focused regression and mounted verifier | ⬜ pending |
| Assign in PLAN | Delivery closeout | Assign in PLAN | MINT-01, MINT-02, DELIV-01 | T-168-05 | Receipts name candidate, relevant graph, required checks, named advisory/path-selected evidence, merge result, and post-merge `main` SHA separately | Hosted CI evidence | Existing required candidate checks; run the Ops proof on its applicable PR/main event; inspect named advisory/path-selected results; verify post-merge `main` | Existing CI/workflow | ⬜ pending |

---

## Wave 0 Requirements

- [ ] Add focused semantic lock-comparison coverage for preserved entries, the allowed Scrypath substitution, additions/removals, changed versions/checksums/source types, malformed syntax, and duplicate keys.
- [ ] Add repository audit orchestration tests for the explicit four-graph inventory, missing/duplicate entries, missing locks/tools, ignored findings, fetch/audit failures, attempt-all behavior, failure aggregation, lock preservation, and timing output.
- [ ] Identify the exact new source and test paths in the PLAN before execution; keep repository inventory/orchestration outside the shipped package surface.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Merge authority and actual integration into public `main` | DELIV-01 and MINT-01 | GitHub merge permission and branch protection are external governance gates; a prepared PR is not delivery | Preserve the required review/check policy. If merge is blocked, record the exact blocker and leave delivery incomplete. After merge, verify named checks and source SHA on `main`. |

All behavior assertions remain automated. No human UAT or advisory waiver substitutes for the required evidence.

---

## Validation Sign-Off

- [ ] All tasks in PLAN have an automated `<verify>` command or an explicit hosted-evidence dependency.
- [ ] Sampling continuity: no three consecutive implementation tasks lack focused automated verification.
- [ ] Wave 0 covers the identified MINT-02 and MINT-03 gaps.
- [ ] No watch-mode flags.
- [ ] Focused and full feedback latency measured during execution; runtime is recorded for the four-graph audit.
- [ ] Set `nyquist_compliant: true` only after the planned validation obligations are implemented and verified.

**Approval:** pending
