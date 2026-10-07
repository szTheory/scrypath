# Phase 174: Recovery Entry and Diagnosis - Discussion Log

> **Audit trail only.** Do not use as input to planning, research or execution agents.
> Decisions are captured in `174-CONTEXT.md`; this log preserves the discussion and alternatives considered.

**Date:** 2026-10-06 (America/New_York; recorded 2026-10-07 UTC)
**Phase:** 174-recovery-entry-and-diagnosis
**Areas discussed:** Control Room priorities, Search health scanning, Failed-work recovery, Schema context

## Interaction and authority

1. The agent reloaded the committed Phase 173 handoff in the prepared planning-only successor, checked Phase 174 had no context/plans, loaded prior decisions and scouted current recovery code. No prior phase was replayed.
2. The agent presented four areas with concrete descriptions: Control Room state/next-action priority; Search health facts/groups/action placement; failed-work eligibility/history before diagnostics; selected-schema context through fleet/recovery views and unavailable-target states. The user could select numbers or all.
3. The maintainer selected **all** and supplied a generic research/fan-out instruction: consider relevant stakeholder lenses, pros/cons/tradeoffs, examples, patterns/antipatterns/footguns, reputable primary sources and an adversarial pass, stopping at diminishing returns. They repeated the preference for small, flat dependency trees and small owned code over unnecessary dependencies. This replaced the normal question-by-question interview with delegated consideration; it did not silently approve unseen defaults.
4. Three typed `gsd-advisor-researcher` agents handled Control Room, Search health and Failed sync work. The Control Room agent was reused for schema-context advice; the Search health agent ran a bounded adversarial synthesis challenge. Project adaptive routing resolved `gpt-6-luna` / high effort, passed explicitly with no conversation fork. All work was read-only advice, not implementation, independent verification or reviewer approval.
5. The parent synthesized and presented the four-area comparison and twelve concrete recommendations, including bounded health claims, duplicate-control removal, selection precedence, current schema-record layout, focus/reflow, source-specific work names, ordinary retry visibility, automatic versus manual retry, safety/evidence boundaries, URL context, three concrete footguns and no new dependency. Primary sources were linked.
6. Final choice presented: **1 — Adopt these recommendations** / **2 — Revise, tell me what to change**. The user replied **1**, adopting the complete synthesis. The resulting decisions are now captured in `174-CONTEXT.md`.

## Control Room priorities

| Option | Description | Selected |
| --- | --- | --- |
| State-led recovery entry | Observed state, affected allowed-schema scope and one safe read-only next step lead; verification/exploration remain quieter | Yes, through adoption of the synthesis |
| Equal three-intent launcher | Keeps recovery, verification and exploration equally prominent; repeats health/recovery entry during an incident | No |

**User's choice:** Adopt the state-led recommendation.
**Notes:** Preserve direct navigation/palette, configuration/partial/unavailable distinctions and bounded claims. A zero observed failure count does not prove all backends healthy or documents fresh. The initial specialist suggestion to automatically select a single affected schema was corrected: an explicit operator selection takes precedence.

## Search health scanning

| Option | Description | Selected |
| --- | --- | --- |
| Ranked schema records | One neutral record per schema; readable full identities, plain Backend/Queue groups, scoped next checks | Yes, through adoption of the synthesis |
| Compact table with expansion | Denser large-fleet comparison but more column pressure and hidden evidence/mobile/focus complexity | No |

**User's choice:** Refine the existing records and preserve classification semantics.
**Notes:** Fleet priority and recovery target remain separate. Keep stable focused identity through refresh reordering; use logical reflow and current time patterns, with no new table/filter/pagination feature.

## Failed-work recovery

| Option | Description | Selected |
| --- | --- | --- |
| Source-aware recovery row | Source/work identity, operation, reason/time and recovery availability before diagnostics; ordinary supported retry control | Yes, through adoption of the synthesis |
| Diagnostics-first compact row | Requires opening evidence to understand recovery; weaker incident scanability | No |

**User's choice:** Adopt source-aware rows and visible supported recovery.
**Notes:** Existing reason/action placement already precedes diagnostics; improve remaining source naming, eligibility explanation and advanced/extra-small treatment rather than replay an already completed fix. Keep automatic Oban retry distinct from executable manual replay. Preserve delete review and server/host gates, accepted receipt and original history. Use source-qualified internal identities to prevent collisions between equal numeric source IDs; no public API change or exactly-once claim.

## Schema context

| Option | Description | Selected |
| --- | --- | --- |
| Validated canonical URL target | Explicit query context survives reload/Back and uses current allowlist resolution and existing mounted-path helpers | Yes, through adoption of the synthesis |
| Browser/session sticky target | Hidden shared state can conflict with tabs/history and removed targets; additional synchronization | No |

**User's choice:** URL target authority with explicit-selection precedence.
**Notes:** Fleet views stay fleet-wide. The existing first default is allowed only for absent targets on schema-specific pages; explicit invalid/removed targets never substitute another schema. Preserve context through recovery rail/mobile/palette and existing sudo return, while respecting auth policy and context invalidation. Palette links must update after a selector patch despite the ignored subtree. Existing rendered changed-selection/Back/reload proof is present and should be extended through the new seams.

## Primary-source and adversarial synthesis

The specialist/parent passes used official Cloudscape, Carbon, Grafana, W3C, Phoenix LiveView, Oban and Meilisearch documentation. Their URLs and the relevant project references are preserved in the canonical context. External design-system guidance informed presentation; project code and requirements define severity, replay and auth semantics. Current general documentation was not treated as authority to upgrade pinned dependencies.

The adversarial challenge reinforced four points: selected context cannot override fleet evidence; refresh reordering must preserve logical focus; primary flow must not expand raw diagnostic/authentication payloads; unavailable observations cannot read as remote terminal failure. Concrete cases were incorporated into acceptance, without pretending they were reproduced or fixed during discussion.

## Agent's Discretion

Exact concise copy, responsive composition within the ensuing UI contract, internal source-qualified UI-key representation, bounded link/hook implementation and helper extraction justified by repeated use. No dependency is recommended. The next lifecycle step is `$gsd-ui-phase 174`, then `$gsd-plan-phase 174`; no automatic implementation chain was requested.

## Deferred Ideas and preserved limits

No additional capability was approved. Large-fleet table/filter/pagination work requires scale evidence; global sticky state, automatic orchestration, cross-session exactly-once guarantees, new auth/redaction products and infrastructure automation remain outside scope. Later phase ownership is preserved.

Inherited broad advisory E2E failures, unchanged Ops-lock Cloak advisories and historical evidence limitations remain recorded; no risk acceptance, release approval or full-matrix success was inferred. The original dirty checkout/preview and frozen Phase 173 source/PR remain untouched.
