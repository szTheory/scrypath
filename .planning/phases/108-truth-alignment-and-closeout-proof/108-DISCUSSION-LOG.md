# Phase 108: Truth Alignment and Closeout Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 108-truth-alignment-and-closeout-proof
**Areas discussed:** Related-data wording, Truth surface scope, Verification posture, Closeout language

---

## Related-data wording

| Option | Description | Selected |
|--------|-------------|----------|
| Strong-default docs | Present `use Scrypath, fan_outs:` as the normal path; document hand-written `__scrypath__/1` only as owner-only/advanced escape hatch. | yes |
| Equal-weight docs | Show macro and hand-written reflection as peers. | |
| Conservative docs | Keep hand-written reflection primary and mention macro as optional. | |

**User's choice:** Asked the agent to research all areas with subagents and produce one-shot recommendations.
**Notes:** Recommendation locks the strong-default approach because it matches Phase 106, reduces copy-paste footguns, and follows the ecosystem pattern of declarative default plus explicit advanced escape hatch.

---

## Truth surface scope

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal pair only | Update only `guides/related-data-and-reindexing.md` and `docs/jtbd-gap-map.md`. | |
| Bounded truth set | Update related-data guide, JTBD gap map, core planning truth, and line-level verification posture as needed. | yes |
| Broad sweep | Rewrite README, overview, milestone candidates, state, CONTRIBUTING, and other route maps broadly. | |

**User's choice:** Asked the agent to research all areas with subagents and produce one-shot recommendations.
**Notes:** Recommendation locks a bounded truth set to cover TRUTH-01 end-to-end without turning README/overview into second authorities.

---

## Verification posture

| Option | Description | Selected |
|--------|-------------|----------|
| Add focused `mix verify.phase108` | Create a narrow service-free gate for TRUTH-01 truth alignment. | yes |
| Extend docs-contract only | Add assertions to existing docs-contract tests without a new task. | |
| Audit plus existing gates | Rely on manual/documented audit and Phase 106/107 gates. | |

**User's choice:** Asked the agent to research all areas with subagents and produce one-shot recommendations.
**Notes:** Recommendation locks a narrow service-free `mix verify.phase108` because it matches existing phase-gate ergonomics and gives contributors one local command without promoting live/browser proof.

---

## Closeout language

| Option | Description | Selected |
|--------|-------------|----------|
| Repair complete; return to maintenance/evidence mode | Decisive closure and explicit scope gate. | yes |
| Near-done; still tracking proof stability | Softer framing that leaves more ambiguity. | |
| Repair complete now; proof stability monitored in maintenance lane | Decisive closure plus explicit ongoing monitoring caveat. | yes |

**User's choice:** Asked the agent to research all areas with subagents and produce one-shot recommendations.
**Notes:** Recommendation locks the dual-frame variant leaning decisive: v1.29 repair is complete after Phase 108, proof stability continues in maintenance, and feature breadth only reopens with outside-adopter evidence or concrete production bugs.

---

## the agent's Discretion

- Exact wording and assertion helper names are left to the planner/executor.
- Exact split between a new phase contract test and tagged existing docs-contract assertions is left to the planner/executor, provided `mix verify.phase108` stays the local command and remains service-free.

## Deferred Ideas

- Owner-only fan-out macro.
- Public fan-out reflection helper.
- Stricter fan-out validation diagnostics.
- Deeper cross-tenant Playwright fixture expansion.
- Promotion of `phase105-e2e` to required CI.
- Any broader feature-lane reopening without reviewed outside-adopter evidence or a concrete production bug.
