# Rolling roadmap (post-v1.48 proposal 2026-11-21, adopted 2026-11-21; post-v1.47 proposal 2026-11-21, adopted and v1.48 Discovery and onboarding shipped; approved 2026-10-24; re-plan adopted 2026-11-18; post-v1.46 proposal 2026-11-19 below; v1.47 opened 2026-11-20 with a gap pass, see research/v1.47-gap-pass/)

The maintainer approved this order and these working rules after a research fan-out and a grilling round. Pick up the first unfinished item. `STATE.md` records progress.

## v1.50 proposal (2026-11-25, prepared upstream; ADOPTED 2026-11-25: "yes to all follow ur recs"; v1.50 is open)

**Order now adopted:** v1.50 Adopter-ready (active), v1.51 agent diagnosis (SEED-005 first slice: one read-only, versioned diagnosis report), v1.52 catalog breadth, v1.53 announce-ready. This replaces the earlier order in the tables below. 0.3.21 (the authentication fix) was released the same day.

**Planted 2026-11-25, no slot:** [SEED-006](../seeds/SEED-006-connected-cli-and-operator-api.md), a `gh`-like CLI that signs in to a running app's operator API for people and LLM agents; the maintainer wants the operator UI in good shape first.

Four research notes and a synthesis are in [research/v1.50-prep/](../research/v1.50-prep/SYNTHESIS.md). The prep found that a published Scrypath cannot authenticate to a Meilisearch server with a master key (reproduced, then fixed outside the milestone; its release needs the maintainer's yes).

**Recommended: keep v1.50 "Adopter-ready", and lead it with making the documented path work.** Confidence 0.8.

| Step | Content | Plans |
|---|---|---|
| 199 Documented path works | Reproduce first; golden path and guides, `sortable:` settings (F4), Oban queue observation (F5, new), task history past 1,000 (F1) | 2 to 3 |
| 200 Fresh-consumer walk | Published package and HexDocs only, keyed production-mode server | 1 |
| 201 Testing guide | "Testing your app", no new API, walk findings; **cut line**; release | 2 |

Highlight, crop and a paging guard are not built unless a grilling session asks. About 5 to 6 plans (recorded estimate 3 to 5); stop and re-ask beyond 7.

**Decisions waiting on the maintainer:** root `lib/` changes in 199; release 0.3.21 for the authentication fix; and whether the AI-agent diagnosis slice (SEED-005) becomes v1.51, ahead of catalog breadth, which moves to v1.52. The last one reorders the adopted roadmap, so nothing changes until the maintainer says so.

## v1.49 closeout input for the next milestone (2026-11-25)

The storybook review is closed and recorded in [PAUSE-2-FEEDBACK.md](../research/storybook-catalog/PAUSE-2-FEEDBACK.md); its "For v1.50 input" list and the [v1.49 audit](../milestones/v1.49-MILESTONE-AUDIT.md) are inputs to the next milestone choice. SEED-005 (AI-operable Scrypath) is a candidate to weigh, not approved scope.

## Working rules

- One PR per coherent slice. Squash-merge it once the required checks (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`) pass. `deep-quality (advisory)` is expected to be red until sigra makes `cloak_ecto` optional; see below.
- Hex releases wait for the maintainer's explicit yes. Visible UI PRs no longer wait: squash-merge any PR once its required checks are green on the exact head (maintainer standing instruction, 2026-11-19, in AGENTS.md). A release-please PR needs a close and reopen before its CI runs.
- **Full GSD lifecycle per milestone** (maintainer, 2026-10-25, replacing the earlier "one lean plan" rule):
  - `/gsd-new-milestone` turns this file's section into requirements and a phase roadmap;
  - then each phase goes through discuss → (UI-spec for frontend phases) → plan → execute → verify, plus code review and security where they apply;
  - the milestone ends with audit → complete → archive.

  The maintainer values the discussion and decision points.
- This file stays the cross-milestone order and its research findings. GSD's `ROADMAP.md`/`REQUIREMENTS.md` hold the active milestone.
- Tests and CI are still the proof: no manual UAT. Subjective checks become executable ones, and anything genuinely subjective goes to the maintainer as a decision rather than a UAT step.
- Prefer copying a small helper over adding a dependency.

## Correction 2026-11-21 (maintainer feedback session): the catalog leads

The maintainer called the catalog deferral in the Post-v1.48 proposal below "a huge miss": it overrode their recorded 2026-10-25 decision (ADR 0001, UI engine D1) and they want the storybook now, built from realistic fictional adopters, run in GSD autonomous mode with the storybook opened for their feedback at the end of every milestone. Five sibling-project sessions replied; seven upstream prep notes and an adversarial pass followed. Full reconciliation: `.planning/research/catalog-prep/SYNTHESIS.md`. Learned rules: playbook C31 to C38. The reopen triggers below are moot for the catalog.

| Slot | Milestone | Goal | Size | Confidence |
|---|---|---|---|---|
| 0 | Pre-work PRs (not a milestone) | Merge #168; fix the false guide line and `posture.ex` path; split `deep-quality`; proposed cadence text. Titles `docs`/`chore`/`test`/`ci` only | 2 small PRs | high |
| 1 | **v1.49 Catalog foundation** (decided) | 195 mount and prove (spike, pre-authorized unless an ADR 0001 trigger trips); 196 fixtures and three adopters; 197 JOB-03 pilot then **pause 1**; 198 scale (cut by default); **pause 2** at the end | about 15 plans, stop at 20 | decided |
| 2 | **v1.50 Adopter-ready** | "Testing your app" guide, fresh-consumer walk, then after an API-grilling session maybe highlight/crop or a paging guard; first release 0.3.21 with the maintainer's yes (phases 199 to 201) | 3 to 5, cut after the guide and walk | 0.7 |
| 3 | v1.51 Catalog breadth | Remaining screens, a second mounted journey, the storybook becomes the review surface; only if 198 was cut or review says widen | 5 to 8 | 0.4 |
| 4 | v1.52 Announce-ready | Website content with real product images from stories, then a maintainer-run announcement, after a release carrying the testing guide | 3 to 4 | 0.6 |
| 5 | ScrypathOps on Hex | A decision, not a milestone (lockstep pin, no `@moduledoc false` internals, allowlisted `files:`, prebuilt assets, clean `hex.audit`) | ADR and package dry run first | 0.8 not planned |

v1.34 is **not** paused (shipped 2026-06-29), so there is no theme milestone: the catalog's light, dark and System stories and the milestone-end review cover the residual gap. No Hex release inside v1.49. Bug candidates handed to the maintainer: `Tasks.list_sync_tasks` truncates history at 1,000 tasks though Meilisearch keeps about 1M (library); the ops UI prints Meilisearch error messages unbounded; a stale-sudo operator returns to `/` in production.

## Post-v1.48 proposal (2026-11-21, prepared upstream; ADOPTED 2026-11-21: the maintainer said to follow the recommendations; a UI feedback session on the previous milestone runs before the milestone is opened, and its feedback is folded into `.planning/MILESTONE-CONTEXT.md`)

v1.48 Discovery and onboarding shipped and is archived ([audit](../milestones/v1.48-MILESTONE-AUDIT.md), `tech_debt`, no unsatisfied requirement). The optional website phase was cut at the checkpoint because traffic is effectively nil ([CHECKPOINT.md](../research/v1.48-prep/CHECKPOINT.md)). Three research notes with lenses, primary sources and an adversarial pass are in [research/v1.49-prep/](../research/v1.49-prep/): A catalog readiness refresh, B adopter-features evidence, C sequencing and release. They converge more than they conflict.

**Recommended: a one-PR readiness pass, then v1.49 "Adopter-ready" as a small, cuttable milestone; the catalog is deferred with named reopen triggers, not cancelled.** Confidence 0.55 for the milestone choice (B 0.55, C 0.6, A rates the catalog-as-written at 0.1 and a shrunk catalog at 0.55 with deferral to adopter work as its runner-up), 0.8 for no Hex release right now.

| Step | Scope | Proof | Needs the maintainer |
|------|-------|-------|----------------------|
| Readiness pass (one PR, not a milestone) | Fix the false line in `guides/per-query-tuning-pipeline.md:64` ("highlight / crop already modeled": the `per_query` allowlist has only the three ranking-score keys); fix `scrypath_ops/lib/scrypath_ops/posture.ex:416` (resolves a guide path that does not exist under `scrypath_ops/`); split the `deep-quality` lane so its one known red (sigra to cloak_ecto) stops hiding other findings (CI-EFFICIENCY finding 1); read-only `mix verify.release_parity 0.3.10` for issue #52; write the release cadence rule below into `docs/releasing.md` | existing contract tests plus one test per fixed defect | the cadence rule and anything touching repository settings (Dependabot security updates) |
| v1.49 Adopter-ready (about 3 to 5 plans, cut line after the second phase) | (1) a "Testing your app" guide with no new API (`req_options` with `Req.Test` already works and is validated; Oban `assert_enqueued`; the inline-sync path in about 25 lines), plus a fresh-consumer walk (an agent builds an app from Hex 0.3.20 using only HexDocs; recorded as maintainer-side friction evidence, not outside-adopter evidence); (2) highlight and crop passthrough as new `per_query` allowlist keys, only if the walk or the maintainer asks for it; (3) `pagination.max_total_hits` plus a paging guard as the cut line | planted-failure tests, built-docs checks, the walk's recorded findings | a yes that this is a deliberate strategic product decision (the third reopen trigger in the scope policy; nothing here is outside-adopter evidence) and one API-grilling session before phase (2) |
| Catalog foundation (deferred, v1.5x) | If reopened: fixtures consolidation (two drifting `Phase173FixtureSource` copies), then the phoenix_storybook spike ending in a go/no-go; the pilot and "at scale" wait for the spike numbers | spike numbers: cold-cache CI cost, NIF fetch, lock growth | a reopen trigger (below) |

**What was corrected after v1.48 (carry these into any catalog plan):** the required-gate ledger is 10 of 12 (not 8); the `scrypath_ops` lock is 54 packages and phoenix_storybook 1.5.0 adds 9 (the Rust NIF is in `mdex_native`); phase numbers 192 to 194 are used or cut, so the next phase is 195; the axe defect and the CI speed pass that note B cited are already merged; the retained preview is still pinned at `8beb3ed0`; all phoenix_storybook GitHub advisories were fixed by 2026-05-20 and none is open on 1.5.0, and its playground evaluates templates server-side, so any route stays dev-only and loopback-bound.

**Hex release: not now.** Every commit since 0.3.20 is `docs:` or `chore:`, so release-please opens no PR, and 0.3.20 shipped on 2026-11-21. The Phase 193 regroup rides the next release that carries a behavior change; time-box it to 2026-12-21 and revisit then (a docs-only release is justified only with an announcement). The maintainer's yes is needed only to merge that release PR. **Versioning footgun:** `release-please-config.json` has `bump-patch-for-minor-pre-major: true`, so features ship as patches and `~> 0.3` accepts any 0.x below 1.0. Recommend the first new-public-API release ships as 0.4.0 and the install-line shape is decided when v1.49 opens (the install-line guard already goes red at that bump, by design; `docs/releasing.md` has the fix).

**Proposed cadence rule (the maintainer's to adopt):** 20 releases in seven months (median gap 3 days; 3 in the last 3 days) is about 34 a year against about 12 to 15 for Req and Oban. Release only on a behavior change, a runtime-dependency advisory, an adopter-facing doc defect or an announcement; never docs-only alone; at most one release per 14 days except for bug and security fixes.

**Catalog reopen triggers:** ScrypathOps becomes a published package; two or more ops UI regressions in a quarter that existing checks missed; a spike result under about 3 minutes of added cold CI plus the maintainer wanting the UI engine first; an outside request for a component reference.

**What would change this:** any outside report or adopter question (reorder to it); the fresh-consumer walk finds nothing painful (stop after the guide, then catalog or idle); the Req.Test snippet cannot cover inline sync in about 25 lines (then a public `Scrypath.Testing` module needs an ADR); the maintainer skips the API-grilling session (go to maintenance mode plus distribution, not to the catalog); the maintainer wants the UI engine for its own sake (then the shrunk catalog, A's two phases, is the way to do it). Deferred as costly or one-way and not recommended now: a public `Scrypath.Testing` module, the indexable predicate, new backfill and reindex Mix tasks.

**Not verified by the notes (U):** who the single hex.pm dependant is and whether anyone pins `~> 0.3`; whether `_formatted` highlight output is HTML-escaped (any highlight feature needs an escape-then-wrap recipe and a hostile-title test); sibling-library API names (check against source before a public guide); the NIF's actual CI cost. Correction to note B: the faceted-search guide mentions `Req.Test`-style fixtures in passing; no guide has a testing recipe.

## Post-v1.47 proposal (2026-11-21, prepared upstream; ADOPTED 2026-11-21: housekeeping merged as #157 and #158, v1.48 Discovery and onboarding opened exactly as recommended, catalog is v1.49)

v1.47 Brand completion shipped (Phases 188.1 and 189-191, PRs #149, #152, #153, #154; [audit](../milestones/v1.47-MILESTONE-AUDIT.md) `tech_debt`, no unsatisfied requirement; website live). The slot decision the maintainer left open is the discovery and onboarding milestone versus the catalog milestone. Four research notes with lenses, primary sources and an adversarial pass are in [research/v1.48-prep/](../research/v1.48-prep/): A discovery and onboarding, B catalog readiness, C sequencing, release and CI, D adversarial review and synthesis. Where the notes conflict, D is the tie-breaker.

**Recommended: housekeeping first, then v1.48 Discovery and onboarding as a cuttable three-phase milestone; the catalog becomes v1.49.** Confidence 0.62 that discovery goes before the catalog (a close call), 0.8 for the housekeeping, 0.75 for no Hex release until the README fix lands, 0.5 that the website content phase should happen at all.

**Housekeeping, no milestone, proceed without asking (green required checks, squash):**
1. The CI speed and reliability PR already in preparation (repository-contracts halves in parallel, compatibility cells skipped on PRs that cannot affect the library, PR-run cancellation, the flaky `loader_backfill_postgres_test` generator, the `ops-ui-path` gap for `examples/scrypath_ecommerce/assets/`, a pre-push local-mirror checklist).
2. A small `chore(ops-ui)` PR: fix the axe `label-content-name-mismatch` markup in `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` (fix the accessible names, never disable the rule), the vacuous regex at `operator.spec.ts:261`, and qualify the two unqualified `verify.adopter` lines in `docs/`. Then rebase and merge Dependabot #129.
3. A README-only PR fixing the HexDocs self-links (six links resolve to the README itself on the live HexDocs page).
Then the other Dependabot PRs (#150, #151) on green.

**v1.48 Discovery and onboarding (about 7 plans, cut line after 193):**
| Phase | Scope | Verification | Needs the maintainer |
|---|---|---|---|
| 192 Docs truth and README | no Hex-shipped doc names a repo-only task (one invariant plus a planted case, changed together with the PROJECT.md Canonical Adopter Contract), README trimmed to one job, links absolute to HexDocs where needed | docs contract tests, link checks, planted violation | Hex 0.3.20 release PR: explicit yes |
| 193 HexDocs regroup plus guards | sidebar grouping only (no guide merges, deletions or renames), link, snippet and claim guards | docs build, link and snippet checks | no |
| checkpoint | entry-point signal: record GitHub traffic referrers (14-day window; 4 views from 3 uniques today) and hex.pm downloads (1,782 all time, 89 last week) | numbers recorded | decides whether 194 happens |
| 194 Website content (optional) | content and information architecture on the existing token pipeline; Docs points at HexDocs | computed-style, contrast, axe, link and copy checks; design recorded as unproven | outward-facing claims need a yes |

**Then v1.49 Catalog foundation** (4 phases, spike-first with a go/no-go by the ADR 0001 triggers; consolidate the fixture copies and copy stubs; the rendered-text lint ingests `copy_rules.json`; storybook route dev-only and loopback-bound; the retained preview refresh is plan 1 of the first rendered-evidence phase), unless the checkpoint favors adopter features. v1.50 stays adopter features; grill API shapes first.

**What would change this:** the checkpoint shows almost no traffic (then adopter features before more docs work), the maintainer does not want a website redesign (drop 194), ScrypathOps becomes a published package (catalog first), or an adopter report of a concrete library bug (bundle it into the next release).

**Notes for the maintainer:** (1) the repository is public and every job uses a standard runner, so runner-minutes cost nothing; the real costs are wall time (about 18.5 minutes per PR, serialized by the strict up-to-date rule), attention, and an Actions cache at 10.76 GB over the 10 GB cap. The AGENTS.md "GitHub Actions money" wording is yours to revisit. (2) No Hex release is recommended now: the shipped files differ from 0.3.19 by almost nothing. (3) Branch protection stays as it is; a merge queue is rejected for now.

## Post-v1.46 proposal (2026-11-19, prepared upstream; the maintainer chooses)

v1.46 shipped to `main` (Phases 186-188, PRs #137, #138, #139, #143; [audit](../milestones/v1.46-MILESTONE-AUDIT.md) `tech_debt`, no blockers). Phases 189 and 190 were deferred. Four decision notes with evidence, lenses and adversarial passes are in [research/v1.47-prep/](../research/v1.47-prep/): A scope and shape, B website, C release and delivery, D verification and cleanup.

**Recommended next milestone: v1.47 Brand completion** (small, about 5-6 plans), then v1.48 Catalog foundation. Run `/gsd-new-milestone v1.47` from this section; `.planning/MILESTONE-CONTEXT.md` carries the prepared input.

| Phase | Scope | Gate | Confidence |
|---|---|---|---|
| 189 Website re-skin (SITE-01), 2-3 plans | `build.mjs` derives theme variables from pinned `brand/tokens.json` and copies the pinned fonts (Bricolage included, OFL texts served), lockups, light and dark favicons and social card; light default with a Light/Dark/System picker; the old website palette is added to the deny-set in the same commit as the asset swap; `check.mjs` (today capture-only) rewritten to computed-style, font-hash and contrast assertions; `brand/**` added to the website path filter | dependency-free static contract in `core`/`repository-contracts`; `build-and-check` green on the exact head (the deploy job depends on it, but it is not a required check: wait for it before merging, and decide in the plan whether to make it gate 9 of 12) | 0.75 (0.6 on the picker) |
| 190 Wording (COPY-01 and the "Control room" casing) | glossary-rule copy fixes, guards written as a data table inside the required `ops-ui` job so the v1.48 copy lint can ingest them | one local e2e run | medium-high |
| 191 Cleanup | in order: demo favicon becomes a copy of `favicon-light.svg`; delete the `brandbook/` readers (`ui_tokens.ex`, its contract test, the `verify.phase99` entry, the mix alias); then `brandbook/`, the `ci.yml` path regex entry and the allowlist entries (ceilings recomputed from merged `main` after Phase 189 (5 entries and 197 hits, ending at 0 and 0)). Add static invariants to the existing token test (12 px floor, no arbitrary text sizes, no `uppercase`, no `infinite`; about 1 s, no new gate); tripwire test that the pinned `icon/favicon.svg` is still unthemed plus a scan for any non-`brand/` use of it; reword the CONTRIBUTING ledger triggers; name `brand/tokens.json` as the authority | stays at 8 of 12 | high |

v1.48 Catalog foundation (about 11 plans): 192 phoenix_storybook spike and boundary; 193 fixtures and cheap copy layers; 194 pilot read-only half (JOB-03); 195 pilot retry half with `decide/4`; 196 catalog at scale (trimmed). No ADR 0001 revisit trigger has fired. phoenix_storybook 1.5.0 adds 9 packages and one Rust NIF to the 54-package `scrypath_ops` lock, so the spike reads the audit output. Old v1.48 (screens, flows) and v1.49 (adopter features) become v1.49 and v1.50. Confidence medium-high; the phase list is the same under a single combined milestone, so being wrong costs one extra closeout.

**Delivery: done 2026-11-20.** README header pinned to commit `8beb3ed0` raw URLs (#145, loads on hex.pm, verified on the live 0.3.19 page); Release Please repository setting fixed (via the API); Hex 0.3.19 released (#146; README and HexDocs only, changelog hand-edited); Dependabot #128, #131, #140, #142 merged, #130 closed with an ignore, #141 closed until the storybook spike. Still open: #132 (relax a hardcoded SHA in `workflow_wiring_test`) and #129 (re-run after the re-skin).

**Carry-forward items:** the 11-20 nightly is the first on re-skinned `main` (the `ecommerce-e2e` job failed on 7 of 8 earlier nightlies unnoticed because it is advisory; read it first); the retained preview is refreshed just before the first rendered-evidence phase of v1.48 (no preview capture runs in v1.47); report the unthemed `favicon.svg` upstream to the book's author; the Cancel-focus assertion and the unpinned copy values moved to v1.47 Phase 190 (COPY-04, in the required-lane `operator.spec.ts`).

**What would change this:** a computed-style regression reaching `main`, a concrete library bug (bundle it into 0.3.19), preferring fewer milestone boundaries (then one combined v1.47 with 189-191 first), or wanting a light-only website (drop the picker, script and dark tokens).

## Re-plan (2026-11-18, adopted by opening v1.46)

Status: ADOPTED 2026-11-18. The maintainer confirmed the v1.46 scope and ran `/gsd-new-milestone v1.46` from it, with Steps 0, 0b and Hex 0.3.18 done (merged or published). It supersedes the "Re-order (approved 2026-10-25)" plan and sections 4 to 6 below for the UI work. Detail and evidence: [V1.46-PREP.md](../research/brand-and-catalog/V1.46-PREP.md), [PROPOSAL.md](../research/brand-and-catalog/PROPOSAL.md), [BRAND-ADOPTION-PLAYBOOK.md](BRAND-ADOPTION-PLAYBOOK.md). Trigger: the maintainer adopted a new brand book as the official identity on 2026-11-18 (it supersedes the v1.35 violet and copper identity) and asked for the UI to be re-skinned and cataloged in phoenix_storybook.

Standing practice (AGENTS.md, "Milestone preparation"): at every milestone boundary the next milestone is prepared upstream with research and a recommendation, and this file is updated, before the maintainer is asked what is next.

| Step | Scope | Key gates | Needs the maintainer |
|---|---|---|---|
| Step 0 (not a milestone) — DONE 2026-11-18 (squash `b67c964d`, PR #123; #122 closed as subsumed; `v1.44` and `v1.45` tags on the remote) | Land v1.44 and v1.45: freeze main, push the `v1.45` tag first (it holds the ledger bootstrap commit), retarget #123 to main, close and reopen it, `BEGIN_COMMIT_OVERRIDE` squash, close #122 and five superseded Dependabot PRs; do not repin the ledger | five required checks green on the reopened run | yes (once, including the tag push) |
| Step 0b (small PR) — IN PROGRESS (branch `chore/ci-hygiene-step-0b`: `ac00e000` CI hygiene, `c05227ea` ecto 3.14.3 and plug 1.20.4) | Clear the advisory bumps the nightly audit flags (cloak and cloak_ecto have no patched release and stay flagged until sigra ships without a hard `cloak_ecto` requirement; the audit stays fail-closed); Dependabot entry for `scrypath_ops`, examples, website, docker; make `ops-ui` required (extend its paths; amend `workflow_wiring_test`); fix the `action-pins` regex; digest-pin the Playwright image; default workflow permission read | `deep-quality` green or each exception recorded; nightly lanes green | no (routine), unless an exception is needed |
| Hex 0.3.18 | Release-please PR after Step 0 with upgrade notes (v1.44 changed the explicit loader contract) | release checks | yes at release time |
| Planning compaction | Archive history from PROJECT, MILESTONES, RETROSPECTIVE under `.planning/milestones/`, keep a contract-anchors block | phase108, phase111, no_human_gates, docs_contract tests | no |
| v1.46 Brand foundation and re-skin — DONE 2026-11-19 (189 and 190 deferred) | 186 ingest, pin and guard (at most 3 plans, test and evidence only); 187 ScrypathOps re-skin as one Draft PR; 188 README header and HexDocs; 189 website (deferrable); 190 wording that does not need the catalog (deferrable) | offline brand pin, one Node token test (parity, allowlist, deny-list), contrast pairs, required `ops-ui`, mounted-host font check | one merge-time yes on 187 (merge authority, no aesthetic claim) |
| v1.47 Catalog foundation (SUPERSEDED by the Post-v1.46 proposal: it is now v1.48, Phases 192-196) | 191 phoenix_storybook spike and boundary proof; 192 fixtures and cheap copy layers; 193 pilot, read-only half (JOB-03); 194 pilot, retry half with `decide/4`; 195 catalog at scale (trimmed) | storybook boundary required, JOB-03 whole-job test, rendered-text lint | no, unless a revisit trigger fires on ADR 0001 |
| v1.48 Screens, flows, full catalog | Search (JOB-05 pilot second), Sync and index, Help, shell, Job stories, "every routed state has a story", advisory nightly sweep, type scale, progress line decision, deferred defects | per-area parity checks | batched yes on visible copy and design |
| v1.49 Adopter features (was v1.48) | Testing kit, indexable predicate, highlighting passthrough, hit and facet limits, backfill and reindex tasks; grill API shapes first | as before | API grilling |

Guardrails proposed for every phase: the progress guard (no phase continues without a rendered-UI change to a whole screen or journey; a second consecutive evidence-only plan forces a stop-and-decide; evidence-only phases capped at 2 plans), loop breakers (one full gate per commit SHA, per-lane timeouts recorded as failures, at most 2 review-and-fix cycles per oracle, a stale receipt is a failed gate, no capture from a dirty tree), a finite route and state inventory per milestone, and a gate budget (at most 12 new required gates, each with a deletion trigger).

Why re-skin before catalog: seven sibling reviews (accrue, sigra, threadline, mailglass, exifcleaner, playstead, fablebook) and a measured recolor dry run (only about 12 literal test lines need a rewrite) point to the cheapest path being a global-token re-skin first, then a small catalog proven on one whole job. It is one chosen path, not a proven winner.

Known stale text to fix when v1.46 opens: PROJECT.md "Current State" and "Next Milestone Goals" call v1.46 "UI quality engine and pilot"; the STATE.md closeout cursor points at a deleted `/private/tmp` directory.

## 0. 0.3.17 hotfix — done

PR #114 lets pre-0.3.16 Oban upsert jobs write their stored snapshot when the app can't reload records, instead of cancelling them. It also adds an upgrade note saying Oban mode needs `:repo`. Released as 0.3.17 (#115).

## 1. v1.43 closeout — done

Done 2026-10-25. Closeout run 40204029522 on `ebed49b5`; receipt in `v1.43-final-receipt.json`; T-177-05 closed; phases 173–177 archived. The steps below are kept for the record.


1. Dispatch CI on `main` (`workflow_dispatch`) so the `closeout-attestation` job runs; its artifact is kept 7 days.
2. Write `reference/v1.43-final-receipt.json` from that run, shaped like `v1.42-final-receipt.json`.
3. Close T-177-05 in the phase 177 `SECURITY.md` against that evidence.
4. Archive phases 173–177 into `milestones/v1.43-*`, then set STATE to `Awaiting next milestone`.
5. Tidy stray files: `phases/89-*`, `phases/95-*`, `tmp_get_data.sh`, the `v1.27-v1.27-MILESTONE-AUDIT.md` name, and the root v1.0/v1.1 audits (move them under `milestones/`).
6. Delete the stale todo `todos/pending/2026-10-15-dependency-audit-followup.md`.

## 2. v1.44 sync correctness (library)

- Backfill and reindex ignore the schema loader's `preload:` and `search_records/2` (`lib/scrypath/backfill.ex`, `base_query/3`), so documents built by a backfill can differ from those built by inline/Oban sync. Route them through the same loader.
- Keyset paging uses only the first primary-key column (`primary_key/1` in `backfill.ex`), which skips rows on composite keys. Either guard against multi-column keys with a clear error or page on the full key.
- `sync_related` resolvers get records under inline sync but only ids under Oban. Make them always get records.
- The Oban workers emit no telemetry, and deletes for ids that no longer exist are silent. Add spans/events with stable metadata.
- Id lists are unbounded. Chunk them (about 1000 per call) for loads and backend calls.
- `RelatedEnqueue` has drifted from the main enqueue path: it has no `unique:`, and it calls `String.to_existing_atom` without a rescue.
- Schema hooks are duck-typed. Declare them as `@optional_callbacks`.
- Add a loader test against a real database; the current ones only use `FakeRepo`.
- The `lib/scrypath/sync.ex` (around line 60) compile warning is a false positive in builds without Oban. Silence it properly. Phase 181 found it was a real Elixir 1.19 type warning from an always-raising no-Oban stub (fixed), not a false positive; the earlier `verify.no_optional_deps` greens in the Phase 179/180 summaries ran with Oban on the code path.

## Re-order (approved 2026-10-25; superseded for the UI work if the 2026-11-18 re-plan is approved)

The maintainer named a UI quality engine as the next major UI opportunity: [owner intent](../research/ui-quality-engine/OWNER-INTENT.md) and [recommendations](../research/ui-quality-engine/RECOMMENDATIONS.md). Approved order: **v1.44 sync → v1.45 foundation and CI (plus the engine's prerequisites) → v1.46 UI engine and pilot → v1.47 UI surfaces and polish → v1.48 adopter features.**

- **Sync stays first.** Composite-key paging that skips rows and backfills that ignore the loader are correctness bugs. That work is all in `lib/` and doesn't touch `scrypath_ops`.
- **The UI engine waits for v1.45.** Its browser sweep needs the nightly lane green, which v1.45 delivers.
- **Adopter features move after the UI engine.** They need API grilling anyway, and highlighting will render in Search, so it should land on the composable, storied Search surface rather than the 2,000-line monolith.

## 3. v1.45 foundation and CI

- Fix the false claim in older STATE text: the 19 standalone `phase173_*` specs are **not** run anywhere (nothing invokes `verify-phase173.sh`). In `verify-e2e.sh`, add `-f compose.phase173.yaml` when scope is `full`, and raise the timeout to 30 minutes. This also fixes the nightly `ecommerce-e2e`, red since 2026-10-13.
- Give the 13 skipped specs (`ui_followup.spec.ts` 8, `ui_iteration3.spec.ts` 6) the same port guard `ui_baseline` uses, so they run.
- Move the ~44 maintainer `verify.*` mix tasks out of the Hex package into `dev/mix/tasks`, and update the package parity gate with them.
- Root deps: declare `{:telemetry, "~> 1.0"}`, and allow `req` `~> 0.6.1 or ~> 0.7` (Dependabot #73).
- scrypath_ops deps: drop swoosh/Mailer; make phoenix_live_dashboard and telemetry_poller/metrics dev- or standalone-only; set esbuild/tailwind to `only: :dev`; loosen the sigra pin.
- CI caching: buildx GHA cache and `restore-keys`.
- Fold the open Dependabot PRs (#65, #68–#76) into this milestone instead of merging them one by one.
- UI engine prerequisites (no visible UI change):
  - an L1 ratchet that bans hex, arbitrary values, `style=` and `z-` literals outside the token files;
  - a Tailwind colour-namespace reset;
  - delete the generator `home.html.heex`;
  - run `contrast-checker.mjs` in `repository-contracts`, with focus-ring pairs;
  - give `brandbook/tokens` a DTCG `ops` group with a drift test;
  - delete the paid OpenAI path in `ops-ui-visual-judge.mjs`, which breaks the no-paid-judge rule.

  See RECOMMENDATIONS D4 and D6.

## 4. v1.46 UI quality engine and pilot (old plan; see the 2026-11-18 re-plan: this becomes v1.47 Catalog foundation)

- **Personas:** operators and adopters both get personas. Operator personas map onto `ROLE-*`/`JOB-*`; the adopter twins are Wikily, Chatly, Langalern, Budgetly and Shoply. See the grilling decisions in RECOMMENDATIONS.
- **Fixtures:** a `fixtures/scrypath_fixtures` path dependency (dev/test only) with 12 invariant tests. It replaces both `Phase173FixtureSource` copies.
- **Storybook:** phoenix_storybook in `scrypath_ops`, dev/test only. Themes use `data_attribute: "theme"`, page and section stories run in iframes, and `storybook.css` imports `app.css`. Our ExUnit gates sit on top: every variation renders, every variation is described, every component is covered, and no two variations render identically. A manifest feeds the sweep. Primitive and group stories cover `OpsUi`.
- **Pilot:** extract Search health and Control room into area components over pure view-models, keeping pixels the same.
- **Checks:**
  - the L2 browser sweep over the manifest, advisory until 14 clean nights;
  - the `copy_rules.json` lint with a shrink-only baseline;
  - the `ui-decisions.jsonl` decisions log.
- **Cleanup:** port the `phase173_*` specs onto stories and delete the `phase173` fixture mode.

## 5. v1.47 UI surfaces and polish (old plan; becomes v1.48)

- Extract Search, then Failed sync work, then Sync and index, with area, section and page stories for each.
- L3 element screenshots get one pinned Linux baseline.
- The L4 judge becomes a bounded, agent-run pairwise skill, calibrated on `UI-FEEDBACK.md`.
- Each section gets one rubric review.
- Copy and design fixes are batched for the maintainer's yes.

## 6. v1.48 adopter features (was v1.46; becomes v1.49 in the 2026-11-18 re-plan)

Scope guard, exactly these five: a testing kit (`Scrypath.Testing`); a `search_indexable?/1` predicate (which also covers soft deletes); highlighting/cropping passthrough (`per_query` allowlist, `_formatted`); `pagination.max_total_hits` and `faceting.max_values_per_facet` settings plus a guard; `mix scrypath.backfill` and `mix scrypath.reindex`.

Still out of scope: vector/hybrid search, autocomplete, callback or Repo-hook auto-sync, automatic association walking, a public multi-backend facade.

**Grill the maintainer on the API shapes before starting this milestone.**

## Discovery and onboarding journey, including the website refresh (planted 2026-11-20 as SEED-004; slot pending the maintainer)

Widened the same day: the website refresh is one part of a coherent journey across README, website, HexDocs and guides for first-time visitors, people starting to use Scrypath and returning users, with one job per surface and no duplicated content or link spam. Intent and open questions: `reference/DISCOVERY-AND-ONBOARDING-JOURNEY.md`. Recommended shape: one milestone (README trim, website refresh, HexDocs and guide structure, upkeep guards), slotted right after v1.47. The paragraph below describes the website part.

The maintainer wants the public website fully refreshed, not only re-skinned: goal-first scope, Impeccable for design, `ux-writing` for copy, brand-book voice, and permanent upkeep guards so the copy never drifts. Scoping notes: `research/website-refresh/` (01 goals and scope, 02 benchmarks, 03 inventory); seed: `seeds/SEED-004-website-refresh.md`. Recommended slot (confidence medium): a small milestone right after v1.47, ahead of the catalog (the catalog would then renumber to v1.49 and later), because the brand work and deploy safety net are fresh. v1.47 Phase 189 stays identity-only plus the SITE-06 accuracy fix (the site tells Hex adopters to run the repo-only `mix verify.adopter`). Separate item: two Hex-shipped guides (`guides/outside-adopter-intake.md`, `guides/support-and-compatibility.md`) also name `mix verify.adopter`; contract tests pin that text.

## Later

- Backend seam: `case backend do Scrypath.Meilisearch -> ...` bypasses the adapter in seven places (`sync.ex`, `backfill.ex`, `operator/index_contract_drift.ex`, `operator/status.ex`, `operator/reconcile.ex`, `operator/failed_work/retrieval.ex`).
- Contract-test sprawl.
- Throttling, geo search.
- Release-please app token (deferred; keep the close+reopen nudge).
- Elixir 1.20.4/OTP 29 adds no-Oban warnings outside the 1.19 support target (redundant clauses at `lib/scrypath/meilisearch/task_payload.ex:53`, `lib/scrypath/meilisearch/settings.ex:167`, `lib/scrypath/composition/merge.ex:163,166,169`, plus "cannot infer signatures from :oban"). Fix when CI adds a 1.20 lane.

## Known open items

- `deep-quality (advisory)`: as of 2026-11-18 (audit run at branch HEAD), after the v1.45 lockfile changes only ecto 3.14.2 and plug 1.19.5 or 1.20.3 remained besides cloak; Step 0b bumps ecto to 3.14.3 and plug to 1.20.4, which clears root, phoenix_meilisearch and ecommerce. `scrypath_ops` stays red on `cloak` 1.1.4 (EEF-CVE-2026-95105) and `cloak_ecto` 1.3.0 (EEF-CVE-2026-94206), which have no patched release and come in through optional `sigra ~> 1.5` (sigra 1.7.1 requires `cloak_ecto ~> 1.3` non-optional; `hex.audit` audits the whole lockfile so `optional: true` does not help). An ignore can't help, because `scripts/ci/dependency_audit.ex` treats any ignore as failed by design. Fix: release sigra without a hard `cloak_ecto` requirement, then bump sigra in `scrypath_ops/mix.exs` and refresh the lock with Hex 2.5 or newer (owner decision recorded in V1.46-PREP). The nightly `ecommerce-e2e` failure (`standalone_ops` unresolved) was fixed by the v1.45 merge; confirm with one dispatched run.
- The maintainer's untracked `examples/scrypath_ecommerce/priv/playbooks/my-search.json` stays untouched.
