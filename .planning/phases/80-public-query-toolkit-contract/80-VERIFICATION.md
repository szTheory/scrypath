---
phase: 80-public-query-toolkit-contract
verified: 2026-05-22T12:15:38Z
status: passed
score: 6/7 must-haves verified
overrides_applied: 0
deferred:
  - truth: "A context can turn request-shaped search input into stable toolkit output and pass it to `Scrypath.search/3` without touching internal query structs."
    addressed_in: "Phase 81"
    evidence: "Phase 81 success criteria: 'Request params normalize once at the edge for text, filters, sort, page, facets, and facet-filter inputs.'"
---

# Phase 80: Public Query Toolkit Contract Verification Report

**Phase Goal:** carve out the small public param toolkit as a plain-data edge contract over the existing runtime without promoting internal query structs or inventing a second runtime.
**Verified:** 2026-05-22T12:15:38Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A context can turn request-shaped search input into stable toolkit output and pass it to `Scrypath.search/3` without touching internal query structs. | ⚠️ DEFERRED | `Scrypath.QueryParams.cast/1` only normalizes the top-level envelope and explicitly rejects nested request-style maps in [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:11) and [test/scrypath/query_params_test.exs](/Users/jon/projects/scrypath/test/scrypath/query_params_test.exs:59). Later-phase coverage is explicit in Phase 81 roadmap success criterion 1. |
| 2 | The public toolkit contract is data-first and explicit enough that apps can use it outside Phoenix. | ✓ VERIFIED | `Scrypath.QueryParams` is a plain map contract with typed keys and no Phoenix dependency in [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:19). |
| 3 | Search orchestration still lives in app contexts or search modules, not in toolkit helpers. | ✓ VERIFIED | The public surface exports `cast/1` and `to_search_args/1` only in [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:36); tests assert no `search/*` helper is exported in [test/scrypath/query_params_test.exs](/Users/jon/projects/scrypath/test/scrypath/query_params_test.exs:77). |
| 4 | No schema-generated runtime verbs or new canonical runtime entrypoint appear. | ✓ VERIFIED | Root docs keep `search/3` canonical and list `Scrypath.QueryParams` as request-edge preparation only in [lib/scrypath.ex](/Users/jon/projects/scrypath/lib/scrypath.ex:18). No new public runtime function was added. |
| 5 | A host app can produce one stable plain-data Scrypath toolkit shape without touching `%Scrypath.Query{}`. | ✓ VERIFIED | `cast/1` returns a plain map and tests explicitly refute `%Scrypath.Query{}` in [test/scrypath/query_params_test.exs](/Users/jon/projects/scrypath/test/scrypath/query_params_test.exs:18). |
| 6 | The toolkit surface reuses the existing `filter`, `sort`, `page`, `facets`, `facet_filter`, and `per_query` vocabulary. | ✓ VERIFIED | The contract type and `@search_option_keys` reuse the runtime vocabulary exactly in [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:20) and `to_search_args/1` preserves that shape at [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:46). |
| 7 | Toolkit output stays aligned with the existing runtime and adapter grammar through Meilisearch payload generation. | ✓ VERIFIED | Runtime parity is asserted in [test/scrypath/search_test.exs](/Users/jon/projects/scrypath/test/scrypath/search_test.exs:119), and payload parity is asserted in [test/scrypath/meilisearch/query_test.exs](/Users/jon/projects/scrypath/test/scrypath/meilisearch/query_test.exs:107). |

**Score:** 6/7 truths verified

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases.

| # | Item | Addressed In | Evidence |
| --- | --- | --- | --- |
| 1 | Nested browser-style request param normalization (`%{"filter" => %{"status" => "published"}}`, `%{"page" => %{"number" => "2"}}`, etc.) is not implemented in phase 80. | Phase 81 | Phase 81 success criterion 1: "Request params normalize once at the edge for text, filters, sort, page, facets, and facet-filter inputs." |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/scrypath/query_params.ex` | Public plain-data query toolkit facade and stable typed contract | ✓ VERIFIED | Substantive module with moduledoc, type, `cast/1`, and `to_search_args/1`; wired to the internal caster via `alias Scrypath.QueryParams.Caster` and `Caster.cast(params)` at [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:17). |
| `lib/scrypath/query_params/caster.ex` | Internal request-shape casting seam behind the public facade | ✓ VERIFIED | Explicit allowlist for top-level keys, validation of nested runtime-compatible shapes, and no `String.to_atom/1` usage in [lib/scrypath/query_params/caster.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params/caster.ex:14). |
| `lib/scrypath.ex` | Root-level discoverability that keeps `search/3` canonical | ✓ VERIFIED | Moduledoc points readers to `Scrypath.QueryParams` for edge preparation while preserving contexts and `search/3` as runtime in [lib/scrypath.ex](/Users/jon/projects/scrypath/lib/scrypath.ex:25). |
| `test/scrypath/query_params_test.exs` | Contract tests for plain-data output and narrow public boundary | ✓ VERIFIED | Covers stable shape, public export surface, and explicit rejection of nested request-style values in [test/scrypath/query_params_test.exs](/Users/jon/projects/scrypath/test/scrypath/query_params_test.exs:6). |
| `test/scrypath/search_test.exs` | Delegation parity tests into the common search path | ✓ VERIFIED | Compares toolkit-produced args to direct `Scrypath.search/3` results in [test/scrypath/search_test.exs](/Users/jon/projects/scrypath/test/scrypath/search_test.exs:119). |
| `test/scrypath/meilisearch/query_test.exs` | Adapter grammar parity proof for toolkit-produced args | ✓ VERIFIED | Compares toolkit payload with direct `Query.new/2` payload in [test/scrypath/meilisearch/query_test.exs](/Users/jon/projects/scrypath/test/scrypath/meilisearch/query_test.exs:107). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/scrypath/query_params.ex` | `lib/scrypath/query_params/caster.ex` | delegating public facade over an internal casting seam | ✓ WIRED | `Caster.cast(params)` in [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:37). |
| `lib/scrypath/query_params.ex` | `lib/scrypath/query.ex` | explicit public-vs-internal boundary wording | ✓ WIRED | The moduledoc names `%Scrypath.Query{}` as internal normalized query state in [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:6), matching the internal-only contract in [lib/scrypath/query.ex](/Users/jon/projects/scrypath/lib/scrypath/query.ex:2). |
| `test/scrypath/query_params_test.exs` | `lib/scrypath/query_params.ex` | contract assertions against public output shape and helper names | ✓ WIRED | Tests call `QueryParams.cast/1` and `QueryParams.to_search_args/1`, and refute `search/*` exports at [test/scrypath/query_params_test.exs](/Users/jon/projects/scrypath/test/scrypath/query_params_test.exs:6). |
| `test/scrypath/search_test.exs` | `lib/scrypath/query_params.ex` | cast output converted into `Scrypath.search/3` inputs | ✓ WIRED | `QueryParams.cast/1` and `QueryParams.to_search_args/1` feed `Scrypath.search/3` in [test/scrypath/search_test.exs](/Users/jon/projects/scrypath/test/scrypath/search_test.exs:120). |
| `test/scrypath/search_test.exs` | `lib/scrypath/search.ex` | common search path assertions on resulting internal `%Scrypath.Query{}` | ✓ WIRED | Tests assert the resulting `%Query{}` shape after `Scrypath.search/3`; the runtime path validates opts then builds `Query.new/2` in [lib/scrypath/search.ex](/Users/jon/projects/scrypath/lib/scrypath/search.ex:29) and [lib/scrypath/search.ex](/Users/jon/projects/scrypath/lib/scrypath/search.ex:95). |
| `test/scrypath/meilisearch/query_test.exs` | `lib/scrypath/meilisearch/query.ex` | payload assertions using toolkit-produced search args | ✓ WIRED | Toolkit-produced args are converted with `Query.new/2` then `MeilisearchQuery.to_payload/1` in [test/scrypath/meilisearch/query_test.exs](/Users/jon/projects/scrypath/test/scrypath/meilisearch/query_test.exs:121). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/scrypath/query_params.ex` | `query_params` / `text` / search opts | `Scrypath.QueryParams.Caster.cast/1` via [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:37) | Yes — values come from caller-supplied input, merged with explicit defaults, then forwarded as `{text, opts}` in [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:46) | ✓ FLOWING |
| `test/scrypath/search_test.exs` parity path | `toolkit_query` | `Scrypath.search/3` → `Scrypath.Options.validate_search_options/2` → `Query.new/2` in [lib/scrypath/search.ex](/Users/jon/projects/scrypath/lib/scrypath/search.ex:29) and [lib/scrypath/search.ex](/Users/jon/projects/scrypath/lib/scrypath/search.ex:95) | Yes — the test proves toolkit-produced args and direct args converge to the same internal query struct | ✓ FLOWING |
| `test/scrypath/meilisearch/query_test.exs` parity path | `toolkit_payload` | `Query.new/2` → `MeilisearchQuery.to_payload/1` in [lib/scrypath/meilisearch/query.ex](/Users/jon/projects/scrypath/lib/scrypath/meilisearch/query.ex:15) | Yes — payload contains real runtime keys `filter`, `sort`, `facets`, `page`, `hitsPerPage`, and `"facetFilters"` | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 80 focused contract and parity tests pass | `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs` | `26 tests, 0 failures` | ✓ PASS |
| Full repo test gate after phase 80 changes | `mix test` | `436 tests, 2 failures (9 excluded)` | ✓ PASS_WITH_NOTES |

`mix test` failures were outside the phase 80 scope and did not point at phase-80 files:

- `test/release/package_metadata_test.exs:32` failed because `docs[:groups_for_extras][:Maintainers]` now includes `docs/jtbd-gap-map.md`.
- `test/scrypath/docs_contract_test.exs:839` failed because requirements traceability no longer contains `| AUDT-01 |`.

Those failures are pre-existing docs/planning drift and are not caused by `lib/scrypath/query_params.ex`, `lib/scrypath/query_params/caster.ex`, `lib/scrypath.ex`, or the phase 80 tests.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `QTK-01` | `80-01-PLAN.md` | Apps can cast browser-shaped request params into a stable plain-data search-args shape without exposing `%Scrypath.Query{}`. | ⚠️ PARTIAL / DEFERRED | Stable plain-data contract exists and `%Scrypath.Query{}` stays internal, but nested browser-style params are explicitly deferred to Phase 81 in [lib/scrypath/query_params.ex](/Users/jon/projects/scrypath/lib/scrypath/query_params.ex:11) and [test/scrypath/query_params_test.exs](/Users/jon/projects/scrypath/test/scrypath/query_params_test.exs:59). |
| `QTK-04` | `80-02-PLAN.md` | Toolkit output feeds `Scrypath.search/3` cleanly without creating a second runtime or moving orchestration out of contexts. | ✓ SATISFIED | The only public bridge is `to_search_args/1`, root docs keep `search/3` canonical, and parity tests prove identical runtime and payload behavior in [lib/scrypath.ex](/Users/jon/projects/scrypath/lib/scrypath.ex:25), [test/scrypath/search_test.exs](/Users/jon/projects/scrypath/test/scrypath/search_test.exs:119), and [test/scrypath/meilisearch/query_test.exs](/Users/jon/projects/scrypath/test/scrypath/meilisearch/query_test.exs:107). |

No orphaned Phase 80 requirements were found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/scrypath/query_params_test.exs` | 59 | Explicit rejection of nested request-style maps | ⚠️ Warning | This is intentional for phase 80, but it means the contract is narrower than full browser-param normalization until Phase 81 lands. |

### Gaps Summary

No actionable phase-80 blockers remain after filtering deferred work against later roadmap phases.

Phase 80 achieved its core goal: there is now one public plain-data toolkit contract, it does not promote `%Scrypath.Query{}` to public API, it does not introduce a second runtime, and its output feeds the existing `Scrypath.search/3` and Meilisearch pipeline unchanged. The only uncovered slice is nested browser-style param normalization, and the roadmap explicitly schedules that work for Phase 81 rather than this contract-freezing phase.

---

_Verified: 2026-05-22T12:15:38Z_
_Verifier: Claude (gsd-verifier)_
