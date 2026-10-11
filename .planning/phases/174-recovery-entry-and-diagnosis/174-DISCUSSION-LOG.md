# Phase 174: Recovery Entry and Diagnosis - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `174-CONTEXT.md`; this log preserves the alternatives considered.

**Date:** 2026-10-10
**Phase:** 174-recovery-entry-and-diagnosis
**Areas discussed:** Control Room hierarchy, Search health records, Failed sync recovery/action disclosure, selected-schema continuity

---

The maintainer asked the agent to automatically follow the recommended next steps. Phase 174 discussion therefore used GSD `--auto`: the agent selected all four in-scope areas and auto-adopted the recommended option for each. These entries record delegated recommendations; they are not direct user answers or a simulated interview. The review considered operator/product, design/accessibility, Phoenix/technical, security, operational-truth, and maintenance lenses, plus adversarial cases.

## Control Room: status, affected scope, and action priority

| Option | Description | Selected |
|--------|-------------|----------|
| State + affected scope + one contextual action | Keep the landing view as an orientation summary; direct incident diagnosis to Search health; leave independent verify/explore work secondary. Avoid repeating the schema ledger. | ✓ Agent recommendation, auto-adopted |
| Expanded incident dashboard | Put per-schema records and multiple recovery actions on the landing screen. This can shorten one click but duplicates Search health and competes with the independent intents. | |

**Auto-selection:** Recommended first option. A role-specific missing-backend/setup state must not offer a misleading retry path. Search health remains the source for exact per-schema identity and evidence.

## Search health: schema-record information shape

| Option | Description | Selected |
|--------|-------------|----------|
| Worst-first schema records | Keep one meaningful surface per schema, full readable identity/time, plain Backend/Queue groups, and a contextual next-check link beside the evidence. Retain semantic text cues and the existing stable rank/tie behavior. | ✓ Agent recommendation, auto-adopted |
| Collapsed fleet table | Compress schemas into a single comparison table and hide reasons/destinations in expansion controls. This may improve density but makes diagnosis less direct and can obscure long identities/actions on narrow screens. | |

**Auto-selection:** Recommended first option. Preserve the existing priority order and separate newest-evidence-first Failed sync list; do not infer freshness from last-success or zero-error values.

## Failed sync work: recovery action and evidence priority

| Option | Description | Selected |
|--------|-------------|----------|
| Reason, identity, eligibility, and gated action first | Show the actionable failure context in the record, make the existing supported retry discoverable only when currently eligible, explain unavailability, and keep verbose diagnostics secondary. | ✓ Agent recommendation, auto-adopted |
| Put recovery behind Diagnostics | Keep the row visually short by hiding its action and eligibility with optional raw evidence. This reduces first-scan density but adds discovery cost and hides the next safe action. | |

**Auto-selection:** Recommended first option. Security and operations constraints keep allowlist/host checks server-side at action time, retain the original failure record, and describe acceptance as an intermediate outcome.

## Selected schema: durable and safe recovery handoff

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical URL state and fail-closed validation | Preserve the canonical `schema` parameter through routes and history, revalidate against the current allowlist on load/action, and visibly stop for invalid or removed targets. | ✓ Agent recommendation, auto-adopted |
| LiveView-only selection with fallback | Keep selection only in process state and silently choose another schema if resolution fails. It simplifies the URL but loses refresh/history continuity and can direct work at the wrong target. | |

**Auto-selection:** Recommended first option. This follows the existing `OperatorSelection` seam and official LiveView guidance that received params are public/untrusted. Test a changed non-first selection, refresh, back/forward, and invalid/unavailable targets through rendered controls.

## the agent's Discretion

Exact comp composition, copy, iconography, token-level spacing, breakpoints, and small shared-component changes remain for the Phase 174 UI contract and plan. Keep the structural decisions and safety boundaries in `174-CONTEXT.md` fixed. No new dependency or capability was recommended.

## Deferred Ideas

None. No roadmap scope was added or deferred from this phase.
