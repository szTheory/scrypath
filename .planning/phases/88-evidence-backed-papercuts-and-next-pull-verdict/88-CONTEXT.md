# Phase 88: Evidence-Backed Papercuts And Next-Pull Verdict - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 88 focuses exclusively on closing the evidence-backed papercuts accepted from Phase 87 and formally ending the milestone with the explicit next-step verdict. The only accepted papercut is a docs/onboarding gap regarding how to manually handle related-data updates (a `docs/onboarding gap`). This phase does not build the `related-data propagation` feature; it merely documents the workaround and freezes the milestone so that the next milestone can open the feature.

</domain>

<decisions>
## Implementation Decisions

### Documentation Papercut Fix
- **D-01:** Add clear instructions in `guides/related-data-and-reindexing.md` (or a dedicated example guide) showing how to manually handle related-data updates using custom Oban jobs for child relations.
- **D-02:** Ensure the documentation is explicit that this is a temporary workaround until `related-data propagation` becomes a first-class feature.

### Regression Protection
- **D-03:** Add a bounded regression test or docs contract to ensure this workaround documentation is not accidentally removed before the first-class feature is built.

### Milestone Freeze
- **D-04:** Update `ROADMAP.md`, `STATE.md`, and `REQUIREMENTS.md` to officially freeze the milestone with the `related-data propagation` verdict.
- **D-05:** Conclude Phase 88 and the entire v1.23 milestone.

</decisions>
