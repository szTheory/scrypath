# Phase 91: Integration, Guides, and Verification - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 9 (3 new, 6 edited)
**Analogs found:** 9 / 9 (every file has an in-repo analog — this phase adds no novel structure)

> **Phase-wide invariant (carried into every file):** This phase ships NO new public API
> and NO library code changes. `Scrypath.sync_related/3`, `fan_outs:` metadata, and the
> internal `Scrypath.Sync.RelatedWorker` are FIXED inputs (shipped Phases 89–90). Every
> excerpt below from `lib/scrypath*.ex` is **read-only reference to document verbatim**, not
> a file to edit.

> **Resolver-arity duality (the dominant correctness risk — applies to 91-01 guide example,
> 91-03 Author schema + Blog context + both smoke tests):** the resolver MFA is invoked with
> TWO different first-arg shapes depending on `sync_mode`:
> - `:inline` → `lib/scrypath/sync.ex:92` passes `[records_list]` = **owning-schema structs** (`[%Author{}]`)
> - `:oban` → `lib/scrypath/sync/related_worker.ex:47` passes `[document_ids]` = **integer IDs** (round-tripped through JSON)
>
> Any resolver in guide or example MUST handle both shapes or the `:oban` path crashes on a
> struct it expected to be an integer. The two existing hermetic test resolvers encode exactly
> this split: `related_test.exs:50` (`[_ | _] = records`, dereferences `&1.id`/`&1.name`) vs
> `related_worker_test.exs:60` (`[_ | _] = ids`, treats elements as integers).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/verify.phase91.ex` (NEW) | mix task | batch (test-runner) | `lib/mix/tasks/verify.phase85.ex` | exact |
| `mix.exs` `preferred_envs` (EDIT, ~line 58) | config | — | existing `"verify.phaseNN": :test` block (lines 40–58) | exact |
| `test/scrypath/docs_contract_test.exs` (EDIT) | test (docs-contract) | transform (substring assertions) | self — `@verify_phase85` attr (line 29), `verify.phase85 stays wired` test (lines 333–340), line-1128 test, helpers (1144–1167) | exact |
| `guides/related-data-and-reindexing.md` (EDIT) | docs | — | self — workaround block (82–135) to replace, follow-up section (176–220) to extend | exact (rewrite) |
| `examples/.../lib/scrypath_demo/blog/author.ex` (NEW) | example schema | event-driven (fan-out owner) | `examples/.../lib/scrypath_demo/blog/post.ex` (`use Scrypath` shape) + `related_test.exs:39–46` (`fan_outs:` shape) | role-match + composed |
| `examples/.../lib/scrypath_demo/blog.ex` (NEW) | example context | request-response + event-driven | RESEARCH Pattern 3 (no context module exists today — confirmed by `find`); resolver-arity from `sync.ex:92` + `related_worker.ex:47` | no direct analog (composed) |
| `examples/.../lib/scrypath_demo/blog/post.ex` (EDIT) | example schema | CRUD | self (add `author_id` + `author_name` field + `:author_name` to `fields:`) | exact (extend) |
| `examples/.../priv/repo/migrations/2025…_add_authors_and_post_author_fields.exs` (NEW) | migration | — | `examples/.../priv/repo/migrations/20250418120000_create_posts.exs` | role-match |
| `examples/.../test/smoke/meilisearch_related_inline_stack_test.exs` (NEW) | smoke test | event-driven (inline fan-out) | `examples/.../test/smoke/meilisearch_stack_test.exs` | exact |
| `examples/.../test/smoke/meilisearch_related_oban_stack_test.exs` (NEW) | smoke test | event-driven (oban fan-out) | `examples/.../test/smoke/meilisearch_oban_stack_test.exs` | exact (with Pitfall 5 deviation) |
| `examples/.../README.md` (EDIT) | docs | — | self (extend the inline/Oban `sync_record` narrative, lines 69–70) | exact (extend) |

---

## Pattern Assignments

### `lib/mix/tasks/verify.phase91.ex` (NEW — mix task, batch) — 91-02 / D-10

**Analog:** `lib/mix/tasks/verify.phase85.ex` (entire 37-line file — copy verbatim, swap label + test list).

**Full shape to copy** (`verify.phase85.ex:1-37`):
```elixir
defmodule Mix.Tasks.Verify.Phase85 do
  @moduledoc false
  use Mix.Task

  @shortdoc "Runs focused real-app composition story verification (Phase 85)"

  @focused_tests [
    "test/scrypath/composition_test.exs",
    "test/scrypath/metadata_test.exs",
    "test/scrypath/composition_many_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    run_test!(@focused_tests, "Phase 85 real-app composition verification")

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

  defp ensure_no_args!(args) do
    Mix.raise("verify.phase85 does not accept arguments, got: #{Enum.join(args, " ")}")
  end
end
```

**Required swaps for Phase 91 (D-10):**
- Module → `Mix.Tasks.Verify.Phase91`
- `@focused_tests` → exactly these three (hermetic, no live Meilisearch — that satisfies TEST-01):
  ```elixir
  @focused_tests [
    "test/scrypath/sync/related_test.exs",
    "test/scrypath/sync/related_worker_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ]
  ```
- `@shortdoc` + label string → Phase 91 wording.
- `ensure_no_args!/1` raise message → `"verify.phase91 does not accept arguments, …"`.

**Load-bearing details (do NOT drop):**
- `Mix.Task.reenable("test")` and `reenable("docs")` are mandatory — `app.start` consumes the task lock; omitting them silently no-ops the second run.
- Tests run via `Mix.Task.run("test", args)` (in-process), NOT `System.cmd`.
- Final step is always `Mix.Task.run("docs", ["--warnings-as-errors"])` — the `verify.phaseNN stays wired` test asserts this literal string.

**Out of scope (Pitfall 4):** Do NOT add example smoke test paths (`examples/.../test/smoke/...`) to `@focused_tests`. Those require live Meilisearch and run on a separate surface (`phoenix-example-integration` CI / `mix verify.adopter --live`).

---

### `mix.exs` `preferred_envs` (EDIT, ~line 58) — 91-02 / D-10, Pitfall 3

**Analog:** the existing `preferred_envs` keyword block in `cli/0` (`mix.exs:39-71`).

**Existing entries to mirror** (`mix.exs:55-58`):
```elixir
        "verify.phase82": :test,
        "verify.phase83": :test,
        "verify.phase84": :test,
        "verify.phase85": :test,
```

**Change:** add `"verify.phase91": :test` to this list (placement after `verify.phase85` is conventional). Without it the task runs under `:dev` and cannot load `test/...` files. The docs-contract `verify.phase91 stays wired` test (below) asserts `String.contains?(File.read!("mix.exs"), "\"verify.phase91\": :test")`, so this is doubly required.

---

### `test/scrypath/docs_contract_test.exs` (EDIT) — 91-02 / D-11, D-12, TEST-02

This file gets **three coordinated edits**. It is a `String.contains?` substring contract — no fuzzy matching (Pitfall 2), so every asserted string must literally appear in the rewritten guide and `verify.phase91.ex`.

#### Edit A — register `@verify_phase91` attribute (D-12, near line 29)

**Analog** (`docs_contract_test.exs:26-29`):
```elixir
  @verify_phase82 File.read!("lib/mix/tasks/verify.phase82.ex")
  @verify_phase83 File.read!("lib/mix/tasks/verify.phase83.ex")
  @verify_phase84 File.read!("lib/mix/tasks/verify.phase84.ex")
  @verify_phase85 File.read!("lib/mix/tasks/verify.phase85.ex")
```
**Add:** `@verify_phase91 File.read!("lib/mix/tasks/verify.phase91.ex")` immediately after line 29.

#### Edit B — add the "verify.phase91 stays wired" test (D-12)

**Analog** — copy the `verify.phase85 stays wired` test verbatim (`docs_contract_test.exs:333-340`):
```elixir
  test "verify.phase85 stays wired into the focused maintainer flow" do
    assert String.contains?(@verify_phase85, "test/scrypath/composition_test.exs")
    assert String.contains?(@verify_phase85, "test/scrypath/metadata_test.exs")
    assert String.contains?(@verify_phase85, "test/scrypath/composition_many_test.exs")
    assert String.contains?(@verify_phase85, "test/scrypath/docs_contract_test.exs")
    assert String.contains?(@verify_phase85, "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])")
    assert String.contains?(File.read!("mix.exs"), "\"verify.phase85\": :test")
  end
```
**Phase 91 version (swap the asserted test paths to match `@focused_tests`):**
```elixir
  test "verify.phase91 stays wired into the focused maintainer flow" do
    assert String.contains?(@verify_phase91, "test/scrypath/sync/related_test.exs")
    assert String.contains?(@verify_phase91, "test/scrypath/sync/related_worker_test.exs")
    assert String.contains?(@verify_phase91, "test/scrypath/docs_contract_test.exs")
    assert String.contains?(@verify_phase91, "Mix.Task.run(\"docs\", [\"--warnings-as-errors\"])")
    assert String.contains?(File.read!("mix.exs"), "\"verify.phase91\": :test")
  end
```

#### Edit C — invert the related-data assertion (D-11, line 1128–1136)

**Current test to REPLACE** (`docs_contract_test.exs:1128-1136`):
```elixir
  test "related-data guide explicitly mentions temporary Oban workaround" do
    guide = @guides["guides/related-data-and-reindexing.md"]

    assert_contains_all(guide, [
      "temporary workaround",
      "first-class feature",
      "Oban"
    ])
  end
```
The guide key `"guides/related-data-and-reindexing.md"` is already registered in `@guide_paths` (line 54) and materialized in `@guides` (line 56) — no change needed there.

**Inverted shape (D-11; exact boundary strings are Claude's discretion but MUST appear verbatim in the rewritten guide — coordinate 91-01 + 91-02):**
```elixir
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
      "callback magic"   # no-callback-magic invariant; guide already says this at line 305
    ])
    # plus: assert the context-owned-orchestration vs library-owned-execution boundary phrasing
    # (a string the rewritten guide literally contains).
  end
```

**Helpers available (read-only — do not modify):**
- `assert_contains_all/2` (`docs_contract_test.exs:1150-1155`): literal `String.contains?` over each snippet.
- `extract_elixir_fences/1` (`1144-1148`): pulls ```` ```elixir ```` fence bodies.
- `ordered?/3` (`1157-1167`): asserts `first` appears before `second` via `:binary.match`.

---

### `guides/related-data-and-reindexing.md` (EDIT) — 91-01 / D-06..D-09, EXEC-02

**Analog:** the file itself. Two regions change; the rest of the file's voice is preserved.

**Region 1 — DELETE + REPLACE the `### Temporary Workaround: Custom Oban Jobs` subsection** (lines 82–135). This is the custom `MyApp.Blog.SyncAuthorPostsWorker` (lines 88–110) + the `MyApp.Accounts.update_author` enqueue (lines 115–134). Per D-06/D-07 it is removed entirely (not retained as an alternative) and replaced with a canonical "fan-out with `Scrypath.sync_related/3`" section showing:
  - (a) schema-side `fan_outs:` on the OWNING schema (Author declaring a fan-out to Post);
  - (b) context-side call for BOTH `sync_mode: :inline` and `sync_mode: :oban`;
  - the resolver-arity-safe resolver (handles records AND ids).

**Region 2 — EXTEND "Picking the right follow-up path"** (lines 176–220) per D-08/EXEC-02:
- Keep the existing inline / `:oban` / manual split (lines 178–220).
- Keep the honesty block verbatim and attach it to the `:oban` path (current lines 201–207):
  ```text
  Truth you can say:
  - "the follow-up work is durably queued"
  Truth you cannot say:
  - "all affected documents are searchable now"
  ```
- ADD the `RelatedWorker` retry/cancel outcomes (D-04) — see Shared Pattern "Oban failure matrix" below.

**Voice anchors to preserve (D-07/D-09):**
- Line 16: `**Scrypath does not hide cross-record invalidation behind callback magic. Your app owns the fan-out.**`
- Line 174: `The important invariant is that web modules still do not own this logic.`
- Lines 299–305 ("What Scrypath should stay opinionated about"): `contexts own orchestration`, `related-data propagation is explicit`, `use Scrypath stays metadata-only`, and the `callback magic` sentence (line 305).
- Line 255 authz warning ("index prefixes alone are [not] your authorization model") — preserve.
- Worked example motif: Author rename → re-sync posts that store `author_name` (lines 9, 60, 168).

**Strings that must NOT survive anywhere in the guide (D-09):** `temporary workaround`, `first-class feature`.

**Canonical inline / oban call snippets to embed** (signatures verbatim from shipped API):
```elixir
# inline (context-side)
{:ok, %{mode: :inline, status: :completed}} =
  Scrypath.sync_related(Author, updated_author,
    fan_out: :posts, sync_mode: :inline, backend: Scrypath.Meilisearch)

# oban (context-side) — "durably queued", NOT "searchable now"
{:ok, %{mode: :oban, status: :accepted}} =
  Scrypath.sync_related(Author, updated_author,
    fan_out: :posts, sync_mode: :oban, oban: MyApp.Oban,
    oban_queue: :scrypath, backend: Scrypath.Meilisearch)
```

---

### `examples/.../lib/scrypath_demo/blog/author.ex` (NEW — example schema, fan-out owner) — 91-03 / D-13, D-02

**Analogs:** `examples/.../lib/scrypath_demo/blog/post.ex` (the `use Scrypath` + `schema` shape) AND `related_test.exs:39-46` (the `fan_outs:` keyword shape, validated by `options.ex:827-838` → each entry needs `target:` module + `resolver:` MFA tuple).

**Post.ex `use Scrypath` shape to mirror** (`post.ex:1-22`):
```elixir
defmodule ScrypathDemo.Blog.Post do
  @moduledoc false
  use Ecto.Schema

  use Scrypath,
    fields: [:title, :body],
    filterable: [:status],
    sortable: [:inserted_at]

  schema "posts" do
    field(:title, :string)
    field(:body, :string)
    field(:status, :string)
    timestamps()
  end

  def changeset(post, attrs) do
    post
    |> Ecto.Changeset.cast(attrs, [:title, :body, :status])
    |> Ecto.Changeset.validate_required([:title, :body, :status])
  end
end
```

**`fan_outs:` declaration to add on the OWNING (Author) schema** — keys validated by `options.ex` (`target:` must be a module — `fetch_and_validate_module/2`, line 840; `resolver:` must be `{mod, fun, args}` — `fetch_and_validate_mfa/2`, line 848):
```elixir
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
```
**Note:** `fan_outs:` lives on the OWNING schema (Author), never on Post (D-02, RESEARCH).

---

### `examples/.../lib/scrypath_demo/blog.ex` (NEW — example context) — 91-03 / D-13, D-15, D-05

**No direct in-repo analog** (no `blog.ex` exists today — confirmed by `find`). Composed from: RESEARCH Pattern 3 + the two arity sites (`sync.ex:92` inline records, `related_worker.ex:47` oban ids) + the two test resolvers (`related_test.exs:50` records, `related_worker_test.exs:60` ids).

**Two responsibilities (D-05 — context owns the decision, library owns execution):**

1. **`update_author/2-3`** — persist, keep denormalized `author_name` projection in sync (D-15, app-owned), then invoke the explicit fan-out:
   ```elixir
   def update_author(%Author{} = author, attrs, sync_opts) do
     {:ok, updated} = author |> Author.changeset(attrs) |> Repo.update()
     # (D-15) keep denormalized projection in sync — APP-OWNED, explicit, ordered BEFORE fan-out.
     {_n, _} =
       from(p in Post, where: p.author_id == ^updated.id)
       |> Repo.update_all(set: [author_name: updated.name])
     # explicit fan-out the context invokes (D-05) — not a callback.
     {:ok, _result} =
       Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts))
     {:ok, updated}
   end
   ```

2. **`resolve_posts_for_authors/1`** — the resolver MFA. **MUST handle both arities** (records inline, ids under oban). Funnel both to a reload-by-`author_id` query so the reload is uniform:
   ```elixir
   def resolve_posts_for_authors([%Author{} | _] = authors),
     do: authors |> Enum.map(& &1.id) |> reload_posts()
   def resolve_posts_for_authors([_id | _] = author_ids), do: reload_posts(author_ids)
   def resolve_posts_for_authors([]), do: []
   defp reload_posts(author_ids),
     do: Repo.all(from p in Post, where: p.author_id in ^author_ids)
   ```

**Why reload-by-id (not deref struct fields):** the `:oban` path discards the Author struct at enqueue (`related_worker.ex:102` keeps only `Identity.document_ids`), so the resolver can never trust `.name` to be loaded. The denormalized `posts.author_name` column makes the reload a flat Post query (no Author join) identical across both arities. (D-15 recommendation; the planner may pick the resolve-time-preload alternative instead, but it must stay app-owned per D-05.)

**Anti-patterns (RESEARCH):** resolver that handles only records OR only ids (#1 footgun); fan-out logic in a web/controller module or in Post schema (violates D-05); a library-side preload/`belongs_to` walk to make `author_name` appear (explicit D-05 non-goal).

---

### `examples/.../lib/scrypath_demo/blog/post.ex` (EDIT — example schema) — 91-03 / D-13, D-15

**Analog:** the file itself (shown above). Extend, do not rewrite.

**Edits:**
- Add `:author_name` to the `fields:` list (so the denormalized name is projected into the search doc): `fields: [:title, :body, :author_name]`.
- Add columns to `schema "posts"`: `field(:author_name, :string)` and `belongs_to(:author, ScrypathDemo.Blog.Author)`.
- Add `:author_id`, `:author_name` to the changeset cast list.

---

### `examples/.../priv/repo/migrations/2025…_add_authors_and_post_author_fields.exs` (NEW — migration) — 91-03 / D-13

**Analog:** `examples/.../priv/repo/migrations/20250418120000_create_posts.exs`:
```elixir
defmodule ScrypathDemo.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add(:title, :string)
      add(:body, :string)
      add(:status, :string)
      timestamps(type: :utc_datetime)
    end
  end
end
```

**This migration adds:** an `authors` table (`add(:name, :string)` + `timestamps`), `posts.author_id` (`add(:author_id, references(:authors))`), and `posts.author_name` (`add(:author_name, :string)`). Use a timestamp prefix later than `20250419000000` (the Oban migration) so ordering is correct. The example `test` alias (`mix.exs:67`) creates + migrates the test DB fresh, so no manual DB step.

---

### `examples/.../test/smoke/meilisearch_related_inline_stack_test.exs` (NEW — smoke test, inline fan-out) — 91-03 / D-14

**Analog:** `examples/.../test/smoke/meilisearch_stack_test.exs` (entire file — copy setup + teardown verbatim).

**Reusable scaffolding to copy verbatim** (`meilisearch_stack_test.exs`):
- `@moduletag :integration` + `use ScrypathDemo.DataCase, async: false` (lines 3, 5).
- `setup` block reading `SCRYPATH_MEILISEARCH_URL`, building a unique `prefix` (`phx_demo_#{System.unique_integer([:positive])}`), computing `live_index` via `Scrypath.Meilisearch.index_name/2`, and `on_exit(fn -> delete_index(url, live_index) end)` (lines 10–29).
- `delete_index/2` private helper using `Req.new` (lines 61–70).

**Body deviation (the new behavior):** insert an Author + a Post owned by it, rename the author via `ScrypathDemo.Blog.update_author/3` with `sync_mode: :inline`, then `Scrypath.search(Post, <new name>, …)` and assert the Post document reflects the new `author_name`. Assert `{:ok, %{mode: :inline, status: :completed}}` from the fan-out (the inline arity passes Author structs to the resolver — `sync.ex:92`).

---

### `examples/.../test/smoke/meilisearch_related_oban_stack_test.exs` (NEW — smoke test, oban fan-out) — 91-03 / D-14, Pitfall 5

**Analog:** `examples/.../test/smoke/meilisearch_oban_stack_test.exs` (copy setup + `await_search/5` + `delete_index/2`).

**Reusable scaffolding to copy** (`meilisearch_oban_stack_test.exs`):
- Same `@moduletag :integration` / `DataCase` / `setup` / `delete_index` as above, with an `oban`-flavored prefix (`phx_demo_oban_#{…}`).
- `await_search/5` retry helper (lines 60–81) — needed because Oban-driven upserts have visibility lag.
- Oban runs in-process via `config/test.exs:36` `config :scrypath_demo, Oban, testing: :inline`; module is `ScrypathDemo.Oban` (`lib/scrypath_demo/oban.ex:1`); queue `:scrypath` already declared (`config/config.exs:16`).

**CRITICAL deviation from the analog (Pitfall 5):** the existing Oban smoke asserts `job: %{worker: "Scrypath.Oban.UpsertWorker", state: "completed"}` (`meilisearch_oban_stack_test.exs:44`). The fan-out `:oban` path enqueues `Scrypath.Sync.RelatedWorker` (via `related_worker.ex:101 enqueue/4`), NOT `UpsertWorker`. So:
- Assert the fan-out result is `{:ok, %{mode: :oban, status: :accepted}}` (do NOT copy the `"Scrypath.Oban.UpsertWorker"` string).
- Verify the EFFECT: after the in-process job runs (`testing: :inline`), `await_search` finds the Post with the updated `author_name`.

Pass `sync_mode: :oban, oban: ScrypathDemo.Oban, oban_queue: :scrypath` through `update_author/3` (mirrors `meilisearch_oban_stack_test.exs:46-53`).

---

### `examples/.../README.md` (EDIT) — 91-03 / D-16

**Analog:** the README itself. Extend the existing dual-path narrative:
- Line 3 intro mentions `Scrypath.sync_record/3` + Oban — add the fan-out (`Scrypath.sync_related/3`) path.
- Lines 69–70 ("End-to-end smoke" → Inline / Oban) describe the two `sync_record` paths — add the inline + oban **fan-out** smoke tests alongside them (Author rename → re-sync posts).
- Line 33 (`SCRYPATH_EXAMPLE_INTEGRATION` row) already says "inline + Oban paths" — keep accurate as the fan-out smokes join the same gate.

---

## Shared Patterns

### Verify-task family shape
**Source:** `lib/mix/tasks/verify.phase85.ex` (whole file)
**Apply to:** `verify.phase91.ex`
`app.start` → `ensure_no_args!` → `run_test!(@focused_tests, label)` → `reenable("docs")` → `Mix.Task.run("docs", ["--warnings-as-errors"])`. The `reenable` calls are mandatory; the docs step is the literal string the contract test asserts.

### Discoverability registration (verify tasks)
**Source:** `mix.exs:55-58` (`preferred_envs`) + `docs_contract_test.exs:26-29` (`@verify_phaseNN` attrs) + `:333-340` (`stays wired` test)
**Apply to:** every new `verify.phaseNN` — register in all three places or it is invisible / runs in `:dev`.

### Resolver-arity-safe resolver
**Source:** `lib/scrypath/sync.ex:92` (inline → records) + `lib/scrypath/sync/related_worker.ex:47` (oban → ids); encoded by `related_test.exs:50` vs `related_worker_test.exs:60`
**Apply to:** every resolver shipped in the guide (91-01) and example Blog context (91-03). Pattern-match `[%Schema{} | _]` vs `[_id | _]`, funnel both to a reload-by-id query, never trust struct fields.

### Oban failure → outcome matrix (document verbatim, D-04)
**Source:** `lib/scrypath/sync/related_worker.ex:54-70` (the `perform/1` case) — read-only, do not edit
```elixir
case sync_result do
  :ok -> :ok
  {:ok, _result} -> :ok
  {:error, {:http_error, status, body}} when status in 400..499 ->
    {:cancel, "HTTP #{status}: #{inspect(body)}"}   # 4xx → permanent, no retry
  {:error, reason} -> {:error, reason}              # 5xx/generic → transient, Oban retries to max_attempts: 8
end
# invalid schema/fan_out (lines 67-70) → {:cancel, {:invalid_job, reason}}  # permanent
```
**Apply to:** the guide's "Picking the right follow-up path" section (91-01/D-08): adopters must see 4xx→cancel, 5xx/generic→retry, invalid→cancel, and the honesty boundary ("durably queued" ≠ "searchable now"). `max_attempts: 8` default is `related_worker.ex:5`.

### Smoke-test scaffolding (setup/teardown)
**Source:** `meilisearch_stack_test.exs:10-29,61-70` (setup + `delete_index`) and `meilisearch_oban_stack_test.exs:60-81` (`await_search`)
**Apply to:** both new fan-out smoke tests. Reuse `SCRYPATH_MEILISEARCH_URL` guard, unique-prefix index naming, `on_exit` index cleanup, and (oban) the `await_search` retry loop.

### Shipped API to document verbatim (read-only references)
| Symbol | Location | What to quote |
|--------|----------|---------------|
| `Scrypath.sync_related/3` `@spec` + `@doc` | `lib/scrypath.ex:186-195` | public entrypoint signature |
| inline dispatch + required `:fan_out` | `lib/scrypath/sync.ex:38-70` | `fan_out` raises `ArgumentError` if absent (line 42); `:oban` vs inline branch (53–60) |
| inline resolver arg = records | `lib/scrypath/sync.ex:92` | `apply(mod, fun, [records_list] ++ mfa_args)` |
| oban resolver arg = ids | `lib/scrypath/sync/related_worker.ex:47` | `apply(mod, fun, [document_ids] ++ mfa_args)` |
| enqueue keeps only ids | `lib/scrypath/sync/related_worker.ex:101-102` | `Identity.document_ids(schema_module, List.wrap(records))` |
| `fan_outs:` validation | `lib/scrypath/options.ex:806-857` | `target:` module + `resolver:` `{mod, fun, args}` |

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `examples/.../lib/scrypath_demo/blog.ex` | example context | request-response + event-driven | No context module exists in the example today (only `blog/post.ex` schema). Composed from RESEARCH Pattern 3 + the two arity sites. This is the only file with no direct in-repo analog; its `update_author/3` + `resolve_posts_for_authors/1` shape comes from the resolver-arity duality, not an existing file. |

> Everything else has a strong analog — this phase is deliberately a "copy the established shape" phase.

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/scrypath*.ex`, `lib/scrypath/sync/`, `lib/scrypath/options.ex`, `test/scrypath/docs_contract_test.exs`, `test/scrypath/sync/`, `guides/related-data-and-reindexing.md`, `examples/phoenix_meilisearch/{lib,priv,test,config,README.md}`, `mix.exs`
**Files scanned:** 18 (read) + structural greps across docs_contract_test, options.ex, example tree
**Pattern extraction date:** 2026-05-25
