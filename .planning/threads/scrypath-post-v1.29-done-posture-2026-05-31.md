# Scrypath post-v1.29 done posture — 2026-05-31

## Purpose

Durable posture note for future agents and future milestone starts.

Use this when a new context asks "are we done?", "what next?", or "does this go on forever?"

## Current answer

Scrypath is effectively done for its stated v1 library mission: Meilisearch-first, Ecto-native indexing and search orchestration with Phoenix-friendly ergonomics, honest sync semantics, operator recovery, adoption proof, and bounded real-app evidence.

The project is not frozen. It is past the point where generic internal polish should create new milestones by default.

## Default posture

- Cut and verify releases when appropriate.
- Keep required gates green.
- Keep install, support, proof, README, HexDocs, website, and planning truth aligned.
- Gather outside-adopter evidence.
- Fix concrete bugs and evidence-backed papercuts as patch-sized work.
- Stay silent when there is no real pull.

## Feature reopening rule

Open a new feature milestone only when at least one of these is true:

- A concrete production bug shows the current contract is wrong or incomplete.
- Reviewed outside-adopter evidence shows a missing expected capability.
- The maintainer explicitly chooses a strategic wedge and accepts that it is new product scope.

Otherwise, do not manufacture a roadmap.

## Likely diminishing-returns work

- Autocomplete or suggestions without adopter evidence.
- More Phoenix helper sugar beyond the current context-edge and query-toolkit surfaces.
- Broader OPSUI productization.
- Multi-backend, vector, hybrid, analytics, or personalization breadth.
- Super-polish that does not change an adopter outcome.

These may be good later, but they are not default next work.

## Practical next moves

The near-term useful work is release/maintenance shaped:

- Run the release train when the package is ready.
- Verify post-publish parity.
- Keep advisory real-services proof honest without promoting it by default.
- Review real adopter friction and route it into patch-sized fixes.

If none of those have work attached, the correct answer is that the release train is idle.
