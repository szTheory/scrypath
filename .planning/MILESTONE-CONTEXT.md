# Next milestone context: v1.49 Catalog foundation (Adopter-ready follows as v1.50; the sections below the fold-in are the Adopter-ready plan)

**Captured:** 2026-11-21
**Status:** Prepared upstream under the standing milestone-preparation rule and adopted by the maintainer on 2026-11-21 ("follow your recs"). Input for `/gsd-new-milestone v1.49`; it does not activate a milestone or approve a phase. The workflow consumes and deletes this file. **The UI feedback session ran on 2026-11-21 and its first finding changed the lead: see "Fold-in from the 2026-11-21 feedback session" directly below, which supersedes the recommended scope further down where they conflict. More screen feedback may still be appended to the feedback note.**

## Fold-in from the 2026-11-21 feedback session (supersedes the scope below where they conflict)

Full record and triage: [research/storybook-catalog/FEEDBACK-SESSION-2026-11-21.md](research/storybook-catalog/FEEDBACK-SESSION-2026-11-21.md). Evidence: [SIBLING-SCAN-2026-11-21.md](research/storybook-catalog/SIBLING-SCAN-2026-11-21.md), playbook rules C31 to C34.

**What changed.** The maintainer wants the storybook now ("a huge miss" that prep note A deferred it; it overrode their 2026-10-25 decision, ADR 0001 and the UI engine D1). The catalog becomes the lead of the next milestone. AGENTS.md now has a "Recorded owner decisions" rule so a prep note cannot do that again.

**Recommended shape (sequence is the one open scope choice; recommendation, not a decision).**

0. **Readiness PR first, not a milestone** (unchanged from the Adopter-ready plan below, Phase 195 items): the false `per_query` line, the `posture.ex` guide path, the `deep-quality` split, the release-cadence proposal. Independent of the catalog and one small PR.
1. **v1.49 "Catalog foundation" (lead).** Phases keep the existing numbering from 195 (renumber the Adopter-ready phases to v1.50). Cap 5 plans per phase (playbook C33); the catalog CI job is path-filtered and advisory until the spike numbers justify a gate.
   - **Phase 195 Fixtures and adopters:** build `fixtures/scrypath_fixtures` per ADR 0002 (replaces the two drifting `Phase173FixtureSource` copies and the `:phase173_fixture` branches in `PostureLive`); one deterministic scenario module with a fixed clock; adopter profiles from the fablebook twins (C31) after the license answer: Shoply (from Shopadelic), Chatly, Budgetly (from Finanza), Langalern (Classwell plus Chatly CJK), Wikily, plus Logistify and Clinicly; hostile text as escaped code points; invariant tests (closed enums, legal transitions, null not empty string, ordered timestamps); a deterministic bulk generator for huge counts.
   - **Phase 196 Catalog spike and go/no-go:** `{:phoenix_storybook, "~> 1.5", only: [:dev, :test]}` in `scrypath_ops`, dev-only loopback route behind a macro that guards outside the `quote` (C28), `storybook.css` that cannot go stale (C8/accrue recompose `--check`), five primitives in light, dark and System, a render-all ExUnit test, the ADR 0001 numbers. **Pre-authorized to continue** unless an ADR 0001 trigger trips (advisory open over 14 days, cold `ops-ui` more than 3 minutes slower, isolation work over a day); the maintainer wants it, so a clean spike does not wait for another yes. Verify on 1.5 whether `:example` stories can use `handle_params` (threadline found they cannot on 1.2.0).
   - **Phase 197 Pilot, all five tiers on one screen:** Search health first (it has a view-model and a fixture seam; UI engine D2), tier ladder Primitive / Pattern / Area / Screen / Flow, state classes per C34, every state carrying persona plus `JOB-*`, tests that every exported component and every LiveView route has a story and no two variations render identically. Flows are backed by LiveViewTest, not stories (C7, C23).
   - **Phase 198 Catalog at scale:** remaining screens in D2's order (control room, search, failed sync, sync and index, help), then the retained preview is replaced by the storybook as the review surface (AGENTS.md "Milestone-end review"). Cut line after 197 if the pilot disappoints.
2. **v1.50 Adopter-ready** (the plan below, Phases 196/197/198 renumbered) unless the maintainer wants it earlier or an outside report arrives.

**Design bar and process carried in** (from the owner intent and C32): ordinary-data-first default states, stress states separate and named; light and dark both look good; two gated widths (375 and 1280; more only ad hoc); a stable seeded server on one port for review with each feedback row mapped to an entry id; no parallel gallery, no hash-bound receipts, no LLM critic as a gate; copy and microcopy use the glossary; no compliance claims in healthcare or finance adopters.

**Inputs still arriving.** The maintainer is pasting the prompts in `research/storybook-catalog/PASTE-PROMPTS.md` into the accrue, threadline, mailglass and exifcleaner sessions and the brandbook session. Replies go to `research/storybook-catalog/replies/`; fold anything that changes the shape above into this section before `/gsd-new-milestone`. Screen-level feedback on the v1.46 and v1.47 UI is still to come and is triaged in the feedback note.

**Open for the maintainer.** (1) fablebook records license: copy a trimmed subset with provenance, never logos? (2) Confirm the sequence: catalog as v1.49 and Adopter-ready as v1.50.

---

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
