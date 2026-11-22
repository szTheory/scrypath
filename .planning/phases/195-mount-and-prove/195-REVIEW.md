---
phase: 195-mount-and-prove
reviewed: 2026-11-21T23:40:00Z
depth: standard
files_reviewed: 28
files_reviewed_list:
  - .formatter.exs
  - examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh
  - scrypath_ops/.formatter.exs
  - scrypath_ops/assets/js/storybook.js
  - scrypath_ops/catalog/lib/scrypath_ops/catalog/storybook.ex
  - scrypath_ops/config/config.exs
  - scrypath_ops/config/dev.exs
  - scrypath_ops/config/test.exs
  - scrypath_ops/lib/scrypath_ops_web/dev_router.ex
  - scrypath_ops/lib/scrypath_ops_web/optional_catalog_routes.ex
  - scrypath_ops/mix.exs
  - scrypath_ops/storybook/primitives/ops_badge.story.exs
  - scrypath_ops/storybook/primitives/ops_button.story.exs
  - scrypath_ops/storybook/primitives/ops_empty_state.story.exs
  - scrypath_ops/storybook/primitives/ops_panel.story.exs
  - scrypath_ops/storybook/primitives/ops_sync_status.story.exs
  - scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs
  - scrypath_ops/test/scrypath_ops_web/catalog_routes_test.exs
  - scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs
  - scrypath_ops/test/support/catalog/planted_endpoint.ex
  - scrypath_ops/test/support/catalog/planted_router.ex
  - scrypath_ops/test/support/catalog/planted_storybook.ex
  - scrypath_ops/test/support/catalog_render_all.ex
  - scrypath_ops/test/support/storybook_planted/failing/boom.story.exs
  - scrypath_ops/test/support/storybook_planted/failing/empty.story.exs
  - test/mix/tasks/dependency_boundary_contract_test.exs
  - test/release/ops_dependency_boundary_test.exs
  - test/release/package_metadata_test.exs
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
  necessity: 2
status: issues_found
---

# Phase 195: Code Review Report

**Reviewed:** 2026-11-21T23:40:00Z
**Depth:** standard
**Files Reviewed:** 28
**Status:** issues_found

## Summary

I reviewed the mount (route macro, config, dependency declaration), the five stories, the catalog tests and
their planted failures, the three boundary test files, and the Docker boundary script. I also read the
resolved `phoenix_storybook` 1.5.0 and `phoenix_live_view` sources in `scrypath_ops/deps` to check claims
the tests make about them, and ran what I could locally: the 8 storybook-boundary tests at the repo root
and the 22 ops tests in the three catalog and shell contract files all pass. A rebuild of
`assets/js/storybook.js` with the pinned esbuild is byte-identical to the tracked bundle, so the generated
file is not stale today.

The design holds up on the high-stakes properties. The `/storybook` routes sit behind two independent
guards (the `:catalog_routes` flag and `Code.ensure_loaded?(PhoenixStorybook.Router)`), the dependency is
`only: [:dev, :test]`, mounted consumers compile `scrypath_ops` as `:prod`, and each boundary test has a
planted failure that does fail. I found no Critical issue. The strongest finding is WR-01: the flag guard
is read at compile time through an untracked call, and I reproduced a state on the real router where the
flag is `false`, the test endpoint binds `0.0.0.0` and 8 `/storybook` routes are compiled in. That is the
residual the go/no-go records as accepted-low (item b); I am re-raising it because the exact fix is one
line and Mix then fails loudly instead of silently.

Premise check on "the playground can run code": in `phoenix_storybook` 1.5.0 I could not find a path from
client input to `Code.eval*`. The `{:eval, _}` attribute tuples come only from story files
(`rendering/component_renderer.ex:168-215`, `live/story/playground.ex:1087-1112` casts client values to
strings, integers and existing atoms and passes them as runtime assigns). The loopback and flag guards are
therefore defense in depth for an unauthenticated component viewer, not the only barrier against remote
code execution. That lowers the stakes of WR-01 but does not remove the invariant the tests pin.

Examined and not reported: `check_origin: false` in `dev.exs` (a Phoenix default, and the storybook adds no
state-changing server action); the `printf | grep -q` under `pipefail` in the Docker script (the real
`mix deps` output is 3.6 KB for prod and 4.7 KB for test, a single write, so SIGPIPE cannot hide a match
today); `runtime.exs` overriding the loopback bind (it only deep-merges `port`; I confirmed the bind stays
`127.0.0.1` when `PHX_SERVER` is not `true`).

## Warnings

### WR-01: Catalog flag is read with untracked `Application.get_env`, so a stale router keeps `/storybook` on a `0.0.0.0` bind

**File:** `scrypath_ops/lib/scrypath_ops_web/optional_catalog_routes.ex:8-11` (also `scrypath_ops/config/test.exs:32`, `test/mix/tasks/dependency_boundary_contract_test.exs:832-838` and `:863-867`)

**Issue:** The macro reads the flag with `Application.get_env/3` at router expansion. Mix does not record
that read, so changing `PHX_SERVER` between two invocations in the same `_build` never recompiles
`DevRouter`. `config/test.exs` derives the flag (`PHX_SERVER != "true"`) and the bind (`PHX_SERVER == "true"`
gives `0.0.0.0`) from the same variable, which is the invariant `catalog_bind_violation/1` pins, but that
test reads config files only, not the compiled router.

Reproduced on the real code. After the normal `mix test` compile, this:

```
PHX_SERVER=true MIX_ENV=test mix run --no-start -e '...DevRouter.__routes__()...'
```

printed `%{catalog_routes_flag: false, bind_ip: {0, 0, 0, 0}, storybook_route_count: 8}`: flag off, all
interfaces, catalog mounted. A scratch Mix project shows the mechanism in isolation: a macro using
`Application.get_env` stays at its old value when only the environment variable flips (plain `mix compile`
is a no-op), while the same macro using `Application.compile_env(__CALLER__, ...)` makes `mix compile` abort
with "different value ... during runtime compared to compile time".

The Docker images are safe because they compile fresh with `PHX_SERVER=true` baked in (`Dockerfile:90-91`)
and the hosted 404 probe checks that. The exposure is a long-lived local `_build/test`, which the go/no-go
records as residual (b). The phase173 entrypoint (`phase173-standalone-entrypoint.sh`) itself runs
`PHX_SERVER=false mix ecto.create` and then `PHX_SERVER=true mix phx.server` against one `_build`, so the
result depends on which invocation compiled the router.

**Fix:** Use the macro-aware, tracked read (documented for macros, available on the Elixir 1.17 floor):

```elixir
defmacro catalog_routes do
  if enabled?(
       Application.compile_env(__CALLER__, :scrypath_ops, :catalog_routes, false),
       Code.ensure_loaded?(PhoenixStorybook.Router)
     ) do
    ...
```

This still returns a plain value (so the `Macro.expand` pitfall in the comment does not apply) and turns a
silent stale build into a loud Mix error. Update the tests with it: `catalog_flag_read?/1` must match
`[_env, :scrypath_ops, :catalog_routes | _]` for `compile_env`, and the `:drop_flag_read` mutation clause in
`mutate_catalog_guard/2` must match the new call shape. Re-run `catalog_routes_test.exs` (it sets the flag
with `Application.put_env` before compiling quoted routers) to confirm the flag-off and flag-on cases still
behave.

### WR-02: Impossible-state guard: the `[data-phx-error]` check can never fire

**File:** `scrypath_ops/test/support/catalog_render_all.ex:46-48`
**Category:** necessity
**Issue:** `problems/1` fails a render when `[data-phx-error]` is present, but the server never emits that
attribute. The source comment says so ("Kept for the requirement wording"), and I confirmed it: there is no
`data-phx-error` in `deps/phoenix_live_view/lib` or `deps/phoenix_storybook/lib`; `phx-error` is a
client-side class added by the browser JS, and `Phoenix.LiveViewTest` runs no client JS. The planted case
(`catalog_contract_test.exs:127-137`) proves only that the helper matches an attribute the test injects by
hand with `String.replace`. A reader of the contract ("fails on empty output or `data-phx-error`") is told
a failure signal exists that cannot occur, while the real signals (a crash, empty output, an unknown
variation id) are the planted tree's job.
**Fix:** Delete the selector tuple and the `marked` planted block (the `problems(marked) ==
["data-phx-error present"]` assertion), keep the crash, empty and unknown-variation plants as the contract,
and reword the requirement text that names `data-phx-error`. If the wording must stay, say next to it that
it is unreachable in this stack.

### WR-03: The tracked storybook bundle's freshness check only greps hook names

**File:** `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs:322-333` (build note at `scrypath_ops/config/config.exs:50-56`)
**Issue:** `priv/static/assets/js/storybook.js` is a generated artifact built by hand
(`MIX_ENV=dev mix esbuild scrypath_ops_storybook`) and deliberately kept out of `assets.build`, so no CI
step rebuilds it. It bundles seven modules (`ops_notifications`, `ops_clipboard`, `ops_time`, `ops_hooks`,
`ops_validation`, `ops_search`, `storybook`), six of them shared with `app.js`. The "freshness" test only
asserts that the bundle contains `window.storybook`, `data-theme` and the nine hook names, and the comment
credits the render-all `?hash=` assertion with proving it is served, which proves the file exists, not that
it is current. Changing any shared hook body leaves the catalog rendering stale behavior with every test
green, and fidelity with the real app is the reason the bundle exists. (I rebuilt it from the current
sources and it matches byte for byte, so there is no defect today.)
**Fix:** Make staleness fail. Commit a digest of the bundle's inputs next to it and have the test recompute
it, for example:

```elixir
inputs = ~w(storybook ops_hooks ops_search ops_notifications ops_clipboard ops_time ops_validation)
digest = inputs |> Enum.map_join(&File.read!(Path.join("assets/js", &1 <> ".js"))) |> sha256()
assert digest == File.read!("priv/static/assets/js/storybook.js.inputs.sha256") |> String.trim()
```

Generate both files from one alias (`assets.storybook`) so the manual step cannot write one without the
other, and derive the input list from esbuild's `--metafile` instead of hardcoding it.

## Info

### IN-01: Planted mutant 1 in the Docker-script test is malformed shell

**File:** `test/mix/tasks/dependency_boundary_contract_test.exs:744-745`
**Issue:** The first mutant replaces `forbidden_deps="$forbidden_deps phoenix_storybook mdex mdex_native"`
with `forbidden_deps="$forbidden_deps phoenix_storybook mdex` (the closing `"` is gone). It is still caught,
but because the `conditional` regex no longer matches a broken line, not because `mdex_native` was dropped,
so it does not isolate the deletion it names.
**Fix:** Keep the quote: `~s(forbidden_deps="$forbidden_deps phoenix_storybook mdex")`.

### IN-02: `refute "storybook"` and `refute "fixtures"` in `package.files` guard names that do not exist

**File:** `test/release/package_metadata_test.exs:135-136`
**Category:** necessity
**Issue:** `package.files` is an allowlist (`lib`, `mix.exs`, `README.md`, `guides`, ...), and the repo root
has no `storybook/` or `fixtures/` directory (the stories live at `scrypath_ops/storybook`, already covered
by `refute "scrypath_ops"` at line 127). The two assertions can only fail if someone adds those exact names
to the list. This rests on judgment (they may anticipate a later phase adding root directories), hence Info.
**Fix:** Keep them only if a later phase creates those root directories; otherwise drop them and rely on the
allowlist plus the existing `scrypath_ops` refute.

### IN-03: The dev-tool bundle ships in the production static tree

**File:** `scrypath_ops/priv/static/assets/js/storybook.js` (served via `scrypath_ops/lib/scrypath_ops_web.ex:20`, `scrypath_ops/lib/scrypath_ops_web/endpoint.ex:26-29`, `Dockerfile:73,109`)
**Issue:** The tracked bundle is copied by `asset_builder` into the `runtime_prod` and `runtime_test`
images, digested by `phx.digest`, and served by `Plug.Static` (`only: assets`) and by `AssetPlug` for
mounted hosts. It is inert (the same public hook code as `app.js`, no secrets), but it is a catalog artifact
in a tree the boundary work promises is catalog-free, and nothing asserts its absence.
**Fix:** Either delete it in the runtime stages after the `COPY --from=asset_builder` (`rm -f
.../assets/js/storybook.js`) and assert `test ! -e` in the runtime probe, or record it as accepted next to
the "`.dockerignore` skipped" choice.

### IN-04: Dev live reload does not watch the stories or the catalog backend

**File:** `scrypath_ops/config/dev.exs:58-69`
**Issue:** The `live_reload` patterns cover `lib/scrypath_ops_web/...` and `priv/static` only. Upstream's
setup guide (`deps/phoenix_storybook/guides/setup.md:174-178`) adds `~r"storybook/.*\.exs$"`. Editing a
`.story.exs` in dev will not refresh the browser.
**Fix:** Add `~r"storybook/.*\.exs$"` and `~r"catalog/lib/.*\.ex$"` to the patterns.

### IN-05: The new `/storybook` 404 probes are not part of the runtime completion marker

**File:** `examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh:797-808` (marker logic at `:222-237`)
**Issue:** The script proves other runtime checks ran by counting them in `runtime_completion_error`
(images, projects, `runtime_host_ports`), and the unit test pins the loop's text. Nothing records that the
four probes (host and ops, test and prod) actually executed, so a later refactor that leaves the loop
textually intact but unreachable would still pass.
**Fix:** Append `"$environment/$catalog_name"` to a `runtime_catalog_probes` array inside the loop and
require `${#runtime_catalog_probes[@]} == 4` in `runtime_completion_error`.

### IN-06: The hook-parity test is blind to a colocated hook

**File:** `scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs:315-319` (claim at `scrypath_ops/assets/js/storybook.js:2-3`)
**Issue:** The parity check removes `"...colocatedHooks"` from the app list before comparing, so a
colocated hook added under `lib` later would never reach the catalog while the test stays green. The
storybook.js comment ("none exist under lib") is true today (no `ColocatedHook` in `lib`) but unasserted.
**Fix:** Assert the premise in the test so the first colocated hook fails it and forces the catalog bundle to
import it, for example `assert Enum.filter(Path.wildcard("lib/**/*.{ex,heex}"), &(File.read!(&1) =~
"ColocatedHook")) == []`.

---

_Reviewed: 2026-11-21T23:40:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
