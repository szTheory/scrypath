# Phase 40 — Technical research: `:all` expansion (FED-02)

**Phase:** 40 — `:all` expansion  
**Question:** What do we need to know to plan implementation well?

---

## Summary

Implement **`{:all, text}`** / **`{:all, text, entry_keyword}`** as **list elements** in `search_many/2`’s first argument. **Before** `MultiSearch.Entries.normalize/2`, expand each tag **in place** into zero or more **`{schema, text, merged_entry_opts}`** triples using a **declared allowlist** (never reflection). **Registry source:** optional **`global_schemas:`** in `shared_opts` (replaces any app default for that call) else **`Application.get_env(otp_app, :scrypath_global_search_schemas, [])`** where **`otp_app`** comes from existing `shared_opts` / repo resolution patterns (same mental model as `Config.per_repo_config/1`). If **both** are absent or the resolved list is **empty** when an `{:all, _}` tag is present, return **`{:error, {:invalid_options, {:all_expansion, :empty_registry}}}}`**. **Cardinality:** run **`check_schema_count`** on the **fully expanded** flat list so **`{:too_many_schemas, count, max}`** matches explicit multi-schema calls. **`Entries.normalize/2`** should only see normal schema tuples after expansion (single choke point for merge + rails). **`global_schemas`** (or final name) must be a **runtime option** in `Options.@runtime_options` **or** stripped before `Config.resolve!/1` so `validate_runtime_options!` does not reject unknown keys — **prefer adding to `@runtime_options`** with `default: nil` so it flows through `runtime_option_keys/0` and is dropped from per-schema Nimble validation via `Keyword.drop(opts, runtime_option_keys())`. **Malformed `{:all, ...}`** shapes → **`{:error, {:invalid_options, :malformed_entry}}`** or a dedicated **`{:all_expansion, :invalid_shape}`** tuple under **`{:invalid_options, _}`** for grep stability (align with CONTEXT D-12 reserve). **Telemetry:** `search_many` span metadata today uses `length(entries)` pre-normalization; after expansion, consider **`schema_count: length(expanded)`** (or both raw + expanded) so operators see true batch size.

---

## Code anchors (current)

| Area | Role |
|------|------|
| `Search.run_search_many/2` | `with {:ok, quads} <- Entries.normalize(...)` — insert **`expand_all_tags(entries, shared_opts)`** step before normalize. |
| `MultiSearch.Entries.normalize/2` | `check_schema_count/2` on raw `entries` — **move count check to post-expansion list** or expand first in `Search` then pass only flat tuples. |
| `Options.validate_runtime_options!/1` | Nimble schema for `shared_opts`; must accept registry override key or strip it. |
| `Options.validate_search_options/2` | Already drops `runtime_option_keys()` — new key must be in that set. |
| `test/scrypath/search_many_test.exs` | Primary integration tests for multi-search. |

---

## Expansion algorithm (recommended)

1. **Walk** `entries` left-to-right.
2. For **`{schema, text}`** or **`{schema, text, kw}`** when `schema` is a normal module atom → **copy** to output (unchanged).
3. For **`{:all, text}`** when `is_binary(text)` → treat as **`{:all, text, []}`**.
4. For **`{:all, text, kw}`** when `is_binary(text)` and `is_list(kw)`:
   - Resolve **`modules = resolve_modules(shared_opts)`** (`{:ok, modules}` | `{:error, _}`).
   - If **`modules == []`** → **`{:error, {:invalid_options, {:all_expansion, :empty_registry}}}}`**.
   - Else emit **`Enum.flat_map(modules, fn m -> [{m, text, merged_kw(m)}] end)`** where **`merged_kw`** applies CONTEXT **D-03**: for each `m`, `Keyword.merge(shared_rails_only_for_entry_merge(shared_opts), kw, fn _, _, e -> e end)` — actually per CONTEXT, each expanded slot is **`{schema, text, merged_entry_opts}`** with same merge as `normalize_one` (entry wins over shared). Expansion can emit **`{m, text, kw}`** only and let **`Entries.normalize_one`** merge `shared` + `entry_kw` — so expansion outputs **`{schema, text, entry_kw_from_all_tag}`** only (the third element is the **`{:all`** tag’s keyword list).
5. **Reject** unknown tuple shapes before expansion (keep **`malformed_entry`** for non-matching tuples).

**Order / duplicates:** Preserve allowlist order; duplicates in allowlist → duplicate slots (CONTEXT D-02).

---

## Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Unknown `shared_opts` key breaks `Config.resolve!` | Register `global_schemas` in `@runtime_options` or strip before resolve. |
| `:empty_schema_list` conflated with empty registry | Use **`{:all_expansion, :empty_registry}}`** only for registry-empty (CONTEXT D-11). |
| Pre-expansion `max_schemas` check | Count **after** expansion. |

---

## Out of scope (confirm)

- README / guides contract strings (**Phase 41 / FED-03**).
- Shared-only `schemas: :all` without tagged tuple (**deferred** in CONTEXT).

---

## Validation Architecture

**Dimension 8 (Nyquist):** Phase 40 is **library + ExUnit** only. Automated verification is **`mix test`** on targeted modules plus **`mix compile --warnings-as-errors`**.

| Layer | Command | When |
|-------|---------|------|
| Fast | `mix test test/scrypath/multi_search/entries_test.exs` | After `Entries` changes |
| Integration | `mix test test/scrypath/search_many_test.exs` | After `Search` / expansion changes |
| Gate | `mix compile --warnings-as-errors && mix test test/scrypath/multi_search test/scrypath/search_many_test.exs` | End of phase |

**Manual:** None required for FED-02 beyond optional local Meilisearch if adding live HTTP tests (existing tests use `FakeBackend` — **stay on fakes** unless a plan explicitly adds integration).

---

## RESEARCH COMPLETE

Proceed to **`40-VALIDATION.md`**, **`40-PATTERNS.md`**, and **`40-*-PLAN.md`**.
