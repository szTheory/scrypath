# Phase 183: Maintainer tooling outside the Hex package - Research

**Researched:** 2026-10-27
**Domain:** Mix project layout, Hex packaging boundary, release-gate engineering (Elixir, ExUnit, ExDoc, GitHub Actions)
**Confidence:** HIGH. The whole move was rehearsed end to end in a scratch copy of the repo (outside the checkout), and every load-bearing claim below was reproduced there. One locked decision (D-07) fails its own acceptance proof and needs an amendment; see "Findings that change or qualify locked decisions".

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

The maintainer selected all four gray areas and asked for a research fan-out, with coherent recommendations adopted automatically. Every decision below is the synthesized recommendation from four parallel research passes, cross-checked against the code. Per the delegated-decisions memory, merges and releases still need the maintainer's confirmation.

#### Inventory and classification
- **D-01:** The namespace is the classifier. `lib/mix/tasks` keeps exactly the 8 public operator tasks:
  - `scrypath.status`, `scrypath.failed`, `scrypath.retry`, `scrypath.reconcile`
  - `scrypath.settings.diff`, `scrypath.settings.read`, `scrypath.settings.hot_apply`
  - `scrypath.index.contract_drift` (at `lib/mix/tasks/scrypath/index/contract_drift.ex`)

  Every `verify*` task and every verify support module moves to `dev/mix/tasks`. There is no separate classification manifest; the directory plus the gate allowlist (D-09) is the source of truth.
- **D-02:** The move covers 53 files and keeps their relative layout:
  - 40 top-level `verify*.ex`: the bare `verify`, `verify.all`, 29 `verify.phaseNN`, `verify.adopter`, `verify.coverage`, `verify.meilisearch_smoke`, `verify.no_optional_deps`, `verify.ops_ui`, `verify.postgres`, `verify.release_parity`, `verify.release_publish` and `verify.workspace_clean`.
  - 9 capability tasks under `verify/`.
  - 3 helper modules: `verify/capability.ex` and `verify/phoenix_example/{lock_graph,package}.ex`.
  - The renamed namespace fence (D-03).

  Nothing under `lib/scrypath/**` is verify-only, so it all stays. `Scrypath.CLI.OperatorTask` stays because it serves the public tasks.
- **D-03:** Rename `scrypath.namespace_fence` to `verify.namespace_fence` (module `Mix.Tasks.Verify.NamespaceFence`, file `dev/mix/tasks/verify.namespace_fence.ex`), and move its test to `test/mix/tasks/verify_namespace_fence_test.exs`.
  - It is a repo-only Sigra lint that scans `scrypath_ops/`, yet the `scrypath.*` prefix wrongly signals an adopter-facing task, and 0.3.17 ships it.
  - Update the task name in `verify/capability.ex` and in `verify_capability_test.exs`.
  - Add a `"verify.namespace_fence": :test` entry to `preferred_envs`.
  - Add no compatibility alias. The name is undocumented, so "historical commands" (PKGH-02) does not cover it.
  - **Reversibility:** costly — it removes a task name that 0.3.17 published. Restoring it would mean re-adding a public-looking task.
- **D-04:** Keep every `cli/0 preferred_envs` entry. They are required, because Mix chooses the env before compiling and `:test` is the only env that compiles `dev/`. Add a cheap test that every `use Mix.Task` module under `dev/mix/tasks` has a matching `:test` entry, and that every `verify*` key resolves to a task.

#### How `dev/` gets compiled
- **D-05:** Set `elixirc_paths: elixirc_paths(Mix.env())`, with `defp elixirc_paths(:test), do: ["lib", "dev/mix/tasks"]` and `defp elixirc_paths(_), do: ["lib"]`. Add no `File.dir?` guard; research showed Mix tolerates a missing path. Do not add `dev` to `package files:`.
  - Dependencies compile in `:prod`, so Hex, path-dep and git-dep consumers never compile the verifiers. That includes `examples/*` and `scrypath_ops`, which use `path: "../.."`.
  - Phoenix uses the same env-keyed shape (`:docs` env) and so does Oban (`:test`).
  - Rejected: compiling in all envs, which leaks into path/git deps and HexDocs. Also rejected: `Code.require_file`, which `mix.exs` would evaluate in dep contexts too, and a nested Mix project, which breaks root-level commands.
  - **Reversibility:** costly — every documented command depends on `preferred_envs` routing to `:test`.
- **D-06:** Running `MIX_ENV=dev mix verify.x` explicitly will report "task could not be found". That is the accepted, intended behavior. CONTRIBUTING documents it in one sentence: verifier tasks compile only under `MIX_ENV=test`, which `preferred_envs` selects automatically.
- **D-07:** Docs stay consistent across envs. Add ExDoc `filter_modules` that excludes `Mix.Tasks.Verify*` modules, so the local `:test` docs build (`verify`, `verify.phase11`) and the `:dev` `hex.publish` docs build agree. Do not use `@moduledoc false`, which would hide the tasks from `mix help`. HexDocs will intentionally stop listing the Verify modules. The planner/researcher must prove that `MIX_ENV=dev mix docs --warnings-as-errors` and the `:test` docs run are both clean. The risk to check is autolinks in packaged docs such as README, guides and CONTRIBUTING that point at modules or tasks absent in `:dev`.
- **D-08:** Update these configs, any of which would otherwise silently lose coverage:
  - `.formatter.exs` inputs gain `dev`.
  - `.credo.exs` `included` gains `"dev/"`.
  - The `sourceRoots` of all four graphs in `scripts/ci/beam_cache.cjs` gain `"dev"`, and `beam_cache.test.cjs` gains a fixture proving that a `dev/` edit changes the digest. The single cache-key rotation is expected.
  - The `ops-ui-path` filter regex in `.github/workflows/ci.yml` gains `dev/`.
  - The HYG-02 scans in `workflow_wiring_test.exs` cover `dev/**` as well as `lib/**`.
  - The `verify.workspace_clean` pathspecs gain `dev/`.
  - Optional: a `/dev/` line in `CODEOWNERS`.

#### Leak gate (PKGH-03)
- **D-09:** The gate is a fail-closed allowlist, not a `verify.*` denylist. A denylist misses non-`verify` names (`scrypath.namespace_fence` is exactly that case today) and cannot prove that the public tasks are retained.
  - The pure checker is `Scrypath.Release.PackageContract` in `test/support/release/package_contract.ex`. It is never packaged.
  - It holds `@public_tasks` (the 8 tasks from D-01) and `@allowed_top_level`, which mirrors `package files:` plus `hex_metadata.config`.
  - It follows the repo's pure `compute`/`classify` plus thin runner pattern.
- **D-10:** The gate checks the directory produced by a real `mix hex.build --unpack --output <tmp>`, never the source tree or the text of `files:`.
  - **L0, archive contents:** every top-level entry must be in the allowed set. This replaces the enumerated `forbidden_prefixes` and catches `dev/` entering `files:`.
  - **L1, static scan:** `Code.string_to_quoted!` over every packaged `lib/**/*.ex` collects the `Mix.Tasks.*` defmodules, resolving nesting, and maps them to names with `Mix.Task.task_name/1`. The set must equal `@public_tasks`. Use the AST, not a regex.
  - **L2, compiled consumer:** this layer reuses the existing `test/release/consumer_smoke_test.exs` consumer that compiles from the unpacked archive. It asserts:
    - The `Mix.Tasks.*` subset of `:application.get_key(:scrypath, :modules)` equals the manifest.
    - Each public task resolves through `Mix.Task.get/1`, has a non-empty shortdoc and exports `run/1`.
    - The consumer's `ebin` holds no `Elixir.Mix.Tasks.Verify.*.beam`.
    - `mix verify.package` in the consumer fails with "could not be found".
    - One operator task is invoked without a backend. Preferred: `mix scrypath.status` with no args exits non-zero with its own usage error. Fallback, if `app.start` misbehaves in a bare consumer: `mix help scrypath.status`.

    Because the consumer compiles an archive whose `mix.exs` names an absent `dev/mix/tasks`, L2 also proves the "unpacked package compiles without the dev tree" half of PKGH-02. Also prove that the unpacked archive compiles under both `MIX_ENV=prod` and `MIX_ENV=test` with `--warnings-as-errors`.
- **D-11:** A mutation/negative test lives in a new `test/release/package_contents_test.exs`. It works on a `@tag :tmp_dir` copy of the packaged files and runs a real `hex.build --unpack` with `MIX_BUILD_PATH` isolated. It must stay offline and hermetic (about 2.5 s).
  - Inject `lib/mix/tasks/scrypath.repo_only.ex`. This is the canonical PKGH-03 case and must fail.
  - Inject `lib/mix/tasks/verify.sneaky.ex`. Must fail.
  - Define `Mix.Tasks.Verify.Hidden` inside an ordinary `lib/scrypath/*.ex`. Must fail, proving the check does not depend on file path.
  - Add `"dev"` to `files:` with a file under `dev/`. Must fail at L0.
  - Delete `scrypath.status.ex`. Must fail with a missing-task error.
  - Control: the unmutated copy returns `:ok`.

  Failure output is sorted, with one line per violation. Each line gives a tag (`[unexpected-task]`, `[missing-task]` or `[forbidden-path]`), the task name, module and path, and a "fix:" hint that names both options: move the file to `dev/mix/tasks/`, or add the task to `@public_tasks` and document it in `guides/operator-mix-tasks.md`.
- **D-12:** The gate is wired into the existing lanes: no new Mix task and no new CI job.
  - Add `package_contents_test.exs` to the `verify.phase11` test list. `verify.package` → `Capability.run(:package)` → `Phase11` already runs in `ci.yml`'s required `package` job, `release-please.yml` and `publish-hex.yml` before `hex.publish`.
  - Update the `verify.phase11` pins in `docs_contract_test.exs`.
  - Add `refute "dev" in package_files` to `test/release/package_metadata_test.exs`.
- **D-13:** Leave `verify.release_parity` unchanged. Its tag-versus-tarball path sets are both computed, so it stays consistent across the move and for old tags. Do not attach the contents checker to it in this phase, because the 0.3.0 integration canary legitimately contains `verify.*`.

#### Path-coupled tests, docs and history
- **D-14:** Add one test-support helper, `Scrypath.RepoTooling` in `test/support/repo_tooling.ex`, with `tasks_root/0`, `task_path/1` and `task_source!/1`. It replaces all 34 literal `lib/mix/tasks/...` sites across 14 test files:
  - `verify.phase{97,98,99,106,107,108,112}_test.exs`
  - `verify_capability_test.exs`, `verify_phoenix_example_package_test.exs`, `verify_adopter_test.exs`, `workflow_wiring_test.exs`
  - `test/scrypath/phase99_contract_test.exs` and the roughly 19 compile-time attributes in `test/scrypath/docs_contract_test.exs`

  These tests assert source content, not location, so they keep reading source text through the helper. `module_info(:compile)[:source]` was rejected because absolute paths go stale across worktrees, Docker and the Phase 182 BEAM caches. `test_helper.exs` already requires `test/support/**` before the tests compile. A runtime `Mix.Task.get/1` check is optional for the existence assertions in `verify_capability_test`.
- **D-15:** Tests stay in `test/mix/tasks/`. The task sources and documented commands (for example `mix test test/mix/tasks/verify_adopter_test.exs`, which `readiness_contract_test` and `docs_contract_test` assert) embed those paths, so moving the tests would put PKGH-02 at risk.
- **D-16:** The move is a pure `git mv` commit with 100% renames, checked with `git diff -M --stat`, so that blame and `--follow` survive. The only exception is the rename in D-03, which may carry the minimal name edit in the same file. The PR's commit order is green at every step; there is no deliberately red intermediate commit:
  1. Add the helper and convert all call sites while it still points at `lib/mix/tasks`.
  2. Make the additive config edits (D-05, D-07, D-08).
  3. Do the `git mv`, flip the helper root, apply the rename in D-03 and add the boundary guard.
  4. Extend the gate and add the mutation tests. Record the pre-move violation count (about 53) as evidence by running the checker against the 0.3.17 archive or a pre-move build, not as a red commit.
  5. Update the docs.
- **D-17:** The boundary guard asserts four things:
  - `Path.wildcard("lib/mix/tasks/verify*") == []`
  - `dev/mix/tasks` exists
  - `"dev/mix/tasks"` is in the `:test` `elixirc_paths`
  - `"dev"` is not in `package[:files]`
- **D-18:** Packaged docs that mention `mix verify.adopter`, `mix verify.adopter --live` and `mix verify.meilisearch_smoke` keep those exact strings, which contract tests assert:
  - `README.md:31`, `:200`, `:204`
  - `guides/support-and-compatibility.md:77-78`
  - `guides/outside-adopter-intake.md:30-31`

  Add only a qualifier such as "from a source checkout (not part of the Hex package)". Add one sentence to CONTRIBUTING (near line 28, as a code span, not a link): "Repository-only `mix verify*` tasks live in `dev/mix/tasks/` and are not part of the Hex package; public operator tasks (`mix scrypath.*`) stay in `lib/mix/tasks/`. Command names and focused test paths are unchanged." The sentence also notes the `:test`-only compile from D-06.
- **D-19:** Do not hand-edit `CHANGELOG.md`, because release-please owns it. The user-visible commit type is `fix(package):`, so the changelog records that adopters no longer receive `mix verify*` tasks or `scrypath.namespace_fence`. Releasing stays a separate step that needs the maintainer's confirmation.
- **D-20:** Leave archived `.planning/` evidence that mentions `lib/mix/tasks`, including completed Phase 182, untouched.

### Claude's Discretion
- The exact helper and checker function names, and the wording of failure messages within the D-11 shape.
- Whether `verify_capability_test` also asserts with `Mix.Task.get/1`.
- The `CODEOWNERS` line.
- Whether L2's operator smoke uses the usage-error path or the `mix help` fallback, based on behavior observed in the bare consumer.

### Deferred Ideas (OUT OF SCOPE)
- A `--contents` flag on `verify.release_parity`, to run the contents allowlist against published versions from the first post-move release onward. This is a follow-up and not needed for PKGH-03.
- Cutting a Hex release that ships the cleaned package. That is release work, separate from this phase, and needs the maintainer's confirmation.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PKGH-01 | An adopter receives no repository-only `verify.*` task source or verification support modules in the Hex archive or compiled dependency; the complete inventoried maintainer task tree lives under `dev/mix/tasks` outside the package allowlist. | The 53-file inventory was moved in a scratch copy: `find dev -type f` returned 53, `lib/mix/tasks` kept 8, and `mix hex.build --unpack` held only the 8 public task files. A git-dep consumer and a path-dep consumer compiled 95 files with 8 `Mix.Tasks` beams and 0 Verify beams. See "Prototype evidence". |
| PKGH-02 | A contributor can invoke the documented canonical and historical verification commands from the source checkout in their intended environments after the move, while an unpacked package compiles without requiring the absent development tree. | Default-env `mix verify.namespace_fence` and `mix verify.adopter` routed to `:test` and ran. The full fast suite was green after a mechanical path flip (1036 tests; the single failure came from the scratch repo's synthetic git history). The unpacked archive compiled warning-free under `prod` and `test` with `dev/mix/tasks` absent, and the missing path is tolerated on Elixir 1.17.3, 1.19.5 and 1.20.4. |
| PKGH-03 | A maintainer can run the package/parity gate and prove the actual unpacked archive excludes maintainer tooling while retaining supported public operator tasks and consumer behavior; adding a repository-only task to packaged source fails the gate. | A prototype `PackageContract` (pure `classify/2` plus thin `check/1`) returned `:ok` on the control and the right violation for all five D-11 mutations in 2.4 s total, offline. The consumer probes for L2 were exercised by hand. See "Code Examples". |
</phase_requirements>

## Project Constraints (from AGENTS.md)

No `./CLAUDE.md` exists; `./AGENTS.md` is the project instruction file. Directives that bind this phase:

- **Green-main release train.** Keep `main` green on the lean required gates. Serious feature-depth work is PR-first. Completion must be backed by executable tests or exact-SHA hosted evidence, never post-implementation human verification or pending UAT. Resolve subjective choices before implementation; do not simulate a reviewer.
- **Lean CI.** Add no new CI job (consistent with D-12). Keep required gates `core`, `package`, `repository-contracts`, `backend`, `ecommerce-mounted` unchanged in name.
- **No new dependencies** (maintainer preference recorded in CONTEXT; the package legitimacy audit below is therefore empty).
- **Release quality.** Commit type is `fix(package):`; the PR title becomes the squash commit that Release Please reads (CONTRIBUTING: squash merge only). Do not hand-edit `CHANGELOG.md`; do not cut a release without the maintainer's confirmation.
- **Worktree continuity.** Use absolute paths; reconcile dirty edits explicitly. `.planning/config.json` has unrelated uncommitted edits and must not be touched or staged.
- **Local reference material.** `prompts/elixir-opensource-libs-best-practices-deep-research.md` and `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` are the canonical practice references named in CONTEXT.
- Update `.planning/PROJECT.md` only if product scope or shipped claims change on purpose (this phase changes the packaged surface; the planner should decide whether the "what ships" wording needs one line).

## Summary

The phase is mostly mechanical and low technical risk, but it hides three silent-loss traps and one decision that does not survive contact with ExDoc. The move itself works exactly as CONTEXT predicts: with `elixirc_paths(:test)` returning `["lib", "dev/mix/tasks"]`, `mix` routes every documented `verify*` command to `:test` through `cli/0 preferred_envs`, the dev tree compiles only there, and dependencies (Hex, git and path) compile in `:prod` so they never see it. The published 0.3.17 currently leaks 25 `verify*`/fence entries into a Hex consumer's `mix help`, including a bare `mix verify` and `mix scrypath.namespace_fence`, so the leak is real and user-visible [VERIFIED: consumer of the Hex 0.3.17 tarball, prototype run].

The gate design in D-09 to D-12 holds up. A pure `classify/2` over (top-level entries, AST-derived `Mix.Tasks.*` names) plus a real `hex.build --unpack` in a tmp copy needs no deps, no lock file and no network, and runs in about 0.4 s per build. The L2 consumer (already built by `consumer_smoke_test.exs`) can additionally assert the compiled `ebin`, the public-task surface, and the "could not be found" behavior, all of which were exercised by hand and behave as D-10 expects.

**Primary recommendation:** Execute D-01 to D-20 as written, with these amendments: (1) drop `filter_modules` from D-07, because it makes `MIX_ENV=test mix docs --warnings-as-errors` fail with 59 "reference to a filtered module" warnings while the unfiltered config is clean in both envs; (2) make the D-14 conversion an acceptance-checked grep rather than trusting the 34/14 count (grep finds 32 sites in 13 files); (3) classify D-04 tasks by the `Mix.Task` behaviour attribute, not `Mix.Task.task?/1`; (4) optionally do the D-03 rename in place before the `git mv` so the move commit is 53 of 53 pure renames.

## Findings that change or qualify locked decisions

These are the places where research evidence disagrees with, or sharpens, CONTEXT. The planner should treat F1 as an escalation to carry into the plan (the maintainer delegated design calls, but D-07 is a locked decision being amended); the rest are refinements inside Claude's Discretion or acceptance criteria.

| # | Finding | Evidence | Action |
|---|---------|----------|--------|
| F1 | **D-07 `filter_modules` fails its own acceptance proof.** With `filter_modules: fn module, _ -> not String.starts_with?(inspect(module), "Mix.Tasks.Verify") end`, `MIX_ENV=dev mix docs --warnings-as-errors` is clean but `MIX_ENV=test mix docs --warnings-as-errors` prints "warning: reference to a filtered module" about 59 times (README.md, CONTRIBUTING.md, docs/releasing.md, docs/operator-support.md, docs/search-backend-sre.md, guides/support-and-compatibility.md, guides/outside-adopter-intake.md, guides/golden-path.md) and exits with "generation for html, epub formats failed due to warnings". `mix verify` step 6/6 and `verify.phase11` run docs in `:test`, so both would go red. Removing `filter_modules` makes both envs clean (re-run, including with the D-18 CONTRIBUTING sentence applied). | [VERIFIED: prototype run, ex_doc 0.40.3, Elixir 1.19.5/OTP 28] | Do **not** add `filter_modules`. Keep `docs/0` unchanged. HexDocs (built in `:dev` by `hex.publish`) stops listing Verify pages automatically because the modules are not compiled there; local `:test` docs still list them (26 pages, 52 html+md files). This satisfies D-07's stated acceptance (both builds clean) and its intent (HexDocs drops the Verify modules). Add a cheap hermetic guard that no packaged doc names `Mix.Tasks.Verify` (today: zero hits). |
| F2 | **`mix help verify.x` from a shell no longer finds the task.** `help` is not in `preferred_envs`, so it runs in `:dev`. `mix help verify.adopter` -> `** (Mix) The task "verify.adopter" could not be found`; `MIX_ENV=test mix help verify.adopter` works. No doc tells contributors to run `mix help verify.*` (only `readiness_contract_test.exs:46` does, in-process). Do **not** add `help: :test` to `preferred_envs` (it would change `mix help` for everyone). | [VERIFIED: prototype run; grep of README/CONTRIBUTING/guides/docs/lib/test/.github/scripts] | Extend the D-06 CONTRIBUTING sentence: "`mix help verify.x` also needs `MIX_ENV=test`." |
| F3 | **D-14 counts differ.** `grep -rn "lib/mix/tasks" test` finds 32 lines in 13 files (docs_contract_test.exs 19, verify_capability_test.exs 2, one each in phase97/98/99/106/107/108/112 tests, verify_adopter_test.exs, verify_phoenix_example_package_test.exs, workflow_wiring_test.exs, phase99_contract_test.exs), not 34 in 14. | [VERIFIED: grep this session] | Make the acceptance criterion `grep -rn "lib/mix/tasks/verify" test` returns nothing after step 1, instead of relying on the count. |
| F4 | **Pre-move evidence numbers.** A `hex.build --unpack` of the current tree holds 61 `Mix.Tasks.*` defmodules (53 not in the public set, 0 missing); the **published** Hex 0.3.17 tarball holds 60 (52 unexpected, 0 missing) because `verify.postgres` landed after the tag. Post-move: 8, 0, 0. `scrypath.namespace_fence` is the only non-`verify` offender in both. The 0.3.0 tarball has 20 modules, 13 unexpected, and **1 missing** (`scrypath.index.contract_drift`), which independently confirms D-13 (do not attach the checker to `verify.release_parity`). | [VERIFIED: prototype AST scan over the three archives] | Record "53 on the pre-move HEAD build, 52 on published 0.3.17" for D-16 step 4. Produce it with `--output <tmp>` before the move commit, because a later local `mix verify.package` overwrites the repo-root `scrypath-0.3.17/` directory. |
| F5 | **`Mix.Task.task?/1` is the wrong classifier for D-04.** It returns true for any module exporting `run/1`, so it counts `Mix.Tasks.Verify.PhoenixExample.Package` (a `@moduledoc false` helper with `def run(opts \\ [])`). Of the 61 `Mix.Tasks.*` modules in `:test`, 59 satisfy `task?/1` but only 58 declare the `Mix.Task` behaviour (`use Mix.Task`): the 8 public tasks plus 50 maintainer tasks. Three modules (`Verify.Capability`, `Verify.PhoenixExample.LockGraph`, `Verify.PhoenixExample.Package`) are helpers. | [VERIFIED: prototype `Mix.Task.task?/1` vs `module_info(:attributes)[:behaviour]`] | Classify with `Mix.Task in List.flatten(Keyword.get_values(m.module_info(:attributes), :behaviour))`. A passing guard test was run: 50 maintainer `use Mix.Task` modules all map to `:test`. |
| F6 | **D-11 mutation fixtures must be exact.** (a) The "hidden" case must be a top-level `defmodule Mix.Tasks.Verify.Hidden` placed in an ordinary `lib/scrypath/*.ex` file. A `defmodule Mix.Tasks.Verify.Hidden` nested inside another module compiles to `Parent.Mix.Tasks.Verify.Hidden`, which is not a Mix task, and the resolver must not flag it. (b) The `files:` mutation edits `mix.exs` by string replace; assert the replacement changed the text (`refute mutated == original`) or the test passes vacuously if the `~w(...)` line is reformatted. | [VERIFIED: prototype mutation run; nested case produces `Scrypath.HiddenHolder.Mix.Tasks...`] | Encode both in the fixtures. |
| F7 | **D-17's third assertion only sees `:test`.** `elixirc_paths/1` is private, so a test can read only the value for the current env (`Scrypath.MixProject.project()[:elixirc_paths]`, evaluated under `:test`). That is sufficient; the non-test side is proven by L2 and the prod compile of the archive. Do not make `elixirc_paths/1` public just for this. | [VERIFIED: guard test passes in prototype] | Keep `defp`. |
| F8 | **Optional ordering refinement for D-16.** `verify/capability.ex` references `scrypath.namespace_fence` at lines 105 and 112, and the fence file itself changes name and module. If those edits ride in the `git mv` commit, only 51 of 53 renames are 100%. Doing the D-03 rename in place first (module, task name, `capability.ex`, test move, `preferred_envs` entry), then the pure `git mv`, keeps the move commit at 53/53 100% renames and stays green at every step. | [ASSUMED: git rename detection of the two edited files was not measured] | Planner's choice inside D-16's exception clause. |
| F9 | **Subprocesses do not inherit `:test`.** `preferred_envs` routing sets `Mix.env()` in-process only; `System.get_env("MIX_ENV")` stays `nil`. Any `System.cmd("mix", ...)` from a verifier runs in `:dev` locally but `:test` in CI (job-level `MIX_ENV: test`). The new mutation test and prod/test archive compiles must pass `MIX_ENV` and `MIX_BUILD_PATH` explicitly. | [VERIFIED: tiny-project task printing `Mix.env=test OS MIX_ENV=nil`] | Always pass `env: [{"MIX_ENV", ...}, {"MIX_BUILD_PATH", ...}]`. |

Note on F5 counts (measured in `:test`: `{all, task?/1, behaviour, public, maintainer}` = `{61, 59, 58, 8, 50}`): 61 `Mix.Tasks.*` modules = 8 public + 53 moved; of the 53, 50 are `use Mix.Task` tasks (40 top-level + 9 capability + 1 fence) and 3 are helpers (D-02's "3 helper modules"). `task?/1` adds the helper `Verify.PhoenixExample.Package` (it exports `run/1` through a default argument) for 59.

## Prototype evidence

All of the following ran in a scratch copy of the repo (rsync of the working tree minus `.git`, `deps`-sized dirs kept; a throwaway git repo was initialised there for the git-dependent tests). The real checkout was never modified. Toolchain: Elixir 1.19.5 / OTP 28.1 (CI uses 1.19.0 / OTP 28.1).

| Check | Result |
|-------|--------|
| Move 53 files to `dev/mix/tasks`, add env-keyed `elixirc_paths`, `MIX_ENV=test mix compile --force --warnings-as-errors` | 148 files, clean, 61 `Mix.Tasks` beams |
| Same compile under `MIX_ENV=dev` | 95 files, clean, 8 `Mix.Tasks` beams (the public ones) |
| `mix verify.namespace_fence` with no `MIX_ENV` | routed to `:test`, printed "==> Namespace fence passed" |
| `MIX_ENV=dev mix verify.namespace_fence` / `mix verify.core` | `** (Mix) The task "..." could not be found` (D-06 behavior confirmed) |
| `mix verify.adopter` and `mix test test/mix/tasks/verify_adopter_test.exs` (documented commands) | 25 and 15 tests, 0 failures |
| Full fast suite after mechanical path flip (`lib/mix/tasks/` -> `dev/mix/tasks/` in the 13 test files) and the fence test rename | 1036 tests, 5 properties; 1 failure, `UAT-09 ... recent history` in `workflow_wiring_test.exs:496`, caused only by the scratch repo's one-commit git history |
| `mix verify.package` (full chain: metadata, consumer smoke, docs_contract, release contract greps, `hex.build --unpack`) | green in about 19 s |
| `hex.build --unpack` of the moved tree | top-level entries `.formatter.exs ARCHITECTURE.md CHANGELOG.md CONTRIBUTING.md LICENSE README.md SECURITY.md docs guides hex_metadata.config lib mix.exs`; `lib/mix` holds exactly the 8 public task files |
| git-dep consumer (existing `consumer_smoke_test.exs` flow) | existing test passes (2 tests, 7 s); consumer compiles 95 scrypath files, `_build/dev/lib/scrypath/ebin` holds 8 `Mix.Tasks` beams and 0 Verify beams; `mix verify.package` in consumer -> exit 1 `The task "verify.package" could not be found`; `mix scrypath.status` (no args) -> exit 1 `expected one schema module argument, for example `SearchablePost``; `mix help scrypath.status` -> exit 0 |
| Runtime probe in consumer: `:application.get_key(:scrypath, :modules)` filtered to `Elixir.Mix.Tasks.*` | the 8 public names; each has `Mix.Task.get/1` non-nil, non-empty shortdoc, `run/1` exported |
| path-dep consumer (`{:scrypath, path: ...}`) in `MIX_ENV=test` and `MIX_ENV=dev` | scrypath compiled as 95 files, 0 Verify beams in both (deps compile in `:prod`) |
| Unpacked archive compiled directly with `--warnings-as-errors` | `prod`: clean, 5 s, 8 task beams. `test` (absent `dev/mix/tasks` named in `elixirc_paths`): clean, 1 s, 8 task beams |
| Missing `dev/mix/tasks` in `elixirc_paths(:test)` on a tiny project, `--force --warnings-as-errors`, all three envs | clean on Elixir 1.17.3/OTP 27.3, 1.19.5/OTP 28.1 and 1.20.4/OTP 29.1.1 |
| `mix credo --strict` before/after `"dev/"` in `.credo.exs` `included` | 213 -> 266 source files, no issues |
| `mix format --check-formatted` with a deliberate format error in a `dev/` file | exit 0 without `dev` in `.formatter.exs` inputs (silent loss); exit 1 with it |
| Consumer of the **published** Hex 0.3.17 | `mix help` shows 25 `verify*`/fence entries, including `mix verify` ("Runs the standard repository maturity gate") and `mix scrypath.namespace_fence` |
| Prototype `PackageContract` + 5 D-11 mutations + control, hermetic `hex.build` in a tmp copy (no `deps/`, no `mix.lock`, `HEX_OFFLINE=1`, isolated `MIX_BUILD_PATH`) | control `:ok`; each mutation yields exactly the expected sorted violation; total 2.4 s |
| Support helper used at **compile time** by a test file (`@src Scrypath.RepoTooling.task_source!(...)`) | works (test_helper requires `test/support/**` before test files compile) |

## Architectural Responsibility Map

This is a build/packaging phase, so the "tiers" are repository layers rather than web tiers.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public operator tasks (8) | Packaged library source `lib/mix/tasks/` | `guides/operator-mix-tasks.md` | They ship to adopters and are the only Mix tasks the package may expose. |
| Maintainer verifiers and helpers (53 files) | Unpackaged tooling tree `dev/mix/tasks/` | `mix.exs` `cli/0 preferred_envs` | Compiled only in `:test`; never in `files:`; env routing is what keeps every command callable. |
| Env-scoped compilation | Package manifest `mix.exs` `elixirc_paths/1` | — | Mix evaluates it per env; deps get `:prod`, so consumers are insulated. |
| Leak gate (contents + AST + compiled consumer) | Test support `test/support/release/package_contract.ex` (pure) | `test/release/package_contents_test.exs`, `consumer_smoke_test.exs` (thin runners) | Keeps the checker unpackaged and unit-testable; real `hex.build` output is the input. |
| Gate wiring | `verify.phase11` test list (lane `package`) | `docs_contract_test.exs` pins, `package_metadata_test.exs` | Reuses the required `package` job and the publish pre-checks; no new job. |
| Coverage that must follow the move | CI/config (`.formatter.exs`, `.credo.exs`, `scripts/ci/beam_cache.cjs`, `ci.yml` regex, `verify.workspace_clean`) | `workflow_wiring_test.exs` HYG-02 scans | Each silently stops covering moved files unless `dev` is added. |
| Contributor documentation | `CONTRIBUTING.md` | README, support guides (qualifier only) | Contract tests pin exact command strings; only qualifiers may be added. |

## Standard Stack

No new dependencies (maintainer preference; the move and the gate use only Mix, ExUnit, `Code`, `Mix.Task` and `System.cmd`).

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | `~> 1.17` floor (`mix.exs`), CI 1.19.0/OTP 28.1 (`ci.yml`); verified here on 1.17.3, 1.19.5, 1.20.4 | `elixirc_paths`, `cli/0 preferred_envs`, `Mix.Task.task_name/1`, `Mix.Task.get/1`, `hex.build --unpack` | The mechanism is built into Mix; same env-keyed shape used by Phoenix and Oban (per CONTEXT). |
| ExUnit | bundled | Gate tests, `@tag :tmp_dir`, `setup_all` | Existing test stack. |
| ex_doc | 0.40.3 (`mix.lock`) | Docs build in `:dev` and `:test` | Already a dep; behavior in F1 measured against this version. |
| credo | 1.7.18 (`mix.lock`) | `--strict` now must include `dev/` | Existing gate. |
| dialyxir | 1.4.7 (`mix.lock`) | Runs in `:test` so it still analyzes `dev/` | Existing gate; `plt_add_apps: [:mix]` already set. |
| Node.js | v26.10.0 locally | `scripts/ci/beam_cache.test.cjs` (run inside `workflow_wiring_test.exs`) | Existing Phase 182 harness. |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `mix hex.build --unpack --output <tmp>` | Produce the real archive | Every gate input; never use the default output dir (it writes `scrypath-<version>/` into the repo root, gitignored by `/scrypath-*/`). |
| `git diff -M --stat` | Prove 100% renames | D-16 step 3. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Unfiltered docs (recommended, F1) | `filter_modules` + `skip_undefined_reference_warnings_on` listing every doc file | Would suppress real undefined-reference warnings in README/guides, defeating the docs gate. Not recommended. |
| Unfiltered docs | `@moduledoc false` on every Verify module | Hides the tasks from `mix help` in `:test` (rejected in D-07). |
| `Mix.Task.task?/1` | `behaviour` attribute (recommended, F5) | `task?/1` over-counts helpers that export `run/1`. |

**Installation:** none.

**Version verification:** Elixir/OTP versions were confirmed with `mix --version` under asdf (`ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1`); dependency versions are from `mix.lock`. No registry lookup is needed because nothing is installed.

## Package Legitimacy Audit

No external packages are added or changed by this phase, so the legitimacy seam (`package-legitimacy check`) was not run and no row is required.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | — |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
Contributor shell                                           Adopter (Hex / git / path dep)
  mix verify.package                                          {:scrypath, "~> x"}   mix deps.compile
        |                                                              |
        v                                                              v
 Mix CLI reads mix.exs cli/0  -- "verify.package": :test -->   dep env = :prod (default)
        |                                                              |
        v                                                              v
 Mix.env = :test                                              elixirc_paths(:prod) = ["lib"]
 elixirc_paths(:test) = ["lib", "dev/mix/tasks"]                       |
        |                                                              v
        v                                                    ebin: 8 Mix.Tasks.Scrypath.* only
 _build/test/lib/scrypath/ebin  (8 public + 53 maintainer modules)
        |
        |  Phase11.run_without_docs  (reached from verify.package, ci.yml `package` job,
        |                             release-please.yml, publish-hex.yml)
        v
 mix test  test/release/package_metadata_test.exs
           test/release/package_contents_test.exs   <-- NEW (hermetic, ~2.5 s)
           test/release/consumer_smoke_test.exs     <-- EXTENDED (L2)
           test/scrypath/docs_contract_test.exs
        |
        +--> package_contents_test:
        |      tmp copy of packaged files --(optional mutation)--> `mix hex.build --unpack --output tmp`
        |         --> PackageContract.check(unpacked_dir)
        |               L0: File.ls!(dir) subset-of @allowed_top_level
        |               L1: lib/**/*.ex --Code.string_to_quoted!--> Mix.Tasks.* names == @public_tasks
        |               --> :ok | {:error, sorted "[tag] name module path fix: ..." lines}
        |
        +--> consumer_smoke_test (L2):
               real `hex.build --unpack` --> git-tagged artifact --> `mix new` consumer (git dep)
                 --> deps.get, compile (MIX_ENV=dev consumer, dep compiled as :prod)
                 --> ebin Mix.Tasks == 8 public, no Verify beams
                 --> `mix verify.package` exits non-zero "could not be found"
                 --> `mix scrypath.status` exits 1 with its usage error
```

### Recommended Project Structure
```
dev/mix/tasks/                          # NEW, unpackaged, compiled only in :test (53 files)
  verify.ex  verify.all.ex  verify.adopter.ex  verify.coverage.ex
  verify.meilisearch_smoke.ex  verify.no_optional_deps.ex  verify.ops_ui.ex
  verify.postgres.ex  verify.release_parity.ex  verify.release_publish.ex
  verify.workspace_clean.ex  verify.namespace_fence.ex     # renamed from scrypath.namespace_fence
  verify.phase{5,8,10,11,13,14,20,22,26,28,36,37,38,41,43,82,83,84,85,91,94,96,97,98,99,106,107,108,112}.ex
  verify/{backend,capability,compatibility,core,deep_quality,ecommerce_e2e,
          ecommerce_mounted,package,phoenix_example,repository_contracts}.ex
  verify/phoenix_example/{lock_graph,package}.ex
lib/mix/tasks/                          # 8 files, packaged
  scrypath.{status,failed,retry,reconcile}.ex
  scrypath.settings.{diff,read,hot_apply}.ex
  scrypath/index/contract_drift.ex
test/support/repo_tooling.ex            # Scrypath.RepoTooling (tasks_root/0, task_path/1, task_source!/1)
test/support/release/package_contract.ex# Scrypath.Release.PackageContract (pure + thin check/1)
test/release/package_contents_test.exs # NEW: control + D-11 mutations + boundary guard
test/mix/tasks/verify_namespace_fence_test.exs   # moved from test/mix/tasks/scrypath/namespace_fence_test.exs
```

### Pattern 1: Env-keyed `elixirc_paths`
**What:** The maintainer tree is a source path only in `:test`; `cli/0 preferred_envs` makes every documented command run there.
**When to use:** Any code that must exist for contributors but never ship or compile in a dependent app.
**Example:**
```elixir
# mix.exs  (verified in prototype; the tree compiled warning-free on 1.17.3, 1.19.5, 1.20.4)
def project do
  [
    app: :scrypath,
    version: @version,
    elixir: "~> 1.17",
    start_permanent: Mix.env() == :prod,
    elixirc_paths: elixirc_paths(Mix.env()),
    deps: deps(),
    # ...
  ]
end

# Maintainer verifiers live in dev/mix/tasks and compile only under :test. Dependencies
# compile in :prod, so Hex, git and path consumers never see them.
defp elixirc_paths(:test), do: ["lib", "dev/mix/tasks"]
defp elixirc_paths(_env), do: ["lib"]
```
Also add `"verify.namespace_fence": :test,` to `preferred_envs` (D-03). `[CITED: https://mix.hexdocs.pm/Mix.Tasks.Deps.html]` states dependencies default to `:prod`; `[CITED: https://mix.hexdocs.pm/Mix.Project.html]` describes `preferred_envs` as a keyword list of `{task, env}`.

### Pattern 2: Pure classifier plus thin runner (repo idiom)
**What:** `classify/2` takes plain data and returns `:ok | {:error, [line]}`; `check/1` does the I/O. Mirrors `Mix.Tasks.Verify.ReleaseParity.compute/2` and `WorkspaceClean.classify/3`.
**Example (prototype, passes control and all five mutations):**
```elixir
defmodule Scrypath.Release.PackageContract do
  @moduledoc false
  # Source of truth for what the Hex archive may contain. Never packaged (lives in test/support).
  @public_tasks ~w(scrypath.failed scrypath.index.contract_drift scrypath.reconcile scrypath.retry
                   scrypath.settings.diff scrypath.settings.hot_apply scrypath.settings.read scrypath.status)
  # Mirrors package files: top-level entries plus the file `mix hex.build` adds.
  @allowed_top_level ~w(.formatter.exs ARCHITECTURE.md CHANGELOG.md CONTRIBUTING.md LICENSE README.md
                        SECURITY.md docs guides hex_metadata.config lib mix.exs)

  def public_tasks, do: @public_tasks
  def allowed_top_level, do: @allowed_top_level

  @spec check(Path.t()) :: :ok | {:error, [String.t()]}
  def check(unpacked_dir) do
    top = unpacked_dir |> File.ls!() |> Enum.sort()

    sources =
      unpacked_dir
      |> Path.join("lib/**/*.ex")
      |> Path.wildcard()
      |> Enum.map(&{Path.relative_to(&1, unpacked_dir), File.read!(&1)})

    classify(top, collect_task_modules(sources))
  end

  @spec classify([String.t()], [{String.t(), module(), String.t()}]) :: :ok | {:error, [String.t()]}
  def classify(top_level, task_modules) do
    forbidden =
      for e <- top_level, e not in @allowed_top_level,
        do: "[forbidden-path] #{e} fix: remove it from package files: (maintainer tooling belongs in dev/)"

    seen = MapSet.new(task_modules, &elem(&1, 0))

    unexpected =
      for {n, m, p} <- task_modules, n not in @public_tasks,
        do: "[unexpected-task] #{n} #{inspect(m)} #{p} fix: move it to dev/mix/tasks/, or add it to @public_tasks and document it in guides/operator-mix-tasks.md"

    missing =
      for n <- @public_tasks, not MapSet.member?(seen, n),
        do: "[missing-task] #{n} fix: restore its file under lib/mix/tasks/"

    case Enum.sort(forbidden ++ unexpected ++ missing) do
      [] -> :ok
      violations -> {:error, violations}
    end
  end

  def collect_task_modules(sources) do
    for {path, src} <- sources,
        mod <- src |> Code.string_to_quoted!() |> modules([]),
        String.starts_with?(Atom.to_string(mod), "Elixir.Mix.Tasks."),
        do: {Mix.Task.task_name(mod), mod, path}
  end

  # Walk the AST; nested defmodule names are prefixed by the enclosing module (Elixir semantics).
  defp modules({:defmodule, _, [name, [do: body]]}, parents) do
    full = resolve(name, parents)
    [full | modules(body, [full | parents])]
  end

  defp modules({_, _, args}, parents) when is_list(args), do: Enum.flat_map(args, &modules(&1, parents))
  defp modules(list, parents) when is_list(list), do: Enum.flat_map(list, &modules(&1, parents))
  defp modules({a, b}, parents), do: modules(a, parents) ++ modules(b, parents)
  defp modules(_, _), do: []

  defp resolve({:__aliases__, _, [{:__MODULE__, _, _} | rest]}, [p | _]), do: Module.concat([p | rest])
  defp resolve({:__aliases__, _, parts}, []), do: Module.concat(parts)
  defp resolve({:__aliases__, _, parts}, [p | _]), do: Module.concat([p | parts])
end
```
Add a unit test that `@allowed_top_level` minus `hex_metadata.config` equals the set of first path segments of `Scrypath.MixProject.project()[:package][:files]`, so the constant cannot drift from `mix.exs`. `@public_tasks` must also equal the task names derived from the repo's own `lib/mix/tasks` tree (a second tripwire on the source side).

### Pattern 3: Hermetic mutation test (D-11)
**What:** Copy only the packaged files to a tmp dir, optionally mutate, run a real `hex.build --unpack --output`, then `PackageContract.check/1`.
**Key facts (all measured):** needs no `deps/`, no `mix.lock` and no network; about 0.4 s per build; six builds took 2.4 s.
```elixir
# in test/release/package_contents_test.exs (sketch; use @moduletag :tmp_dir or per-test @tag :tmp_dir)
@packaged ~w(lib .formatter.exs mix.exs README.md CONTRIBUTING.md ARCHITECTURE.md CHANGELOG.md
             LICENSE SECURITY.md guides docs)

# tmp_dir is the ExUnit @tag :tmp_dir path; copy each entry of @packaged from File.cwd!() into
# Path.join(tmp_dir, "src"), apply the mutation, then build and check.
defp build_and_check!(src_copy, out) do
  {output, status} =
    System.cmd("mix", ["hex.build", "--unpack", "--output", out],
      cd: src_copy,
      stderr_to_stdout: true,
      env: [
        {"MIX_ENV", "test"},
        {"MIX_BUILD_PATH", Path.join(src_copy, "_build_isolated")},
        {"HEX_OFFLINE", "1"}
      ]
    )

  assert status == 0, "hex.build failed:\n" <> output
  Scrypath.Release.PackageContract.check(out)
end
```
Mutations (each asserts the exact tag and name, and the control asserts `:ok`):
1. `lib/mix/tasks/scrypath.repo_only.ex` defining `Mix.Tasks.Scrypath.RepoOnly` -> `[unexpected-task] scrypath.repo_only`.
2. `lib/mix/tasks/verify.sneaky.ex` -> `[unexpected-task] verify.sneaky`.
3. A **top-level** `defmodule Mix.Tasks.Verify.Hidden` appended to an ordinary `lib/scrypath/*.ex` file -> `[unexpected-task] verify.hidden` with that file's path (F6).
4. `mix.exs` `files:` gains `dev` (string replace of `~w(lib ` with `~w(dev lib `, with `refute mutated == original`) plus a file under `dev/` -> `[forbidden-path] dev`.
5. Delete `lib/mix/tasks/scrypath.status.ex` -> `[missing-task] scrypath.status`.

### Pattern 4: Test-support helper that survives the move (D-14)
```elixir
# test/support/repo_tooling.ex  (loaded by test_helper.exs before test files compile; verified usable in @module attributes)
defmodule Scrypath.RepoTooling do
  @moduledoc false
  # Step 1 of D-16 ships this pointing at "lib/mix/tasks"; step 3 flips it to "dev/mix/tasks".
  @tasks_root "dev/mix/tasks"

  def tasks_root, do: @tasks_root
  def task_path(relative), do: Path.join(@tasks_root, relative)
  def task_source!(relative), do: relative |> task_path() |> File.read!()
end
```
Call sites become `Scrypath.RepoTooling.task_source!("verify.phase11.ex")`, `task_path("verify/#{task}.ex")`, `task_path("verify.ops_ui.ex")`, `task_path("verify/phoenix_example/package.ex")`. Compile-time attributes in `docs_contract_test.exs` (lines 17-34 and 67) use the same calls.

### Pattern 5: Extend the existing consumer smoke test (L2) without a second `deps.get`
Move the expensive setup (artifact build, `git` tag, `mix new`, `deps.get`, `compile`) into `setup_all` (or one shared helper) returning `%{app_dir: ..., artifact_dir: ...}`, keep the existing test, and add a second test that reads the compiled consumer. `on_exit` registered in `setup_all` runs after the module. The new assertions need no VM boot for the module list:
```elixir
# ebin and .app file of the git dependency inside the consumer (MIX_ENV=dev consumer, dep compiled as :prod)
ebin = Path.join(app_dir, "_build/dev/lib/scrypath/ebin")
beams = ebin |> File.ls!() |> Enum.filter(&String.starts_with?(&1, "Elixir.Mix.Tasks."))
refute Enum.any?(beams, &String.starts_with?(&1, "Elixir.Mix.Tasks.Verify."))

{:ok, [{:application, :scrypath, props}]} = :file.consult(Path.join(ebin, "scrypath.app"))
task_names =
  for m <- props[:modules], String.starts_with?(Atom.to_string(m), "Elixir.Mix.Tasks."),
      do: Mix.Task.task_name(m)
assert Enum.sort(task_names) == Enum.sort(Scrypath.Release.PackageContract.public_tasks())

# CLI behavior, run with the same isolated env (HEX_HOME, MIX_HOME, MIX_ENV=dev):
{out, status} = System.cmd("mix", ["verify.package"], cd: app_dir, env: isolated_env, stderr_to_stdout: true)
assert status != 0 and out =~ ~s|The task "verify.package" could not be found|
{out, status} = System.cmd("mix", ["scrypath.status"], cd: app_dir, env: isolated_env, stderr_to_stdout: true)
assert status == 1 and out =~ "expected one schema module argument"
```
Observed in the bare consumer: `mix scrypath.status` with no args exits 1 with "expected one schema module argument, for example `SearchablePost`", so the preferred (usage-error) path works and the `mix help` fallback is not needed. Also assert `Mix.Task.get/1`, a non-empty shortdoc and `function_exported?(mod, :run, 1)` through `mix run --no-start -e` if the VM-level check from D-10 is wanted; this was exercised and returned `true` for all 8.

### Pattern 6: D-04 and D-17 guard tests (verified passing in prototype)
```elixir
@preferred Scrypath.MixProject.cli()[:preferred_envs]

test "maintainer tooling lives outside lib and the package" do
  assert Path.wildcard("lib/mix/tasks/verify*") == []
  assert File.dir?("dev/mix/tasks")
  assert "dev/mix/tasks" in Scrypath.MixProject.project()[:elixirc_paths]
  refute "dev" in Scrypath.MixProject.project()[:package][:files]
end

test "every maintainer Mix.Task has a :test preferred_env and every verify* key resolves" do
  {:ok, modules} = :application.get_key(:scrypath, :modules)

  maintainer_tasks =
    for m <- modules,
        String.starts_with?(Atom.to_string(m), "Elixir.Mix.Tasks.Verify"),
        Code.ensure_loaded?(m),
        Mix.Task in List.flatten(Keyword.get_values(m.module_info(:attributes), :behaviour)),
        do: Mix.Task.task_name(m)

  assert maintainer_tasks != []
  for t <- maintainer_tasks, do: assert(@preferred[String.to_atom(t)] == :test, "no :test preferred_env for #{t}")

  for {key, _} <- @preferred, String.starts_with?(Atom.to_string(key), "verify") do
    assert Mix.Task.get(Atom.to_string(key)), "preferred_envs key #{key} resolves to no task"
  end
end
```
In the prototype this found exactly 50 maintainer tasks, all with `:test`. Avoid hard-coding 50 in the committed test; assert non-empty and the per-task mapping.

### Pattern 7: BEAM-cache fixture (D-08)
`scripts/ci/beam_cache.test.cjs` already has a fixture-tree test (`path graph manifests and locks fingerprint only the consuming resolved cache`, files map at about lines 187-196). Add `"dev/mix/tasks/verify.ex": "maintainer source\n"` to that `files` map and append a test (or assertions) that for each of the four graphs (`root`, `ops`, `ecommerce`, `phoenix-example`) `buildPlan(...).source_digest`-derived keys (`resolved_key`) change after `fs.appendFileSync(path.join(root, "dev/mix/tasks/verify.ex"), "changed\n")`, and that `source_files` contains `dev/mix/tasks/verify.ex`. `collectSourceFiles` already skips absent roots (`if (fs.existsSync(absolute)) visit(sourceRoot)`), so adding `"dev"` before the directory exists is safe. This suite runs inside `workflow_wiring_test.exs` (`node --test ... scripts/ci/beam_cache.test.cjs ...`), i.e., in the `repository-contracts` lane.

### Anti-Patterns to Avoid
- **`filter_modules` for Verify modules (F1).** Breaks `:test` docs with `--warnings-as-errors`.
- **A `verify.*` denylist or a `files:` text check.** Misses `scrypath.namespace_fence`-style names and cannot prove the public tasks are retained (D-09/D-10).
- **Regex over source for `defmodule`.** Misses nesting and `__MODULE__`-relative names; use the AST.
- **Default `hex.build --unpack` output dir.** Pollutes the repo root and races with `Phase11`'s own final unpack.
- **Compiling `dev/` in all envs or via `Code.require_file`.** Rejected in D-05; it leaks into path/git deps.
- **Rewriting archived `.planning/` evidence (D-20).**

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Module -> task name | String munging of module atoms | `Mix.Task.task_name/1` | Handles `HotApply` -> `hot_apply` and dotted namespaces; matches how Mix resolves tasks. |
| Find `Mix.Tasks.*` modules in source | Regex on `defmodule` | `Code.string_to_quoted!/1` plus a small nested-aware walk | Regex misses nesting and `__MODULE__` forms (F6). |
| Build the archive | Copy files by `files:` text | `mix hex.build --unpack --output <tmp>` | Only Hex knows the final file set, including `hex_metadata.config`. |
| Prove consumer behavior | A hand-built fake consumer | The existing `consumer_smoke_test.exs` consumer (git dep, tagged artifact) | Already release-like, isolated `HEX_HOME`/`MIX_HOME`, and forbids `path:` deps. |
| Temp dirs | `File.mkdir_p!` plus manual cleanup | ExUnit `@tag :tmp_dir` / `@moduletag :tmp_dir` | Auto-cleaned, unique per test. |
| Env routing for contributor commands | Wrapper scripts or aliases | `cli/0 preferred_envs` | Already used for 50+ tasks; works for subcommands and CI. |
| Source-vs-archive parity for old tags | Reusing the new checker | Existing `verify.release_parity` (unchanged, D-13) | Tag-vs-tarball path sets are both computed; old tags legitimately contain `verify.*`. |

**Key insight:** every piece needed already exists as a Mix/ExUnit/Hex primitive. The only new logic is a roughly 60-line pure classifier and fixtures; resist adding a manifest file, a new Mix task, or a new CI job.

## Runtime State Inventory

This phase relocates source files and renames one task, so the state inventory applies.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None. No datastore, collection, ID or key embeds `lib/mix/tasks`, `verify.*` or `scrypath.namespace_fence` as data (grep of `lib/scrypath`, `priv`, `config` found no references; the only `namespace_fence` hits are the task, its test, `capability.ex` and `verify_capability_test.exs`). | None. |
| Live service config | `.github/workflows/ci.yml` line 359: the `ops-ui-path` filter `grep -qE '^(scrypath_ops/\|lib/\|mix\\.exs\|mix\\.lock)'` decides whether the path-scoped `ops-ui` job runs; verifier edits used to be under `lib/` and will be under `dev/`. Required-check names (`core (required)`, `package (required)`, ...) do not change. GitHub branch protection references job names only. | Code edit: add `dev/` to the regex (D-08). No data migration. |
| OS-registered state | None. No launchd/systemd/Task Scheduler/pm2 entries reference these paths; `scripts/verify_phase11_docker.sh` runs `mix verify.phase11` by name and mounts `$PWD:/app` (so `dev/` is present). | None. |
| Secrets/env vars | None change. `HEX_API_KEY` handling is untouched; `docs_contract_test` still refutes it inside `verify.phase11`. Tests read env names (`SCRYPATH_*`), not the renamed task. | None. |
| Build artifacts / installed packages | (1) CI BEAM cache: `_build/test` restored by `scripts/ci/beam_cache.cjs`; without `dev` in `sourceRoots` a `dev/`-only edit would not rotate the key (stale beams). The move itself rotates all four graph keys once (expected). (2) Dialyzer PLT cache key derives from the same plan (`plt_key`). (3) Repo-root `scrypath-0.3.*` unpack directories (gitignored) hold old archives; `Phase11` overwrites `scrypath-<current>/`. (4) Examples/ops `_build` dirs from earlier runs may still hold old Verify beams until recompiled (Mix removes beams for deleted sources on the next compile). (5) The **published** Hex 0.3.17 and its HexDocs are immutable and still contain the verifiers; only the next release fixes adopters. | Edit `beam_cache.cjs` (+ fixture test); no manual cache deletion needed; note (5) in the PR description and leave the release to the maintainer (deferred item). |

## Common Pitfalls

### Pitfall 1: `filter_modules` turns the `:test` docs build red
**What goes wrong:** Adding the D-07 filter makes `MIX_ENV=test mix docs --warnings-as-errors` fail (about 59 "reference to a filtered module" warnings), so `mix verify` (step 6/6), `mix verify.core` and `mix verify.phase11` go red in CI.
**Why it happens:** In `:test` the Verify modules exist, ExDoc autolinks `mix verify.x` to them, then finds them filtered. In `:dev` they do not exist, so nothing links.
**How to avoid:** Leave `docs/0` unchanged (F1). Run both `MIX_ENV=test mix docs --warnings-as-errors` and `MIX_ENV=dev mix docs --warnings-as-errors` once during execution and record the output.
**Warning signs:** The string "reference to a filtered module" in docs output; "generation for html, epub formats failed due to warnings".

### Pitfall 2: Silent coverage loss for moved files
**What goes wrong:** `mix credo --strict` drops from 266 to 213 files, `mix format --check-formatted` stops looking at `dev/`, the BEAM cache stops keying on `dev/`, `verify.workspace_clean` stops flagging uncommitted `dev/` edits, `ops-ui-path` stops triggering on verifier edits, HYG-02 scans stop covering the moved sources. Nothing fails.
**How to avoid:** Apply every D-08 edit and add a check for each that can fail: the beam-cache fixture, a `workspace_clean` pathspec assertion (`"dev" in pathspecs`; existing test asserts membership only, so it will not break), and for formatter/credo a one-time proof in the plan (deliberately malformat a `dev/` file and see it rejected). For `workflow_wiring_test.exs`, scan `["lib/**/*.ex", "dev/**/*.ex"]`; no `no_warn_undefined` or `Code.put_compiler_option` exists in `dev/` today, so the Oban site count (>= 3, all in `lib/scrypath/oban*`) is unchanged.
**Warning signs:** File counts in tool output drop after the move.

### Pitfall 3: `mix help verify.x` and explicit `MIX_ENV=dev` fail
**What goes wrong:** `mix help verify.adopter` from a shell says the task could not be found (F2).
**How to avoid:** Document `MIX_ENV=test mix help verify.x` in the CONTRIBUTING sentence; do not change `help`'s env.

### Pitfall 4: Vacuous or over-eager mutation tests
**What goes wrong:** A `String.replace` on `mix.exs` that no longer matches leaves the control copy unchanged, and the "dev in files:" case passes for the wrong reason; a nested `defmodule` fixture is not a Mix task.
**How to avoid:** F6. Assert the mutation happened; assert the exact tag, task name and path in the violation line, not just `{:error, _}`.

### Pitfall 5: Subprocess environment mismatch
**What goes wrong:** Locally `mix verify.package` runs in-process as `:test` but spawned `mix` commands run in `:dev`; in CI both are `:test`. A test that works in CI can fail locally (or the reverse) if it relies on inherited env.
**How to avoid:** Pass `MIX_ENV`, `MIX_BUILD_PATH`, `HEX_HOME`, `MIX_HOME` explicitly in every `System.cmd` (the consumer smoke test already does this for HEX/MIX homes and `MIX_ENV=dev`).

### Pitfall 6: Stale unpack directory read as evidence
**What goes wrong:** The repo-root `scrypath-0.3.17/` is rebuilt by every local `mix verify.package`, so "pre-move" evidence taken after any post-move run is actually post-move.
**How to avoid:** Capture the pre-move count (F4) with `mix hex.build --unpack --output <tmp>` before the move commit, or from `mix hex.package fetch scrypath 0.3.17 --unpack -o <tmp>` (published, 52).

### Pitfall 7: Renaming the fence without its call sites
**What goes wrong:** `verify/capability.ex` names the task as `task_runner.("scrypath.namespace_fence", [])` (line 105), a `defp run_deep_quality_task!("scrypath.namespace_fence", [])` clause head (line 111) and `Mix.Task.run("scrypath.namespace_fence")` (line 112); `verify_capability_test.exs` asserts the sequence (lines 88 and 97). Missing either breaks `verify.deep_quality` (CI job `deep-quality`, which runs `Mix.Tasks.Verify.Capability.run_deep_quality_without_audit()` in `:test`) at runtime, not compile time.
**How to avoid:** One grep for `scrypath.namespace_fence` must return nothing outside archived `.planning/` after the rename.

### Pitfall 8: A new `Mix.Tasks.*` helper in `lib/` for a public task
**What goes wrong:** A future public task with a helper module named `Mix.Tasks.Scrypath.Something.Helper` (or any extra `Mix.Tasks.*` module) fails the allowlist by design.
**How to avoid:** The failure line's "fix:" hint names both remedies (move to `dev/`, or add to `@public_tasks` and document it). Keep helper modules outside the `Mix.Tasks.*` namespace (like `Scrypath.CLI.OperatorTask`).

## Code Examples

### The `verify.phase11` test list and its pin (D-12)
Current list (`lib/mix/tasks/verify.phase11.ex:28-35`, verbatim):
```elixir
run_test!(
  [
    "test/release/package_metadata_test.exs",
    "test/release/consumer_smoke_test.exs",
    "test/scrypath/docs_contract_test.exs"
  ],
  "Release contract tests"
)
```
Add `"test/release/package_contents_test.exs"` (suggested position: after `package_metadata_test.exs`, before the network-bound consumer smoke so the fast hermetic failure shows first). Update the pin in `test/scrypath/docs_contract_test.exs` test `"verify.phase11 keeps the release gate auth-free and complete"` (the `assert_contains_all(@verify_phase11, [...])` list, currently the three paths plus `"mix verify.release_publish"`). Add `refute "dev" in package[:files]` alongside the existing `refute "scrypath_ops" in package_files` lines in `package_metadata_test.exs` ("package file allowlist only targets root library surfaces").

### Config edits (D-08), exact current text and the change
- `.formatter.exs` line 4: `"{config,lib,test}/**/*.{ex,exs}",` -> `"{config,lib,dev,test}/**/*.{ex,exs}",`
- `.credo.exs` line 6: `included: ["lib/", "test/", "mix.exs"],` -> `included: ["lib/", "dev/", "test/", "mix.exs"],`
- `scripts/ci/beam_cache.cjs` lines 18, 24, 30, 36: each `sourceRoots: ["lib", "test", "config", "priv", ...]` gains `"dev"` (for example `["lib", "dev", "test", "config", "priv"]`).
- `.github/workflows/ci.yml` line 359: `grep -qE '^(scrypath_ops/|lib/|mix\.exs|mix\.lock)'` -> `grep -qE '^(scrypath_ops/|lib/|dev/|mix\.exs|mix\.lock)'`
- `lib/mix/tasks/verify.workspace_clean.ex` line 96 (becomes `dev/mix/tasks/...` after the move): `package_files ++ ["test"]` -> `package_files ++ ["dev", "test"]` (keep the comment accurate: `dev` is unpackaged but must be committed for the gate to be meaningful). `git status --porcelain -- ... dev` exits 0 even when `dev` does not exist yet, so step 2 can land before the move.
- `test/mix/tasks/workflow_wiring_test.exs` lines 18 and 28 scan only `"lib/**/*.ex"`; extend both to include `dev/**/*.ex`. Line 8 `@verify_task "lib/mix/tasks/verify.ex"` goes through `Scrypath.RepoTooling.task_path("verify.ex")`.
- `CODEOWNERS` currently has a single line `lib/scrypath/ @szTheory`; optional `/dev/ @szTheory`.

### Operator-doc sync for `@public_tasks`
`guides/operator-mix-tasks.md` documents seven tasks by `mix scrypath.*` heading text; `scrypath.settings.read` is documented in `guides/relevance-tuning.md:73` (packaged) instead. The D-11 "fix:" hint says "document it in `guides/operator-mix-tasks.md`"; consider also a small test that each name in `@public_tasks` appears in at least one packaged guide so the allowlist cannot outgrow its documentation.

### D-18 doc wording (verified clean in both docs envs)
CONTRIBUTING (insert before "Use capability-named commands for new work."): "Repository-only `mix verify*` tasks live in `dev/mix/tasks/` and are not part of the Hex package; public operator tasks (`mix scrypath.*`) stay in `lib/mix/tasks/`. Command names and focused test paths are unchanged. Verifier tasks compile only under `MIX_ENV=test`, which `preferred_envs` selects automatically; `MIX_ENV=dev mix verify.x` (or `mix help verify.x` without `MIX_ENV=test`) reports that the task could not be found." Applying a sentence of this shape produced zero ExDoc warnings in both envs. Packaged README/guides keep `mix verify.adopter`, `mix verify.adopter --live`, `mix verify.meilisearch_smoke` verbatim (they are pinned by `docs_contract_test.exs:315-343`, `phase99_contract_test.exs`, `readiness_contract_test.exs`, `phase98_contract_test.exs`) and only gain a qualifier such as "from a source checkout (not part of the Hex package)". Optionally add one sentence to `docs/releasing.md` describing the new contents gate inside `verify.package` (no contract test forbids it).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| All Mix tasks in `lib/`, shipped to every consumer | Maintainer tasks in an env-keyed extra source path (`elixirc_paths(:test)`) | Phoenix/Oban/Ecto/LiveView use env-keyed `elixirc_paths` [CITED: CONTEXT.md Canonical References] | Consumers compile only `lib/`. |
| Denylist of forbidden path prefixes in `consumer_smoke_test.exs` (`scrypath_ops/`, `examples/`, `website/`, `.planning/`, `node_modules/`, `playwright-report/`, `test-results/`) | Fail-closed top-level allowlist plus AST task inventory plus compiled-consumer check | This phase | Catches `dev/`, non-`verify` names, and missing public tasks. The old denylist block is superseded by L0 and can be replaced by it. |
| `preferred_envs` via `Mix.env` hacks | `cli/0` `preferred_envs` (Mix >= 1.15) | already in use | Required for this design (D-04). |

**Deprecated/outdated:**
- `scrypath.namespace_fence` as a public-looking name: replaced by `verify.namespace_fence` with no alias (D-03).
- Hand-maintained `forbidden_prefixes` in `consumer_smoke_test.exs`: replaced by the allowlist.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mix hex.publish` (dry-run and real) runs `docs` in the invoking env, `:dev` in `release-please.yml`/`publish-hex.yml` where `MIX_ENV` is unset, so the published HexDocs are built from `lib/` only. Not observed in this session; the `:dev` docs build itself was proven clean. | Findings F1, Runtime State | Low. If publish built docs in `:test`, HexDocs would still list Verify pages (cosmetic), not fail. Executor can confirm with the next release's `--dry-run` log. |
| A2 | CI (GitHub-hosted, Elixir 1.19.0/OTP 28.1, Ubuntu) behaves like the local 1.19.5/OTP 28.1 macOS prototype for docs, compile and the hermetic `hex.build`. | Prototype evidence | Low; the verified tiny-project matrix covers 1.17.3 through 1.20.4. Full-tree compile on 1.17.3 was not run (the verifier sources already compile on 1.17 today from `lib/`). |
| A3 | Git rename detection will keep the two edited files (fence, `capability.ex`) as renames if edited in the move commit. | F8 | Cosmetic (blame). Avoided entirely by doing the D-03 rename in place first. |
| A4 | HexDocs pages for 0.3.17 remain published (Hex docs are not retroactively rewritten). | Runtime State | None for this phase. |
| A5 | A consumer `mix verify` collision (an adopter defining its own `verify` task or alias) is a plausible real-world harm of the leak; observed only that the leaked task resolves in a consumer's `mix help`. | Summary | None; motivates PKGH-01 only. |

**If this table is empty:** not applicable; items above are low-risk and none block planning.

## Open Questions

1. **Is the maintainer comfortable amending D-07 (drop `filter_modules`)?**
   - What we know: D-07 requires both docs builds to be clean; with the filter the `:test` build is not (F1); without it both are.
   - What's unclear: whether "docs builds agree" (identical module lists) is a hard requirement beyond "both clean". They cannot agree without warnings; ExDoc offers no clean way to hide modules in `:test` while keeping `mix verify.x` references legal.
   - Recommendation: Plan without `filter_modules`; state the amendment and the evidence in the first plan's objective and in the PR description so the maintainer can veto. Add the hermetic guard that packaged docs never mention `Mix.Tasks.Verify`.

2. **Should PR CI build `:dev` docs?**
   - What we know: `:dev` docs have no PR-time coverage today; `hex.publish` builds them only at release time and does not pass `--warnings-as-errors`. A `:dev`-only warning would need an explicit reference to a Verify module in a packaged doc, which today does not exist (zero hits for `Mix.Tasks.Verify` in README, CONTRIBUTING, ARCHITECTURE, guides, docs).
   - Recommendation: do not add a dev-build CI step (lean gates; about 16 s extra dev compile). Use the hermetic doc-reference guard plus one recorded manual `MIX_ENV=dev mix docs --warnings-as-errors` run in the plan's acceptance evidence.

3. **Where does the D-17 boundary guard live?**
   - Recommendation: a `describe "tooling boundary"` in `test/release/package_contents_test.exs`, so it rides the same `verify.phase11` entry as the gate (the D-12 list needs no extra file).

4. **D-14's 34/14 vs grep's 32/13 (F3).**
   - Recommendation: acceptance by grep, not by count.

5. **Test-env compile of the unpacked archive (D-10 "both envs").**
   - What we know: `prod` is hermetic with `MIX_DEPS_PATH=<repo deps>`, a copied `mix.lock` and isolated `MIX_BUILD_PATH` (5 s). `test` needs the dep builds: copying `_build/test/lib/*` except `scrypath` into the isolated build path made it a 1 s compile. Both need the repo's `deps/` and `_build/test` to exist, which is true in every lane that runs `package_contents_test` (`mix deps.get` and a test-env compile have already happened).
   - Recommendation: implement both as one extra test in `package_contents_test.exs` using `Mix.Project.deps_path()` and `Mix.Project.build_path()`; skip the `test`-env variant only if flaky, since L2 already proves the realistic `prod` path and the tiny-project matrix proves the "missing path tolerated" semantics.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP (asdf) | everything | yes | 1.17.3-otp-27, 1.18.4-otp-27, 1.19.0-otp-28, 1.19.5-otp-27/28, 1.20.2/1.20.4-otp-29 installed; **no default version is set in the shell** (use `ASDF_ELIXIR_VERSION`/`ASDF_ERLANG_VERSION`, for example `1.19.5-otp-28` / `28.1`) | — |
| Hex registry (network) | consumer smoke `deps.get`, `hex.package fetch` | yes (repo.hex.pm returned HTTP 200) | — | `HEX_OFFLINE=1` works for the hermetic archive build only |
| `git` | consumer smoke (tagged artifact), workspace gate | yes | — | — |
| Node.js | `beam_cache.test.cjs` (via `workflow_wiring_test`) | yes | v26.10.0 | — |
| Docker | not needed for this phase (mounted/E2E lanes are separate) | not probed | — | — |
| Local repo deps/build | prototype and tests | `deps/` 23 MB, `_build/test` populated | — | `mix deps.get` |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.x in CI), `node:test` for `scripts/ci/*.test.cjs` |
| Config file | `test/test_helper.exs` (composes excludes, requires `test/support/**/*.ex` after `ExUnit.start()`); `mix.exs` `test_ignore_filters: [&support_file?/1]` keeps support modules out of test discovery; custom `test` alias in `mix.exs` |
| Quick run command | `mix test test/release/package_contents_test.exs test/release/package_metadata_test.exs` (hermetic, a few seconds) |
| Full suite command | `mix test --exclude integration` (about 25 s on the prototype, 1036 tests); gates: `mix verify.package`, `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.repository_contracts` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PKGH-01 | Inventory lives under `dev/mix/tasks`; `lib/mix/tasks/verify*` empty; `dev` not in `files:` | unit (boundary guard) | `mix test test/release/package_contents_test.exs` | Wave 0 (new) |
| PKGH-01 | Unpacked archive holds exactly the 8 public task modules and only allowed top-level entries | integration (real `hex.build`) | `mix test test/release/package_contents_test.exs` | Wave 0 (new) |
| PKGH-01 | Compiled consumer `ebin` has the 8 public tasks and no `Elixir.Mix.Tasks.Verify.*.beam` | integration | `mix test test/release/consumer_smoke_test.exs` | exists, extend |
| PKGH-02 | Every `use Mix.Task` module in `dev/mix/tasks` has a `:test` preferred_env; every `verify*` key resolves | unit | `mix test test/mix/tasks/verify_capability_test.exs` (or the new guard) | Wave 0 (new test) |
| PKGH-02 | Documented focused commands unchanged: `mix test test/mix/tasks/verify_adopter_test.exs`, `mix verify.adopter`, `mix verify.namespace_fence` | existing + smoke | `mix test test/mix/tasks/ test/scrypath/readiness_contract_test.exs` | exists (paths converted via `Scrypath.RepoTooling`) |
| PKGH-02 | Unpacked archive compiles with absent `dev/mix/tasks` (`prod`, `test`, `--warnings-as-errors`) | integration | `mix test test/release/package_contents_test.exs` (compile cases) and the git-dep compile in `consumer_smoke_test.exs` | Wave 0 (new) / exists |
| PKGH-02 | Source-reading contract tests still find the verifier sources | unit | `mix test test/scrypath/docs_contract_test.exs test/scrypath/phase99_contract_test.exs test/mix/tasks/` | exists (helper conversion) |
| PKGH-03 | Injecting `scrypath.repo_only`, `verify.sneaky`, hidden `Mix.Tasks.Verify.Hidden`, `dev` in `files:` fails; deleting `scrypath.status` fails; control passes | integration (mutation) | `mix test test/release/package_contents_test.exs` | Wave 0 (new) |
| PKGH-03 | Public operator tasks usable from an installed package (`mix scrypath.status` usage error, `mix help scrypath.status`) | integration | `mix test test/release/consumer_smoke_test.exs` | exists, extend |
| PKGH-03 | Gate runs in the required lane and is pinned | unit | `mix test test/scrypath/docs_contract_test.exs`; `mix verify.package` | exists (update pin) |
| D-08 | `dev/` edits change every BEAM cache graph key | node unit | `node --test scripts/ci/beam_cache.test.cjs` | exists, extend |
| D-08 | `verify.workspace_clean` pathspecs include `dev`; HYG-02 scans cover `dev/**` | unit | `mix test test/mix/tasks/verify_workspace_clean_test.exs test/mix/tasks/workflow_wiring_test.exs` | exists, extend |

### Sampling Rate
- **Per task commit:** the focused file(s) for the files touched (for example `mix test test/release/package_contents_test.exs`), plus `mix format --check-formatted` and `mix credo --strict` on touched files.
- **Per wave merge:** `mix test --exclude integration` and `mix verify.package` (about 19 s on the prototype; needs network for the consumer smoke).
- **Phase gate:** `mix verify.core --exclude integration --exclude docs_contract`, `mix verify.package`, `mix verify.repository_contracts`, `node --test scripts/ci/beam_cache.test.cjs`, both docs builds (`MIX_ENV=test mix docs --warnings-as-errors` and `MIX_ENV=dev mix docs --warnings-as-errors`), then exact-SHA hosted CI per the repo's closeout flow. No human UAT (AGENTS.md).

### Wave 0 Gaps
- [ ] `test/support/repo_tooling.ex` - `Scrypath.RepoTooling` (covers PKGH-02 path coupling)
- [ ] `test/support/release/package_contract.ex` - `Scrypath.Release.PackageContract` (covers PKGH-01, PKGH-03)
- [ ] `test/release/package_contents_test.exs` - control, five mutations, boundary guard, archive compile cases (PKGH-01..03)
- [ ] `test/mix/tasks/verify_namespace_fence_test.exs` - moved/renamed from `test/mix/tasks/scrypath/namespace_fence_test.exs` (module `Mix.Tasks.Verify.NamespaceFenceTest`, alias `Mix.Tasks.Verify.NamespaceFence`)
- [ ] D-04 guard test (placement: `verify_capability_test.exs` or the new contents test)
- [ ] `scripts/ci/beam_cache.test.cjs` fixture for `dev/`
- No framework install needed.

## Security Domain

`security_enforcement` is not set to `false` in `.planning/config.json`, so this section applies. The phase has no authentication, session or user-input surface; the relevant control is supply-chain hygiene of what the package ships.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | limited | Gate inputs are fixed constants and tmp paths; `hex.build` arguments are constants. No user-supplied strings reach `System.cmd`. |
| V6 Cryptography | no | — |
| V14 Configuration / build and deployment | yes | Fail-closed allowlist of packaged contents; hermetic subprocess env (`HEX_HOME`, `MIX_HOME`, `MIX_BUILD_PATH`); no credentials in the gate (`HEX_API_KEY` stays out of `verify.phase11`, pinned by `docs_contract_test`). |

### Known Threat Patterns for Elixir/Hex packaging

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Maintainer automation shipped to adopters (verifiers run `git`, `mix hex.*`, Docker, `System.cmd`) | Elevation of privilege / Tampering | Keep it out of `files:` and out of `lib/`; allowlist gate fails on any extra `Mix.Tasks.*` module. |
| Task-name collision in a consumer app (`mix verify`, `mix scrypath.namespace_fence` resolve to Scrypath's tasks today) | Spoofing / Tampering | Public namespace is exactly `scrypath.*` operator tasks; verified absent in the compiled consumer. |
| Repo-only files entering the archive (`dev/`, `.planning/`, `scrypath_ops/`) | Information disclosure | L0 top-level allowlist derived from `package files:` plus `hex_metadata.config`. |
| Gate bypass via a path-based check (module defined in an ordinary file) | Tampering | AST scan over all packaged `lib/**/*.ex`, plus the compiled-consumer module list as the ground truth for macro-generated modules. |
| Leaking local state through the test harness (real HEX token, developer `~/.mix`) | Information disclosure | Isolated `HEX_HOME`/`MIX_HOME` in every subprocess (already done in `consumer_smoke_test.exs`). |
| Dynamically generated task modules (`Module.create/3`, `unquote` names) evading the AST scan | Tampering | L2 compiled-consumer check is the backstop; document the limit in the checker's moduledoc. |

## Sources

### Primary (HIGH confidence)
- Repo files read with the Read tool this session: `mix.exs` (whole file), `test/release/consumer_smoke_test.exs`, `test/release/package_metadata_test.exs`, `lib/mix/tasks/verify.phase11.ex:19-46`, `lib/mix/tasks/verify/capability.ex:98-115`, `lib/mix/tasks/verify.workspace_clean.ex:86-108`, `.formatter.exs`, `.credo.exs`, `test/test_helper.exs`, `scripts/ci/beam_cache.cjs:14-39`, `.github/workflows/ci.yml:349-360`, `test/mix/tasks/workflow_wiring_test.exs:1-32`, `test/scrypath/docs_contract_test.exs:14-35`, the first lines of each of the 7 other public task files, `lib/mix/tasks/scrypath.status.ex`, and `183-CONTEXT.md`.
- Prototype runs (scratch copy of the repo, Elixir 1.17.3/1.19.5/1.20.4): compile/docs/format/credo/test/consumer/hex.build/mutation results in "Prototype evidence".
- Published artifacts: `mix hex.package fetch scrypath 0.3.17 --unpack` (60 `Mix.Tasks.*` modules); a Hex consumer of 0.3.17 (`mix help` shows 25 verify/fence entries).

### Secondary (MEDIUM confidence)
- [CITED: https://mix.hexdocs.pm/Mix.Tasks.Deps.html] dependency `:env` defaults to `:prod`.
- [CITED: https://mix.hexdocs.pm/Mix.Project.html] `cli/0` `:preferred_envs` is a keyword list of `{task, env}` tuples (the page does not document `:elixirc_paths`; its behavior here is `[VERIFIED: prototype]`).
- [CITED: 183-CONTEXT.md Canonical References] Phoenix/Oban/Ecto/LiveView env-keyed `elixirc_paths` precedent (not re-fetched this session).

### Tertiary (LOW confidence)
- The confidence seam rated web-fetched documentation `LOW` (`classify-confidence --provider webfetch`, with or without `--verified`); every claim that matters was therefore confirmed by a prototype run instead.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. No new deps; all primitives exercised.
- Architecture: HIGH. The move, env routing, consumer and path-dep behavior, archive compile and the gate were all reproduced.
- Pitfalls: HIGH for F1-F7 and F9 (observed); MEDIUM for F8 and A1 (reasoned, not measured).

**Research date:** 2026-10-27
**Valid until:** 2026-11-26 (stable Mix/Hex behavior; re-verify F1 if ex_doc is bumped, since its warning policy for filtered modules is the cause).
