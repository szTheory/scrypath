# Phase 36: Hierarchical facets - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `36-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-19
**Phase:** 36 — Hierarchical facets
**Areas discussed:** Declaration and settings; `%Facets{}` / runtime keys; Rollout and compatibility; Documentation split (36 vs 38)
**Mode:** User selected **all** areas and requested parallel subagent research + one-shot synthesis (no per-turn interactive Q&A).

---

## 1. Declaration and settings

| Approach | Description | Selected |
|----------|-------------|----------|
| A — Wire-faithful explicit attributes | `faceting: [attributes: [:"categories.lvl0", …]]` only | ✓ (canonical) |
| B — Nested keyword tree only | Tree in `faceting:` without normalized list | |
| C — String paths as primary | `"categories.lvl0"` in attributes | |
| D — Sugar expands to wire list | `hierarchy:` → expanded `attributes:` | ✓ (optional, with D-04) |
| E — Virtual facet id | Single atom mapping to many wire fields | Deferred (out of scope / risks second namespace) |

**User's choice:** Research-backed recommendation — **D + A**: canonical explicit list, optional compile-time sugar, **no** string-keyed primary surface.

**Notes:** Meilisearch hierarchy is **multiple filterable attributes** + standard `facets` / `facetDistribution` keys. Lessons: Algolia/InstantSearch explicit attribute lists “did it right”; Typesense “two places to declare” and Searchkick runtime-only patterns are footguns to avoid.

---

## 2. `%Facets{}` and runtime keys

| Approach | Description | Selected |
|----------|-------------|----------|
| A — Dotted atoms in `distribution` | Same atoms as `facets:` / `facet_filter:` | ✓ |
| B — Nested map tree in `%Facets{}` | UI-shaped tree | |
| C — String keys in `%Facets{}` | JSON mirror | |
| D — Composite encoded keys | Custom key grammar | |
| E — Path struct in every `Bucket` | Parse `value` into segments | |

**User's choice:** **A** — keep `%Facets{}` struct; extend keys; **`Bucket.value`** stays wire-shaped string/number.

**Notes:** Matches `decode_facets/2` today; one identifier end-to-end; avoids stringly maps and ambiguous `>` parsing in core.

---

## 3. Rollout and compatibility

| Strategy | Description | Selected |
|----------|-------------|----------|
| A — Global implicit unlock | Allow dots for everyone | |
| B — Schema opt-in | Flag required to allow dotted facet attrs / sugar | ✓ |
| C — Structured entries only | Replace atom list | |
| D — Major-only | Big bang | |
| E — Env feature flag | Runtime config in host | |

**User's choice:** **B** + **minor SemVer bump** messaging (D-10, D-11) — default validation unchanged; hierarchical adopters opt in explicitly.

**Notes:** Protects FACET-01 “no regression” story; pairs with drift/test matrix guidance (D-12).

---

## 4. Documentation — Phase 36 vs 38

| Split | Phase 36 | Phase 38 |
|-------|----------|----------|
| Hierarchical shapes + Meilisearch limits + guide fix | ✓ | |
| `search_within_facet` API + composition tables | | ✓ |
| Full README / ExDoc facet-depth discoverability (`FACET-04`) | Minimal one-line OK if needed | ✓ |
| `docs_contract_test` for new public API strings | Minimal hierarchy anchors | ✓ (full) |

**User's choice:** **Extend** `guides/faceted-search-with-phoenix-liveview.md`; **thin** `docs_contract_test` additions in 36; **defer** FACET-04 closure to 38 per traceability.

---

## Claude's Discretion

- Exact opt-in keyword name under `faceting:` (see CONTEXT `<decisions>`).
- Submodule/file layout for expansion helpers.

## Deferred Ideas

- Phase 37 disjunctive counts; Phase 38 `search_within_facet` + FACET-04; virtual facet ids; optional path-parsing helpers for UI.
