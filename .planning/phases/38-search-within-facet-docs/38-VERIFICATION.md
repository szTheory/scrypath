---
status: passed
phase: "38"
completed: "2026-04-20"
---

# Phase 38 verification — Search within facet + docs

## Goal

Ship **FACET-03** (`search_within_facet/4`) and **FACET-04** (guide + contracts + verify slice) per phase plans.

## Automated evidence

| Check | Result |
|-------|--------|
| `mix compile --warnings-as-errors` | Pass |
| `mix verify.phase38` | Pass |

## Must-haves (plans)

### 38-01

- [x] Scoped search uses same validation, `Query`, telemetry span `[:scrypath, :search]`, and backend dispatch as `search/3`.
- [x] Duplicate facet attribute in `facet_filter:` + bucket raises `ArgumentError` with `search_within_facet:` prefix.
- [x] Integration test asserts Meilisearch JSON **`filter`** and **`facetFilters`** for a composed scenario.
- [x] Telemetry includes **`search_scope: :within_facet`** and **`scoped_facet`** for scoped calls.

### 38-02

- [x] Guide contains exact **`##`** titles and composition / duplicate / LiveView footgun prose without **`FACET-NN`** tokens.
- [x] **`docs_contract_test.exs`** locks headings and stable phrases; verifies **`verify.phase38`** focused list and **no `HEX_API_KEY`**.
- [x] **`mix verify.phase38`** registered in **`mix.exs`** **`preferred_cli_env`**.
- [x] **README** one-line discoverability with relative guide link; **`@moduledoc`** mentions **`search_within_facet/4`** and the guide path.

## human_verification

None required for this phase.

## Gaps

None.
