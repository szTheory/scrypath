# Phase 175: Repair and Verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `175-CONTEXT.md`; this log preserves the alternatives considered.

**Date:** 2026-10-10
**Phase:** 175-Repair and Verification
**Areas discussed:** Evidence boundaries and operator decision order; repair versus advanced promotion; asynchronous outcome and recovery states; authorization, accessibility, and verification.

**Decision process:** The maintainer's standing instruction is to fan out relevant considerations, synthesize a recommendation, and follow it automatically; they reiterated “yes auto follow ur recs keep us moving” after compaction. I used that authority to adopt the recommended defaults below. I did not present a user interview, claim the maintainer selected a quoted option, or simulate approval.

---

## Evidence boundaries and operator decision order

| Option assessed | Pros | Cons | Outcome |
|---|---|---|---|
| Collapse queue, contract, and document evidence into one health result | Fast first scan and minimal copy | Hides which source is unknown; a clean index contract or completed queue job can falsely imply documents are visible | Rejected |
| Keep queue/task observation, index contract, and active-index document evidence distinct with local next steps | Preserves operational truth and lets operators act on the evidence they actually have | Needs careful grouping to avoid a verbose dashboard | Recommended and adopted |

**Maintainer's choice:** Agent recommendation adopted under the standing instruction above; no specific interview answer was recorded.
**Notes:** Evaluated from on-call scan speed, product trust, distributed task/index state, accessibility, and content density.

---

## Repair versus advanced promotion

| Option assessed | Pros | Cons | Outcome |
|---|---|---|---|
| Present repair and promotion as peer actions | Makes both capabilities equally visible | Makes a risky index swap compete with common incident recovery and can blur their purpose | Rejected |
| Keep eligible ordinary recovery common; separate promotion in the existing advanced disclosure and confirmation | Matches the operator job order and existing authorization/confirmation gates | Advanced actions take an extra step | Recommended and adopted |

**Maintainer's choice:** Agent recommendation adopted under the standing instruction above; no specific interview answer was recorded.
**Notes:** Preserve the rule that prior failed work blocks promotion until resolved, without blocking independent observation of new recovery work.

---

## Asynchronous outcome and recovery states

| Option assessed | Pros | Cons | Outcome |
|---|---|---|---|
| Treat accepted request as success and show a generic refresh result | Few visible states | Violates Meilisearch's asynchronous contract and encourages duplicate submissions after timeouts | Rejected |
| Retain exact task/job identity; distinguish accepted, running, terminal, and unknown observation | Enables safe follow-up and prevents observer failure from being misreported as remote task failure | Requires focused state copy and identity display | Recommended and adopted |

**Maintainer's choice:** Agent recommendation adopted under the standing instruction above; no specific interview answer was recorded.
**Notes:** Meilisearch's `202 Accepted` returns an enqueued summary; task UID, index identity, and terminal status are authoritative. Keep cancellation distinct from failure where source evidence supports that distinction. Refresh never resubmits a mutation.

---

## Authorization, accessibility, and verification

| Option assessed | Pros | Cons | Outcome |
|---|---|---|---|
| Rely on disabled controls and screenshot-only review | Low implementation/test cost | Does not prove server-side authorization, task correlation, keyboard behavior, or failure-state truth | Rejected |
| Revalidate host authorization and current eligibility at mutation time; exercise rendered and mounted evidence boundaries | Protects host boundary and proves important user-visible transitions | Requires focused fixtures and disposable-stack setup | Recommended and adopted |

**Maintainer's choice:** Agent recommendation adopted under the standing instruction above; no specific interview answer was recorded.
**Notes:** Reuse existing Ops UI primitives and executable gates; pair status color with text and expose non-focus-moving updates without stealing focus. No new dependency or visual-judge service is justified.

---

## the agent's Discretion

Exact headings, concise status/error wording, icon treatment, grouping, responsive spacing, and whether an existing shared primitive needs a small semantic improvement remain open to the UI contract. Researchers and planners may choose task decomposition. The evidence and authorization rules in `175-CONTEXT.md` remain fixed.

## Deferred Ideas

None. New recovery capabilities, backends, authorization products, and operator surfaces remain outside the approved Phase 175 boundary.
