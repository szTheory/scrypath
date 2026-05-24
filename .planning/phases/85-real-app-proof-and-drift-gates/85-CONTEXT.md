# Phase 85: Real-App Proof And Drift Gates - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Show the v1.22 composition seam in real app flows, document the non-goals clearly, and lock the milestone story behind focused verification. This phase proves that presets/scopes, metadata reflection, and `search_many/2` parity reduce repeated app-side glue without implying framework magic, generated UI, tenant/authz guarantees, or hidden operational correctness.

</domain>

<decisions>
## Implementation Decisions

### Canonical proof flows
- **D-01:** Phase 85 should freeze **two** canonical real-app proof flows, not one and not a broad matrix.
- **D-02:** The primary proof flow should be a **single-schema Phoenix catalog/search page** that uses presets/scopes plus metadata-driven controls while keeping Phoenix thin and the context canonical.
- **D-03:** The secondary proof flow should be a **multi-schema/global search flow** that uses `Scrypath.Composition.compose_many/2` plus entry-scoped reflection and partial-failure honesty.
- **D-04:** The two proof flows must feel like one coherent story: request edge -> plain data -> context -> canonical runtime. Composition lowers into `Scrypath.search/3` or `Scrypath.search_many/2`; it does not become a second runtime.
- **D-05:** A controller/JSON API flow and a non-Phoenix plain context flow may appear only as **supporting notes or small examples**, not as the two flagship proofs for this phase.
- **D-06:** The single-schema flow should emphasize the most common adopter job: one searchable Phoenix screen with real text/filter/sort/page/facet behavior, less repeated glue, and metadata rendering honest controls.
- **D-07:** The multi-schema flow should emphasize the advanced-but-bounded job: global search without pretending there is one merged capability surface, one universal ranking scale, or merged cross-schema facets.

### Docs architecture and ownership
- **D-08:** Use a **hybrid docs shape**: create one new canonical composition guide plus small updates to existing guides and README/overview for wayfinding.
- **D-09:** The new guide should be **framework-agnostic** and should own the full v1.22 semantics: why composition exists after v1.21, presets vs scopes, `defaults` vs `fixed`, metadata/reflection purpose, `compose_many/2` parity, and explicit non-goals.
- **D-10:** Existing guides should stay role-specific and link back to the new canonical guide instead of re-explaining its semantics.
- **D-11:** The new guide should sit in ExDoc reading order immediately after `guides/request-edge-search.md` and before Phoenix walkthrough material so users find it as the “what to do next once param normalization is settled” step.
- **D-12:** `guides/request-edge-search.md` remains the canonical v1.21 contract; Phase 85 should add only a next-step link there, not reopen its semantics.
- **D-13:** `guides/faceted-search-with-phoenix-liveview.md` should own the single-schema metadata-driven UI proof. `guides/multi-index-search.md` should own the `compose_many/2` lowering and per-entry parity proof.
- **D-14:** `guides/golden-path.md` must remain first-hour only. At most, it gets a short “when you need reusable search defaults next” link.

### Boundary emphasis and non-goals
- **D-15:** Boundary emphasis should use **both** a dedicated canonical non-goals section and **short selective inline reminders** in high-footgun examples.
- **D-16:** The canonical new guide should contain the authoritative non-goals section covering: no public `%Scrypath.Query{}`, no generated UI widgets/forms/components, no schema-generated runtime verbs, no tenant/authz guarantees, and no related-data propagation or rebuild correctness claims.
- **D-17:** Inline boundary reminders should appear only where readers are likely to overgeneralize: especially in the single-schema metadata/UI example and the multi-search/global-search example.
- **D-18:** Inline reminders must stay short, calm, and anchored to the canonical section. Do not turn the docs into repetitive banner warnings.
- **D-19:** Metadata must be presented as **host-rendering support**, not as a generated control system. Composition must be presented as **host-owned search policy**, not as authorization policy.

### Verification and drift gates
- **D-20:** Add a new focused **`mix verify.phase85`** as the primary phase gate.
- **D-21:** `verify.phase85` should stay phase-scoped and should verify **boundary truth + example truth + cross-guide parity**, not rerun all prior runtime-focused verification wholesale.
- **D-22:** `verify.phase85` may carry forward only the **minimal prior tests** that directly protect the new public story. It should not shell out to `verify.phase83` and `verify.phase84` unchanged unless a specific carried-forward assertion truly needs it.
- **D-23:** New docs-contract assertions should lock structural invariants and authority hierarchy, not large blocks of prose. Avoid over-freezing narrative wording.
- **D-24:** A broader milestone-close aggregate may be reasonable later, but it is **not** the primary Phase 85 loop. The primary loop should keep failures local and actionable for maintainers editing docs/examples.

### UX, DX, and ecosystem fit
- **D-25:** Phase 85 should optimize for the Elixir/Phoenix/Ecto posture that best fits Scrypath: schemas declare capabilities, contexts own orchestration, web layers own params/URL/UI state, and public helpers stay plain-data and inspectable.
- **D-26:** The new examples should feel closer to **Flop-style metadata-first DX** than to **Searchkick/Scout-style model magic**.
- **D-27:** Scrypath should borrow the best lessons from adjacent libraries without copying their footguns:
  - keep the first real app flow obvious and copy-pasteable
  - keep multiple sync/rebuild realities explicit
  - keep one canonical runtime contract
  - avoid callback-magic promises and hidden policy behavior
- **D-28:** Examples should explicitly show `applied`, `defaulted`, `fixed`, and `unsupported` as inspectable state useful for tests, logs, and host rendering.
- **D-29:** The multi-search example must keep entry-scoped capability differences visible and must not imply cross-schema score comparability or a fake global capability graph.
- **D-30:** In Phoenix/LiveView examples, keep URL state and request-edge normalization in `handle_params/3` / `push_patch` style flows rather than ephemeral local-only state.

### Decision cadence and shifted default
- **D-31:** Shift this preference left for this project area: for public-boundary work, downstream agents should default to **decisive, cohesive recommendations** that preserve least surprise, strong DX, and boundary honesty rather than surfacing many equally-weighted options.
- **D-32:** Reopen these kinds of choices with the user only when they materially affect public runtime entrypoints, semver cost, framework coupling, or milestone scope.
- **D-33:** Downstream planning should explicitly answer two questions early:
  - what is the canonical boundary anchor for this phase?
  - which prior tests must be carried forward, and why?

### the agent's Discretion
- Exact name of the new canonical guide, provided it is precise, discoverable in HexDocs, and clearly about composition/metadata rather than a vague “overview.”
- Exact prose and example domain used for the single-schema and multi-schema flows, provided the locked boundaries and authority hierarchy above remain intact.
- Exact `verify.phase85` file list, provided it stays focused, phase-local, and protects the new public story without broad noisy reruns.
- Exact docs-contract assertions, provided they lock structural truth and ownership boundaries rather than large prose chunks.

</decisions>

<specifics>
## Specific Ideas

- The desired feel is “**Flop for search orchestration boundaries**” more than “Searchkick for magical search.”
- Composition should be taught as **lowering** into canonical runtime calls, not as a new executable query object.
- The best pair of flagship proofs is:
  - one searchable Phoenix catalog page with metadata-driven controls
  - one global-search/dashboard flow with `compose_many/2`, entry-scoped reflection, and partial-failure honesty
- Supporting notes may mention:
  - the same contract also works for controller/JSON edges
  - the seam remains framework-agnostic and context-owned outside Phoenix
- Cross-ecosystem calibration that informed these decisions:
  - Flop gets the metadata/UI contract right without owning all rendering
  - Searchkick compresses the first mile well but encourages callback-magic expectations that Scrypath should avoid
  - Laravel Scout keeps one common runtime surface and an engine seam, which matches Scrypath’s posture
  - meilisearch-rails is a useful reminder to stay explicit about propagation, deletes, rebuilds, and operational reality

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and milestone guardrails
- `.planning/ROADMAP.md` — Phase 85 goal, success criteria, and active milestone sequencing
- `.planning/REQUIREMENTS.md` — `DOC-01`, `DOC-02`, and `VRFY-01`
- `.planning/PROJECT.md` — v1.22 posture, boundary guardrails, and product voice
- `.planning/STATE.md` — current phase state and explicit v1.22 guardrail language

### Locked prior phase decisions
- `.planning/phases/82-docs-examples-and-drift-protection/82-CONTEXT.md` — core-first docs posture, optional Phoenix hierarchy, and boundary-honest story constraints
- `.planning/phases/83-composition-presets-and-scope-contract/83-CONTEXT.md` — plain-data composition seam, defaults/fixed rules, visibility vocabulary, and host-owned boundary decisions
- `.planning/phases/84-metadata-reflection-and-multi-search-parity/84-CONTEXT.md` — metadata/reflection split, multi-search parity, and per-entry honesty decisions
- `.planning/milestones/v1.17-phases/68-example-proof-and-support-contract/68-CONTEXT.md` — prior real-app proof and support-contract patterns
- `.planning/milestones/v1.17-phases/69-adopter-verify-spine/69-CONTEXT.md` — maintainer-facing verification posture and proof-path lessons

### Current public docs and runtime seams
- `README.md` — root wayfinding and public story entrypoints
- `guides/request-edge-search.md` — canonical request-edge contract from v1.21
- `guides/faceted-search-with-phoenix-liveview.md` — single-schema metadata-driven UI example surface
- `guides/multi-index-search.md` — `compose_many/2`, per-entry boundaries, and partial-failure honesty
- `guides/jtbd-and-user-flows.md` — user/job framing and the existing composition JTBD story
- `guides/overview.md` — published guide hierarchy and reading order
- `guides/golden-path.md` — first-hour scope boundary that Phase 85 must not absorb
- `guides/phoenix-liveview.md` — Phoenix request-edge and URL-state patterns
- `guides/phoenix-controllers-and-json.md` — controller/JSON edge posture that may appear only as supporting proof
- `lib/scrypath/composition.ex` — canonical plain-data composition seam
- `lib/scrypath/metadata.ex` — canonical reflection helpers and host-owned advisory posture
- `lib/scrypath.ex` — public entrypoint documentation and boundary language
- `test/scrypath/docs_contract_test.exs` — current docs authority and drift-gate structure
- `lib/mix/tasks/verify.phase82.ex` — prior focused docs/example drift gate pattern
- `lib/mix/tasks/verify.phase83.ex` — focused phase gate pattern for composition work
- `lib/mix/tasks/verify.phase84.ex` — focused phase gate pattern for metadata and multi-search work

### Prompt corpus and research lenses
- `prompts/elixir-best-practices-deep-research.md` — function-first, explicit Elixir API guidance
- `prompts/ecto-best-practices-deep-research.md` — context-boundary and thin-schema guidance
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix optional-adapter and context-first architecture guidance
- `prompts/phoenix-live-view-best-practices-deep-research.md` — URL-state and `handle_params/3` guidance
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — boundary and system-design discipline
- `prompts/elixir-search-lib-deep-research.md` — search-library architecture and anti-facade guidance
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS API discipline, semver, and docs/maintenance guidance
- `prompts/search-lib-use-cases-deep-research.md` — adopter jobs and pressure points for this product category
- `prompts/scrypath-brand-book.md` — calm, exact, non-hype product voice

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/scrypath/composition.ex`: already exposes the plain-data composition seam that docs should teach as lowering into canonical runtime calls
- `lib/scrypath/metadata.ex`: already exposes `schema_capabilities/1`, `reflect_search/2`, and `reflect_search_many/2` with host-owned advisory state
- `guides/faceted-search-with-phoenix-liveview.md`: already contains a promising single-schema metadata-driven UI example that can be sharpened into one flagship proof
- `guides/multi-index-search.md`: already contains `compose_many/2` and multi-search honesty language that can be sharpened into the second flagship proof
- `test/scrypath/docs_contract_test.exs`: existing place to lock wayfinding, canonical authority, and non-goal drift
- `lib/mix/tasks/verify.phase82.ex`, `verify.phase83.ex`, `verify.phase84.ex`: established pattern for focused phase-local verification commands

### Established Patterns
- Public Scrypath surfaces stay explicit, function-based, plain-data, and low-magic
- Contexts remain the application boundary; Phoenix stays optional glue
- `%Scrypath.Query{}` remains internal normalized runtime state
- Published docs prefer one canonical authority page plus smaller role-specific guides
- Focused verification commands are preferred over broad noisy phase reruns

### Integration Points
- Phase 85 should add one new canonical guide and rewire README/overview/request-edge wayfinding to it
- The single-schema proof should likely extend the existing faceted/LiveView guide rather than inventing a separate Phoenix runtime story
- The multi-schema proof should likely extend the existing multi-index guide while keeping per-entry boundaries explicit
- `verify.phase85` should likely combine docs-contract coverage, the smallest necessary example/runtime truth assertions, and docs build with warnings as errors

</code_context>

<deferred>
## Deferred Ideas

- Making controller/JSON flow or non-Phoenix library flow a flagship phase-85 proof
- Generated UI widgets, forms, or Phoenix-specific component helpers
- Schema-generated runtime search verbs or macros
- Tenant-safe authorization or policy enforcement via presets/scopes
- Related-data propagation or rebuild orchestration claims as part of composition
- A milestone-wide aggregate verify command as the primary phase loop
- Any broader reopening of the v1.21 request-edge contract

</deferred>

---

*Phase: 85-real-app-proof-and-drift-gates*
*Context gathered: 2026-05-23*
