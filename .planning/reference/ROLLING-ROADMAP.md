# Rolling roadmap (approved 2026-10-24; proposed re-plan 2026-11-18 below)

The maintainer approved this order and these working rules after a research fan-out and a grilling round. Pick up the first unfinished item. `STATE.md` records progress.

## Working rules

- One PR per coherent slice. Squash-merge it once the required checks (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`) pass. `deep-quality (advisory)` is expected to be red until sigra makes `cloak_ecto` optional; see below.
- Hex releases and visible UI changes wait for the maintainer's explicit yes. A release-please PR needs a close and reopen before its CI runs.
- **Full GSD lifecycle per milestone** (maintainer, 2026-10-25, replacing the earlier "one lean plan" rule):
  - `/gsd-new-milestone` turns this file's section into requirements and a phase roadmap;
  - then each phase goes through discuss → (UI-spec for frontend phases) → plan → execute → verify, plus code review and security where they apply;
  - the milestone ends with audit → complete → archive.

  The maintainer values the discussion and decision points.
- This file stays the cross-milestone order and its research findings. GSD's `ROADMAP.md`/`REQUIREMENTS.md` hold the active milestone.
- Tests and CI are still the proof: no manual UAT. Subjective checks become executable ones, and anything genuinely subjective goes to the maintainer as a decision rather than a UAT step.
- Prefer copying a small helper over adding a dependency.

## Proposed re-plan (2026-11-18, awaiting maintainer approval)

Status: PROPOSED. Not approved. If approved it supersedes the "Re-order (approved 2026-10-25)" plan and sections 4 to 6 below for the UI work. Detail and evidence: [V1.46-PREP.md](../research/brand-and-catalog/V1.46-PREP.md), [PROPOSAL.md](../research/brand-and-catalog/PROPOSAL.md), [BRAND-ADOPTION-PLAYBOOK.md](BRAND-ADOPTION-PLAYBOOK.md). Trigger: the maintainer adopted a new brand book as the official identity on 2026-11-18 (it supersedes the v1.35 violet and copper identity) and asked for the UI to be re-skinned and cataloged in phoenix_storybook.

Standing practice (AGENTS.md, "Milestone preparation"): at every milestone boundary the next milestone is prepared upstream with research and a recommendation, and this file is updated, before the maintainer is asked what is next.

| Step | Scope | Key gates | Needs the maintainer |
|---|---|---|---|
| Step 0 (not a milestone) — DONE 2026-11-18 (squash `b67c964d`, PR #123; #122 closed as subsumed; `v1.44` and `v1.45` tags on the remote) | Land v1.44 and v1.45: freeze main, push the `v1.45` tag first (it holds the ledger bootstrap commit), retarget #123 to main, close and reopen it, `BEGIN_COMMIT_OVERRIDE` squash, close #122 and five superseded Dependabot PRs; do not repin the ledger | five required checks green on the reopened run | yes (once, including the tag push) |
| Step 0b (small PR) — IN PROGRESS (branch `chore/ci-hygiene-step-0b`: `ac00e000` CI hygiene, `c05227ea` ecto 3.14.3 and plug 1.20.4) | Clear the advisory bumps the nightly audit flags (cloak and cloak_ecto have no patched release and stay flagged until sigra ships without a hard `cloak_ecto` requirement; the audit stays fail-closed); Dependabot entry for `scrypath_ops`, examples, website, docker; make `ops-ui` required (extend its paths; amend `workflow_wiring_test`); fix the `action-pins` regex; digest-pin the Playwright image; default workflow permission read | `deep-quality` green or each exception recorded; nightly lanes green | no (routine), unless an exception is needed |
| Hex 0.3.18 | Release-please PR after Step 0 with upgrade notes (v1.44 changed the explicit loader contract) | release checks | yes at release time |
| Planning compaction | Archive history from PROJECT, MILESTONES, RETROSPECTIVE under `.planning/milestones/`, keep a contract-anchors block | phase108, phase111, no_human_gates, docs_contract tests | no |
| v1.46 Brand foundation and re-skin | 186 ingest, pin and guard (at most 3 plans, test and evidence only); 187 ScrypathOps re-skin as one Draft PR; 188 README header and HexDocs; 189 website (deferrable); 190 wording that does not need the catalog (deferrable) | offline brand pin, one Node token test (parity, allowlist, deny-list), contrast pairs, required `ops-ui`, mounted-host font check | one merge-time yes on 187 (merge authority, no aesthetic claim) |
| v1.47 Catalog foundation | 191 phoenix_storybook spike and boundary proof; 192 fixtures and cheap copy layers; 193 pilot, read-only half (JOB-03); 194 pilot, retry half with `decide/4`; 195 catalog at scale (trimmed) | storybook boundary required, JOB-03 whole-job test, rendered-text lint | no, unless a revisit trigger fires on ADR 0001 |
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

## Later

- Backend seam: `case backend do Scrypath.Meilisearch -> ...` bypasses the adapter in seven places (`sync.ex`, `backfill.ex`, `operator/index_contract_drift.ex`, `operator/status.ex`, `operator/reconcile.ex`, `operator/failed_work/retrieval.ex`).
- Contract-test sprawl.
- Throttling, geo search.
- Release-please app token (deferred; keep the close+reopen nudge).
- Elixir 1.20.4/OTP 29 adds no-Oban warnings outside the 1.19 support target (redundant clauses at `lib/scrypath/meilisearch/task_payload.ex:53`, `lib/scrypath/meilisearch/settings.ex:167`, `lib/scrypath/composition/merge.ex:163,166,169`, plus "cannot infer signatures from :oban"). Fix when CI adds a 1.20 lane.

## Known open items

- `deep-quality (advisory)`: as of 2026-11-18 (audit run at branch HEAD), after the v1.45 lockfile changes only ecto 3.14.2 and plug 1.19.5 or 1.20.3 remained besides cloak; Step 0b bumps ecto to 3.14.3 and plug to 1.20.4, which clears root, phoenix_meilisearch and ecommerce. `scrypath_ops` stays red on `cloak` 1.1.4 (EEF-CVE-2026-95105) and `cloak_ecto` 1.3.0 (EEF-CVE-2026-94206), which have no patched release and come in through optional `sigra ~> 1.5` (sigra 1.7.1 requires `cloak_ecto ~> 1.3` non-optional; `hex.audit` audits the whole lockfile so `optional: true` does not help). An ignore can't help, because `scripts/ci/dependency_audit.ex` treats any ignore as failed by design. Fix: release sigra without a hard `cloak_ecto` requirement, then bump sigra in `scrypath_ops/mix.exs` and refresh the lock with Hex 2.5 or newer (owner decision recorded in V1.46-PREP). The nightly `ecommerce-e2e` failure (`standalone_ops` unresolved) was fixed by the v1.45 merge; confirm with one dispatched run.
- The maintainer's untracked `examples/scrypath_ecommerce/priv/playbooks/my-search.json` stays untouched.
