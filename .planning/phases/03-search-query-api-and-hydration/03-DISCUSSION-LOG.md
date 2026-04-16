# Phase 3: Search Query API and Hydration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 3-Search Query API and Hydration
**Areas discussed:** Search API surface, query input shape, result and hydration shape, backend escape hatch

---

## Search API Surface

| Option | Description | Selected |
|--------|-------------|----------|
| Schema-injected runtime API | Add model-centric calls such as `Post.search/2` or a fluent builder on schemas | |
| Fluent chain builder | Use Searchkick-style chaining for filters, sort, pagination, and load behavior | |
| Top-level explicit `Scrypath.*` API | Keep search under `Scrypath.search/3` with explicit arguments and keyword options | ✓ |

**User's choice:** Top-level explicit `Scrypath.*` API.
**Notes:** The user asked for a one-shot coherent recommendation set optimized for great DX, least surprise, and strong architecture. The final recommendation rejected schema magic and kept runtime behavior under `Scrypath.*`.

---

## Query Input Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Raw backend payload | Pass Meilisearch-shaped maps or raw filter strings directly through the common API | |
| Public builder or map object | Use a public query object or builder as the main v1 interface | |
| Small Elixir option DSL | Use `filter:`, `sort:`, and `page:` keyword options, then normalize internally to a query struct | ✓ |

**User's choice:** Small Elixir option DSL.
**Notes:** The recommendation set favored structured Elixir data over raw backend syntax, with internal normalization to `%Scrypath.Query{}` for validation and adapter translation.

---

## Result and Hydration Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Raw-first API | Return raw hits only and require callers to hydrate separately | |
| Hydrated-only API | Return only Ecto records, with raw hit access hidden or secondary | |
| Stable result envelope | Return a stable result struct containing hydrated records, raw hits, metadata, and missing-hit visibility | ✓ |

**User's choice:** Stable result envelope.
**Notes:** The recommendation explicitly required one stable result shape, batched hydration, preserved hit ordering, and explicit `missing_ids` so stale index rows remain visible.

---

## Backend Escape Hatch

| Option | Description | Selected |
|--------|-------------|----------|
| Common API with passthrough backend options | Keep one surface and let backend-native behavior flow through opaque options | |
| Common path plus explicit `Scrypath.Meilisearch.*` namespace | Keep a small common path and expose richer Meilisearch-native query behavior under an explicit backend namespace | ✓ |
| Backend-native modules only | Skip the common search path and use backend-specific modules for most search behavior | |

**User's choice:** Common path plus explicit `Scrypath.Meilisearch.*` namespace.
**Notes:** The final recommendation kept `Scrypath.search/3` small and explicit while reserving richer Meilisearch query power for `Scrypath.Meilisearch.search/3`.

---

## the agent's Discretion

- Exact names and field layout of the internal query and result structs
- Exact structured-filter syntax for ranges and boolean composition
- Exact adapter-boundary translation between the common query struct and Meilisearch-native payloads

## Deferred Ideas

- Richer common-path support for facets, multisearch, and backend-native search features
- Generic post-search hydration hooks in the common API
- Public multi-backend query parity in v1
