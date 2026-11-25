# v1.50 correctness: fix, defer or drop

Static only (no mix, Docker or database) on `chore/patch-dependency-advisories`. Meilisearch facts: official docs, v1.15.2 source (`MS:` = `github.com/meilisearch/meilisearch/blob/v1.15.2/crates/`), repo recordings. S = under one plan, M = 1 to 2 plans.

**Bottom line:** two defects outrank most of the listed findings: a new one (F5, Oban jobs are never read) and F4, which is worse than recorded.

## F5 (new): operator APIs report an empty Oban queue. FIX, first

- Evidence: with no `oban_inspector`, `lib/scrypath/oban/inspect.ex:11-12` returns `[]`; `operator/status.ex:112` still says `observed?: true`. Grep finds no built-in inspector, runtime option, CLI switch or guide mention. The only real one is demo code (`examples/scrypath_ecommerce/.../e2e_controller.ex:1-33`). `guides/operator-mix-tasks.md:28` and `sync-modes-and-visibility.md:85` promise backlog and failed jobs.
- Impact: every `:oban` user (the recommended production path) without an undocumented module sees discarded jobs as clear; Mix retry cannot find them. Certain.
- Fix (M): default inspector via `Oban.config/1` and `Oban.Repo` (prefix aware, no new dependency): Scrypath workers, this schema, bounded per state with a truncated flag. No running instance: `observed?: false`.
- Compatibility: explicit `oban_inspector`/`oban_jobs` unchanged; others newly see failures and retry recommendations. Changelog note.
- Planted test: SQLite Oban harness, one discarded upsert job, no inspector; `failed_sync_work/2` must return it (today `[]`).

## F1: task history over 1,000 is an error. FIX

- Verified: `meilisearch/tasks.ex:12,79-81`. Meilisearch cleans up only at 1,000,000 tasks (`MS:index-scheduler/src/queue/mod.rs`, `cleanup_task_queue`; `MS:meilisearch/src/lib.rs:229`).
- Impact: near certain on a live index (one inline sync is one task). `sync_status`, `failed_sync_work`, `reconcile_sync`, four Mix tasks and ops screens fail, queue data included (`status.ex:55`, `retrieval.ex:14`). Workaround `task_history_limit` is absent from guides, loads everything, and ScrypathOps cannot set it (`schemas.ex:11-13`).
- Fix (M): query by `statuses`: pending, failed/canceled (each newest N), latest succeeded. Never error on size; add `truncated?` to `Status.backend`, `FailedSyncWorkInspection` and telemetry. Same for reindex visibility. An empty result stays exact, so "Clear" cannot come from a partial read. This keeps recorded v1.37 SAFE-05 (bounded, explicit partial).
- Also drop `indexSwap` from the filtered query (`tasks.ex:26`). Source reading: Meilisearch applies `limit` before removing swaps (`MS:index-scheduler/src/queue/tasks.rs`), and derives `next` from page length (`MS:meilisearch/src/routes/tasks.rs`). A swap inside the newest page therefore silently ends pagination.
- Compatibility: `{:error, {:task_history_truncated, _}}` stops occurring; a plain failed-work list can be the newest N. Update fixtures (fake client lacks `statuses`).
- Test: 1,200 successes plus one older failure returns `ok` with the failure; today errors.

## F4 and the golden-path lead: CONFIRMED statically. FIX

The filtered, sorted search at `guides/golden-path.md:139-140` should fail on a fresh install. Three independent breaks:

1. **No settings step.** The guide never applies settings or reindexes. Upsert sends documents only (`meilisearch/operations.ex:14-34`); settings are written only by `settings.ex:194,294`.
2. **`sortable:` never sent.** `settings.ex:15-35` merges only filterable and facets. Adding a reindex step would not fix sort.
3. **Fields not projected.** `golden-path.md:66-68` declares `fields: [:title, :body]`; `projection.ex:73-83` sends only those plus id. `status` and `inserted_at` are absent.

Meilisearch [error codes](https://www.meilisearch.com/docs/reference/errors/error_codes): attributes outside `filterableAttributes`/`sortableAttributes` give `invalid_search_filter`/`invalid_search_sort`; both default empty (recordings `16`, `21`). After settings alone, the status filter would succeed with zero hits.

Same pattern: `getting-started.md:24,81`, `phoenix-walkthrough.md:16,76`. README's search (page only) is unaffected. CI misses it: the live reindex test passes `sortableAttributes` by hand (`live_meilisearch_verification_test.exs`), the tenant example never sorts.

- Further impact: managed reindex builds a target without declared sortables, so hand-set sorting breaks at cutover.
- Fix (S/M): union `sortable:` into `resolve/2`; compare `sortableAttributes` and `stopWords` as sets. Meilisearch returns both as sorted sets (`MS:meilisearch-types/src/settings.rs:220,233`) while `compute_drift` compares order, so two sortables could fail reindex verification (unsorted stop words likely already do). Docs: add both fields, add a settings step (`apply_settings` needs `meilisearch_url:` explicitly, `meilisearch.ex:111`; wait on its task). Consider a compile warning for filterable/sortable outside `fields` when no `search_document/1`.
- Compatibility: next apply changes live settings; `settings.diff` may newly report drift.
- Tests: captured payload contains sortables; live golden-path schema, no override, two reverse-ordered sortables; guide contract that these are in `fields`.

**Minimal reproduction** (disposable Meilisearch v1.15): add `[{"id":1,"title":"hello","body":"x"}]` to an index, wait; search with `filter: ["status = \"published\""]`, then `sort: ["inserted_at:desc"]`; expect the two 400s. Then through Scrypath with the guide schema: inline `sync_record`, search (400), `apply_settings`, wait; expect `sortableAttributes: []` and zero filtered hits.

## F2: unbounded error text. FIX (S)

- Verified: `translation.ex:112-120` (queue reasons are capped at 500, line 7); full text in page and copy attribute (`failed_sync.ex:280`, `ops_ui.ex:1490`). Meilisearch serializes the whole document into `missing_document_id` (`MS:milli/src/error.rs:261`; recordings `08`, `09`).
- Impact: customer data on screen and clipboard, bidi spoofing, large DOM. Not XSS (HEEx escapes). Low to medium: needs a bad id (an email as id is plausible) or key mismatch.
- Fix: one cap-and-neutralize-bidi helper in the library for both sources; cover raw `inspect` output (`failed_sync.ex:608`, `recovery.ex:138`, promotion copy, multi-search failures). Full text stays in Meilisearch by task uid.
- Compatibility: shorter `reason`. Test: recording `08` yields no raw U+202E; a 5,000-character message yields at most 500.

## D2: receipts live in one LiveView. DEFER persistence, fix wording (S)

- Verified: `failed_sync_live.ex:40,205,306`; observer TTL 10 minutes. Reload offers Retry again. Harm is limited: retries reload current records; unique collapses pending duplicates (`enqueue.ex:109`).
- But `conflict?` is ignored, so "Retry queued" (`:339`) can be false; a `retryable` job with identical args may collapse into itself (check at runtime).
- Fix: say "an identical job is already waiting" on conflict; test with a conflicting fake. Persistence needs a migration; revisit on a multi-node report or ops on Hex.

## F3: swaps invisible. FIX LAST (cut line)

- Verified: Meilisearch deliberately excludes `indexSwap` under `indexUids`, and for index-scoped keys (`queue/tasks.rs`; recordings `27-29`). Cutover always reads `not_started`.
- Static hazard: nothing in `PromotionEligibility` appears to stop a second promotion after cutover, putting old data live (`sync_drift_live.ex:1139`).
- Fix (M): one unfiltered `types=indexSwap` read, match `details.swaps`; completed only if newer than the target's latest task. Must also change `reconcile.ex:219`, or completed cutover recommends reindex forever. Document that scoped keys cannot see swaps. Report values change. Test from recordings.

## Low items

| Item | Call |
|---|---|
| `search_live.ex:122` bypasses `return_to_path/1`; query control characters | Fix with F2; consistency only |
| Catalog `check_origin: false` (`dev.exs:91`) | Fix, one line: keys are committed and stories render server side, so origin check is useful depth. It does not stop HTTP reads. Test a foreign Origin |
| `dashboard_routes` guard (`dev_router.ex:5-7`) | Defer until LiveDashboard leaves dev-only |
| Bundle/image extras, WR-03/04, remaining IN items | Defer until ops publishes or tests next change |
| Missing `:backend` raises; `:not_checked` collapse | Drop: programmer error; unreachable |

## Adversarial pass

- "F5 is an intentional seam": it still claims observation, and Mix users cannot supply it.
- "Partial history creates false health": only counts and old rows are windowed; state it.
- "Built-in queries are fragile": test SQLite and Postgres; use Ecto JSON access.
- "No adopter reported these": F4 is on the first-hour path.
- "Everything is static": reproduce F4, F5, F1 before planning.

## Ordered recommendation

1. Reproduce (one short session).
2. F5.
3. F1, including the `indexSwap` removal.
4. F4 plus guides.
5. F2, D2 wording, small ops fixes.
6. F3; cut if the milestone runs long.

Release 2 to 5 as one patch (0.3.21) with upgrade notes, only on the maintainer's yes. **Ask first:** these are root `lib/` changes (FLOW-02), and the rolling roadmap records v1.50 as "Adopter-ready". Recommend correctness leads that slot, with its guide and fresh-consumer walk following; that reorder is the maintainer's call.

**Leads to check in the same session, unverified:** a second managed reindex may fail because the partner index is never deleted (`reindex.ex:41`); partial `typo_tolerance` may fail verification; first sync with `id` plus `tenant_id` may fail primary-key inference (upsert sends no `primaryKey`).

**Confidence:** F5, F1, F4 about 0.9; ordering 0.75. A runtime repro that passes, a documented inspector I missed, or an adopter report would reorder.
