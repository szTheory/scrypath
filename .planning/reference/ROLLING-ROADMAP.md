# Rolling roadmap (approved 2026-10-24)

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
- The `lib/scrypath/sync.ex` (around line 60) compile warning is a false positive in builds without Oban. Silence it properly.

## Proposed re-order (2026-10-25, waiting on the maintainer's yes)

The maintainer named a UI quality engine as the next major UI opportunity: [owner intent](../research/ui-quality-engine/OWNER-INTENT.md) and [recommendations](../research/ui-quality-engine/RECOMMENDATIONS.md). Proposed order: **v1.44 sync → v1.45 foundation and CI (plus the engine's prerequisites) → v1.46 UI engine and pilot → v1.47 UI surfaces and polish → v1.48 adopter features.**

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

## 4. v1.46 UI quality engine and pilot (proposed)

- **Fixtures:** a `fixtures/scrypath_fixtures` path dependency (dev/test only) with five adopter profiles and 12 invariant tests. It replaces both `Phase173FixtureSource` copies.
- **Story harness:** hand-rolled in `scrypath_ops`, with no new dependencies. It has a manifest and ExUnit gates: every variation renders, every variation is described, every component is covered, and no two variations render identically. Primitive and group stories cover `OpsUi`.
- **Pilot:** extract Search health and Control room into area components over pure view-models, keeping pixels the same.
- **Checks:**
  - the L2 browser sweep over the manifest, advisory until 14 clean nights;
  - the `copy_rules.json` lint with a shrink-only baseline;
  - the `ui-decisions.jsonl` decisions log.
- **Cleanup:** port the `phase173_*` specs onto stories and delete the `phase173` fixture mode.

## 5. v1.47 UI surfaces and polish (proposed)

- Extract Search, then Failed sync work, then Sync and index, with area, section and page stories for each.
- L3 element screenshots get one pinned Linux baseline.
- The L4 judge becomes a bounded, agent-run pairwise skill, calibrated on `UI-FEEDBACK.md`.
- Each section gets one rubric review.
- Copy and design fixes are batched for the maintainer's yes.

## 6. v1.48 adopter features (was v1.46)

Scope guard, exactly these five: a testing kit (`Scrypath.Testing`); a `search_indexable?/1` predicate (which also covers soft deletes); highlighting/cropping passthrough (`per_query` allowlist, `_formatted`); `pagination.max_total_hits` and `faceting.max_values_per_facet` settings plus a guard; `mix scrypath.backfill` and `mix scrypath.reindex`.

Still out of scope: vector/hybrid search, autocomplete, callback or Repo-hook auto-sync, automatic association walking, a public multi-backend facade.

**Grill the maintainer on the API shapes before starting this milestone.**

## Later

- Backend seam: `case backend do Scrypath.Meilisearch -> ...` bypasses the adapter in seven places (`sync.ex`, `backfill.ex`, `operator/index_contract_drift.ex`, `operator/status.ex`, `operator/reconcile.ex`, `operator/failed_work/retrieval.ex`).
- Contract-test sprawl.
- Throttling, geo search.
- Release-please app token (deferred; keep the close+reopen nudge).

## Known open items

- `deep-quality (advisory)` is red only on the `scrypath_ops` graph: `cloak` 1.1.4 and `cloak_ecto` 1.3.0 come in through optional `sigra ~> 1.5.0`, and no fixed release exists. An ignore can't help, because `scripts/ci/dependency_audit.ex` treats any ignore as failed by design. When sigra ships `cloak_ecto` as optional, bump sigra in `scrypath_ops/mix.exs` and refresh the lock with Hex 2.5 or newer.
- The maintainer's untracked `examples/scrypath_ecommerce/priv/playbooks/my-search.json` stays untouched.
