# Architecture Research

**Domain:** OPSUI as consumer of Scrypath
**Researched:** 2026-04-20
**Confidence:** HIGH

## Integration Picture

```
┌─────────────────────┐     path / Hex      ┌──────────────────┐
│  OPSUI Phoenix app  │ ───────────────────▶ │  scrypath (lib)  │
│  (LiveView routes)  │   Scrypath.* calls   │  Meilisearch     │
└─────────────────────┘                      └──────────────────┘
         │                                            │
         │  Telemetry subscribe (optional)           │
         ▼                                            ▼
   Low-cardinality aggregates                  Engine / tasks
```

## Major Components

1. **Router + live_session** — Namespaced `/ops` (or similar); authentication boundary (OPSUI-08).
2. **Context modules** — Thin adapters that call `Scrypath` functions and normalize structs for templates (no business logic fork).
3. **LiveViews by JTBD** — Dashboard (posture), Failed work, Sync status, Federation / multi-search lab, Settings/drift read-only views as needed.
4. **Presentation layer** — Components for hit lists, merge metadata, partial-failure banners; shared empty/error states.

## Data Flow

- **Read-mostly:** UI polls or refreshes on user action; avoid inventing background reconcilers.
- **Federation:** Use the same structs and ordering helpers the library documents (`MultiSearchResult`, merge projection) so UI cannot claim a sort the library does not guarantee.

## Build Order (for phases)

1. App shell + security + IA (enables safe iteration).
2. Posture + failed work + sync visibility (highest daily value).
3. Search / federation lab (depends on shell + trust in read paths).
4. Verification hardening + CI wiring.

## New vs Modified

| Area | New | Modified |
|------|-----|----------|
| Hex package | OPSUI app tree | No change to `mix.exs` publish surface unless explicitly adding an umbrella app |
| Scrypath core | — | Only if a **small** read API gap is proven; default is zero library feature work |

## Sources

- Library federation phases (39–41) and per-query phase (43) planning artifacts in `milestones/`
- `docs/search-backend-sre.md`

---
*Architecture research for: Scrypath v1.10 OPSUI*
*Researched: 2026-04-20*
