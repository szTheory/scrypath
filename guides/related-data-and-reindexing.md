# Related data and reindexing

This guide is for the Phoenix or Ecto team that has moved beyond flat documents and now needs to answer the uncomfortable real-app question:

**What should happen when a record changes data that lives in someone else's search document?**

Examples:

- an `Author` name changes and post documents store `author_name`
- a `Tag` is renamed and product documents store tag labels
- an account changes status and many searchable child records should now filter differently
- a support ticket changes teams and search documents store team metadata

The short version is simple:

**Scrypath does not hide cross-record invalidation behind callback magic. Your app owns the fan-out.**

That is the least-surprise Ecto shape, and it keeps recovery honest when the blast radius is larger than one row.

## The rule of thumb

Use simple `Scrypath.sync_record/3` when the changed row is the same row that owns the search document.

Reach for explicit fan-out when:

- the indexed document includes data from associated records
- a shared lookup table changes many documents at once
- a permission or tenant boundary change affects search visibility
- the shape of the document changed and you no longer trust the live index

If you remember one sentence from this guide, make it this:

**Find affected source records explicitly, then sync or rebuild them deliberately.**

## Three kinds of related-data changes

### 1. One changed row, one changed document

This is the easy case.

Example:

- a `Post` title changes
- a `Customer` email changes
- a `Ticket` status changes and the document is built from the ticket row itself

Do this:

- persist the row in your context
- call `Scrypath.sync_record/3` for that row

You do not need a broader recovery workflow unless the sync fails or the contract changed.

### 2. One changed row affects many other documents

This is the common real-app footgun.

Example:

- an `Author` rename should update every searchable post that stores `author_name`
- a `Category` label change should update every product document that stores category names
- an organization rename should update many user-facing result documents

Do this:

- persist the changed row in its owning context
- query for the affected source records explicitly
- sync those source records in a deliberate follow-up step

In Ecto terms, this usually means:

- identify the source schema that owns the search document
- build one query that finds affected records
- decide whether the follow-up should be inline, queued, or manual

The important thing is what you do **not** promise:

- no hidden association walking
- no automatic preload magic
- no assumption that a related-row change is cheap

## 3. The document contract changed

Sometimes the question is not "which records changed?"

Sometimes the question is:

**Do I still trust the live index at all?**

Examples:

- you added or removed projected fields
- you changed filterable, sortable, or faceting declarations
- you changed settings in a way that implies a rebuild
- you cannot confidently enumerate every affected record

That is no longer a simple fan-out job.

This is when you move from sync into repair or rebuild:

- use index-contract drift or reconcile when you need posture first
- use backfill when the live index is still trustworthy and just needs repair
- use managed reindex when the contract changed or the live index no longer deserves trust

## A Phoenix context shape that stays honest

The clean shape is still:

- the owning context persists the original change
- the owning context decides whether there is fan-out work
- the context chooses the follow-up sync mode or operator path

For example, if posts own the search document but authors affect post documents:

1. `Accounts` updates the author
2. `Accounts` or a small orchestration boundary identifies affected posts
3. that boundary syncs those posts explicitly

The exact module split can vary. The important invariant is that web modules still do not own this logic.

## Picking the right follow-up path

### Small, user-visible fan-out

Good fit:

- a bounded number of affected rows
- the caller benefits from knowing the update finished now

Default:

- inline follow-up, if latency is acceptable

### Larger fan-out with ordinary production traffic

Good fit:

- many affected rows
- request latency matters
- your app already treats Oban as normal production infrastructure

Default:

- durable enqueue with `:oban`

Truth you can say:

- "the follow-up work is durably queued"

Truth you cannot say:

- "all affected documents are searchable now"

### Bulk repair, imports, or uncertain blast radius

Good fit:

- imports
- large migrations
- staged operator work
- situations where you want to inspect before cutover

Default:

- manual flow, backfill, or managed reindex

## Deletes are their own category

Deletes are where many libraries get hand-wavy. Scrypath should not.

If a source row is gone, a later async delete job may not be able to reload it. That is normal. The safe pattern is:

- carry enough identity to delete the document directly from the index
- do not depend on reloading the deleted source row later

When stale deletes still appear:

- inspect failed work
- inspect reconcile and drift posture
- decide whether one explicit retry is enough or whether the index needs broader repair

## Tenant and permission changes are related-data changes too

In SaaS apps, not every related-data change is cosmetic.

Sometimes the changed data affects **who should be able to see the document at all**.

Examples:

- a record moves tenants
- a team membership change affects searchable visibility
- a role or account-status change changes which rows should appear

Treat these as higher-risk related-data events:

- be explicit about the tenant boundary in app code
- be explicit about which source records are affected
- prefer a repair or rebuild workflow when the visibility model changed broadly

Scrypath can help with sync, search, and recovery. It should not pretend index prefixes alone are your authorization model.

## When to choose backfill versus reindex

Use this shortcut:

- **backfill** when the live index contract is still right and the data just needs repair
- **reindex** when the contract changed or you no longer trust the live index

Examples where backfill is usually right:

- a queue outage delayed some updates
- a bounded set of related-data fan-out jobs failed
- the document shape is unchanged and you trust the current index settings

Examples where reindex is usually right:

- projected fields changed broadly
- filterable or faceting declarations changed
- settings changed in a way that implies a rebuild
- you cannot confidently identify all affected source records

## A practical decision tree

Ask these questions in order:

1. Did the changed row own the document directly?
2. If not, can I clearly query the affected source records?
3. Is the blast radius small enough for normal sync, or is this now repair work?
4. Do I still trust the live index contract?
5. What truth do I need to be able to say when this function returns?

That yields the usual outcomes:

- direct sync
- explicit fan-out sync
- queued fan-out sync
- backfill
- managed reindex

## What Scrypath should stay opinionated about here

These are the least-surprise defaults:

- contexts own orchestration
- related-data propagation is explicit
- request-edge helpers do not own fan-out logic
- `use Scrypath` stays metadata-only
- recovery is public and documented

The tempting alternative is callback magic. That shape feels easy until the first production drift incident. Then it becomes hard to reason about, hard to test, and hard to repair.

## Read next

- [JTBD and user flows](jtbd-and-user-flows.md)
- [Sync modes and visibility](sync-modes-and-visibility.md)
- [Drift recovery](drift-recovery.md)
- [Operator Mix tasks](operator-mix-tasks.md)
