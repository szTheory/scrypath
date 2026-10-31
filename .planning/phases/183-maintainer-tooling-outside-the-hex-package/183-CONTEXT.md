# Phase 183: Maintainer tooling outside the Hex package - Context

**Gathered:** 2026-10-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Move every repository-only Mix task and verification support module out of the packaged `lib/` tree into an unpackaged `dev/mix/tasks` tree. Contributors keep every documented canonical and historical `mix verify*` command from the source checkout. Hex consumers and path/git-dependency consumers receive only the supported public operator tasks. The existing package gate is extended so that it inspects the real unpacked archive and a compiled consumer, and it fails when maintainer tooling leaks back in. Requirements: PKGH-01, PKGH-02, PKGH-03.

Not in this phase: dependency changes (Phase 184), UI token work (Phase 185), cutting a Hex release, and retiring or merging any historical `verify.phaseNN` command.

</domain>

<decisions>
## Implementation Decisions

The maintainer selected all four gray areas and asked for a research fan-out, with coherent recommendations adopted automatically. Every decision below is the synthesized recommendation from four parallel research passes, cross-checked against the code. Per the delegated-decisions memory, merges and releases still need the maintainer's confirmation.

### Inventory and classification
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

### How `dev/` gets compiled
- **D-05:** Set `elixirc_paths: elixirc_paths(Mix.env())`, with `defp elixirc_paths(:test), do: ["lib", "dev/mix/tasks"]` and `defp elixirc_paths(_), do: ["lib"]`. Add no `File.dir?` guard; research showed Mix tolerates a missing path. Do not add `dev` to `package files:`.
  - Dependencies compile in `:prod`, so Hex, path-dep and git-dep consumers never compile the verifiers. That includes `examples/*` and `scrypath_ops`, which use `path: "../.."`.
  - Phoenix uses the same env-keyed shape (`:docs` env) and so does Oban (`:test`).
  - Rejected: compiling in all envs, which leaks into path/git deps and HexDocs. Also rejected: `Code.require_file`, which `mix.exs` would evaluate in dep contexts too, and a nested Mix project, which breaks root-level commands.
  - **Reversibility:** costly — every documented command depends on `preferred_envs` routing to `:test`.
- **D-06:** Running `MIX_ENV=dev mix verify.x` explicitly will report "task could not be found". That is the accepted, intended behavior. CONTRIBUTING documents it in one sentence: verifier tasks compile only under `MIX_ENV=test`, which `preferred_envs` selects automatically.
- **D-07:** Docs stay consistent across envs. Add ExDoc `filter_modules` that excludes `Mix.Tasks.Verify*` modules, so the local `:test` docs build (`verify`, `verify.phase11`) and the `:dev` `hex.publish` docs build agree. Do not use `@moduledoc false`, which would hide the tasks from `mix help`. HexDocs will intentionally stop listing the Verify modules. The planner/researcher must prove that `MIX_ENV=dev mix docs --warnings-as-errors` and the `:test` docs run are both clean. The risk to check is autolinks in packaged docs such as README, guides and CONTRIBUTING that point at modules or tasks absent in `:dev`.
  - **Amended 2026-10-28 (maintainer-approved):** The original text above is kept for history and no longer governs. The maintainer answered the orchestrator's question prompt directly and approved the research recommendation (183-RESEARCH.md F1, Open Question 1). Leave `docs/0` unchanged, with no `filter_modules`. Add a hermetic guard that packaged docs (every ExDoc extra) and packaged `lib/**/*.ex` never reference `Mix.Tasks.Verify`. Reason: with the filter, `MIX_ENV=test mix docs --warnings-as-errors` fails with about 59 "reference to a filtered module" warnings, which would turn `mix verify`, `verify.core` and `verify.phase11` red. Without it, both docs builds are clean. HexDocs, which `hex.publish` builds in `:dev`, still drops the Verify modules because they are not compiled there. Accepted consequence: local `:test` docs still list the Verify pages, so the local and published module lists differ. The requirement that both builds are clean (`MIX_ENV=dev` and `:test`, `--warnings-as-errors`) still applies. The `@moduledoc false` prohibition also still applies. Implemented in 183-07 Task 1.
- **D-08:** Update these configs, any of which would otherwise silently lose coverage:
  - `.formatter.exs` inputs gain `dev`.
  - `.credo.exs` `included` gains `"dev/"`.
  - The `sourceRoots` of all four graphs in `scripts/ci/beam_cache.cjs` gain `"dev"`, and `beam_cache.test.cjs` gains a fixture proving that a `dev/` edit changes the digest. The single cache-key rotation is expected.
  - The `ops-ui-path` filter regex in `.github/workflows/ci.yml` gains `dev/`.
  - The HYG-02 scans in `workflow_wiring_test.exs` cover `dev/**` as well as `lib/**`.
  - The `verify.workspace_clean` pathspecs gain `dev/`.
  - Optional: a `/dev/` line in `CODEOWNERS`.

### Leak gate (PKGH-03)
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

### Path-coupled tests, docs and history
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/ROADMAP.md` § Phase 183 — goal and the three success criteria.
- `.planning/REQUIREMENTS.md` — PKGH-01, PKGH-02, PKGH-03.
- `.planning/PROJECT.md` § Current Milestone: v1.45 — target feature and the lean-gates / no-manual-UAT posture.
- `.planning/reference/ROLLING-ROADMAP.md` §3 (line 59) — origin of the "move ~44 verify tasks to dev/mix/tasks" item.
- `AGENTS.md` — green-main release-train posture and shift-left executable verification.

### Code touch points
- `mix.exs` — `project/0` (add `elixirc_paths`), `cli/0` `preferred_envs`, `docs/0` (`filter_modules`), `package/0` `files:` (unchanged).
- `lib/mix/tasks/**` — the move inventory in D-01 to D-03.
- `lib/mix/tasks/verify/package.ex`, `lib/mix/tasks/verify/capability.ex`, `lib/mix/tasks/verify.phase11.ex` — the gate's entry path.
- `lib/mix/tasks/verify.release_parity.ex`, `lib/mix/tasks/verify.workspace_clean.ex` — interplay (D-08, D-13).
- `test/release/consumer_smoke_test.exs`, `test/release/package_metadata_test.exs` — consumer probe and metadata guard.
- `test/scrypath/docs_contract_test.exs`, `test/scrypath/phase99_contract_test.exs`, `test/scrypath/readiness_contract_test.exs`, `test/mix/tasks/*` — path-coupled and wording-coupled contracts.
- `test/test_helper.exs` — `test/support/**` require order.
- `.formatter.exs`, `.credo.exs`, `scripts/ci/beam_cache.cjs`, `scripts/ci/beam_cache.test.cjs`, `.github/workflows/ci.yml` (around line 359), `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml`.
- `guides/operator-mix-tasks.md` — the public-task documentation that `@public_tasks` must match.
- `CONTRIBUTING.md`, `docs/releasing.md`, `README.md`, `guides/support-and-compatibility.md`, `guides/outside-adopter-intake.md`.

### Practices
- `prompts/elixir-opensource-libs-best-practices-deep-research.md`, `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`.
- Mix deps compile in `:prod` by default: https://hexdocs.pm/mix/Mix.Tasks.Deps.html.
- Prior art: the env-keyed `elixirc_paths` in the `mix.exs` files of Phoenix, Oban, Ecto and LiveView.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/release/consumer_smoke_test.exs` already builds the archive with `hex.build --unpack` and compiles a consumer from it. L2 extends this test rather than building a new consumer.
- `verify.no_optional_deps` already compiles the library under `MIX_ENV=prod` in an isolated `MIX_BUILD_PATH`. That is free proof that `lib/` compiles alone.
- `verify.phase10` and `verify.phase11` already use `hex.build --unpack`.
- `test_helper.exs` requires `test/support/**/*.ex` before the tests compile, so both new support modules load in time.

### Established Patterns
- A pure `compute/2` or `classify/2` plus a thin `run/1` that halts, so exit semantics are unit-testable (`verify.release_parity`).
- The canonical capability chain: `verify.package` → `Capability.run(:package)` → `Phase11.run_without_docs/0` → `run_test!` list.
- Contract tests pin task source text and documented strings, so wording changes need matching pin updates.

### Integration Points
- The required `package` job in `ci.yml`, plus the pre-publish runs in `release-please.yml` and `publish-hex.yml`.
- The Phase 182 BEAM cache (`beam_cache.cjs` `sourceRoots`). Missing `dev` there means stale beams in CI.
- `examples/scrypath_ecommerce` and `examples/phoenix_meilisearch` (`path: "../.."`) and `scrypath_ops`. They must keep compiling with no Verify beams.

</code_context>

<specifics>
## Specific Ideas

- Measured during research: the 0.3.17 archive holds 61 `Mix.Tasks.*` modules. 8 are public, 52 are `verify*`, and 1 is `scrypath.namespace_fence`. On the pre-move tree the allowlist reports about 53 violations, which is the built-in mutant.
- On Elixir 1.17.3/OTP 27 and 1.19.5/OTP 28, `elixirc_paths(:test)` with `dev/` absent compiles cleanly with `--warnings-as-errors`, and path/git-dep consumers get no Verify beams.
- Maintainer preference: no new dependencies; prefer a small copy over adding a dependency.

</specifics>

<deferred>
## Deferred Ideas

- A `--contents` flag on `verify.release_parity`, to run the contents allowlist against published versions from the first post-move release onward. This is a follow-up and not needed for PKGH-03.
- Cutting a Hex release that ships the cleaned package. That is release work, separate from this phase, and needs the maintainer's confirmation.

</deferred>

---

*Phase: 183-maintainer-tooling-outside-the-hex-package*
*Context gathered: 2026-10-27*
