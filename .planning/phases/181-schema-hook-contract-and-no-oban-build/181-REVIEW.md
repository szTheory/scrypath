---
phase: 181-schema-hook-contract-and-no-oban-build
reviewed: 2026-10-26T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - lib/mix/tasks/verify.no_optional_deps.ex
  - lib/mix/tasks/verify/capability.ex
  - lib/scrypath/oban/enqueue.ex
  - lib/scrypath/schema.ex
  - lib/scrypath/sync/related_enqueue.ex
  - test/mix/tasks/verify_capability_test.exs
  - test/mix/tasks/verify_no_optional_deps_test.exs
  - test/mix/tasks/workflow_wiring_test.exs
  - test/scrypath/schema_test.exs
  - CONTRIBUTING.md
findings:
  critical: 0
  warning: 3
  info: 5
  total: 8
status: issues_found
---

# Phase 181: Code Review Report

**Reviewed:** 2026-10-26T00:00:00Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Scope: `git diff f21cd4b1 HEAD`. That covers the isolated no-optional-deps build (181-01) and the `Scrypath.Schema` behaviour with its wrong-arity compile warning (181-02).

What I checked:
- The phase's four test files pass: 84 tests, 0 failures.
- `mix verify.no_optional_deps` runs green. Its isolated `_build/no_optional_deps/lib` has no `oban` directory.
- The `RelatedEnqueue` refactor keeps the same job options as before (queue, max_attempts, `unique: Enqueue.unique_opts()`). Without Oban, the public `Sync.sync_related` path is still guarded first by `Config.ensure_oban_ready!/1`.
- I probed the hook check with scratch modules. A wrong-arity `def` warns. Default-argument definitions (`def search_records(ids, ctx \\ %{})`) stay silent. A `defmacro` hook gets Elixir's own behaviour diagnostic.

I found no blockers. The problems are:
- One callback doc gives the wrong failure contract.
- Adding `@behaviour Scrypath.Schema` is a new source of compile warnings for adopters, and no upgrade note mentions it.
- One of the new HYG-02 guard tests is easy to get around.

## Warnings

### WR-01: `search_document_id/1` callback doc says enqueue returns an error tuple, but it raises

**File:** `lib/scrypath/schema.ex:62-65`
**Issue:** The new callback doc says: "without it, enqueueing returns `{:error, :search_records_required}`". In the code, every enqueue path calls `Loader.ensure_loadable!/2` before building a job:
- `Enqueue.upsert_job_changeset/4` (`lib/scrypath/oban/enqueue.ex:67`)
- `RelatedEnqueue.enqueue/4` (`lib/scrypath/sync/related_enqueue.ex:19`)

`Loader.ensure_loadable!/2` raises `ArgumentError` ("... defines search_document_id/1, so Oban sync cannot load its records by document id ...", `lib/scrypath/loader.ex:74-77`). `Sync.dispatch_upsert` and the telemetry span do not catch it. The `{:error, :search_records_required}` tuple only appears from `Loader.check_loadable/2` and inside the workers, where it cancels the job. An adopter who follows the doc and writes `{:error, :search_records_required} = Scrypath.sync_record(...)` crashes instead. This is a public hook contract, so it should match the code.
**Fix:**
```elixir
  `document_id:` field. If you sync through Oban, also define
  `c:search_records/2`, because the job cannot map a custom id back to a row:
  without it, enqueueing raises `ArgumentError` before any job is inserted.
```
Also add a test that pins the raise, so the doc and the code cannot drift apart again.

### WR-02: Adding `@behaviour Scrypath.Schema` creates new warnings for existing adopters, and no upgrade note mentions it

**File:** `lib/scrypath/schema.ex:123` (also `:43-44`)
**Issue:** `use Scrypath` now adds `@behaviour Scrypath.Schema` to every schema module. A schema module may already use `@impl` for another behaviour and define `search_document/1`, `search_document_id/1` or `search_records/2` without `@impl`. That module now gets a new warning. I reproduced it:

`module attribute @impl was not set for function search_document/1 callback (specified in Scrypath.Schema)`

Adopters who compile with `--warnings-as-errors` will fail their build after upgrading, without changing any code. The moduledoc mentions this, but `CHANGELOG.md`, `guides/` and `README.md` do not. The commits are plain `feat(181-02): ...` with no `!` and no `BREAKING CHANGE:` footer, so release-please will not call it out either. Defining a hook as `defp` now also produces Elixir's behaviour warning, which is a second new warning source.
**Fix:** Add an upgrade note to the release notes. Either use a `BREAKING CHANGE:`/`!` footer on the squash commit, or add an explicit CHANGELOG/guide entry such as "schemas that use `@impl` elsewhere must mark hooks `@impl Scrypath.Schema`". Add a compile-diagnostics test with a mixed-behaviour fixture so the documented behaviour is pinned.

### WR-03: HYG-02 `no_warn_undefined` guard misses the keyword and multi-line `@compile` forms

**File:** `test/mix/tasks/workflow_wiring_test.exs:26-45`
**Issue:** The test claims "no_warn_undefined is limited to Oban modules". Its regex, `~r/@compile\s*\{\s*:no_warn_undefined\s*,\s*(.+?)\s*\}\s*$/m`, only matches the single-line tuple form. These forms would pass unseen:
- `@compile no_warn_undefined: [Foo]`, the common keyword form
- `@compile {:no_warn_undefined,\n  [Foo]}`, a tuple split across lines
- `@compile [no_warn_undefined: Foo]`
- `Module.put_attribute(__MODULE__, :compile, ...)`

Any of these could suppress undefined-function warnings for non-Oban modules. The `>= 3` count check does not catch this, because the three existing sites already satisfy it. The guard also gets the MFA form wrong: `{Oban, :insert, 2}` quotes to a `{:{}, ...}` node and would be rejected.
**Fix:** Search for the token and inspect the AST instead of matching text:
```elixir
for path <- Path.wildcard("lib/**/*.ex"),
    {_, _, _} = node <- collect_compile_attrs(Code.string_to_quoted!(File.read!(path))) ...
```
At minimum, add a raw `refute src =~ ~r/no_warn_undefined:/` check, and assert that every file containing `no_warn_undefined` is in the parsed `sites` set.

## Info

### IN-01: `@hooks` duplicates `@optional_callbacks`

**File:** `lib/scrypath/schema.ex:85-87`
**Issue:** The two lists are identical literals. The schema test compares the behaviour with `@hooks`, but nothing ties `@hooks` to the arity check if someone edits only one list.
**Fix:** Define `@hooks` once and write `@optional_callbacks @hooks`.

### IN-02: Wrong-arity check only looks at `def`, but the moduledoc promises a warning for any wrong-arity hook

**File:** `lib/scrypath/schema.ex:40-41, 91`
**Issue:** The check reads `Module.definitions_in(env.module, :def)`. A `defp search_records/1` or `defmacro search_document/2` is ignored at runtime but gets no warning, from Scrypath or from Elixir, because the name/arity is not a declared callback.
**Fix:** Also scan `:defp` and `:defmacro`, or narrow the moduledoc to "a public `def` at the wrong arity".

### IN-03: Probe for Oban-compiled code hard-codes one module, and the error message hard-codes "Oban"

**File:** `lib/mix/tasks/verify.no_optional_deps.ex:14, 102, 110`
**Issue:** Only `Scrypath.Oban.UpsertWorker.beam` is probed. `DeleteWorker` and `RelatedWorker` are compiled under the same condition and are not checked. `optional_deps/0` is generic, but the raise message always says "Oban was on the code path", which will be wrong once another optional dep exists.
**Fix:** Probe all three conditional worker beams, or glob `Elixir.Scrypath.Oban.*Worker.beam`. Make the message name the dep that was found.

### IN-04: Isolated build dir can leave the project when `MIX_BUILD_PATH` is set

**File:** `lib/mix/tasks/verify.no_optional_deps.ex:62-64`
**Issue:** `Path.dirname(Mix.Project.build_path())` with `MIX_BUILD_PATH=/tmp/build` resolves to `/tmp/no_optional_deps`. That directory is outside the project and shared between checkouts, and the task runs `File.rm_rf!` inside it.
**Fix:** Root the isolated build at `Path.join(Mix.Project.app_path() |> ..., "_build/no_optional_deps")`, or under `Mix.Project.build_path()` itself, for example `Path.join(Mix.Project.build_path(), "no_optional_deps")`.

### IN-05: Drift-guard regex depends on the variable being named `schema_module`

**File:** `test/scrypath/schema_test.exs:277`
**Issue:** A future probe such as `function_exported?(module, :search_facets, 1)` would not be seen, and the "declares every hook lib/ probes" guarantee would silently fail.
**Fix:** Match `function_exported\?\(\w+, :(search_[a-z_]+), (\d+)\)`, or collect probes from the AST.

---

_Reviewed: 2026-10-26T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
