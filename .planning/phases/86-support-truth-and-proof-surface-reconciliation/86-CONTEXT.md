# Phase 86: Support Truth And Proof Surface Reconciliation - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 86 reconciles Scrypath's current support, readiness, and proof surfaces with the checked-out tree that actually exists. This phase does not add new search capability. It fixes truth drift around canonical support/readiness authority, `mix verify.adopter`, and archive-era `SearchModule` claims so maintainers and adopters can trust the defended Phoenix + Meilisearch path before outside-adopter intake begins in Phase 87.

</domain>

<decisions>
## Implementation Decisions

### Canonical support surface
- **D-01:** Restore one dedicated support/readiness guide as the single canonical authority instead of keeping truth split across `README.md`, `CONTRIBUTING.md`, and the example README.
- **D-02:** Keep that guide narrow and contract-shaped. It should define: defended Phoenix + Meilisearch path, supported runtime/version anchors, supported sync-mode posture, canonical proof command family, repo-clone vs Hex-package boundary, and the distinction between in-repo proof and reviewed outside-adopter evidence.
- **D-03:** Do not let the restored guide duplicate the sync semantics owned by `guides/sync-modes-and-visibility.md` or the live env/runbook details owned by `examples/phoenix_meilisearch/README.md`.
- **D-04:** Keep `README.md` as the adopter front door and quick-path map, `CONTRIBUTING.md` as the maintainer workflow surface, and the example README as the authoritative live proof runbook. Those files should point to the canonical support/readiness guide rather than each becoming partial authorities.

### `mix verify.adopter` contract
- **D-05:** Phase 86 should do more than replace the stale fast target. It should tighten the fast-vs-live contract across task help, task implementation, focused tests, and bounded maintainer docs.
- **D-06:** The fast mode must stay narrow, honest, and service-free. It should target existing files only and should not be widened into the full docs-contract suite.
- **D-07:** The live mode remains the explicit Phoenix example proof path under `examples/phoenix_meilisearch`, with loud prerequisite checks and CI-parity wording.
- **D-08:** `mix help verify.adopter` is treated as a maintainer-facing contract surface and must stay aligned with the actual fast/live execution paths.
- **D-09:** `CONTRIBUTING.md` should explicitly name `mix verify.adopter` as the maintainer-facing adopter-proof command family and map fast mode, live mode, and the `phoenix-example-integration` CI job clearly.

### SearchModule drift handling
- **D-10:** Treat the `v1.20` `Scrypath.SearchModule` mismatch as a history-reconciliation problem, not just a wording fix.
- **D-11:** Do one bounded salvage/history check first, then correct active claims immediately. The purpose is classification, not feature recovery.
- **D-12:** The checked-out branch-tip truth must be made explicit: `main` does not currently expose `Scrypath.SearchModule`, its guide, or its tests.
- **D-13:** If milestone archives or audits clearly point to previously existing implementation artifacts, preserve that distinction in wording: historically claimed/recoverable is not the same as currently available on `main`.
- **D-14:** Do not let Phase 86 widen into relanding or resurrecting `SearchModule`. Any recovery decision is deferred to a separate future product/maintenance call.

### Regression guard scope
- **D-15:** Prefer minimal bounded guards over a broad planning/docs truth net. Phase 86 should protect the concrete support-truth seams that drifted, not freeze large amounts of prose.
- **D-16:** Add guards that directly prove:
  - advertised `verify.adopter` fast-path files exist
  - `mix help verify.adopter` matches the real fast/live contract
  - active maintainer/adopter docs point to one current canonical support/readiness surface
  - active planning surfaces do not restate removed `support-and-compatibility` or `SearchModule` surfaces as current checked-out truth
- **D-17:** Do not treat active planning prose as a release-grade fully snapshotted contract surface. The goal is trust repair with low recurrence risk, not building a second product in tests.

### Workflow preference for this phase
- **D-18:** Research should lead. For planning and execution inside Phase 86, prefer repo-local truth, `prompts/` research, and bounded ecosystem comparison before asking the user follow-up questions.
- **D-19:** Only escalate back to the user on genuinely high-impact branch decisions or when live repo evidence cannot resolve the ambiguity safely.

### the agent's Discretion
- Exact filename for the restored support/readiness guide.
- Whether the focused fast-path contract becomes a new dedicated test file or a narrow reuse of an existing test seam, as long as it stays small and truthful.
- Exact wording used to separate branch-tip truth from historical/archive truth for `SearchModule`.
- Exact placement of maintainer pointers in `README.md` vs `CONTRIBUTING.md`, provided the authority split above is preserved.

</decisions>

<specifics>
## Specific Ideas

- The desired product feel is: small explicit public surface, one obvious truth source per concern, no hidden operational semantics, no archaeology-driven maintainer burden.
- The recommended doc shape is closer to Oban / Laravel Scout than to a giant monolithic README: thin front door, deeper canonical guide, example runbook isolated where it belongs.
- The recommended test shape is executable-truth-first rather than prose-locking. Keep guards close to the broken seams.
- The maintainer preference for this phase is "think deeply one-shot, do the research first, ask later only if the fork actually matters."

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and scope truth
- `.planning/ROADMAP.md` — Phase 86 goal, plans `86-01` through `86-03`, and milestone sequencing.
- `.planning/REQUIREMENTS.md` — `TRUTH-01` through `TRUTH-03` acceptance targets for this phase.
- `.planning/STATE.md` — current drift notes, blocker framing, and active-milestone posture.
- `.planning/PROJECT.md` — project-level scope, current posture, and boundary discipline.

### Current proof and support surfaces
- `README.md` — adopter front door and current wayfinding surface.
- `CONTRIBUTING.md` — maintainer verification and CI matrix surface.
- `examples/phoenix_meilisearch/README.md` — canonical live Phoenix example runbook and CI-shaped example truth.
- `lib/mix/tasks/verify.adopter.ex` — current fast/live task contract and stale-target drift.
- `test/mix/tasks/verify_adopter_test.exs` — current task regression seam.
- `guides/jtbd-and-user-flows.md` — product-level adopter mental model.
- `guides/sync-modes-and-visibility.md` — canonical sync semantics authority that must not be duplicated loosely.

### Drift and archive truth
- `test/scrypath/docs_contract_test.exs` — current docs-contract seam, including live branch-tip expectations around `SearchModule`.
- `.planning/todos/search-module-archive-code-drift.md` — existing recorded drift and intended resolution shape.
- `.planning/MILESTONES.md` — active rolling planning surface that still carries `SearchModule` archive claims.
- `.planning/milestones/v1.20-ROADMAP.md` — historical milestone claims for the `SearchModule` arc.
- `.planning/milestones/v1.20-MILESTONE-AUDIT.md` — archive/audit truth that currently references missing branch-tip files.

### Local research and methodology
- `docs/jtbd-gap-map.md` — current leverage ranking and diminishing-returns framing.
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Elixir OSS API/docs expectations.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — maintainer verification and CI norms.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — context boundaries and explicit-runtime design norms.
- `prompts/search-lib-use-cases-deep-research.md` — search-library adopter jobs and leverage framing.
- `prompts/scrypath-brand-book.md` — voice and product-posture constraints for public-facing wording.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/verify.adopter.ex`: existing command seam for fast/live proof; should be repaired, not replaced.
- `test/mix/tasks/verify_adopter_test.exs`: existing focused task test file; good base for contract-strengthening.
- `test/scrypath/docs_contract_test.exs`: already enforces some branch-tip truth; use sparingly for narrow support-surface checks rather than broad new prose locking.
- `examples/phoenix_meilisearch/README.md`: already owns the best live-runbook detail; avoid duplicating it elsewhere.

### Established Patterns
- Scrypath consistently treats one guide as canonical per concern and routes shorter docs toward it.
- Context-owned orchestration and optional Phoenix glue are established constraints; documentation should preserve that same boundary discipline.
- Verify tasks in this repo are usually narrow and purpose-built; broad "do everything" task sprawl is not the house style.

### Integration Points
- Support/readiness guide must route cleanly from `README.md`, `CONTRIBUTING.md`, and `mix help verify.adopter`.
- `verify.adopter` fast/live wording must align with the example README and CI job names.
- Planning truth updates must keep active files aligned with branch-tip reality while preserving archive nuance for `v1.20`.

</code_context>

<deferred>
## Deferred Ideas

- Relanding or resurrecting `Scrypath.SearchModule` as code on `main`.
- Building a broad planning-wide or docs-wide frozen truth harness beyond the few seams that actually drifted.
- Any new product capability, search feature, or adopter wedge; those remain Phase 87+ concerns.

</deferred>

---

*Phase: 86-support-truth-and-proof-surface-reconciliation*
*Context gathered: 2026-05-24*
