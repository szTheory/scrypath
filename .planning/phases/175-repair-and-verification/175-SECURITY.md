---
phase: "175"
slug: "repair-and-verification"
status: verified
threats_open: 0
asvs_level: 1
block_on: high
created: "2026-10-11"
---

# Phase 175 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| URL/receipt → LiveView | Selected schema and recovery handle remain untrusted until current allowlist, host context, generation, and receipt identity checks pass. | Schema, host, generation, job, attempt, and task identity |
| Queue/backend/document readers → rendered result | Partial, stale, missing, or cross-target observations must not become a success claim. | Task status and UID, active index, expected document identity/effect, observation errors |
| Browser event/URL → promotion mutation | Confirmation, selector values, and disabled UI state are not authorization; current host gate and eligibility checks decide. | Selected schema/index pair and mutation event |
| Disposable browser fixture → mounted Ops actions | Fixture inputs and backend results can be stale or cross-target and must correlate with the selected operation. | Schema, live/target indexes, task UID, fixture document |
| Rendered operational values → browser | Long identifiers and reasons must remain escaped and readable at narrow widths. | Backend-controlled IDs and error/reason strings |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-175-01 | Spoofing | Recovery receipt and selected schema | high | mitigate | Keep schema selection allowlisted and bind recovery receipts/results to host, generation, job, and task identity. Forged schema and stale-generation behavior is covered in `sync_drift_live_test.exs` (`schema selector rejects non-allowlisted module strings without creating atoms`; stale observer results cannot replace the current schema). | closed |
| T-175-02 | Tampering | Document freshness presentation | high | mitigate | A checked result requires the receipt's expected identity/effect and an exact read from the resolved active index. Missing expected identity, wrong index/document, or mismatched payload cannot render verified; covered by `document_observation_test.exs` and `sync_drift_live_test.exs`. | closed |
| T-175-03 | Repudiation | Asynchronous recovery outcome | medium | mitigate | Render exact job, attempt, task UID, schema, and index with the outcome; keep prior observed evidence/time while refresh is pending or unknown. Covered by the recovery lifecycle and refresh-retention LiveView tests. | closed |
| T-175-04 | Elevation of privilege | Confirmed index swap | high | mitigate | `swap_live/1` rechecks allowlist, current promotion eligibility, and the existing host authorization gate at the mutation boundary; forged, replayed, impersonated, and stale-sudo events are covered in `sync_drift_live_test.exs`. | closed |
| T-175-05 | Tampering | Promotion task/index/document correlation | high | mitigate | Completion requires the exact task UID/type/status, current generation, live/target pair, and fresh post-swap evidence for the selected live index; absent or mismatched document evidence remains unchecked. Focused LiveView and document-observation tests cover task, index, and effect mismatches. | closed |
| T-175-06 | Repudiation | Observer timeout and expiry | medium | mitigate | Bounded observation timeouts and expired/unavailable evidence remain unknown while retaining the task UID; same-UID refresh does not issue another swap. Covered by observer and mounted refresh tests. | closed |
| T-175-07 | Tampering | Mounted operation identity | high | mitigate | The disposable mounted journey compares the displayed UID and selected schema/index with the queried task, active alias, and seeded document; cross-target probes are rejected. Final mounted proof passed 4/4 browser checks. | closed |
| T-175-08 | Spoofing | Browser controls and confirmation | high | mitigate | Rendered selector and confirmation paths are exercised, while server-side host/eligibility checks remain authoritative even for forged or stale events. Focused LiveView tests and final disposable mounted proof passed. | closed |
| T-175-09 | Information disclosure | Long identity and error text | low | mitigate | HEEx retains escaped rendering; explicit wrapping rules preserve full identifiers/reasons in narrow layouts and both themes. Mounted geometry assertions and contrast verification passed with zero AA failures. | closed |
| T-175-10 | Tampering | Prepared-target document evidence | high | mitigate | Keep receipt schema/index/endpoint correlation and propagate every non-verified applicable effect observation. Correlated mismatch, unavailable-source, and unavailable-read tests leave promotion unconfirmed; no-applicable-effect remains explicitly not checked. | closed |
| T-175-11 | Repudiation | Promotion task versus observer outcome | medium | mitigate | Preserve task UID and receipt identity; render a succeeded swap separately from an unconfirmed document observation and its reason. Same-task refresh asserts `[991, 991]` and zero swap calls. | closed |
| T-175-SC | Tampering | Dependency/package changes | high | mitigate | No dependency manifests or lockfiles changed and no package was installed by the Phase 175 gap-closure work. The `verify.ops_ui` retry reported all dependencies unchanged. | closed |

*Status: all 12 registered threats closed; no open threats.*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).* 

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-11 | 9 | 9 | 0 | Codex orchestrator (ASVS L1, plan-authored register) |
| 2026-10-11 | 12 | 12 | 0 | GSD security audit (ASVS L1; Phase 175-04 mitigations rechecked) |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-11

## Security Audit 2026-10-11

| Metric | Count |
|---|---|
| Threats found | 9 |
| Closed | 9 |
| Open | 0 |

## Final Security Audit 2026-10-11

| Metric | Count |
|---|---|
| Threats found | 12 |
| Closed | 12 |
| Open | 0 |
