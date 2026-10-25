---
phase: 179-bounded-id-lists-and-related-sync-parity
plan: 06
subsystem: docs
status: complete
tags: [docs, fan-out, chunking, oban, fan-01, fan-02, fan-03, page-03]
requires:
  - 179-02 (chunked backfill writes, tasks on batch results)
  - 179-05 (RelatedWorker loads triggers, related enqueue chunked and unique)
provides:
  - "guides/related-data-and-reindexing.md §(c) What your resolver receives"
  - "guides/sync-modes-and-visibility.md ### Large id lists plus :inline/:oban/:manual chunk notes"
  - ":tasks bullet and halt sentence in @sync_public_ops_doc; resolver-input sentences in sync_related/3 @doc"
  - "Scrypath.Oban moduledoc note on Multi helpers (resolved OQ1)"
  - "PROJECT.md v1.44 Active items for Phase 179"
  - "Release note text (below) for the phase PR, squash commit body and release PR"
affects: [179-07]
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified:
    - guides/related-data-and-reindexing.md
    - guides/sync-modes-and-visibility.md
    - lib/scrypath.ex
    - lib/scrypath/oban.ex
    - .planning/PROJECT.md
decisions:
  - "The guide's :oban sync_related example now passes repo: MyApp.Repo, because 179-05 made related enqueue raise without a repo or search_records/2"
  - "The :oban failure table gains an all-triggers-missing row (:ok, resolver not called) and widens the cancel row to undecodable job args"
  - "CHANGELOG.md is not edited (resolved OQ6); the upgrade sentence lives in this SUMMARY's Release note"
metrics:
  duration: ~15m
  completed: 2026-10-25
estimate:
  tokens: 30000
  tasks: 2
actuals:
  tokens: 5500
  tasks: 2
  commits: 2
plan_head_before: 655e79853f12677b43e738e6b31a2a134c58f0e2
plan_head_after: 4982240c2776df5c252bbff9ade3981aacb6f0cd
---

# Phase 179 Plan 06: Docs for resolver records, chunked sync and job collapse Summary

The resolver guide now teaches one shape: resolvers get owning-schema records in every sync mode. The sync-modes guide explains the new behaviour: 1000-id chunks, `tasks:`, stopping at the first failed chunk, per-chunk `inline_timeout`, and Oban job collapse with `conflict?: true`. The public `@doc`s, the `Scrypath.Oban` moduledoc and PROJECT.md now match.

## What was built

- **`guides/related-data-and-reindexing.md`**
  - `#### (c) Write an arity-safe resolver (the #1 footgun)` is now `#### (c) What your resolver receives`. The example has a single `[%Author{} | _]` clause, and the guide says old id-taking clauses are dead code and safe to remove.
  - The section explains how Oban carries the trigger "document IDs" and reloads them through `preload:` / `search_records/2`. It also covers:
    - deleted and soft-deleted triggers are skipped, and a job whose triggers are all missing succeeds without calling the resolver; `Scrypath.sync_records(Post, posts)` hides their targets
    - call `sync_related/3` after the write commits
    - under inline, a deleted struct is still passed to the resolver; an empty trigger list is a noop
    - triggers are deduped, at most 1000 per job, with no ordering contract
    - the `:oban` path needs `repo:` or `search_records/2`; tenant-scoped owners should define `search_records/2`
    - a hand-written owner-only `__scrypath__/1` keeps working
  - The `apply/3` sentence in (a) no longer says the first argument differs by mode.
  - The `:oban` example in (b) passes `repo: MyApp.Repo`.
  - The `:oban` failure table has a new all-triggers-missing row, and its cancel row now includes undecodable job args.
- **`guides/sync-modes-and-visibility.md`**
  - New `### Large id lists` under The Contract (D-01/D-03/D-06/D-07): dedupe, fixed chunks of at most 1000, in-order chunks that stop at the first failure, sent chunks stay applied, `tasks:` per chunk with `task:` as the last, and set semantics with no ordering.
  - `:inline`: Scrypath waits on each chunk before sending the next, and `inline_timeout` applies per chunk. Inline sync of more than 1000 ids inside a request is flagged as a smell; use `:oban` instead.
  - `:oban` / What an Oban job carries (D-04/D-20/D-21): one job per chunk, inserted in one transaction. An identical pending job collapses and is reported with `conflict?: true`. The `Scrypath.Oban.enqueue_upsert/5` and `enqueue_delete/5` Multi helpers still add one job per step, and the worker bounds each write (OQ1).
  - `:manual` (D-08): every chunk is sent without waiting. A successful `task:` does not prove earlier chunks succeeded, so check every `tasks:` entry.
- **`lib/scrypath.ex`**
  - `@sync_public_ops_doc` has a `:tasks` paragraph covering per-chunk tasks or jobs, `:task`/`:job` as the last, the manual check, and stop at the first failed chunk.
  - The `sync_related/3` `@doc` says resolvers receive loaded records in every mode and that Oban reloads them and skips missing ones.
- **`lib/scrypath/oban.ex`**: the moduledoc says the Multi helpers add one job per step and do not split ids.
- **`.planning/PROJECT.md`**: three v1.44 Active items are now `[x] — Phase 179 (verified locally; unreleased)`: resolver records, chunking, and related uniqueness with safe decoding. The footer's last-updated line names Phase 179.

## Tasks

| Task | Name | Commit |
| ---- | ---- | ------ |
| 1 | Tracer: rewrite §(c) as "What your resolver receives" and prove the docs contracts stay green | 1c5cc49e |
| 2 | Sync-modes guide, public sync docs, Oban Multi note, PROJECT.md | 4982240c |

Tracer gate (Task 1): `mix verify.phase108` (6 tests) and `mix test test/scrypath/docs_contract_test.exs --include docs_contract` (74 tests) both passed with 0 failures before Task 2 started. Neither test file was edited.

## Verification

- `mix verify.phase108`: 6 tests, 0 failures (after both tasks)
- `mix test test/scrypath/docs_contract_test.exs --include docs_contract`: 74 tests, 0 failures
- `mix docs --warnings-as-errors`: exit 0. The compile warnings printed during the run come from the `oban` dependency (`lib/oban/repo.ex`), not from ExDoc.
- `mix format --check-formatted`: exit 0
- Full `mix test`: 897 tests, 5 properties, 0 failures (26 excluded)
- Acceptance greps:

  | Grep | Count |
  | ---- | ----- |
  | `What your resolver receives` (related guide) | 1 |
  | `arity-safe\|both arities\|both shapes` (related guide) | 0 |
  | `def resolve_posts_for_authors([_id` (related guide) | 0 |
  | `document IDs` (related guide) | 1 |
  | `conflict?` (sync-modes guide) | 1 |
  | `inline_timeout` (sync-modes guide) | 1 (baseline 0) |
  | `tasks:` (sync-modes guide) | 3 |
  | `Phase 179` (PROJECT.md) | 4 |
  | `git diff --name-only 655e7985 HEAD -- CHANGELOG.md` | empty |

## Release note

Upgrade notes (for the phase PR body, the squash commit body and the release PR's CHANGELOG `### Upgrade notes` block, as 0.3.16 did; do not use a `BREAKING CHANGE:` footer):

- Oban `sync_related` resolvers now receive loaded trigger records instead of document ids. Existing id-taking resolver clauses are dead code and safe to remove; triggers that no longer load are skipped. Sync results gain `tasks:` (one per chunk of up to 1000 ids). See [guides/related-data-and-reindexing.md](guides/related-data-and-reindexing.md).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Correctness] The `:oban` `sync_related` example needed `repo:`**
- **Found during:** Task 1
- **Issue:** After 179-05, `RelatedEnqueue` calls `Loader.ensure_loadable!/2`. The guide's copy-paste `:oban` example had no `repo:`, so it would raise `needs :repo` on any schema without `search_records/2`.
- **Fix:** The example now passes `repo: MyApp.Repo`, and §(c) explains the requirement.
- **Files modified:** guides/related-data-and-reindexing.md
- **Commit:** 1c5cc49e

**2. [Rule 2 - Correctness] The `:oban` failure table did not describe 179-05 outcomes**
- **Issue:** The table did not mention the all-missing `:ok` outcome or cancels for undecodable args (FAN-03).
- **Fix:** Added one row and widened the cancel row's wording.
- **Commit:** 1c5cc49e

### Notes

- `examples/phoenix_meilisearch` still has the two-arity resolver (`blog.ex`, `blog/author.ex`). Those files belong to plan 179-07, which runs in parallel, so this plan did not touch them.

## Known Stubs

None.

## Threat Flags

None. T-179-17 is mitigated because §(c) tells tenant-scoped owners to define `search_records/2`. T-179-18 is mitigated because the guide and `@sync_public_ops_doc` both say to check every `tasks:` entry under `:manual`.

## Self-Check: PASSED

- FOUND: guides/related-data-and-reindexing.md, guides/sync-modes-and-visibility.md, lib/scrypath.ex, lib/scrypath/oban.ex, .planning/PROJECT.md
- FOUND commits: 1c5cc49e, 4982240c (both ancestors of HEAD)
