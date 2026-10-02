# Phase 170: Documentation and Readiness Closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-29
**Phase:** 170-documentation-and-readiness-closeout
**Areas discussed:** Adopter documentation hierarchy and first-result journey; durable terminal readiness record

---

## Adopter documentation hierarchy and first-result journey

| Option | Description | Selected |
|--------|-------------|----------|
| Concise summary and canonical links | Keep short mode-selection guidance and the acceptance/visibility caveat; route detailed sync semantics and return contracts to the canonical guide and API docs. Merge duplicate route maps while keeping unique useful destinations. | ✓ |
| Compact sync-mode table and canonical links | Keep a three-row mode comparison and caveat in README, with detailed contracts at their canonical owners. | |
| Links only | Replace README sync guidance with links to canonical docs. | |

**User's choice:** Adopt the concise summary-and-links recommendation and merge duplicate README/JTBD navigation while preserving useful unique routes.
**Notes:** The user asked for recommendation-led research across relevant disciplines, with strong developer ergonomics and a coherent set of trade-offs. Specialist research used the local v1.41 adoption review and project prompts, plus Ecto, Phoenix, ExDoc, and Searchkick documentation examples. The sync guide heading and copy-specific assertions should be corrected narrowly.

---

## Durable terminal readiness record

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated GitHub issue and dated comment | Link a dedicated issue from the tracked readiness authority before final attestation; post the semantic six-condition decision as a dated comment after final-source attestation. Append dated corrections. | ✓ |
| Long-retention object storage with write-once controls | Store the terminal decision in a separately operated retention-controlled service. | |
| GitHub Release note or asset | Attach the decision to the public release when one is published. | |

**User's choice:** Adopt the dedicated GitHub issue and dated-comment recommendation.
**Notes:** A Release asset is coupled to publication and cannot stand alone if the patch is blocked or explicitly deferred. Existing CI artifacts are short-lived and report job outcomes, not semantic readiness. The user added an automation-first/shift-left bias. Apply it to receipt gathering, source/run consistency, required-field and link checks, and record-shape validation; keep semantic judgments and the final readiness decision accountable to the maintainer, and reuse existing CI lanes unless recurring value justifies a new one.

---

## the agent's Discretion

- Select the smallest maintainable way to collect and validate factual receipt fields from existing workflow outputs.
- Make focused updates to documentation assertions superseded by the copy consolidation while retaining meaningful docs validation.
- Choose plan decomposition and applicable existing verification commands.

## Deferred Ideas

None — discussion stayed within the approved Phase 170 scope.
