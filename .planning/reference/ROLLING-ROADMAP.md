# Rolling roadmap (approved 2026-10-24)

The maintainer approved this order and these working rules after a research fan-out and a grilling round. Pick up the first unfinished item. `STATE.md` records progress.

## Working rules

- One PR per coherent slice. Squash-merge it once the required checks (`core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted`) pass. `deep-quality (advisory)` is expected to be red until sigra makes `cloak_ecto` optional; see below.
- Hex releases and visible UI changes wait for the maintainer's explicit yes. A release-please PR needs a close and reopen before its CI runs.
- One lean plan per milestone (a section in this file is enough). Tests and CI are the proof. No per-phase GSD document sets, no manual UAT.
- Prefer copying a small helper over adding a dependency.

## 0. 0.3.17 hotfix — done

PR #114 lets pre-0.3.16 Oban upsert jobs write their stored snapshot when the app can't reload records, instead of cancelling them. It also adds an upgrade note saying Oban mode needs `:repo`. Released as 0.3.17 (#115).

## 1. v1.43 closeout — automated only

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

## 3. v1.45 foundation and CI

- Fix the false claim in older STATE text: the 19 standalone `phase173_*` specs are **not** run anywhere (nothing invokes `verify-phase173.sh`). In `verify-e2e.sh`, add `-f compose.phase173.yaml` when scope is `full`, and raise the timeout to 30 minutes. This also fixes the nightly `ecommerce-e2e`, red since 2026-10-13.
- Give the 13 skipped specs (`ui_followup.spec.ts` 8, `ui_iteration3.spec.ts` 6) the same port guard `ui_baseline` uses, so they run.
- Move the ~44 maintainer `verify.*` mix tasks out of the Hex package into `dev/mix/tasks`, and update the package parity gate with them.
- Root deps: declare `{:telemetry, "~> 1.0"}`, and allow `req` `~> 0.6.1 or ~> 0.7` (Dependabot #73).
- scrypath_ops deps: drop swoosh/Mailer; make phoenix_live_dashboard and telemetry_poller/metrics dev- or standalone-only; set esbuild/tailwind to `only: :dev`; loosen the sigra pin.
- CI caching: buildx GHA cache and `restore-keys`.
- Fold the open Dependabot PRs (#65, #68–#76) into this milestone instead of merging them one by one.

## 4. v1.46 adopter features

Scope guard, exactly these five: a testing kit (`Scrypath.Testing`); a `search_indexable?/1` predicate (which also covers soft deletes); highlighting/cropping passthrough (`per_query` allowlist, `_formatted`); `pagination.max_total_hits` and `faceting.max_values_per_facet` settings plus a guard; `mix scrypath.backfill` and `mix scrypath.reindex`.

Still out of scope: vector/hybrid search, autocomplete, callback or Repo-hook auto-sync, automatic association walking, a public multi-backend facade.

**Grill the maintainer on the API shapes before starting v1.46.**

## Later

- Backend seam: `case backend do Scrypath.Meilisearch -> ...` bypasses the adapter in seven places (`sync.ex`, `backfill.ex`, `operator/index_contract_drift.ex`, `operator/status.ex`, `operator/reconcile.ex`, `operator/failed_work/retrieval.ex`).
- Contract-test sprawl.
- Throttling, geo search.
- Release-please app token (deferred; keep the close+reopen nudge).

## Known open items

- `deep-quality (advisory)` is red only on the `scrypath_ops` graph: `cloak` 1.1.4 and `cloak_ecto` 1.3.0 come in through optional `sigra ~> 1.5.0`, and no fixed release exists. An ignore can't help, because `scripts/ci/dependency_audit.ex` treats any ignore as failed by design. When sigra ships `cloak_ecto` as optional, bump sigra in `scrypath_ops/mix.exs` and refresh the lock with Hex 2.5 or newer.
- The maintainer's untracked `examples/scrypath_ecommerce/priv/playbooks/my-search.json` stays untouched.
