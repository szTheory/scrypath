# Phase 108: Truth Alignment and Closeout Proof - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 108 reconciles the truth surfaces around v1.29's completed repair work: related-data docs must describe declaration-backed fan-out reflection accurately, roadmap/JTBD/planning truth must stop pointing at stale feature pulls, and verification posture must remain explicit without promoting `phase105-e2e` or adding new product breadth.

This is a closeout and drift-prevention phase. It does not add new runtime APIs, new fan-out helper surfaces, deeper Playwright fixture breadth, CI topology expansion, or any feature-lane reopening.

</domain>

<decisions>
## Implementation Decisions

### Related-data wording
- **D-01:** Present `use Scrypath, fan_outs:` as the ordinary path for searchable schemas. Phase 106 repaired generated `__scrypath__(:fan_outs)`, so docs should stop treating hand-written fan-out reflection as the normal copy-paste path.
- **D-02:** Keep hand-written `__scrypath__/1` documented as a supported low-level escape hatch for unusual owner-only schemas that intentionally do not `use Scrypath`; do not label it deprecated.
- **D-03:** Preserve the two main related-data footgun warnings: `sync_mode: :oban` means durably queued, not searchable now; resolvers must handle both inline record lists and Oban document-id lists.
- **D-04:** Explicitly avoid advertising deferred fan-out breadth as shipped contract: no `Scrypath.FanOuts` owner-only macro, no public `schema_fan_outs/1` helper, and no duplicate/nil fan-out validation tightening in this phase.

### Truth surface scope
- **D-05:** Use a bounded truth set, not a broad docs sweep. Phase 108 should reconcile `guides/related-data-and-reindexing.md`, `docs/jtbd-gap-map.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, and line-level `CONTRIBUTING.md` verification posture if needed.
- **D-06:** Keep authority boundaries intact: runtime and related-data semantics live in guides; milestone intent and closure live in `.planning/*`; verification-gate posture lives in `CONTRIBUTING.md`; README and overview stay route maps unless a direct contradiction is found.
- **D-07:** Do not rewrite stable root docs into second authorities for policy, support, proof, or related-data semantics.

### Verification posture
- **D-08:** Add a focused, service-free `mix verify.phase108` gate for TRUTH-01 rather than relying only on a one-time audit or broad docs-contract coverage.
- **D-09:** Keep `verify.phase108` narrow: a new `test/scrypath/phase108_contract_test.exs`, a task contract test such as `test/mix/tasks/verify.phase108_test.exs`, and only dedicated docs-contract tagging if needed.
- **D-10:** The gate must not run Meilisearch, Playwright, the ecommerce example service stack, or full broad docs snapshots. Use stable tokens and anchors rather than brittle paragraph equality.
- **D-11:** Do not create a new required GitHub Actions job for Phase 108 by default. Keep `phase105-e2e` advisory unless release policy explicitly promotes it.

### Closeout language
- **D-12:** Close v1.29 decisively as repair complete, then return Scrypath to maintenance-and-evidence mode.
- **D-13:** Use this closeout posture: v1.29 repairs declaration-backed fan-out reflection, guards tenant-preserving ecommerce readiness, aligns planning/JTBD truth, keeps `phase105-e2e` advisory, and reopens future feature breadth only with reviewed outside-adopter evidence or a concrete production bug.
- **D-14:** Avoid vague "near-done" framing unless the remaining open evidence is named. The remaining confidence gap is outside adoption/proof stability, not another in-repo feature wedge.

### the agent's Discretion
- Exact wording, section names, and assertion helper names may be chosen by the planner/executor as long as the ordinary-vs-advanced fan-out split, bounded truth surface list, service-free gate shape, and repair-complete closeout posture remain intact.
- The planner may decide whether Phase 108 assertions live entirely in new phase-specific tests or share a small tagged section in existing docs-contract tests, provided the local reproduction command remains `mix verify.phase108` and the scope stays low-noise.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority
- `.planning/ROADMAP.md` — Phase 108 goal, success criteria, and v1.29 roadmap status.
- `.planning/REQUIREMENTS.md` — TRUTH-01 requirement and explicit v1.29 future/out-of-scope fan-out and proof items.
- `.planning/PROJECT.md` — current milestone posture, canonical adopter contract, scope guard, and maintenance/evidence lane.
- `.planning/STATE.md` — active position after Phase 107 and accumulated decisions.
- `.planning/phases/97-canonical-contract-freeze-and-scope-guard/97-SCOPE-GUARD.md` — active scope guard and reopen policy for runtime breadth.

### Truth surfaces to reconcile
- `guides/related-data-and-reindexing.md` — canonical related-data fan-out guide and the ordinary-vs-advanced reflection wording target.
- `docs/jtbd-gap-map.md` — current JTBD ranking, diminishing-returns line, and v1.29 closeout truth.
- `CONTRIBUTING.md` — contributor verification posture and advisory `phase105-e2e` wording; edit only if line-level posture needs alignment.
- `.planning/milestone-candidates.md` — planning-truth ranking surface; consult for stale post-v1.28 statements before deciding whether it needs an update.
- `README.md` and `guides/overview.md` — route-map surfaces only; consult to avoid contradictions, but do not expand into second authorities unless needed.

### Existing implementation and verification seams
- `lib/mix/tasks/verify.phase106.ex` — focused service-free phase-gate pattern for fan-out reflection repair.
- `lib/mix/tasks/verify.phase107.ex` — focused service-free phase-gate pattern for ecommerce readiness regression proof.
- `lib/mix/tasks/verify.phase99.ex` — focused trust-gate precedent for docs and policy truth.
- `test/mix/tasks/verify.phase106_test.exs` — verify-task contract test pattern.
- `test/mix/tasks/verify.phase107_test.exs` — verify-task contract test pattern.
- `test/mix/tasks/verify.phase99_test.exs` — verify-task contract and focused source-check pattern.
- `test/scrypath/docs_contract_test.exs` — existing docs-contract seam; use carefully to avoid broad noisy assertions.
- `test/scrypath/phase99_contract_test.exs` — token/anchor-style phase contract assertion precedent.
- `mix.exs` — `cli.preferred_envs` registration point for phase verify tasks.
- `.github/workflows/ci.yml` — required/advisory CI posture reference; do not promote `phase105-e2e` here.

### Prompt guidance to apply
- `prompts/elixir-best-practices-deep-research.md` — idiomatic Elixir API and least-surprise guidance.
- `prompts/ecto-best-practices-deep-research.md` — Ecto-native context and explicitness patterns.
- `prompts/phoenix-best-practices-deep-research.md` — Phoenix context/docs ergonomics and thin web-boundary guidance.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — OSS documentation and DX lessons.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — focused, low-noise verification and release-train guidance.
- `prompts/elixir-search-lib-deep-research.md` — search-library contract and maintenance posture lessons.
- `prompts/search-lib-use-cases-deep-research.md` — adopter expectation and future-scope calibration.
- `prompts/scrypath-brand-book.md` — product voice and positioning constraints.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/verify.phase106.ex`, `lib/mix/tasks/verify.phase107.ex`, and `lib/mix/tasks/verify.phase99.ex`: established focused phase-gate scaffolds for service-free verification.
- `test/mix/tasks/verify.phase*_test.exs`: task contract tests for no-args behavior, focused command routing, and preferred env wiring.
- `test/scrypath/phase99_contract_test.exs`: precedent for token-based contract assertions over brittle prose snapshots.
- `test/scrypath/docs_contract_test.exs`: existing high-risk docs assertion seam; use only for dedicated Phase 108 anchors if sharing makes sense.
- `examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex`: concrete owner-only hand-written reflection example that should remain supported but labeled advanced/owner-only.

### Established Patterns
- Required/local confidence gates stay service-free and deterministic; heavier live/browser proof remains explicit or advisory.
- Root docs route to guide authority instead of duplicating policy matrices.
- Ecto/Phoenix guidance favors context-owned orchestration, no hidden callbacks, and explicit operational semantics.
- Phase-scoped verification uses stable tokens, anchors, and command names rather than paragraph snapshots.

### Integration Points
- New verification task likely belongs at `lib/mix/tasks/verify.phase108.ex`.
- New task test likely belongs at `test/mix/tasks/verify.phase108_test.exs`.
- New focused contract test likely belongs at `test/scrypath/phase108_contract_test.exs`.
- `mix.exs` should register the task in `cli.preferred_envs` if matching existing phase-gate pattern.
- `CONTRIBUTING.md` should mention `mix verify.phase108` only if it helps keep the v1.29 closeout proof discoverable without expanding required CI.

</code_context>

<specifics>
## Specific Ideas

- Preferred related-data wording: "For ordinary schemas, declare fan-out with `use Scrypath, fan_outs:`. Scrypath generates `__scrypath__(:fan_outs)` for this path. Hand-written `__scrypath__/1` is a low-level escape hatch for owner-only schemas that intentionally do not `use Scrypath`."
- Preferred closeout wording: "v1.29 closes the bounded contract-repair milestone: fan-out reflection via `use Scrypath, fan_outs:` is repaired, tenant-preserving ecommerce readiness regression proof is in place, and planning/JTBD truth is aligned. Scrypath now returns to maintenance-and-evidence mode: keep release/support truth and required gates green, keep `phase105-e2e` advisory unless release policy explicitly promotes it, and only reopen feature breadth with reviewed outside-adopter evidence or a concrete production bug."
- External ecosystem lesson to preserve: successful integration libraries usually give adopters a declarative default plus an explicit escape hatch. Scrypath should follow that shape without hiding fan-out, queueing, or reindex operational realities.

</specifics>

<deferred>
## Deferred Ideas

- Owner-only fan-out declaration macro (`Scrypath.FanOuts`) remains deferred.
- Public fan-out reflection helper (`Scrypath.schema_fan_outs/1`) remains deferred.
- Duplicate/nil fan-out validation tightening remains deferred.
- Deeper cross-tenant Playwright fixture expansion remains deferred.
- Promotion of `phase105-e2e` to required CI remains deferred until explicit release policy and stability evidence justify it.
- Broader feature categories remain evidence-gated: autocomplete/suggestions, vector or hybrid retrieval, public backend broadening, tenant-token helpers, and OPSUI productization.

</deferred>

---

*Phase: 108-truth-alignment-and-closeout-proof*
*Context gathered: 2026-05-31*
