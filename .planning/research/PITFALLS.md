# Domain Pitfalls

**Domain:** Reusable composition presets, metadata surfaces, and real-app adoption depth for an existing Ecto-first search library
**Researched:** 2026-05-23
**Confidence:** HIGH for product-boundary and roadmap risks from repo context; MEDIUM for ecosystem-pattern comparisons where the evidence is prior research plus official Ecto/Phoenix docs

## Critical Pitfalls

### Pitfall 1: Freezing The Wrong Abstraction
**What goes wrong:** v1.22 turns a few repeated app-side patterns into a broad public composition system too early. Presets become mini search modules, scopes become hidden runtime verbs, and the library accidentally promises a long-lived abstraction before real adopter evidence proves which shapes are stable.
**Why it happens:** repeated boilerplate feels painful after v1.21, so it is tempting to generalize around internal convenience instead of freezing only the smallest public seam that real apps actually repeat.
**Consequences:** semver pressure rises immediately; later tenant, related-data, or backend-specific needs no longer fit the frozen API; `%Scrypath.Query{}` pressure returns through the side door.
**Warning signs:** proposed APIs need custom callback hooks, arbitrary merge order rules, runtime function generation, or preset inheritance trees; examples explain the abstraction more than the search flow.
**Prevention:** keep presets plain data over the existing `search/3` and `search_many/2` contract; require contexts to remain the application boundary; make composition additive rather than replacing direct option calls; explicitly forbid public exposure of internal query structs or schema-generated runtime verbs.
**Detection:** if a preset cannot be explained as “prepare stable search args, then call the existing runtime,” the abstraction is too large.
**Phase:** **Phase 83 — Composition seam and preset contract.** This phase should freeze only one bounded preset/scope representation and reject broader composition frameworks.

### Pitfall 2: Rebuilding A Hidden Query DSL
**What goes wrong:** presets/scopes accumulate conditionals, inheritance, lambdas, and merge rules until Scrypath effectively ships a second query language on top of its current plain-data search args.
**Why it happens:** composition work often starts with honest helper data, then drifts into “smart” transformation layers to solve every edge case.
**Consequences:** callers can no longer predict final search options, docs become translation-heavy, validation errors get worse, and `search_many/2` parity becomes brittle.
**Warning signs:** new concepts like “extends”, “override precedence”, “late binding”, “computed filters”, or preset-local validation that differs from `Scrypath.Options`.
**Prevention:** composition should normalize into the same canonical option shapes already validated today; no hidden precedence lattice; no preset-specific execution semantics; no separate casting path from the query toolkit.
**Detection:** if `search_many/2` needs a special composition-only validator or if option-merging rules cannot be shown in one short table, the design has drifted into DSL territory.
**Phase:** **Phase 83 — Composition seam and preset contract.** Lock the merge rules before any metadata or Phoenix-facing work lands.

### Pitfall 3: Scope Spill Into Tenant, Auth, Or Related-Data Semantics
**What goes wrong:** “scope” starts meaning tenant enforcement, row-level authorization, or joined/associated-data propagation, even though v1.22 is only supposed to reduce repeated query composition glue.
**Why it happens:** real apps do need tenant-safe and related-data-aware search, and the word “scope” invites overloading those concerns into one ergonomic surface.
**Consequences:** Scrypath makes promises it cannot honestly keep yet; adopters confuse search presets with security boundaries; roadmap priority gets inverted by hiding B1/B2-class problems inside a composition milestone.
**Warning signs:** scope examples mention current user authorization, organization isolation, ownership rules, or automatic fan-out after associated data changes; docs imply that using a scope makes a search “safe” for SaaS.
**Prevention:** name scopes as search-argument composition only; force tenant/access examples to remain host-owned context code; link explicitly to future tenant-safe and related-data milestones rather than implying those are solved here.
**Detection:** if a scope requires `current_user`, policy modules, repo lookups, or association dependency graphs, it is out of milestone scope.
**Phase:** **Phase 83 — Composition seam and preset contract** must write the hard boundary. **Phase 85 — Real-app docs and examples** must reinforce it with explicit “not solved here” guidance.

### Pitfall 4: Phoenix Leakage Into Core
**What goes wrong:** metadata exposure or reusable composition APIs start depending on Phoenix structs, form concerns, LiveView navigation, or request/session semantics.
**Why it happens:** the most obvious consumers are controllers and LiveViews, so helpers are often designed from those call sites backward.
**Consequences:** the core library stops feeling Ecto-native and becomes framework-biased; non-Phoenix Ecto adopters pay API and dependency cost; boundary discipline from v1.21 regresses.
**Warning signs:** core APIs mention `Phoenix.HTML.Form`, `Plug.Conn`, URL params, LiveView assigns, or UI widget assumptions; docs require Phoenix to understand metadata contracts.
**Prevention:** keep core metadata surfaces as plain reflection/data APIs over declared schema metadata and validated search args; leave Phoenix round-tripping and rendering helpers optional and thin, as in v1.21.
**Detection:** if a metadata API returns Phoenix-shaped tuples or requires Phoenix typespecs in core modules, the boundary has already been crossed.
**Phase:** **Phase 84 — Metadata reflection and `search_many/2` alignment.** This phase should define pure data contracts only. Any Phoenix examples belong in **Phase 85**.

### Pitfall 5: Metadata Drift Between Declarations, Runtime Behavior, And UI
**What goes wrong:** the library exposes filter/sort/facet/page metadata for UI builders, but that metadata drifts from actual validation, backend behavior, or declared schema settings.
**Why it happens:** UI metadata is often hand-assembled separately from the canonical validation and backend-setting paths.
**Consequences:** apps render controls that do not work, hide controls that do work, or misstate operator truth about facet/filter/sort availability; trust in the library drops because the mismatch feels like dishonesty.
**Warning signs:** metadata is assembled in a separate module with duplicate field lists; changing a schema declaration or query-param rule requires touching multiple codepaths; tests assert UI-facing labels but not contract parity.
**Prevention:** derive metadata from the same declaration and validation sources that power runtime behavior; reuse existing `__scrypath__/1`, option validators, and drift-checking mindset; define one canonical metadata contract and lock it with docs/tests.
**Detection:** a single schema declaration change should propagate to runtime, metadata reflection, and docs fixtures without manual synchronization.
**Phase:** **Phase 84 — Metadata reflection and `search_many/2` alignment.** It should ship with parity tests and doc contracts before real-app examples are expanded.

## Moderate Pitfalls

### Pitfall 6: Breaking `search_many/2` Alignment With Single-Search Composition
**What goes wrong:** single-search presets/scopes feel ergonomic, but multi-index flows need a different shape or lose important per-entry overrides.
**Prevention:** design composition against both `search/3` and `search_many/2` from day one; treat multi-search as a first-class contract test, not a later extension.
**Warning signs:** examples work only for one schema; `search_many/2` needs ad hoc wrapping or silently ignores preset metadata.
**Phase:** **Phase 84 — Metadata reflection and `search_many/2` alignment.**

### Pitfall 7: Preset Merge Rules That Hide Operational Truth
**What goes wrong:** composition silently overrides filters, pages, facets, or sort order in ways callers cannot see, especially when combining defaults with user input.
**Prevention:** publish explicit precedence rules; prefer validation failures over silent overrides for conflicting locked values; keep “locked” vs “defaultable” semantics explicit.
**Warning signs:** docs use words like “smart merge” without a deterministic table; conflict behavior differs between `search/3` and Phoenix helpers.
**Phase:** **Phase 83 — Composition seam and preset contract.**

### Pitfall 8: UI Metadata That Implies Widgets Or Product Guarantees
**What goes wrong:** metadata surfaces start encoding presentation decisions, labels, component hints, or richer UI conventions that Scrypath cannot maintain as a core library promise.
**Prevention:** expose honest capability metadata first; keep labels, grouping, and widget decisions app-owned unless repeated evidence proves a smaller stable seam.
**Warning signs:** metadata design discussions center on component rendering rather than search capability truth.
**Phase:** **Phase 84 — Metadata reflection and `search_many/2` alignment**, with restraint enforced again in **Phase 85** docs.

### Pitfall 9: Composition Examples That Quietly Reintroduce Framework Magic
**What goes wrong:** guides present copy-paste flows where contexts disappear and controllers/LiveViews call directly into composition helpers as if Scrypath owns the app boundary.
**Prevention:** every real-app example should still end with a context-owned `Scrypath.search/3` or `search_many/2` call; examples must show where host code owns auth, preload, and related-data logic.
**Warning signs:** examples omit context functions or present schema-local search verbs as the primary story.
**Phase:** **Phase 85 — Real-app docs, examples, and drift gates.**

### Pitfall 10: Overfitting To One Dogfood App
**What goes wrong:** the chosen preset/scope API matches one Phoenix example beautifully but fails to generalize across other Ecto apps, JSON APIs, or non-LiveView flows.
**Prevention:** require at least two materially different worked examples before claiming a surface is reusable; one should be Phoenix-heavy, one should be plainer context/API-oriented.
**Warning signs:** a proposed public helper exists only to satisfy one UI flow or one naming convention.
**Phase:** **Phase 85 — Real-app docs, examples, and drift gates.**

## Minor Pitfalls

### Pitfall 11: Naming Drift Between “Preset”, “Scope”, “Query”, And “Metadata”
**What goes wrong:** the docs use overlapping vocabulary, so adopters cannot tell whether a scope is executable, declarative, request-edge, or UI-only.
**Prevention:** define four or five canonical nouns and use them consistently across guides, typespecs, and examples.
**Phase:** **Phase 85 — Real-app docs, examples, and drift gates.**

### Pitfall 12: Verification That Checks Prose But Not Contract Parity
**What goes wrong:** docs read well, but no contract tests prove metadata reflection, preset merge behavior, and request-edge compatibility stay aligned as the API evolves.
**Prevention:** add focused verification tasks for preset merge semantics, reflected metadata shape, and guide/example parity; keep them auth-free and deterministic like prior doc-contract gates.
**Phase:** **Phase 85 — Real-app docs, examples, and drift gates.**

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Phase 83 — Composition seam and preset contract | Freezing a broad abstraction or inventing a hidden DSL | Ship one plain-data preset/scope seam, one precedence table, one conflict policy, and keep contexts canonical |
| Phase 83 — Composition seam and preset contract | Scope spill into tenant/access/related-data semantics | Write explicit non-goals into requirements and reject examples that depend on auth or propagation semantics |
| Phase 84 — Metadata reflection and `search_many/2` alignment | Metadata drift from declarations and validators | Derive metadata from canonical schema declarations and existing validation paths; add parity tests |
| Phase 84 — Metadata reflection and `search_many/2` alignment | Phoenix leakage into runtime core | Keep metadata contracts framework-agnostic; move any rendering or URL concerns to optional docs/helpers only |
| Phase 84 — Metadata reflection and `search_many/2` alignment | Single-search ergonomics that do not survive multi-search | Require `search_many/2` contract coverage before freezing the public API |
| Phase 85 — Real-app docs, examples, and drift gates | Examples imply solved SaaS security or related-data semantics | Add “host-owned, not solved here” callouts and keep auth/tenant examples explicit about app responsibility |
| Phase 85 — Real-app docs, examples, and drift gates | One worked example overdetermines the API | Require at least two distinct adopter flows and lock them with docs/tests |
| Phase 85 — Real-app docs, examples, and drift gates | Drift between prose and shipped behavior | Add doc-contract and example smoke gates for metadata, presets, and composition outputs |

## Roadmap Prevention Strategy

1. **Phase 83 should be the hardest product-boundary phase.** Freeze only the smallest reusable preset/scope shape that composes into existing search args. Do not start with UI metadata or Phoenix ergonomics.
2. **Phase 84 should be a contract-parity phase, not a feature-bloat phase.** Metadata reflection must be derived, framework-agnostic, and proven against both `search/3` and `search_many/2`.
3. **Phase 85 should prove adoption honestly.** The docs should show reduced duplication without implying solved auth, tenancy, related-data propagation, or hidden operational guarantees.
4. **Do not let v1.22 absorb B1/B2 work by accident.** If composition needs tenant policy or related-data dependency semantics to feel “complete,” stop and split that into future milestones instead of smuggling it into presets/scopes.

## Sources

- `.planning/PROJECT.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/milestone-candidates.md`
- `.planning/seeds/SEED-002-composition-real-app-depth.md`
- `prompts/elixir-search-lib-deep-research.md`
- `prompts/search-lib-use-cases-deep-research.md`
- `prompts/ecto-best-practices-deep-research.md`
- `prompts/elixir-opensource-libs-best-practices-deep-research.md`
- [Phoenix Contexts Guide](https://hexdocs.pm/phoenix/contexts.html)
- [Phoenix LiveView `on_mount` docs](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1)
- [Ecto dynamic queries guide](https://hexdocs.pm/ecto/dynamic-queries.html)
- [Ecto.Query docs](https://hexdocs.pm/ecto/Ecto.Query.html)
