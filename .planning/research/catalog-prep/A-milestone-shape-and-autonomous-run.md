# Catalog prep A: milestone shape, sequence and the autonomous run

Date 2026-11-21. Research only; nothing edited except this note. Tags: V = read or ran it, J = judgment, U = unverified. Sources read: AGENTS.md, MILESTONE-CONTEXT fold-in, FEEDBACK-SESSION, sigra and other replies, ADR 0001/0002, v1.49-prep A, ROLLING-ROADMAP post-v1.48, CI-EFFICIENCY, `~/.claude/gsd-core/workflows/autonomous.md`, `release-please-config.json`, `posture.ex`, `ops_dependency_boundary_test`.

## Recommendation in one paragraph

Ship the readiness work as **two small PRs before the milestone opens** (not a phase). Open v1.49 as **four phases, about 16 plans, spike first**: 195 Mount and prove, 196 Fixtures and first three adopters, 197 One-job pilot, 198 Scale (sized by feedback). Run GSD **one phase at a time (`--only N`)**, pause for the maintainer after 197 (first real storybook look, decides 198's size), and again at milestone end before audit. No Hex release; commits and PR titles use `chore`/`test`/`docs` types so release-please stays quiet.

## D1. Phase structure

**Recommended (confidence 0.6 on order, 0.75 on content): spike first, fixtures second, adopters staged by consumption.**

| Phase | Plans | Testable exit |
|---|---|---|
| 195 Mount and prove | 2 | `phoenix_storybook ~> 1.5` dev/test-only in `scrypath_ops`; dev-only loopback route (guard outside the `quote`); `storybook.css` imports production CSS; five primitives in light, dark, System; render-all ExUnit passes; **prod-absence proof** (fresh consumer built without the dep has no storybook module or route; extend `test/release/ops_dependency_boundary_test.exs`); ADR 0001 numbers recorded (cold and warm `ops-ui`, NIF fetch, `mix hex.audit` and `gh api` advisories on the new subtree, `handle_params` in `:example` on 1.5); `GO-NO-GO.md` with a machine-readable `decision:` field |
| 196 Fixtures and first three adopters | 4 | `fixtures/scrypath_fixtures` (ADR 0002); both `Phase173FixtureSource` copies and the `:phase173_fixture` branch in `PostureLive` deleted (a test greps for them); one scenario module, builders take `now`, static test bans wall-clock calls in the fixtures lib; invariant tests; **Shopadelic (routine drift), Logistify (backlog, nothing failed), Clinicly (failed work the operator may not read)**; every failure fixture carries a `source:` pointing at a real Meilisearch error code or Scrypath code path, and a test checks the codes against a closed list taken from the adapter |
| 197 Pilot, one job | 5 | Search-health job: focused stories on real renderers; routine, actionable-error, denied cases; **one mounted LiveViewTest journey** (same operator, index, run, timeline across screens) asserting denial leaves state unchanged, protected details are absent from the response, zero enqueues, and the permitted recovery changes the selected record; story audience and persona equal the journey actor (C36); cheap gates: every exported component and LiveView route has a story, no two variations render identically; one command and a preflight give a stable seeded storybook URL |
| 198 Scale (sized after the 197 review) | 5 | Default: remaining adopters (Chatly, Classwell, Finanza, Wikily) and the small or high-value screens (control room 263 lines, help 201, failed sync 1,253); search (2,055) and sync-drift (2,490) only if feedback asks; storybook becomes the review surface |

**Why spike first (J).** Its uncertainty is external (mdex_native on Apple silicon and cold CI, 1.5 `:example` limits) and decides whether the largest later spend happens at all; the first two plans cost about a day. Fixtures are valuable on either branch (a NO-GO falls back to ADR 0001's hand-rolled harness, which needs the same data), so order costs nothing on that side. **Why not fixtures first:** the spike answers what shape stories take (attrs versus source, whether `now` flows through `handle_params`), which fixtures should serve. **Why staged adopters:** sigra's rule is one job and three cases first; an adopter state no screen consumes is exactly the contrived-data defect the maintainer named (F4). Seven adopters all in 195 would also blow the 5-plan cap once each failure story is checked against real Meilisearch limits.

**Cut lines.** (a) 195 NO-GO: stop and ask (cost and risk change). (b) 197 review: the maintainer sizes or cuts 198. (c) Budget: 16 planned, **stop and re-ask at 22** (v1.44 ran 17 and v1.46 16 against estimates near 11, V per v1.49-prep A; siblings' 76 to 138 came from manifests, baselines and evidence closure, which are refused). Early-warning plan names: "manifest", "matrix", "evidence closure", "baseline".

**Alternatives rejected.** Merge 195+196: different failure modes, one PR would hide a spike NO-GO inside fixture churn. Split 197 into read-only and journey halves: sigra and accrue both say the handoff between screens is where defects hide, so the journey belongs with the first stories. All seven adopters up front: see above.

**Adversarial.** Spike-first is wrong if five bare primitives teach nothing and force fixture rework; cheapest test is to keep plan 195-1's stories on inline attrs only, so nothing is built that fixtures must undo. The pause after 197 is wrong if the maintainer is away (cost: calendar time only; a one-word reply continues).

## D2. Readiness PR: separate, before, split in two

**Recommended (0.75).** Two PRs under the v1.47 "housekeeping, no milestone" precedent (ROLLING-ROADMAP), squash-merged on green:

1. `docs`/`test` PR: false line `guides/per-query-tuning-pipeline.md:64` (V: `lib/scrypath/options.ex` has no highlight or crop key) plus an allowlist-wording pin; `scrypath_ops/lib/scrypath_ops/posture.ex:416` resolves `guides/operator-mix-tasks.md` under `scrypath_ops/`, where no `guides/` exists (V), so `maybe_append_mix_status` silently never fires: fix with a test; read-only `mix verify.release_parity` for #52; the cadence rule in `docs/releasing.md`.
2. `ci` PR: split `deep-quality` (CI-EFFICIENCY finding 1, `.planning/reference/CI-EFFICIENCY.md:70`). **This one is load-bearing for the catalog:** v1.49-prep A says the new subtree's `mix hex.audit` "is recorded by hand because deep-quality is already red", so a split before 195 lets the spike's audit and dialyzer results show up on their own. Validate with `act -l -W .github/workflows/ci.yml` and keep the required contexts unchanged. If the split proves costly, 195-2 records the audit by hand and the PR is dropped.

Rejected: a phase 0 (GSD discuss, plan, verify and STATE writes cost more than a one-PR job, and it puts non-catalog items in the catalog's audit); deferral (the false guide line ships on HexDocs; the posture bug sits beside fixtures work). **First action regardless:** merge the open docs branch (`docs/storybook-replies-2026-11-21`, one commit ahead of `main`, U on whether a PR exists) so MILESTONE-CONTEXT is on `main` before `/gsd-new-milestone` consumes it.

## D3. Running GSD autonomous

Facts (V, `autonomous.md`): `--only N` and `--to N` skip the lifecycle (lines 578, 632-640); with all phases done, lifecycle runs audit, complete, cleanup with no review pause, except prompts on audit gaps or tech debt (690-711) and cleanup approval (742); `human_needed` prompts the user (456-474); a failed step goes to `handle_blocker` (760). The skill never opens or merges PRs (memory, v1.48 run), and phase N+1 needs phase N merged, so **run `--only 195`, ship, `--only 196`, and so on**, as in v1.48. That also makes the review pauses natural, and the lifecycle never fires before the review.

**Pre-authorized (no asking):** discuss fan-out and following its synthesis; plan, plan-check, execute, verify, code review; PRs and squash-merge on green required checks at the exact head; adding the storybook dependency per ADR 0001 and the fixtures project per ADR 0002; continuing from 195 to 196 **unless** an ADR 0001 trigger trips (advisory open over 14 days, cold `ops-ui` over 3 minutes slower, isolation work over a day); advisory-only CI jobs; audit with `tech_debt` status accepted if no requirement is unsatisfied.

**Must pause:** (1) after 197 (review plus scope of 198); (2) milestone end, before audit; (3) spike NO-GO or any tripped trigger; (4) a new required CI context or branch-protection change; (5) any Hex release or release PR; (6) copying anything from the six brand repos or the reuse grant; (7) a new runtime dependency beyond the storybook subtree; (8) any change under root `lib/` public API (out of scope for this milestone); (9) 22 plans; (10) `human_needed`: treat as a plan defect (zero-UAT rule), convert to an executable check, do not prompt.

**State and config hygiene (V from memory and `git status`).** `.planning/config.json`, `.planning/state.json`, `.impeccable/config.json` are dirty and must never be staged: commit with explicit paths, never `git add -A` or `.`, and run `git diff --cached --name-only` before every commit. Set `workflow.use_worktrees=false` for the run, restore after (the isolation guard blocks sequential executors otherwise). After `state.begin-phase`, `phase.complete`, `state.planned-phase`, run `git diff .planning/STATE.md` and restore `milestone_name`, `status`, focus lines. Cheap check, not a CI gate: before each commit, grep STATE.md frontmatter for the milestone name. Delete a stale `gsd/phase-*` pointer before renaming; refresh main with `git switch -C main origin/main`, never `reset --hard`. Re-read `.planning/REQUIREMENTS.md` after `new-milestone` (memory: it drifts stale).

**Pre-push confidence.** Per AGENTS, run each required lane's local command; the Docker lanes cost about 2h20 locally versus about 14 minutes hosted (CI-EFFICIENCY finding 22, via memory), so for phases touching only `scrypath_ops` and `fixtures` run `ops-ui`'s command, `mix verify.package`, `scripts/ci/pre_push.sh` and the boundary test, and record the skipped Docker lanes as a known risk. Phase 196 rewires e2e specs, so it is the one phase where an `ecommerce-mounted` local run may earn its cost.

## D4. Milestone-end review mechanics

**Before any screen story exists** (only if 197 is cut): AGENTS.md:175 path: read `.planning/UI-PREVIEW.json`, `npm run ui:preflight`, refresh the preview to `main`, say that no shipped UI changed, give the URL, wait.

**After 197 (expected):** the storybook is the surface. Mechanics, all produced in 197-5 and kept tiny: one documented command starts a seeded, fixed-clock server on one loopback port; extend `ui:preflight` with a `storybook` block in `UI-PREVIEW.json` (checkout, branch contains `main`, port answers, story count equals the render-all count) rather than a new tool (copy over dependency). The pause message states: what changed (a new dev-only catalog; shipped ops UI unchanged unless a story forced a fix), URL, three stories to open (routine, error, denied), and the journey test name. The review note is one dated file under `.planning/research/` with exact quotes and rows mapped to story id, state, viewport, theme; unknown viewport stays unknown. Two reviews (after 197 and at the end) match sigra's "put one realistic decision in front of the owner before expanding"; the second is cheap.

## D5. Release stance and cadence

No Hex release (0.8): `scrypath_ops` and `fixtures` are outside the `files:` allowlist (`mix verify.package` asserts it, V per ADR 0002), and ScrypathOps is not a package. **Footgun (V):** `release-please-config.json` has one root package, no `exclude-paths`, so a `feat:` or `fix:` PR title touching `scrypath_ops/` opens a release PR (compare `feat(ops-ui)` #138). Use `chore(ops-ui)`, `test(ops-ui)`, `docs` titles (squash-only, the PR title is the commit); after each merge check no release PR appeared. Optional, needs a yes: `exclude-paths` for `scrypath_ops` and `fixtures` (U on the action's release-please version). Adopt the 14-day cadence as a guideline in `docs/releasing.md` (0.7): release on behavior change, runtime-dependency advisory, adopter-facing doc defect or announcement; at most one per 14 days except bug or security fixes; last release 0.3.20 on 2026-11-21, so nothing before 2026-12-05 and the roadmap time-box stays 2026-12-21. It is agent guidance; the maintainer's yes still gates every release.

## D6. Definition of done and top risks

**Done = all executable:** (1) `mix test` in `scrypath_ops` includes render-all, coverage (every exported component and LiveView route has a story), no-identical-variations, journey-with-denial; (2) fixtures invariants and the no-wall-clock static test pass; both old fixture copies gone; (3) prod-absence and `mix verify.package` green; (4) `GO-NO-GO.md` and ADR 0001 numbers recorded; (5) required-gate budget stays at 10 of 12 (render-all rides `ops-ui`, no new required context); (6) no release PR opened; (7) the review note exists and its actionable rows are folded into v1.50 input; (8) every adopter labeled fictional and nothing copied from the brand repos.

**Cross-area flag.** MILESTONE-CONTEXT proposes a separate path-filtered advisory catalog CI job. Because the dependency is `only: [:dev, :test]`, `ops-ui` compiles it in test anyway; a second job would rebuild the same subtree and cache. I recommend render-all inside `ops-ui` and no separate job unless the spike shows a measured reason (J, 0.65).

**Top risks.**
1. A catalog nobody can use to review one decision (sigra). Early sign: an inventory or grid grows before the maintainer has a stable link. Check: the 197 pause.
2. Contrived data. Early sign: a failure string with no `source:` that traces to a real Meilisearch code or Scrypath path. Check: closed-list test.
3. Spike surprise, cost, cache. Early sign: mdex_native build failure, boundary test timeouts (fresh consumer per case, NIF fetch on a cold cache), Actions cache at 10.77 GB over its cap (V, CI-EFFICIENCY). Check: GO-NO-GO numbers.
4. Plan sprawl. Early sign: more than 5 plans in a phase, plan-check hitting its 3-round cap twice, plans named evidence, manifest or matrix. Check: 22-plan stop.
5. Playground exposure (its critical RCE was fixed in 1.1.0, V). Early sign: a route present outside dev, or a non-loopback bind. Check: prod-absence test plus a test that the route is absent in `:test` router config, and `check_origin` is not loosened for serving.

**What would change this.** A spike NO-GO (switch to the hand-rolled harness, ask first); an outside adopter report (reorder to it); the maintainer wanting fewer pauses (drop the 197 pause, keep milestone end); a measured deep-quality split cost above its value (drop PR 2).

## Questions only the maintainer can answer

None block the start. Worth one line each: adopt the cadence text (default yes); whether to add `exclude-paths` to release-please (default no, title discipline instead); whether the 197 pause may be a one-word reply (default yes).
