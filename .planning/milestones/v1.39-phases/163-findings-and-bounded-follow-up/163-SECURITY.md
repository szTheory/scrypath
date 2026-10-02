---
phase: "163"
slug: "findings-and-bounded-follow-up"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-25"
---

# Phase 163 — Security

> Security review of the phase's evidence handling and structural checker. This is not a product security certification.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Archived/source evidence → canonical baseline | Historical evidence could be misrepresented as current. | Claim links, commit SHAs, hosted run identifiers |
| Findings links and command text → checker | Repository content must not become out-of-repository access or shell execution. | Markdown paths and inert command strings |
| Hosted logs → durable evidence | Unrelated or sensitive log data must not be copied into planning artifacts. | Selected result metadata and provenance |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-163-01 | Tampering / Repudiation | C-21 and C-17 provenance | high | mitigate | Findings record named run/SHA/environment/oracle boundaries and limit claims to those receipts; see [findings](163-FINDINGS.md#c-15c-17-operational-evidence-boundary). | closed |
| T-163-02 | Tampering | check_findings.py | medium | mitigate | Local links are resolved and constrained to repository root; absolute and escaping links have negative fixtures. Commands are parsed as Markdown data and never executed. | closed |
| T-163-03 | Information disclosure | Findings and baseline amendments | high | mitigate | Artifacts retain targeted provenance and explicitly exclude environment dumps and credential-bearing data; see [C-21 chronology](163-FINDINGS.md#c-21-chronology-and-boundary). | closed |
| T-163-04 | Tampering | Findings classification and rank | high | mitigate | Required claim/finding fields separate evidence, impact, confidence, and costs; source-only concerns remain bounded evidence gaps. | closed |
| T-163-05 | Spoofing / Repudiation | Accepted-risk finding cards | high | mitigate | Accepted risk requires decision-source link, owner, and accepted risk state; no owner approval is inferred. | closed |
| T-163-06 | Tampering | Disposition summary | medium | mitigate | Summary sets are derived from F/K/P cards and compared using the field-specific identifier prefix. | closed |
| T-163-07 | Elevation of privilege | Candidate scope authority | high | mitigate | Candidate cards require scope authority, exclusions, owner boundary, route rationale, and material finding references; none qualifies in the completed inventory. | closed |
| T-163-08 | Tampering / Repudiation | Claim-proof records | high | mitigate | Proof cards require fixture/oracle/receipt fields and are nested beneath the owning candidate; acceptance claims enforce ownership. | closed |
| T-163-09 | Tampering | Phase 164 handoff | medium | mitigate | Complete mode requires explicit residual gaps, unresolved owner decisions, and Phase 164 gate ownership. | closed |

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-25 | 9 | 9 | 0 | Phase execution review |

## Sign-Off

- [x] All threats have a disposition
- [x] Accepted risks documented (none)
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-25
