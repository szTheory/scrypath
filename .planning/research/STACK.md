# Technology Stack

**Project:** Scrypath v1.22 - Composition And Real-App Depth  
**Researched:** 2026-05-23  
**Scope:** Stack additions and implementation support for bounded composition presets/scopes, `search_many/2`-aligned composition, and stronger UI metadata exposure.  
**Confidence:** HIGH

## Executive Recommendation

For v1.22, **do not add a new runtime subsystem**. Presets, scopes, composition, and UI metadata are a **pure library-layer concern** over the already-shipped plain-data query contract. The right stack move is:

1. **Keep core runtime dependencies flat**.
2. **Make `:telemetry` a direct dependency** because Scrypath already calls it directly and v1.22 increases reliance on metadata as public observability surface.
3. **Reuse `NimbleOptions` more aggressively** for bounded preset/scope/metadata definition validation and generated docs.
4. **Add `StreamData` as a test-only dependency** for merge, round-trip, and metadata invariant testing.
5. **Do not add Phoenix, LiveView, Plug-runtime, Flop, Ash/Spark, typed-struct DSLs, or a general composition framework** to core.

This milestone should feel like a stronger `Scrypath.QueryParams` / search-args composition layer, not like a second runtime, a UI kit, or a Phoenix mini-framework.

## Recommended Stack

### Core Runtime

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | `~> 1.17` | Core runtime floor | No new language/runtime pressure from composition work |
| Ecto | `~> 3.13` | Existing schema/context integration surface | Composition still belongs above contexts and search args, not in a new DSL engine |
| NimbleOptions | `~> 1.1` | Validate bounded preset/scope/metadata option shapes | Supports nested key schemas and documentation-oriented option contracts |
| Telemetry | `~> 1.4` | Direct public observability dependency | Scrypath already calls `:telemetry` directly; composition metadata makes this more central |
| Req | `~> 0.5` | Existing backend transport | No transport change is required for presets/scopes/metadata |
| Oban | `~> 2.21` optional | Existing async sync path | Unchanged; composition must not create queue/runtime coupling |

### Test Support

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| StreamData | `~> 1.3`, `only: [:dev, :test]` | Property tests for composition invariants | Use for right-biased merge rules, idempotent normalization, metadata projection, and `search_many/2` shared-vs-entry precedence |
| Req.Test | bundled with `req` | Backend stub/mocked transport testing | Keep using it for Meilisearch request-shape and failure-path tests; no extra HTTP mock library needed |
| Mox | none for v1.22 | Not recommended now | Add only if a real behaviour seam is introduced later; do not invent one for presets/scopes |

### Documentation / Verification Support

| Tool | Version | Purpose | Why |
|------|---------|---------|-----|
| ExDoc | existing `~> 0.37` | Guides and API docs | Enough for a new composition guide, metadata reference, and real-app examples |
| Docs contract tests | existing repo pattern | Prevent story drift | Use existing doc-lock pattern instead of adding another docs toolchain |
| Phoenix example app/docs fixtures | existing repo assets | Real-app proof | Reuse the existing example/test surfaces rather than pulling Phoenix into runtime core |

## Required Stack Changes

These are the only stack changes justified by the milestone.

### 1. Add direct `:telemetry` dependency

**Add:**

```elixir
{:telemetry, "~> 1.4"}
```

**Why this is required:**

- Scrypath already calls `:telemetry.span/3` and `:telemetry.execute/3` directly in core modules.
- Today `:telemetry` is present only transitively through deps such as Ecto, Finch, Plug, and Oban.
- v1.22 makes metadata a more explicit public surface through composition and UI metadata exposure, so relying on a transitive dependency is the wrong contract.

**This is a real stack correction**, not a design flourish.

### 2. Add `StreamData` as a test-only dependency

**Add:**

```elixir
{:stream_data, "~> 1.3", only: [:dev, :test], runtime: false}
```

**Why this is justified:**

- Composition introduces merge and projection laws that are easy to under-test with only hand-written cases.
- `ExUnitProperties` is designed for property-based testing and shrinking counterexamples, which fits:
  - preset merge associativity / precedence checks
  - scope composition idempotence
  - browser-param round-trip invariants
  - `search_many/2` shared-option vs per-entry-option precedence
  - metadata declaration ordering and canonicalization

**This is a test-only quality addition**, not a runtime expansion.

## Zero-Library Choices That Are Correct For v1.22

These are deliberate non-additions.

### 1. No new composition framework

Use **plain maps/keywords/functions** and `NimbleOptions` validation. Do not add a rule engine, macro-heavy DSL, or generic policy/composition library.

Reason:
- The bounded problem is “merge and expose known search args safely,” not “host arbitrary workflows.”
- A new framework would widen the public abstraction faster than the milestone justifies.

### 2. No Phoenix or LiveView runtime dependency in `scrypath`

Keep Phoenix support where it already belongs: optional wrappers, examples, and guides.

Reason:
- UI metadata exposure is still plain data.
- Hosts should be able to consume metadata from controllers, LiveViews, JSON APIs, or non-Phoenix Elixir apps.

### 3. No Flop, Ash/Spark, or admin/search-form libraries

Do not add `flop`, `ash`, `spark`, `ecto_filter`, or similar higher-level frameworks.

Reason:
- They would pull Scrypath toward app-framework territory instead of staying an Ecto-native search library.
- The milestone is about exposing declared metadata, not owning the host app's listing/filtering stack.

### 4. No typed-struct / embedded-schema DSL layer for metadata

Do not add `typed_struct`, `typed_ecto_schema`, or an `embedded_schema`-driven public metadata contract just to model presets or UI metadata.

Reason:
- The data is already naturally expressible as maps/keywords/atoms.
- Extra struct DSLs add compile-time surface and API freeze pressure without solving a runtime problem.

### 5. No Mox unless a real behaviour seam appears

Do not introduce a behaviour purely so tests can use Mox.

Reason:
- Presets/scopes should stay data-first and function-first.
- Existing HTTP/back-end testing is already well-covered by `Req.Test`.
- Introducing a behaviour here would encourage a fake extensibility promise.

## How To Use Existing Dependencies For v1.22

### NimbleOptions should carry the bounded public contract

Use `NimbleOptions` schemas for:

- preset definitions
- allowed scope keys
- metadata exposure options
- composition entry schemas for `search_many/2`-aligned helpers

Recommended posture:

- validate nested keys strictly
- reject unknown top-level preset/scope definition keys
- keep extension points narrow and explicit
- use generated option docs in module docs so the contract stays readable

This is the right use of the dependency already present in the repo.

### Req / Req.Test already cover the backend side

No new network test dependency is needed.

Use the existing `Req.Test` path for:

- backend payload assertions after composition
- transport errors during composed queries
- verifying that presets/scopes do not mutate Meilisearch wire semantics unexpectedly

### ExDoc + current docs-contract pattern are enough

Do not add a new docs site or playground dependency.

Instead, add:

- one canonical composition guide
- one metadata/UI-contract guide
- one real-app adoption guide showing repeated flows collapsing into presets/scopes
- contract tests that lock guide authority and terminology

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Runtime validation | `NimbleOptions` reuse | Custom structs / macro DSL | More compile-time surface and weaker docs story for little gain |
| Observability | Direct `:telemetry` dep | Keep transitive-only | Fragile for a public metadata-heavy surface |
| Property testing | `StreamData` | Hand-written cases only | Too weak for precedence and round-trip invariants |
| HTTP test support | `Req.Test` | `Bypass` / other stub servers | Extra dependency with no clear advantage for this milestone |
| Extensibility seam | No new behaviour | Introduce behaviour + Mox | Risks implying a broader public adapter/composition promise |
| UI integration | Plain metadata maps | Phoenix/LiveView runtime helpers in core | Accidental framework coupling |

## Installation

```elixir
# mix.exs
{:telemetry, "~> 1.4"}
{:stream_data, "~> 1.3", only: [:dev, :test], runtime: false}
```

No other dependency additions are recommended for v1.22.

## Explicitly Do NOT Add

- `phoenix` or `phoenix_live_view` to root `scrypath` runtime deps
- `plug` as a broader runtime dependency; keep it test-only unless an existing shipped contract truly changes
- `mox` for invented seams
- `bypass`
- `flop`
- `ash`, `spark`, or other declarative app frameworks
- `typed_struct`, `typed_ecto_schema`, or similar struct DSL packages
- any public multi-backend composition layer beyond the current internal backend seam
- any second runtime process, registry, or supervisor for presets/scopes

## Milestone Boundary Check

If a proposed addition does any of the following, reject it from v1.22:

- introduces a Phoenix runtime dependency into `scrypath` core
- implies “Scrypath owns your search UI” rather than exposing data for the host UI
- creates a new long-lived runtime process for composition
- turns bounded presets/scopes into a generic public adapter/plugin framework
- widens Meilisearch-first product scope into broader backend promises

## Sources

- Project context and milestone scope:
  - `.planning/PROJECT.md`
  - `.planning/MILESTONE-ARC.md`
  - `.planning/milestone-candidates.md`
  - `.planning/seeds/SEED-002-composition-real-app-depth.md`
- Current repo dependency shape:
  - `mix.exs`
  - `mix.lock`
  - `lib/scrypath/query_params.ex`
  - `lib/scrypath/query_params/caster.ex`
  - `lib/scrypath/phoenix.ex`
  - `lib/scrypath/telemetry.ex`
- Official/current package and docs sources:
  - NimbleOptions docs: https://hexdocs.pm/nimble_options/1.1.1/NimbleOptions.html
  - Req.Test docs: https://hexdocs.pm/req/Req.Test.html
  - StreamData docs: https://hexdocs.pm/stream_data/ExUnitProperties.html
  - Req package: https://hex.pm/packages/req
  - StreamData package: https://hex.pm/packages/stream_data
  - Mox package/docs: https://hex.pm/packages/mox , https://hexdocs.pm/mox/Mox.html
