# Phase 147: Ecommerce Mounted-Ops Remediation and Closure Evidence - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-25
**Phase:** 147-ecommerce-mounted-ops-remediation-and-closure-evidence
**Areas discussed:** Mounted-source provenance, Required gate bundle, Browser evidence, Closure ledger and commit truth

---

## Todo Intake

| Option | Description | Selected |
|--------|-------------|----------|
| Fold it into Phase 147 | Complete the todo's remaining ecommerce and all-graph closure work here | ✓ |
| Review but do not fold | Preserve the todo separately | |

**User's choice:** Fold it into Phase 147.
**Notes:** The root/shared, legacy, and Ops portions were already completed in Phases 144-146. The todo remains open until Phase 147 closes its full evidence chain.

---

## Mounted-Source Provenance

### Provenance model

| Option | Description | Selected |
|--------|-------------|----------|
| Two-stage isolated proof | Isolated pre-commit proof plus guarded exact-SHA detached proof | ✓ |
| Isolated pre-commit only | Lean, but lacks immutable candidate reproduction | |
| Detached exact-SHA only | Strong audit artifact, but cannot satisfy the before-commit gate alone | |
| You decide | Use the recommendation unless blocked | |

### Receipt contents

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical paths + hashes + status | Assert both path sources and record candidate/input/dirty-state identity | ✓ |
| Canonical paths only | Proves source selection without exact dependency inputs | |
| Hashes only | Records inputs without proving the resolved path | |
| You decide | Use the complete receipt | |

### Build isolation

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh temporary paths for every command | Propagate isolated dependency/build paths through fetch, compile, tests, and preparation | ✓ |
| Isolate compile/tests only | Reuse fetched dependency sources | |
| Trust normal Mix caches | Depend on automatic path recompilation without extra isolation | |

### Cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Guarded cleanup and compact receipt | Fail-closed path validation, cleanup, absence checks, and redacted evidence | ✓ |
| Best-effort cleanup | Simpler but weaker failure safety | |
| Retain worktree | Easier manual inspection but leaks disposable state | |

**User's choice:** Explicitly selected the recommended model, receipt, and full isolation; then requested that all remaining recommendations be followed automatically.
**Notes:** Phase 146's macOS canonical-path and cleanup lessons are binding precedent. Contributor caches must not be destroyed.

---

## Required Gate Bundle

| Decision | Alternatives considered | Selected recommendation |
|----------|-------------------------|-------------------------|
| Overall model | Ecommerce-only; layered closure; promote full browser lane | Layered closure bundle |
| Ecommerce order | Causal-first; full-suite-only; preparation-first | Diff → checked lock/source identity → compile → focused mount → precommit → lock/status recheck |
| Live preparation | Required prerequisite-bound; supplemental; browser-only | Required `mix e2e.prepare`; unavailable blocks closure |
| Upstream regressions | Root+Ops always; root only; none | Root gates once; Ops only if Phase 147 touches Ops-owned files or finds an Ops regression |

**User's choice:** Auto-follow the research-backed recommendations.
**Notes:** `precommit` can format and unlock unused dependencies, so post-command lock/status verification is mandatory. Browser work does not substitute for required preparation.

---

## Browser Evidence

| Decision | Alternatives considered | Selected recommendation |
|----------|-------------------------|-------------------------|
| Proportional local proof | Full Phase 105 suite; focused mounted subset; CI-only reuse | Existing `harness.spec.ts` + `operator.spec.ts` subset when prerequisites are available |
| Full-lane use | Always rerun; reuse exact-SHA CI; ignore | Reuse exact-SHA advisory CI result when present |
| Classification | Binary; narrative; three-state | `passed` / `failed` / `unavailable`, plus `flake: true` on retry recovery |
| Failure policy | Any failure blocks; none block; causal failures block | Causal mounted regression blocks; non-causal advisory failure stays honestly classified without expanding UI scope |

**User's choice:** Auto-follow the research-backed recommendations.
**Notes:** Existing visual/theme/contrast evidence remains useful for regression detection but is not promoted to a Phase 147 gate. Current `brandbook/` is the visual authority if interpretation is needed.

---

## Closure Ledger and Commit Truth

| Decision | Alternatives considered | Selected recommendation |
|----------|-------------------------|-------------------------|
| Evidence model | Fresh-reprove all; historical only; hybrid | Hybrid historical exact-SHA proofs + fresh ecommerce + same-window final checked-lock/audit rows |
| History model | Literal four commits; unlabeled SHA list; remediation batches | Four ordered batches with primary/recovery/test-only roles preserved |
| Artifact detail | Raw transcript; prose only; compact matrix | Compact graph/SHA/time/tool/lock/version/status/reference matrix |
| Closure timing | After lock update; after browser; after full evidence | Close todo only after implementation, gates, fresh proof, four dated rows, browser classification, topology, and cleanup |

**User's choice:** Auto-follow the research-backed recommendations.
**Notes:** Preserve history exactly: `f711521`; `e50fbd5` + `4e2abed`; `59d2e6a` + `ff1531c`; future ecommerce commit. Reconcile planning wording to four remediation batches. Preserve the user-owned untracked milestone audit without staging or editing it.

---

## the agent's Discretion

- Temporary directory names and the exact public Mix expression used for path assertions.
- Compact evidence-table formatting and command ordering where `CONTRIBUTING.md` dependencies require it.
- Direct Playwright spec-path invocation details, provided no permanent script or CI lane is added.

## Deferred Ideas

- Permanent dependency/security automation.
- Promotion of `phase105-e2e` to a required lane.
- Package-head modernization.
- Product, UI, accessibility-design, theme, motion, microcopy, or brand changes.
