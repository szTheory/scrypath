# Phase 91: Integration, Guides, and Verification - Research

**Researched:** 2026-05-25
**Domain:** Elixir/Phoenix docs + verify-gate + example-app polish for an already-shipped related-data fan-out API (`Scrypath.sync_related/3`)
**Confidence:** HIGH (everything load-bearing was read directly from this repo's source on disk)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Fixed inputs carried forward from Phases 89–90 (do NOT re-litigate):**
- **D-01 — Public API shape (locked):** `Scrypath.sync_related(schema_module, records, opts)`. `opts[:fan_out]` is **required** (raises `ArgumentError` if absent) and names a key in the schema's `fan_outs:` declaration. `opts[:sync_mode]` selects `:inline` (resolve + `sync_records` now) or `:oban` (enqueue internal `RelatedWorker`). See `lib/scrypath.ex:192` and `lib/scrypath/sync.ex:38`.
- **D-02 — `fan_outs:` declaration (locked):** A keyword list on the *owning* schema's `use Scrypath` block, each entry `target:` (the schema whose documents get re-synced) + `resolver:` (an `{mod, fun, extra_args}` MFA invoked as `apply(mod, fun, [records | extra_args])`, returning the target records to sync). Validated in `lib/scrypath/options.ex`.
- **D-03 — Oban path is config-driven, NOT a macro (locked):** The `:oban` path uses the internal `Scrypath.Sync.RelatedWorker`. There is **no public `use Scrypath.Oban.Worker` macro** — adopters never name the worker module. Docs/example must reflect this: just `sync_mode: :oban, oban: [queue: …, max_attempts: …]`.
- **D-04 — Error/handoff contract (locked):** Oban path returns `{:ok, %Result{status: :accepted}}` on successful enqueue. `RelatedWorker.perform/1` maps fan-out failures onto Oban outcomes: HTTP 4xx → `{:cancel, _}` (permanent), HTTP 5xx/generic → `{:error, _}` (transient retry), invalid schema/fan_out → `{:cancel, {:invalid_job, reason}}`. Docs must state these outcomes and the honest truth boundary ("durably queued" ≠ "searchable now").
- **D-05 — Invariant (locked):** Explicit orchestration only. No Ecto lifecycle callbacks, no hidden association walking, no deep preload cascade. Contexts own the fan-out decision and invoke it; the library owns execution. This is the boundary the verify gate must assert.

**91-01 — Guide rewrite:**
- **D-06:** Replace the `### Temporary Workaround: Custom Oban Jobs` subsection (current `guides/related-data-and-reindexing.md` lines 82–135) with a canonical "fan-out with `Scrypath.sync_related/3`" section. Show: (a) the schema-side `fan_outs:` declaration on the owning schema (Author declaring a fan-out to Post), then (b) the context-side call for both `sync_mode: :inline` and `sync_mode: :oban`.
- **D-07:** Preserve the guide's existing voice — "your app owns the fan-out / no callback magic." Frame `sync_related/3` as *explicit orchestration the context invokes*, not a hidden callback. The custom-worker code (lines 88–135) is removed, not kept as an alternative.
- **D-08 (EXEC-02):** Fold the new API into the existing "Picking the right follow-up path" section so the inline-vs-Oban choice maps explicitly to **blast radius + request latency**: small/bounded + latency-tolerant → `:inline`; large/many rows + latency-sensitive + Oban-as-normal-infra → `:oban`. Keep the existing honest truth/cannot-say boundaries and add the `RelatedWorker` retry/cancel outcomes (D-04).
- **D-09:** Remove the strings the old contract test asserted ("temporary workaround", "first-class feature") — they must not survive anywhere in the guide.

**91-02 — `mix verify.phase91` + docs contract (TEST-01, TEST-02):**
- **D-10:** New `Mix.Tasks.Verify.Phase91` mirroring the `verify.phase85` shape (`lib/mix/tasks/verify.phase85.ex`): `app.start` → no-args guard → run focused tests → `mix docs --warnings-as-errors`. Focused test set: `test/scrypath/sync/related_test.exs`, `test/scrypath/sync/related_worker_test.exs`, `test/scrypath/docs_contract_test.exs`. These are hermetic (no live Meilisearch), which is how TEST-01 is satisfied.
- **D-11 (TEST-02):** Invert the existing docs-contract test (`test/scrypath/docs_contract_test.exs:1128`). New assertions on `guides/related-data-and-reindexing.md`: does **NOT** contain `"temporary workaround"` or `"first-class feature"`; **DOES** reference `Scrypath.sync_related/3`, a `fan_outs:` declaration, and both `sync_mode: :inline` and `sync_mode: :oban`; articulates the **context-owned orchestration vs library-owned execution** boundary and the **no-callback-magic** invariant.
- **D-12:** Register the new task file in the docs-contract test's `@verify_phase*` module-attribute list so the verify task stays discoverable per the existing pattern.

**91-03 — Phoenix example polish:**
- **D-13:** Add an `Author` schema + `posts.author_id` association (migration) to `examples/phoenix_meilisearch`. `Author` declares a `fan_outs:` entry targeting `ScrypathDemo.Blog.Post` via a Blog-context resolver. The example's `update_author` flow calls `Scrypath.sync_related(Author, author, fan_out: :posts, …)` so renaming an author re-syncs that author's post documents.
- **D-14 (user-selected):** The example smoke proof exercises **both** the `sync_mode: :inline` and `sync_mode: :oban` fan-out paths — mirroring the example's existing dual `sync_record` smoke coverage. Oban already wired (`config/config.exs`, `config/test.exs` `testing: :inline`).
- **D-15:** The mechanism for getting the renamed author's name into the Post document is an **implementation detail left to research/planning**. Locked constraint: whatever mechanism is chosen stays **app-owned and explicit** — the library must not gain implicit preload/association-walking behavior. (Recommendation in this doc; see Architecture Patterns Pattern 3.)
- **D-16:** Update `examples/phoenix_meilisearch/README.md` to describe the related-data fan-out path alongside the existing inline/Oban `sync_record` narrative.

### Claude's Discretion
- Exact section ordering and prose of the rewritten guide, provided D-06–D-09 hold.
- Exact assertion strings in the docs-contract test, provided they enforce D-11.
- The `author_name` projection mechanism in the example (D-15), provided it stays explicit.
- Whether the example needs a thin `ScrypathDemo.Blog` context module to host the resolver + `update_author/2` (likely yes — confirmed: no context module exists today, see Runtime State Inventory).

### Deferred Ideas (OUT OF SCOPE)
- **Tenant-safe search access (AUTH-01)** — next milestone's wedge, not this phase. The guide may *mention* tenant/permission changes are higher-risk related-data events (it already does), but no tenant-safety mechanism is built here.
- **High-cardinality facet-value search (FACET-UX-01)** — unrelated catalog-depth follow-on.
- No new public API, Ecto callbacks, association-walking, or preload-cascade behavior may be added to the library (D-05). All proposed mechanisms stay app-owned and explicit.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **EXEC-02** | Developer docs clearly define when to use inline fan-out versus durable (Oban) queueing based on blast radius and request latency. | Guide already has a "Picking the right follow-up path" section (current lines 176–220) with the inline/oban/manual split and the "Truth you can say / cannot say" honesty block. 91-01 folds `sync_related/3` into it and adds the D-04 retry/cancel outcomes. Decision matrix captured below (Code Examples + Architecture). |
| **TEST-01** | Maintainers can easily test related-data propagation behavior in hermetic unit tests without a live Meilisearch backend. | `test/scrypath/sync/related_test.exs` (4 tests, in-memory `RecordingBackend`) and `test/scrypath/sync/related_worker_test.exs` (6 tests, `RecordingBackend`/`ErrorBackend`, gated on `Code.ensure_loaded?(Oban.Worker)`) are already hermetic. 91-02's gate *runs* these — TEST-01 is satisfied by wiring, not by new tests. |
| **TEST-02** | The `verify.phase…` pattern ensures docs contracts correctly articulate the boundary between context-owned orchestration and library-owned execution. | `test/scrypath/docs_contract_test.exs:1128` is the assertion to invert (D-11). `assert_contains_all/2` (line 1150), `extract_elixir_fences/1` (line 1144), `ordered?/3` (line 1157) are the available helpers. The `@verify_phase*` attr list (lines 16–31) + the `verify.phaseNN stays wired` test pattern (lines 277–340) are the D-12 wiring points. |
</phase_requirements>

## Summary

Phase 91 is a **docs + verify-gate + example-polish** phase. There is **NO new public API, no new packages, and no library code changes** — `Scrypath.sync_related/3`, the `fan_outs:` metadata, and the internal `Scrypath.Sync.RelatedWorker` shipped in Phases 89–90 and are fixed inputs. The phase's job is to (91-01) rewrite one guide to make the already-shipped API canonical, (91-02) add a `mix verify.phase91` gate plus an inverted docs-contract assertion, and (91-03) extend the Phoenix example app with an `Author`→`Post` fan-out exercising both `:inline` and `:oban`.

The single most important *engineering* finding — and the only genuinely open design question — is the **resolver-arity duality** (D-15). The resolver MFA is invoked with **two different first arguments depending on sync mode**: the inline path (`lib/scrypath/sync.ex:92`) passes a list of **owning-schema records** (`Author` structs); the Oban path (`lib/scrypath/sync/related_worker.ex:47`) passes a list of **owning-schema document IDs** (`Author` `:id` integers, extracted by `Identity.document_ids/2` at enqueue time and round-tripped through JSON). The existing hermetic tests already encode this: `RelatedTest.resolve_comments/2` takes records, `RelatedWorkerTest.resolve_comments/2` takes IDs. **Any resolver the guide or example ships MUST handle both shapes**, or the `:oban` path will crash on an `Author` struct it expected to be an integer ID. This is the dominant correctness risk in the phase and the planner must make it an explicit task requirement.

For D-15's "how does the new author name reach the Post document" question, the recommended mechanism is a **denormalized `posts.author_name` column kept in sync by the Blog context**, with the resolver reloading affected Posts from the repo by `author_id` and returning fully-projected `Post` structs. This keeps the projection 100% app-owned and explicit (no library preload/association-walking), satisfies the resolver-arity duality cleanly (reload-by-id works identically whether you receive records or IDs), and matches what the existing guide and example already imply (Post stores `author_name`).

**Primary recommendation:** Treat this as three near-independent text/wiring deliverables. Make the resolver-arity duality a first-class, tested requirement of both the guide example and the example app. Use a denormalized `author_name` column + repo reload-by-`author_id` as the projection mechanism. Mirror `verify.phase85` line-for-line for the gate, and mirror the `verify.phase83/84/85 stays wired` test for D-12 discoverability.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Decide *whether* a related-data change needs fan-out | App context (`ScrypathDemo.Blog`) | — | D-05 invariant: contexts own the fan-out decision. Never the library, never web modules. |
| Resolve owning record/IDs → target records to re-sync | App resolver MFA (`Blog.resolve_posts_for_authors/1`) | — | The `fan_outs:` `resolver:` is app code (`apply(mod, fun, …)`). All querying/preload/projection is app-owned (D-05, D-15). |
| Project the renamed `author_name` into the Post document | App context / Ecto schema (`posts.author_name` column + `Post` projection field) | App resolver (reloads fresh rows) | Denormalized column lives in the app's DB; projection is the app's `fields:` declaration. Library never walks the `Author`↔`Post` association. |
| Execute the upsert against the backend | **Library** (`Scrypath.Sync.sync_records/3`) | Backend (Meilisearch) | "The library owns execution" half of D-05. Library does the document-building + dispatch. |
| Durable async dispatch of the fan-out | **Library** (`Scrypath.Sync.RelatedWorker`, internal) | Oban | D-03: config-driven, internal worker; adopter never names it. |
| Map fan-out failure → Oban outcome (cancel/retry) | **Library** (`RelatedWorker.perform/1`) | Oban | D-04 contract; not the app's concern. |
| Guide that teaches the inline-vs-oban decision | Docs (`guides/related-data-and-reindexing.md`) | — | EXEC-02. |
| Lock the docs/boundary contract | Maintainer test suite (`docs_contract_test.exs` + `verify.phase91`) | — | TEST-02. |
| Run hermetic propagation tests in the gate | Maintainer test suite (`related_test.exs`, `related_worker_test.exs`) | — | TEST-01. |

## Standard Stack

No packages are added in this phase. Everything below is already a dependency of the library or the example app and is listed only so the planner does not propose adding it.

### Core (already present)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ex_doc` | (dev/docs dep) | `mix docs --warnings-as-errors` step in the verify gate | Already the docs toolchain; every `verify.phaseNN` ends with it. [VERIFIED: `verify.phase85.ex:23` + every `verify.phaseNN stays wired` test asserts `Mix.Task.run("docs", ["--warnings-as-errors"])`] |
| `oban` | `~> 2.21` | `:oban` fan-out dispatch in lib + example | Library declares it optional; example declares `{:oban, "~> 2.21"}`. [VERIFIED: `examples/phoenix_meilisearch/mix.exs:51`; lib worker fallback message says `{:oban, "~> 2.21", optional: true}` at `related_worker.ex:175`] |
| `nimble_options` | (lib dep) | `fan_outs:` and runtime option validation | Used by `Scrypath.Options`. [VERIFIED: `lib/scrypath/options.ex:504` `NimbleOptions.validate`] |
| `phoenix` / `ecto_sql` / `postgrex` / `bandit` | `~> 1.8.5` / `~> 3.13` / `>=0.0.0` / `~> 1.5` | Example app stack | Already declared. [VERIFIED: `examples/phoenix_meilisearch/mix.exs:42–52`] |
| `req` | (lib dep) | Smoke tests delete the live Meilisearch index in teardown | Used in existing smoke `delete_index/2`. [VERIFIED: `meilisearch_stack_test.exs:62`] |

**Installation:** None. `mix deps.get` in the example is already part of the CI/smoke flow; no new entries.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Denormalized `author_name` column (recommended D-15 mechanism) | App-owned preload/projection inside the resolver that joins Author at resolve time and writes `author_name` only into the search doc (not the DB) | The preload-at-resolve approach avoids a DB column but is harder to keep correct across the resolver-arity duality: the `:oban` path receives **only Author IDs** (records were discarded at enqueue), so the resolver would have to reload the Author by ID anyway. A denormalized column reloads Posts by `author_id` and is uniform for both arities. See Pitfall 1 + Open Question 1. |

## Package Legitimacy Audit

> Not applicable — this phase installs **no external packages**. All libraries referenced (ex_doc, oban, nimble_options, phoenix, ecto_sql, req) are pre-existing dependencies of the library or the example app, declared on disk and verified above. No registry lookup, slopcheck, or postinstall audit is required because nothing is being added.

**Packages removed due to slopcheck [SLOP] verdict:** none (no installs)
**Packages flagged as suspicious [SUS]:** none (no installs)

## Architecture Patterns

### System Architecture Diagram

```
                    Author rename request
                            │
                            ▼
        ┌───────────────────────────────────────────┐
        │  ScrypathDemo.Blog (APP CONTEXT)           │   ← owns the fan-out DECISION (D-05)
        │  update_author(author, attrs)              │
        │    1. Repo.update! the Author              │
        │    2. (D-15) write denormalized            │
        │       posts.author_name for that author    │
        │    3. decide blast radius → pick sync_mode │
        └───────────────────┬───────────────────────┘
                            │ Scrypath.sync_related(Author, author,
                            │   fan_out: :posts, sync_mode: :inline | :oban, …)
                            ▼
        ┌───────────────────────────────────────────┐
        │  Scrypath.sync_related/3 (LIBRARY ENTRY)   │   lib/scrypath.ex:193
        │  - require opts[:fan_out] (else ArgError)  │
        │  - look up fan_outs[:posts] on Author      │
        │  - branch on sync_mode                     │
        └──────────┬───────────────────┬────────────┘
                   │ :inline           │ :oban
                   ▼                   ▼
    ┌──────────────────────┐   ┌──────────────────────────────────┐
    │ inline_resolve_and_  │   │ RelatedWorker.enqueue/4          │
    │ sync (sync.ex:72)    │   │ - Identity.document_ids(Author,  │
    │ resolver gets        │   │   records) → [author_id, …]      │
    │   [%Author{}, …]     │   │ - JSON args → Oban.insert        │
    └──────────┬───────────┘   └──────────────┬───────────────────┘
               │                              │ {:ok, status: :accepted}
               │                              ▼  (later, async)
               │              ┌───────────────────────────────────┐
               │              │ RelatedWorker.perform/1            │
               │              │ resolver gets [author_id, …]       │  ← DIFFERENT ARG SHAPE
               │              │ (sync.ex:47)                       │
               │              └──────────────┬────────────────────┘
               ▼                             ▼
    ┌────────────────────────────────────────────────────────────┐
    │  APP RESOLVER MFA: Blog.resolve_posts_for_authors/1         │  ← MUST accept records OR ids
    │  reload Posts by author_id from Repo, return [%Post{…}]     │  (resolver-arity duality)
    └──────────────────────────┬─────────────────────────────────┘
                               ▼
    ┌────────────────────────────────────────────────────────────┐
    │  Scrypath.Sync.sync_records(Post, posts, opts)  (LIBRARY)   │  ← library owns EXECUTION
    │  Projection.document/2 → backend.upsert_documents/3         │
    └──────────────────────────┬─────────────────────────────────┘
                               ▼
                       Meilisearch index
        (inline: waits for task → :completed │ oban: :accepted, not searchable yet)
```

### Recommended Example-App Project Structure (91-03)

```
examples/phoenix_meilisearch/
├── lib/scrypath_demo/
│   ├── blog.ex                 # NEW context: update_author/2 + resolve_posts_for_authors/1
│   └── blog/
│       ├── author.ex           # NEW schema: use Scrypath, fan_outs: [posts: [...]]
│       └── post.ex             # EDIT: add author_id + author_name fields, add :author_name to fields:
├── priv/repo/migrations/
│   └── 2025…_add_authors_and_post_author_fields.exs   # NEW: authors table + posts.author_id + posts.author_name
└── test/smoke/
    ├── meilisearch_related_inline_stack_test.exs   # NEW: inline fan-out smoke (mirror existing inline)
    └── meilisearch_related_oban_stack_test.exs     # NEW: oban fan-out smoke (mirror existing oban)
```

(Naming above is illustrative; the planner may split or merge the two new smoke tests. D-14 only requires both paths be exercised.)

### Pattern 1: The verify task (copy `verify.phase85`)

**What:** A thin `Mix.Task` that boots the app, guards against args, runs a focused test list, then builds docs with warnings-as-errors.
**When to use:** 91-02, verbatim shape with a swapped test list and label.
```elixir
# Source: lib/mix/tasks/verify.phase85.ex (read 2026-05-25)
defmodule Mix.Tasks.Verify.Phase91 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused related-data fan-out + docs-contract verification (Phase 91)"

  @focused_tests [
    "test/scrypath/sync/related_test.exs",
    "test/scrypath/sync/related_worker_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)
    run_test!(@focused_tests, "Phase 91 related-data fan-out verification")
    Mix.shell().info("==> Building docs with warnings as errors")
    Mix.Task.reenable("docs")
    Mix.Task.run("docs", ["--warnings-as-errors"])
  end

  defp run_test!(args, label) do
    Mix.shell().info("==> Running #{label}")
    Mix.Task.reenable("test")
    Mix.Task.run("test", args)
  end

  defp ensure_no_args!([]), do: :ok
  defp ensure_no_args!(args),
    do: Mix.raise("verify.phase91 does not accept arguments, got: #{Enum.join(args, " ")}")
end
```
**Gotcha (verified):** tests run via `Mix.Task.run("test", args)` (in-process), **not** `System.cmd`. The `Mix.Task.reenable("test")` / `reenable("docs")` calls are mandatory because `app.start` may have already consumed the task lock — omitting them silently no-ops the second run. The gate must be registered as `:test` env in `mix.exs` `preferred_envs` (see Pattern 4) or it will run under `:dev` and fail to find test files.

### Pattern 2: Invert the docs-contract assertion (D-11, TEST-02)

**What:** Replace the `refute`-style "must mention temporary workaround" test with an assert/refute pair enforcing the new canonical story.
**When to use:** 91-02, replacing `docs_contract_test.exs:1128–1136`.
```elixir
# Source: derived from docs_contract_test.exs helpers read 2026-05-25
test "related-data guide adopts sync_related/3 as the canonical fan-out story" do
  guide = @guides["guides/related-data-and-reindexing.md"]

  refute String.contains?(guide, "temporary workaround"),
         "guide must not frame the fan-out path as a temporary workaround (D-09)"
  refute String.contains?(guide, "first-class feature"),
         "guide must not promise a future first-class feature; it already shipped (D-09)"

  assert_contains_all(guide, [
    "Scrypath.sync_related/3",
    "fan_outs:",
    "sync_mode: :inline",
    "sync_mode: :oban",
    # boundary phrasing (exact strings are Claude's discretion per CONTEXT, but must encode the invariant)
    "context",        # context-owned orchestration
    "execution",      # library-owned execution
    "callback magic"  # the no-callback-magic invariant (guide already says "callback magic" at line 305)
  ])
end
```
**Note:** The exact boundary strings are discretionary (CONTEXT), but they MUST be strings the rewritten guide actually contains, and they MUST encode "context-owned orchestration vs library-owned execution" + "no callback magic". Coordinate 91-01 and 91-02 so the asserted strings and the guide prose are written together — this is a known cross-plan coupling.

### Pattern 3: App-owned projection via denormalized column (recommended D-15)

**What:** Post stores `author_name` as a real column. The Blog context updates it on author rename, then fans out to re-sync the affected Post documents. The resolver reloads Posts by `author_id`, returning fully-built `Post` structs.
**When to use:** 91-03 example, and the worked example in the 91-01 guide.
```elixir
# Source: composed from sync.ex:92 (inline arg) + related_worker.ex:47 (oban arg) + existing post.ex
# RESOLVER-ARITY DUALITY: first arg is [%Author{}] inline, [author_id] under :oban.
defmodule ScrypathDemo.Blog do
  import Ecto.Query
  alias ScrypathDemo.Repo
  alias ScrypathDemo.Blog.{Author, Post}

  def update_author(%Author{} = author, attrs, sync_opts) do
    {:ok, updated} =
      author |> Author.changeset(attrs) |> Repo.update()

    # (D-15) keep the denormalized projection in sync — APP-OWNED, explicit.
    {_n, _} =
      from(p in Post, where: p.author_id == ^updated.id)
      |> Repo.update_all(set: [author_name: updated.name])

    # explicit fan-out the context invokes (D-05) — not a callback.
    {:ok, _result} =
      Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts))

    {:ok, updated}
  end

  # Resolver MFA. MUST handle records (inline) AND ids (oban) — see Pitfall 1.
  def resolve_posts_for_authors([%Author{} | _] = authors),
    do: authors |> Enum.map(& &1.id) |> reload_posts()

  def resolve_posts_for_authors([_id | _] = author_ids),
    do: reload_posts(author_ids)

  def resolve_posts_for_authors([]), do: []

  defp reload_posts(author_ids) do
    Repo.all(from p in Post, where: p.author_id in ^author_ids)
  end
end
```
```elixir
# Author schema declares the fan-out on the OWNING schema (D-02).
defmodule ScrypathDemo.Blog.Author do
  use Ecto.Schema
  use Scrypath,
    fields: [:name],
    fan_outs: [
      posts: [
        target: ScrypathDemo.Blog.Post,
        resolver: {ScrypathDemo.Blog, :resolve_posts_for_authors, []}
      ]
    ]

  schema "authors" do
    field(:name, :string)
    has_many(:posts, ScrypathDemo.Blog.Post)
    timestamps(type: :utc_datetime)
  end

  def changeset(author, attrs) do
    author |> Ecto.Changeset.cast(attrs, [:name]) |> Ecto.Changeset.validate_required([:name])
  end
end
```
```elixir
# Post gains author_id + author_name (the projected, denormalized field).
defmodule ScrypathDemo.Blog.Post do
  use Ecto.Schema
  use Scrypath,
    fields: [:title, :body, :author_name],   # author_name now projected into the search doc
    filterable: [:status],
    sortable: [:inserted_at]

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:status, :string)
    field(:author_name, :string)
    belongs_to(:author, ScrypathDemo.Blog.Author)
    timestamps()
  end
  # changeset adds :author_id, :author_name to the cast list
end
```
**Why denormalized column over resolve-time preload:** The `:oban` path discards the `Author` struct at enqueue (`enqueue/4` keeps only `Identity.document_ids`), so a resolver can NEVER rely on receiving an `Author` struct with `.name` already loaded. It must reload from the DB by ID regardless. A denormalized `posts.author_name` makes the reload a flat `Post` query that needs no Author join and is identical across both arities. It also matches the guide's longstanding framing ("post documents store `author_name`", current line 9).

### Anti-Patterns to Avoid
- **Resolver that only handles records (or only IDs).** Will crash on the path it didn't anticipate. The inline and oban paths pass different first args (verified, sync.ex:92 vs related_worker.ex:47). This is the #1 footgun.
- **Putting fan-out logic in a web/controller module or in the `Post` schema.** Violates D-05 ("web modules still do not own this logic", guide line 174). The decision lives in `ScrypathDemo.Blog`.
- **Adding a library-side preload/`belongs_to` walk to make `author_name` appear.** Explicit D-05 non-goal. The library must stay metadata-only (`use Scrypath stays metadata-only`, guide line 302).
- **Asserting docs-contract strings the guide does not literally contain.** The contract test is a substring match (`String.contains?`); a typo in either file fails the gate. Write guide + test together.
- **Forgetting the `mix.exs` `preferred_envs` registration.** Without `"verify.phase91": :test`, the task runs in `:dev` and the test files won't compile/load.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Async fan-out worker | A custom Oban worker in the example (like the old guide's `SyncAuthorPostsWorker`) | `sync_mode: :oban` → internal `Scrypath.Sync.RelatedWorker` | D-03: the whole point of the rewrite is that adopters no longer write/own the worker. The old custom-worker code (guide lines 88–135) is exactly what gets deleted. |
| Failure→retry/cancel mapping | App-side try/rescue around the fan-out | The library's `RelatedWorker.perform/1` matrix (D-04) | Already implemented and tested (related_worker_test.exs 4xx/5xx/generic cases). Docs just describe it. |
| Verify-task scaffolding | A bespoke test runner | Copy `verify.phase85.ex` | Identical shape across phases 82–85; consistency is itself the contract (docs_contract_test asserts the shape). |
| Document building / id extraction | Manual Meilisearch upsert in the resolver | Return records; let `Scrypath.Sync.sync_records/3` project + dispatch | `inline_resolve_and_sync` (sync.ex:94) and the worker (related_worker.ex:49) both call `sync_records` with the resolver's return value. |

**Key insight:** This phase's value is *removing* hand-rolled code (the temporary custom worker) and *documenting/testing* the shipped replacement — not adding anything.

## Runtime State Inventory

> This is partly a refactor (guide rewrite + assertion inversion) plus additive example/test work. No production datastores, no OS-registered state, no secrets are touched. The relevant "state" is what other files/tests reference and what must be added.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **None** — the only DB touched is the *example app's* Postgres, in test/smoke only (Sandbox). No production data, no Meilisearch state outside ephemeral per-test indexes (`phx_demo_#{unique_integer}`, deleted in `on_exit`). | None for the library. 91-03 adds an `authors` table + `posts.author_id`/`posts.author_name` columns via a NEW migration; example test DB is created fresh by the `test` alias (`mix.exs:67`). |
| Live service config | **None.** Oban is already wired in the example (`config/config.exs:14`, `config/test.exs:36 testing: :inline`). No new queues needed — `sync_related` `:oban` enqueues onto the `:scrypath` queue which already exists (`queues: [scrypath: 10]`). | None. Verify the `:scrypath` queue suffices; `RelatedWorker` uses queue `:scrypath`, max_attempts 8 by default (related_worker.ex:5), overridable via `oban_queue:`/`oban_max_attempts:`. |
| OS-registered state | **None.** No schedulers, no daemons, no systemd/launchd units involved in docs/verify/example work. | None. |
| Secrets/env vars | Example smoke tests read `SCRYPATH_MEILISEARCH_URL`, `SCRYPATH_EXAMPLE_INTEGRATION`, `PGPORT` (existing). New smoke tests reuse the same vars — no new secrets. | None — reuse existing env contract. |
| Build artifacts | The verify task `Mix.Tasks.Verify.Phase91` is a new compiled module; the docs-contract test reads its **source file** via `File.read!` (a new `@verify_phase91` attribute, D-12). `mix docs` rebuilds HexDocs (existing extras list in `mix.exs:139–181` already includes the guide — no new extra to register since the guide already exists). | New file `lib/mix/tasks/verify.phase91.ex`; register `@verify_phase91` in docs_contract_test (line ~30) and `"verify.phase91": :test` in `mix.exs` `preferred_envs` (line ~58). |

**Nothing found in OS-registered/secrets/production-stored categories — verified by reading config/config.exs, config/test.exs, application.ex, and the smoke tests.**

## Common Pitfalls

### Pitfall 1: Resolver-arity duality (records vs IDs)
**What goes wrong:** A resolver written `def resolve(authors)` that calls `authors |> Enum.map(& &1.name)` works inline but crashes under `:oban`, where the first arg is `[123, 456]` (integer IDs), not `[%Author{}]`. The reverse (writing for IDs only) crashes inline.
**Why it happens:** `inline_resolve_and_sync` passes `records_list` (the structs the caller handed in) at `sync.ex:92`; `RelatedWorker.perform/1` passes `document_ids` (extracted at enqueue via `Identity.document_ids/2`, serialized to JSON, deserialized as a plain list) at `related_worker.ex:47`. The two existing test resolvers prove this: `RelatedTest.resolve_comments([%DummySource{}], …)` vs `RelatedWorkerTest.resolve_comments([id], …)`.
**How to avoid:** Write the resolver to accept both shapes (pattern-match `[%Author{} | _]` vs `[_id | _]`, then funnel to a reload-by-id query). Reload from the DB in both cases — never trust struct fields to be present. The denormalized-column mechanism (Pattern 3) makes the reload uniform.
**Warning signs:** A guide/example resolver that dereferences struct fields (`&1.name`) without a reload; a smoke test that only exercises `:inline`. D-14 requiring *both* paths is the guard.

### Pitfall 2: Docs-contract substring drift
**What goes wrong:** The inverted assertion asserts `"Scrypath.sync_related/3"` but the guide writes `Scrypath.sync_related/3` inside a fenced code block with different surrounding text, or the boundary phrase in the test (`"library-owned execution"`) doesn't match the guide's actual wording.
**Why it happens:** `assert_contains_all/2` is a literal `String.contains?` (line 1150–1155). No fuzzy matching.
**How to avoid:** Author the guide rewrite (91-01) and the assertion rewrite (91-02) as a coordinated pair; copy the exact boundary sentence from the guide into the test. Run `mix test test/scrypath/docs_contract_test.exs` before declaring done.
**Warning signs:** Plans for 91-01 and 91-02 written independently with no shared "canonical strings" list.

### Pitfall 3: `mix.exs` env registration omitted
**What goes wrong:** `mix verify.phase91` runs in `:dev`, can't load `test/...` files, fails confusingly.
**Why it happens:** Every other `verify.phaseNN` is registered in `preferred_envs` (`mix.exs:40–58`); a new one needs the same.
**How to avoid:** Add `"verify.phase91": :test` to `mix.exs` `cli/0 preferred_envs`. The docs-contract `verify.phaseNN stays wired` test (lines 277–340) also asserts `String.contains?(File.read!("mix.exs"), "\"verify.phase91\": :test")`, so this is doubly required.
**Warning signs:** A new `verify.phaseNN stays wired` test that passes locally but the task fails when invoked.

### Pitfall 4: Smoke tests need live services and are integration-tagged
**What goes wrong:** Adding the new fan-out smoke tests to the *library's* hermetic gate would require live Meilisearch — breaking TEST-01's "no live backend" promise.
**Why it happens:** Example smoke tests are `@moduletag :integration`, gated on `SCRYPATH_EXAMPLE_INTEGRATION` and require `SCRYPATH_MEILISEARCH_URL` (meilisearch_stack_test.exs:11–14, test_helper.exs:1).
**How to avoid:** Keep the new example smoke tests in `examples/phoenix_meilisearch/test/smoke/` (run by `phoenix-example-integration` CI + `mix verify.adopter --live`), NOT in the library's `verify.phase91` focused list. The library gate runs only the hermetic `related_test.exs`/`related_worker_test.exs` (D-10). These are two separate validation surfaces — do not conflate them.
**Warning signs:** A plan that adds an example smoke test path to `verify.phase91`'s `@focused_tests`.

### Pitfall 5: Oban smoke worker-name assertion
**What goes wrong:** Copying the existing Oban smoke test's `job: %{worker: "Scrypath.Oban.UpsertWorker", …}` assertion into the fan-out smoke test — but the fan-out `:oban` path enqueues `Scrypath.Sync.RelatedWorker`, not `UpsertWorker`.
**Why it happens:** The existing Oban smoke (`meilisearch_oban_stack_test.exs:44`) tests `sync_record` → `UpsertWorker`. Fan-out goes through `RelatedWorker.enqueue/4` (related_worker.ex:101) whose public job carries `worker: job.worker` = `Scrypath.Sync.RelatedWorker`.
**How to avoid:** In the new fan-out Oban smoke, assert the result is `{:ok, %{mode: :oban, status: :accepted, …}}` and verify the *effect* (the Post documents reflect the new author_name after the in-process job runs), rather than copy-pasting the `UpsertWorker` string. Under `testing: :inline` the job runs synchronously so the post-state assertion is deterministic.
**Warning signs:** A fan-out smoke test asserting `"Scrypath.Oban.UpsertWorker"`.

## Code Examples

### EXEC-02 decision matrix (for the guide rewrite, D-08)
```text
Source: synthesized from guide lines 176–220 + D-04 (related_worker.ex outcomes)

| Situation                                   | sync_mode | Truth you CAN say          | Truth you CANNOT say         |
|---------------------------------------------|-----------|----------------------------|------------------------------|
| Bounded rows, latency-tolerant caller       | :inline   | "documents synced now"      | —                            |
| Many rows, latency-sensitive, Oban=normal   | :oban     | "follow-up durably queued"  | "all docs searchable now"    |
| Import / migration / uncertain blast radius | manual /  | "staged for operator review"| "live index already correct" |
|                                             | backfill /|                            |                              |
|                                             | reindex   |                            |                              |

Oban failure outcomes (from RelatedWorker.perform/1, D-04):
- backend HTTP 4xx  → {:cancel, "HTTP 4xx…"}      (permanent, no retry)
- backend HTTP 5xx  → {:error, …}                 (transient, Oban retries to max_attempts: 8)
- generic error     → {:error, …}                 (transient, retries)
- invalid schema/fan_out → {:cancel, {:invalid_job, reason}} (permanent)
```

### Inline call (guide context-side, D-06)
```elixir
# Source: derived from related_test.exs:80 + sync.ex inline branch
{:ok, %{mode: :inline, status: :completed}} =
  Scrypath.sync_related(Author, updated_author,
    fan_out: :posts,
    sync_mode: :inline,
    backend: Scrypath.Meilisearch
  )
```

### Oban call (guide context-side, D-06)
```elixir
# Source: derived from related_test.exs:99 + related_worker.ex enqueue contract
{:ok, %{mode: :oban, status: :accepted}} =
  Scrypath.sync_related(Author, updated_author,
    fan_out: :posts,
    sync_mode: :oban,
    oban: MyApp.Oban,
    oban_queue: :scrypath,
    backend: Scrypath.Meilisearch
  )
# "durably queued" — NOT "searchable now" (D-04 honesty boundary)
```

### D-12 discoverability test (mirror lines 277–340)
```elixir
# Source: docs_contract_test.exs "verify.phase85 stays wired" pattern
test "verify.phase91 stays wired into the focused maintainer flow" do
  assert String.contains?(@verify_phase91, "test/scrypath/sync/related_test.exs")
  assert String.contains?(@verify_phase91, "test/scrypath/sync/related_worker_test.exs")
  assert String.contains?(@verify_phase91, "test/scrypath/docs_contract_test.exs")
  assert String.contains?(@verify_phase91, "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])")
  assert String.contains?(File.read!("mix.exs"), "\"verify.phase91\": :test")
end
# plus add: @verify_phase91 File.read!("lib/mix/tasks/verify.phase91.ex") near line 30
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Adopter writes a custom Oban worker to fan out (guide lines 88–135) | `Scrypath.sync_related/3` + internal `RelatedWorker` via `sync_mode: :oban` | Shipped Phases 89–90 (v1.24) | The guide's custom-worker code is deleted (D-06); adopters never name a worker module (D-03). |
| Guide framed fan-out as a "temporary workaround" pending a "first-class feature" | Fan-out is the shipped, canonical path | Phase 91 (this phase) | D-09 removes both strings; D-11 contract test forbids their return. |

**Deprecated/outdated:**
- The custom `SyncAuthorPostsWorker` example (guide lines 88–135): removed, not retained as an alternative (D-07).
- The `docs_contract_test.exs:1128` assertion ("must mention temporary Oban workaround"): inverted (D-11).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A thin `ScrypathDemo.Blog` context module must be created (none exists; only `blog/post.ex`). | Architecture Patterns / Runtime State | LOW — verified by `find` that no `blog.ex` exists. CONTEXT D-15 discretion note already says "likely yes". |
| A2 | Denormalized `posts.author_name` column is the best D-15 mechanism. | Summary / Pattern 3 | MEDIUM — this is a recommendation, not a locked decision (D-15 leaves it to research). The resolve-time-preload alternative is viable but worse under the oban arity (Open Question 1). Planner/discuss-phase may override; either is explicit and satisfies D-05. |
| A3 | The `:scrypath` Oban queue (already configured) suffices for fan-out jobs; no new queue needed. | Runtime State | LOW — `RelatedWorker` defaults to queue `:scrypath` (related_worker.ex:5) and the example config declares `queues: [scrypath: 10]`. |
| A4 | The boundary phrasing strings to assert in D-11 (e.g. "library-owned execution") are discretionary but must be present verbatim in the guide. | Pattern 2 | LOW — CONTEXT explicitly grants string discretion; the only risk is 91-01/91-02 drift (Pitfall 2), mitigated by coordinating the two plans. |
| A5 | `mix.exs` `extras`/`groups_for_extras` need no change (the guide is already a registered extra at `mix.exs:153,181`). | Runtime State | LOW — verified by grep; the guide path already appears twice in mix.exs docs config. |

## Open Questions (RESOLVED)

1. **D-15 projection mechanism: denormalized column vs resolve-time projection.** — RESOLVED: denormalized `author_name` column (Pattern 3), locked in 91-03 (Tasks 1–2).
   - What we know: Both are app-owned/explicit and satisfy D-05. The oban path receives only IDs, forcing a reload regardless.
   - What's unclear: Whether the example maintainers prefer a real `author_name` column (more "production-shaped", one extra migration column + an `update_all` in `update_author`) or a thinner schema where the resolver joins Author at reload time and the `Post` projection computes `author_name` from a preloaded assoc (no extra column, but the projection must preload — still app-owned).
   - Recommendation: Ship the **denormalized column** (Pattern 3). It is the least surprising, uniform across both sync arities, and matches the guide's longstanding "posts store `author_name`" framing. Flag for the planner/discuss-phase as the one substantive design choice; either path is acceptable if it stays explicit.

2. **Should the two example fan-out smoke tests be one file or two?** — RESOLVED: two files, mirroring the existing inline/oban split, locked in 91-03 (Task 3).
   - What we know: The existing pattern uses two files (`meilisearch_stack_test.exs` inline, `meilisearch_oban_stack_test.exs` oban). D-14 requires both paths; it does not mandate file count.
   - Recommendation: Two files mirroring the existing split for symmetry and clear CI failure attribution. Discretionary.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | All three plans (`mix verify.phase91`, `mix docs`, example `mix test`) | Assumed ✓ (repo is an Elixir project) | `~> 1.17` (example) | — |
| `ex_doc` (`mix docs`) | 91-02 verify gate final step | ✓ (every existing `verify.phaseNN` uses it) | dev/docs dep | — |
| `oban` | example `:oban` smoke + lib `RelatedWorker` | ✓ | `~> 2.21` | `:inline` path still works without Oban; lib worker has a no-Oban fallback that raises a clear message (related_worker.ex:170–177) |
| PostgreSQL | example test DB (smoke + ConnCase) | Required at example test time (Docker compose, port 5433) | PG 16 (compose.yaml) | None for example smoke; not needed for the library hermetic gate (TEST-01 tests use in-memory `RecordingBackend`) |
| Live Meilisearch | example **integration** smoke only | Only under `SCRYPATH_EXAMPLE_INTEGRATION=1` | v1.15 (compose.yaml) | Library hermetic gate needs none — that is the whole point of TEST-01 |

**Missing dependencies with no fallback:** None for the library-side deliverables (91-01, 91-02 are hermetic). The example integration smoke (part of 91-03's full validation) requires live PG + Meilisearch, but those are already provisioned by `compose.yaml` / the `phoenix-example-integration` CI job and are out of scope to install here.

**Missing dependencies with fallback:** The example's `:oban` fan-out smoke runs deterministically under `testing: :inline` (config/test.exs:36) without a separate Oban poller process.

## Validation Architecture

> nyquist_validation is enabled (config.json `workflow.nyquist_validation: true`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | none for the library (standard `test/test_helper.exs`); example has `test/test_helper.exs` gating `:integration` |
| Quick run command | `mix test test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs` |
| Full suite command (this phase's gate) | `mix verify.phase91` |
| Example smoke command | `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` (or `mix verify.adopter --live` from root) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TEST-01 | Hermetic related-data propagation tests run (no live Meilisearch) | unit (in-process backend) | `mix test test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs` | ✅ exists (10 tests total) |
| TEST-01 | The gate *runs* those hermetic tests | gate | `mix verify.phase91` | ❌ Wave 0 (verify task is new in 91-02) |
| TEST-02 | Guide no longer says "temporary workaround"/"first-class feature"; references `sync_related/3`, `fan_outs:`, both sync modes, and the boundary/no-callback-magic invariant | docs-contract (substring) | `mix test test/scrypath/docs_contract_test.exs` (inverted assertion) | ✅ file exists; ❌ assertion must be rewritten (91-02) |
| TEST-02 | New verify task is discoverable/wired (registered in `@verify_phase*` + `mix.exs`) | docs-contract | `mix test test/scrypath/docs_contract_test.exs` (new "verify.phase91 stays wired" test) | ❌ Wave 0 (new test, mirror lines 277–340) |
| EXEC-02 | Guide's "Picking the right follow-up path" maps inline/oban to blast-radius + latency, includes honesty boundary + D-04 outcomes | docs-contract (substring) + human review of prose | `mix test test/scrypath/docs_contract_test.exs` | ✅ section exists; rewritten in 91-01, asserted in 91-02 |
| EXEC-02 | Example demonstrates BOTH inline and oban fan-out end-to-end (D-14) | integration smoke (live PG + Meilisearch) | `cd examples/phoenix_meilisearch && SCRYPATH_EXAMPLE_INTEGRATION=1 mix test` | ❌ Wave 0 (new smoke tests in 91-03) |

### Sampling Rate
- **Per task commit:** `mix test test/scrypath/sync/related_test.exs test/scrypath/sync/related_worker_test.exs test/scrypath/docs_contract_test.exs` (fast, hermetic, < a few seconds).
- **Per wave merge:** `mix verify.phase91` (the full hermetic gate including `mix docs --warnings-as-errors`).
- **Phase gate:** `mix verify.phase91` green AND (for 91-03) example integration smoke green via `phoenix-example-integration` CI / `mix verify.adopter --live` before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `lib/mix/tasks/verify.phase91.ex` — new verify task (D-10), enables TEST-01 gate.
- [ ] `test/scrypath/docs_contract_test.exs` — invert the line-1128 assertion (D-11) + add `@verify_phase91` attr (line ~30) + add "verify.phase91 stays wired" test (mirror lines 277–340) (D-12). Enables TEST-02.
- [ ] `mix.exs` — add `"verify.phase91": :test` to `preferred_envs` (line ~58).
- [ ] `examples/phoenix_meilisearch/test/smoke/` — new inline + oban fan-out smoke tests (D-14). Enables EXEC-02 end-to-end demonstrability.
- [ ] `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex`, `blog/author.ex`, migration, `blog/post.ex` edits — new example code under test by the smoke tests.
- [ ] No framework install needed — ExUnit is built in; example deps already declared.

## Security Domain

> `security_enforcement` is not set in config.json (no `security_enforcement` key). Treating as enabled but scoping to this phase's surface.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Docs/verify/example phase; no auth surface. Tenant-safe access (AUTH-01) is explicitly deferred (CONTEXT). |
| V3 Session Management | no | No sessions touched. |
| V4 Access Control | no (but noted) | The guide already warns tenant/permission changes are higher-risk related-data events and that "index prefixes alone are [not] your authorization model" (guide line 255). 91-01 must preserve that warning; it builds no authz mechanism. |
| V5 Input Validation | yes (existing) | `fan_outs:`/runtime options validated via `NimbleOptions` in `Scrypath.Options` (already shipped). `sync_related/3` raises `ArgumentError` on missing/invalid `:fan_out` (sync.ex:42, 48). No new untrusted input introduced by docs/example. |
| V6 Cryptography | no | None. |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Oban arg deserialization (`String.to_existing_atom` on `schema`/`fan_out` from JSON job args) | Tampering / DoS (atom exhaustion) | Already mitigated in `RelatedWorker`: uses `String.to_existing_atom` (not `to_atom`) and rescues `ArgumentError` → `{:cancel, {:invalid_job, …}}` (related_worker.ex:73–99). Example/guide must NOT introduce dynamic atom creation from user input. |
| Resolver running arbitrary app code under a job | Elevation/Tampering | By design app-owned (D-05); the resolver is the app's own MFA. Guide should keep resolvers deterministic and side-effect-light (just query + return records). |
| Denormalized `author_name` going stale (data integrity, not classic security) | Repudiation/integrity | The `update_author` flow updates the column in the same context action before fan-out (Pattern 3); document the ordering so the search doc never shows a name the DB no longer holds. |

## Sources

### Primary (HIGH confidence — read from disk this session)
- `.planning/phases/91-integration-guides-and-verification/91-CONTEXT.md` — all decisions D-01..D-16
- `.planning/milestones/v1.24-REQUIREMENTS.md` — EXEC-02, TEST-01, TEST-02, Out-of-Scope table
- `.planning/milestones/v1.24-ROADMAP.md` — Phase 91 goal, plan stubs, working assumptions
- `lib/scrypath.ex` (`sync_related/3` @spec, line 186–195)
- `lib/scrypath/sync.ex` (inline resolver arg at line 92, `:oban` dispatch line 53–58, `fan_out` required line 41)
- `lib/scrypath/sync/related_worker.ex` (perform/1 outcome matrix lines 54–70, resolver arg = IDs line 47, enqueue uses `Identity.document_ids` line 102, no-Oban fallback line 170–177)
- `lib/scrypath/options.ex` (`fan_outs:` schema line 41, `validate_fan_outs/1` line 806, resolver MFA validation line 848)
- `lib/scrypath/identity.ex` (`document_ids/2` returns IDs, line 13–16)
- `lib/mix/tasks/verify.phase85.ex` (canonical verify shape)
- `test/scrypath/docs_contract_test.exs` (@verify_phase* lines 16–31, @guide_paths line 32–55, inverted test line 1128, helpers line 1138–1167, "verify.phaseNN stays wired" pattern line 277–340)
- `test/scrypath/sync/related_test.exs` (inline+oban hermetic tests, resolver takes records)
- `test/scrypath/sync/related_worker_test.exs` (worker hermetic tests, resolver takes IDs, 4xx/5xx/generic outcomes)
- `guides/related-data-and-reindexing.md` (full 312 lines; rewrite target — workaround block lines 82–135, follow-up section 176–220, honesty block 201–207, no-callback-magic line 305, authz warning 255)
- `mix.exs` (preferred_envs lines 37–64, docs extras lines 139–181)
- `examples/phoenix_meilisearch/` — `lib/scrypath_demo/blog/post.ex`, `lib/scrypath_demo/oban.ex`, `lib/scrypath_demo/application.ex`, `config/config.exs`, `config/test.exs`, `mix.exs`, `priv/repo/migrations/20250418120000_create_posts.exs`, `test/smoke/meilisearch_stack_test.exs`, `test/smoke/meilisearch_oban_stack_test.exs`, `test/test_helper.exs`, `README.md`, full file tree via `find`

### Secondary (MEDIUM confidence)
- None — no web sources needed; everything is in-repo.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all deps verified on disk.
- Architecture / API signatures: HIGH — read directly from shipped source; resolver-arity duality confirmed by two existing test files encoding both shapes.
- Pitfalls: HIGH — each pitfall traces to a specific verified line (arity duality, substring matching, env registration, integration tagging, worker name).
- D-15 recommendation: MEDIUM — a justified recommendation, but CONTEXT explicitly leaves the choice open; either explicit mechanism is valid.

**Research date:** 2026-05-25
**Valid until:** ~2026-06-24 (stable — depends on in-repo, already-shipped code; only risk is unrelated repo churn before planning)
