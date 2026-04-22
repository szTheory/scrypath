# Phase 52 — Pattern map

Analogs and conventions for executors.

## Documentation and contracts

| Target | Closest analog | Pattern |
|--------|----------------|---------|
| New guide + ExDoc extras | `guides/golden-path.md`, `mix.exs` `:docs` | Add path to `extras:` and `groups_for_extras`; extend `@guide_paths` / `@published_markdown_for_hygiene` in `docs_contract_test.exs` |
| Overview TOC row | `guides/overview.md` existing rows | Short description + markdown link |
| CONTRIBUTING discoverability | Phase 51 edits to `CONTRIBUTING.md` | Short “Common mistakes” pointer block |

## Errors and exceptions

| Target | Closest analog | Pattern |
|--------|----------------|---------|
| Tagged search errors | `lib/scrypath/search.ex` `{:error, {:transport_failed, reason}}` | Preserve tuple tag; enrich operator-facing text only |
| Bang wrapping | Current `raise RuntimeError, "search failed: #{inspect(reason)}"` | Replace with `raise Scrypath.Search.Error, reason: reason` (or equivalent) + `Exception.message/1` |
| API misuse | `raise ArgumentError` in `search/3` validation path | Document in `@doc` “Raises” section per **D-05** |

## Module docs

| Target | Closest analog | Pattern |
|--------|----------------|---------|
| `Scrypath` lobby | `README.md` “Quick Path” + phase 51 authority language | Product one-liner, then bullets linking `guides/golden-path.md` first, `guides/sync-modes-and-visibility.md` second; defer option tables to `Scrypath.Schema` |
| Mix task long docs | `Mix.Tasks.Scrypath.Status` | Expand `@moduledoc` with same two-hop block for operator tasks listed in CONTEXT **D-14** |

---

## PATTERN MAPPING COMPLETE
