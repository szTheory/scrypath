---
phase: 80
slug: public-query-toolkit-contract
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-22
---

# Phase 80 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| untrusted request params -> `Scrypath.QueryParams` | Browser-shaped request data enters the public toolkit edge here. | User-controlled query text plus top-level search option envelopes |
| public toolkit facade -> internal caster | Only recognized top-level keys should cross into the normalized public plain-data shape. | `q` / `text`, `filter`, `sort`, `page`, `facets`, `facet_filter`, `per_query` |
| toolkit output -> `Scrypath.search/3` | Prepared plain data crosses into validated runtime execution here. | `{text, keyword_opts}` for the canonical search runtime |
| runtime query struct -> Meilisearch payload | The adapter must preserve the defended payload grammar when fed by toolkit-produced args. | Internal `%Scrypath.Query{}` fields mapped to Meilisearch payload keys |
| public docs -> library consumers | Wording must not freeze internal runtime details or imply a second executor surface. | Public API guidance and request-edge usage expectations |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-80-01 | D | `lib/scrypath/query_params/caster.ex` | mitigate | `Caster.cast/1` maps only explicit known top-level keys, uses direct key matching, and never calls `String.to_atom/1`; nested request-style values are rejected with `ArgumentError`. | closed |
| T-80-02 | I | `lib/scrypath/query_params.ex` | mitigate | The public moduledoc states `%Scrypath.Query{}` remains internal normalized query state, and the public contract is a plain data map plus `to_search_args/1`. | closed |
| T-80-03 | S | `lib/scrypath/query_params.ex` | mitigate | The toolkit exports `cast/1` and `to_search_args/1` only; tests explicitly refute any `search/*` public helper and the module does not call `Scrypath.search/3`. | closed |
| T-80-04 | T | `test/scrypath/search_test.exs` | mitigate | Runtime parity tests prove toolkit-produced args and direct calls converge to the same `%Scrypath.Query{}` through the common `Scrypath.search/3` path. | closed |
| T-80-05 | T | `test/scrypath/meilisearch/query_test.exs` | mitigate | Payload parity tests prove toolkit-fed runtime queries preserve the existing Meilisearch key grammar, including `filter`, `sort`, `facets`, `page`, and `facetFilters`. | closed |
| T-80-06 | S | `lib/scrypath.ex` | mitigate | Root docs describe `Scrypath.QueryParams` as request-edge preparation only and keep `Scrypath.search/3` as the sole canonical executor owned by app contexts. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-22 | 6 | 6 | 0 | Codex (`$gsd-secure-phase`) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-22
