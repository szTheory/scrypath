---
slug: scrypath-post-v1-26-gameplan-2026-05-27
title: Scrypath post-v1.26 gameplan and operating model
status: resolved
created: 2026-05-27
updated: 2026-05-27
---

# Scrypath post-v1.26 gameplan (repo-grounded)

## 1) Framing

Scrypath is now a near-done Ecto-native search indexing/orchestration library for its stated Meilisearch-first scope, with strong core flows already shipped and verified. In this context, "done" means:

- a Phoenix/Ecto team can ship first-search quickly;
- write-path semantics stay honest across `:inline`, `:manual`, and `:oban`;
- related-data propagation, tenant-safe access, facets, and multi-index search are real;
- operator recovery is practical and explicit;
- the release/support truth stays tighter than roadmap ambition.

Confidence caveat: planning truth has one known drift (`v1.20` `Scrypath.SearchModule` archive claim vs branch-tip code). Conclusions below prioritize checked-out `lib/`, tests, and published guides over archive wording.

## 2) Current state

**One-line job:** keep a search-shaped read model in sync with Ecto truth without hiding consistency, rebuild, or recovery realities.

**Done estimate:** **93-95%** (near-done band; diminishing returns already active).

What is clearly real now:

- common runtime search/sync/operator surfaces (`Scrypath.search/3`, `search_many/2`, `search_within_facet/4`, `sync_related/3`, `sync_status/2`, `reconcile_sync/2`);
- tenant-safe shared-index search (`tenant_field:`, `tenant_scope:`, multitenancy guide);
- high-cardinality facet vocabulary search (`search_facet_values/4`, `FacetSearchResult`);
- request-edge and composition layers (`Scrypath.QueryParams`, optional `Scrypath.Phoenix`, `Scrypath.Composition`);
- release-train posture and docs contract discipline.

## 3) Adopter coverage map

### Well-served

- First schema to working search in Phoenix contexts.
- Explicit sync-mode semantics and operational honesty.
- Faceted and federated search behavior.
- Related-data fan-out propagation (`sync_related/3`, worker path, guide + smokes).
- Operator diagnostics and report-first recovery flow.

### Partially served

- Outside-adopter evidence loop exists, but reviewed external usage remains thinner than in-repo proof.
- Browser-direct multitenancy/token ergonomics are documented at guidance level, not first-class runtime helper API.

### Still rough

- Planning-truth confidence around historical `v1.20` SearchModule claim (archive/code mismatch).

## 4) Next-work recommendation

### Ranked wedges (3-5)

1. **Operational stewardship lane (maintenance milestone, not feature breadth)**
   - Why: highest leverage now is keeping a release-ready, trustable library posture while adoption signal accumulates.
   - Done enough: defined maintenance cadence, release-train checklist, explicit PR/CI merge rules, and support-truth checkpoints are codified in planning truth.

2. **Outside-adopter evidence loop**
   - Why: the main remaining uncertainty is external integration behavior, not missing in-repo capability.
   - Done enough: consistent Class A/B intake cadence, triage rubric, and patch/doc follow-through SLAs tied to `guides/outside-adopter-intake.md`.

3. **SearchModule archive/code reconciliation**
   - Why: this is the single largest planning-truth debt and can mis-rank future work.
   - Done enough: archive, rolling docs, and code truth align on whether SearchModule is recovered or explicitly deferred/removed from claims.

4. **Evidence-gated suggestions/autocomplete wedge**
   - Why: plausible UX pull, but below current evidence threshold.
   - Done enough: narrow scope over existing backend/search seams only (no UI framework coupling), opened only by adopter evidence.

5. **Optional tenant-token helper wedge (browser-direct only, evidence-gated)**
   - Why: useful for SaaS teams doing browser-direct search, but not mandatory for current server-side defended path.
   - Done enough: small helper + canonical docs + explicit non-goals; no auth framework or implicit tenant extraction.

### Single highest-leverage pick now

**Pick:** **Operational stewardship lane** (maintenance + evidence + truth reconciliation), not a new feature milestone.

### Suggested ordering

1. Operational stewardship lane (codify and run).
2. Outside-adopter evidence loop (ongoing).
3. SearchModule truth reconciliation.
4. Feature wedge only if evidence demands it (suggestions first, then tenant-token helper if needed).

## 5) Diminishing-returns judgment

**Verdict:** finish the last important maintenance wedges and mostly stop major feature expansion unless real adopter evidence or a concrete bug reopens scope.

High leverage:

- release/train hygiene,
- external evidence intake and response,
- planning-truth integrity.

Likely overbuild right now:

- broad new ergonomics arcs,
- deeper OPSUI breadth,
- multi-backend/vector/hybrid expansion,
- speculative feature milestones without reviewed adopter signal.

## 6) Blunt maintainer takeaway

If I were maintaining Scrypath now, I would **not** open a new feature milestone by default. I would run a disciplined maintenance lane, keep `main` green, enforce PR-first/green-PR-CI for any serious work, and only reopen product breadth when outside adopters produce concrete evidence.

## 7) Bookkeeping written in this pass

Planned bookkeeping updates attached to this gameplan:

- update rolling planning truth for the two-lane workflow in:
  - `.planning/PROJECT.md`
  - `.planning/STATE.md`
  - `.planning/milestone-candidates.md`
- reconcile stale arc language in `.planning/MILESTONE-ARC.md` to no-active-milestone maintenance mode.
- keep SearchModule drift explicitly tracked via `.planning/todos/search-module-archive-code-drift.md` and rolling references.
- no active phase exists, so new lessons are recorded in rolling planning/thread documents now and should graduate into `NN-LEARNINGS.md` only when a new phase opens.

## 8) Shift-left applied

Inspection results:

- `.planning/config.json` already has key low-risk defaults aligned with this workflow (`research: true`, `parallelization: true`, `verifier: true`, `nyquist_validation: true`, `research_before_questions: true`, `discuss_mode: "discuss"`).
- `~/.gsd/defaults.json` is intentionally minimal and does not conflict.

Action:

- **No config changes applied** in this pass (explicit no-op) because current project defaults already encode the requested low-risk posture.
- Any future high-impact config changes (model profile shifts, disabling research/plan-check/verifier/nyquist gates) require explicit maintainer approval before modification.
