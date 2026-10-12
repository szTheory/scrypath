---
phase: "173"
slug: "shared-visual-foundation-and-operational-time"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-10"
---

# Phase 173 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser storage → theme state | Stored theme values may be arbitrary, and browser storage can be denied. | User preference string / storage errors |
| Test fixture → application | Phase-only deterministic routes must stay in test builds and separate from the retained preview. | Test schema, observation and failure fixture data |
| Backend/queue timestamp → operator UI | External timestamp text must be validated before it is displayed or copied. | ISO timestamp strings and observation snapshots |
| Observed backend/queue state → operator labels | Failed, unavailable and partial observations must not collapse into a false success. | Status, error reasons and server eligibility |
| Rendered timestamp → browser clipboard | Only validated source evidence may be copied, and browser denial must remain recoverable. | User-activated exact ISO clipboard write |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-173-01 | Tampering | Theme storage | low | mitigate | Normalize to system/light/dark and catch storage exceptions before setting appearance; Ops shell tests cover the stored preference path. | closed |
| T-173-02 | Information disclosure | Test fixture route | medium | mitigate | Fixture routes/providers are test-only; mounted and standalone browser proofs use a disposable Compose project with no published standalone host port and verify owned-resource cleanup. | closed |
| T-173-03 | Tampering | State timestamp normalization | medium | mitigate | Retain `source_iso` only when it parses and matches the normalized `DateTime`; tests reject mismatched source text and render escaped selectable evidence. | closed |
| T-173-04 | Repudiation | Retained observation time | medium | mitigate | Carry the source-local snapshot reference across failed refreshes and label unavailability without changing Checked time; LiveView and browser tests assert the prior age/evidence remains. | closed |
| T-173-05 | Spoofing | Status presentation | medium | mitigate | Production status renders explicit state text and source reasons; mounted and standalone status matrix covers healthy, failure, unavailable, empty, and partial observations. | closed |
| T-173-06 | Elevation of privilege | `OpsRefreshButton` | medium | mitigate | Server-rendered disabled eligibility remains authoritative after LiveView patches; the focused test exercises enabled → disabled → enabled and the browser suite verifies the busy lifecycle. | closed |
| T-173-07 | Spoofing | Clipboard feedback | medium | mitigate | Await `writeText` before success; resolved, rejected, and unavailable API outcomes are tested in both entrypoints, and failure remains persistent until dismissed. | closed |
| T-173-08 | Tampering | Timestamp payload | medium | mitigate | Copy data is the validated `State.source_iso`; browser proof checks the exact fractional seconds and offset and confirms the call came from user activation. | closed |
| T-173-SC | Tampering | Dependency installation | high | mitigate | No package installation or dependency change occurred; locked dependencies remained unchanged during verification. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on` count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).* 

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-10 | 9 | 9 | 0 | Codex phase executor (ASVS L1) |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-10

## Security Audit 2026-10-11

| Metric | Count |
|---|---|
| Threats found | 9 |
| Closed | 9 |
| Open | 0 |
