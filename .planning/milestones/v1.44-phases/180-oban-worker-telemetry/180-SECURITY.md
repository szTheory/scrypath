---
phase: "180"
slug: "oban-worker-telemetry"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-10-25"
---

# Phase 180 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Oban job args -> worker | Job args are stored, editable input; decode tags can carry untrusted values | schema names, ids, free-text cancel detail |
| worker -> telemetry handlers / metrics backends | Metadata leaves the library into host handlers, reporters and dashboards | atoms, integers, modules, index string |
| Meilisearch response -> Oban errors column | Backend response bodies can echo document content | HTTP status and body (body now dropped on 4xx) |
| Published docs -> adopters | Adopters attach handlers to the names and keys the guide documents | event names, metadata key sets |
| Library source -> published contract | Adopter handlers rely on the guide matching emitted events | event catalog |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-180-01 | Information disclosure | worker span / missing_removed metadata | high | mitigate | Metadata limited to atoms, integers, modules and the index string; `cancel_reason/1` keeps only the atom head (`lib/scrypath/telemetry.ex:97-101`); D-08 walk test rejects tuple/list values (`test/scrypath/oban/worker_telemetry_test.exs:415`) | closed |
| T-180-02 | Denial of service | `Scrypath.Telemetry` cancel_reason/1 | high | mitigate | Pattern-matches existing atoms, falls back to `:other`; no atom creation from job input; `{:cancel, "free text"}` -> `:other` case (`test/scrypath/telemetry_test.exs:362`) | closed |
| T-180-03 | Denial of service (observability backend) | start metadata keys | medium | mitigate | `start_metadata/3` in both workers carries no job_id, queue or id list; `document_count` is `Chunks.distinct_count/1` (`lib/scrypath/oban/delete_worker.ex:31-37`) | closed |
| T-180-04 | Repudiation | raising backend path | low | mitigate | Span re-raises after `:exception`; `assert_raise` in worker telemetry tests (lines 134, 269) | closed |
| T-180-05 | Information disclosure | RelatedWorker `job_result/1` 4xx clause | high | mitigate | 4xx returns `{:cancel, {:http_error, status}}`, body discarded (`lib/scrypath/sync/related_worker.ex:81-82`); test pins exact tuple (`test/scrypath/sync/related_worker_test.exs:503`) | closed |
| T-180-06 | Tampering (contract drift) | guides/telemetry.md vs lib emit sites | medium | transfer | Transferred to plan 180-03 contract test (`test/scrypath/telemetry_contract_test.exs`), core CI lane | closed |
| T-180-07 | Information disclosure | guide guidance on tags | low | mitigate | Cardinality section forbids ids, bodies and job ids as tags; exception `reason` documented as diagnostic only (`guides/telemetry.md:82-84`) | closed |
| T-180-08 | Tampering (silent drift) | telemetry_contract_test.exs CI placement | high | mitigate | File has no `@moduletag`/`@tag`/`docs_contract`, so the core lane runs it | closed |
| T-180-09 | Tampering (bypass) | computed event names in lib/ | medium | mitigate | AST guard with one-entry `@allowlist` plus stale-allowlist assertion (`test/scrypath/telemetry_contract_test.exs:17,209-218`) | closed |
| T-180-10 | Repudiation | key contract never firing | medium | mitigate | Coverage assertion requires each worker event phase to be observed (`test/scrypath/telemetry_contract_test.exs:312`) | closed |
| T-180-SC | Tampering | npm/pip/cargo/hex installs | low | accept | No packages installed; `mix.lock` unchanged across the phase | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-180-01 | T-180-SC | Phase installs no dependencies; `mix.lock` diff is empty | plan-time disposition (180-01/02/03 PLAN threat models) | 2026-10-25 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-25 | 11 | 11 | 0 | gsd-secure-phase (ASVS L1 grep verification, orchestrator) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-25
