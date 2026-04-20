# Phase 41 — Technical research

**Phase:** 41 — Federation docs & contracts  
**Question:** What do we need to know to plan **FED-03** well?

---

## Findings

### 1. Verify task pattern

`Mix.Tasks.Verify.Phase38` (`lib/mix/tasks/verify.phase38.ex`) is the canonical **thin composer**: `Mix.Task.run("app.start")`, `ensure_no_args!/1`, `@focused_tests` list, `Mix.Task.run("test", paths)`. Phase 41 should add **`Mix.Tasks.Verify.Phase41`** the same way, with tests scoped to **doc contracts** and any **federation doc-adjacent** unit files the CONTEXT names (default: `test/scrypath/docs_contract_test.exs` only unless expanded in execution).

### 2. Doc contract module

`test/scrypath/docs_contract_test.exs` already:

- Uses `@readme`, `@guides` map from `@guide_paths`, and `@published_markdown_for_hygiene`.
- Loads **`lib/mix/tasks/verify.phase36.ex` … `verify.phase38.ex`** for string presence in the verify-task corpus.
- **Phase 41** must add **`@verify_phase41 File.read!("lib/mix/tasks/verify.phase41.ex")`** and extend hygiene / structural tests per **D-05–D-09** in `41-CONTEXT.md` (forbidden tokens already cover many internal IDs; add **FED-** style if federation REQ IDs appear in published paths — today hygiene lists FACET/TUNE/MULTI etc.; **do not** add `FED-` to forbidden list if it would block legitimate user-facing “federation” word — CONTEXT says avoid **REQ-** / **`.planning/`** in published markdown).

### 3. `search_many/2` @doc state

`lib/scrypath/search.ex` already documents **`federation_weight:`**, **`:all` expansion**, **`global_schemas:`**, **`:scrypath_global_search_schemas`**, merge metadata. **Gap vs D-16/D-17:** explicit **two-layer score story** — per-index scores stay local; weights tune **merge ordering** under engine policy; avoid “global best match” wording. Add a short bold invariant + one paragraph in the existing `@doc` block.

### 4. CI placement

`.github/workflows/ci.yml` **quality** job runs discrete **`mix verify.phaseNN`** steps (11, 13, 14, 20, 22, 26, 28). **No** phase36–38 steps appear there — facet depth likely rides on **`mix test`**. For **D-03**, add **`mix verify.phase41`** to **quality** after compile-heavy steps (alongside other verify gates): no Meilisearch service required if the task only runs excluded-integration tests.

### 5. CONTRIBUTING

Table lists verify gates through **28**. Add **41** with one sentence: federation docs + doc contract slice, no integration daemon.

### 6. Canonical guide

`guides/multi-index-search.md` is the **single narrative source** for federation weights, `:all`, merge trace (**D-11**). Planner should diff against **Phase 39/40** shipped behavior and **21-CONTEXT** tuple API.

---

## Validation Architecture

Phase 41 is **documentation + static contracts**; no new runtime attack surface.

- **Primary automated path:** `mix verify.phase41` → `mix test` on focused files (at minimum `test/scrypath/docs_contract_test.exs`).
- **Sampling:** After each plan wave touching docs or tests, run `mix verify.phase41`; before verify-work, full `mix test --exclude integration` as per repo norms.
- **Manual:** Optional read-through of ExDoc-rendered HTML for broken anchors — **out of scope** unless lychee is adopted (**CONTEXT deferred**).

Nyquist Dimension 8 is satisfied by **VALIDATION.md** task map keyed to plan tasks.

---

## RESEARCH COMPLETE
