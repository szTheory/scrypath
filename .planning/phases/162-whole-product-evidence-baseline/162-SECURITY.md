---
phase: "162"
slug: "whole-product-evidence-baseline"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-25"
---

# Phase 162 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Canonical receipt to baseline assertion | Archived sources and hosted runs describe bounded SHAs, tuples, and scenarios; claim rows must not overstate them. | Public planning evidence, run identifiers, versions, and source links |
| Host app to Scrypath | Authorization, policy, and result presentation remain application-owned. | Search requests, result metadata, and host policy context |
| Operator evidence to baseline | Diagnostic records may contain sensitive values; the baseline should link sanitized evidence without copying credentials or payloads. | Sanitized summaries and evidence references |
| CI/release receipt to support claim | Exact-SHA, package, and selected-tuple evidence must remain scoped to the tested artifact and environment. | Public CI receipts, package versions, compatibility tuples |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-162-01 | Tampering | C-01 receipt mapping | high | mitigate | C-01 links the Phase 160 source/result and states its SHA, service tuple, exercised scenarios, opt-outs, and advisory posture. | closed |
| T-162-02 | Information disclosure | Evidence snippets | medium | mitigate | Baseline rows link canonical evidence and record sanitized result summaries; no credentials or raw payloads are copied. | closed |
| T-162-03 | Elevation of privilege | Host policy claim | medium | mitigate | Baseline states that authorization and presentation policy belong to the host application at the Phoenix/context seam. | closed |
| T-162-04 | Tampering | C-07 through C-12 async claims | high | mitigate | Rows separate write/enqueue, backend task completion, and visible search results, and cite only the receipt for the exercised scenario. | closed |
| T-162-05 | Information disclosure | C-13 through C-17 operator evidence | high | mitigate | Rows link canonical sanitized operator evidence and record metadata without credentials or raw payload values. | closed |
| T-162-06 | Repudiation | Recovery outcome | medium | mitigate | Recovery evidence separates diagnosis, selected mutation, command/result, and observed outcome with provenance. | closed |
| T-162-07 | Tampering | C-18 through C-24 release/support claims | high | mitigate | Rows record exact receipt, SHA/version, selected tuple, invalidator, and CI enforcement posture. | closed |
| T-162-08 | Information disclosure | Security/privacy rows | high | mitigate | Security/privacy rows link sanitized sources/results and record boundaries without copying credentials or payload values. | closed |
| T-162-09 | Repudiation | Baseline completion | medium | mitigate | The 24-row audit checks source links, coverage, explicit evidence questions, and Phase 163/164 ownership. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-25 | 9 | 9 | 0 | Codex |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-25
