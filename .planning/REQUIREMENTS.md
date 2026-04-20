# Requirements: Scrypath

**Defined:** 2026-04-20  
**Milestone:** v1.8 — *Multi-index federation*  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.8 Requirements

### Federation (prefix: FED)

- [x] **FED-01**: Developer can run `search_many/2` with **documented federation scoring / weighting** (Meilisearch-native semantics where applicable) so **merged hit ordering** across indexes is **predictable, test-covered**, and reflected in the public result types (`%MultiSearchResult{}` and federation metadata) without breaking existing per-schema `%SearchResult{}` contracts for callers that only use `by_schema`.

- [x] **FED-02**: Developer can use an explicit **`:all` (or equivalent documented token)** to expand a multi-search over **all schemas intended for global search** per a **documented resolution rule** (e.g. application config or compile-time registration — exact mechanism is an implementation choice) with **clear cardinality rails**, **timeouts**, and **error tuples** when resolution is empty, ambiguous, or over limits.

- [x] **FED-03**: **Guides, README, and `docs_contract_test.exs` anchors** describe federation scoring, weighting, and `:all` behavior so adopters and **future operator UI** work can rely on stable wording and discoverability paths.

## v2+ / deferred requirements

### Operator UI (prefix: OPSUI)

- **OPSUI-01**: Optional **operator LiveView dashboard** (example app or separate package) over existing `Scrypath.*` visibility, telemetry, and **federation-shaped** multi-search results — **explicitly deferred** past v1.8 core delivery; v1.8 primitives (**FED-01..03**) are now complete in-repo, so UI work can proceed when prioritized.

## Out of scope (v1.8)

| Item | Reason |
|------|--------|
| **TUNE-PIPE-01** / **TUNE-01** per-query relevance pipeline | Separate design milestone; not required for federation merge semantics. |
| **First-class public multi-backend** | Product boundary unchanged (`PROJECT.md`). |
| **Vector / hybrid / personalization** | Still deferred globally. |
| **Built-in LiveView app in the core Hex package** | UI stays out of core; OPSUI-01 remains a follow-on surface. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUDT-01 | Phase 32; gap closure 33 | Complete |
| FED-01 | Phase 39 | Complete |
| FED-02 | Phase 40 | Complete |
| FED-03 | Phase 41 | Complete |

**Coverage:**

- v1.8 requirements: **3** total  
- Mapped to phases: **3**  
- Unmapped: **0**

---
*Requirements defined: 2026-04-20*  
*Last updated: 2026-04-20 after `/gsd-new-milestone` — v1.8 Multi-index federation*
