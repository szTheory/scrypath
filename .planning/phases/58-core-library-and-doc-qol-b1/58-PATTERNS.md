# Phase 58 — Pattern map

Analogs and excerpts for executors.

## Error + doc hop pattern

**Analog:** `lib/scrypath/search/error.ex`

- `defexception` with `reason` field.
- `message/1` calls `classify/1` + optional `guide_hint/1` returning stable paths such as **`guides/meilisearch-operations.md`**.

**Apply to:** Sync wait/transport failures and any new **`format_reason/1`** consumer (LIB-01).

## Success-path decoration

**Analog:** `lib/scrypath/sync.ex` — `decorate_result/2`, `public_result/1`, `result_status/1`

- `{:ok, map}` includes `:mode` (`:inline` | `:oban` | `:manual`) and `:status` (`:completed` | `:accepted`).
- **Doc task:** Mirror these keys verbatim in `@doc` tables so adopters do not confuse **accepted** with **searchable**.

## Doc contract tests

**Analog:** `test/scrypath/docs_contract_test.exs`

- `@guide_paths` — list of guide files read into `@guides`.
- `@published_markdown_for_hygiene` — `README.md`, `docs/*`, **plus** `@guide_paths`.
- **Gap:** `mix.exs` `extras:` includes **`guides/overview.md`** but `@guide_paths` omits it — LIB-03 closes this.

## NimbleOptions validation

**Analog:** `lib/scrypath/options.ex`

- Map `NimbleOptions.ValidationError` to tagged `{:error, _}` at call sites that today leak raw validation messages (LIB-01 / LIB-02 boundary per CONTEXT **D-10**).

## Query struct documentation

**Analog:** `lib/scrypath/query.ex`

- Internal `%Scrypath.Query{}` — expand `@moduledoc` / `@typedoc` without `@opaque` (CONTEXT **D-09**).
