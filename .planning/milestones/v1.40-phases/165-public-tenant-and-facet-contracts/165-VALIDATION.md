---
phase: "165"
slug: "public-tenant-and-facet-contracts"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-26"
---

# Phase 165 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing ExUnit; local executable Elixir/Mix 1.19.5, OTP 28 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | One independent focused command per requirement in the per-task map |
| **Full suite command** | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test --exclude integration --exclude docs_contract` |
| **Estimated runtime** | Unmeasured; record the first focused run rather than assume a duration |

The focused test files are proposed by research and do not exist yet. Locally, apply the explicit asdf environment prefix shown above.

---

## Sampling Rate

- **After every task commit:** Run that task's focused contract test file.
- **After Plan 01:** Run applicable existing tenant and multi-search contributor tasks once.
- **After Plan 02:** Run the facet contributor task and one consolidated core gate, which already includes the fast suite; do not duplicate a full-suite run without a new change or failure.
- **Before `$gsd-verify-work`:** The full fast suite must be green.
- **Max feedback latency:** Unmeasured; record the first focused run rather than assume a duration.

Existing contributor tasks relevant to changes are `mix verify.phase94` and `mix verify.phase96`; include `mix verify.phase41` for multi-search changes. If an implementation changes Meilisearch integration code, follow the existing `mix verify.backend` policy and its documented local skip path without claiming live service proof. New verification lanes are out of scope.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 165-01-01 | 01 | 1 | API-01 | T-165-01 | Single public search retains tenant and ordinary filter | public contract / recording backend tracer | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/tenant_scope_contract_test.exs --only tenant_tracer` | created by task | ✅ pass |
| 165-01-02 | 01 | 1 | API-01 | T-165-01 | Shared multi-search/facet composition; invalid scope rejects before all dispatch | public contract / recording backend | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/tenant_scope_contract_test.exs` | depends on 165-01-01 | ✅ pass |
| 165-02-01 | 02 | 2 | API-02 | T-165-02 | Public defaults reach encoded HTTP with endpoint-compatible shape | public HTTP contract / Req.Test tracer | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/facet_values_contract_test.exs --only facet_defaults` | created by task | ✅ pass |
| 165-02-02 | 02 | 2 | API-02, API-01 | T-165-02, T-165-03 | Keyword/tenant predicates preserved; errors never broaden request | public HTTP contract / Req.Test | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix test test/scrypath/facet_values_contract_test.exs` | depends on 165-02-01 | ✅ pass |

The tenant and facet commands are independent. The tenant recorder must cover `search/3`, `search_many/2`, and `search_facet_values/4`, including shared multi-search tenant options and path-specific errors. The Req.Test case must enter through `search_facet_values/4` and check defaults and a nonempty documented keyword filter separately. Neither test alone establishes live service behavior.

---

## Wave 0 Requirements

- [x] `test/scrypath/tenant_scope_contract_test.exs` — created and executed in tracer task 165-01-01 before expansion task 165-01-02.
- [x] `test/scrypath/facet_values_contract_test.exs` — created and executed in tracer task 165-02-01 before expansion task 165-02-02.
- [ ] Reuse existing test helpers and fixtures; no framework install, live service, or new CI lane is required.

---

## Manual-Only Verifications

All phase behaviors have automated verification. No routine human UAT is required.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency recorded from focused runs
- [x] `nyquist_compliant: true` set in frontmatter

## Validation Audit 2026-09-26

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All four tasks map to executed automated probes. The plan-specific unit, Req.Test contract, contributor, and consolidated core receipts are recorded in the corresponding plan summaries. No human-only behavior remains in this phase's acceptance contract.

**Approval:** pending

## Planning alignment

Two plans, two waves, two tasks each. Plan 02 consumes Plan 01 only for one joined tenant/status facet HTTP assertion; its primary defaults and keyword probes use no tenant scope and remain independently executable. Tracer tasks create their own local test scaffold before running verification, so there is no separate foundation-only task. Every runnable automated command in the plans has an immediately following observable fails_when statement.

Use the existing rendered-client and query test files as supplemental regression in task 165-02-02. Primary acceptance remains public entry. Record exact source identities, measured focused durations and actual baseline/corrected outcomes during execution; all status boxes remain pending until evidence exists. Spec-less edge assumptions and descriptor-less prohibition flags are in 165-SOURCE-AUDIT.md.
