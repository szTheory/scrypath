# Milestone Arc

## Active arc: Outside-Adopter Validation And Trust Closure

**Status:** active - `v1.23` opened on 2026-05-24 after `v1.22` shipped on 2026-05-24  
**Started:** 2026-05-24

## Why this arc exists

Scrypath already proved a credible Meilisearch-first, Ecto-native indexing and sync story, and the request-edge plus composition work pushed the library close to diminishing returns on internal breadth.

The next leverage move is not another surface-area milestone by default. It is to reconcile support truth with the checked-out tree, collect real outside-adopter evidence on the defended Phoenix + Meilisearch path, and let that evidence determine whether the library should stop soon or open one final high-leverage wedge.

## Arc goals

- Reconcile public support/readiness/proof claims with the actual checked-out repo.
- Force milestone selection to depend on reviewed outside-adopter evidence rather than internal momentum.
- Close only evidence-backed docs/support/proof papercuts in this arc.
- End the arc with a clear next-pull verdict: stop soon, related-data propagation, or tenant-safe access.

## Arc non-goals

- No new generic ergonomics breadth in core search/runtime APIs by default.
- No public multi-backend expansion, vectors, hybrid retrieval, or delight-first search UX.
- No deeper OPSUI productization unless outside-adopter evidence shows the current proof posture is missing real failures.
- No hiding the `v1.20` archive/code drift or the removed support-guide references behind vague milestone language.

## Prior completed arc: Batteries-Included Search Modules

**Status:** completed in-repo with `v1.22` on 2026-05-24  
**Started:** 2026-05-07

### v1.20 — Search Module Foundation

- **Status:** shipped on 2026-05-08
- Archive claims a context-owned `Scrypath.SearchModule`
- The current tree does **not** expose that module, so this remains a reconciliation concern rather than trusted current product truth

### v1.21 — Query Toolkit And Phoenix Edge Helpers

- **Status:** shipped on 2026-05-23
- Public normalization/casting helpers for request-edge search
- Optional Phoenix URL/form/LiveView round-tripping
- No Phoenix coupling in the core runtime

### v1.22 — Composition And Real-App Depth

- **Status:** shipped on 2026-05-24
- Reusable presets/scopes where they help real app flows
- Composition support aligned with `search_many/2`
- Stronger UI metadata exposure for declared filters, sorts, facets, and paging
- Real-app proof that the new layer reduces repeated app glue without turning Scrypath into a framework facade

## Active milestone sequence

### v1.23 — Outside-Adopter Evidence And Support-Truth Reconciliation

- **Status:** active on 2026-05-24
- Reconcile current support/readiness/proof surfaces with actual repo truth
- Review real outside-adopter attempts against the defended Phoenix + Meilisearch path
- Close only evidence-backed papercuts
- Decide whether Scrypath should stop soon or open one final high-leverage product wedge

## Next candidate posture

- Default next pull after `v1.23` is **not** more generic breadth work.
- If outside-adopter evidence is mostly green, bias toward stopping soon.
- If feature work reopens, the ranking is: related-data propagation first, tenant-safe access second, high-cardinality facet-value search third.

## Planning posture for future milestone opens

- Ground the next decision in repo truth plus reviewed adopter evidence, not archive momentum.
- Treat current support-truth drift as a credibility issue, not as a reason to invent new features.
- Ask for product reshaping input only when outside evidence and repo-local proof no longer point clearly enough.
