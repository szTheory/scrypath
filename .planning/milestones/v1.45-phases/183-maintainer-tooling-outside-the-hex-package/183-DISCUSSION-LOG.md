# Phase 183: Maintainer tooling outside the Hex package - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-27
**Phase:** 183-maintainer-tooling-outside-the-hex-package
**Areas discussed:** Inventory edge cases, How dev/ gets compiled, Leak-gate shape, Path-coupled tests & docs

**Mode:** advisor (calibration `minimal_decisive`). The maintainer selected all four areas and asked for a deep research fan-out across all relevant lenses, with coherent one-shot recommendations followed automatically ("find set of recommendations that are coherent auto follow those"). They also stated a preference for copy-paste over new dependencies. Four parallel `gsd-advisor-researcher` passes ran, one per area. The orchestrator then reconciled the passes where they disagreed.

---

## Inventory edge cases

| Option | Description | Selected |
|--------|-------------|----------|
| A. Namespace as the classifier, no manifest; rename `scrypath.namespace_fence` to `verify.namespace_fence` | `scrypath.*` ships, `verify*` never ships; the gate holds an 8-entry allowlist | ✓ |
| B. Move as-is with an explicit classification manifest; keep the fence's name | The manifest duplicates the directory and needs a special-case exemption | |

**User's choice:** delegated; the recommendation was auto-followed.
**Notes:** Full classified inventory: 53 files move; nothing under `lib/scrypath/**` is verify-only. `verify.adopter` and `verify.meilisearch_smoke` are maintainer-only, but the shipped README and guides mention them, so those mentions keep their exact strings and gain a "source checkout" qualifier.

## How dev/ gets compiled

| Option | Description | Selected |
|--------|-------------|----------|
| A. Env-keyed `elixirc_paths`, adding `dev/mix/tasks` only for `:test` | Deps compile in `:prod`, so Hex, path and git consumers stay clean; same pattern as Phoenix and Oban | ✓ |
| B. Same paths in every env, guarded by `File.dir?` | Leaks into path/git-dep builds and HexDocs | |

**User's choice:** delegated; the recommendation was auto-followed.
**Notes:** Verified experimentally on Elixir 1.17 and 1.19. The researchers disagreed on `["lib","dev"]` versus `["lib","dev/mix/tasks"]`; the orchestrator chose the narrower `dev/mix/tasks`. They also disagreed on whether to use ExDoc `filter_modules`; the orchestrator chose it, so the `:test` and `:dev` docs builds agree.

## Leak-gate shape

| Option | Description | Selected |
|--------|-------------|----------|
| A. Allowlist manifest checked against the unpacked archive (L0 entries, L1 AST scan) and a compiled consumer (L2), plus mutation tests, inside `verify.package` | Fails closed and proves the public tasks are retained | ✓ |
| B. Denylist pattern (`verify.*`, `Mix.Tasks.Verify.*`, `dev/`) | Fails open; would miss `scrypath.namespace_fence` today | |

**User's choice:** delegated; the recommendation was auto-followed.
**Notes:** One researcher proposed landing the gate red before the move. The orchestrator replaced that with an all-green commit sequence: the pre-move violation count is recorded as evidence and the mutation tests serve as the negative proof. This keeps the repo's green-main posture.

## Path-coupled tests & docs

| Option | Description | Selected |
|--------|-------------|----------|
| C. Shared test-support helper (`Scrypath.RepoTooling`) used at all 34 sites | One place names the tooling root; allows a staged, green move | ✓ |
| A. Rewrite the literals in place | Simple, but couples the move to every test edit | |
| B. Resolve the source via `module_info(:compile)[:source]` | Absolute paths go stale across worktrees, Docker and caches | |

**User's choice:** delegated; the recommendation was auto-followed.
**Notes:** Tests stay in `test/mix/tasks/`. The move is a pure `git mv`. Archived `.planning/` evidence is not rewritten. The researchers disagreed on whether `verify.workspace_clean` should cover `dev/`; the orchestrator chose to add it. The commit type is `fix(package):`, so the change appears in the changelog that release-please generates.

## Claude's Discretion

- Helper and checker names, and the wording of failure messages.
- Whether to add an optional `Mix.Task.get/1` assertion.
- The CODEOWNERS line.
- Which L2 operator smoke path to use.

## Deferred Ideas

- A `--contents` flag on `verify.release_parity` for post-move releases.
- A Hex release that ships the cleaned package (needs the maintainer's confirmation).
