# Phase 46 — Technical research

**Question:** What do we need to know to plan bounded search + federation-honest OPSUI well?

## Library contracts

- **`Scrypath.search/3`** — single-schema path; options validated via **`Scrypath.Options.validate_search_options/2`**; **`page.size`** is part of search options vocabulary.
- **`Scrypath.search_many/2`** — normalizes entries through **`Scrypath.MultiSearch.Entries.normalize/2`** with defaults **`max_schemas: 10`**, hard ceiling **`@max_page_size 50`** for per-entry page sizes; errors include **`{:invalid_options, {:page_size, n, 50}}`**, **`{:error, {:too_many_schemas, count, max}}`**, **`{:invalid_options, {:all_expansion, _}}`** (see phase 40).
- **`%Scrypath.MultiSearchResult{}`** — **`ordered`**, **`by_schema`**, **`failures`**, optional **`federation`**, **`merge_hit_order`**; **`merge_projection/1`** returns `[]` when **`merge_hit_order`** is `nil` (sequential / non-federated fallback).

## OPSUI constraints (from CONTEXT + UI-SPEC)

- **Single allowlist** — **`ScrypathOps.Schemas.allowlist/0`** only for schema pickers; same as posture / drift / failed-sync.
- **Default mode** — single-index on first load; **`?mode=multi`** (and optional **`?mode=single`**) via **`handle_params/3`** + **`push_patch`**; **no `search_many` on mount**.
- **Copy / tokens** — locked strings in **`46-UI-SPEC.md`** (banner, federation caption, `:all` footnote, partial-failure banner, hard error panel).
- **Inspector** — render hits from **`results.ordered`** only; merge / weights / failures panels per spec disclosure defaults (**D-12–D-17**).

## Testability

- **`scrypath_ops`** has **no Mox** today; phase 45 tests swap **`Application.put_env`** on **`:meilisearch_client`** and stub schemas under **`ScrypathOps.Test`**.
- Search LiveView should call **`Scrypath`** through a **small runtime-configurable adapter module** (default delegates to **`Scrypath`**) so tests can **`put_env(:scrypath_ops, :search_playground_adapter, StubModule)`** without HTTP.

## Risks

- **Silent clamp** — forbidden for page size over max; must surface as validation / hard error before calling the library (CONTEXT **D-02**).
- **Telemetry** — only low-cardinality events (**`:single` / `:multi`**, coarse counts); never raw query strings (**D-05**, **`docs/search-backend-sre.md`**).

## Validation Architecture

Execution should keep a **tight feedback loop**:

| Layer | Command | When |
|-------|---------|------|
| Compile | `cd scrypath_ops && mix compile` | After each task touching `lib/` |
| Unit | `cd scrypath_ops && mix test test/scrypath_ops/search_playground_test.exs` (or path chosen by executor for config/adapter) | After config + adapter tasks |
| LiveView | `cd scrypath_ops && mix test test/scrypath_ops_web/live/search_live_test.exs` | After SearchLive + tests land |
| Full ops slice | `cd scrypath_ops && mix test` | End of each wave |

**Manual spot-check (optional):** Load **`/ops/search`** in dev with demo schemas; confirm banner + mode toggle + inspector match **`46-UI-SPEC.md`** (no automated substitute for visual skim).

**Contract anchors:** Tests **`assert html =~`** for at least these literals from UI-SPEC: **`Non-production search playground`**, **`Merged order is a federation view`**, **`Run sample searches`**, **`Some indexes did not return results.`** (partial path).

---

## RESEARCH COMPLETE
