---
phase: 91-integration-guides-and-verification
reviewed: 2026-05-25T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - examples/phoenix_meilisearch/README.md
  - examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex
  - examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex
  - examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex
  - examples/phoenix_meilisearch/priv/repo/migrations/20250420000000_add_authors_and_post_author_fields.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_related_inline_stack_test.exs
  - examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs
  - guides/related-data-and-reindexing.md
  - lib/mix/tasks/verify.phase91.ex
  - mix.exs
  - test/scrypath/docs_contract_test.exs
findings:
  critical: 2
  warning: 4
  info: 2
  total: 8
status: issues_found
---

# Phase 91: Code Review Report

**Reviewed:** 2026-05-25T00:00:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Phase 91 delivers the related-data fan-out integration example (Author to Post),
the companion guide (`guides/related-data-and-reindexing.md`), two smoke tests,
and the `verify.phase91` Mix task. The two-arity resolver pattern is
well-structured, the docs-contract test adds meaningful guide assertions, and the
overall conceptual shape is sound.

Two blockers require fixing before this ships:

1. The public guide (`guides/related-data-and-reindexing.md`) teaches
   `use Scrypath, fan_outs: [...]` as the canonical fan-out declaration, while the
   companion example source explicitly documents that this does **not** work — the
   macro does not generate `__scrypath__(:fan_outs)`. An adopter following only
   the guide will write silently broken code that crashes at runtime.
2. `ordered?/3` in `docs_contract_test.exs` raises an opaque `ArgumentError`
   (from `elem(:nomatch, 0)`) instead of a clear test failure when either needle
   is absent, turning any future content regression into a confusing crash.

Four warnings also need attention: the `Post` schema timestamp type diverges from
its migration, `blog.ex` promises error propagation but its bare matches crash
instead, the guide and implementation return different tuple arities from
`update_author/3`, and `await_search` in the Oban smoke test silently passes
search errors back to the assertion instead of calling `flunk`.

---

## Critical Issues

### CR-01: Guide teaches `use Scrypath, fan_outs:` which the library does not support

**File:** `guides/related-data-and-reindexing.md:101-131`

**Issue:** Section (a) of the fan-out walkthrough (lines 101–131) shows
`use Scrypath` with a `fan_outs:` key as the canonical declaration path. The
companion example schema (`blog/author.ex`, lines 17–21) explicitly documents
the opposite: *"The shipped `use Scrypath` declaration macro does not yet resolve
module aliases in `fan_outs:` at macro-expansion time, and it does not generate a
`__scrypath__(:fan_outs)` accessor, so the hand-written reflection is the correct,
library-respecting (read-only) declaration path."* The guide never mentions this
limitation, never shows the hand-written `def __scrypath__(:fan_outs)` and
`def __scrypath__(:document_id)` definitions, and the `DocsContractTest`
"all Elixir code fences" test validates only parse-level syntax
(`Code.string_to_quoted`), so the broken snippet passes CI. An adopter following
the guide will produce an `Author` schema with no `__scrypath__/1` accessor, and
`Scrypath.sync_related/3` will raise `UndefinedFunctionError` or
`FunctionClauseError` at runtime.

**Fix:** Replace the `use Scrypath, fan_outs:` snippet with the working
hand-written pattern and add an explanatory note:

```elixir
defmodule MyApp.Accounts.Author do
  use Ecto.Schema

  # NOTE: `use Scrypath` does not yet support fan_outs: at macro-expansion time.
  # Declare the fan-out accessors by hand until the macro is updated.
  def __scrypath__(:fan_outs) do
    [
      posts: [
        target: MyApp.Blog.Post,
        resolver: {MyApp.Accounts, :resolve_posts_for_authors, []}
      ]
    ]
  end

  def __scrypath__(:document_id), do: :id

  schema "authors" do
    field(:name, :string)
    has_many(:posts, MyApp.Blog.Post)
    timestamps()
  end

  def changeset(author, attrs) do
    author
    |> Ecto.Changeset.cast(attrs, [:name])
    |> Ecto.Changeset.validate_required([:name])
  end
end
```

Also add a `DocsContractTest` assertion that the guide contains
`def __scrypath__(:fan_outs)` so this cannot regress silently.

---

### CR-02: `ordered?/3` crashes with opaque `ArgumentError` when a needle is absent

**File:** `test/scrypath/docs_contract_test.exs:1178-1188`

**Issue:** `ordered?/3` calls `:binary.match(content, needle)` and then
`elem(result, 0)`. When either needle is absent, `:binary.match/2` returns the
atom `:nomatch` (not a `{position, length}` tuple). `elem(:nomatch, 0)` raises
`ArgumentError: not a tuple`. The resulting crash message names no file, no
needle, and no assertion — it is indistinguishable from a bug in the test
infrastructure. All 21 call sites of `ordered?` in the test file are affected,
as are the two direct `:binary.match` destructures at lines 385–386 (the
`lobby moduledoc two_hop` test).

**Fix:**

```elixir
defp ordered?(content, first, second) do
  case {:binary.match(content, first), :binary.match(content, second)} do
    {:nomatch, _} ->
      flunk("ordered? could not find first needle in content: #{inspect(first)}")

    {_, :nomatch} ->
      flunk("ordered? could not find second needle in content: #{inspect(second)}")

    {{first_index, _}, {second_index, _}} ->
      first_index < second_index
  end
end
```

For lines 385–386, replace the bare destructure with a guarded form:

```elixir
golden_pos =
  case :binary.match(doc, "guides/golden-path.md") do
    :nomatch -> flunk("missing 'guides/golden-path.md' in Scrypath @moduledoc")
    {pos, _} -> pos
  end

sync_pos =
  case :binary.match(doc, "guides/sync-modes-and-visibility.md") do
    :nomatch -> flunk("missing 'guides/sync-modes-and-visibility.md' in Scrypath @moduledoc")
    {pos, _} -> pos
  end
```

---

## Warnings

### WR-01: `Post` schema `timestamps()` type conflicts with migration `utc_datetime`

**File:** `examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex:16`

**Issue:** `Post` uses bare `timestamps()` which defaults to `:naive_datetime`
in Ecto. The creating migration (`20250418120000_create_posts.exs:10`) declares
`timestamps(type: :utc_datetime)`, matching the `Author` schema. The `Post`
schema also declares `sortable: [:inserted_at]` via `use Scrypath`, so
Meilisearch receives `:inserted_at` from this schema. At runtime Ecto reads the
column back as `NaiveDateTime` while the DB was written treating the column as a
UTC timestamp. This mismatch causes incorrect Elixir struct types on reads and
potentially wrong sort semantics for date-range queries. The project-level
`generators: [timestamp_type: :utc_datetime]` config only affects `mix phx.gen.*`
generators; it does not affect the runtime schema `timestamps()` default.

**Fix:**

```elixir
# examples/phoenix_meilisearch/lib/scrypath_demo/blog/post.ex
schema "posts" do
  field(:title, :string)
  field(:body, :string)
  field(:status, :string)
  field(:author_name, :string)
  belongs_to(:author, ScrypathDemo.Blog.Author)
  timestamps(type: :utc_datetime)   # was: timestamps()
end
```

---

### WR-02: `update_author/3` doc claims error propagation but bare matches crash instead

**File:** `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex:35-48`

**Issue:** The `@doc` states: *"Propagates errors from Repo or Scrypath on
failure."* Lines 38 and 45 use bare `{:ok, _} = ...` matches. If
`Repo.update/1` returns `{:error, %Ecto.Changeset{}}` or
`Scrypath.sync_related/3` returns `{:error, reason}`, the function raises a
`MatchError` rather than returning `{:error, _}`. The smoke tests never exercise
this failure path, so the defect is invisible in CI. Adopters reading the `@doc`
and the guide's companion snippet (which has the same pattern) will believe the
function returns structured errors.

**Fix:**

```elixir
def update_author(%Author{} = author, attrs, sync_opts) do
  with {:ok, updated} <- author |> Author.changeset(attrs) |> Repo.update(),
       _ <- (from(p in Post, where: p.author_id == ^updated.id)
             |> Repo.update_all(set: [author_name: updated.name])),
       {:ok, result} <-
         Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts)) do
    {:ok, result, updated}
  end
end
```

Or, if the intent is to let the function raise on failure (acceptable for an
example), remove the misleading "Propagates errors" sentence from the `@doc`.

---

### WR-03: Guide `update_author` example returns 2-tuple; canonical implementation returns 3-tuple

**File:** `guides/related-data-and-reindexing.md:202-218`

**Issue:** The guide's section (c) code block (around line 202) shows
`update_author/3` ending with `{:ok, updated}` (a 2-tuple). The actual example
implementation at `blog.ex:48` returns `{:ok, result, updated}` (a 3-tuple), and
both smoke tests assert the 3-tuple shape:

```elixir
assert {:ok, %{mode: :inline, status: :completed}, _updated_author} =
         Blog.update_author(author, %{name: "Renamed Author"}, sync_opts)
```

An adopter who copies the guide's context module will write a function returning
`{:ok, updated}`. If they also copy the test pattern, the assertion will fail with
a match error. The guide and the reference implementation teach inconsistent
return shapes.

**Fix:** Update the guide's `update_author` example to return the 3-tuple:

```elixir
    {:ok, result} =
      Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts))

    {:ok, result, updated}   # was: {:ok, updated}
```

---

### WR-04: `await_search` passes search errors back to the caller instead of failing immediately

**File:** `examples/phoenix_meilisearch/test/smoke/meilisearch_related_oban_stack_test.exs:105-106`

**Issue:** The `other ->` branch in `await_search/5` returns the value to the
caller rather than calling `flunk/1`. If `Scrypath.search/3` returns
`{:error, reason}` (network failure, index not found, misconfigured URL), the
function returns `{:error, reason}` and the subsequent
`assert {:ok, result} = await_search(...)` at line 82 fails with a pattern-match
error. The error message will say something like "no match of right hand side
value: {:error, :econnrefused}" rather than "search returned error: ..." —
making live CI failures harder to diagnose.

**Fix:**

```elixir
other ->
  flunk("await_search: unexpected result from Scrypath.search/3: #{inspect(other)}")
```

---

## Info

### IN-01: Internal planning decision IDs (`(D-NN)`) in example module comments

**File:** `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex:5,8,10,40,44`
**File:** `examples/phoenix_meilisearch/lib/scrypath_demo/blog/author.ex:30`

**Issue:** `@moduledoc` and inline comments reference internal planning
annotations: `(D-05)`, `(D-15)` (blog.ex), and `(D-02)` (author.ex). The
`examples/` directory is not in the Hex package `files:` list, so these
annotations will not reach adopters via Hex. However, they are visible in the
public GitHub repository and will confuse outside contributors who cannot resolve
these IDs without access to the internal planning archive. The published guide
correctly omits such references.

**Fix:** Replace inline decision references with plain-English rationale that
mirrors the language used in the guide. For example:

```elixir
# Keep denormalized projection in sync — app-owned, explicit, ordered BEFORE fan-out.
```

---

### IN-02: `run_test!/2` parameter named `args` is misleading given local `args` naming convention

**File:** `lib/mix/tasks/verify.phase91.ex:25-29`

**Issue:** The private function `run_test!(args, label)` receives
`@focused_tests` (a static list of `.exs` file paths) as its first argument, but
the parameter is named `args`. In the surrounding Mix task context, `args` refers
to command-line arguments. This naming implies the helper is general-purpose or
forwards user arguments, when it only ever receives a static test-path list.

**Fix:**

```elixir
defp run_test!(test_paths, label) do
  Mix.shell().info("==> Running #{label}")
  Mix.Task.reenable("test")
  Mix.Task.run("test", test_paths)
end
```

---

_Reviewed: 2026-05-25T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
