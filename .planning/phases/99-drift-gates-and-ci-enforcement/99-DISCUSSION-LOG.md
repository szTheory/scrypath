# Phase 99: Drift Gates and CI Enforcement - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `99-CONTEXT.md`; this log preserves alternatives considered.

**Date:** 2026-05-27
**Phase:** 99-drift-gates-and-ci-enforcement
**Areas discussed:** gate shape, required PR checks, assertion placement, strictness calibration, coherent architecture

---

## 1) `verify.phase99` gate shape

| Option | Description | Selected |
|--------|-------------|----------|
| Delegating umbrella gate | `verify.phase99` delegates to prior phase gates and adds minimal phase-99 checks | |
| Focused dedicated gate | `verify.phase99` runs only focused phase-99 trust suites and docs build | ✓ |
| Manifest-driven gate | Declarative contract manifest plus generic runner | |
| CI-only enforcement | No new Mix gate; rely on workflow checks only | |

**User's choice:** Focused dedicated gate (research-backed recommendation selected one-shot).
**Notes:** Maximizes signal-to-noise, preserves local/CI parity, and aligns with existing `verify.phase97`/`verify.phase98` task pattern.

---

## 2) Required PR checks contract

| Option | Description | Selected |
|--------|-------------|----------|
| Keep current required three | Keep only `main-ci`, `repo-hygiene`, `release-truth` required | |
| Lean-4 required contract | Existing three + one stable phase-99 trust check job | ✓ |
| Single meta-check | Collapse all required logic into one aggregate CI status | |
| Path-sensitive required checks | Conditionally require trust checks only for certain file changes | |

**User's choice:** Lean-4 required contract (research-backed recommendation selected one-shot).
**Notes:** Most coherent with v1.27 goals: explicit trust enforcement without promoting heavy/integration checks to routine blockers.

---

## 3) Drift assertion placement and ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Add all checks to `docs_contract_test.exs` | Keep one large umbrella docs contract suite | |
| Phase-scoped ownership split | Add `phase99_contract_test.exs`; keep `docs_contract_test.exs` evergreen | ✓ |
| Surface-owned micro-suites | Split by surface (`readme_contract`, `ci_contract`, etc.) immediately | |
| Manifest-runner ownership | Assertions generated from a shared policy manifest | |

**User's choice:** Phase-scoped ownership split (research-backed recommendation selected one-shot).
**Notes:** Maintains failure readability and keeps long-lived docs contracts from accumulating milestone noise.

---

## 4) Strictness/noise calibration

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal | Keep trust checks mostly advisory | |
| Balanced strict core | Required service-free trust gate with token/anchor assertions; heavy checks advisory | ✓ |
| Diff-aware escalation | Conditionally tighten strictness based on changed paths | |
| Hard-block all | Promote most heavy/integration checks to required | |

**User's choice:** Balanced strict core (research-backed recommendation selected one-shot).
**Notes:** Best fit for release-train stability and least-surprise DX in pre-1.0 OSS maintenance cadence.

---

## 5) Coherent architecture across all decisions

| Option | Description | Selected |
|--------|-------------|----------|
| One big monolith gate | Centralize all trust checks into one broad assertion surface | |
| Layered trust rings | Content contract + wiring contract + required-check policy, all via one canonical command | ✓ |
| Manifest engine architecture | Shared declarative policy engine driving all trust checks | |

**User's choice:** Layered trust rings (research-backed recommendation selected one-shot).
**Notes:** Gives coherent, explainable architecture with strong enforcement and bounded complexity.

---

## Ecosystem Lessons Applied

- Keep required checks deterministic and fast; keep live/integration proof explicit and prerequisite-bound unless deliberately promoted.
- Prefer explicit bounded contracts over framework-like abstraction layers for gate policy (especially pre-1.0 library phase).
- Avoid broad prose snapshot tests; token/anchor/check-name assertions reduce CI false positives and contributor friction.
- Keep local command parity with CI required checks (`mix verify.phase99` as canonical seam).

## Claude's Discretion

- Final required trust-job name (`phase99-trust` vs `phase99-contract`) as long as naming is stable and parity-tested.
- Exact assertion helper organization and failure-message formatting.
- Exact split between focused phase99 suite and existing evergreen docs contract suite.

## Deferred Ideas

- Manifest-driven policy engine for future milestones.
- Path-sensitive required-check escalation.
- Broad required promotion of live/service-heavy checks.
