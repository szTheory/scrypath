# Phase 110: Support Intake and Evidence Routing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 110-Support Intake and Evidence Routing
**Areas discussed:** Evidence Template Shape, Classification and Routing Model, Verification Boundary, Public Surface Scope

---

## Evidence Template Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Mostly freeform Markdown sections | Lowest reporter friction, but Class A-D remains implicit and maintainer follow-up risk stays higher. | |
| Structured GitHub Issue Form | Strongest enforcement and filtering, but too much process weight for current outside-adopter volume. | |
| Hybrid Markdown template | Keep narrative sections and add a compact required evidence block for path, support-matrix status, class guess, finding guess, ref/version, failing step, and logs. | yes |

**User's choice:** Discuss all gray areas with subagent research and produce one cohesive recommendation set.
**Notes:** Subagent research recommended the hybrid shape as the best balance of adopter DX, reproducibility, and maintenance-mode scope discipline.

---

## Classification and Routing Model

| Option | Description | Selected |
|--------|-------------|----------|
| Keep prose-only guidance | Lowest churn, but maintainer interpretation can drift. | |
| Add compact decision table/checklist | Makes Class A-D and finding bucket routing deterministic while staying docs-first and lightweight. | yes |
| Move to GitHub Issue Form dropdown routing | Highest normalization, but too bureaucratic for the current phase. | |

**User's choice:** Discuss all gray areas with subagent research and produce one cohesive recommendation set.
**Notes:** The selected model maps Class A-D plus finding buckets to maintainer actions: bugfix, docs gap, app-side error, environment failure, or needs-info.

---

## Verification Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Add `mix verify.phase110` plus a focused contract test | Clear phase-local command, but risks verify-task and gate sprawl. | |
| Extend only existing readiness/phase98/phase99 tests | No new command surface, but blurs Phase 110 completion and makes failures noisier. | |
| Add `test/scrypath/phase110_contract_test.exs` and wire it into an existing fast support path | Explicit SUP-01/SUP-02 proof without a new required CI lane. | yes |

**User's choice:** Discuss all gray areas with subagent research and produce one cohesive recommendation set.
**Notes:** Research recommended keeping routine gates lean and service-free while adding precise Phase 110 assertions.

---

## Public Surface Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Core support surfaces only | Maximum scope discipline, but website/operator entrypoints may remain weaker routing surfaces. | |
| Core surfaces plus minimal route-only public entrypoint hygiene | Keeps support routing coherent without stealing Phase 112 website truth work. | yes |
| Broad docs/website/operator truth cleanup | One-pass polish, but violates the Phase 110/112 boundary. | |

**User's choice:** Discuss all gray areas with subagent research and produce one cohesive recommendation set.
**Notes:** Phase 110 may normalize route-only links/callouts in website/operator entrypoints. Broad claim alignment and homepage narrative work remain Phase 112.

---

## the agent's Discretion

- Planner may choose exact Markdown wording, table layout, and test helper organization.
- Planner may decide the exact existing fast support verification alias for the Phase 110 contract test.
- Planner may make minimal route-only public entrypoint edits when they remove support-routing ambiguity.

## Deferred Ideas

- GitHub Issue Forms migration.
- New `mix verify.phase110` command unless planning proves it is worth the extra verify surface.
- Broad website/public claim cleanup, reserved for Phase 112.
- Any feature-lane reopen or new runtime/product surface.
