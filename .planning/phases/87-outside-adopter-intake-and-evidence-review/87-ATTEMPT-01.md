## Provenance
Source artifact: .planning/phases/87-outside-adopter-intake-and-evidence-review/87-SUBMISSION-01.md
- submitted by: @realistic_adopter_1
- date received: 2026-05-24
- outside adopter: true

# Outside-Adopter Evidence Bundle

Please use this template to submit evidence of a failed or confusing outside-adopter integration attempt. Provide exact commands run and the first failure point. 

## Adopter Context
Adding Scrypath to an existing SaaS app. I have a `Post` schema that has many `Comments`. My search index is built around `Post`, but the `search_document/1` includes a string of aggregated comment text. When a `Comment` is inserted or updated, the `Post` index is not updating. I'm trying to figure out how to propagate the change from the `Comment` Ecto lifecycle to the `Post` index without writing manual Oban jobs or Ecto.Multi steps for every child relation.

## Environment Matrix
- **OS / Architecture:** macOS ARM64
- **Elixir version:** 1.15.7
- **OTP version:** 26.1
- **Meilisearch version:** 1.42.1
- **Database (if applicable):** PostgreSQL 15

## Scrypath Ref or Hex version
Hex package `0.3.5`

## Chosen Proof Path
Integrating the Hex-package into an existing app.

## Sync Mode
`:oban`

## Ordered Commands
1. Insert a new `Post` (it syncs to Meilisearch).
2. Insert a new `Comment` belonging to that `Post`.
3. Search for a word present in the new comment via `Scrypath.search/2`.

## Expected versus Actual Outcome
I expected the `Post` returned in the search results, but it returned no results because the `Post` document in Meilisearch was never re-synced after the comment was added. 

## First Failure/Confusion Point
The first failure/confusion point: I realized Scrypath's `Scrypath.Ecto.Searchable` hooks only listen to the parent schema (`Post`). There is no documented or clear declarative way to say "when a `Comment` changes, re-project and re-sync its parent `Post`". The library lacks an explicit association propagation or dependency graph feature, leaving me to build my own manual reindex trigger on the child schema.

## Supporting Logs
```text
[debug] QUERY OK db=2.1ms
INSERT INTO "comments" ("post_id", "body", "inserted_at", "updated_at") VALUES (1, 'This is a new comment', ~U[...], ~U[...]]

# No Oban job is enqueued for Scrypath to update the Post index here.
```

## Maintainer Review Block
*For maintainer use only.*
- **Classification:** Class A
- **Findings:**
  - `product gap`: The library lacks an automatic association propagation/dependency graph feature for reindexing parent documents when child Ecto relations change.
  - `docs/onboarding gap`: Adopters are not given clear instructions on how to use custom Oban jobs to handle child relation updates without building manual Ecto.Multi structures.
- **Action:** Add to evidence ledger as a Class A finding mapping to related-data propagation.
