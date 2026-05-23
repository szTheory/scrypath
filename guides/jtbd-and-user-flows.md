# JTBD and user flows

This guide is for the Phoenix or Ecto engineer who wants to use Scrypath in a real app and wants the library to make sense before wiring more code.

The short version: Scrypath is for teams who already trust Postgres and Ecto as the source of truth, but want search to feel native instead of bolted on. It does not promise magic. It gives you an explicit way to project records into search documents, keep them in sync, query them back through one common path, and recover when reality gets messy.

If you want the copy-paste first hour, start with the [Golden path](golden-path.md). This guide is the mental model and flow map.

## The core job

The job is not "run a search query."

The real job is:

**Keep a search-shaped read model in sync with Ecto data without lying about consistency, rebuilds, or recovery.**

That one sentence explains most of the library shape:

- schemas declare what a search document looks like
- contexts decide when sync happens
- search returns both hits and hydrated records
- operators get explicit tools for drift, failed work, backfill, and reindex

If you want hidden callbacks that whisper "trust me, it's indexed," Scrypath is the wrong tool.

## The mental model

Think in six steps:

1. Your **Ecto schema** declares search metadata with `use Scrypath`.
2. Your **context** decides when a repo write should trigger search sync.
3. Scrypath builds a **search document** from the source record.
4. The backend stores that document in the current search index.
5. `Scrypath.search/3` queries that index and returns raw hits plus hydrated records.
6. If the index drifts from the database, you use **status, failed-work, backfill, or reindex** to recover deliberately.

The database is still the source of truth. The search index is a derived system you keep honest.

## Flow 1: "Get search working on one schema without inventing an indexing subsystem"

This is the first-hour job.

Picture a SaaS app with `Post`, `Ticket`, or `Customer` records. You already have an Ecto schema and a Phoenix context. You want one search box and you do not want to redesign the app around search.

What Scrypath gives you:

- a metadata declaration on the schema
- one context-owned call to `Scrypath.sync_record/3` after a successful write
- one context-owned call to `Scrypath.search/3` for reads

What success means:

- creating or updating the record can push a corresponding search document
- searching returns hydrated repo records in hit order
- controllers or LiveView stay thin

What success does not mean:

- the database and search write are suddenly atomic
- the library will discover your repo or web boundary for you

This is why the [Golden path](golden-path.md) starts with one schema, one context, and `sync_mode: :inline`.

## Flow 2: "Choose the right sync honesty for this feature"

This is usually the first serious design decision.

The question is not "which mode is best?"

The question is:

**When this write returns to my app, what truth do I want to be able to say out loud?**

### `:inline`

Use this when the caller should wait for terminal backend task success.

Good fit:

- local development
- first adoption
- admin or internal workflows where a slower write is acceptable

Truth you can say:

- "the backend finished the indexing task before I returned"

Truth you still cannot say:

- "the database write and search write were one atomic transaction"

### `:oban`

Use this when durable enqueue matters more than immediate visibility.

Good fit:

- higher write volume
- user flows where request latency matters
- production systems already comfortable with Oban

Truth you can say:

- "the indexing job is durably queued"

Truth you still cannot say:

- "the document is searchable right now"

### `:manual`

Use this when a human or explicit workflow should control the next step.

Good fit:

- imports
- migrations
- large repair jobs
- staged operator workflows

Truth you can say:

- "the backend accepted the work"

Truth you still cannot say:

- "the index is already caught up"

The canonical semantics live in [Sync modes and visibility](sync-modes-and-visibility.md). The mental shortcut is simple: **accepted work is not the same thing as visible search results.**

## Flow 3: "Add search to a normal Phoenix screen without contaminating controllers or LiveView"

This is the everyday application flow.

You have a controller action or LiveView page for something like:

- searching support tickets
- browsing published posts
- filtering customers by status
- finding users by name and email

The clean Scrypath shape is:

- params enter at the web edge
- the context turns those params into one `Scrypath.search/3` call
- Scrypath returns hits, records, paging, and any missing ids
- the web layer renders the result honestly

What this buys you:

- search stays a context concern, not a controller trick
- hydration is explicit, so stale search hits do not silently vanish
- search options stay close to app rules like preloads, allowed filters, and sort defaults

The relevant follow-on guides are [Phoenix walkthrough](phoenix-walkthrough.md), [Phoenix contexts](phoenix-contexts.md), [Phoenix controllers and JSON](phoenix-controllers-and-json.md), and [Phoenix LiveView](phoenix-liveview.md).

## Flow 4: "Build a catalog search experience, not just a search box"

This is where search starts feeling like product surface instead of plumbing.

Picture a marketplace or media app:

- products by brand, category, and price
- listings by city and status
- movies by genre, year, rating, and director

Now the job is not just text search. The job is:

**Help users narrow a large result set without losing the shape of the catalog.**

Scrypath's current catalog flow supports:

- declared facet attributes on the schema
- `facets:` and `facet_filter:` on the common search path
- hierarchical facets
- disjunctive facet-count merge helpers
- `search_within_facet/4` for "search inside this bucket"

What it deliberately preserves:

- LiveView owns UI state and URL state
- your context still owns the Scrypath call
- facet counts and filters are explicit, not hidden behind a giant UI abstraction

Read [Faceted search with Phoenix LiveView](faceted-search-with-phoenix-liveview.md) when your app moves from "search page" to "browse and refine."

## Flow 5: "Search across several kinds of records without pretending they are one index"

This is the global-search or dashboard job.

Examples:

- one search bar across posts, users, tags, and events
- an internal admin console searching customers, accounts, and tickets
- a support workspace that needs cross-entity lookup

Scrypath supports this through `Scrypath.search_many/2`.

The key honesty rule is the whole point:

**You can merge several result streams into one response without pretending the scores are universally comparable.**

That is why the library keeps per-schema boundaries visible:

- ordered results
- per-schema result access
- partial failures
- federation metadata
- `:all` expansion over an allowlist

This is a powerful flow, but it is not "one magical global index." Read [Multi-index search](multi-index-search.md) when that distinction starts mattering.

## Flow 6: "Recover when search and the database disagree"

This is the grown-up job, and it is where Scrypath is more honest than many libraries.

Sooner or later one of these happens:

- a delete did not land
- a worker retried too many times
- a deployment changed projection or settings
- the DB count and index count diverged
- search returns an id whose row is gone

Scrypath treats that as a normal operator workflow, not a shameful edge case.

The decision tree is blunt:

- use `Scrypath.sync_status/2` when you need posture
- use `Scrypath.failed_sync_work/2` when you need concrete failed units
- retry one explicit failed item when the contract is still sound
- backfill when the live index is still trustworthy and just needs repair
- reindex when the contract changed or the live index no longer deserves trust

The important mindset shift is this:

**Backfill repairs a trustworthy index. Reindex replaces an untrustworthy one.**

Read [Drift recovery](drift-recovery.md) and [Operator Mix tasks](operator-mix-tasks.md) when you are in this phase of adoption.

## How the flows usually mature

Most teams grow through Scrypath in roughly this order:

1. One schema, one context, one inline search flow.
2. More filters, sorts, and Phoenix pages on the same common path.
3. Facets or multi-index search once search becomes product-facing.
4. Oban or manual sync once throughput, imports, or operator control matter more.
5. Backfill and reindex runbooks once the system is clearly valuable enough to need operational discipline.

That progression is healthy. You do not need every flow on day one.

## What Scrypath is opinionated about

Scrypath keeps making the same bets:

- **Ecto-first** beats controller-first or callback-first integration.
- **Contexts own orchestration** beats scattering search logic through the web layer.
- **One common runtime path** beats a pile of generated per-schema verbs.
- **Operational honesty** beats pretending eventual consistency does not exist.
- **Explicit repair workflows** beat "maybe just rerun the callback and hope."

Those bets are why the library feels small in some places and unusually blunt in others.

## What it intentionally does not try to be

Scrypath is not currently trying to be:

- a Postgres full-text abstraction
- a public multi-backend facade
- a Phoenix-only framework
- an admin dashboard that replaces your own auth and operational stack
- a library that claims accepted work means immediate search visibility

That restraint matters. A search library becomes confusing fast when it promises every shape of search, every backend, every UI pattern, and every operations workflow at once.

## Where to go next

- Want the first implementation path: [Golden path](golden-path.md)
- Want the app boundary: [Getting started](getting-started.md) and [Phoenix contexts](phoenix-contexts.md)
- Want to choose sync semantics carefully: [Sync modes and visibility](sync-modes-and-visibility.md)
- Want catalog UX: [Faceted search with Phoenix LiveView](faceted-search-with-phoenix-liveview.md)
- Want cross-schema search: [Multi-index search](multi-index-search.md)
- Want the operator playbook: [Drift recovery](drift-recovery.md)
