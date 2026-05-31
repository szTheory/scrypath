# Phase 106: Fan-Out Reflection Contract Repair - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 106-fan-out-reflection-contract-repair
**Areas discussed:** Compatibility semantics, Proof boundary, Docs/API boundary

---

## Compatibility Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Generated `:fan_outs` plus owner-only hand-written compatibility | Smallest repair: ordinary `use Scrypath` schemas get generated `__scrypath__(:fan_outs)`, owner-only schemas keep hand-written reflection. | |
| Generated `:fan_outs` plus `defoverridable __scrypath__/1` delegation escape hatch | Preserves owner-only compatibility while giving advanced `use Scrypath` schemas a bounded customization path without new public API. | yes |
| Generated/private split such as `__scrypath_generated__/1` | Strong extensibility, but too much contract movement for a bounded repair. | |

**User's choice:** User asked to discuss all areas with subagent research and receive a cohesive recommendation.
**Notes:** Recommended path is generated `__scrypath__(:fan_outs)` for ordinary declarations, preserved hand-written owner compatibility, and a documented `defoverridable` delegation escape hatch if implementation needs advanced customization.

---

## Proof Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| `schema_test` only | Fast reflection proof, but does not prove runtime fan-out consumption. | |
| Reflection plus related sync/worker tests | Proves declaration-to-consumption behavior, but lacks a named phase proof command. | |
| Focused `mix verify.phase106` gate | Runs schema reflection plus related sync/worker consumption tests through a local phase proof command, without required CI expansion. | yes |

**User's choice:** User asked for one-shot recommendations that move the project toward the milestone goals.
**Notes:** Recommended path is a service-free `mix verify.phase106` covering `test/scrypath/schema_test.exs`, `test/scrypath/sync/related_test.exs`, and `test/scrypath/sync/related_worker_test.exs`.

---

## Docs/API Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 106 code-only, defer adopter docs to Phase 108 | Maximum scope containment, but temporary doc/code drift risk. | |
| Targeted Phase 106 contract correction, broader truth in Phase 108 | Allows minimal ordinary-vs-unusual wording correction without widening public API. | yes |
| Add `Scrypath.schema_fan_outs/1` helper | Cleaner reader API, but explicitly deferred and too broad for v1.29. | |

**User's choice:** User asked for recommendations coherent with scope guard, DX, and least surprise.
**Notes:** Recommended path is no new public helper API in Phase 106. Minimal docs corrections are allowed only where needed to avoid immediate contract confusion; broad docs/JTBD reconciliation stays in Phase 108.

---

## Codex's Discretion

- Exact assertion names and helper structure.
- Exact `verify.phase106` shell output wording.
- Whether a minimal docs-contract assertion lands in Phase 106 or waits for Phase 108, provided no broad docs rewrite happens in Phase 106.

## Deferred Ideas

- `Scrypath.FanOuts` owner-only macro.
- `Scrypath.schema_fan_outs/1` public helper.
- Duplicate/nil fan-out validation tightening.
- Broader related-data docs and JTBD truth reconciliation beyond targeted contract corrections.
