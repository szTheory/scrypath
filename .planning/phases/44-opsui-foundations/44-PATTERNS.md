# Phase 44 — Pattern map (OPSUI foundations)

Analogs in-repo for executor `read_first` targets.

## Phoenix application layout

| New / modified (phase 44) | Analog | Excerpt / note |
|---------------------------|--------|----------------|
| `scrypath_ops/mix.exs` path dep | `examples/phoenix_meilisearch/mix.exs` | `{:scrypath, path: "../.."}` from example → use `{:scrypath, path: ".."}` from `scrypath_ops/` (one level to library root). |
| `config/runtime.exs` secrets | `examples/phoenix_meilisearch/config/runtime.exs` | Same `if config_env() == :prod` guard patterns for env-driven config. |
| Router `scope` | `examples/phoenix_meilisearch/lib/scrypath_demo_web/router.ex` | Minimal router—OPSUI adds `/ops` scope + `live_session`. |

## Hex packaging boundary

| Concern | Analog | Note |
|---------|--------|------|
| Whitelist `package.files` | `mix.exs` `defp package` | Current `files: ~w(lib .formatter.exs mix.exs ...)` already excludes `scrypath_ops/`; plans add **documentation** and optional comment—do not broaden globs blindly. |

## Documentation tone

| Concern | Analog | Note |
|---------|--------|------|
| Pinned headings (future) | `test/docs_contract_test.exs` (library) | Phase 44 does not add OPSUI doc contract tests (phase 47); keep headings stable by hand. |

## Telemetry discipline

| Concern | Analog | Note |
|---------|--------|------|
| Low-cardinality events | `docs/search-backend-sre.md` | Copy event naming guidance into `SECURITY.md` or `README.md` snippets for OPSUI shell. |
