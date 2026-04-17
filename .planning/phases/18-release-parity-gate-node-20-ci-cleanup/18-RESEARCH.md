# Phase 18: Release-Parity Gate + Node 20 CI Cleanup - Research

**Researched:** 2026-04-17
**Domain:** Elixir OSS release-pipeline integrity + GitHub Actions runtime hygiene
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**workspace_clean Mix task:**

- **D-01:** `mix verify.workspace_clean` derives its pathspecs from `mix.exs` `files:` list + `test/**`. At Phase 18 scope that resolves to: `lib/**`, `.formatter.exs`, `mix.exs`, `README.md`, `ARCHITECTURE.md`, `CHANGELOG.md`, `guides/**`, `docs/**`, `test/**`. Self-maintaining — adding a new packaged path to `files:` automatically extends the gate.
- **D-02:** Implementation uses `System.cmd("git", ["status", "--porcelain", "--"] ++ pathspecs, stderr_to_stdout: true)`. Empty stdout + exit 0 = clean. Non-empty output = `Mix.raise/1` with the offending paths and next-step copy (`git add`, `git stash -u`, `git checkout --`). Pattern mirrors the prior art in `expublish`'s `Expublish.Git.validate/1`.
- **D-03:** No HEAD-behind-origin/main check. `release_parity` catches post-publish tarball drift; layering a network-requiring `git fetch` inside a Mix verify task adds friction without closing a drift class that isn't already covered.
- **D-04:** No escape-hatch flag or env var. v1.2 proved emergency bypasses become routine (see the `cargo publish --allow-dirty` anti-pattern — rust-lang/cargo#9398). If a true emergency requires a dirty publish, the maintainer comments out the workflow step in a PR; the friction is the feature.
- **D-05:** `test/**` is included despite test files not shipping in the tarball — uncommitted tests mean "the lib/ state being published was not tested as it will ship," which maps directly to Scrypath's operational-honesty posture.

**release_parity Mix task:**

- **D-06:** `mix verify.release_parity X.Y.Z` acquires the Hex side via `System.cmd("mix", ["hex.package", "fetch", "scrypath", version, "--unpack", "-o", tmp_dir], stderr_to_stdout: true)` — the canonical Hex CLI handles auth-free download, checksum verify, and unpack in one step. No new HTTP client code; no `Req` dep reach; parallel pattern to existing `verify.phase11`'s shell-out idiom.
- **D-07:** Git side uses `git ls-tree -r --name-only scrypath-vX.Y.Z -- lib/ guides/ docs/`. No checkout needed, respects the actual tagged tree, fast.
- **D-08:** Comparison depth is path-set equality via `MapSet.difference/2` on `lib/ + guides/ + docs/` only (INFRA-02 literal scope). SHA-256 hash comparison is deliberately deferred.
- **D-09:** Scope stays restricted to `lib/ + guides/ + docs/` even though `mix.exs` `files:` is broader.
- **D-10:** Exit codes: `0` = parity, `2` = drift (POSIX "intentional failure"), `1` = runtime error (network failure, missing tag, tarball fetch failure). CI treats any non-zero as failure; humans and downstream automation can distinguish drift from infra hiccups.
- **D-11:** Output is human-readable by default with a machine-readable `--json` flag. Human output shows BOTH directions of the diff plus a file count summary on success. JSON shape: `{"version": "X.Y.Z", "status": "ok" | "drift", "only_in_git": [...], "only_in_hex": [...]}`.
- **D-12:** CDN propagation race: inherit `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` / `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` env-var retry pattern from `verify.release_publish` so daily runs don't false-fail on freshly-cut releases.

**Node 20 CI cleanup (INFRA-03):**

- **D-13:** Only `.github/workflows/ci.yml` needs edits. `actions/checkout@v4` → `actions/checkout@v6`, `actions/cache@v4` → `actions/cache@v5` across all jobs. No other workflow changes — `publish-hex.yml`, `release-please.yml`, `verify-published-release.yml` already run on `@v6`.

**Workflow wiring (INFRA-01 + INFRA-04):**

- **D-14:** Symmetric gate coverage across BOTH publish paths. INFRA-01's literal "`publish-hex.yml`" phrasing is treated as paperwork-era scope.
- **D-15:** `ci.yml`'s `quality` job gets a new `workspace_clean` step, positioned after `mix format --check-formatted` and before `mix credo`.
- **D-16:** `release-please.yml`'s `publish-hex` job gets a new `workspace_clean` step, positioned immediately after tag checkout and before `mix verify.phase11`.
- **D-17:** `publish-hex.yml` (manual recovery) gets the same `workspace_clean` step at the same position as the canonical path.
- **D-18:** `verify-published-release.yml` is EXTENDED — not forked — with a new `mix verify.release_parity "${{ steps.resolve-version.outputs.version }}"` step running after the existing `mix verify.release_publish` step in the same job.
- **D-19:** Daily-cron drift surfacing: default GitHub workflow-failure email to maintainer, plus `JasonEtco/create-an-issue@v2` with a deduplicating title like `"Release parity drift detected: scrypath X.Y.Z"`. Auto-file ONLY on `event_name == 'schedule'` + drift exit code 2; manual `workflow_dispatch` runs stay silent beyond the red check.
- **D-20:** No new workflow files. Four existing workflows get one step each.

**Known-divergence transition (0.3.0 → 0.4.0):**

- **D-21:** No bootstrap allowlist, no `MIN_VERSION` env var, no hardcoded skip list for 0.3.0. `mix verify.release_parity 0.3.0` passes today with exit 0 and no special-casing.
- **D-22:** Phase 18 closes with a `feat(18): add release-parity gates + Node 20 CI cleanup` Conventional Commit on `main`. Release-please opens a release PR; merging promotes `mix.exs` `@version` `0.3.0 → 0.4.0`.
- **D-23:** `docs/releasing.md` gets a new "Release parity gate" section. Documentation lives in the published surface (HexDocs-visible).
- **D-24:** `CHANGELOG.md` unreleased entry names both new Mix tasks and carries one `### Notes` bullet pointing to `.planning/milestones/v1.2-MILESTONE-AUDIT.md` for traceability.

### Claude's Discretion

- Exact Mix.raise/1 copy phrasing (D-02) — match existing Scrypath error-message tone from `lib/scrypath/options.ex` precedent.
- Tmp-dir naming for `hex.package fetch --unpack` output (D-06) — use `System.tmp_dir!/0` + unique suffix + `File.rm_rf!/1` cleanup.
- JSON field ordering in `--json` output (D-11) — stable ordering, fields as named above.
- `create-an-issue` labels/assignees (D-19) — add `area:release`, `severity:drift`, assign to repo maintainers.
- Test-file layout for the new tasks — `test/mix/tasks/verify_workspace_clean_test.exs`, `test/mix/tasks/verify_release_parity_test.exs`.

### Deferred Ideas (OUT OF SCOPE)

- **SHA-256 hash comparison for release_parity (belt-and-suspenders mode)** — defer to a future phase.
- **Emergency-publish escape hatch for workspace_clean** (`SCRYPATH_WORKSPACE_CLEAN_SKIP=1`) — deliberately rejected per D-04.
- **Extracting a shared `Mix.Tasks.Verify.Helpers` module** — defer until a third `verify.*` task lands needing the same shell-out helper.
- **Per-phase SUMMARY manifest convention for release_parity** — not adopted; path-list diff against `git ls-tree` at tag supersedes the need.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INFRA-01 | `mix verify.workspace_clean` fails if the working tree contains any untracked file matching `lib/**`, `test/**`, `guides/**`, or `docs/**` OR any tracked file with uncommitted modifications in those paths. Integrated into `publish-hex.yml` before `mix hex.publish`. | D-01/D-02 pathspec derivation (self-maintaining from `mix.exs` `package.files`); `git status --porcelain --` porcelain-v1 output contract verified (§`Code Examples` pattern 1); positioning inside `quality` job + `publish-hex` + `release-please`'s `publish-hex` job wired per D-14/D-15/D-16/D-17. |
| INFRA-02 | `mix verify.release_parity X.Y.Z` compares the published Hex `X.Y.Z` tarball's `lib/` + `guides/` + `docs/` file list against the current git tag of the same version; exits non-zero on divergence. Integrated into `verify-published-release.yml`. | D-06 `mix hex.package fetch --unpack -o DIR` primitive (auth-free, verified); D-07 `git ls-tree -r --name-only <tag> -- paths`; D-08 path-set diff via `MapSet.difference/2`; D-10 exit-code discipline (0/1/2); D-12 retry pattern inherited from `verify.release_publish`. |
| INFRA-03 | `.github/workflows/ci.yml` uses `actions/checkout@v6` and `actions/cache@v5` (clears Node 20 deprecation before the 2026-09 removal). No other workflow edits required. | D-13 scope already validated against live workflow files (see §`Architecture Patterns` → workflow inventory table); verified against GitHub's 2025-09-19 deprecation changelog + Node 24 migration deadline "June 2nd, 2026 default" / "fall of 2026 full migration." |
| INFRA-04 | CI runs `mix verify.workspace_clean` on every push AND `mix verify.release_parity` as a scheduled daily job against the latest published Hex version. | `ci.yml` covers per-push via `quality` job D-15; `verify-published-release.yml` covers scheduled daily via D-18 (extends existing `schedule: cron: "17 6 * * *"`); drift-surfacing via D-19 `create-an-issue@v2` with `if: failure() && github.event_name == 'schedule'`. |
</phase_requirements>

## Summary

Phase 18 ships two new Mix tasks (`Mix.Tasks.Verify.WorkspaceClean`, `Mix.Tasks.Verify.ReleaseParity`), wires them into four existing workflows with one step each, and swaps five action-pin references in `ci.yml` from `@v4` to `@v6/@v5` to clear the Node 20 deprecation ahead of GitHub's September 2026 removal. Every architectural decision (workspace-clean pathspec derivation, release-parity diff depth, exit-code discipline, CDN-retry inheritance, no-escape-hatch stance) is locked in CONTEXT.md D-01..D-24. This research focuses on **implementation-level** knowledge: exact command syntaxes, error paths, test fixture strategy, YAML wiring shape, and pitfalls the planner would otherwise hit at execution time.

The two new Mix tasks follow the established `lib/mix/tasks/verify.*.ex` architecture: `use Mix.Task`, `@shortdoc`, `@moduledoc`, `@impl true def run(args)` that calls `Mix.Task.run("app.start")`, argument validation helper, shell-out via `System.cmd(..., stderr_to_stdout: true)`, `Mix.shell().info/1` for progress, `Mix.raise/1` on failure. Direct prior art: `verify.phase11.ex` for argument-guarded multi-step verification, `verify.release_publish.ex` for the retry-with-env-var loop and `unique_tmp_dir!/0` + `File.rm_rf/1` cleanup idiom.

The highest implementation risk is **CDN propagation latency** on freshly-cut releases — `mix hex.package fetch X.Y.Z` may 404 for several minutes after a publish while the tarball replicates. Inheriting `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` (default 10, set to 20 in publish-hex workflows) + `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` (default 15_000) from `verify.release_publish` is the mitigation; runtime fetch failures surface as exit code 1, while post-fetch path-diff divergence surfaces as exit code 2.

**Primary recommendation:** Build both Mix tasks in parallel in a single plan (they share no code but share a testing strategy, shell-out idiom, and workflow-wiring surface); land the four workflow edits in a second plan; land the `docs/releasing.md` + `CHANGELOG.md` copy in a third plan; close with a single `feat(18):` commit that triggers release-please to cut 0.4.0, auto-healing the v1.2 divergence.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Workspace-clean gate | Mix task (build-time CLI) | CI workflow step | Runs in developer + CI shell before any tarball is built; no runtime library surface |
| Release-parity comparison | Mix task (CLI) | CI workflow step | Shells out to `git` + `mix hex.package`; no library code path |
| Hex tarball fetch | External (hex.pm CDN → `mix hex.package`) | Mix task shell-out | Auth-free canonical primitive; no Scrypath-owned HTTP code |
| Git tree introspection | External (local/runner git) | Mix task shell-out | `git ls-tree` against tag ref; requires tag to exist locally (CI checkout fetches tags) |
| CI action pin currency | GitHub Actions runtime | YAML workflow file | `.github/workflows/ci.yml` edits only; other workflows already `@v6` |
| Daily drift surfacing | Scheduled workflow + issue-creation action | External GH API via `JasonEtco/create-an-issue@v2` | Title-based dedup prevents issue spam across daily runs |
| Closing-cycle release cut | Release-please action | Merged `feat(18):` commit | Default versioning strategy (pre-1.0) bumps minor on `feat:` → 0.3.0 → 0.4.0 |

## Standard Stack

### Core (already in project, no changes)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir Mix | ~> 1.17 | Task framework for `mix verify.*` | Project convention; `verify.phase*` tasks established since Phase 5 |
| `System.cmd/3` | stdlib | Shell out to `git`, `mix hex.package` | Used throughout existing verify tasks; no alternative warranted |
| `File` / `Path` / `System.tmp_dir!/0` | stdlib | Tmp-dir management for tarball unpack | Pattern proven in `verify.release_publish.ex:202-210` |
| `MapSet` | stdlib | Path-set diff for release parity | `MapSet.difference/2` handles both diff directions in one call |
| Jason ~> 1.4 | pinned in `mix.exs:58` | `--json` output serialization (D-11) | Already a direct dependency; no new deps |
| ExUnit | stdlib | Test framework for new Mix-task tests | `test/scrypath/mix_tasks/operator_tasks_test.exs` is the precedent |
| `ExUnit.CaptureIO` | stdlib | Capture `Mix.shell().info/1` output in tests | Used in existing operator_tasks_test.exs:3,105,117,153,230 |

### GitHub Actions (pin changes in `ci.yml` only)

| Action | Current Pin | Target Pin | Status | Verified |
|--------|-------------|------------|--------|----------|
| `actions/checkout` | `@v4` (ci.yml) | `@v6` | Node 24 runtime | [VERIFIED: GitHub Changelog 2025-09-19 + v6 release notes] |
| `actions/cache` | `@v4` (ci.yml) | `@v5` | Node 24 runtime; requires runner >= 2.327.1 | [VERIFIED: v5 release notes; GitHub-hosted runners satisfy this automatically] |
| `erlef/setup-beam` | `@v1` (all workflows) | `@v1` (no change) | Already Node 24-ready | [VERIFIED: CONTEXT.md D-13 + v1.24+ changelog] |
| `googleapis/release-please-action` | `@v4` (release-please.yml:33) | `@v4` (no change) | Already Node 24-compatible | [VERIFIED: D-13] |
| `JasonEtco/create-an-issue` | NEW | `@v2` | For daily drift issue filing | [VERIFIED: README; `update_existing: true` + `search_existing: open` dedup semantics confirmed] |

### Hex CLI primitives (the `mix hex.package fetch` contract)

| Subcommand | Signature | Behavior | Verified |
|------------|-----------|----------|----------|
| `mix hex.package fetch PACKAGE VERSION --unpack -o DIR` | Positional + flags | Downloads + verifies checksum + unpacks into `DIR` in one step | [CITED: hexdocs.pm/hex/Mix.Tasks.Hex.Package.html] |
| Authentication | None for public packages | `scrypath` is public; no `HEX_API_KEY` needed for fetch | [CITED: hex CLI is auth-free for public-package downloads; `publish-hex.yml` scopes `HEX_API_KEY` only to publish job] |
| Exit code (missing version) | Raises via `Hex.Shell.error/1` → Mix.Error → non-zero exit | Treat as exit code 1 (runtime error, not drift) | [VERIFIED: hex source — `fetch_tarball!` raises on download failure] |
| Exit code (checksum failure) | Raises `"Checksum mismatch against registry (inner/outer)"` → non-zero | Treat as exit code 1 | [VERIFIED: hex source `lib/mix/tasks/hex.package.ex`] |
| Unpacked layout | `DIR/lib/...`, `DIR/guides/...`, `DIR/docs/...`, `DIR/hex_metadata.config`, `DIR/mix.exs`, `DIR/README.md`, `DIR/CHANGELOG.md`, `DIR/ARCHITECTURE.md`, `DIR/.formatter.exs` | Top-level files + directories match `mix.exs` `package.files` + `hex_metadata.config` | [VERIFIED via `mix.exs:106` + hex docs; `hex_metadata.config` appears at TOP LEVEL of unpacked dir] |

**Installation:** No new Elixir deps. `JasonEtco/create-an-issue@v2` is a GitHub Action, not a dep.

**Version verification commands** (run during Plan 01 before finalizing pins):

```bash
# GitHub Actions pin currency
curl -sI https://github.com/actions/checkout/releases/tag/v6 | head -1
curl -sI https://github.com/actions/cache/releases/tag/v5 | head -1
curl -sI https://github.com/JasonEtco/create-an-issue/releases/tag/v2 | head -1

# Hex CLI behavior (sanity-check against live Hex)
mix hex.package fetch scrypath 0.3.0 --unpack -o /tmp/parity-smoke
ls /tmp/parity-smoke/  # expect: lib/ guides/ docs/ mix.exs README.md ... hex_metadata.config
```

### Alternatives Considered

| Instead of | Could Use | Why Standard Wins |
|------------|-----------|-------------------|
| `mix hex.package fetch --unpack` | Direct `Req.get!` against hex.pm/packages URL + `:erl_tar` | D-06: adds HTTP + untar code for zero gain; hex CLI handles checksum verify |
| `git ls-tree -r --name-only TAG -- paths` | `git archive TAG \| tar tf -` | D-07: requires piping, slower, same output set |
| `git status --porcelain -- pathspecs` | `git diff-index --quiet HEAD -- pathspecs` | D-02: porcelain covers untracked files (`??`); `diff-index` only covers tracked modifications |
| `JasonEtco/create-an-issue@v2` | `peter-evans/create-issue-from-file@v5` | D-19: `create-an-issue` has native title-based dedup via `update_existing`; alternative requires manual issue-search logic |
| SHA-256 hash comparison | Path-set equality | D-08: path-only matches v1.2 incident class and is upgradeable in ~20 LOC later |

## Architecture Patterns

### System Architecture Diagram

```
┌──────────────────────────┐           ┌─────────────────────────┐
│  Developer shell or      │           │  GitHub Actions runner  │
│  CI `quality` job        │           │  (ci.yml / publish-hex  │
│                          │           │   / release-please.yml) │
└────────────┬─────────────┘           └────────────┬────────────┘
             │                                      │
             ▼                                      ▼
   ┌─────────────────────────────────────────────────────────────┐
   │ mix verify.workspace_clean                                  │
   │                                                             │
   │   1. derive pathspecs from mix.exs package.files + test/**  │
   │   2. System.cmd("git",                                      │
   │        ["status","--porcelain","--"] ++ pathspecs)          │
   │   3. empty stdout  → :ok                                    │
   │      non-empty     → Mix.raise with offending paths         │
   └─────────────────────────────────────────────────────────────┘
                   │                              │
                   │ exit 0 (clean)               │ exit 1 (dirty)
                   ▼                              ▼
        ┌──────────────────────┐       ┌──────────────────────┐
        │ Next workflow step   │       │ Workflow FAILS.      │
        │ proceeds.            │       │ Publish BLOCKED.     │
        └──────────────────────┘       └──────────────────────┘


┌──────────────────────────┐           ┌─────────────────────────┐
│  Scheduled daily cron    │           │  Manual workflow_dispatch│
│  (verify-published-      │           │  (same workflow)         │
│   release.yml @ 06:17 UTC│           │                          │
└────────────┬─────────────┘           └────────────┬────────────┘
             │                                      │
             ▼                                      ▼
   ┌─────────────────────────────────────────────────────────────┐
   │ resolve-version step: curl hex.pm API → LATEST_VERSION      │
   │   (handles 404-before-first-publish gracefully)             │
   └─────────────────────────────────────────────────────────────┘
                              │
                              ▼
   ┌─────────────────────────────────────────────────────────────┐
   │ mix verify.release_publish LATEST_VERSION                   │
   │   (existing step, unchanged)                                │
   └─────────────────────────────────────────────────────────────┘
                              │
                              ▼
   ┌─────────────────────────────────────────────────────────────┐
   │ mix verify.release_parity LATEST_VERSION    (NEW — D-18)    │
   │                                                             │
   │  retry loop (SCRYPATH_RELEASE_VERIFY_ATTEMPTS / _SLEEP_MS): │
   │   1. System.cmd("mix", ["hex.package","fetch","scrypath",   │
   │        ver,"--unpack","-o",tmp_dir])                        │
   │   2. System.cmd("git", ["ls-tree","-r","--name-only",       │
   │        "scrypath-v"<>ver,"--","lib/","guides/","docs/"])    │
   │   3. Build MapSets: hex_paths, git_paths                    │
   │      (trim tmp_dir prefix from hex side)                    │
   │   4. only_in_git = MapSet.difference(git, hex)              │
   │      only_in_hex = MapSet.difference(hex, git)              │
   │   5. both empty   → :ok (exit 0)                            │
   │      non-empty    → human or JSON output, exit 2 (drift)    │
   │      fetch failed → exit 1 (runtime)                        │
   │                                                             │
   │  cleanup: File.rm_rf!(tmp_dir) in try/after                 │
   └─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼────────────────┐
              │               │                │
        exit 0│         exit 1│          exit 2│
              ▼               ▼                ▼
      ┌───────────┐   ┌───────────────┐  ┌──────────────────────────┐
      │ green ✓   │   │ red ✗         │  │ red ✗                    │
      │           │   │ (infra issue) │  │ + if scheduled run:      │
      │           │   │               │  │   JasonEtco/create-an-   │
      │           │   │               │  │   issue@v2 files/updates │
      │           │   │               │  │   dedup'd drift issue    │
      └───────────┘   └───────────────┘  └──────────────────────────┘
```

### Recommended Project Structure (additions only)

```
lib/mix/tasks/
├── verify.workspace_clean.ex    # NEW — D-01/D-02/D-14-17 gate
└── verify.release_parity.ex     # NEW — D-06..D-12 post-publish diff

test/mix/tasks/
├── verify_workspace_clean_test.exs    # NEW — pathspec derivation, clean/dirty, error message
└── verify_release_parity_test.exs     # NEW — path-set diff, exit 0/1/2, --json shape, CDN retry

.github/workflows/
├── ci.yml                       # EDITED — 5 pin swaps (@v4 → @v6/@v5) + 1 new workspace_clean step in quality
├── release-please.yml           # EDITED — 1 new workspace_clean step in publish-hex job
├── publish-hex.yml              # EDITED — 1 new workspace_clean step
└── verify-published-release.yml # EDITED — 1 new release_parity step + 1 new create-an-issue step

docs/
└── releasing.md                 # EDITED — new "Release parity gate" section (D-23)

CHANGELOG.md                     # EDITED — new Unreleased entry (D-24)

mix.exs                          # EDITED — 2 new entries in cli.preferred_envs
```

### Pattern 1: Mix Verify Task Skeleton (from `verify.phase11.ex`)

```elixir
# Source: /Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex
defmodule Mix.Tasks.Verify.WorkspaceClean do
  use Mix.Task

  @shortdoc "Fails if the working tree has uncommitted changes in packaged paths"

  @moduledoc """
  Verifies that `git status` is clean for all pathspecs that ship in the Hex
  tarball plus `test/**`.

  Runs as the first step of every publish path (canonical release-please flow,
  manual-recovery workflow, and per-push CI) so a release cannot ship files
  that were not reviewed and merged.
  """

  @impl true
  def run(args) do
    Mix.Task.run("app.start")
    ensure_no_args!(args)

    pathspecs = build_pathspecs()
    Mix.shell().info("==> Checking workspace cleanliness for #{length(pathspecs)} pathspecs")

    {output, exit_status} =
      System.cmd("git", ["status", "--porcelain", "--" | pathspecs],
        stderr_to_stdout: true
      )

    case {output, exit_status} do
      {"", 0} -> :ok
      {dirty_output, 0} -> raise_dirty!(dirty_output)
      {err, _nonzero} -> Mix.raise("git status failed:\n\n#{err}")
    end
  end

  defp build_pathspecs do
    # Source of truth: mix.exs package.files (D-01)
    project = Mix.Project.config()
    Keyword.get(project[:package] || [], :files, [])
    |> Enum.map(&pathspec_for/1)
    |> Kernel.++(["test"])  # D-05
  end

  defp pathspec_for(path) when is_binary(path), do: path

  defp raise_dirty!(output) do
    Mix.raise("""
    Workspace is not clean. Uncommitted or untracked files exist in packaged paths:

    #{output}
    Resolve with:
      git add <path>       # stage
      git stash -u         # shelve
      git checkout -- <path>  # discard

    This gate exists because v1.2 shipped a partial tarball when uncommitted
    files did not travel to the release tag. See .planning/milestones/v1.2-MILESTONE-AUDIT.md.
    """)
  end

  defp ensure_no_args!([]), do: :ok
  defp ensure_no_args!(args),
    do: Mix.raise("verify.workspace_clean does not accept arguments, got: #{Enum.join(args, " ")}")
end
```

### Pattern 2: Retry-with-env-var Loop (from `verify.release_publish.ex`)

```elixir
# Source: /Users/jon/projects/scrypath/lib/mix/tasks/verify.release_publish.ex:58-75
# Inherit verbatim into verify.release_parity.ex per D-12.
@default_attempts 10
@default_sleep_ms 15_000

defp retry_until!(label, attempts, sleep_ms, fun) do
  Enum.reduce_while(1..attempts, nil, fn attempt, _acc ->
    Mix.shell().info("==> #{label} (attempt #{attempt}/#{attempts})")

    case fun.() do
      :ok -> {:halt, :ok}
      {:error, reason} when attempt < attempts ->
        Mix.shell().info(reason)
        Process.sleep(sleep_ms)
        {:cont, nil}
      {:error, reason} ->
        Mix.raise("#{label} failed after #{attempts} attempts\n\n#{reason}")
    end
  end)
end

defp env_integer(name, default) do
  case System.get_env(name) do
    nil -> default
    value ->
      case Integer.parse(value) do
        {parsed, ""} when parsed > 0 -> parsed
        _ -> Mix.raise("#{name} must be a positive integer, got: #{inspect(value)}")
      end
  end
end
```

### Pattern 3: Tmp-Dir Safety (from `verify.release_publish.ex:202-210`)

```elixir
# Source: /Users/jon/projects/scrypath/lib/mix/tasks/verify.release_publish.ex:202-210
defp unique_tmp_dir! do
  path =
    Path.join(
      System.tmp_dir!(),
      "scrypath-release-parity-#{System.unique_integer([:positive])}"
    )
  File.mkdir_p!(path)
  path
end

# Usage (rephrased from verify.release_publish.ex:92-119):
tmp_root = unique_tmp_dir!()
try do
  # ... fetch, unpack, diff ...
after
  File.rm_rf(tmp_root)
end
```

**Why `File.rm_rf/1` not `File.rm_rf!/1`** in the `after` block: the bang version would mask the original exception if cleanup fails. Non-bang version logs and continues. This idiom is copy-paste from `verify.release_publish.ex:118`.

### Pattern 4: Drift Exit Code Discipline (D-10)

```elixir
# release_parity custom exit codes — pattern NOT in verify.phase11 (which uses Mix.raise → exit 1)
# To emit exit 2 specifically for drift, bypass Mix.raise:

defp emit_drift_and_halt!(only_in_git, only_in_hex, version, opts) do
  output =
    if opts[:json] do
      Jason.encode!(%{
        "version" => version,
        "status" => "drift",
        "only_in_git" => Enum.sort(only_in_git),
        "only_in_hex" => Enum.sort(only_in_hex)
      })
    else
      human_diff(only_in_git, only_in_hex, version)
    end

  Mix.shell().info(output)
  System.halt(2)   # explicit exit 2 per D-10 (POSIX "intentional failure")
end

# Runtime errors still use Mix.raise → exit 1 (default Mix behavior)
```

**Note:** `Mix.raise/1` exits with `{:shutdown, 1}` (non-zero but not 2). For the drift-specific exit code 2 per D-10, use `System.halt(2)` after emitting the drift output. Test it via `:os.cmd/1` in the test (see `Testing Strategy` below).

### Pattern 5: Workflow Step Wiring (YAML)

```yaml
# ci.yml quality job (D-15) — insert between "Check formatting" and "Run Credo"
      - name: Check formatting
        run: mix format --check-formatted

      - name: Verify workspace is clean
        run: mix verify.workspace_clean

      - name: Run Credo
        run: mix credo

# release-please.yml publish-hex job (D-16) — insert between checkout and deps.get
      - uses: actions/checkout@v6
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}

      - name: Verify workspace is clean
        run: mix verify.workspace_clean

      - uses: erlef/setup-beam@v1
        # ... existing

# publish-hex.yml (D-17) — same position as canonical path
      - uses: actions/checkout@v6
        with:
          ref: ${{ inputs.tag }}

      - name: Verify workspace is clean
        run: mix verify.workspace_clean

      - uses: erlef/setup-beam@v1

# verify-published-release.yml (D-18, D-19) — extend existing job
      - name: Verify the latest published Scrypath release
        if: ${{ steps.resolve-version.outputs.published == 'true' }}
        env:
          SCRYPATH_RELEASE_VERIFY_ATTEMPTS: "10"
          SCRYPATH_RELEASE_VERIFY_SLEEP_MS: "15000"
        run: mix verify.release_publish "${{ steps.resolve-version.outputs.version }}"

      - name: Verify release-parity against latest published version
        if: ${{ steps.resolve-version.outputs.published == 'true' }}
        env:
          SCRYPATH_RELEASE_VERIFY_ATTEMPTS: "10"
          SCRYPATH_RELEASE_VERIFY_SLEEP_MS: "15000"
        run: mix verify.release_parity "${{ steps.resolve-version.outputs.version }}"

      # D-19: drift-surfacing step — guarded on failure() + scheduled event
      - name: Open drift issue (scheduled runs only)
        if: ${{ failure() && github.event_name == 'schedule' && steps.resolve-version.outputs.published == 'true' }}
        uses: JasonEtco/create-an-issue@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          VERSION: ${{ steps.resolve-version.outputs.version }}
        with:
          update_existing: true
          search_existing: open
          filename: .github/ISSUE_TEMPLATE/release-parity-drift.md
```

**Note on `if: failure()`:** `failure()` must be explicit — any `if:` expression that lacks a status function implicitly defaults to `success()`, which would suppress the step on the prior step's failure. Confirmed from GitHub Actions docs.

### Pattern 6: Issue Template File (new file: `.github/ISSUE_TEMPLATE/release-parity-drift.md`)

```markdown
---
title: "Release parity drift detected: scrypath {{ env.VERSION }}"
labels: ["area:release", "severity:drift"]
assignees: szTheory
---

`mix verify.release_parity {{ env.VERSION }}` detected a divergence between
the published Hex tarball and the git tag of the same version.

- Workflow run: {{ env.GITHUB_SERVER_URL }}/{{ env.GITHUB_REPOSITORY }}/actions/runs/{{ env.GITHUB_RUN_ID }}
- Version: {{ env.VERSION }}

Expand the workflow logs for the exact `only_in_git` and `only_in_hex` file lists.

See `.planning/milestones/v1.2-MILESTONE-AUDIT.md` for background on why this gate exists.
```

Title uses environment-variable interpolation per create-an-issue docs. `update_existing: true` + `search_existing: open` means: second scheduled run on the same drift updates the existing open issue rather than opening a duplicate.

### Anti-Patterns to Avoid

- **Don't use `git status --porcelain=v2`**: v1 output is simpler to parse and CONTEXT.md D-02 specifies `--porcelain` (which means v1). v2 adds fields the task doesn't need (file modes, object IDs).
- **Don't use `git diff-index --quiet HEAD`** in place of `git status --porcelain`: `diff-index` does not report untracked files, but untracked files under `lib/`, `test/`, `guides/`, `docs/` are precisely the v1.2 failure class.
- **Don't shell out to `curl`/`wget` to fetch the Hex tarball**: `mix hex.package fetch --unpack` is the canonical primitive, handles CDN redirects + checksum verification in one step.
- **Don't include `lib`, `guides`, `docs` as raw atoms in pathspecs**: `package.files` entries are strings. Pass them through as-is; pathspec expansion is git's job.
- **Don't wrap `System.cmd` args in shell quoting**: `System.cmd/3` does NOT invoke a shell, so spaces/globs in args are not re-interpreted. Pass pathspecs as a plain list.
- **Don't `Mix.raise/1` for drift**: `Mix.raise/1` always exits 1, which conflates drift (exit 2) with runtime failure (exit 1). Use `System.halt(2)` for drift per D-10.
- **Don't file a new issue every daily run on persistent drift**: must use `update_existing: true` on create-an-issue@v2 — otherwise N scheduled runs file N issues.
- **Don't set `search_existing: all`** on the create-an-issue step: that would re-open CLOSED drift issues with identical titles, which is noisier than filing a fresh one. `open` (default) is correct.
- **Don't add `docs/releasing.md` updates to a separate commit from the code changes**: the gate's existence and the docs that explain it should land together so HexDocs-at-0.4.0 ships with accurate maintainer docs.
- **Don't forget the `cli.preferred_envs` entries**: without them, `mix verify.workspace_clean` and `mix verify.release_parity` will compile under the default `:dev` env and diverge from the CI environment used by the existing verify tasks.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hex tarball download + checksum verify | Custom `Req.get!` + `:erl_tar.extract/2` + manual SHA-256 verify | `mix hex.package fetch PACKAGE VER --unpack -o DIR` | Auth-free; handles registry checksum (inner AND outer); retries CDN failures once internally; emits structured error output |
| Git tree listing at tagged ref | Custom `git archive TAG \| tar tf -` piping | `git ls-tree -r --name-only TAG -- paths` | No subshell pipe; pathspec filtering native to git; no tar dependency on runner |
| Workspace-clean detection | Custom recursive `File.ls/1` + commit-SHA comparison | `git status --porcelain -- pathspecs` | Handles untracked, modified, renamed, deleted, submodule, ignored in one call |
| Duplicate-issue avoidance | Custom `gh api` search-then-create logic | `JasonEtco/create-an-issue@v2` with `update_existing: true` | Native title-match dedup; no custom search pagination code |
| Path-set diff | Manual `Enum.reject` nested loops | `MapSet.difference/2` called twice (both directions) | O(n) set operations; stable result; named clearly in output |
| Issue template content | Inline markdown in the workflow YAML | Separate `.github/ISSUE_TEMPLATE/release-parity-drift.md` with frontmatter | Create-an-issue's canonical shape; separates template authoring from workflow logic |
| Version bump for 0.3.0 → 0.4.0 | Manual edit of `mix.exs` `@version` + `.release-please-manifest.json` | `feat(18):` conventional commit → release-please PR → merge | D-22; release-please handles both files atomically |
| Exit code 2 convention | Custom signal handling or stderr parsing | `System.halt(2)` direct from Mix task | POSIX "intentional failure" code; standard across grep, diff, check-manifest, cargo |

**Key insight:** Every primitive Phase 18 needs already exists as a tested, auth-free, single-command primitive. The task boundaries are "compose existing primitives and format the result" — not "build a new abstraction."

## Runtime State Inventory

> Phase 18 is a build-time + CI + Mix-task phase. No runtime state is stored, cached, or externally registered.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — Phase 18 introduces no database, cache, datastore, or persistent file written by the tasks themselves (tmp dirs are deleted in `after` blocks). | None |
| Live service config | None — Hex tarball is fetched fresh each run; git state is queried read-only; no external service configuration is written. | None |
| OS-registered state | None — no systemd/launchd/Task Scheduler registration. GitHub Actions `schedule:` cron is already registered; Phase 18 extends it with one step, no new cron entry. | None |
| Secrets/env vars | `SCRYPATH_RELEASE_VERIFY_ATTEMPTS`, `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` — INHERITED from `verify.release_publish`, same names, same behavior. Code reads them via `env_integer/2`; no change to variable names. | None — existing workflows already set these in env blocks; `verify.release_parity` just reads the same vars. |
| Build artifacts | None persistent. `tmp_dir` created by `unique_tmp_dir!/0` is scoped via `System.unique_integer` and cleaned up in `try/after File.rm_rf(tmp_dir)`. Hex fetch downloads into that tmp dir only. | None — cleanup is in the Mix-task code itself. |

**The canonical question:** *After every file in the repo is updated, what runtime systems still have the old string cached, stored, or registered?*

**Answer: Nothing.** Phase 18 is read-only against repo state + hex.pm CDN + GitHub API. The only writes are ephemeral tmp dirs and (on scheduled drift) a deduplicated GitHub issue.

## Common Pitfalls

### Pitfall 1: CDN propagation race on freshly-published versions
**What goes wrong:** `mix hex.package fetch scrypath 0.4.0 --unpack -o DIR` returns non-zero for 2-15 minutes after `mix hex.publish` because the tarball is still propagating through hex.pm's CDN.
**Why it happens:** hex.pm fronts tarball downloads via Fastly CDN with staged rollout. The `mix hex.info` API is visible earlier than the binary tarball.
**How to avoid:** Inherit the retry pattern verbatim from `verify.release_publish.ex:58-75`. Set `SCRYPATH_RELEASE_VERIFY_ATTEMPTS=20` + `SCRYPATH_RELEASE_VERIFY_SLEEP_MS=15000` in publish-hex workflows (same as `verify.release_publish` does today).
**Warning signs:** Flaky CI on the first daily run after a merge that cuts a release; same run passing on re-run 10 minutes later.
**Specific guidance for testing:** In the unit test for `verify.release_parity`, stub the fetch function to return `{:error, reason}` once then `:ok` on second attempt; assert retry loop halts after first `:ok`. Property: retry count never exceeds configured attempts.

### Pitfall 2: `git status --porcelain --` with pathspec quoting through System.cmd
**What goes wrong:** Developer writes `System.cmd("git", ["status", "--porcelain", "--", "lib/**"])` expecting shell-glob expansion, gets zero matches even when `lib/scrypath/foo.ex` is dirty.
**Why it happens:** `System.cmd/3` does NOT spawn a shell — it calls `execvp(2)` directly. Git treats `lib/**` as a literal pathspec, and git's pathspec syntax treats bare globs as limited (`lib/**` only matches files starting literally with `lib/**`). Git's pathspec wildcards use `**` only when `--pathspec-from-file` or specific magic is set.
**How to avoid:** Pass directory pathspecs WITHOUT trailing globs. `"lib"` (not `"lib/**"`) tells git "recursively match everything under lib/". This is exactly how `package.files` is structured: `~w(lib .formatter.exs mix.exs README.md ARCHITECTURE.md CHANGELOG.md guides docs)` — bare names, no globs.
**Warning signs:** Tests pass on clean repo but miss obviously dirty files in staging.
**Specific guidance:** Pathspecs passed to git via `System.cmd/3` should match the exact strings from `mix.exs package.files` + `"test"`. No extra suffix. No shell quoting.

### Pitfall 3: Tmp-dir collision between concurrent test runs
**What goes wrong:** Two CI jobs running in parallel (e.g., `quality` + `phase13-verification`) both invoke the parity task (if a future wiring did this), both pick the same tmp dir path, collide.
**Why it happens:** `System.tmp_dir!/0` returns the same root (`/tmp` on Linux). Naive naming like `Path.join(System.tmp_dir!(), "scrypath-parity")` creates collision.
**How to avoid:** Follow `verify.release_publish.ex:202-210` exactly: `"scrypath-release-parity-#{System.unique_integer([:positive])}"`. `System.unique_integer([:positive])` guarantees monotonic uniqueness within a BEAM VM; across BEAMs, the two-level uniqueness (VM boot time + incrementing counter) makes collision virtually impossible.
**Warning signs:** Intermittent CI failures on "tmp dir already exists" or `File.mkdir_p!` races.

### Pitfall 4: `File.rm_rf!/1` in `after` block masking original exception
**What goes wrong:** Task raises a genuine error (e.g., git tag missing), `after File.rm_rf!(tmp_dir)` also raises because the dir was never created (fetch failed before mkdir), and the bang-version crashes with a masking `File.Error`. User sees wrong error.
**Why it happens:** `File.rm_rf!/1` raises on failure; `File.rm_rf/1` returns `{:ok, files}` or `{:error, reason, file}` and never raises.
**How to avoid:** Use `File.rm_rf/1` (no bang) in cleanup blocks. This matches `verify.release_publish.ex:118`: `after: File.rm_rf(tmp_root)`.
**Warning signs:** Test failures that report "tmp dir not found" when the real error was upstream.

### Pitfall 5: `mix hex.package fetch` returning exit 0 with empty directory
**What goes wrong:** A network hiccup returns HTTP 200 with empty body; hex CLI unpacks zero files; diff reports "everything in git tag is missing from hex" (massive false positive drift).
**Why it happens:** Rare but documented; typically requires upstream proxy issues. Retry loop handles transient; one-shot unpack-no-files is possible.
**How to avoid:** After `mix hex.package fetch`, sanity-check that tmp_dir contains a non-zero number of expected files (at minimum `mix.exs` at the top level — always present in published Hex packages). If missing, treat as retryable runtime error (exit 1, not exit 2).
**Warning signs:** Drift issues filed listing every lib/ file as "only in git"; user re-runs and it passes.

### Pitfall 6: Trimming the tmp-dir prefix from Hex-side paths
**What goes wrong:** `git ls-tree` emits `lib/scrypath.ex` (repo-root-relative) but after `mix hex.package fetch --unpack -o /tmp/foo/` the hex side paths exist at `/tmp/foo/lib/scrypath.ex`. Naive diff compares absolute vs relative paths, finds 100% drift.
**Why it happens:** `Path.wildcard/1` and `File.ls/1` return paths under the argument dir.
**How to avoid:** After enumerating files under `tmp_dir`, trim the prefix via `Path.relative_to/2`:
```elixir
hex_paths =
  Path.wildcard(Path.join(tmp_dir, "{lib,guides,docs}/**/*"))
  |> Enum.filter(&File.regular?/1)
  |> Enum.map(&Path.relative_to(&1, tmp_dir))
  |> MapSet.new()
```
Then `git_paths` (output of `git ls-tree -r --name-only TAG -- lib/ guides/ docs/`) is already repo-root-relative.
**Warning signs:** First test run of release_parity reports every file as divergent.

### Pitfall 7: Missing git tag emits exit code 128, not the expected "tag ls-tree empty"
**What goes wrong:** `mix verify.release_parity 9.9.9` against a nonexistent tag fails with `fatal: Not a valid object name: 'scrypath-v9.9.9'` on stderr and exit 128 from git. Naive handling treats this as drift.
**Why it happens:** Git returns exit 128 for unknown-ref errors, not exit 1. Porcelain format doesn't apply to ls-tree.
**How to avoid:** Branch on git exit status in the Mix task:
- exit 0 → parse output normally
- exit != 0 → `Mix.raise/1` with the stderr content → exits with 1 (runtime error per D-10)
Never attempt to parse output when git exit is non-zero.
**Warning signs:** Daily cron passes green on `0.3.0` but red with "drift" on a typoed version; investigate → find missing tag.

### Pitfall 8: Drift message truncation when output is very long
**What goes wrong:** 10+ file drift produces a long error message; GitHub Actions log line limit or terminal truncation obscures the tail.
**Why it happens:** `Mix.shell().info/1` writes to stdout; no intrinsic truncation, but CI UIs may collapse.
**How to avoid:** Human-readable output format should show a summary header first:
```
Release parity drift detected for scrypath 0.3.0:
  12 files only in git tag (missing from Hex tarball)
  0 files only in Hex tarball (not in git tag)

Only in git tag (missing from Hex tarball):
  lib/scrypath/faceting.ex
  ...
```
Summary comes first; tail contains full lists. Reviewer can click "expand" to see full content.
**Warning signs:** User reports "drift detected but I can't see what's different."

### Pitfall 9: Running `mix hex.package fetch` without Hex installed on runner
**What goes wrong:** Clean GitHub Actions runner (e.g., after `erlef/setup-beam` but before `mix local.hex --force`) lacks Hex.
**Why it happens:** Elixir ships `Mix` without Hex. Hex is a separate archive installed via `mix local.hex --force`.
**How to avoid:** `verify.release_parity` workflow steps must run AFTER `mix local.hex --force` + `mix deps.get` (which transitively installs Hex). `verify-published-release.yml` already has this at lines 63-65. No new wiring needed — just confirm step ordering.
**Warning signs:** CI error: `** (Mix) The task "hex.package" could not be found`.

### Pitfall 10: `cli.preferred_envs` omission causing compile-time env mismatch
**What goes wrong:** `mix verify.workspace_clean` run locally defaults to `:dev` env; CI `quality` job runs it after a `mix test` step (which set `MIX_ENV=test`), producing inconsistent warning outputs.
**Why it happens:** Without a `cli.preferred_envs` entry, Mix task env defaults to Mix.env() at task start time.
**How to avoid:** Add both tasks to `mix.exs` `cli.preferred_envs`:
```elixir
def cli do
  [
    preferred_envs: [
      "verify.phase5": :test,
      # ... existing entries ...
      "verify.release_publish": :test,
      "verify.workspace_clean": :test,   # NEW
      "verify.release_parity": :test     # NEW
    ]
  ]
end
```
**Warning signs:** Tests pass locally but CI emits warnings about compile-time config differences.

### Pitfall 11: `System.halt(2)` in a test runs the exit-code path but kills the test runner
**What goes wrong:** Unit test for drift calls the task function directly; `System.halt(2)` halts the BEAM, all other tests fail to run.
**Why it happens:** `System.halt/1` is unconditional — it exits the VM.
**How to avoid:** Structure the task with an injectable halt function OR test the exit code via subprocess:
```elixir
# Option A: Extract the core logic to a function that returns {:ok, :parity} | {:drift, ...} | {:error, ...}
# then the `run/1` top-level calls System.halt only for the drift case.
# Unit tests call the core logic function.

# Option B: Use System.cmd in the test to invoke mix verify.release_parity in a subprocess.
test "exits 2 on drift" do
  {_output, exit_status} = System.cmd("mix", ["verify.release_parity", "0.3.0"], cd: tmp_fixture_dir)
  assert exit_status == 2
end
```
Option A is the Elixir idiom; Option B is slower but more realistic. Mix both: unit-test the core logic (A); integration-test the exit code via subprocess in a tagged `@tag :integration` test (B).

### Pitfall 12: Release-please pre-1.0 default bumping
**What goes wrong:** Maintainer expects `feat(18):` on 0.3.0 to cut `0.4.0`, but release-please config has `bump-minor-pre-major` set (it doesn't — confirmed) or `bump-patch-for-minor-pre-major` set (also doesn't) — which WOULD downgrade the bump to `0.3.1`.
**Why it happens:** These options flip the default versioning strategy for pre-1.0 projects.
**How to avoid (already handled):** Confirmed `release-please-config.json` does NOT set either option. Default strategy stands: `feat:` → minor bump → `0.3.0 → 0.4.0`. D-22 is accurate.
**Verification for planner:** Before finalizing the Phase 18 closing commit, run `git log --oneline v0.3.0..HEAD | grep -c '^[a-f0-9]* feat'` — this will show release-please what to expect. Also preview by running Release Please locally via `npx release-please release-pr --dry-run --repo-url https://github.com/szTheory/scrypath --token $GITHUB_TOKEN` if there's doubt.

## Code Examples

Verified patterns from official sources.

### Deriving pathspecs from `mix.exs` package.files

```elixir
# Source: /Users/jon/projects/scrypath/mix.exs:106 (D-01 derivation)
project_config = Mix.Project.config()
package_files = get_in(project_config, [:package, :files]) || []
# package_files = ~w(lib .formatter.exs mix.exs README.md ARCHITECTURE.md CHANGELOG.md guides docs)
pathspecs = package_files ++ ["test"]  # D-05
# => ["lib", ".formatter.exs", "mix.exs", "README.md", "ARCHITECTURE.md",
#     "CHANGELOG.md", "guides", "docs", "test"]
```

### Porcelain v1 output parsing

```elixir
# Source: [CITED: git-scm.com/docs/git-status Porcelain Format v1]
# Format: XY<space>PATH  (3 chars + path, newline terminated)
# XY codes used by this task:
#   "??" = untracked
#   " M" / "M " / "MM" = modified
#   " A" / "A " = added (staged)
#   " D" / "D " = deleted
#   " R" / "R " = renamed
#   Any non-space in either column = attention needed

# Parsing is just "is output non-empty?" — we don't need to distinguish codes.
# But for a friendly error message, split and show paths:
defp parse_dirty(output) do
  output
  |> String.split("\n", trim: true)
  |> Enum.map(fn line ->
    # line is "XY<space>PATH" — drop first 3 chars
    String.slice(line, 3..-1//1)
  end)
end
```

### `git ls-tree` at tagged ref

```bash
# Source: [CITED: git-scm.com/docs/git-ls-tree]
git ls-tree -r --name-only scrypath-v0.3.0 -- lib/ guides/ docs/
# Output example:
#   lib/scrypath.ex
#   lib/scrypath/backend.ex
#   ...
#   guides/getting-started.md
#   ...
# Exit 0 on success; exit 128 on unknown ref; exit 128 on path error.
```

```elixir
# Invocation:
{output, exit_status} =
  System.cmd("git",
    ["ls-tree", "-r", "--name-only", "scrypath-v#{version}", "--", "lib/", "guides/", "docs/"],
    stderr_to_stdout: true
  )

case exit_status do
  0 ->
    git_paths = output |> String.split("\n", trim: true) |> MapSet.new()
    {:ok, git_paths}
  _ ->
    {:error, "git ls-tree failed for tag scrypath-v#{version}:\n\n#{output}"}
end
```

### `mix hex.package fetch --unpack` invocation

```elixir
# Source: [CITED: hexdocs.pm/hex/Mix.Tasks.Hex.Package.html]
tmp_dir = unique_tmp_dir!()

{output, exit_status} =
  System.cmd("mix",
    ["hex.package", "fetch", "scrypath", version, "--unpack", "-o", tmp_dir],
    stderr_to_stdout: true
  )

case exit_status do
  0 ->
    # Sanity-check — per Pitfall 5
    unless File.exists?(Path.join(tmp_dir, "mix.exs")) do
      {:error, "hex.package fetch succeeded but tmp_dir lacks mix.exs — empty tarball?"}
    else
      enumerate_hex_paths(tmp_dir)
    end
  _ ->
    {:error, "mix hex.package fetch failed:\n\n#{output}"}
end
```

### Path-set diff

```elixir
# Source: stdlib MapSet
only_in_git = MapSet.difference(git_paths, hex_paths) |> MapSet.to_list() |> Enum.sort()
only_in_hex = MapSet.difference(hex_paths, git_paths) |> MapSet.to_list() |> Enum.sort()

case {only_in_git, only_in_hex} do
  {[], []} -> :parity
  {og, oh} -> {:drift, og, oh}
end
```

### JSON output shape (D-11)

```elixir
# When --json flag is set:
Jason.encode!(%{
  "version" => version,
  "status" => status,  # "ok" | "drift"
  "only_in_git" => only_in_git,
  "only_in_hex" => only_in_hex
}, pretty: false)
```

### CONTEXT.md-specified Pathspec list construction

```elixir
# Actual verified content of mix.exs package.files at HEAD:
# files: ~w(lib .formatter.exs mix.exs README.md ARCHITECTURE.md CHANGELOG.md guides docs)
#
# At Phase 18 scope, D-01 pathspecs are:
[
  "lib",
  ".formatter.exs",
  "mix.exs",
  "README.md",
  "ARCHITECTURE.md",
  "CHANGELOG.md",
  "guides",
  "docs",
  "test"
]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `actions/checkout@v4` (Node 20) | `actions/checkout@v6` (Node 24) | 2025-09-19 deprecation notice; default switch Jun 2 2026; full removal fall 2026 | Node 20 runtime will be removed from runners |
| `actions/cache@v4` (Node 20) | `actions/cache@v5` (Node 24) | 2025-09-19 deprecation notice | Cache backend service v2 rewritten; requires runner 2.327.1+ (GitHub-hosted runners satisfy) |
| Manual `curl + tar` for Hex tarballs | `mix hex.package fetch --unpack` | Hex CLI `hex.package` subcommand added 2019 (issue #632) | One command handles checksum + unpack; auth-free for public packages |
| `cargo publish --allow-dirty`-style bypass | No bypass (D-04) | Post-rust-lang/cargo#9398 (2021 sensitive-file leak incident) | Friction is the feature; emergencies comment out the workflow step in a reviewed PR |

**Deprecated/outdated:**
- Node 20 on GitHub Actions: Deprecated 2025-09-19. Node 24 default: June 2, 2026. Full Node 20 removal: fall 2026.
- `git status --short` parsing: Use `--porcelain` (v1) for stable script-consumable output.

## Assumptions Log

All claims in this research were verified against official sources or documented as derivation from CONTEXT.md locked decisions. Items marked `[ASSUMED]` below need user confirmation only if the planner wants to challenge them.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mix hex.package fetch --unpack` places `hex_metadata.config` at the TOP LEVEL of the output dir (not inside a `scrypath-X.Y.Z/` subdirectory when `-o DIR` is provided) | Pattern 5 / Standard Stack "Unpacked layout" | If wrong, path enumeration needs one extra directory layer; cosmetic fix |
| A2 | GitHub Actions runner `ubuntu-latest` has runner version >= 2.327.1 in April 2026 (required by `actions/cache@v5`) | Standard Stack → GitHub Actions pins | If wrong, cache step fails; unlikely — GH auto-updates runners |
| A3 | `git ls-tree` emits one path per line with no padding, trailing whitespace, or surprising quoting under `--name-only` for ASCII-path repos | Code Examples → ls-tree | Scrypath repo has zero non-ASCII paths; risk is 0 today |
| A4 | Release-please-action@v4 with the current `release-please-config.json` (no `bump-minor-pre-major` / `bump-patch-for-minor-pre-major` set) will bump `0.3.0 → 0.4.0` on a `feat(18):` commit | D-22 implementation expectation | Medium risk — verified default behavior via GitHub docs and release-please source, but not yet empirically validated on this repo. Mitigation: preview via `release-please release-pr --dry-run` if planner wants certainty. |
| A5 | `JasonEtco/create-an-issue@v2` does NOT re-open a CLOSED drift issue when `search_existing: open` (default) — it files a fresh one | Anti-Patterns → search_existing | If wrong, drift issue history is muddier; still functional |

**Items NOT in this table (i.e., VERIFIED):** `git status --porcelain` output format (CITED), `mix hex.package fetch` flags (CITED), action pin currency (VERIFIED via release notes), retry pattern idiom (VERIFIED via `verify.release_publish.ex`), `create-an-issue@v2` `update_existing` semantics (CITED via README), `if: failure() && github.event_name == 'schedule'` syntax (CITED via GitHub Actions docs).

## Open Questions

1. **Should `verify.release_parity` in the scheduled daily job also rebuild the local `mix deps.get` before shelling out to `mix hex.package`?**
   - What we know: `verify-published-release.yml:71-73` already runs `mix deps.get` before `mix verify.release_publish`. That step is needed because the verify task shells `mix hex.info` which requires Hex to be installed. `mix hex.package` has the same requirement.
   - What's unclear: Whether the existing `mix deps.get` also installs Hex archive. It does (transitively, if not already present).
   - Recommendation: Keep the workflow step ordering exactly as in verify-published-release.yml today; no new wiring needed. Just add the new `mix verify.release_parity` step after `mix verify.release_publish`.

2. **Does the workspace_clean gate need a special-case for `.github/` edits?**
   - What we know: `.github/workflows/*.yml` is NOT in `mix.exs package.files`, so CONTEXT.md D-01 does NOT include it in pathspecs.
   - What's unclear: Whether workspace_clean should also check that `.github/` has no uncommitted changes.
   - Recommendation: NO — D-01 is clear that the pathspec list is derived from `package.files` + `test/**`. Adding `.github/` would overreach. Workflow-file drift is caught by the fact that publish-hex checks out the tag (a clean checkout) rather than HEAD, and by the fact that release-please requires workflow changes to be merged into `main` before they take effect.

3. **Should the drift GitHub issue template live in `.github/ISSUE_TEMPLATE/` or a Phase-18-specific directory?**
   - What we know: `.github/ISSUE_TEMPLATE/` is the GitHub convention; repos expect templates there.
   - What's unclear: Whether the template should be a user-facing issue template (shown in the "new issue" picker) or a bot-only template (hidden).
   - Recommendation: Place at `.github/ISSUE_TEMPLATE/release-parity-drift.md` with a reasonable-looking frontmatter. The `config.yml`-level "blank_issues_enabled" isn't touched. Users who land there manually can ignore it; the `name:` field makes it clear it's bot-only.

4. **Is there value in a `--fixtures` or `--captured-baseline` mode on `verify.release_parity` for testing without hitting hex.pm?**
   - What we know: The task shells out to `mix hex.package fetch` directly. A test that runs the actual Mix task without mocking WILL hit the network.
   - What's unclear: Whether the test strategy is "unit-test the core logic with mocked fetch + mocked git output" (preferred) or "hit the network and treat as integration test."
   - Recommendation: Structure the task with an injectable "fetch function" and "git function" (higher-order) so unit tests pass stubs; add a single integration test tagged `@tag :integration` that runs against hex 0.3.0 (known-good) and passes exit 0. This matches the `SCRYPATH_INTEGRATION` pattern already used in `test/test_helper.exs:1`.

5. **What is the minimum test count for Nyquist Dimension 8 "cross-workflow contract" coverage?**
   - What we know: Nyquist (workflow.nyquist_validation: true) requires validation across dimensions.
   - Recommendation: See Validation Architecture section below for specific dimension mapping.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `git` CLI | workspace_clean, release_parity | ✓ (any runner / developer machine) | >= 2.0 (porcelain v1 stable since 2010) | — |
| `mix` (Elixir) | release_parity shell-out to `hex.package` | ✓ (already required for existing tasks) | ~> 1.17 | — |
| Hex archive | release_parity `mix hex.package` invocation | ✓ in CI after `mix local.hex --force`; ✓ for devs who have run any `mix deps.get` | any | — |
| hex.pm CDN reachable | release_parity fetch | ✓ in CI + local dev | — | Retry loop handles transient; ATTEMPTS env var tunable |
| GitHub API + `GITHUB_TOKEN` | daily drift issue filing | ✓ in GH Actions | — | If API is down, step fails red; no silent skip |
| Network access from runner | hex.pm fetch, GH API | ✓ (GH Actions runners) | — | — |

**Missing dependencies with no fallback:** None — all required dependencies already exist in the target environments (local dev machines that run `mix` + GitHub Actions runners).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib) — project convention |
| Config file | `test/test_helper.exs` (excludes `:integration` tag unless `SCRYPATH_INTEGRATION` env is set) |
| Quick run command | `mix test test/mix/tasks/` |
| Full suite command | `mix test --exclude integration` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INFRA-01 | pathspec derivation from `mix.exs package.files` + `test` | unit | `mix test test/mix/tasks/verify_workspace_clean_test.exs -x` | ❌ Wave 0 |
| INFRA-01 | clean tree → exit 0, dirty tree → Mix.raise with offending paths | unit | same file, `test "raises on dirty tree"` | ❌ Wave 0 |
| INFRA-01 | workspace_clean step present in ci.yml quality job | unit (YAML grep) | `grep -nF 'mix verify.workspace_clean' .github/workflows/ci.yml` | ❌ Wave 0 |
| INFRA-01 | workspace_clean step present in publish-hex.yml | unit (YAML grep) | `grep -nF 'mix verify.workspace_clean' .github/workflows/publish-hex.yml` | ❌ Wave 0 |
| INFRA-01 | workspace_clean step present in release-please.yml publish-hex job | unit (YAML grep) | `grep -nF 'mix verify.workspace_clean' .github/workflows/release-please.yml` | ❌ Wave 0 |
| INFRA-02 | parity against 0.3.0 git tag exits 0 (D-21 canary) | integration (hits Hex) | `mix verify.release_parity 0.3.0` (tagged `@tag :integration`) | ❌ Wave 0 |
| INFRA-02 | path-set diff logic with stubbed fetch + stubbed git output | unit | `mix test test/mix/tasks/verify_release_parity_test.exs::test "detects drift"` | ❌ Wave 0 |
| INFRA-02 | exit code 2 on drift, 1 on runtime error, 0 on parity | unit + subprocess | subprocess test via `System.cmd` | ❌ Wave 0 |
| INFRA-02 | `--json` output matches documented shape | unit | `assert Jason.decode!(output) == %{"version" => ..., "status" => "drift", ...}` | ❌ Wave 0 |
| INFRA-02 | CDN retry: first `:error` then `:ok` halts retry loop | unit | stub fetch to fail once then succeed | ❌ Wave 0 |
| INFRA-02 | release_parity step present in verify-published-release.yml | unit (YAML grep) | `grep -nF 'mix verify.release_parity' .github/workflows/verify-published-release.yml` | ❌ Wave 0 |
| INFRA-03 | `actions/checkout@v6` in ci.yml (all jobs) | unit (YAML grep) | `grep -c 'actions/checkout@v6' .github/workflows/ci.yml` expected ≥ 4 | ❌ Wave 0 |
| INFRA-03 | `actions/cache@v5` in ci.yml (all jobs) | unit (YAML grep) | `grep -c 'actions/cache@v5' .github/workflows/ci.yml` expected ≥ 4 | ❌ Wave 0 |
| INFRA-03 | no remaining `@v4` refs in ci.yml | unit (YAML grep) | `grep -E 'actions/(checkout\|cache)@v4' .github/workflows/ci.yml` expected empty | ❌ Wave 0 |
| INFRA-04 | scheduled cron run wires release_parity | unit (YAML grep) | confirm `schedule:` + `cron:` + release_parity step co-exist in verify-published-release.yml | ❌ Wave 0 |
| INFRA-04 | create-an-issue step guarded on `failure() && github.event_name == 'schedule'` | unit (YAML grep) | `grep -nF "failure() && github.event_name == 'schedule'"` | ❌ Wave 0 |
| INFRA-04 | `update_existing: true` in create-an-issue step | unit (YAML grep) | `grep -nF 'update_existing: true'` | ❌ Wave 0 |
| INFRA-01..04 | new tasks listed in mix.exs cli.preferred_envs | unit | `Scrypath.MixProject.cli()[:preferred_envs]` assertion | ❌ Wave 0 |

### Nyquist Dimension 8 Coverage (minimum test counts per dimension)

| Dimension | Coverage | Minimum Tests |
|-----------|----------|---------------|
| 1. Task-level unit (each Mix task in isolation, mocked dependencies) | 8 tests: pathspec derivation, clean/dirty, error formatting (workspace_clean); path-diff logic, JSON shape, exit-code branches, retry, tmp-dir cleanup (release_parity) | 8 |
| 2. Workflow-level integration (each workflow YAML parseable + referenced task runs) | 4 tests: ci.yml parses, release-please.yml parses, publish-hex.yml parses, verify-published-release.yml parses; each has required step present | 4 |
| 3. Cross-workflow contract (workspace_clean gate appears in all 3 publish paths per D-14) | 3 tests: grep presence in ci.yml quality job, release-please.yml publish-hex job, publish-hex.yml | 3 |
| 4. Post-publish monitoring (daily cron actually fires + issue dedup works) | 2 tests: manual `workflow_dispatch` run triggers release_parity against 0.3.0 (passes by D-21); dry-run create-an-issue via subprocess | 2 (1 automated + 1 manual-verification at phase close) |
| 5. Subprocess integration (actually invoking `mix verify.release_parity 0.3.0` against live Hex) | 1 integration test tagged `@tag :integration`, runs only with `SCRYPATH_INTEGRATION=1` | 1 |

**Total: 18 tests minimum.** All are automatable except the manual dry-run of `workflow_dispatch` at phase close (one-time verification, not a repeat regression test).

### Sampling Rate

- **Per task commit:** `mix test test/mix/tasks/ --exclude integration` (runs in < 5s)
- **Per wave merge:** `mix test --exclude integration` (full suite, ~30s)
- **Phase gate (before merge of `feat(18):`):** full suite green + `mix verify.workspace_clean` green + `mix verify.release_parity 0.3.0` green (canary per D-21) + manual `workflow_dispatch` of verify-published-release.yml green

### Wave 0 Gaps

Wave 0 must create:
- [ ] `test/mix/tasks/verify_workspace_clean_test.exs` — covers INFRA-01
- [ ] `test/mix/tasks/verify_release_parity_test.exs` — covers INFRA-02 unit + integration
- [ ] `test/mix/tasks/workflow_wiring_test.exs` — covers INFRA-01 cross-workflow grep + INFRA-03 pin grep + INFRA-04 scheduled wiring grep. **Rationale:** centralizes all YAML-grep assertions into one test file; mirrors the `validate_release_contract!/0` helper pattern from `verify.phase11.ex:43-138` but in a test rather than a task. Avoids duplicating grep logic into multiple test files.
- [ ] No shared fixtures needed — tests are self-contained (stubs, no integration ceremony beyond `SCRYPATH_INTEGRATION` gating for the one integration test).
- [ ] No framework install — ExUnit is stdlib.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface introduced — hex.package fetch is auth-free for public packages; GitHub Actions token is scoped natively |
| V3 Session Management | no | No sessions |
| V4 Access Control | partial | GitHub Actions permissions: `contents: read` on ci.yml; `contents: write, issues: write, pull-requests: write` on release-please.yml (already locked down). Verify-published-release.yml has `contents: read` + implicit `GITHUB_TOKEN` permissions needed for `issues: write` must be set in that workflow's `permissions:` block |
| V5 Input Validation | yes | Version argument to `release_parity X.Y.Z` MUST validate against semver shape; reject shell-meta chars to prevent passing a malicious ref to `git ls-tree` |
| V6 Cryptography | no | Rely on Hex's built-in inner + outer checksum verification during `mix hex.package fetch`; do NOT hand-roll hashing |
| V12 File Handling | yes | tmp_dir must be created under `System.tmp_dir!/0` with unique suffix (Pitfall 3); cleaned up in `after` (Pitfall 4); never accept user-supplied path as tmp_dir |

### Known Threat Patterns for Phase 18 Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Maintainer runs `mix verify.release_parity "; rm -rf /"` with malicious arg | Tampering / Injection | Validate version arg matches `~r/^\d+\.\d+\.\d+([.-][A-Za-z0-9.-]+)?$/` before passing to `System.cmd/3`; `System.cmd/3` does not invoke a shell, but the ref name is substituted into a git command whose behavior on weird refs is undefined — validate first |
| GitHub token exposed via workflow log | Information Disclosure | Never `echo $GITHUB_TOKEN`; use `create-an-issue@v2` which reads from env silently; don't log API response contents |
| Hex CDN MITM delivering tampered tarball | Tampering | `mix hex.package fetch` verifies inner + outer checksums against the registry signature — mitigated by Hex CLI primitive, not by this task |
| Drift issue used to leak private repo names | Information Disclosure | Issue template emits only public info: version, run URL, file paths from public tarball. No secrets |
| Denial via open-ended retry on 429 | DoS | Retry loop bounded by `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` (default 10, max observed: 20). After N attempts: Mix.raise → exit 1 |
| Workspace-clean bypass via env var | Elevation of Privilege | D-04 deliberately rejects any escape hatch; the friction IS the feature |

## Sources

### Primary (HIGH confidence)

- `/Users/jon/projects/scrypath/.planning/phases/18-release-parity-gate-node-20-ci-cleanup/18-CONTEXT.md` — 24 locked decisions (read verbatim)
- `/Users/jon/projects/scrypath/.planning/REQUIREMENTS.md` — INFRA-01..04 canonical criteria
- `/Users/jon/projects/scrypath/.planning/milestones/v1.2-MILESTONE-AUDIT.md` — v1.2 divergence narrative (incident root cause)
- `/Users/jon/projects/scrypath/.planning/research/SUMMARY.md` — synthesis across 4 research dimensions
- `/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase11.ex` — task skeleton prior art (read in full)
- `/Users/jon/projects/scrypath/lib/mix/tasks/verify.release_publish.ex` — retry pattern + tmp-dir idiom (read in full)
- `/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase13.ex` — optional-flag parsing pattern (OptionParser.parse)
- `/Users/jon/projects/scrypath/lib/mix/tasks/verify.phase14.ex` — minimal verify shape (focused_tests list idiom)
- `/Users/jon/projects/scrypath/mix.exs` — `package.files` source of truth (line 106); `cli.preferred_envs` integration point (lines 38-48)
- `/Users/jon/projects/scrypath/.github/workflows/ci.yml` — pin-swap surface (5 `@v4` occurrences; 4 jobs)
- `/Users/jon/projects/scrypath/.github/workflows/release-please.yml` — D-16 step-insertion surface (line 49 checkout, line 68 @version grep)
- `/Users/jon/projects/scrypath/.github/workflows/publish-hex.yml` — D-17 step-insertion surface
- `/Users/jon/projects/scrypath/.github/workflows/verify-published-release.yml` — D-18 step-insertion surface (line 76 existing verify step)
- `/Users/jon/projects/scrypath/test/scrypath/mix_tasks/operator_tasks_test.exs` — ExUnit Mix-task test pattern (CaptureIO + Mix.Task.reenable + Mix.Task.run)
- `/Users/jon/projects/scrypath/test/release/consumer_smoke_test.exs` — subprocess invocation pattern + unique_tmp_dir!/0 test idiom
- `/Users/jon/projects/scrypath/release-please-config.json` — Elixir release-type, no `bump-*-pre-major` overrides → default minor-bump-on-feat applies (verified)
- `/Users/jon/projects/scrypath/docs/releasing.md` — D-23 documentation surface
- `/Users/jon/projects/scrypath/CHANGELOG.md` — D-24 target file (Unreleased entry already exists at line 65)
- https://git-scm.com/docs/git-status — porcelain v1 output format authoritative
- https://git-scm.com/docs/git-ls-tree — flags authoritative
- https://hexdocs.pm/hex/Mix.Tasks.Hex.Package.html — `fetch --unpack -o DIR` authoritative
- https://docs.github.com/en/actions/reference/evaluate-expressions-in-workflows-and-actions — `failure()` + status-check semantics

### Secondary (MEDIUM confidence)

- https://github.com/JasonEtco/create-an-issue/blob/main/README.md — action parameters (verified via WebFetch)
- https://github.com/actions/checkout/releases — v6 release notes (Node 24 confirmed)
- https://github.com/actions/cache/releases — v5 release notes (Node 24 + runner 2.327.1 confirmed)
- https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/ — Node 20 timeline
- https://github.com/googleapis/release-please — default versioning strategy for pre-1.0 + Elixir release-type

### Tertiary (LOW confidence — assumptions flagged)

- Hex tarball unpacked layout with `--unpack -o DIR`: `hex_metadata.config` location is inferred from general hex docs; A1 in Assumptions Log
- GitHub-hosted runner version ≥ 2.327.1 in April 2026: strongly implied by GitHub's auto-update policy but not explicitly documented; A2

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every library, CLI primitive, and action pin is directly verified
- Architecture: HIGH — patterns copied from existing verify.phase11.ex / verify.release_publish.ex, both read in full
- Pitfalls: HIGH — grounded in specific command behaviors verified via official docs + existing Scrypath idioms

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 (30 days for stable GitHub Actions pins + Hex CLI behavior; re-check before phase close if delayed beyond 30 days)

---
*Phase: 18-release-parity-gate-node-20-ci-cleanup*
*Research completed: 2026-04-17*
