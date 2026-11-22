---
phase: 195-mount-and-prove
verified: 2026-11-21T23:50:00Z
status: passed
score: 8/8 must-haves verified
covered_files:
  - ".formatter.exs"
  - ".planning/phases/195-mount-and-prove/195-01-PLAN.md"
  - ".planning/phases/195-mount-and-prove/195-01-SUMMARY.md"
  - ".planning/phases/195-mount-and-prove/195-02-PLAN.md"
  - ".planning/phases/195-mount-and-prove/195-02-SUMMARY.md"
  - ".planning/phases/195-mount-and-prove/195-03-PLAN.md"
  - ".planning/phases/195-mount-and-prove/195-03-SUMMARY.md"
  - "examples/scrypath_ecommerce/scripts/phase173-standalone-entrypoint.sh"
  - "examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh"
  - "scrypath_ops/.formatter.exs"
  - "scrypath_ops/assets/js/storybook.js"
  - "scrypath_ops/catalog/lib/scrypath_ops/catalog/storybook.ex"
  - "scrypath_ops/config/config.exs"
  - "scrypath_ops/config/dev.exs"
  - "scrypath_ops/config/test.exs"
  - "scrypath_ops/lib/scrypath_ops_web/dev_router.ex"
  - "scrypath_ops/lib/scrypath_ops_web/optional_catalog_routes.ex"
  - "scrypath_ops/mix.exs"
  - "scrypath_ops/mix.lock"
  - "scrypath_ops/priv/static/assets/js/storybook.js"
  - "scrypath_ops/storybook/primitives/ops_badge.story.exs"
  - "scrypath_ops/storybook/primitives/ops_button.story.exs"
  - "scrypath_ops/storybook/primitives/ops_empty_state.story.exs"
  - "scrypath_ops/storybook/primitives/ops_panel.story.exs"
  - "scrypath_ops/storybook/primitives/ops_sync_status.story.exs"
  - "scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/catalog_routes_test.exs"
  - "scrypath_ops/test/scrypath_ops_web/ops_shell_contract_test.exs"
  - "scrypath_ops/test/support/catalog/planted_endpoint.ex"
  - "scrypath_ops/test/support/catalog/planted_router.ex"
  - "scrypath_ops/test/support/catalog/planted_storybook.ex"
  - "scrypath_ops/test/support/catalog_render_all.ex"
  - "scrypath_ops/test/support/storybook_planted/failing/boom.story.exs"
  - "scrypath_ops/test/support/storybook_planted/failing/empty.story.exs"
  - "test/mix/tasks/dependency_boundary_contract_test.exs"
  - "test/release/ops_dependency_boundary_test.exs"
  - "test/release/package_metadata_test.exs"
covered_digest: "v4:sha256:f92315cc568e6d8058882051a8db424a4d61fa7b97004890fe8479e3038a9599"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 195: Mount and prove Verification Report

**Phase Goal:** The storybook mounts in ScrypathOps for dev and test only, renders with the real styling and hooks, can never reach a production graph or the Hex tarball, and a measured go/no-go says whether the milestone continues.
**Verified:** 2026-11-21T23:50:00Z
**Status:** passed
**Re-verification:** Initial verification at 23:26Z, then re-run at 23:50Z after the code-review fixes (`1ed5e402`, `a979b0d1`, `f72af5f5`). The fixes touched criteria 1 and 2, so those were re-checked against the new code; nothing failed in the first pass, so there is no gap-closure delta.
**Checkout:** branch `gsd/phase-195-close`, HEAD `f72af5f5`. `origin/main` is `6002ab4b`, so **the three review-fix commits are local only: not pushed, no open PR, no hosted CI run on them.** Everything below that says "hosted" refers to the earlier merged tree (`96521ab1`, whose tree equals the PR head `f9af18d4`).

## What the verdict rests on, and what it does not

The goal is met on executable checks, recorded hosted numbers, and one recorded maintainer decision. Stated plainly, as the project rules ask:

- **The cold `ops-ui` trigger tripped.** The first main push run after the merge took 620 s against the 548 s line (368 s baseline plus 180 s). The phase therefore did not pass its own go/no-go on the numbers. It continues on the maintainer's choice, recorded as a choice against a tripped cold sample and not as a pass. The PR's own cold run (517 s) was under the line and the warm run (378 s) is within its 428 s line.
- **The hosted timings are recorded evidence, not a pass or fail gate.** Nothing in the test suite asserts them.
- **The maintainer's answer reached the executor through the orchestrating agent.** GO-NO-GO.md says so itself. I confirmed the record, the commit sequence (a "hold the decision" commit, then a "record the continue decision" commit) and that nothing else merged in between. I cannot confirm from the repository that the interactive dialog happened as described; that rests on the agent that ran it.
- **The review fixes have not been through hosted CI or the Docker lane.** I ran the focused tests, the cheap script checks and the prod route-table integration probe on the new code (all green, below). I did not run `mix verify.ecommerce_mounted`, so the Docker images have not been rebuilt and probed with the tracked flag read or the changed entrypoint script.
- **No claim is made that the catalog looks good or that anyone reviewed it.** Nothing here is subjective; Phase 197 and the milestone-end review own that.

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP success criteria 1 to 4, then standing rules) | Status | Evidence |
|---|---|---|---|
| 1 | SC1 (MOUNT-01): the boundary test asserts `phoenix_storybook ~> 1.5` with `only: [:dev, :test]`; a planted loosening fails it; `PhoenixStorybook` and `MDEx` are absent from every mounted and direct-prod consumer and from the prod-image script lists; the tarball test refutes `fixtures` and `storybook` | VERIFIED | See "Truth 1 evidence". Re-checked after the fixes: root boundary and package tests green (61 tests, 0 failures); my own mutation of the real `scrypath_ops/mix.exs` (`only: [:dev, :test, :prod]`) failed the root test with "must declare only: [:dev, :test], got [:dev, :test, :prod]"; restored. |
| 2 | SC2 (MOUNT-02): a test proves the production route table has no `/storybook` path, with a planted case that fails when the guard (outside the `quote`) is removed; loopback-bound; never mounted in the host's production image | VERIFIED | See "Truth 2 evidence". Re-checked against the new `Application.compile_env(__CALLER__, ...)` read: guard still an `if` outside the `quote`, flag still read as a value, four planted mutants fail, my own two mutations of the real macro fail, the prod route-table probe passes on the new code (2 tests, 0 failures, 196.8 s). |
| 3 | SC3 (MOUNT-03): render-all loads every variation of the five primitives through the real iframe route with `css_path` at the built `app.css` and the `storybook.js` hooks, fails on empty output or `data-phx-error`, and a planted failing story proves it can fail | VERIFIED | See "Truth 3 evidence". Re-ran after the fixes: 22 tests, 0 failures. Bundle rebuilt in the first pass is byte-identical to the tracked file and no bundle file changed since. |
| 4 | SC4 (MOUNT-04): GO-NO-GO.md records cold and warm hosted timings, NIF fetch time, lock growth, advisory status; ADR 0001 is amended; each ADR 0001 trigger has a verdict; a tripped trigger stops the run and asks the maintainer | VERIFIED | See "Truth 4 evidence". Every hosted number I re-derived from `gh` matches. The trigger tripped and the record says so. The updated GO-NO-GO.md only changes finding (b) and adds (g) (see Warnings). |
| 5 | FLOW-01: no Hex release or release PR; every PR title is `docs`, `chore`, `test` or `ci` | VERIFIED | PR #171 `chore(ops-ui): ...`, PR #172 `docs(phase-195): ...`; the three review-fix commits are `chore(ops-ui)`, `test(ops-ui)`, `chore(ops-ui)`. No `feat` or `fix` title anywhere in `a11c36cd..HEAD`. `gh pr list --state open` returns `[]`. |
| 6 | FLOW-02: within the plan cap; no new required CI context; no root `lib/` change | VERIFIED | 3 plans (cap 5). `git diff a11c36cd..HEAD -- lib/` and `git diff 6002ab4b..HEAD -- lib/` are both empty; root `mix.exs` and `mix.lock` unchanged. Nothing under `.github/` or `scripts/ci/` changed. Branch-protection required contexts are exactly `backend`, `core`, `ecommerce-mounted`, `package`, `repository-contracts` and `ops-ui (path-scoped)`. No gate row added (CONTRIBUTING.md untouched). |
| 7 | FLOW-03: the three protected files were never staged; commits name paths; local lane mirror ran before the push, skips recorded | VERIFIED | `git log a11c36cd..HEAD -- .planning/config.json .planning/state.json .impeccable/config.json` prints nothing, including the three new commits. The three files are modified in the working tree (uncommitted, as expected) and I did not touch them. The local mirror table is in 195-03-SUMMARY.md and PR #171's body. |
| 8 | FLOW-04: F1, F2, D2 and the test-hygiene items, plus the new findings, are recorded for the maintainer and not fixed | VERIFIED | GO-NO-GO.md "Findings for the maintainer" (a) to (g), and 195-REVIEW-DISPOSITION.md rows for the nine review findings (1 fixed warning, 1 fixed info, 2 accepted, 5 handed off). The `OptionalDevRoutes.dashboard_routes/1` defect (a) is still unfixed and handed off. |

**Score:** 8/8 truths verified (0 present but behavior-unverified).

### Truth 1 evidence (MOUNT-01, dependency boundary)

- `scrypath_ops/mix.exs:64`: `{:phoenix_storybook, "~> 1.5", only: [:dev, :test]}`; `elixirc_paths/1` compiles `catalog/lib` only for `:dev` and `:test`. `mix.exs`, `config/` and `dev_router.ex` have no diff since `6002ab4b`.
- `storybook_dependency_violation/1` in `test/mix/tasks/dependency_boundary_contract_test.exs` was a vacuous `nil` for an absent dependency at `a11c36cd`. It now reports absent, wrong requirement (`~> 1.4`), unrestricted, `only: :dev` and `only: [:dev, :test, :prod]`. Six planted manifests exist in "planted storybook mention and unrestricted dependency are flagged"; the real-manifest test asserts `== nil` against `scrypath_ops/mix.exs`.
- Mounted and direct-prod consumers: `test/release/ops_dependency_boundary_test.exs` adds `PhoenixStorybook`, `MDEx` and `ScrypathOps.Catalog.Storybook` to `@absent_modules` and `:phoenix_storybook`, `:mdex`, `:mdex_native` to the forbidden lock apps; the direct probe asserts availability equals `env in ["dev", "test"]`. **Run here on the new code: `mix test --include integration test/release/ops_dependency_boundary_test.exs`, 2 tests, 0 failures, 196.8 s** (233.4 s on the earlier tree). It also passed hosted.
- `examples/scrypath_ecommerce/scripts/verify-dependency-boundaries.sh`: the forbidden dependency list gains `phoenix_storybook mdex mdex_native` when `environment == prod` or the project is the host, leaving only the `/app/scrypath_ops` test-image case exempt; the runtime probe's `forbidden_modules` gains `PhoenixStorybook` and `MDEx`; a `/storybook` HTTP 404 probe covers the host and standalone Ops. The root text check has four planted `String.replace` mutants, each required to produce a violation. Since `a979b0d1` each mutant is also written to a temp file and must pass `bash -n`, and the first mutant's missing closing quote is fixed, so the violation is caused by the removed edit and not by a syntax break. `bash -n` and `--static-contract-only` pass here on the current script. **The hosted `ecommerce-mounted (required)` log (run 44955813968, pre-fix tree) printed `DEPENDENCY_BOUNDARY_CATALOG ... status=404` for `test/host`, `test/ops`, `prod/host` and `prod/ops`.**
- Tarball: `test/release/package_metadata_test.exs` has `refute "fixtures" in package_files` and `refute "storybook" in package_files`; root `mix.exs` `files:` is an allowlist with no `scrypath_ops`.

### Truth 2 evidence (MOUNT-02, route guard, prod route table, loopback)

- `scrypath_ops/lib/scrypath_ops_web/optional_catalog_routes.ex` (changed by `1ed5e402`): the guard is `if enabled?(Application.compile_env(__CALLER__, :scrypath_ops, :catalog_routes, false), Code.ensure_loaded?(PhoenixStorybook.Router)) do quote ... else quote(do: :ok) end`. The `if` is still outside both `quote` blocks, and the flag is still read as a plain value (the function form with the caller env returns the value; the comment explains why the three-argument macro would not). The new read also records the value with Mix, so a flag change between two compiles recompiles the router or aborts instead of keeping a stale mount. I did not exercise that stale-build abort myself; I verified the guard shape, the tests and the mutants. Two independent conditions still keep prod out: the flag is unset (default false) and the storybook router cannot load, because the dependency is `only: [:dev, :test]`.
- Guard-removal plants (root AST test, "catalog route guard sits outside the quote and fails when moved, deleted, flag-blind or untracked"): four mutants over the real macro source, each required to be reported as a "route guard" violation, with `assert mutated != ast` against a no-op mutant. The fourth, `:untrack_flag_read`, rewrites the tracked read into the old untracked `get_env`. `catalog_flag_read?/1` now accepts only `Application.compile_env(<env>, :scrypath_ops, :catalog_routes, ...)`. **My own mutations of the real file, each failing the root test and then restored (`git diff --quiet` clean afterwards):** flag read replaced by `true`, and flag read replaced by the untracked `Application.get_env(:scrypath_ops, :catalog_routes, false)`; both gave "the route guard must be an if outside the quote ...".
- `scrypath_ops/test/scrypath_ops_web/catalog_routes_test.exs` still passes on the new read: flag-off, flag-unset and real-macro routers have no `/storybook` path, the flag-on router has it (positive control), and the planted guard-stripped copy of the macro mounts `/storybook/iframe/*story` with the flag off.
- Production route table: the mounted and direct probes call `ScrypathOpsWeb.DevRouter.__routes__()`, assert it is non-empty and assert no `/storybook` path in mounted test and prod graphs and direct prod, while direct dev and test do have it. Passed on the new code (above).
- Loopback: `dev.exs` binds `{127, 0, 0, 1}` and sets the flag; `test.exs` binds `{0, 0, 0, 0}` only when `PHX_SERVER=true` and then sets the flag to `false`; `runtime.exs` never sets the flag. The root test "catalog flag is off whenever the test endpoint is not loopback" reads the real configs in a subprocess for three cases and has planted violations. Passes.
- Standalone Ops entrypoint (`f72af5f5`): `scripts/phase173-standalone-entrypoint.sh` now exports `PHX_SERVER=true` once instead of running its ecto steps under `PHX_SERVER=false`. This is consistent with the test image (`runtime_test` sets `ENV PHX_SERVER=true`), so every mix call in the container sees the value the image was compiled with, which the tracked read needs. `bash -n` passes, the root static-contract tests that list this script pass, `--static-contract-only` passes, and `node --test scripts/ci/ui_bundle_contract.test.cjs` (which copies this script) passes, 12 of 12. The Docker lane itself was not re-run.
- Host production image: no config in `examples/scrypath_ecommerce` or `scrypath_ops/lib` sets the flag. The Docker 404 evidence above is from the earlier tree. The `.dockerignore` skip is a recorded choice in GO-NO-GO.md.

### Truth 3 evidence (MOUNT-03, render-all, styling, hooks)

- Backend: `scrypath_ops/catalog/lib/scrypath_ops/catalog/storybook.ex` sets `css_path: "/assets/css/app.css"` (tracked), `js_path: "/assets/js/storybook.js"` and `themes_strategies: [data_attribute: "theme"]`.
- Render-all (`catalog_contract_test.exs`, helpers in `test/support/catalog_render_all.ex`): walks `backend.leaves()` and `load_story`, builds `GET /storybook/iframe/<path>?variation_id=<id>&theme=<light|dark>` and renders each through `Phoenix.ConnTest.dispatch` plus `Phoenix.LiveViewTest.live/1`, so it uses the real iframe route and a real LiveView mount, not a `render_component` helper. `RenderAll.problems/1` uses LazyHTML selectors (`[data-phx-main] > *`, `[data-phx-main] > * > *`, `[data-phx-error]`, `style`, `script[src^="/assets/js/storybook.js?hash="]`) and flags a missing sandbox, empty output, `data-phx-error`, an unresolved `app.css?hash=` import and an unresolved `storybook.js?hash=`; `theme_problem/2` checks `body[data-theme]`. The test asserts the five primitive paths are present, none is `:page`-unsupported, and the failure list is empty in both themes.
- Planted failing tree: a test-only endpoint, router and backend under `test/support/catalog/` (nothing in `lib` references them). The same `render_target/3` plus `problems/1` path reports `{:crashed, :error, "** (RuntimeError) planted render failure"}`, `{:rendered, ["empty output"]}` and `{:crashed, :error, ":function_clause"}` for the unknown-id cases, each pinned by cause. A separate test shows `problems/1` flagging stripped hashes and a `data-phx-error` attribute on otherwise-real output. As the executor recorded and the review disposition accepted (WR-02): LiveView 1.1.34 and phoenix_storybook 1.5.0 never emit `data-phx-error` server-side, so that selector is a guard for the requirement's wording and the crash, empty and unknown-variation plants are the real failure signals.
- Five primitives: `ops_button`, `ops_badge`, `ops_panel`, `ops_empty_state`, `ops_sync_status` under `scrypath_ops/storybook/primitives/` (17 variations per the SUMMARY).
- `storybook.js`: sets `html[data-theme]` for `light` and `dark` from the query string and exposes `window.storybook.Hooks` with nine hooks. `ops_shell_contract_test.exs` asserts the imports, that the `storybook.js` hook names equal the `app.js` `hooks:` list minus `...colocatedHooks`, and that the tracked bundle contains `window.storybook`, `data-theme` and each hook name (the review's WR-03 notes this is a name check, not a freshness digest, and hands it off with a trigger). The bundle `scrypath_ops/priv/static/assets/js/storybook.js` is tracked; I rebuilt it in the first pass with `MIX_ENV=dev mix esbuild scrypath_ops_storybook` and the md5 was identical before and after, and no bundle or JS source has changed since.
- Literal rule: `node scripts/ci/ui_literal_policy.cjs` exits 0 with "UI literal policy: PASS" (first pass); no story or JS file changed since. `mix format --check-formatted` passes at the root and in `scrypath_ops/` on the current tree.
- Re-run on the new code: `mix test test/scrypath_ops_web/catalog_contract_test.exs test/scrypath_ops_web/catalog_routes_test.exs test/scrypath_ops_web/ops_shell_contract_test.exs` in `scrypath_ops/`: 22 tests, 0 failures.

### Truth 4 evidence (MOUNT-04, go/no-go)

Hosted numbers, re-derived from `gh run view <id> [--attempt N] --json jobs` (job start to completion):

| Sample | Run, attempt, job | I computed | GO-NO-GO.md |
|---|---|---|---|
| Cold, PR head | 44955813968, 1, 137003601222 | 22:15:52 to 22:24:29 = 517 s | 517 s |
| Warm rerun, same SHA | 44955813968, 2, 137007958395 | 22:32:11 to 22:38:29 = 378 s | 378 s |
| Cold, first main run after merge | 44958204651, 1, 137010963728 | 22:43:36 to 22:53:56 = 620 s | 620 s |
| Same-day control | 44943834998, 2, 137007989641 | 22:32:17 to 22:37:59 = 342 s | 342 s |
| Control at the main run's hour | 44943834998, 3, 137014561618 | 22:57:36 to 23:04:33 = 417 s | 417 s |
| Locked baseline run | 44943834998, 1, 136966725694 | 19:59:35 to 20:05:49 = 374 s | 374 s |

- NIF fetch: the hosted `ecommerce-mounted` log shows `22:17:31.966 Downloading NIF ...` and `22:17:32.366 NIF cached`, which is 0.400 s, matching the record.
- Lock growth: `scrypath_ops/mix.lock` 56 to 65 lines (9 added entries, none changed); the root and example locks have no diff.
- Advisory status: `gh api /advisories` for `phoenix_storybook` returns three advisories, all patched in 1.1.0 (resolved 1.5.0); none for `mdex` or `mdex_native`. The `handle_params` claim is confirmed at `scrypath_ops/deps/phoenix_storybook/lib/phoenix_storybook/stories/story.ex` line 99.
- Triggers: GO-NO-GO.md "Trigger evaluation" has exactly one row per ADR 0001 trigger (advisory over 14 days: not tripped; cold `ops-ui` over 548 s: **tripped**; isolation work over a day: not tripped at 0.1 h; Docker `asset_builder` over +60 s: not tripped at +33 s on a hosted proxy; NIF failure twice: not tripped, 0 failures) plus the warm line as an exit criterion (378 s against 428 s, within).
- Decision: front matter `decision: go`, `decided_by` says "the maintainer, against a tripped cold sample (not a pass)", and the `## Decision` section opens "Go, as the maintainer's choice against a tripped cold sample, not as a pass." Commit order: `38d75709` (hold) before `ed29d923` (record the continue decision). The merge of #171 preceded the second cold sample; finding (f) records that ordering gap.
- ADR 0001: the "Amendment: measured go/no-go (Phase 195, 2026-11-21)" section is present with the decision, numbers, one verdict per trigger and a link to GO-NO-GO.md.
- Both H exit items are in GO-NO-GO.md "Exit criteria": `handle_params` in an `:example` story is impossible, with the source line as evidence; the fidelity probe is deferred to Phase 197, and finding (g) now names Phase 197's discuss step as the carrier.
- The updated GO-NO-GO.md (uncommitted at the time of this check) changes finding (b) to "closed by the close-out review fix" with the developer consequence (flipping `PHX_SERVER` against one `scrypath_ops/_build` now needs `mix compile --force`), and adds finding (g). Its hosted numbers are untouched.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `scrypath_ops/lib/scrypath_ops_web/optional_catalog_routes.ex` | guard macro with `live_storybook` | VERIFIED | guard outside the quote, tracked flag read, wired from `dev_router.ex` |
| `scrypath_ops/catalog/lib/scrypath_ops/catalog/storybook.ex` | `use PhoenixStorybook` backend, dev and test compile only | VERIFIED | named by the macro's `backend_module:`; compiled via `elixirc_paths(:dev/:test)` only |
| `scrypath_ops/storybook/primitives/*.story.exs` (5) | five primitive stories | VERIFIED | all five render in the render-all run |
| `scrypath_ops/assets/js/storybook.js` and tracked bundle | theme attribute plus nine hooks | VERIFIED | bundle rebuilds byte-identically; hook parity asserted |
| `scrypath_ops/test/scrypath_ops_web/catalog_contract_test.exs`, `catalog_routes_test.exs` | mount, render-all, planted tree, guard tests | VERIFIED | ran green on the new code |
| `scrypath_ops/test/support/catalog_render_all.ex` and `catalog/planted_*.ex` | helpers and planted tree | VERIFIED | used by the contract test; not referenced from `lib` |
| `examples/scrypath_ecommerce/scripts/phase173-standalone-entrypoint.sh` | one `PHX_SERVER` for every mix call | VERIFIED (static) | `bash -n`, static-contract tests and the node bundle contract pass; Docker lane not re-run |
| `.planning/phases/195-mount-and-prove/GO-NO-GO.md` | measured record, one verdict per trigger | VERIFIED | numbers re-derived above |
| `.planning/adr/0001-phoenix-storybook-for-scrypath-ops.md` | amendment with numbers | VERIFIED | present and links GO-NO-GO.md |
| `.planning/reference/CI-EFFICIENCY.md` | findings 25 to 28 | VERIFIED | four findings appended |

### Key Link Verification

| From | To | Via | Status |
|---|---|---|---|
| `dev_router.ex` | `optional_catalog_routes.ex` | `require` plus `catalog_routes()` call | WIRED (root test asserts the router mounts only through the macro and names no storybook module itself) |
| `optional_catalog_routes.ex` | `catalog/storybook.ex` | `backend_module: ScrypathOps.Catalog.Storybook` | WIRED |
| `mix.exs` | `catalog/storybook.ex` | `elixirc_paths(:dev)` and `(:test)` include `catalog/lib` | WIRED |
| `catalog/storybook.ex` | tracked `storybook.js` bundle | `js_path` resolves with `?hash=` in render-all | WIRED |
| `storybook.js` | `ops_hooks.js` and `ops_search.js` | nine imported hooks | WIRED (regex and set-equality asserted) |
| `catalog_contract_test.exs` | `catalog_render_all.ex` | same `targets/url/problems` against the real and planted endpoints | WIRED |
| `GO-NO-GO.md` | ADR 0001 | amendment cites and repeats the numbers | WIRED |

### Data-Flow Trace (Level 4)

The render-all target list comes from `backend.leaves()` and `load_story/1`, i.e. the real story files, and each render is produced by the real LiveView mount. The test asserts the five expected paths are in that list, so an empty target set cannot pass. Status: FLOWING.

### Behavioral Spot-Checks and Verification Commands Run Here

| Behavior | Command | Result | Status |
|---|---|---|---|
| Root boundary and tarball tests (new code) | `mix test test/mix/tasks/dependency_boundary_contract_test.exs test/release/package_metadata_test.exs` | 61 tests, 0 failures | PASS |
| Ops catalog, route guard and hook tests (new code) | `mix test test/scrypath_ops_web/{catalog_contract,catalog_routes,ops_shell_contract}_test.exs` in `scrypath_ops/` | 22 tests, 0 failures | PASS |
| Mounted and direct prod probes: route table, modules, lock (new code) | `mix test --include integration test/release/ops_dependency_boundary_test.exs` | 2 tests, 0 failures, 196.8 s | PASS |
| Flag-blind guard is caught | replace the flag read with `true`, rerun root boundary test, restore | 1 failure ("the route guard must be an if outside the quote ...") | PASS (file restored) |
| Untracked flag read is caught | replace the tracked read with `Application.get_env(...)`, rerun, restore | 1 failure (same message) | PASS (file restored) |
| Loosened dependency is caught | `only: [:dev, :test, :prod]` in `scrypath_ops/mix.exs`, rerun, restore | 1 failure ("must declare only: [:dev, :test], got [:dev, :test, :prod]") | PASS (file restored) |
| Docker script text and syntax | `bash -n` on both scripts; `verify-dependency-boundaries.sh --static-contract-only` | pass | PASS |
| Node test that copies the entrypoint | `node --test scripts/ci/ui_bundle_contract.test.cjs` | 12 pass, 0 fail, 79 s | PASS |
| Formatting | `mix format --check-formatted` at root and in `scrypath_ops/` | clean | PASS |
| Bundle is reproducible (first pass) | `MIX_ENV=dev mix esbuild scrypath_ops_storybook`, compare md5 | identical | PASS |
| UI literal policy (first pass) | `node scripts/ci/ui_literal_policy.cjs` | exit 0, PASS | PASS |

After every mutation run `git diff --quiet` on the two mutated files was clean. `git status --short` lists only the three protected config files, the planning files the coordinator is editing (VALIDATION, GO-NO-GO) and the new untracked review and verification files.

### Hosted evidence

Hosted evidence is for the pre-fix merged tree only. The PR head's required checks were all `SUCCESS` (`core`, `package`, `backend`, `repository-contracts`, `ecommerce-mounted`, `ops-ui`; `deep-quality (advisory)` red for its known sigra, cloak and cloak_ecto cause). The post-merge main push run 44958204651 on `96521ab1` also had every required job green. The three review-fix commits are unpushed, so no hosted run exists for them.

### Probe Execution

Step 7c: no `scripts/*/tests/probe-*.sh` exists and no plan or summary declares one. The phase's probes are the Elixir probes in `ops_dependency_boundary_test.exs` and the Docker script, both run or read above. SKIPPED (no shell probes declared).

### Requirements Coverage

| Requirement | Source plan | Description | Status | Evidence |
|---|---|---|---|---|
| MOUNT-01 | 195-01 | dev/test-only dependency; non-vacuous boundary row; absent modules; tarball refutes | SATISFIED | Truth 1 |
| MOUNT-02 | 195-01 | route only in dev/test, loopback, guard outside the quote, prod route table test with planted case | SATISFIED | Truth 2 |
| MOUNT-03 | 195-02 | real styling and hooks; five primitives; render-all through the real iframe route; planted failing story | SATISFIED | Truth 3 |
| MOUNT-04 | 195-03 | measured go/no-go recorded, ADR 0001 amended, triggers evaluated, stop-and-ask on a trip | SATISFIED | Truth 4 (the trip and the maintainer's choice are stated plainly) |
| FLOW-01 | 195-01, 02, 03 | no release, no `feat`/`fix` | SATISFIED | Truth 5 |
| FLOW-02 | 195-03 (and 01) | plan cap, ask-first items | SATISFIED | Truth 6; the one ask-first event (a tripped trigger) was asked |
| FLOW-03 | 195-01, 02, 03 | protected files, explicit paths, local mirror | SATISFIED | Truth 7 |
| FLOW-04 | 195-01, 03 | findings recorded not fixed | SATISFIED | Truth 8 |

All eight IDs appear in the PLAN frontmatter and in REQUIREMENTS.md, where all eight are `[x]` and "Complete" and mapped to Phase 195. No orphaned requirement.

### Anti-Patterns Found

None. A scan of the added lines in every non-planning file (including the three review-fix commits) for `TBD`, `FIXME`, `XXX`, `TODO`, `HACK` and `PLACEHOLDER` finds nothing in the diff (the one `XXXXXX` hit is an existing `mktemp` template). The planted failing stories are test-only fixtures, not stubs.

### Human Verification Required

None. No `<human-check>` block exists in any plan. The plan's one `checkpoint:decision` (the maintainer's go or no-go) was reached and answered; it is recorded, not a pending item.

## Warnings

These do not change the status.

1. **The review fixes are local, unpushed and unmeasured on hosted CI or Docker.** `1ed5e402` changes how the catalog flag is read (now tracked by Mix) and `f72af5f5` changes a script the `ecommerce-mounted` lane runs. I verified both statically and with the focused tests and the prod route-table probe, but not with the Docker images, which is where a flag or `PHX_SERVER` mismatch would abort a compile. Per the pre-push-confidence rule, run `mix verify.ecommerce_mounted` locally or let the required hosted lane run on the exact head before merging, and say so if it is skipped.
2. **PR #172's GitHub body is still stale.** It says "no ADR 0001 trigger tripped", contradicting the committed record. The files and the squash commit message are right; only the PR body is wrong.
3. **Review findings handed off or accepted, not fixed** (195-REVIEW-DISPOSITION.md): WR-02 accepted (the `data-phx-error` check can never fire; kept as a guard), WR-03 handed off (bundle test checks hook names, not a build digest), and IN-03 to IN-06 handed off (the dev-tool `storybook.js` ships in prod and test static trees, dev `live_reload` does not watch stories, the 404 probes are not in the script's completion marker, hook parity subtracts `colocatedHooks`). IN-02 accepted.
4. **ROADMAP.md still shows Phase 195 as `[ ]` and "3/3 | In Progress".** The orchestrator updates that on phase completion.
5. **Other open items the record hands to the maintainer, not fixed:** the `OptionalDevRoutes.dashboard_routes/1` guard (still reads `compile_env` through `Macro.expand`, so its `and dev_routes?` is always truthy; unobservable while LiveDashboard is dev-only), F1, F2, D2, the test-hygiene items, and the unrelated `phoenix 1.8.16` advisory in `examples/phoenix_meilisearch`.
6. **The cold-cost attribution is an inference.** The record says most of the 620 s comes from the root-graph cache miss any lock change pays (about 135 s) and that the storybook's own marginal cost is about +36 s on one paired sample. It labels this an inference and I did not re-derive it, though the paired controls it rests on reproduce from `gh`. CI-EFFICIENCY.md sets a revisit trigger.

Cleared since the first report: the fidelity probe now has a recorded carrier (GO-NO-GO.md finding (g): Phase 197's discuss step takes it as input, a local non-gating Playwright computed-style comparison), and `195-VALIDATION.md` is finalized (`status: validated`, all rows green, all boxes checked).

## Gaps Summary

No gaps. All four roadmap success criteria and the four standing rules are met on executable checks, hosted records I re-derived, and one recorded decision. After the review fixes, criteria 1 and 2 hold against the new code. The phase did not clear its cold-time trigger on the numbers; it continues because the maintainer chose to continue, and the record, the ADR amendment and this report all say that. The one open verification item is warning 1: the post-review commits still need the Docker lane or a hosted run before merge.

---

_Verified: 2026-11-21T23:50:00Z_
_Verifier: Claude (gsd-verifier)_
