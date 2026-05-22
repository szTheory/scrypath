# Phase 80: Public Query Toolkit Contract - Research

**Researched:** 2026-05-22
**Domain:** Public plain-data query-param contract over the existing `Scrypath.search/3` runtime. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: lib/scrypath.ex]
**Confidence:** HIGH. [VERIFIED: repo code grep] [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] [CITED: https://hexdocs.pm/phoenix/1.8.0/contexts.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://www.meilisearch.com/docs/capabilities/filtering_sorting_faceting/overview]

<user_constraints>
## User Constraints

- Read live code, not archive claims, and do not assume a `Scrypath.SearchModule` layer exists unless the checked-out code proves it. [VERIFIED: user prompt] [VERIFIED: .planning/STATE.md]
- Keep the milestone narrow: a public query-param toolkit plus thin optional Phoenix edge helpers over the existing `Scrypath.search/3` runtime. [VERIFIED: user prompt] [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/REQUIREMENTS.md]
- Phase 80 covers only `QTK-01` and `QTK-04`. It must define a small public plain-data contract without exposing `%Scrypath.Query{}` and without creating a second runtime. [VERIFIED: user prompt] [VERIFIED: .planning/REQUIREMENTS.md]
- Contexts remain the canonical application boundary. No public `%Scrypath.Query{}`. No schema-generated runtime verbs. Phoenix stays optional. [VERIFIED: user prompt] [VERIFIED: .planning/ROADMAP.md] [VERIFIED: guides/phoenix-contexts.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QTK-01 | Apps can cast browser-shaped request params into a stable plain-data search-args shape without exposing `%Scrypath.Query{}` or other current internal query structs as public API. [VERIFIED: .planning/REQUIREMENTS.md] | Recommend one public plain-data contract whose output is `{text, opts}`-equivalent data for `Scrypath.search/3`, while keeping `%Scrypath.Query{}` explicitly internal. [VERIFIED: lib/scrypath/query.ex] [VERIFIED: lib/scrypath/search.ex] |
| QTK-04 | Toolkit output feeds the existing `Scrypath.search/3` path cleanly and does not create a second runtime or move orchestration out of contexts or context-owned search modules. [VERIFIED: .planning/REQUIREMENTS.md] | Recommend toolkit ownership at the request edge only, with contexts still calling `Scrypath.search/3` and runtime validation still flowing through `Scrypath.Options.validate_search_options/2` and `Scrypath.Query.new/2`. [VERIFIED: lib/scrypath.ex] [VERIFIED: lib/scrypath/search.ex] [VERIFIED: guides/phoenix-contexts.md] |
</phase_requirements>

## Summary

The checked-out code has one canonical single-schema search runtime today: `Scrypath.search/3` delegates into `Scrypath.Search.search/3`, which validates keyword options with `Scrypath.Options.validate_search_options/2`, builds an internal `%Scrypath.Query{}` with `Query.new/2`, and only then dispatches to the backend. `%Scrypath.Query{}` is already documented in code as internal and not semver-stable for application pattern matching. [VERIFIED: lib/scrypath.ex] [VERIFIED: lib/scrypath/search.ex] [VERIFIED: lib/scrypath/query.ex]

Phase 80 should therefore add a public request-edge contract strictly above that pipeline, not beside it and not below it. The safest contract is plain data that mirrors the already-accepted `Scrypath.search/3` call shape: one text field plus one search-options payload limited to the existing validated keys (`:filter`, `:sort`, `:page`, `:facets`, `:facet_filter`, `:per_query`). That keeps the toolkit reusable outside Phoenix, lets contexts stay canonical, and prevents freezing the internal `%Scrypath.Query{}` representation as public API. [VERIFIED: lib/scrypath/search.ex] [VERIFIED: lib/scrypath/options.ex] [VERIFIED: guides/phoenix-contexts.md] [CITED: https://hexdocs.pm/phoenix/1.8.0/contexts.html]

Archive drift is real and already acknowledged by the repo. Multiple planning files claim a shipped `Scrypath.SearchModule` layer with `search_args/2`, but the checked-out code, guides, and docs-contract tests all treat that layer as absent and explicitly warn against trusting the archive over the tree. Planning for phase 80 must not depend on `Scrypath.SearchModule`, `search_args/2`, or a `ParamError` module already existing. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/MILESTONES.md] [VERIFIED: docs/jtbd-gap-map.md] [VERIFIED: test/scrypath/docs_contract_test.exs] [VERIFIED: repo code grep]

**Primary recommendation:** add one public root module for plain-data query args, keep its output directly consumable by `Scrypath.search/3`, and forbid it from executing searches itself. [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Request-param casting into search args | API / Backend | Frontend Server (SSR) | Phoenix controllers and LiveViews receive params, but Phoenix guidance and repo guides both keep business boundaries in contexts, and the Scrypath runtime is server-side Elixir, not browser code. [VERIFIED: guides/phoenix-contexts.md] [VERIFIED: guides/phoenix-liveview.md] [CITED: https://hexdocs.pm/phoenix/1.8.0/contexts.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Search execution | API / Backend | — | `Scrypath.search/3` is the canonical public execution path and delegates into `Scrypath.Search.search/3`; no browser runtime exists here. [VERIFIED: lib/scrypath.ex] [VERIFIED: lib/scrypath/search.ex] |
| URL and form round-tripping | Frontend Server (SSR) | API / Backend | LiveView `handle_params/3` and controller params are edge concerns, but they should feed a context-owned call rather than execute search directly. [VERIFIED: guides/phoenix-controllers-and-json.md] [VERIFIED: guides/phoenix-liveview.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |

## Standard Stack

### Core
| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `Scrypath.search/3` | in-repo runtime surface | Canonical single-schema search entrypoint. [VERIFIED: lib/scrypath.ex] | Phase 80 must feed this path rather than introduce a second executor. [VERIFIED: lib/scrypath.ex] [VERIFIED: .planning/REQUIREMENTS.md] |
| `Scrypath.Options.validate_search_options/2` | in-repo runtime validator | Canonical grammar for accepted search options. [VERIFIED: lib/scrypath/options.ex] | Reusing this keeps toolkit output aligned with the already-defended runtime grammar. [VERIFIED: lib/scrypath/options.ex] |
| `NimbleOptions` | repo declares `~> 1.1`; docs observed at `v1.1.1` | Keyword/map validation with structured validation errors. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] | Scrypath already relies on it for option schemas, so phase 80 should extend the existing validation idiom instead of inventing another one. [VERIFIED: lib/scrypath/options.ex] |
| `Scrypath.Query` | in-repo internal struct | Internal normalized runtime state. [VERIFIED: lib/scrypath/query.ex] | Keep it internal; do not promote it as public toolkit output. [VERIFIED: lib/scrypath/query.ex] |

### Supporting
| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `Phoenix` contexts pattern | docs observed at `v1.8.0` | Canonical application boundary for orchestration. [CITED: https://hexdocs.pm/phoenix/1.8.0/contexts.html] | Use for host-app examples and docs; keep toolkit consumers calling their context boundary. [VERIFIED: guides/phoenix-contexts.md] |
| `Phoenix.LiveView.handle_params/3` | docs observed at `v1.1.30` | URL-param edge hook for optional phase-81 helpers. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] | Use only for optional wrappers; phase 80 should stay Phoenix-agnostic. [VERIFIED: .planning/REQUIREMENTS.md] |
| `Scrypath.Meilisearch.Query` | in-repo backend adapter | Converts validated runtime query state into Meilisearch payload keys such as `filter`, `facets`, and `sort`. [VERIFIED: lib/scrypath/meilisearch/query.ex] | Use as the downstream compatibility target when checking that toolkit output still maps to the existing runtime. [VERIFIED: lib/scrypath/meilisearch/query.ex] [CITED: https://www.meilisearch.com/docs/capabilities/filtering_sorting_faceting/overview] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Plain-data toolkit output | Public `%Scrypath.Query{}` | Reject this: the struct is explicitly internal in code and would freeze runtime representation too early. [VERIFIED: lib/scrypath/query.ex] |
| Context-owned `Scrypath.search/3` execution | Toolkit module that performs search | Reject this: it would become a second runtime entrypoint and violate `QTK-04`. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: guides/phoenix-contexts.md] |
| Repo reality | Depend on archived `Scrypath.SearchModule` / `search_args/2` claims | Reject this for phase 80 planning because the checked-out code does not expose those APIs. [VERIFIED: .planning/STATE.md] [VERIFIED: repo code grep] |

**Installation:**
```bash
# No new dependency is required for Phase 80.
```

**Version verification:** The repo currently declares `elixir: "~> 1.17"`, `ecto: "~> 3.13"`, `nimble_options: "~> 1.1"`, and `req: "~> 0.5"` in `mix.exs`; phase 80 does not need an additional package to define the contract. [VERIFIED: mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
HTTP params / LiveView params / non-Phoenix input
                |
                v
      Public plain-data toolkit contract
      (request-edge casting only)
                |
                v
         Host app context function
                |
                v
       Scrypath.search(schema, text, opts)
                |
                v
  Scrypath.Options.validate_search_options/2
                |
                v
         Scrypath.Query.new/2
                |
                v
      Backend adapter search + hydration
                |
                v
            SearchResult
```

The verified runtime already follows the lower half of this diagram; phase 80 should only formalize the top request-edge seam. [VERIFIED: lib/scrypath/search.ex] [VERIFIED: lib/scrypath/query.ex]

### Recommended Project Structure
```text
lib/
├── scrypath.ex                 # Canonical public runtime entrypoints
├── scrypath/search.ex          # Existing runtime pipeline
├── scrypath/options.ex         # Existing search-option grammar
├── scrypath/query.ex           # Internal normalized runtime struct
├── scrypath/query_params.ex    # Proposed public plain-data contract module [ASSUMED]
└── scrypath/query_params/      # Optional internal normalizers for later phases [ASSUMED]
```

### Pattern 1: Plain-Data Contract Above The Runtime
**What:** Define one public data shape that carries `text` plus runtime-compatible search opts, but does not perform search. [ASSUMED]
**When to use:** Whenever host apps need reusable request-edge casting from controller params, LiveView params, CLI input, or other plain maps into `Scrypath.search/3` arguments. [ASSUMED]
**Example:**
```elixir
# Source: current verified boundary pattern in guides/phoenix-contexts.md
def search_posts(query, opts \\ []) do
  Scrypath.search(Post, query,
    Keyword.merge([backend: Scrypath.Meilisearch, repo: Repo], opts)
  )
end
```

### Pattern 2: Runtime Grammar Reuse, Not Reimplementation
**What:** Treat `Scrypath.Options.validate_search_options/2` as the canonical accepted-option grammar and make toolkit output pass through it unchanged. [VERIFIED: lib/scrypath/options.ex]
**When to use:** On every path that turns edge data into runtime options. [VERIFIED: lib/scrypath/options.ex]
**Example:**
```elixir
# Source: lib/scrypath/search.ex
case Scrypath.Options.validate_search_options(schema_module, opts) do
  {:ok, search_opts} -> do_search(schema_module, text, search_opts, opts, [])
  {:error, _} = err -> err
end
```

### Anti-Patterns to Avoid
- **Public `%Scrypath.Query{}` contract:** the module docs explicitly mark it internal and non-semver-stable for application code. [VERIFIED: lib/scrypath/query.ex]
- **Toolkit as executor:** phase 80 should not add `search_from_params/…` or any new canonical runtime entrypoint. [VERIFIED: .planning/REQUIREMENTS.md]
- **Phoenix-first API surface:** phase 80 is required to stay usable outside Phoenix; optional Phoenix wrappers belong to phase 81. [VERIFIED: .planning/REQUIREMENTS.md]
- **Dynamic atom creation from untrusted params:** Elixir documents `String.to_atom/1` as unsafe for web input because atoms are not garbage-collected. [CITED: https://hexdocs.pm/elixir/String.html]
- **Planning against archive claims:** docs-contract tests already pin that the checked-out code does not currently expose `Scrypath.SearchModule`. [VERIFIED: test/scrypath/docs_contract_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Search execution from request params | A second toolkit runtime that talks to the backend | `Scrypath.search/3` | The repo already has a canonical runtime and `QTK-04` forbids creating another one. [VERIFIED: lib/scrypath.ex] [VERIFIED: .planning/REQUIREMENTS.md] |
| Search option grammar | A separate parser grammar for `filter`, `sort`, `page`, `facets`, `facet_filter`, or `per_query` | `Scrypath.Options.validate_search_options/2` | Duplicating the grammar would create drift between toolkit output and runtime acceptance. [VERIFIED: lib/scrypath/options.ex] |
| Validation engine | Custom nested keyword validation | `NimbleOptions` | Scrypath already uses it, and the docs show it returns structured validation errors for schema-driven validation. [VERIFIED: lib/scrypath/options.ex] [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| Phoenix macros for search pages | Controller or LiveView codegen surface | Plain-data toolkit plus optional thin wrappers later | Current guides keep controllers and LiveViews thin and context-first. [VERIFIED: guides/phoenix-controllers-and-json.md] [VERIFIED: guides/phoenix-liveview.md] |

**Key insight:** the existing runtime is already the hard part; phase 80 should freeze only the data seam that feeds it. [VERIFIED: lib/scrypath/search.ex]

## Common Pitfalls

### Pitfall 1: Planning Against `Scrypath.SearchModule`
**What goes wrong:** The plan assumes `search_args/2`, `search/2`, or a shipped `ParamError` layer already exists. [VERIFIED: .planning/MILESTONES.md] [VERIFIED: .planning/STATE.md]
**Why it happens:** The v1.20 archive claims that layer shipped, but the checked-out code and docs-contract tests say otherwise. [VERIFIED: .planning/STATE.md] [VERIFIED: test/scrypath/docs_contract_test.exs]
**How to avoid:** Treat `Scrypath.search/3`, `Scrypath.Options`, and the docs fixture code as the live baseline for phase 80. [VERIFIED: lib/scrypath.ex] [VERIFIED: lib/scrypath/options.ex] [VERIFIED: test/support/docs/phoenix_example_case.ex]
**Warning signs:** A plan step references `Scrypath.SearchModule`, `search_args/2`, or existing public param-error structs. [VERIFIED: repo code grep]

### Pitfall 2: Freezing Internal Runtime State As Public API
**What goes wrong:** The toolkit returns `%Scrypath.Query{}` or encourages consumers to pattern-match on it. [VERIFIED: lib/scrypath/query.ex]
**Why it happens:** `%Scrypath.Query{}` already contains the normalized fields planners want, so it is tempting to reuse it. [VERIFIED: lib/scrypath/query.ex]
**How to avoid:** Publish plain data only, and keep the internal struct created inside `Scrypath.Search.do_search/5`. [VERIFIED: lib/scrypath/search.ex]
**Warning signs:** Public docs or tests assert against `%Scrypath.Query{}` outside runtime-focused tests. [VERIFIED: test/scrypath/search_test.exs]

### Pitfall 3: Toolkit Grammar Drifts From Runtime Grammar
**What goes wrong:** Edge parsing accepts shapes that `Scrypath.search/3` later rejects, or it rejects shapes the runtime already supports. [VERIFIED: lib/scrypath/options.ex]
**Why it happens:** Current fixtures already hand-roll parsing for `page` and `genre`, which is exactly the duplication this milestone is trying to remove. [VERIFIED: test/support/docs/phoenix_example_case.ex]
**How to avoid:** Make the toolkit output a direct `Scrypath.search/3` input shape and validate it through `Scrypath.Options.validate_search_options/2`. [VERIFIED: lib/scrypath/search.ex] [VERIFIED: lib/scrypath/options.ex]
**Warning signs:** Separate allowlists for filters/sorts/pages show up in the toolkit layer. [VERIFIED: repo code grep]

### Pitfall 4: Unsafe Atom Conversion From Request Params
**What goes wrong:** Casting browser params to atoms with `String.to_atom/1` introduces unbounded atom growth from untrusted input. [CITED: https://hexdocs.pm/elixir/String.html]
**Why it happens:** Search option keys are atom-based in the runtime, so a naïve edge parser may convert raw strings directly. [VERIFIED: lib/scrypath/options.ex]
**How to avoid:** Convert only against explicit allowlists or existing atoms, and keep browser param names string-keyed until they are mapped into known runtime keys. [CITED: https://hexdocs.pm/elixir/String.html]
**Warning signs:** `String.to_atom/1` appears in the toolkit implementation path. [VERIFIED: repo code grep]

## Code Examples

Verified patterns from current sources:

### Context-Owned Search Boundary
```elixir
# Source: guides/phoenix-contexts.md
def search_posts(query, opts \\ []) do
  Scrypath.search(Post, query,
    Keyword.merge([backend: Scrypath.Meilisearch, repo: Repo], opts)
  )
end
```

### LiveView URL Params Stay At The Edge
```elixir
# Source: test/support/docs/phoenix_example_case.ex
def handle_params(params, socket) do
  q = Map.get(params, "q", "")
  genres = parse_genres(params["genre"])

  facet_filter =
    case genres do
      [] -> []
      list -> [genre: list]
    end

  with {:ok, result} <-
         Content.search_movies(q,
           facets: [:genre, :year, :rating],
           facet_filter: facet_filter
         ) do
    Map.merge(socket, %{q: q, posts: result.records, facet_filter: facet_filter})
  end
end
```

### Runtime Validation And Internal Query Construction
```elixir
# Source: lib/scrypath/search.ex
case Scrypath.Options.validate_search_options(schema_module, opts) do
  {:ok, search_opts} ->
    query = Query.new(text, search_opts)
    backend.search(schema_module, query, config)

  {:error, _} = err ->
    err
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Archive claims a shipped `Scrypath.SearchModule` with `search_args/2` | Checked-out code does not expose that layer and docs-contract tests explicitly assert the drift | Drift documented in planning state on 2026-05-22. [VERIFIED: .planning/STATE.md] | Phase 80 must plan from live code, not archive claims. [VERIFIED: .planning/STATE.md] |
| Manual request parsing in controller/LiveView examples | Still present in fixtures today for `page` and `genre` params | Verified in current fixtures on 2026-05-22. [VERIFIED: test/support/docs/phoenix_example_case.ex] | Confirms real duplication pressure for a public edge toolkit, but phase 80 should freeze the contract before phase 81 moves those parsers. [VERIFIED: test/support/docs/phoenix_example_case.ex] [VERIFIED: .planning/ROADMAP.md] |
| Internal `%Scrypath.Query{}` as runtime state only | Still internal and explicitly documented as not public API | Verified in current code on 2026-05-22. [VERIFIED: lib/scrypath/query.ex] | Public toolkit should publish plain data instead. [VERIFIED: lib/scrypath/query.ex] |

**Deprecated/outdated:**
- Treating `Scrypath.SearchModule` archive claims as implementation baseline is outdated for this branch tip. [VERIFIED: .planning/STATE.md] [VERIFIED: docs/jtbd-gap-map.md]

## Open Questions

1. **Should the public module be named `Scrypath.QueryParams`?**
   - What we know: the new contract must be public, plain-data, and clearly distinct from internal `%Scrypath.Query{}`. [VERIFIED: lib/scrypath/query.ex] [VERIFIED: .planning/REQUIREMENTS.md]
   - What's unclear: the exact public module name is a design choice, not a verified current API. [ASSUMED]
   - Recommendation: use a root public name that says "request params" rather than "query struct"; `Scrypath.QueryParams` is the clearest fit. [ASSUMED]

2. **Should phase 80 include execution helpers?**
   - What we know: `QTK-04` forbids a second runtime, and current docs keep contexts as the boundary. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: guides/phoenix-contexts.md]
   - What's unclear: whether a convenience helper like `to_search_args/1` is helpful enough without becoming a hidden executor. [ASSUMED]
   - Recommendation: if a helper is added in phase 80, keep it data-only and name it so it cannot be confused with `search/…`. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Phase implementation and tests | ✓ | `1.19.5` | — [VERIFIED: local shell] |
| OTP | Phase implementation and tests | ✓ | `28` | — [VERIFIED: local shell] |
| Mix | Test and verify commands | ✓ | `1.19.5` | — [VERIFIED: local shell] |

**Missing dependencies with no fallback:**
- None for phase 80 research and planning. [VERIFIED: local shell]

**Missing dependencies with fallback:**
- None. [VERIFIED: local shell]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `ExUnit` with support files loaded from `test/support/**/*.ex`. [VERIFIED: test/test_helper.exs] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs test/support/docs/phoenix_examples_test.exs`. [VERIFIED: repo test layout] |
| Full suite command | `mix test`. [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QTK-01 | Public toolkit returns stable plain data without exposing `%Scrypath.Query{}` | unit + contract | `mix test test/scrypath/query_params_test.exs test/scrypath/docs_contract_test.exs` | ❌ Wave 0 [ASSUMED] |
| QTK-04 | Toolkit output feeds `Scrypath.search/3` and does not create a second runtime | unit + integration-style boundary test | `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs test/support/docs/phoenix_examples_test.exs` | ❌ Wave 0 [ASSUMED] |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/query_params_test.exs test/scrypath/search_test.exs`. [ASSUMED]
- **Per wave merge:** `mix test test/scrypath/search_test.exs test/scrypath/meilisearch/query_test.exs test/support/docs/phoenix_examples_test.exs test/scrypath/docs_contract_test.exs`. [ASSUMED]
- **Phase gate:** `mix test`. [VERIFIED: mix.exs]

### Wave 0 Gaps
- [ ] `test/scrypath/query_params_test.exs` — lock the public contract shape, public types, and `%Scrypath.Query{}` non-exposure. [ASSUMED]
- [ ] `test/support/docs/phoenix_examples_test.exs` additions — prove contexts still own execution while edge helpers stay data-only. [VERIFIED: test/support/docs/phoenix_examples_test.exs] [ASSUMED]
- [ ] `test/scrypath/docs_contract_test.exs` additions — fail if docs imply `Scrypath.SearchModule` exists or if the toolkit becomes a runtime wrapper. [VERIFIED: test/scrypath/docs_contract_test.exs] [ASSUMED]

**Current baseline note:** a targeted test run on 2026-05-22 passed search/runtime fixtures but failed one unrelated existing docs-contract assertion expecting `| AUDT-01 |` in root `.planning/REQUIREMENTS.md`. Treat that as baseline repo drift, not as a phase-80-specific failure. [VERIFIED: local `mix test` run]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 80 does not own auth. [VERIFIED: .planning/REQUIREMENTS.md] |
| V3 Session Management | no | Phase 80 is a request-param contract, not a session layer. [VERIFIED: .planning/REQUIREMENTS.md] |
| V4 Access Control | no | Authorization remains a host-app concern at the context boundary. [VERIFIED: guides/phoenix-contexts.md] |
| V5 Input Validation | yes | Reuse `NimbleOptions` plus `Scrypath.Options.validate_search_options/2`; do not trust raw params. [VERIFIED: lib/scrypath/options.ex] [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html] |
| V6 Cryptography | no | No cryptographic concern is introduced by this phase. [VERIFIED: .planning/REQUIREMENTS.md] |

### Known Threat Patterns for This Stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Untrusted request params mapped into runtime options | Tampering | Validate against explicit schemas and runtime allowlists before calling `Scrypath.search/3`. [VERIFIED: lib/scrypath/options.ex] |
| Dynamic atom creation from user input | Denial of service | Avoid `String.to_atom/1` on request data; prefer allowlists or existing atoms only. [CITED: https://hexdocs.pm/elixir/String.html] |
| Controllers / LiveViews bypassing contexts and calling runtime directly | Elevation of privilege / tampering at app boundary | Keep orchestration in contexts as Phoenix and Scrypath guides recommend. [VERIFIED: guides/phoenix-contexts.md] [CITED: https://hexdocs.pm/phoenix/1.8.0/contexts.html] |

## Sources

### Primary (HIGH confidence)
- `lib/scrypath.ex` - verified canonical public search runtime entrypoints and that `Scrypath.search/3` remains the execution boundary. [VERIFIED: lib/scrypath.ex]
- `lib/scrypath/search.ex` - verified runtime flow through option validation, internal query creation, backend dispatch, and search-many behavior. [VERIFIED: lib/scrypath/search.ex]
- `lib/scrypath/query.ex` - verified `%Scrypath.Query{}` is internal and not a semver-stable public contract. [VERIFIED: lib/scrypath/query.ex]
- `lib/scrypath/options.ex` - verified accepted search option grammar and current validation/error patterns. [VERIFIED: lib/scrypath/options.ex]
- `guides/phoenix-contexts.md`, `guides/phoenix-controllers-and-json.md`, `guides/phoenix-liveview.md` - verified repo guidance that contexts remain the application boundary. [VERIFIED: repo guides]
- `test/support/docs/phoenix_example_case.ex` and `test/support/docs/phoenix_examples_test.exs` - verified current duplicated request parsing pressure at the Phoenix edge. [VERIFIED: repo tests]
- `test/scrypath/docs_contract_test.exs` - verified existing contract tests already document and enforce the `SearchModule` archive/code drift. [VERIFIED: test/scrypath/docs_contract_test.exs]
- Phoenix contexts guide - verified official context boundary language. [CITED: https://hexdocs.pm/phoenix/1.8.0/contexts.html]
- Phoenix LiveView docs - verified `handle_params/3` URL-param lifecycle. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- NimbleOptions docs - verified validation return shape and error type. [CITED: https://hexdocs.pm/nimble_options/NimbleOptions.html]
- Meilisearch filtering/sorting/faceting docs - verified that `filter`, `facets`, and `sort` are request-time inputs built over declared index attributes. [CITED: https://www.meilisearch.com/docs/capabilities/filtering_sorting_faceting/overview]
- Elixir `String` docs - verified the `String.to_atom/1` warning for untrusted input. [CITED: https://hexdocs.pm/elixir/String.html]

### Secondary (MEDIUM confidence)
- None. All implementation-driving claims above were verified from repo code or official docs in this session. [VERIFIED: research session]

### Tertiary (LOW confidence)
- None. [VERIFIED: research session]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - phase 80 can rely on current repo modules and existing official docs without needing speculative new dependencies. [VERIFIED: mix.exs] [VERIFIED: lib/scrypath/search.ex]
- Architecture: HIGH - the runtime path, context boundary guidance, and archive drift are all directly verified in the checked-out tree. [VERIFIED: lib/scrypath.ex] [VERIFIED: guides/phoenix-contexts.md] [VERIFIED: .planning/STATE.md]
- Pitfalls: HIGH - each listed pitfall is already visible in code, tests, or official docs. [VERIFIED: repo code grep] [CITED: https://hexdocs.pm/elixir/String.html]

**Research date:** 2026-05-22
**Valid until:** 2026-06-21 for repo-local architecture; re-check sooner if the `SearchModule` reconciliation lands. [VERIFIED: .planning/STATE.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The public module should be named `Scrypath.QueryParams`. | Summary / Recommended Project Structure / Open Questions | Low-to-medium; planner may produce tasks against a name the maintainer wants to change before implementation. |
| A2 | Phase 80 may add a data-only helper name such as `to_search_args/1` without violating scope, as long as it never executes search. | Open Questions | Medium; if the maintainer rejects helper methods entirely, planner tasks should focus only on types/docs/contract docs. |
| A3 | New tests should live in `test/scrypath/query_params_test.exs` and be used as the quick-run spine for this phase. | Validation Architecture | Low; filename and exact command can change without affecting the core design. |

