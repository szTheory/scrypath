# Phase 52 — Technical research

**Question:** What do we need to know to plan **actionable errors and onboarding pitfalls** well?

## Summary

v1.12 expects **bounded** improvements: keep **tagged `{:error, _}`** shapes as the public contract for non-bang APIs; tighten **human-readable** text and **stable `guides/...md` pointers** where guides already define the rule; add **`guides/common-mistakes.md`** with evidence-backed items; reframe **`Scrypath`** `@moduledoc` as the library lobby with a **two-hop** path to **golden-path** then **sync-modes-and-visibility**; align **`mix scrypath.*`** operator task `@moduledoc` blocks with the same link discipline.

Bang helpers today wrap failures as **`RuntimeError`** with **`inspect(reason)`** in `Scrypath.Search` (`search!/3`, `search_many!/2`, `search_within_facet!/4`). CONTEXT locks replacing that with a **small named exception** carrying the same pointer discipline.

**Config resolution:** `Scrypath.Config.resolve!/1` ends in `Options.validate_runtime_options!/1`, which **`raise`s `ArgumentError`** via NimbleOptions on invalid runtime keys — distinct from search-time `{:error, _}`. Document that split per **D-05**; do not silently change raise vs tuple semantics.

**High-value `{:error, _}` tags already in play:** `{:transport_failed, reason}` (native `search_many` path), `{:validation_failed, schema, reason}`, `{:invalid_options, _}`, `{:all_failed, failures}` — improve **message surfaces** (and bang exception messages) without renaming tags.

**Docs contract:** `test/scrypath/docs_contract_test.exs` owns published-markdown hygiene; new guide must join `@guide_paths`, `@published_markdown_for_hygiene`, and **`mix.exs` `:docs` extras** (and a sensible `groups_for_extras` bucket).

## Code touchpoints

| Area | File | Notes |
|------|------|--------|
| Search + bang | `lib/scrypath/search.ex` | `search!/3`, `search_many!/2`, `search_within_facet!/4`; `{:error, {:transport_failed, _}}` |
| Options / validation | `lib/scrypath/options.ex` | `validate_search_options/2` returns `{:error, _}`; runtime `validate!` raises |
| Config | `lib/scrypath/config.ex` | `resolve!/1` pipeline |
| Lobby | `lib/scrypath.ex` | Replace narrow reflection-only `@moduledoc` with lobby narrative + links |
| Mix tasks | `lib/mix/tasks/scrypath.*.ex` | status, reconcile, retry, failed (+ settings if touched) |
| Contract tests | `test/scrypath/docs_contract_test.exs` | New guide path + optional anchor tests |

## Pitfalls evidence (for ONBD-05)

Use **concrete** citations in `guides/common-mistakes.md` (no planning tokens in published text per existing hygiene regex):

- **Federation / backend capability:** `Scrypath.SearchManyTest` covers sequential-only backend vs federation weights — maps to `{:invalid_options, {:federation_merge_requires_native_search_many, _}}`.
- **Partial multi-search vs hard errors:** `@doc` on `search_many/2` and tests document `{:ok, %MultiSearchResult{}}` with `failures:` — pitfall “treating partial hydration/transport rows as total failure.”
- **Runtime config / Meilisearch URL:** Resolution and backend fetch happen inside `do_search` / `run_search_many_prepared` after `Config.resolve!` — failures should name **`meilisearch_url`**, **`backend`**, or application env surfaces the code actually reads.

## Risks

- **Semver:** New exception module for bang functions is **behavior-visible**; document in public `@doc` / changelog expectation (rescuing `RuntimeError` no longer matches).
- **Over-promising:** Messages must not invent recovery steps the library does not perform (**ONBD-04** / out-of-scope table in REQUIREMENTS.md).

## Open choices (Claude discretion)

- Whether to ship **`Scrypath.Error.message/1`** in 52 or defer (**D-07**).
- Exact **`#anchor`** strings once guide sections are written.

## Validation Architecture

**Nyquist / execution sampling for this phase**

| Dimension | Strategy |
|-----------|----------|
| Automated correctness | **`mix test`** full suite after each plan wave; **`mix test test/scrypath/docs_contract_test.exs`** after any published markdown or `mix.exs` docs list change |
| Error/message regression | Targeted tests under `test/scrypath/` for tuple shapes that must remain stable; new or extended tests for bang exception type and message substrings where assertions are safe |
| Doc hygiene | `docs_contract_test` must stay green — no `VRFY-`, `(D-xx)`, etc. in published paths |
| Manual | Spot-check **`mix help scrypath.status`** (and one other task) for link block presence after `@moduledoc` edits |

**Quick command:** `mix test test/scrypath/docs_contract_test.exs`  
**Full command:** `mix test`

---

## RESEARCH COMPLETE
