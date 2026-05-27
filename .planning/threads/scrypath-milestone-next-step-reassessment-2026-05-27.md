---
slug: scrypath-milestone-next-step-reassessment-2026-05-27
title: Scrypath milestone next-step reassessment (post-v1.26)
status: resolved
created: 2026-05-27
updated: 2026-05-27
---

# Scrypath milestone next-step reassessment (repo-grounded)

## 1) Framing

Scrypath is a Meilisearch-first, Ecto-native search indexing and orchestration library for Phoenix/Ecto teams. In this repo, "done enough" means the core adopter jobs are real and defended: first searchable schema, honest sync semantics, practical recovery, and clear docs/support truth.

Confidence is medium-high, with one recurring caveat: planning archive wording has drifted before (v1.20 SearchModule history), so decisions here prioritize current branch-tip code/tests and current guides over archived milestone claims.

## 2) Current state

**One-line job:** keep a search-shaped read model in sync with Ecto truth without hiding eventual consistency, rebuild, or recovery realities.

**Done estimate:** **93-95%** (**near-done / diminishing returns soon**).

What is clearly real today:

- Runtime search/sync flow across `:inline`, `:manual`, and `:oban`, including related-data fan-out and explicit accepted-vs-visible semantics.
- Tenant-safe shared-index access (`tenant_field:`, `tenant_scope:` and canonical multitenancy guidance).
- Catalog/facet depth including high-cardinality facet vocabulary search.
- Request-edge + composition surfaces that keep contexts as the execution boundary.
- Operator and maintainer proof surfaces (`mix verify.adopter`, example smoke paths, support/readiness contract tests).

## 3) Adopter coverage map

### Well-served flows

- First schema to real search in a Phoenix/Ecto app.
- Sync-mode choice with honest semantics and observable recovery workflow.
- Multi-index and faceted search for catalog and admin product surfaces.
- Related-data propagation correctness for common fan-out patterns.
- Tenant-safe shared-index usage in the documented server-side path.

### Partially served flows

- Outside-adopter confidence: intake path exists and is strong, but reviewed external usage is still thinner than in-repo proof.
- Browser-direct multi-tenant ergonomics: guidance exists, but helper-level ergonomics remain intentionally minimal.

### Still rough

- Contract coherence in docs around install/version language (for example, `~> 0.3` in core docs versus `~> 1.0` in outside-adopter intake).
- Historical planning drift risk if archive truth is treated as current shipped surface.

## 4) Next-work recommendation

### Top wedges (ranked)

1. **Adopter Contract Hardening (maintenance wedge, not feature breadth)**  
   Why: fastest way to improve trust and reduce adoption friction now is to harden support/install/proof coherence, not add runtime surface.  
   Done enough:
   - one canonical install/version contract across README, guides, and intake docs;
   - one clear "Hex-only vs repo-clone defended path" explanation;
   - docs-contract checks lock these seams against drift.

2. **Outside-adopter evidence loop (continuing maintenance wedge)**  
   Why: the largest remaining uncertainty is external integration behavior, not core capability gaps.  
   Done enough:
   - reviewed Class A/B cadence;
   - bounded SLA from evidence to bug/docs patch;
   - evidence outcomes reflected in planning truth.

3. **Planning-truth integrity sweep (lightweight hygiene wedge)**  
   Why: keeps milestone ranking grounded in branch-tip reality and avoids false certainty.  
   Done enough:
   - rolling docs and archive labels remain explicit where historical and current surfaces differ;
   - no reopened wedge based on archive-only claims.

4. **Autocomplete/suggestions (feature wedge, evidence-gated only)**  
   Why: plausible user-facing value, but below threshold without confirmed adopter pull.  
   Done enough:
   - bounded API over current runtime seam;
   - no Phoenix UI coupling, no framework facade expansion.

5. **Tenant-token helper (feature wedge, evidence-gated only)**  
   Why: potentially useful for browser-direct adoption, but currently host-app concern and lower leverage than contract hardening/evidence intake.  
   Done enough:
   - small helper plus docs for safe usage;
   - no auth framework lock-in.

### Single highest-leverage pick now

**Pick:** **Adopter Contract Hardening** as the next milestone wedge (PR-scoped when opened), while keeping maintenance lane as default.

### Suggested ordering

1. Adopter Contract Hardening
2. Outside-adopter evidence loop (continuous)
3. Planning-truth integrity sweep (continuous)
4. Autocomplete/suggestions (only with evidence trigger)
5. Tenant-token helper (only with evidence trigger)

## 5) Diminishing-returns judgment

Scrypath is in the **finish-last-important-wedges / mostly stop broad expansion** zone for its stated scope.

Still high-leverage:

- support/install/proof contract coherence,
- outside-adopter signal collection and response,
- release-train and planning-truth discipline.

Likely diminishing returns right now:

- generic runtime ergonomics expansion,
- broader OPSUI productization,
- multi-backend/vector/hybrid expansions,
- speculative feature milestones without reviewed outside-adopter trigger.

## 6) Blunt maintainer takeaway

If this were my library, I would not open a broad feature milestone now. I would run maintenance-by-default, open one bounded PR milestone for Adopter Contract Hardening, and only reopen deeper feature work when reviewed outside-adopter evidence or a concrete production bug demands it.

## 7) Bookkeeping written in this reassessment

- Recorded the updated next-pull wedge and done-band judgment in `STATE.md`.
- Refreshed milestone candidate ordering where materially changed (new top bounded wedge: Adopter Contract Hardening).
- Updated `PROJECT.md` Next Milestone Goals with the current bounded reopen preference.
- Kept learnings in rolling thread/state docs because there is no active phase and therefore no `NN-LEARNINGS.md` target.

## 8) Shift-left applied

- Re-checked `.planning/config.json` and `~/.gsd/defaults.json`.
- Applied **no config changes**: low-risk defaults already match the requested posture (`research`, parallel exploration, verifier/nyquist gates, discuss-first flow).
- High-impact gates/profile settings remain unchanged and still require explicit approval before any modification.
