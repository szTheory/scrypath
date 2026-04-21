# Phase 46: Search & federation honesty - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **bounded** exploratory search and a **federation-honest** multi-search inspector in **`scrypath_ops/`** for **OPSUI-04** and **OPSUI-05**: non-production warnings, explicit merge order / weights / partial failures / **`:all`** expansion consistent with **`guides/multi-index-search.md`** and **`%Scrypath.MultiSearchResult{}`** — no misleading single-merged-index illusion. Visual and copy contract is locked by **`46-UI-SPEC.md`**.

</domain>

<spec_lock>
## Requirements (locked via UI-SPEC + requirements)

**Functional acceptance:** **OPSUI-04**, **OPSUI-05** in **`.planning/REQUIREMENTS.md`**.

**UI / interaction / copy:** **`46-UI-SPEC.md`** (checker-approved). Downstream agents MUST read **`46-UI-SPEC.md`** before implementing LiveView structure, tokens, copy, and accessibility behaviors.

**In scope (summary):** Bounded search playground; multi-search inspector driven from **`results.ordered`**; honesty strip; merge/federation panel when metadata exists; hard errors vs partial success paths per spec.

**Out of scope:** New recovery verbs; high-cardinality or query-text telemetry; treating federation merge as a single native Meilisearch ranking.

</spec_lock>

<decisions>
## Implementation Decisions

### Default bounds and config source (hybrid caps)

- **D-01:** Use **code defaults plus host overrides** under **`:scrypath_ops`** (not global library defaults). Reject **config-only-with-no-floor** as the primary model — missing env must not imply unbounded behavior.
- **D-02:** **`page.size`:** code default **15**; host may set default and max keys (names at planner discretion) with validation clamped to **`[1, 50]`** — library **`Scrypath.MultiSearch.Entries`** uses **`@max_page_size 50`** and returns **`{:invalid_options, {:page_size, n, 50}}`** above that; OPSUI surfaces over-limit as a **hard validation error**, never silent clamp (per **46-UI-SPEC**).
- **D-03:** **Multi-search breadth:** align selectable / active schema count with library **`max_schemas` (default 10)** in **`lib/scrypath/multi_search/entries.ex`**; host may only **lower** effective max for prod (e.g. 4) via config unless library default is raised in a future release.
- **D-04:** Document overrides in **`scrypath_ops/README.md`** / **`runtime.exs`** in the same spirit as **`SCRYPATH_OPS_SCHEMAS`** — structured **`config :scrypath_ops, ...`** first; env for deploy-rotated knobs. Federation-related limits (**`federation_limit`**, etc.) stay within **`search_many/2`** documented vocabulary; violations → **`{:error, _}`** path in UI.
- **D-05:** Telemetry stays **low-cardinality** (e.g. mode `:single | :multi`, bucketed size classes) — align **`docs/search-backend-sre.md`**; never attach raw operator query strings to metrics.

### Initial mode, URL, and persistence

- **D-06:** **Default mode on first load: single-index** (bounded **`Scrypath.search/3`**) — lower blast radius, simpler first paint, consistent with search as **fourth** nav priority (phase 44).
- **D-07:** **URL as source of truth:** support **`?mode=multi`** (and optionally **`?mode=single`**); normalize in **`handle_params/3`**; use **`push_patch`** when toggling so refresh and bookmarks preserve semantics. Invalid values coerce or patch to canonical form — never silent wrong mode.
- **D-08:** **Federation honesty without default multi workload:** always show the **single/multi control** and a **short static line** (plus link to **`guides/multi-index-search.md`**) explaining that merge order is a **federation view** and that multi mode is where merge/weights/partial failures/**`:all`** are materialized from **`%Scrypath.MultiSearchResult{}`**.
- **D-09:** **Do not auto-run** **`search_many/2`** on mount. Optional: remember last mode in **session** (preferred over long-lived cookies unless explicitly documented). Optional **dev-only** config may default contributors to multi for local ergonomics; **prod** stays single-default unless URL overrides.
- **D-10:** Optional deep link **`?mode=multi`** for docs, runbooks, and CI — same mechanism as operator bookmarks.

### Inspector layout and disclosure defaults

- **D-11:** **First paint order:** environment / non-production strip → bounded query controls (**46-UI-SPEC** primary focal); then results / inspector region.
- **D-12:** **Always-visible federation summary** (compact card): mode, whether merge metadata is present, the **federation honesty caption** from the UI-SPEC, and a **one-line aggregate** (e.g. merge row count / schema count) — never bury the caption only inside collapsed regions.
- **D-13:** **Merge order list:** **collapsed by default** with a **summary line** showing schema sequence length / count so operators see proof of federation construction without the full list dominating first paint.
- **D-14:** **Weights:** **collapsed by default**; summary calls out **non-default** weights only; uniform weights as one muted line or omitted per planner judgment within UI-SPEC tokens.
- **D-15:** **Partial success (`:ok`, failures non-empty`):** **L1 banner** with **`aria-live="polite"`** on a dedicated stable region (count + short schema list); **failure details** in **`<details>` closed by default** with count + schema keys in **`<summary>`**; **per-schema panels** show compact inline failure badges so truth is visible without opening the drawer.
- **D-16:** **Hard errors (`{:error, _}`):** persistent **error**-token panel (not only live region, not only `<details>`); reserve **`error`** semantic color for true failures, not partial success.
- **D-17:** **Auto-expand merge/weights details only** when the operator explicitly opts in (**“Show merge trace”**) or when the library returns a condition that **requires** explanation and is not a silent clamp (truncation/limit semantics per spec → error path, not hidden merge drawer).

### Schema allowlist for search targets

- **D-18:** **Single allowlist for v1.10:** search playground targets **must** be exactly **`ScrypathOps.Schemas.allowlist/0`** (**`:schema_allowlist`**) — same source as posture, failed sync, and sync/drift screens. **OPSUI-04** “bounded” is enforced by limits, honesty UX, optional feature toggles, and telemetry discipline — **not** by a second parallel module list.
- **D-19:** If a **subset allowlist** is ever required later, introduce a **second key only** with a **hard boot invariant:** search modules ⊆ master allowlist; default **inherit master** when unset; **never** allow search outside the phase-45 explicit contract.

### Claude's Discretion

- Exact **`Application.get_env`** key names and env var spellings for playground bounds (must be documented in **`scrypath_ops/README.md`**).
- Whether default URL omits **`mode`** when `single` or always canonicalizes with **`push_patch`**.
- Microcopy for merge summary line and optional **“Show merge trace”** control label.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 46 goal, **OPSUI-04** / **OPSUI-05**.
- `.planning/REQUIREMENTS.md` — Acceptance text and out-of-scope table.
- `.planning/PROJECT.md` — Product boundary, operational honesty, OPSUI outside Hex.

### Locked UI contract

- `.planning/phases/46-search-federation-honesty/46-UI-SPEC.md` — Design system, copy, color semantics, focal order, accessibility notes.

### Prior OPSUI context

- `.planning/phases/44-opsui-foundations/44-CONTEXT.md` — Packaging, nav order, **`live_session :ops`**, security, telemetry discipline.
- `.planning/phases/45-posture-failure-triage/45-CONTEXT.md` — Explicit **`schema_allowlist`**, manual-first refresh patterns, dense tables, low-cardinality telemetry.

### Library and ops implementation truth

- `guides/multi-index-search.md` — Federation, **`:all`**, merge semantics.
- `lib/scrypath/multi_search/entries.ex` — **`@max_page_size 50`**, default **`max_schemas: 10`**, validation errors.
- `lib/scrypath.ex` — **`search/3`**, **`search_many/2`** `@doc`.
- `scrypath_ops/lib/scrypath_ops/schemas.ex` — **`allowlist/0`**.
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` — Current stub / integration point.
- `scrypath_ops/README.md` — Allowlist and runtime env patterns.

### Discipline

- `docs/search-backend-sre.md` — Telemetry and logging expectations for OPSUI.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`ScrypathOps.Schemas.allowlist/0`** — Single schema target source for all `/ops` LiveViews; reuse for search target pickers and multi-search entries.
- **Phase 45 LiveViews** — Assigns-first patterns, explicit empty-allowlist copy, **`Application.put_env`** in tests — mirror for **`SearchLive`** tests.

### Established patterns

- **Library ceilings** — Playground UI validates before calling **`Scrypath`** so operators see friendly errors aligned with library **`{:invalid_options, _}`** vocabulary where applicable.
- **Stub `SearchLive`** — Replace with bounded forms, mode toggle, and inspector panels per **46-UI-SPEC**.

### Integration points

- **`scrypath_ops/config/*.exs`**, **`runtime.exs`** — New playground keys colocated with existing **`:scrypath_ops`** operator configuration.
- **`scrypath_ops/docs/operator-ia.md`** — Keep JTBD ↔ route mapping in sync when search ships real behavior.

</code_context>

<specifics>
## Specific Ideas

- User requested **all four** gray areas in one pass with **parallel subagent research** (bounds/config, default mode, inspector disclosure, allowlist); decisions above synthesize agent findings into one coherent OPSUI policy aligned with **least surprise**, **bounded production posture**, and **federation honesty**.

</specifics>

<deferred>
## Deferred Ideas

- **Separate `search_schema_allowlist`:** Deferred unless a product requirement forces catalog-only search while triage covers more schemas — if added, require **subset-of-master** boot validation (**D-19**).
- **Stricter prod-only “unsafe limits” toggles:** Optional later; any such switch must stay auditable and documented — not a substitute for code floors.

### Reviewed Todos (not folded)

- None from **`todo.match-phase`**.

</deferred>

---

*Phase: 46-search-federation-honesty*
*Context gathered: 2026-04-21*
