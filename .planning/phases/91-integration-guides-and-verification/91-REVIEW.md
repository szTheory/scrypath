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
  warning: 3
  info: 2
  total: 7
status: issues_found
---

# Phase 91: Code Review Report

**Reviewed:** 2026-05-25T00:00:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Reviewed the Phase 91 integration guides, example app, smoke tests, verify task, and docs-contract test. The implementation introduces `Scrypath.sync_related/3` fan-out patterns and the `related-data-and-reindexing.md` guide.

Two blockers were found. The most serious is that the public guide (`guides/related-data-and-reindexing.md`) teaches `use Scrypath, fan_outs: [...]` as the working declaration path, while the canonical example's own source code (`blog/author.ex`) explicitly documents this does NOT work — the macro does not support `fan_outs:` yet. An adopter following the guide will write non-functional code. The second blocker is a crash-producing bug in `DocsContractTest.ordered?/3`: `:binary.match/2` returns `:nomatch` (an atom, not a tuple) when either needle is absent from content, and the immediately following `elem(:nomatch, 0)` raises `ArgumentError` instead of producing a useful test failure message. This silently turns a content-contract violation into an uninformative runtime crash.

---

## Critical Issues

### CR-01: Guide teaches `use Scrypath, fan_outs:` which the library does not support

**File:** `guides/related-data-and-reindexing.md:102-125`
**Issue:** Section (a) of the fan-out walkthrough shows this as the canonical declaration:

```elixir
use Scrypath,
  fields: [:name],
  fan_outs: [
    posts: [
      target: MyApp.Blog.Post,
      resolver: {MyApp.Accounts, :resolve_posts_for_authors, []}
    ]
  ]
```

The Author schema in the companion example (`blog/author.ex`, lines 17–21) explicitly states: _"The shipped `use Scrypath` declaration macro does not yet resolve module aliases in `fan_outs:` at macro-expansion time, and it does not generate a `__scrypath__(:fan_outs)` accessor, so the hand-written reflection is the correct, library-respecting (read-only) declaration path."_

The guide never mentions this limitation, never shows the working `def __scrypath__(:fan_outs)` / `def __scrypath__(:document_id)` hand-written definitions, and the `DocsContractTest` "all Elixir code fences" test only validates parse-level syntax (`Code.string_to_quoted`), so the broken snippet passes CI. An adopter following the guide will write schema code that silently omits the `__scrypath__/1` accessor, causing `sync_related/3` to raise `FunctionClauseError` at runtime when it calls `schema_module.__scrypath__(:fan_outs)`.

**Fix:** Replace the `use Scrypath, fan_outs:` snippet in section (a) of the guide with the working hand-written reflection pattern and add a note explaining the macro limitation:

```elixir
defmodule MyApp.Accounts.Author do
  use Ecto.Schema

  # NOTE: `use Scrypath` does not yet support `fan_outs:` at macro-expansion time.
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

Also add a corresponding contract assertion to `DocsContractTest` that the guide contains `def __scrypath__(:fan_outs)` so this does not regress silently.

---

### CR-02: `ordered?/3` in `DocsContractTest` crashes with `ArgumentError` instead of failing with a useful message when a needle is absent

**File:** `test/scrypath/docs_contract_test.exs:1176-1186`
**Issue:** The helper calls `:binary.match(content, needle)` and immediately pattern-matches with `elem(result, 0)`. When either needle is not present in `content`, `:binary.match/2` returns the atom `:nomatch`, not a tuple. `elem(:nomatch, 0)` then raises:

```
** (ArgumentError) errors were found at the given arguments:
  * 2nd argument: not a tuple
```

This produces a confusing crash instead of a failing assertion. Twenty-one call sites in the test file (every `assert ordered?(...)` call) are affected. A regressed doc — one where a required phrase was accidentally removed — will produce an opaque ArgumentError rather than clearly naming which phrase is missing or which ordering invariant broke.

The same crash applies to the two direct `:binary.match` calls at lines 385–386 (the `lobby moduledoc two_hop` test), which destructure the return value with `{pos, _} = :binary.match(...)` directly.

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

For the direct `:binary.match` calls at lines 385–386:
```elixir
case :binary.match(doc, "guides/golden-path.md") do
  :nomatch -> flunk("missing guides/golden-path.md in Scrypath @moduledoc")
  {golden_pos, _} -> golden_pos
end
```

---

## Warnings

### WR-01: `update_author/3` doc claims error propagation but implementation crashes on error

**File:** `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex:37-48`
**Issue:** The `@doc` states: _"Propagates errors from Repo or Scrypath on failure."_ The implementation uses bare pattern matches:

```elixir
{:ok, updated} = author |> Author.changeset(attrs) |> Repo.update()
...
{:ok, result} = Scrypath.sync_related(Author, updated, ...)
```

If either returns `{:error, reason}`, Elixir raises a `MatchError` — the error is not propagated, it is thrown as an exception. An adopter reading the @doc will expect an `{:error, reason}` return, not a process crash.

**Fix:** Either update the `@doc` to accurately state the function raises on failure (and remove the "Propagates errors" clause), or implement actual error propagation:

```elixir
def update_author(%Author{} = author, attrs, sync_opts) do
  with {:ok, updated} <- author |> Author.changeset(attrs) |> Repo.update(),
       _ <- (from(p in Post, where: p.author_id == ^updated.id)
             |> Repo.update_all(set: [author_name: updated.name])),
       {:ok, result} <- Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts)) do
    {:ok, result, updated}
  end
end
```

---

### WR-02: Guide `update_author` example returns `{:ok, updated}` but canonical implementation returns `{:ok, result, updated}`

**File:** `guides/related-data-and-reindexing.md:193` / `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex:48`
**Issue:** The guide's section (c) code block shows `update_author/3` returning `{:ok, updated}` (2-tuple). The actual example implementation in `blog.ex` returns `{:ok, result, updated}` (3-tuple), and the smoke tests assert the 3-tuple shape (e.g., `assert {:ok, %{mode: :inline, status: :completed}, _updated_author} = Blog.update_author(...)`).

An adopter copying the guide's context module will have a function that returns a 2-tuple, which their callers will pattern-match incorrectly if they use the test assertions as a model. The guide and canonical example diverge on a publicly visible API shape.

**Fix:** Update the guide's `update_author` example return value to match the canonical example:

```elixir
    {:ok, result} =
      Scrypath.sync_related(Author, updated, Keyword.put(sync_opts, :fan_out, :posts))

    {:ok, result, updated}   # was: {:ok, updated}
```

---

### WR-03: `Repo.update_all` return value silently discarded in `blog.ex` — contradicts the guide's own example

**File:** `examples/phoenix_meilisearch/lib/scrypath_demo/blog.ex:41-43`
**Issue:** The call to `Repo.update_all/2` discards its return value entirely:

```elixir
from(p in Post, where: p.author_id == ^updated.id)
|> Repo.update_all(set: [author_name: updated.name])
```

`Repo.update_all` returns `{count, results}` on success and raises on a connection or transaction error. Silently dropping the return value means the update count is never available for logging or assertion, and is inconsistent with the guide's own canonical code (lines 185–187 of the guide show `{_count, _} =` binding). Beyond the inconsistency, silently discarding the result makes it easy to miss if the function is later refactored to a version that could return `{:error, reason}`.

**Fix:** Bind the return value to match the guide's own example:

```elixir
{_count, _} =
  from(p in Post, where: p.author_id == ^updated.id)
  |> Repo.update_all(set: [author_name: updated.name])
```

---

## Info

### IN-01: `run_test!/2` parameter named `args` actually receives a list of test file paths

**File:** `lib/mix/tasks/verify.phase91.ex:25-29`
**Issue:** The private function `run_test!(args, label)` receives `@focused_tests` (a list of `.exs` file paths) as its first argument, but the parameter is named `args`. This is misleading because `args` in the surrounding context means command-line arguments to the Mix task. The naming choice implies the function is flexible enough to forward user-supplied arguments, but it only ever receives the static `@focused_tests` list.

**Fix:** Rename the parameter to make the intent clear:

```elixir
defp run_test!(test_paths, label) do
  Mix.shell().info("==> Running #{label}")
  Mix.Task.reenable("test")
  Mix.Task.run("test", test_paths)
end
```

---

### IN-02: Migration adds `author_id` foreign key without an `on_delete:` action

**File:** `examples/phoenix_meilisearch/priv/repo/migrations/20250420000000_add_authors_and_post_author_fields.exs:12`
**Issue:** `add(:author_id, references(:authors))` creates a foreign key with no `on_delete:` strategy. When an `Author` is deleted, the database will raise a foreign key constraint error because posts still reference it. This is likely intentional (example app doesn't implement author deletion), but it leaves adopters who copy this migration pattern without guidance on how to handle the case.

**Fix:** For the example app, explicitly document the intent. For production guidance, recommend declaring `on_delete: :nilify_all` or `:restrict` explicitly:

```elixir
add(:author_id, references(:authors, on_delete: :nilify_all))
```

---

_Reviewed: 2026-05-25T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
