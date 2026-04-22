# Phase 58 — Technical research

**Question:** What do we need to know to plan **LIB-01**, **LIB-02**, and **LIB-03** well?

## Findings

### Sync success envelope (LIB-01 / D-01)

- `Scrypath.Sync.decorate_result/2` attaches `:mode` from config and `:status` from `result_status/1`: `:inline` → `:completed`; `:manual` / `:oban` → `:accepted`.
- `public_result/1` exposes `mode`, `status`, `document_ids`, `document_count`, optional `:index`, `:oban`, `:task` (backend task map), or `:job` (Oban-shaped map). Callers can get `{:ok, %{status: :accepted, ...}}` while Meilisearch is still catching up—this is the “saved ≠ indexed” pitfall **EVID-57-01** targets.
- `Scrypath.sync_record/3` and `sync_records/3` in `lib/scrypath.ex` currently have minimal `@doc`; the heavy narrative lives under **Read next** in `@moduledoc` but not next to the function—plan should attach explicit success-path semantics and the same doc-hop paths as errors (**D-04**).

### Error shape and DX (LIB-01 / D-02–D-03)

- `Scrypath.Search.Error` is the reference: `defexception`, `message/1` combines `classify/1` + optional `guide_hint/1` with **stable relative guide paths** (no match-on-message for callers).
- Sync paths should converge on **tagged tuples** for machine branching; human strings belong in `Exception.message/1` or a shared **`format_reason/1`** (**D-03**) used by Mix tasks if any surface raw reasons today.
- `maybe_wait_for_task/2` and `public_wait_error/1` are the right seam for task-wait failures—today reasons may be opaque; research recommends normalizing to tags like `{:task_wait_failed, ...}` before public return.

### NimbleOptions (LIB-01 / LIB-02 crossover)

- `lib/scrypath/options.ex` validates public option surfaces; `NimbleOptions.ValidationError` should be mapped to **tagged** `{:error, _}` for LIB-01, not string-matched (**D-10**).

### Query struct (LIB-02)

- `lib/scrypath/query.ex` holds normalized pagination/filter/sort state; adapters pattern-match internals today. **D-09** calls for honest `@moduledoc` (“internal normalized … not semver-stable pattern-match target”) and richer `@typedoc` on `t` / nested types—**defer `@opaque`** per CONTEXT.

### Doc contract drift (LIB-03)

- `mix.exs` `extras:` includes **`guides/overview.md`**.
- `test/scrypath/docs_contract_test.exs` `@guide_paths` **omits** `guides/overview.md` while `@published_markdown_for_hygiene` concatenates `@guide_paths` with top-level docs—**overview** is only partially in the contract graph (**D-14**). Fix = add path to `@guide_paths` (and thus hygiene scan) **or** documented exclusion in the test module.
- When LIB-01 adds stable hop strings (e.g. `guides/sync-modes-and-visibility.md`), add **spine-level** `assert_contains_all` (or equivalent) checks per **D-13**—not full paragraph locks.

### Ecosystem precedent (D-06)

- Rails Searchkick / Meilisearch-Rails: queue + worker, “record saved” vs “searchable” split. Scrypath should double down on **explicit `status` in success maps** + **short guide hops** + telemetry already on search—not string-only polish.

### Risks

- **Semver (D-07):** New tuple tags are additive; avoid renaming existing error heads.
- **Test churn:** Doc-contract tests are sensitive to hygiene regexes—keep new anchors minimal.

## Recommendations

1. **LIB-01:** One internal formatter module; success `@doc` on sync entrypoints; tagged errors + guide hops mirroring `Search.Error` path style; telemetry unchanged.
2. **LIB-02:** Documentation-only on `Query` + `Scrypath` moduledoc grouping; optional small private helpers—no new public macros.
3. **LIB-03:** Close `overview.md` contract gap; add anchors for any new stable strings from LIB-01; triad README / CONTRIBUTING / `verify.opsui` only if new contributor-facing tokens appear (**D-15**).

## Validation Architecture

Phase 58 is **Elixir / ExUnit** with no new services. Validation strategy:

- **Framework:** ExUnit (existing).
- **Quick command:** `mix test test/scrypath` (or narrower path after each task).
- **Full command:** `mix test` from repo root (default CI expectation per roadmap).
- **Sampling:** After each task that touches `lib/` or `test/`, run scoped `mix test` on affected modules; after each plan, run full `mix test` once.
- **Doc contract:** `mix test test/scrypath/docs_contract_test.exs` after LIB-03 tasks touching anchors or `@guide_paths`.
- **Manual:** Append-only **EVID-01** errata row for LIB-02 (**D-12**)—human verifies wording with ledger rules.

This section satisfies Nyquist **Dimension 8** (validation continuity) for execution agents.

## RESEARCH COMPLETE
