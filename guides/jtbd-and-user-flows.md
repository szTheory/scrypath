# JTBD and user flows

This guide is for the Phoenix or Ecto engineer who wants to use Scrypath in a real SaaS app and wants the library to make sense before wiring more code.

If you want the copy-paste first hour, start with the [Golden path](golden-path.md). If you want the shared request-edge contract first, read [Request-edge search](request-edge-search.md). If you want the canonical real-app composition and metadata lane, read [Composing real-app search](composing-real-app-search.md). This guide is the mental model and flow map that ties the rest together.

## The core job

The job is not "run a search query."

The real job is:

**Keep a search-shaped read model in sync with Ecto data without lying about consistency, rebuilds, or recovery.**

That one sentence explains almost everything Scrypath is opinionated about:

- schemas declare what a search document looks like
- contexts own orchestration
- request-edge helpers stay thin and optional
- search returns both raw hits and hydrated records
- operator recovery is a first-class user flow, not an appendix

If you want hidden callbacks that whisper "trust me, it's indexed," Scrypath is the wrong tool.

## The mental model

Think in six steps:

1. Your **Ecto schema** declares search metadata with `use Scrypath`.
2. Your **context** decides when a repo write should trigger search sync.
3. Scrypath builds a **search document** from the source record.
4. The backend stores that document in the current search index.
5. `Scrypath.search/3` queries that index and returns raw hits plus hydrated records.
6. If the index drifts from the database, you use **status, failed work, contract drift, backfill, or reindex** to recover deliberately.

The database is still the source of truth. The search index is a derived system you keep honest.

## The six flows that matter

Most teams grow through Scrypath in roughly this order:

1. Get one schema searchable without inventing an indexing subsystem.
2. Choose what is honestly true after a write returns.
3. Normalize browser params once and keep Phoenix screens thin.
4. Build a catalog or global-search experience on the same runtime path.
5. Search across several schemas without pretending they are one index.
6. Recover when the database and the index disagree.

You do not need every flow on day one. You do need the right mental model on day one.

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

## Flow 3: "Normalize browser params once and keep Phoenix screens thin"

This is the day-two Phoenix job.

You have a controller action or LiveView page for something like:

- searching support tickets
- browsing published posts
- filtering customers by status
- finding users by name and email

The clean Scrypath shape is:

- browser params enter at the web edge
- `Scrypath.QueryParams` normalizes them into plain data
- optional `Scrypath.Phoenix` helpers round-trip URL and form state
- the context turns those params into one `Scrypath.search/3` call
- the web layer renders the result honestly

What this buys you:

- search stays a context concern, not a controller trick
- URL-driven LiveView state stays shareable and debuggable
- field-scoped request errors stay renderable without freezing Phoenix into core runtime
- hydration is explicit, so stale search hits do not silently vanish

The important boundary is the whole point:

- `Scrypath.QueryParams` is data-only
- `Scrypath.Phoenix` is optional glue only
- your context still owns repo access, backend choice, preload policy, and search execution

Relevant follow-on guides:

- [Request-edge search](request-edge-search.md)
- [Phoenix walkthrough](phoenix-walkthrough.md)
- [Phoenix controllers and JSON](phoenix-controllers-and-json.md)
- [Phoenix LiveView](phoenix-liveview.md)

## Flow 3.5: "Compose reusable presets and scopes without inventing a second runtime"

This is the feature-level search policy job.

Once a team has more than one screen or caller building the same search defaults, the
question changes from "how do I parse params?" to "where do these shared defaults and
locks live without turning Scrypath into the app boundary?"

The clean shape is:

- host contexts or feature modules define a plain-data preset or scope
- `Scrypath.Composition` resolves those fragments into canonical single-search args
- contexts still call `Scrypath.search/3`
- Phoenix remains optional because composition stops at data, not execution

That boundary matters:

- presets can default text, filters, sort, page, facets, facet filters, or per-query knobs
- fixed constraints can lock only filter-bearing fields and fail explicitly on conflicts
- the result stays inspectable for tests and logs without exposing `%Scrypath.Query{}`

This gives you one reusable composition seam without creating schema-generated runtime
verbs, moving policy onto `Scrypath.Phoenix`, or pretending composition solves tenant
authz or related-data propagation.

Read [Composing real-app search](composing-real-app-search.md) when you want the
canonical `defaults`, `fixed`, metadata, and `compose_many/2` story in one place.

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
- use index-contract drift when the question is declared contract versus live index shape
- retry one explicit failed item when the contract is still sound
- backfill when the live index is still trustworthy and just needs repair
- reindex when the contract changed or the live index no longer deserves trust

The important mindset shift is this:

**Backfill repairs a trustworthy index. Reindex replaces an untrustworthy one.**

Read [Drift recovery](drift-recovery.md), [Operator Mix tasks](operator-mix-tasks.md), and [Related data and reindexing](related-data-and-reindexing.md) when you are in this phase of adoption.

## What Scrypath is opinionated about

Scrypath keeps making the same bets:

- **Ecto-first** beats controller-first or callback-first integration.
- **Contexts own orchestration** beats scattering search logic through the web layer.
- **One common runtime path** beats a pile of generated per-schema verbs.
- **Operational honesty** beats pretending eventual consistency does not exist.
- **Optional Phoenix glue** beats turning the core library into a Phoenix facade.
- **Explicit recovery** beats treating drift as a support embarrassment.

## What is still intentionally not magic

Scrypath is not promising these things for you:

- no hidden database-plus-search atomicity
- no generated search subsystem from one macro
- no automatic cross-record reindex story for every association shape
- no fake cross-index score comparability
- no public multi-backend abstraction in v1

Those constraints are part of the product, not missing polish.

## What to read next

- First hour: [Golden path](golden-path.md)
- Phoenix request edge: [Request-edge search](request-edge-search.md)
- Sync truth: [Sync modes and visibility](sync-modes-and-visibility.md)
- Related-data correctness: [Related data and reindexing](related-data-and-reindexing.md)
- Recovery: [Drift recovery](drift-recovery.md)

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
