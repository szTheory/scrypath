---
phase: "165"
slug: public-tenant-and-facet-contracts
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-26"
---

# Phase 165 — Security

> Per-phase security contract: planned trust boundaries, threat mitigations, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|-----------|-------------|---------------|
| Public tenant option to backend query | Schema validation composes the supplied tenant value into the common filter before runtime configuration and dispatch. | Tenant field/value and ordinary search filters |
| Public common filter to Meilisearch JSON | Facet request construction converts validated keyword filters into the existing Meilisearch expression grammar with JSON-encoded literals. | Filter field names, operators, and values |
| Backend response to public caller | HTTP and transport failures remain explicit error reasons and do not trigger a broader fallback request. | Status/body or transport exception; submitted filter |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-165-01 | Tampering / Information disclosure | Tenant injection and three runtime extractors | high | mitigate | Public tests verify tenant predicates across search paths and reject undeclared or conflicting scope before dispatch; validated `tenant_scope` is excluded from strict runtime config. Evidence: `165-01-SUMMARY.md`, `test/scrypath/tenant_scope_contract_test.exs`. | closed |
| T-165-02 | Tampering / Information disclosure | `Client.facet_search/5` filter construction | high | mitigate | Public Req.Test cases verify keyword and tenant filters in encoded JSON, including quote/backslash literal escaping through the existing renderer. Evidence: `165-02-SUMMARY.md`, `test/scrypath/facet_values_contract_test.exs`. | closed |
| T-165-03 | Information disclosure | Facet HTTP/transport error propagation | high | mitigate | Public tests inspect the submitted predicate, preserve HTTP/timeout and bang reasons, count one request, and rule out an unfiltered fallback. Evidence: `165-02-SUMMARY.md`, `test/scrypath/facet_values_contract_test.exs`. | closed |

*Status: closed for each planned threat; no high-severity threats remain open.*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-26 | 3 | 3 | 0 | Codex, ASVS level 1 evidence check |

## Claim Limits

The tenant tests establish supplied-scope filter composition and pre-dispatch validation only. They do not establish actor identity, membership, trusted tenant derivation, authorization, or database response scoping. Req.Test establishes synchronous request construction and bounded no-fallback error behavior; live Meilisearch and package behavior for the corrected facet keyword scenario remain a Phase 166 handoff. Interruption and parallel backend execution semantics are unclaimed (EA-02).

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-26
