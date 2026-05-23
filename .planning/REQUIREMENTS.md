# Requirements: Scrypath — Milestone v1.22

**Defined:** 2026-05-23  
**Milestone:** v1.22 — *Composition And Real-App Depth*  
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## Milestone goal

Turn the shipped request-edge toolkit into a reusable real-app composition layer through bounded presets, additive scopes, `search_many/2`-aligned composition, and honest metadata reflection, while keeping contexts canonical, Phoenix optional, and `Scrypath.search/3` / `Scrypath.search_many/2` as the only runtime entrypoints.

## Arc and scope gates

**Arc status:** existing milestone candidate from `.planning/MILESTONE-ARC.md`, now activated as the current milestone.  
**Why now:** `v1.21` settled the public request-edge contract, so the next leverage-positive move is reducing repeated app-side composition glue rather than adding more raw param casting or widening the runtime boundary.

### Capability selection rubric

| Capability family | Route-owner expectation | Bridge frequency | Policy sensitivity | Support-matrix impact | Proof required | Package classification |
|-------------------|-------------------------|------------------|--------------------|-----------------------|----------------|------------------------|
| Composition presets and additive scopes | Host contexts own composition choice and execution | Low-frequency semantic | Medium | Core public API and docs | Hermetic merge + parity proof | `core` |
| Metadata reflection for filters/sorts/facets/paging | Host apps render UI from data contract | Low-frequency semantic | Medium | Core public API and docs | Hermetic derivation + docs parity proof | `core` |
| `search_many/2` composition parity | Host contexts own global-search assembly | Low-frequency semantic | Medium | Core public API and docs | Hermetic multi-search parity proof | `core` |
| Phoenix examples and optional helper touch-ups | Optional adapter layer only | Native screen | Low | Docs/examples only | Example + docs-contract proof | `example/docs-only` |
| Tenant-safe authz enforcement, related-data automation, or generated UI | Host app responsibility or future milestone | Defer | High | Would widen product claims | Not for v1.22 | `defer` |

### Packaging ledger

| Surface | Classification | Notes |
|---------|----------------|-------|
| `Scrypath.Composition`-style public composition seam | `core` | Pure library-layer assembly over existing plain-data search args |
| Metadata reflection API for declared capabilities | `core` | Framework-agnostic data only; no UI widgets |
| `search_many/2` composition helpers/parity | `core` | Must preserve existing runtime and failure semantics |
| Phoenix/LiveView examples or thin helper adjustments | `example/docs-only` | Optional and data-only, never required by core |
| Generated UI components, controller/LiveView macros, or saved-search persistence | `defer` | Outside milestone boundary |

### Proof posture gate

| Public claim | Merge-blocking hermetic proof | Advisory proof |
|--------------|-------------------------------|----------------|
| Presets/scopes compose into existing runtime args without a second query system | Merge/precedence/property tests plus direct runtime parity cases | Worked example snapshots |
| Metadata reflects the canonical declaration/runtime contract | Reflection parity tests plus docs-contract coverage | Example UI/state walkthroughs |
| `search_many/2` composition shares the same public model honestly | Multi-search parity and failure-boundary tests | Example global-search flow |
| Real-app depth reduces glue without hiding ownership boundaries | Docs contracts and example smoke coverage | Maintainer review of guide clarity |

### Support truth gate

| Surface | Denial / fallback behavior | Missing prerequisite behavior | Native rebuilds required | Rough-edge docs to publish |
|---------|----------------------------|-------------------------------|--------------------------|----------------------------|
| Composition presets/scopes | Callers can keep using explicit `Scrypath.search/3` / `search_many/2` args directly | Invalid declarations fail fast with explicit errors | No | Composition guide with boundary notes |
| Metadata reflection | Callers can build UIs manually from existing declarations | Missing metadata stays explicit rather than guessed | No | Metadata/UI contract guide |
| `search_many/2` composition parity | Callers can keep assembling tuple entries manually | Unsupported cross-schema behavior remains out of scope and documented | No | Multi-search composition examples |
| Tenant/auth/related-data concerns | Explicitly not solved by v1.22 composition | Host app must own policy, fan-out, and rebuild logic | Sometimes, but outside this milestone | Guardrail callouts in guides/examples |

## v1.22 requirements

### Composition contract

- [x] **CMP-01**: Apps can define named presets as plain-data composition fragments that expand into the existing `Scrypath.search/3` input shape without exposing `%Scrypath.Query{}` or creating a second public query runtime.
- [x] **CMP-02**: Apps can apply additive scopes with deterministic precedence rules that distinguish caller-overridable defaults from fixed constraints.
- [x] **CMP-03**: Composition results expose debug-friendly applied/defaulted search criteria so host apps and tests can see what actually reached the canonical runtime.
- [x] **CMP-04**: Composition definitions stay feature-level and context-owned rather than moving product UX declarations onto Ecto schemas or Phoenix helpers.

### Metadata reflection

- [ ] **META-01**: Apps can reflect declared filters, sorts, facets, and paging capabilities as framework-agnostic metadata derived from the same canonical declarations and validators that drive runtime behavior.
- [ ] **META-02**: Metadata exposes applied defaults and capability constraints clearly enough for Phoenix, LiveView, JSON, or other host UIs to render honest controls without Scrypath generating UI components.
- [ ] **META-03**: Metadata and composition contracts keep tenant policy, authorization, and related-data propagation explicitly host-owned rather than implying those concerns are solved by presets or scopes.

### Multi-search alignment

- [ ] **MSCH-01**: The public composition model can assemble `search_many/2` flows using the existing tuple/shared-option contract rather than introducing a separate multi-search DSL.
- [ ] **MSCH-02**: `search_many/2` composition preserves current per-entry behavior and failure-boundary honesty, including explicit limits around cross-schema ranking, metadata, and shared-vs-entry precedence.

### Docs and verification

- [ ] **DOC-01**: Guides and examples show at least two distinct real-app adoption flows that reduce repeated query glue through the new composition seam while keeping contexts canonical and Phoenix optional.
- [ ] **DOC-02**: Docs make the non-goals explicit: no public `%Scrypath.Query{}`, no schema-generated runtime verbs, no generated UI widgets, and no claims that composition solves tenant-safe access or related-data fan-out.
- [ ] **VRFY-01**: Verification fails on composition drift around merge precedence, metadata derivation, `search_many/2` parity, and guide/example contract alignment.

## Future requirements carried forward

- [ ] **AUTH-01**: Explicit tenant-safe search access surfaces should be scoped as a separate future milestone rather than smuggled into composition helpers.
- [ ] **DATA-01**: Related-data and dependency propagation semantics should remain a separate correctness milestone if real-app pressure proves they need first-class product support.
- [ ] **UX-01**: Generated UI widgets, saved-search persistence, and broader app-framework ergonomics remain future optional-surface work rather than core-library scope.

## Out of scope

| Feature | Reason |
|---------|--------|
| Public `%Scrypath.Query{}` or any new behavioral query object | Would freeze current internal runtime structure into semver-stable API too early |
| Schema-generated runtime search verbs or framework-magic search helpers | Contexts must remain the application boundary |
| Phoenix-specific controller/LiveView macros or generated UI widgets | Would couple runtime core to framework/UI concerns instead of exposing data |
| Automatic related-data propagation or rebuild orchestration from presets/scopes | Composition does not truthfully solve fan-out correctness |
| Tenant authorization or isolation claims based on presets, scopes, or index prefixes | Host apps must own access policy explicitly |
| Broader backend abstraction or adapter-surface widening | `v1.22` stays inside the Meilisearch-first arc and existing internal seam |
| Saved-search persistence or OPSUI-style composition management | Separate product surface; not leverage-positive core scope here |

## Traceability

| Requirement | Planned phase | Status |
|-------------|---------------|--------|
| CMP-01 | Phase 83 | Complete |
| CMP-02 | Phase 83 | Complete |
| CMP-03 | Phase 83 | Complete |
| CMP-04 | Phase 83 | Complete |
| META-01 | Phase 84 | Pending |
| META-02 | Phase 84 | Pending |
| META-03 | Phase 84 | Pending |
| MSCH-01 | Phase 84 | Pending |
| MSCH-02 | Phase 84 | Pending |
| DOC-01 | Phase 85 | Pending |
| DOC-02 | Phase 85 | Pending |
| VRFY-01 | Phase 85 | Pending |

**Coverage:**
- v1.22 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-05-23*
*Last updated: 2026-05-23 after v1.22 milestone research and scope gating*
