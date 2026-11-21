# Next milestone context: v1.49 Adopter-ready

**Captured:** 2026-11-21
**Status:** Prepared upstream under the standing milestone-preparation rule and adopted by the maintainer on 2026-11-21 ("follow your recs"). Input for `/gsd-new-milestone v1.49`; it does not activate a milestone or approve a phase. The workflow consumes and deletes this file. **A UI feedback session on the previous milestone runs first; fold its actionable findings into this file (scope, new phases, or a pre-phase) before `/gsd-new-milestone`.**

## Read first

- `reference/ROLLING-ROADMAP.md`, section "Post-v1.48 proposal (2026-11-21)": the recommendation, step table, corrections, release stance and what would change it.
- `research/v1.49-prep/` notes A (catalog readiness refresh), B (adopter-features evidence), C (sequencing and release). Each has facts marked verified or unverified, lenses and an adversarial pass.
- `milestones/v1.48-MILESTONE-AUDIT.md` (debt carried in), `research/v1.48-prep/CHECKPOINT.md` (why discovery work stopped), `reference/CI-EFFICIENCY.md`, `guides/scope-and-reopen-policy.md` and `AGENTS.md` (house rules and standing instructions, including the milestone-end review).

## Goal

Make Scrypath ready for a first real adopter without guessing at features: close the known truth and CI debt, document what adopters can already do (testing without Meilisearch), find what actually hurts by walking the Hex package as a consumer, and only then consider the smallest new surface. This is a **deliberate strategic product decision** under the third reopen trigger in the scope policy; nothing here is outside-adopter evidence, and no document may say it is.

## Recommended scope (accept or adjust; cuttable after the second phase)

Phase numbering continues from 194 (cut): the first phase is **195**.

0. **Phase 195 Readiness pass (about 1 plan, one PR):** fix the false line in `guides/per-query-tuning-pipeline.md:64` ("highlight / crop already modeled"; the `per_query` allowlist in `lib/scrypath/options.ex` has only the three ranking-score keys) with a test that pins the allowlist wording; fix `scrypath_ops/lib/scrypath_ops/posture.ex` (`operator_mix_guide_path/0` resolves a guide path that does not exist under `scrypath_ops/`) with a test; split the `deep-quality` lane so its one known red (sigra to cloak_ecto) stops hiding other findings (CI-EFFICIENCY finding 1; measure first, keep the required context reporting); read-only `mix verify.release_parity 0.3.10` for issue #52 and close it if clean; write the proposed release cadence rule into `docs/releasing.md` (release only on a behavior change, a runtime-dependency advisory, an adopter-facing doc defect or an announcement; never docs-only alone; at most one release per 14 days except bug and security fixes) as a recommendation for the maintainer to adopt, not as policy.
1. **Phase 196 Testing your app (about 2 plans):** a guide with no new public API: `req_options` with `Req.Test` (public, validated), Oban `assert_enqueued`, the inline-sync path in about 25 lines, a hostile-input note where relevant; then a **fresh-consumer walk**: an agent builds a small Phoenix app from Hex 0.3.20 using only the published HexDocs, records every point of friction, and the findings are labelled maintainer-side friction evidence. Check every sibling-library API name against source before it reaches a public guide. If the guide's snippet cannot cover inline sync in about 25 lines, stop and record that a public `Scrypath.Testing` module needs an ADR; do not add it.
2. **Cut line.** If the walk finds nothing painful, stop after Phase 196 and close the milestone; the maintainer decides the next step (catalog or idle).
3. **Phase 197 (optional, only if the walk or the maintainer asks, after one API-grilling session with the maintainer):** highlight and crop as new `per_query` allowlist keys (verify whether `_formatted` output is HTML-escaped; ship an escape-then-wrap recipe and a hostile-title test), and/or `pagination.max_total_hits` plus a paging guard. The first release with a new public API ships as **0.4.0** (`release-please-config.json` has `bump-patch-for-minor-pre-major: true`, so features would otherwise ship as patches); the install-line shape (`~> 0.3` versus `~> 0.4`) is decided when this phase opens.

Deferred as costly or one-way: a public `Scrypath.Testing` module, the indexable predicate, new backfill and reindex Mix tasks. The catalog is deferred with reopen triggers recorded in the rolling roadmap (ScrypathOps published as a package; two or more ops UI regressions in a quarter that existing checks missed; a cheap spike result plus the maintainer wanting the UI engine first; an outside request for a component reference).

## Constraints and defaults

- No Hex release in this milestone without the maintainer's explicit yes; nothing releasable exists yet, and the revisit time-box is 2026-12-21 (a docs-only release is justified only with an announcement).
- Gate budget: 10 of 12 required gates used; each new gate needs a deletion trigger and expected churn. Prefer untagged contract tests under the existing `core` lane.
- No human UAT: every success criterion is an executable check or a recorded decision. Nothing claims that a guide reads well or that anyone independent reviewed it.
- Squash-merge green PRs without asking (standing instruction); evaluate every CI run for speed and cost wins; run each required lane's local mirror before pushing (`scripts/ci/pre_push.sh`, `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.package`, `mix verify.repository_contracts` with its Git access).
- **Milestone-end review:** after the last phase and before audit, complete and cleanup, stop for the maintainer's UI feedback per `AGENTS.md` "Milestone-end review".
- Local toolchain: `export ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.5`. Never stage `.planning/config.json`, `.planning/state.json` or `.impeccable/config.json`. The executor isolation guard needs `workflow.use_worktrees=false` for sequential runs on the main tree (set it for the run, restore after); `state.begin-phase` and `phase.complete` rewrite STATE.md focus lines, so fix them before committing.

## Open items that still need the maintainer

- The UI feedback session on the previous milestone (before this milestone opens).
- One API-grilling session before Phase 197 (the only item blocked on the maintainer).
- Adopting or changing the proposed release cadence rule; whether to push the local `v1.48` tag.
