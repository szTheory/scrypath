# Phase 81: Edge normalization errors and Phoenix wrappers - Research

**Researched:** 2026-05-23 [VERIFIED: system date]
**Domain:** One-time request-edge normalization, aggregate field-scoped error contracts, and optional thin Phoenix adapters over `Scrypath.QueryParams`. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md]
**Confidence:** HIGH. [VERIFIED: repo code grep] [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Normalization grammar
- **D-01:** Phase 81 should adopt a conservative Plug-native browser grammar, not a rich query DSL. Accept only request shapes Plug already decodes predictably and that ordinary Phoenix forms/URLs naturally produce.
- **D-02:** Canonical text input is `q`, with `text` accepted as a compatibility alias. Normalize once into the existing `Scrypath.QueryParams` plain-data shape.
- **D-03:** Canonical pagination input is `page[number]` and `page[size]`, parsed from positive integer strings with explicit defaults/limits preserved by the normalized contract.
- **D-04:** Canonical facet input is `facets[]` for repeated facet names.
- **D-05:** Canonical filter input is `filter[field]` for a scalar value and `filter[field][]` for repeated values. `facet_filter` follows the same scalar-or-repeated-value shape.
- **D-06:** Canonical sort input should optimize for the common case with `sort[field]` plus `sort[dir]`. If multi-sort is supported in this phase, use only explicit indexed entries such as `sort[0][field]` and `sort[0][dir]`; do not rely on ambiguous nested-list decoding.
- **D-07:** Ignore unrelated top-level params outside Scrypath-owned namespaces. Inside owned namespaces, validate strictly and report structured errors rather than silently dropping malformed or unknown nested keys.
- **D-08:** Do not introduce a predicate/operator mini-language in this phase. Keep public edge semantics narrow: equality, repeated-value membership, and the existing runtime-compatible search options only.
- **D-09:** `per_query` is not part of the primary browser-friendly grammar for this phase. Do not widen the public edge around advanced Meilisearch tuning just to make Phoenix examples feel shorter.

### Error contract
- **D-10:** Invalid request-edge input should become an expected non-raising result, not an exception. Phase 81 should introduce a public normalize/cast path that returns `{:ok, query_params}` or `{:error, error_map}`.
- **D-11:** The core public error contract should be aggregate and field-scoped, not first-error-only and not a literal `%Ecto.Changeset{}`.
- **D-12:** The error payload should contain:
  - `form_errors` for root-level issues such as unknown params or mutually exclusive combinations
  - `field_errors` keyed by top-level public fields such as `:q`, `:filter`, `:sort`, `:page`, `:facets`, and `:facet_filter`
  - `errors` as a flat machine-readable list for tests, logging, and adapters
- **D-13:** Each issue should include stable machine-readable metadata, at minimum `code`, `message`, `path`, and `meta`; `field` is useful when the issue belongs to one top-level field.
- **D-14:** Do not freeze Ecto-specific changeset semantics into the core edge contract. A Phoenix/Ecto adapter may project Scrypath errors into `to_form/2`-friendly tuples, but the core contract stays framework-light.
- **D-15:** Keep request-edge normalization errors clearly separate from later schema-specific runtime validation or backend/search errors.

### Phoenix helper surface
- **D-16:** Ship one optional Phoenix namespace with plain helper functions only. The default recommended public shape is `Scrypath.Phoenix`, not macros and not controller mixins.
- **D-17:** Phoenix helpers may bridge normalized Scrypath data into:
  - `Phoenix.Component.to_form/2`-friendly values and errors
  - verified-route query params / URL round-tripping
  - very thin `from_params` convenience that delegates to the core normalizer
- **D-18:** Phoenix helpers must not execute searches, call app contexts, own socket lifecycle transitions, or become the canonical runtime path.
- **D-19:** Do not ship public controller helpers, `use Scrypath.Phoenix`, generated components, or styled search widgets in this phase.
- **D-20:** Keep helper naming literal and boring. The surface should read as param/form/url helpers, not as a Phoenix search framework.

### LiveView flow
- **D-21:** The canonical LiveView pattern is `handle_params/3` first. URL params are the shareable source of truth for search state.
- **D-22:** `handle_event/3` should only collect transient UI intent and compute/push the next URL state with `push_patch/2` or equivalent navigation. It should not be a second search execution path.
- **D-23:** `handle_params/3` should be the single place that:
  - reads URL params
  - normalizes them once through the Scrypath edge contract
  - assigns attempted values plus field-scoped errors for rendering
  - calls the app context when normalization succeeds
- **D-24:** On normalization failure, LiveView should render the attempted state and field errors directly without searching and without collapsing errors into flash-only messaging.
- **D-25:** Phoenix helpers may support form-friendly value/error shaping and URL param round-tripping for LiveView, but they must not hide state transitions behind macros or opaque callbacks.

### Decision cadence
- **D-26:** Bias toward decisive, conservative defaults during planning and implementation. Only escalate choices that materially affect public API shape, milestone boundary honesty, or future semver cost.

### Claude's Discretion
- Exact function names inside the chosen plain-function Phoenix namespace, as long as they stay literal and narrow.
- Exact issue-code taxonomy, provided codes stay stable, obvious, and scoped to request-edge failures.
- Exact defaulting behavior for blank/absent optional params, provided it is explicit and documented.
- Exact projection helper names for Phoenix forms/JSON, provided they remain adapters over the same core error contract.

### Deferred Ideas (OUT OF SCOPE)
- Rich predicate/operator DSLs at the public edge
- Public controller wrappers or macros such as `use Scrypath.Phoenix`
- Reusable rendered search components or widget layers
- Event-only LiveView abstractions that treat socket assigns as the canonical search state
- Public browser-friendly expansion of advanced `per_query` tuning
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QTK-02 | The public toolkit normalizes text, filters, sort, pagination, facets, and facet-filter input once at the edge while preserving explicit defaults and limits. [VERIFIED: .planning/REQUIREMENTS.md] | Recommend extending `Scrypath.QueryParams.Caster` from top-level envelope casting into conservative Plug-shaped nested param normalization, while preserving the existing plain-data contract consumed by `to_search_args/1`. [VERIFIED: lib/scrypath/query_params.ex] [VERIFIED: lib/scrypath/query_params/caster.ex] [VERIFIED: test/scrypath/query_params_test.exs] [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] |
| QTK-03 | Invalid edge input returns structured, field-scoped errors that host apps can render directly instead of relying on ad hoc controller or LiveView branching. [VERIFIED: .planning/REQUIREMENTS.md] | Recommend replacing the current raise-on-nested-shape seam with `{:ok, query_params} | {:error, error_map}` aggregation, while keeping later runtime validation errors separate from edge normalization failures. [VERIFIED: lib/scrypath/query_params/caster.ex] [VERIFIED: lib/scrypath/options.ex] [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] |
| PHX-01 | Optional Phoenix helpers support URL and form round-tripping over the toolkit without introducing a hard Phoenix dependency in runtime core. [VERIFIED: .planning/REQUIREMENTS.md] | Recommend thin `Scrypath.Phoenix` helpers that produce string-keyed param maps, query strings, and `to_form/2`-friendly value/error shapes, without calling contexts or depending on route macros. [VERIFIED: test/support/docs/phoenix_example_case.ex] [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2] |
| PHX-02 | Optional LiveView helpers support param-driven search flows and error display while keeping URL params as the shareable UI state. [VERIFIED: .planning/REQUIREMENTS.md] | Recommend `handle_params/3` as the single normalization and search boundary, with `handle_event/3` limited to computing the next URL state and calling `push_patch/2`. [VERIFIED: guides/phoenix-liveview.md] [VERIFIED: guides/faceted-search-with-phoenix-liveview.md] [VERIFIED: test/support/docs/phoenix_example_case.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
</phase_requirements>

## Summary

The checked-out code already exposes the right public root for this phase, but it is still deliberately incomplete. `Scrypath.QueryParams.cast/1` currently returns one stable plain-data shape and `to_search_args/1` cleanly feeds `Scrypath.search/3`, yet the caster only handles the top-level request envelope and raises `ArgumentError` when nested request-style maps are passed for `filter`, `sort`, `page`, or `per_query`. Phase 80’s verification report explicitly deferred browser-style nested normalization to Phase 81, and the current tests lock that deferral in place. [VERIFIED: lib/scrypath/query_params.ex] [VERIFIED: lib/scrypath/query_params/caster.ex] [VERIFIED: test/scrypath/query_params_test.exs] [VERIFIED: .planning/phases/80-public-query-toolkit-contract/80-VERIFICATION.md]

The live Phoenix-facing examples also prove where the duplication pressure is today. The docs fixture hand-rolls page parsing in the API controller example and genre parsing in the faceted LiveView example, while the guides keep repeating the same context-first rule: controllers and LiveViews translate params, contexts remain the canonical search boundary, and `Scrypath.search/3` stays the runtime. Phase 81 should therefore standardize only the edge grammar, error contract, and round-tripping helpers, not move search execution into helpers or widen into a Phoenix façade. [VERIFIED: test/support/docs/phoenix_example_case.ex] [VERIFIED: test/support/docs/phoenix_examples_test.exs] [VERIFIED: guides/phoenix-contexts.md] [VERIFIED: guides/phoenix-controllers-and-json.md] [VERIFIED: guides/phoenix-liveview.md] [VERIFIED: .planning/PROJECT.md]

Plug’s current docs are the key external constraint on the public grammar. Plug decodes `foo[bar]` into nested maps and `foo[]` into lists, but it documents nesting inside lists as ambiguous and unspecified behavior. That makes the context decision to prefer `filter[field]`, `filter[field][]`, `page[number]`, `page[size]`, `facets[]`, and either simple `sort[field]`/`sort[dir]` or explicit indexed sort entries the correct browser grammar for this phase. LiveView’s current docs also reinforce the chosen lifecycle: `handle_params/3` runs after mount, and `push_patch/2` immediately re-invokes `handle_params/3` for same-LiveView URL changes. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

**Primary recommendation:** implement Phase 81 as three bounded slices: core non-raising nested-param normalization with aggregate field errors, reverse param/query-string encoding plus Phoenix form projection, and LiveView/docs fixture alignment around `handle_params/3` as the only search path. [ASSUMED]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Browser-shaped param normalization | API / Backend | Frontend Server (SSR) | Params arrive through Phoenix, but normalization lands in `Scrypath.QueryParams` on the server side and must feed the existing Elixir runtime. [VERIFIED: lib/scrypath/query_params.ex] [VERIFIED: guides/phoenix-contexts.md] |
| Aggregate edge error contract | API / Backend | Frontend Server (SSR) | The error shape should be framework-light and reusable outside Phoenix, with Phoenix only projecting it for forms or UI rendering. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [VERIFIED: lib/scrypath/query_params/caster.ex] |
| Phoenix URL and form helpers | Frontend Server (SSR) | API / Backend | These helpers exist only to shape request params, query strings, and form-friendly data around the server-side normalizer. [VERIFIED: test/support/docs/phoenix_example_case.ex] [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2] |
| LiveView URL-state ownership | Frontend Server (SSR) | API / Backend | LiveView should own URL patching and UI assigns, while the shared search boundary stays in the app context. [VERIFIED: guides/phoenix-liveview.md] [VERIFIED: guides/faceted-search-with-phoenix-liveview.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Search execution | API / Backend | — | `Scrypath.search/3` remains the only canonical runtime path, and no helper in this phase should compete with it. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: lib/scrypath.ex] |

## Standard Stack

### Core
| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `Scrypath.QueryParams` | in-repo public surface. [VERIFIED: lib/scrypath/query_params.ex] | Stable plain-data edge contract and `to_search_args/1` bridge. [VERIFIED: lib/scrypath/query_params.ex] | Phase 81 should deepen this existing seam instead of inventing a second public module. [VERIFIED: .planning/phases/80-public-query-toolkit-contract/80-RESEARCH.md] |
| `Scrypath.QueryParams.Caster` | in-repo internal seam. [VERIFIED: lib/scrypath/query_params/caster.ex] | One-time nested request-param normalization and error aggregation. [VERIFIED: lib/scrypath/query_params/caster.ex] | The current raise-on-nested-shape code already marks the exact seam Phase 81 must replace. [VERIFIED: lib/scrypath/query_params/caster.ex] |
| `Scrypath.Options.validate_search_options/2` | in-repo runtime validator. [VERIFIED: lib/scrypath/options.ex] | Canonical downstream validation for `filter`, `sort`, `page`, `facets`, `facet_filter`, and `per_query`. [VERIFIED: lib/scrypath/options.ex] | Reusing it prevents grammar drift between edge helpers and the runtime. [VERIFIED: lib/scrypath/options.ex] |
| `Plug.Conn.Query` | project lock `1.19.1`; current docs `1.19.2`. [VERIFIED: mix.lock] [VERIFIED: `mix hex.info plug`] [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] | Canonical encoding and decoding model for browser query params. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] | Plug’s explicit guidance on nested maps, lists, and ambiguous nested-list decoding should define the public browser grammar. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] |
| `NimbleOptions` | declared `~> 1.1`. [VERIFIED: mix.exs] | Stable validation machinery for option schemas and error messages. [VERIFIED: lib/scrypath/options.ex] | Scrypath already uses it in runtime validation, so Phase 81 should extend the same validation idiom rather than invent a second one. [VERIFIED: lib/scrypath/options.ex] |

### Supporting
| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `Phoenix.Component.to_form/2` | current stable line documented in Phoenix LiveView `1.1.x`; `1.1.30` is the latest stable release surfaced by Hex in this session. [VERIFIED: `mix hex.info phoenix_live_view`] [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2] | Host-app form rendering over string-keyed params and projected errors. [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2] | Use only in optional Phoenix projection helpers or docs examples; the core contract should stay usable without Phoenix. [VERIFIED: .planning/REQUIREMENTS.md] |
| `Phoenix.LiveView.handle_params/3` and `push_patch/2` | latest stable surfaced as `1.1.30`. [VERIFIED: `mix hex.info phoenix_live_view`] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] | Canonical URL-driven search flow in LiveView. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] | Use when documenting or testing shareable search state; keep `handle_event/3` limited to URL mutation intent. [VERIFIED: guides/phoenix-liveview.md] |
| `Phoenix.HTML.FormData` | latest surfaced as `4.3.0`. [VERIFIED: `mix hex.info phoenix_html`] [CITED: https://hexdocs.pm/phoenix_html/Phoenix.HTML.FormData.html] | Optional lower-level form projection target if the library exposes direct form structs later. [CITED: https://hexdocs.pm/phoenix_html/Phoenix.HTML.FormData.html] | Only use if Phase 81 needs more than data-plus-errors maps; otherwise prefer map-based `to_form/2` inputs. [ASSUMED] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Conservative Plug-native keys (`filter[field]`, `filter[field][]`, indexed sort entries) | Rich nested-list DSLs such as `filter[][field]` and `sort[][dir]` | Reject for Phase 81 because Plug documents nesting inside lists as ambiguous and unspecified behavior. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] |
| Framework-light error map | Core `%Ecto.Changeset{}` contract | Reject for core API because the context already decided not to freeze Ecto-specific semantics into the public edge contract. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] |
| URL-owned LiveView state via `handle_params/3` | Event-owned search execution in `handle_event/3` | Reject because current guides and official LiveView docs both make URL params the shareable state and `push_patch/2` the way to re-enter `handle_params/3`. [VERIFIED: guides/faceted-search-with-phoenix-liveview.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Narrow browser grammar without `per_query` | Browser-exposed advanced tuning params | Reject for this phase because the context explicitly keeps `per_query` out of the primary browser grammar. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] |

**Installation:**
```elixir
# No new dependency is required for core Phase 81 normalization.
# Keep Phoenix optional at the host-app edge unless direct Phoenix API calls
# are added to the library surface.
```
[VERIFIED: mix.exs] [VERIFIED: .planning/REQUIREMENTS.md]

**Version verification:** Elixir `1.19.5`, Mix `1.19.5`, and OTP `28` are installed in this workspace. Plug is locked at `1.19.1` in the repo, with current docs at `1.19.2`; current Hex metadata in this session shows Phoenix `1.8.7`, Phoenix.HTML `4.3.0`, and Phoenix LiveView `1.1.30` as the relevant stable lines for optional helper guidance. [VERIFIED: `mix --version`] [VERIFIED: `elixir --version`] [VERIFIED: `mix hex.info plug`] [VERIFIED: `mix hex.info phoenix`] [VERIFIED: `mix hex.info phoenix_html`] [VERIFIED: `mix hex.info phoenix_live_view`]

## Architecture Patterns

### System Architecture Diagram

```text
Browser URL / controller params / LiveView params
                    |
                    v
      Scrypath.QueryParams.normalize/cast
      - accepts conservative Plug-native keys
      - returns {:ok, query_params} or {:error, edge_errors}
                    |
         +----------+-----------+
         |                      |
         v                      v
  Scrypath.Phoenix helpers   Host app non-Phoenix callers
  - attempted param map      - direct tuple handling
  - query string / URL map
  - to_form-friendly data
         |
         v
 Phoenix controller / LiveView
 - render errors directly
 - on success call app context
 - LiveView handle_event only computes next URL
         |
         v
 App context / context-owned search function
         |
         v
 Scrypath.search/3
         |
         v
 Scrypath.Options.validate_search_options/2
         |
         v
 internal %Scrypath.Query{} -> backend payload
```
[VERIFIED: lib/scrypath/query_params.ex] [VERIFIED: lib/scrypath/query_params/caster.ex] [VERIFIED: lib/scrypath/search.ex] [VERIFIED: guides/phoenix-contexts.md] [VERIFIED: guides/phoenix-liveview.md]

### Recommended Project Structure
```text
lib/
├── scrypath/query_params.ex          # public edge facade
├── scrypath/query_params/caster.ex   # nested param normalization + error aggregation
├── scrypath/query_params/errors.ex   # optional core error structs/types if added
└── scrypath/phoenix.ex               # optional thin param/form/url projection helpers

test/
├── scrypath/query_params_test.exs            # core browser grammar + error contract
├── scrypath/phoenix_test.exs                 # optional Phoenix helper projections
└── support/docs/phoenix_example_case.ex      # docs fixture kept aligned with the helper contract
```
[VERIFIED: lib/scrypath/query_params.ex] [VERIFIED: lib/scrypath/query_params/caster.ex] [VERIFIED: test/scrypath/query_params_test.exs] [VERIFIED: test/support/docs/phoenix_example_case.ex] [ASSUMED]

### Pattern 1: Normalize Once At The Edge
**What:** Introduce one public non-raising cast/normalize path that consumes Plug-shaped nested params and returns either stable query params or aggregate edge errors. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [VERIFIED: lib/scrypath/query_params/caster.ex]
**When to use:** Every controller, JSON, or LiveView path that turns browser params into `Scrypath.search/3` inputs. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: test/support/docs/phoenix_example_case.ex]
**Example:**
```elixir
# Source: lib/scrypath/query_params.ex
with {:ok, query_params} <- Scrypath.QueryParams.cast(params) do
  {text, search_opts} = Scrypath.QueryParams.to_search_args(query_params)
  Content.search_posts(text, search_opts)
end
```
[VERIFIED: lib/scrypath/query_params.ex] [ASSUMED]

### Pattern 2: Keep Core Errors Framework-Light, Project In Phoenix
**What:** The core result should stay a plain Elixir error map, while optional Phoenix helpers convert attempted values and field errors into `to_form/2`-friendly inputs. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2]
**When to use:** Whenever a controller or LiveView wants one-pass field rendering without encoding `%Ecto.Changeset{}` semantics into the core library. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```elixir
# Source: Phoenix.Component docs
form = to_form(user_params, as: :user)
```
[CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2]

### Pattern 3: LiveView Uses URL Params As The Shareable Source Of Truth
**What:** `handle_params/3` reads params, normalizes once, renders attempted state and errors, and only then calls the app context on success. `handle_event/3` computes the next URL and patches it. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [VERIFIED: guides/faceted-search-with-phoenix-liveview.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
**When to use:** Search pages and faceted catalog flows that need refreshable and shareable state. [VERIFIED: guides/phoenix-liveview.md] [VERIFIED: guides/faceted-search-with-phoenix-liveview.md]
**Example:**
```elixir
# Source: test/support/docs/phoenix_example_case.ex
def handle_params(params, socket) do
  q = Map.get(params, "q", "")
  genres = parse_genres(params["genre"])
  ...
end
```
[VERIFIED: test/support/docs/phoenix_example_case.ex]

### Anti-Patterns to Avoid
- **Raising from the public edge normalizer:** the current `ArgumentError` seam is exactly what `QTK-03` says to replace. [VERIFIED: lib/scrypath/query_params/caster.ex] [VERIFIED: test/scrypath/query_params_test.exs]
- **Route or LiveView macros in the library:** Phase 81 should ship plain helper functions, not `use Scrypath.Phoenix` or controller mixins. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md]
- **A second search path inside helpers:** no helper in this phase should call contexts or `Scrypath.search/3` itself. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/PROJECT.md]
- **Browser exposure of `per_query` or range-operator mini-languages:** runtime support exists internally, but the context has explicitly narrowed the browser grammar for this phase. [VERIFIED: lib/scrypath/options.ex] [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md]

## Recommended Plan Slices

1. **Core nested grammar + error contract.** Extend `Scrypath.QueryParams.Caster` so `filter`, `facet_filter`, `sort`, `page`, and `facets` accept conservative Plug-native nested params and return aggregate field errors instead of raising. Preserve the current public map shape and `to_search_args/1` bridge. [VERIFIED: lib/scrypath/query_params.ex] [VERIFIED: lib/scrypath/query_params/caster.ex] [VERIFIED: test/scrypath/query_params_test.exs]
2. **Reverse encoding + Phoenix projection.** Add thin helpers that turn normalized query params back into string-keyed nested param maps and query strings, plus helpers that project attempted values and field errors into `to_form/2`-friendly data without performing search. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2] [ASSUMED]
3. **LiveView and docs-fixture alignment.** Update the docs fixture and guides to show `handle_params/3` as the single normalization/search path, `push_patch/2` as the URL mutation path, and direct rendering of field errors on invalid input. [VERIFIED: test/support/docs/phoenix_example_case.ex] [VERIFIED: guides/phoenix-liveview.md] [VERIFIED: guides/faceted-search-with-phoenix-liveview.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Query-string grammar | A custom URL encoder/decoder disconnected from Plug | `Plug.Conn.Query` shapes and encoding rules | Plug already defines how nested maps and `[]` lists behave, and it explicitly warns against ambiguous nested lists. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] |
| Search execution helper | `search_from_params/…` or controller-facing search façades | `Scrypath.QueryParams.to_search_args/1` + app context + `Scrypath.search/3` | The phase goal is edge normalization only, and the repo keeps contexts canonical. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: guides/phoenix-contexts.md] |
| Core Phoenix changeset contract | `%Ecto.Changeset{}` as the public error surface | Plain core error map + optional Phoenix projection | The core library must stay framework-light and reusable outside Phoenix. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] |
| LiveView state machine abstraction | Macros that hide `handle_params/3` / `push_patch/2` flow | Plain helper functions plus guide patterns | LiveView docs already provide the lifecycle; hiding it would obscure URL ownership and error handling. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Predicate DSL | Public browser operators for boolean composition and advanced range syntax | Narrow scalar-or-repeated-value grammar | Runtime validation currently supports some operators internally, but the context explicitly rejects browser-facing DSL expansion in this phase. [VERIFIED: lib/scrypath/options.ex] [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] |

**Key insight:** the hard runtime semantics already exist; Phase 81 should standardize only how browser params enter and leave that runtime. [VERIFIED: lib/scrypath/search.ex] [VERIFIED: lib/scrypath/options.ex]

## Common Pitfalls

### Pitfall 1: Ambiguous Nested-List Grammar
**What goes wrong:** Public APIs accept shapes like `sort[][field]` or `filter[][status]`, which Plug does decode somehow but documents as ambiguous and unspecified. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html]
**Why it happens:** Nested list shapes look concise in URLs and HTML forms, so they are tempting for “multiple sorts” or complex filter groups. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html]
**How to avoid:** Use `sort[field]` + `sort[dir]` for the common case and explicit indexed entries like `sort[0][field]` only if multi-sort is truly required. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html]
**Warning signs:** The planner or implementation proposes unindexed `[]` nesting for maps inside lists. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html]

### Pitfall 2: Public Edge Errors Still Raise
**What goes wrong:** Controllers and LiveViews still need `try/rescue` or branch on exceptions because `QueryParams.cast/1` keeps raising on malformed nested params. [VERIFIED: lib/scrypath/query_params/caster.ex] [VERIFIED: test/scrypath/query_params_test.exs]
**Why it happens:** Phase 80 intentionally used runtime-compatible nested values only and deferred the real edge contract. [VERIFIED: .planning/phases/80-public-query-toolkit-contract/80-VERIFICATION.md]
**How to avoid:** Introduce one aggregate, non-raising result at the request edge and keep later runtime or backend failures on their existing paths. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [VERIFIED: lib/scrypath/options.ex]
**Warning signs:** Proposed controller or LiveView examples still rescue `ArgumentError` from `Scrypath.QueryParams.cast/1`. [VERIFIED: lib/scrypath/query_params/caster.ex]

### Pitfall 3: Freezing Phoenix Or Ecto Semantics Into The Core Contract
**What goes wrong:** The core toolkit returns `%Ecto.Changeset{}`, `Phoenix.HTML.Form`, or route-macro-specific values as its primary output. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md]
**Why it happens:** `to_form/2` is convenient, and Phoenix apps are a major target audience. [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2]
**How to avoid:** Keep the core error/result shape plain, then project it into `to_form/2`-friendly values only in an optional adapter layer. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md]
**Warning signs:** Specs or docs for `Scrypath.QueryParams` mention changesets, form structs, or route helpers directly. [VERIFIED: lib/scrypath/query_params.ex]

### Pitfall 4: LiveView Owns Two Search Paths
**What goes wrong:** `handle_event/3` executes search directly while `handle_params/3` also executes search, so refresh and share-link behavior diverge. [VERIFIED: guides/faceted-search-with-phoenix-liveview.md] [VERIFIED: test/support/docs/phoenix_example_case.ex]
**Why it happens:** Event handlers feel convenient for immediate feedback, especially during form typing or checkbox toggles. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
**How to avoid:** Restrict `handle_event/3` to computing the next URL state and calling `push_patch/2`; let `handle_params/3` remain the single search boundary. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
**Warning signs:** LiveView examples mutate assigns directly for filters or search text without deriving them back from params. [VERIFIED: guides/faceted-search-with-phoenix-liveview.md]

### Pitfall 5: Browser Grammar Widens Past The Milestone Boundary
**What goes wrong:** Phase 81 starts exposing `per_query`, boolean composition, or range-operator syntax because the runtime already supports some of those shapes internally. [VERIFIED: lib/scrypath/options.ex]
**Why it happens:** The internal runtime grammar is richer than the public browser grammar chosen in context. [VERIFIED: lib/scrypath/options.ex] [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md]
**How to avoid:** Keep browser input limited to `q`, scalar-or-repeated filters, page number/size, facets, and the narrow sort grammar for this phase. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md]
**Warning signs:** New tests or docs include `per_query[...]`, `filter[field][gte]`, or `filter[or][...]` browser examples. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [VERIFIED: lib/scrypath/options.ex]

## Code Examples

Verified patterns from official sources and current repo code:

### Conservative Plug Query Grammar
```text
filter[status]=published
filter[status][]=published&filter[status][]=scheduled
page[number]=2&page[size]=20
sort[field]=inserted_at&sort[dir]=desc
sort[0][field]=inserted_at&sort[0][dir]=desc
```
Source: Plug query decoding rules plus the phase context’s chosen grammar. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md]

### `to_form/2` Expects String-Keyed Params For Map Input
```elixir
def handle_event("submitted", %{"user" => user_params}, socket) do
  {:noreply, assign(socket, form: to_form(user_params, as: :user))}
end
```
Source: Phoenix.Component docs. [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2]

### LiveView URL Patch Re-Enters `handle_params/3`
```elixir
{:noreply, push_patch(socket, to: "/")}
```
Source: Phoenix.LiveView docs. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

### Current Docs Fixture Pressure Point
```elixir
def handle_params(params, socket) do
  q = Map.get(params, "q", "")
  genres = parse_genres(params["genre"])
  ...
end
```
Source: current docs fixture showing manual parsing that Phase 81 should absorb. [VERIFIED: test/support/docs/phoenix_example_case.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Request-edge code hand-rolls page and facet parsing in Phoenix examples. [VERIFIED: test/support/docs/phoenix_example_case.ex] | The repo now has `Scrypath.QueryParams`, but only for the top-level envelope and runtime-compatible nested values. [VERIFIED: lib/scrypath/query_params.ex] [VERIFIED: lib/scrypath/query_params/caster.ex] | Phase 80 landed on 2026-05-22. [VERIFIED: .planning/phases/80-public-query-toolkit-contract/80-VERIFICATION.md] | Phase 81 can standardize edge parsing without inventing a new runtime. [VERIFIED: .planning/ROADMAP.md] |
| Invalid nested request-style params currently raise `ArgumentError`. [VERIFIED: lib/scrypath/query_params/caster.ex] | Phase 81 context now requires a non-raising aggregate error contract. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] | Decision gathered 2026-05-22. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] | Controllers and LiveViews should be able to render errors directly instead of rescuing exceptions. [VERIFIED: .planning/REQUIREMENTS.md] |
| LiveView guide already prefers URL-param-driven `handle_params/3` flows. [VERIFIED: guides/faceted-search-with-phoenix-liveview.md] | Official LiveView docs still say `push_patch/2` immediately re-invokes `handle_params/3` on same-view navigation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] | Verified in current docs during this session. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] | The repo’s chosen URL-state ownership is aligned with current Phoenix guidance, so Phase 81 should reinforce it rather than invent abstractions around it. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] |

**Deprecated/outdated:**
- Using `Scrypath.QueryParams.cast/1` as the final Phase 81 behavior is outdated because the current implementation still carries the explicit Phase 80 “runtime-compatible nested values only” limitation. [VERIFIED: lib/scrypath/query_params.ex] [VERIFIED: test/scrypath/query_params_test.exs] [VERIFIED: .planning/phases/80-public-query-toolkit-contract/80-VERIFICATION.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Scrypath.Phoenix` can stay dependency-light by returning data structures and query strings instead of directly depending on Phoenix route macros or LiveView modules. [ASSUMED] | Summary; Standard Stack; Recommended Plan Slices | If wrong, the phase will need optional Phoenix deps plus compile/no-optional-deps verification work earlier than planned. |
| A2 | A dedicated `lib/scrypath/query_params/errors.ex` file is a healthy place for public error structs or types if the error contract becomes large enough. [ASSUMED] | Recommended Project Structure | If wrong, the implementation may fit better as types in `query_params.ex` or private maps only, which is a low-cost structural change. |

## Open Questions

1. **Should the optional Phoenix surface call `to_form/2` directly or only return data and errors that the host app passes to `to_form/2`?**
   - What we know: current Phoenix docs say map input to `to_form/2` expects string-keyed params, and the phase context only requires `to_form/2`-friendly values and errors. [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2] [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md]
   - What's unclear: whether the planner wants zero Phoenix deps in the library or accepts optional compile-time Phoenix deps for a direct helper. [VERIFIED: mix.exs] [ASSUMED]
   - Recommendation: default to data-returning helpers first because that keeps the public edge reusable and minimizes dependency pressure. [ASSUMED]

2. **Should multi-sort ship now or remain single-sort-only in the browser grammar?**
   - What we know: the context allows indexed sort entries only if multi-sort is supported, and Plug warns against ambiguous nested lists. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html]
   - What's unclear: whether current consumer pressure justifies more than `sort[field]` + `sort[dir]` in this milestone. [VERIFIED: test/support/docs/phoenix_example_case.ex] [ASSUMED]
   - Recommendation: plan single-sort as the default slice and treat indexed multi-sort as optional only if tests or docs need it. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compilation and tests | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Erlang / OTP | Compilation and tests | ✓ [VERIFIED: `elixir --version`] | `28` [VERIFIED: `elixir --version`] | — |
| Mix | Compilation, test, Hex metadata checks | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| Plug | Query grammar and encoding rules | ✓ [VERIFIED: mix.lock] | locked `1.19.1`; current docs `1.19.2` [VERIFIED: mix.lock] [VERIFIED: `mix hex.info plug`] | — |
| Phoenix in repo deps | Direct compiled Phoenix helper APIs, if Phase 81 adds them | ✗ in current repo deps. [VERIFIED: mix.exs] | — | Keep helpers data-only, or add optional deps with compile guards. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [ASSUMED] |
| Phoenix LiveView in repo deps | Direct `to_form/2` or LiveView-specific helper code, if Phase 81 adds it | ✗ in current repo deps. [VERIFIED: mix.exs] | — | Use docs fixtures plus optional deps only if direct API calls are necessary. [VERIFIED: test/support/docs/phoenix_example_case.ex] [ASSUMED] |

**Missing dependencies with no fallback:**
- None for the core normalization slice. [VERIFIED: mix.exs] [VERIFIED: lib/scrypath/query_params.ex]

**Missing dependencies with fallback:**
- Phoenix and Phoenix LiveView are not current repo dependencies, but the phase can still proceed with data-only helper design or optional-dependency compile guards. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [ASSUMED]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: `mix --version`] [VERIFIED: `elixir --version`] |
| Config file | `mix.exs` plus default `mix test` conventions; no separate `test_helper`-level custom framework was required for the inspected phase tests. [VERIFIED: mix.exs] [VERIFIED: test/scrypath/query_params_test.exs] |
| Quick run command | `mix test test/scrypath/query_params_test.exs test/support/docs/phoenix_examples_test.exs` [VERIFIED: local command run on 2026-05-23] |
| Full suite command | `mix test` [VERIFIED: mix.exs] [VERIFIED: local command run on 2026-05-23] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QTK-02 | Nested browser params normalize once into the existing public query-param map for `q`, `filter`, `sort`, `page`, `facets`, and `facet_filter`. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/scrypath/query_params_test.exs` | ✅ existing file, but new nested-browser cases are required. [VERIFIED: test/scrypath/query_params_test.exs] |
| QTK-03 | Invalid browser input returns aggregate field-scoped errors instead of raising. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/scrypath/query_params_test.exs` | ✅ existing file, but error-map coverage is missing today. [VERIFIED: test/scrypath/query_params_test.exs] |
| PHX-01 | Optional helpers round-trip normalized state into nested param maps, query strings, and form-friendly values/errors without searching. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/scrypath/phoenix_test.exs` | ❌ Wave 0. [ASSUMED] |
| PHX-02 | LiveView search state is URL-owned: params normalize in `handle_params/3`, invalid params render errors without searching, and events only push the next URL. [VERIFIED: .planning/REQUIREMENTS.md] | docs fixture / bounded integration | `mix test test/support/docs/phoenix_examples_test.exs` | ✅ existing fixture test file, but failure-path and URL-patch assertions are missing. [VERIFIED: test/support/docs/phoenix_examples_test.exs] |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/query_params_test.exs test/support/docs/phoenix_examples_test.exs` [VERIFIED: local command run on 2026-05-23]
- **Per wave merge:** `mix test` [VERIFIED: local command run on 2026-05-23]
- **Phase gate:** Full suite green before `/gsd-verify-work`; note that the current branch already has two unrelated docs/package failures outside Phase 81. [VERIFIED: local `mix test` run on 2026-05-23]

### Wave 0 Gaps
- [ ] Extend `test/scrypath/query_params_test.exs` with nested Plug-shaped success cases for `filter`, `facet_filter`, `sort`, `page`, and `facets`. [VERIFIED: test/scrypath/query_params_test.exs]
- [ ] Extend `test/scrypath/query_params_test.exs` with aggregate `{:error, error_map}` cases for invalid page integers, unknown nested keys, invalid facet lists, and malformed sort/filter shapes. [VERIFIED: test/scrypath/query_params_test.exs] [ASSUMED]
- [ ] Add `test/scrypath/phoenix_test.exs` for param round-tripping, query-string encoding, and optional form projection helpers. [ASSUMED]
- [ ] Extend `test/support/docs/phoenix_examples_test.exs` and `test/support/docs/phoenix_example_case.ex` with invalid-param/no-search LiveView and controller cases. [VERIFIED: test/support/docs/phoenix_examples_test.exs] [VERIFIED: test/support/docs/phoenix_example_case.ex]
- [ ] If optional Phoenix deps are introduced, add `mix compile --no-optional-deps --warnings-as-errors` to the phase verification spine so the library still compiles without them. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [ASSUMED]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no. [VERIFIED: .planning/REQUIREMENTS.md] | — |
| V3 Session Management | no. [VERIFIED: .planning/REQUIREMENTS.md] | — |
| V4 Access Control | no for library core; the phase shapes params but does not enforce authz. [VERIFIED: .planning/PROJECT.md] | Host app authorization stays outside this phase. [VERIFIED: guides/phoenix-contexts.md] |
| V5 Input Validation | yes. [VERIFIED: .planning/REQUIREMENTS.md] | Allowlisted field names, conservative Plug grammar, positive-integer page parsing, and stable machine-readable edge errors. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [VERIFIED: lib/scrypath/options.ex] [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] |
| V6 Cryptography | no. [VERIFIED: .planning/REQUIREMENTS.md] | — |

### Known Threat Patterns for This Stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dynamic atom creation from user params | Denial of service | Keep request keys string-based until mapped through explicit allowlists; do not call `String.to_atom/1` on untrusted params. [VERIFIED: repo code grep] [CITED: https://hexdocs.pm/elixir/String.html] |
| Ambiguous nested-list query decoding | Tampering | Accept only Plug-native shapes with deterministic semantics and reject ambiguous list nesting. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] |
| Helper-driven second runtime path | Tampering | Keep helpers pure and data-first; require contexts to remain the only application search boundary. [VERIFIED: guides/phoenix-contexts.md] [VERIFIED: .planning/ROADMAP.md] |
| LiveView stale-assign drift from URL | Repudiation / Tampering | Derive shareable search state from params in `handle_params/3`, and use `push_patch/2` for state changes. [VERIFIED: guides/faceted-search-with-phoenix-liveview.md] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] |
| Overly raw error rendering | Information disclosure | Emit stable bounded messages and machine-readable codes; leave host templates to escape or style the content. [VERIFIED: .planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md] [ASSUMED] |

## Sources

### Primary (HIGH confidence)
- Repo files: `.planning/{ROADMAP,REQUIREMENTS,PROJECT,STATE}.md`, `.planning/phases/81-edge-normalization-errors-and-phoenix-wrappers/81-CONTEXT.md`, `.planning/phases/80-public-query-toolkit-contract/{80-RESEARCH,80-PATTERNS,80-VERIFICATION}.md`, `lib/scrypath/query_params.ex`, `lib/scrypath/query_params/caster.ex`, `lib/scrypath/options.ex`, `test/scrypath/query_params_test.exs`, `test/scrypath/search_test.exs`, `test/scrypath/meilisearch/query_test.exs`, `test/support/docs/{phoenix_example_case,phoenix_examples_test}.exs`, `guides/{phoenix-contexts,phoenix-liveview,phoenix-controllers-and-json,faceted-search-with-phoenix-liveview}.md`. [VERIFIED: local file reads]
- Plug docs: https://hexdocs.pm/plug/Plug.Conn.Query.html - nested map/list grammar, ambiguous nested-list warning, and query-string encoding rules. [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html]
- Phoenix LiveView docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html - `handle_params/3` lifecycle and `push_patch/2` URL-state behavior. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- Phoenix.Component docs: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2 - `to_form/2` behavior for map params and string-key expectations. [CITED: https://hexdocs.pm/phoenix_live_view/1.0.0/Phoenix.Component.html#to_form/2]
- Mix deps docs: https://hexdocs.pm/mix/Mix.Tasks.Deps.html - optional dependency semantics and `--no-optional-deps` compile recommendation. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

### Secondary (MEDIUM confidence)
- Hex package metadata queried locally with `mix hex.info phoenix`, `mix hex.info phoenix_html`, `mix hex.info phoenix_live_view`, and `mix hex.info plug` for current release lines. [VERIFIED: local commands]
- Prompt corpus files under `prompts/` for Elixir, Ecto, Phoenix, LiveView, search-library, OSS surface, and brand posture. [VERIFIED: local file reads]

### Tertiary (LOW confidence)
- None. [VERIFIED: research session review]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the live repo surface, Plug docs, and Phoenix docs all align on a narrow data-first edge contract. [VERIFIED: repo code grep] [CITED: https://hexdocs.pm/plug/Plug.Conn.Query.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]
- Architecture: HIGH - the repo’s guides, fixtures, and requirements all consistently keep contexts canonical and LiveView URL-driven. [VERIFIED: guides/phoenix-contexts.md] [VERIFIED: guides/phoenix-liveview.md] [VERIFIED: guides/faceted-search-with-phoenix-liveview.md]
- Pitfalls: HIGH - the current codebase already exhibits the exact deferred seams and manual parsing duplication the phase is meant to replace. [VERIFIED: lib/scrypath/query_params/caster.ex] [VERIFIED: test/support/docs/phoenix_example_case.ex] [VERIFIED: .planning/phases/80-public-query-toolkit-contract/80-VERIFICATION.md]

**Research date:** 2026-05-23 [VERIFIED: system date]
**Valid until:** 2026-06-22 for repo-state claims; re-check Phoenix and Plug release metadata after 30 days if exact optional-dependency guidance matters. [VERIFIED: local commands] [ASSUMED]
