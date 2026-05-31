# Phase 106: Fan-Out Reflection Contract Repair - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 106 repairs the fan-out reflection contract for ordinary schemas that declare related-data fan-out metadata through `use Scrypath, fan_outs:`. The required outcome is that these schemas expose `__scrypath__(:fan_outs)` for runtime consumption by `Scrypath.sync_related/3` and `Scrypath.Sync.RelatedWorker`, while existing hand-written fan-out reflection for unusual owner schemas remains compatible.

This phase is a bounded contract repair. It must not add new public fan-out helper APIs, new owner-only macros, broader validation tightening, automatic association walking, callback-driven propagation, or any new search feature breadth.

</domain>

<decisions>
## Implementation Decisions

### Compatibility Semantics
- **D-01:** Ordinary schemas using `use Scrypath, fan_outs:` must expose the declared fan-out metadata through `__scrypath__(:fan_outs)`.
- **D-02:** Existing owner-only schemas with hand-written `__scrypath__(:fan_outs)` remain supported. This preserves the low-level escape hatch for schemas that participate in fan-out but are not ordinary searchable schemas.
- **D-03:** For schemas that do use `Scrypath`, any advanced reflection customization should use a documented `defoverridable __scrypath__/1` delegation pattern if needed. Do not introduce a generated/private split such as `__scrypath_generated__/1`.
- **D-04:** Do not add `Scrypath.FanOuts`, `Scrypath.schema_fan_outs/1`, duplicate-key validation, nil-target validation, or any other future fan-out API/validation surface in Phase 106.

### Proof Boundary
- **D-05:** Add a focused `mix verify.phase106` proof gate for this repair.
- **D-06:** The gate should prove both reflection and runtime consumption: `test/scrypath/schema_test.exs`, `test/scrypath/sync/related_test.exs`, and `test/scrypath/sync/related_worker_test.exs` are the expected focused test spine.
- **D-07:** Keep required CI topology unchanged. If any CI visibility is added, keep it advisory unless release policy explicitly promotes it.
- **D-08:** Proof should stay service-free and deterministic. Live Meilisearch/Phoenix proof belongs to existing advisory lanes or later phase verification, not this narrow contract repair.

### Docs and API Boundary
- **D-09:** Keep the public fan-out API surface unchanged in v1.29. The runtime seam remains `__scrypath__(:fan_outs)` consumed internally by existing sync paths.
- **D-10:** Phase 106 may make targeted contract corrections where needed to prevent immediate adopter confusion, but broad truth reconciliation belongs to Phase 108.
- **D-11:** Final adopter-facing wording should say: ordinary owners prefer `use Scrypath, fan_outs:`; unusual owner-only schemas may hand-write `__scrypath__(:fan_outs)`; fan-out remains explicit and context-owned, not callback magic.

### Architecture and DX Calibration
- **D-12:** Preserve Scrypath's existing product lesson from Searchkick, Laravel Scout, Meilisearch Rails, and Hibernate Search: related-data propagation should be explicit and operationally honest. Do not imply automatic association tracking.
- **D-13:** Prefer the smallest cohesive Elixir-native repair: generated metadata clauses in the schema macro, direct function tests, and a focused verify task. Avoid new abstractions until adopter evidence proves they are worth the public API cost.
- **D-14:** The implementation should optimize for least surprise: the declaration shown in docs must be the same declaration that runtime sync consumes.

### Codex's Discretion
- Exact test names, assertion helper shape, and `verify.phase106` output wording are implementation details, provided failures are actionable and reproduce locally with `mix verify.phase106`.
- Exact placement of minimal docs-contract assertions is flexible, provided Phase 106 does not become a broad docs rewrite.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope and Requirements
- `.planning/ROADMAP.md` - Phase 106 goal, success criteria, dependency on Phase 105, and no-breadth boundary.
- `.planning/REQUIREMENTS.md` - FAN-01, FAN-02, and deferred fan-out future requirements.
- `.planning/PROJECT.md` - v1.29 bounded contract repair posture, release-train discipline, and explicit non-goals.
- `.planning/STATE.md` - active v1.29 decisions and operator next steps.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md` - scope guard and reopen policy for public runtime breadth.

### Fan-Out Runtime Contract
- `lib/scrypath/schema.ex` - `use Scrypath` metadata generation and `__scrypath__/1` reflection clauses.
- `lib/scrypath/sync.ex` - `Scrypath.Sync.sync_related/3` runtime consumption of `__scrypath__(:fan_outs)`.
- `lib/scrypath/sync/related_worker.ex` - Oban-backed fan-out job consumption and validation of `__scrypath__(:fan_outs)`.
- `lib/scrypath.ex` - public `Scrypath.sync_related/3` facade and public docs surface.
- `lib/scrypath/options.ex` - current `fan_outs:` option validation boundary.

### Existing Tests and Verification Patterns
- `test/scrypath/schema_test.exs` - generated schema reflection contract tests.
- `test/scrypath/sync/related_test.exs` - inline/Oban enqueue fan-out consumption tests and hand-written source schema precedent.
- `test/scrypath/sync/related_worker_test.exs` - worker-side fan-out consumption and invalid-job behavior.
- `test/scrypath/docs_contract_test.exs` - targeted docs-contract assertion style.
- `lib/mix/tasks/verify.phase91.ex` - focused related-data phase gate pattern.
- `lib/mix/tasks/verify.phase97.ex` - focused phase verify task pattern.
- `lib/mix/tasks/verify.phase98.ex` - service-free contract gate pattern.
- `lib/mix/tasks/verify.phase99.ex` - trust-hardening verify task pattern.
- `mix.exs` - `cli.preferred_envs` registration for phase verify tasks.

### Examples and Docs
- `guides/related-data-and-reindexing.md` - canonical related-data fan-out guide and ordinary-vs-unusual schema wording target.
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex` - hand-written owner fan-out example and compatibility anchor.
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex` - context-owned explicit fan-out orchestration example.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/category.ex` - current e-commerce owner schema fan-out reflection.
- `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog.ex` - e-commerce context-owned `sync_related/3` call site.

### Prompt Research Inputs
- `prompts/elixir-best-practices-deep-research.md` - macro restraint, explicit APIs, tests, and library architecture guidance.
- `prompts/ecto-best-practices-deep-research.md` - Ecto-native boundaries and schema/context separation.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - Phoenix/Ecto system boundary discipline.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` - OSS library DX, docs, public API, and macro anti-footguns.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - focused, low-noise proof gate guidance.
- `prompts/elixir-search-lib-deep-research.md` - search-library architecture and ecosystem lessons.
- `prompts/search-lib-use-cases-deep-research.md` - Searchkick/Scout/Meilisearch Rails/Hibernate Search lessons for explicit related-data propagation.
- `prompts/scrypath-brand-book.md` - Ecto-native positioning and calm, exact contract language.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Scrypath.Schema.__using__/1` already owns schema metadata validation and generated `__scrypath__/1` clauses. This is the correct repair point for ordinary `use Scrypath, fan_outs:` schemas.
- `Scrypath.Sync.sync_related/3` and `Scrypath.Sync.RelatedWorker` already consume `schema_module.__scrypath__(:fan_outs)` directly. The repair should make the declaration satisfy the existing consumption contract rather than adding a new reader.
- Existing phase verify tasks provide a simple scaffold: no args, focused tests, optional docs build only when the phase needs docs proof.

### Established Patterns
- Scrypath favors explicit, context-owned orchestration over callback magic.
- Phase gates are focused and reproducible locally through `mix verify.phase*`.
- Required CI stays lean; service-backed and heavier proof lanes remain advisory unless deliberately promoted.
- Docs-contract tests should check stable tokens and contract anchors, not prose snapshots.

### Integration Points
- Add/confirm generated `__scrypath__(:fan_outs)` behavior in `lib/scrypath/schema.ex`.
- Strengthen `test/scrypath/schema_test.exs` for ordinary declaration reflection and any `defoverridable` delegation behavior selected by the implementation.
- Preserve and, if needed, extend hand-written compatibility coverage in `test/scrypath/sync/related_test.exs` and `test/scrypath/sync/related_worker_test.exs`.
- Add `lib/mix/tasks/verify.phase106.ex` and register `"verify.phase106": :test` in `mix.exs`.

</code_context>

<specifics>
## Specific Ideas

- Recommended one-shot implementation posture: declaration-first ordinary path, hand-written owner-only compatibility, no public helper, focused proof gate.
- Cross-ecosystem lesson to preserve: Searchkick and Meilisearch Rails make association propagation explicit rather than automatic; Hibernate Search proves explicit dependency modeling matters, but its deeper dependency engine would be too much for this repair.
- The strongest DX outcome is that the code sample adopters copy is truthful: `use Scrypath, fan_outs:` should be enough for ordinary schemas, and `sync_related/3` should consume that exact reflection.

</specifics>

<deferred>
## Deferred Ideas

- `Scrypath.FanOuts` owner-only macro remains deferred as FAN-FUTURE-01.
- `Scrypath.schema_fan_outs/1` public helper remains deferred as FAN-FUTURE-02.
- Duplicate fan-out key validation and nil target/resolver validation remain deferred as FAN-FUTURE-03.
- Broader related-data docs and planning/JTBD truth reconciliation remain Phase 108 scope.
- Deeper Playwright cross-tenant fixture expansion remains outside Phase 106 and belongs, if ever needed, to ecommerce proof work.

</deferred>

---

*Phase: 106-fan-out-reflection-contract-repair*
*Context gathered: 2026-05-31*
