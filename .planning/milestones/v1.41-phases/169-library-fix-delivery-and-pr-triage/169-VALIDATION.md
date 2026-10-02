---
phase: "169"
slug: "library-fix-delivery-and-pr-triage"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-29"
---

# Phase 169 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (bundled with Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/scrypath/tenant_scope_contract_test.exs test/scrypath/facet_values_contract_test.exs` |
| **Full suite command** | `mix test --exclude integration --exclude docs_contract` |
| **Estimated runtime** | Not measured in this planning pass; measure on the first clean candidate run. |

---

## Sampling Rate

- **During each task:** Use its scoped automated command and explicit failure conditions; record actual included scenarios, source and runtime.
- **After code slices:** Run the fast suite after Plan 01 and the joined warnings-as-errors suite in Plan 04. Plans 02/03 run their named service proof. Record-only Plan 05 does not repeat runtime suites without a concrete invalidator.
- **Before `$gsd-verify-work`:** Required candidate checks and selected Phoenix/backend proofs must be green on the candidate SHA; confirm source-specific PR and post-merge evidence separately.
- **Max feedback latency:** Not established; do not assume the focused command completes under 30 seconds before measuring it on a warm checkout.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 169-01-01 | 01 | 1 | DELIV-02 | T-169-03, T-169-05 | Joined tenant/status facet request and retained public locks. | contract | mix test test/scrypath/facet_values_contract_test.exs --only facet_tenant_tracer | Existing case; task adds tag | ⬜ pending |
| 169-01-02 | 01 | 1 | DELIV-02 | T-169-01 | Three tenant paths and rejection before dispatch. | contract | mix test test/scrypath/tenant_scope_contract_test.exs | Yes | ⬜ pending |
| 169-01-03 | 01 | 1 | DELIV-02 | T-169-03 | Defaults, escaping, errors and scoped search. | contract | mix test test/scrypath/facet_values_contract_test.exs test/scrypath/search_within_facet_test.exs | Yes | ⬜ pending |
| 169-02-01 | 02 | 2 | DELIV-02 | T-169-02 | Persisted membership and scoped hydration. | host integration | Plan 02 Task 1: example mix test test/scrypath_demo/blog_tenant_search_test.exs | Yes | ⬜ pending |
| 169-02-02 | 02 | 2 | DELIV-02 | T-169-09 | Four existing live smoke modules retain explicit primary keys/task checks. | service integration | Plan 02 Task 2 names all four tracked test paths explicitly. | Yes | ⬜ pending |
| 169-02-03 | 02 | 2 | DELIV-02 | T-169-07, T-169-08 | Raw tenant evidence in path and fresh package modes. | service/package | mix verify.phoenix_example; mix verify.phoenix_example --package | Yes | ⬜ pending |
| 169-03-01 | 03 | 2 | DELIV-02 | T-169-04 | ID-scoped repair and exact task-to-visible search. | service integration | Plan 03 Task 1: integration-enabled bounded_repair tag. | Yes | ⬜ pending |
| 169-03-02 | 03 | 2 | DELIV-02 | T-169-10 | Repeat, empty scope and unaffected controls. | service integration | Plan 03 Task 2: bounded_repair_empty tag and mix verify.backend. | Yes | ⬜ pending |
| 169-04-01 | 04 | 3 | DELIV-02 | T-169-12, T-169-14 | Joined candidate, README claim agreement, named scenarios and exact-SHA closeout. | joined/hosted | Plan 04 Task 1 runs canonical fast, Phoenix, backend and ci_monitor commands after its narrow README edit. | Yes | ⬜ pending |
| 169-04-02 | 04 | 3 | DELIV-02 | T-169-13, T-169-14 | Protected merge and distinct squash-main proof. | GitHub/source | Plan 04 Task 2 queries PR/run and asserts MERGED and matching SHA. | Existing API | ⬜ pending |
| 169-05-01 | 05 | 4 | DELIV-02 | T-169-16 | Every observed path has one disposition. | record/source | Plan 05 Task 1 bounded Python snapshot/table check. | Command in plan | ⬜ pending |
| 169-05-02 | 05 | 4 | TRIAGE-01 | T-169-17, T-169-18 | Ten rows with current identity and reasons/triggers. | GitHub/record | Plan 05 Task 2 bounded Python table/live head/base/state check. | Command in plan | ⬜ pending |
| 169-05-03 | 05 | 4 | DELIV-02, TRIAGE-01 | T-169-19 | Canonical pointers and truthful patch handoff. | record/source | Plan 05 Task 3 pointer/requirement check and live PR query. | Command in plan | ⬜ pending |

Candidate, PR merge-ref, squash-merged `main`, locally built package, and published package evidence remain distinct. Historical semantic receipts are reusable only after the relevant-source comparison recorded in the plan.

---

## Wave 0 Requirements

- [ ] Create an isolated writable candidate from refreshed public `main`; do not use the accumulated local branch as the delivery unit.
- [ ] Select the owned source and evidence inputs, and record the measured source identities before editing or reusing historical receipts.
- [ ] Existing ExUnit, Phoenix, backend, package, and protected CI infrastructure is available; no new test framework or required CI lane is planned.

---

## Semantic Review Boundaries

These are evidence/authorization judgments, not post-implementation software UAT. Structural commands check factual completeness and current identities; reviewers must still assess cited reasons. No fabricated approval is permitted.

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Evidence-gated PR disposition | TRIAGE-01 | Whether an update has sufficient project value requires a documented maintainer judgment over refreshed change, compatibility, security, and check evidence. | Apply the approved D-01–D-04 gate to each frozen PR; record the evidence, disposition, and revisit trigger. Do not treat a green check or PR age alone as sufficient. |
| Protected review and merge policy | DELIV-02 | GitHub review authorization is enforced by repository policy and cannot be proven by a local test or simulated reviewer. | Use actual repository-required review and checks; record the PR merge ref and subsequent `main` SHA separately. |

---

## Validation Sign-Off

- [x] All 13 plan tasks have an automated command with immediately following failure conditions.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing or isolated-candidate prerequisites.
- [ ] No watch-mode flags.
- [ ] Measure warm-checkout feedback latency before claiming a sub-30-second quick run.
- [ ] Set `nyquist_compliant: true` only after validation tasks and commands are confirmed against the final plans.

**Planning breakdown:** approved by the user; executable/runtime evidence remains pending. Standard summaries own baseline, scenario, delivery and disposition records. No standalone delivery inventory or readiness assessment is planned.
