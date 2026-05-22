# Phase 81: Edge normalization errors and Phoenix wrappers - Discussion Log

**Gathered:** 2026-05-22
**Mode:** `--all` style discussion with research-backed synthesis
**Status:** Complete

## Discussion approach

The user asked to discuss all gray areas and requested that the agent:
- research each area using subagents
- compare pros, cons, tradeoffs, and ecosystem idioms
- consider Elixir, Plug, Ecto, Phoenix, and lessons from successful libraries/apps in adjacent ecosystems
- incorporate the local `prompts/` research corpus
- prefer one coherent recommendation set rather than pushing many decisions back to the user
- bias GSD toward decisive defaults unless a decision is unusually high impact

## Areas discussed

### 1. Normalization grammar

**Options considered**
- Conservative Plug-native grammar
- Hybrid grammar with a few shorthands
- Rich query mini-language

**Recommendation locked**
- Use the conservative Plug-native grammar.
- Keep `q` primary with `text` as alias.
- Use browser-shaped bracket params and repeated keys only where Plug decodes them predictably.
- Use explicit indexed entries for multi-sort if needed; reject ambiguous nested-list syntax.
- Keep operators narrow and avoid a public predicate DSL.

**Why**
- Best fit for Phoenix/Plug expectations
- Lowest semver risk
- Keeps Scrypath in the request-edge toolkit category rather than query-DSL territory

### 2. Structured error contract

**Options considered**
- First-error only
- Aggregate field/root projections
- Literal `%Ecto.Changeset{}` return

**Recommendation locked**
- Return aggregate non-raising field-scoped errors from core.
- Use a stable issue shape with `code`, `message`, `path`, `meta`, and optional `field`.
- Group issues into `form_errors`, `field_errors`, and flat `errors`.
- Keep `%Ecto.Changeset{}` as an optional Phoenix/Ecto projection concern, not the core public contract.

**Why**
- Controllers and LiveViews can render directly
- Maintains framework-light core
- Preserves machine-readable compatibility without freezing only English strings

### 3. Phoenix helper surface

**Options considered**
- Plain functions in `Scrypath.Phoenix`
- Thin form helpers over Phoenix primitives
- Controller helpers
- Macros
- Component-heavy surface

**Recommendation locked**
- Ship one optional `Scrypath.Phoenix` plain-function namespace.
- Allow thin helpers for forms and URL/query round-tripping.
- Do not ship controller wrappers, macros, generated components, or search-executing helpers.

**Why**
- Best ecosystem fit with Phoenix’s explicit module/function style
- Keeps Phoenix optional
- Prevents boundary drift into a web-layer facade

### 4. LiveView flow

**Options considered**
- `handle_params/3`-first flow
- `handle_event/3`-only flow
- Helper-managed assigns bundle
- Opinionated macro/callback layer

**Recommendation locked**
- Make `handle_params/3` the canonical search-state entrypoint.
- Use events only to compute next raw params and patch the URL.
- Normalize once in `handle_params/3`, render errors there, and call the app context only on success.
- Keep helpers data-only and avoid socket-lifecycle magic.

**Why**
- Preserves shareable URL state
- Matches Phoenix LiveView guidance
- Reuses the same normalization/error semantics as non-LiveView edges

## Cross-cutting principles carried forward

- Keep the public surface data-first and explicit.
- Keep contexts as the canonical orchestration boundary.
- Keep Phoenix optional.
- Normalize once at the edge.
- Treat invalid edge input as expected, renderable failure.
- Do not hide search semantics behind convenience.
- Prefer calm, literal helper naming and low-surprise behavior.

## User preference captured

- Prefer decisive recommendations by default.
- Only escalate decisions back to the user when they are materially high impact for product scope, semver surface, or milestone honesty.

## Deferred ideas noted during synthesis

- Rich query DSL / predicate language
- Controller helper façade
- Macros such as `use Scrypath.Phoenix`
- Rendered search UI components
- Browser-friendly `per_query` expansion

---

*Discussion complete on 2026-05-22*
