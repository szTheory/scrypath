# Phase 21: Multi-Index Search - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `21-CONTEXT.md` — this log preserves research synthesis and alternatives considered.

**Date:** 2026-04-17
**Phase:** 21 — Multi-Index Search
**Areas discussed:** Guide emphasis; `search_many!/2`; duplicate schema entries; `federation` field; CI/test strategy; partial-failure guide UX
**Mode:** User requested all six areas in one shot with parallel research subagents; orchestrator synthesized into `21-CONTEXT.md`.

---

## 1. Guide emphasis (dashboard vs global search)

| Option | Description | Selected |
|--------|-------------|----------|
| Dashboard-first only | Multi-section, different text/filters per schema | ✓ (primary) |
| Omnibox-first | Single `q` as main story | |
| Split (recommended) | Dashboard primary + labeled omnibox recipe | ✓ (cohesive) |

**User's choice:** Research-synthesized — dashboard-first + secondary same-`q` recipe (tuple API only), URL-sync per Phase 20 D-02, namespaced params for mixed queries.
**Notes:** Avoid Algolia-style merged relevance promises; cross-links to faceting + sync guides.

---

## 2. `search_many!/2`

| Option | Description | Selected |
|--------|-------------|----------|
| Ship bang | Unwrap `{:ok, _}`; raise on `{:error, _}`; partial `failures` stay on struct | ✓ |
| Defer | Smaller first release | |
| Omit | No bang | |

**User's choice:** Ship for parity with `search!/3`; document that `!` does not clear `failures:`.
**Notes:** Optional future `search_many_strict!/2` explicitly deferred.

---

## 3. Duplicate schema entries

| Option | Description | Selected |
|--------|-------------|----------|
| Allow duplicates | `ordered` full fidelity; `by_schema` last-wins `Enum.into` | ✓ |
| Reject duplicates | `by_schema` unambiguous one key | |

**User's choice:** Allow; document `ordered` as source of truth for UI; MULTI-05 unchanged as equality invariant.

---

## 4. `federation` field content

| Option | Description | Selected |
|--------|-------------|----------|
| Raw Meilisearch JSON | Forward camelCase map | |
| Scrypath struct | Snake_case, versioned fields, `nil` when misleading | ✓ |

**User's choice:** Typed `%MultiSearchResult.Federation{}` (or equivalent); raw under `Scrypath.Meilisearch.*`; `nil` `federation` default on partial failure envelope.

---

## 5. CI / test strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Req.Test + unit + FakeBackend | Default CI, no Docker | ✓ (bulk) |
| Tagged live Meilisearch | MULTI-08 and version-sensitive edges | ✓ (thin) |
| Live-only | High flake, slow PRs | |

**User's choice:** Same pyramid as Phase 20 D-03; concrete file list in CONTEXT D-05.

---

## 6. Partial-failure guide UX

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal banner | Non-empty `failures` only | |
| Rich pedagogy | Two full demos + validation table + a11y + mapper | ✓ |

**User's choice:** Full demos for hydration timeout + transport; validation in table; `user_message/2`; `aria-live="polite"`; dev logging for raw `reason`.

---

## Claude's Discretion

- Exact `Federation` field list after wire verification
- Fixture layout vs inline JSON size threshold

## Deferred Ideas

- `search_many_strict!/2`
- `strict_unique_schemas?`
- v1.4 backlog items from roadmap (cross-schema ranking, `:all`, merged facets)
