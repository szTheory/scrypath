---
phase: "174"
slug: "recovery-entry-and-diagnosis"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-10"
---

# Phase 174 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser query/selection → LiveView | Query values can be forged or become stale as the allowlist or live context changes. | Schema identifiers and recovery-selection state |
| LiveView → retry/delete action | Browser events are untrusted; current server state and host authorization decide eligibility. | Failed-work identity, retry intent, confirmation state |
| Recovery receipt → diagnosis route | A receipt must remain bound to its host, organization, schema, and generation. | Opaque receipt handle and schema context |
| Backend/queue failure → rendered operator UI | Failure text and metadata may be hostile and must not become markup or false success. | Failure reason, metadata, observed health |
| Dependency manifests → release artifact | Extra dependencies increase supply-chain surface. | Dependency and lockfile changes |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-174-01 | Tampering | Schema selection | high | mitigate | Resolve the requested schema against the current allowlist, clear invalid or stale selection, and compare canonical strings without creating atoms. Forged and removed-schema cases are covered by LiveView and mounted tests. | closed |
| T-174-02 | Tampering | Recovery receipt and diagnosis handoff | high | mitigate | Bind receipts to host, organization, schema, and generation; invalidate them when selection changes; revalidate allowlist and runtime context at the diagnosis destination. Tests cover mismatch, invalidation, and stale async results. | closed |
| T-174-03 | Elevation of privilege | Retry and delete confirmation | high | mitigate | Re-read the server-side failed row, derive the current recovery action, and pass sensitive actions through host authorization. Tests cover unavailable work, denied authorization, stale confirmation, and absence of an unauthorized job insert. | closed |
| T-174-04 | Tampering | Failure reason and metadata rendering | high | mitigate | Render through HEEx escaping and the established code-block component. Hostile-value tests assert literal escaped text and the absence of injected script markup. | closed |
| T-174-05 | Tampering | Control Room health state | medium | mitigate | Healthy wording requires a complete observation; an incomplete refresh retains the last successful observation and does not report recovery. LiveView tests cover this failure direction. | closed |
| T-174-06 | Tampering | Search health and schema handoff | high | mitigate | Render observed failure safely and construct the destination through the exact-schema path helper. Tests cover exact-schema routing and escaped hostile reasons. | closed |
| T-174-SC | Supply chain | Phase dependency changes | high | mitigate | No package manifests, lockfiles, or dependency versions changed across the three plans. | closed |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-10 | 7 | 7 | 0 | Codex security auditor (ASVS L1) |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-10

## Security Audit 2026-10-13

| Metric | Count |
|---|---|
| Threats found | 7 |
| Closed | 7 |
| Open | 0 |
