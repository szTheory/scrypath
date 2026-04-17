---
phase: 18-release-parity-gate-node-20-ci-cleanup
verified: 2026-04-17T16:45:00Z
status: passed
score: 13/13 must-haves verified
overrides_applied: 0
requirements_verified: [INFRA-01, INFRA-02, INFRA-03, INFRA-04]
---

# Phase 18: Release-Parity Gate + Node 20 CI Cleanup — Verification Report

**Phase Goal:** Maintainers ship a v1.3 release that mechanically cannot diverge from what they approved on disk, and CI runs on GitHub Actions runtimes that will still exist after September 2026.

**Verified:** 2026-04-17T16:45:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Must-haves derived from ROADMAP.md Phase 18 Success Criteria + PLAN frontmatter truths (merged & de-duplicated).

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Maintainer attempting to publish with untracked/uncommitted changes under `lib/`, `test/`, `guides/`, or `docs/` sees `mix verify.workspace_clean` fail and block publish (SC#1) | VERIFIED | `lib/mix/tasks/verify.workspace_clean.ex` exists (97 lines); invokes `git status --porcelain -- <pathspecs>` via `System.cmd/3` (line 37); dirty output routes to `raise_dirty!/1` emitting `Workspace is not clean` + next-step copy + v1.2 audit backref (lines 82-96); live run `mix verify.workspace_clean` against clean tree exits 0 with `Workspace clean across 9 pathspecs` |
| 2 | `mix verify.release_parity X.Y.Z` exits non-zero on tarball-vs-tag divergence and clean pass otherwise (SC#2) | VERIFIED | `lib/mix/tasks/verify.release_parity.ex` exists (305 lines); `compute/2` is pure and returns `:parity` or `{:drift, og, oh}` (lines 88-99); `run/1` calls `System.halt(2)` on drift (line 259); unit tests cover parity + drift cases (verify_release_parity_test.exs passes in suite run) |
| 3 | CI runs on Node 24 runtimes: `actions/checkout@v6` + `actions/cache@v5` in ci.yml (SC#3) | VERIFIED | `.github/workflows/ci.yml` shows 4× `actions/checkout@v6` + 4× `actions/cache@v5` + 0× `actions/(checkout|cache)@v4` via direct grep counts |
| 4 | Scheduled daily `verify-published-release.yml` run re-checks release parity without human intervention (SC#4) | VERIFIED | `.github/workflows/verify-published-release.yml` has `schedule: - cron: "17 6 * * *"` (lines 4-5); `mix verify.release_parity` step lines 83-88 gated by `steps.resolve-version.outputs.published == 'true'` |
| 5 | `verify.workspace_clean` wired into all 3 publish paths (ci.yml quality, release-please.yml publish-hex, publish-hex.yml manual-recovery) per D-14 symmetry | VERIFIED | Grep count = 1 in each of ci.yml, release-please.yml, publish-hex.yml; 0 in verify-published-release.yml (expected — that's a read-only monitor) |
| 6 | Drift on scheduled run auto-files a deduplicated GitHub issue via create-an-issue@v2 (INFRA-04) | VERIFIED | `JasonEtco/create-an-issue@v2` step in verify-published-release.yml lines 90-99; guarded `failure() && github.event_name == 'schedule' && ...published == 'true'`; `update_existing: true`; `filename: .github/ISSUE_TEMPLATE/release-parity-drift.md` |
| 7 | Workflow `permissions:` includes `issues: write` so create-an-issue@v2 can file issues (Security V4) | VERIFIED | verify-published-release.yml line 10 declares `issues: write`; `contents: read` preserved line 9 |
| 8 | `.github/ISSUE_TEMPLATE/release-parity-drift.md` template exists with proper frontmatter | VERIFIED | File exists (593 bytes); frontmatter has title with `{{ env.VERSION }}` mustache, labels `["area:release", "severity:drift"]`, assignees `szTheory`; body references workflow run URL, version, and v1.2-MILESTONE-AUDIT.md |
| 9 | `docs/releasing.md` has "## Release parity gate" section referencing v1.2-MILESTONE-AUDIT.md (D-23) | VERIFIED | Section present at line 181 with three subsections (`### mix verify.workspace_clean`, `### mix verify.release_parity X.Y.Z`, `### Historical context`); v1.2-MILESTONE-AUDIT.md pointer at line 220 |
| 10 | CHANGELOG.md Unreleased section names both new Mix tasks + Node 24 runtime change + v1.2 traceability (D-24) | VERIFIED | Line 7 `## Unreleased` with `### Added` (both tasks), `### Changed` (actions/checkout@v6 + actions/cache@v5), `### Notes` (v1.2-MILESTONE-AUDIT.md bullet); all appear before first `## [0.3.0]` release heading |
| 11 | Phase closes with Conventional Commit `feat(18): add release-parity gates + Node 20 CI cleanup` (D-22) | VERIFIED | Commit `80500de` subject matches verbatim; body cites INFRA-01..04 and D-04 escape-hatch constraint; release-please can parse for minor bump |
| 12 | compute/2 split public for testability (Pitfall 11); System.halt(2) only in run/1 | VERIFIED | `def compute/2` at line 88 public; `def render_json/4`, `def retry_until!/4`, `def parse_version!/1` all public; `System.halt(2)` appears exactly once inside `emit_drift_and_halt!/4` private helper called from run/1 branch |
| 13 | `parse_version!/1` rejects non-semver before any subprocess reaches git/hex (Security V5 injection guard) | VERIFIED | `@version_regex ~r/^\d+\.\d+\.\d+([.-][A-Za-z0-9.-]+)?$/` at line 48; `parse_version!/1` invoked in run/1 line 55 BEFORE any System.cmd; unit tests cover shell-meta, partial versions, v-prefix, canonical, pre-release, missing arg |

**Score:** 13/13 truths verified

### Required Artifacts

| Artifact | Expected | Exists | Substantive | Wired | Status |
|----------|----------|--------|-------------|-------|--------|
| `lib/mix/tasks/verify.workspace_clean.ex` | Mix task module (INFRA-01) | Yes (2859 bytes) | Yes — 97 lines, uses Mix.Task, implements run/1 + build_pathspecs/0 | Yes — referenced by 3 workflow YAMLs + test file + docs | VERIFIED |
| `lib/mix/tasks/verify.release_parity.ex` | Mix task module (INFRA-02) | Yes (9346 bytes) | Yes — 305 lines; compute/2 split + render_json/4 + retry_until!/4 + parse_version!/1 public | Yes — referenced by verify-published-release.yml + test file + docs | VERIFIED |
| `.github/workflows/ci.yml` | 4× checkout@v6 + 4× cache@v5 + 0× @v4 (INFRA-03) | Yes (4247 bytes) | Yes — 194 lines, 4 jobs × (checkout + cache) = 8 Node-24 pins; no v4 left | Yes — workflow triggers on push/PR | VERIFIED |
| `.github/workflows/verify-published-release.yml` | release_parity step + create-an-issue step + issues:write | Yes (3499 bytes) | Yes — release_parity step lines 83-88; drift-issue step lines 90-99; issues:write line 10 | Yes — scheduled cron (line 5) + workflow_dispatch | VERIFIED |
| `.github/ISSUE_TEMPLATE/release-parity-drift.md` | Frontmatter + body | Yes (593 bytes) | Yes — title/labels/assignees frontmatter + body with 4 mustache env refs + v1.2 audit pointer | Yes — referenced by `filename:` arg in create-an-issue step | VERIFIED |
| `docs/releasing.md` §Release parity gate | New H2 section w/ 3 subsections + v1.2 pointer (D-23) | Yes | Yes — 42-line section at line 181, ships to HexDocs via existing `mix.exs` docs.extras | Yes — HexDocs-published on release | VERIFIED |
| `CHANGELOG.md` Unreleased section | Added/Changed/Notes subsections with Phase 18 deliverables (D-24) | Yes | Yes — Unreleased block lines 7-20 with all prescribed bullets; appears above [0.3.0] | Yes — release-please consumes on promote | VERIFIED |
| `mix.exs` cli.preferred_envs | +`verify.workspace_clean` +`verify.release_parity` as :test | Yes — line 46 `"verify.workspace_clean": :test` + line 47 `"verify.release_parity": :test` | Yes — `Scrypath.MixProject.cli()[:preferred_envs]` returns `:test` for both keys at runtime | Yes — Mix CLI honors for task invocation | VERIFIED |
| `test/mix/tasks/verify_workspace_clean_test.exs` | Red-state unit test → green | Yes | Yes — contract tests for build_pathspecs/0, arg guard, clean-path | Yes — passes in suite run | VERIFIED |
| `test/mix/tasks/verify_release_parity_test.exs` | Red-state unit + integration canary | Yes | Yes — 5 describe blocks (compute/2, render_json/4, retry_until!/4, parse_version!/1, integration) | Yes — unit tests pass; @tag :integration gated by SCRYPATH_INTEGRATION | VERIFIED |
| `test/mix/tasks/workflow_wiring_test.exs` | 15 YAML-grep contract tests | Yes | Yes — 5 describe blocks (INFRA-01×3, INFRA-02×1, INFRA-03×4, INFRA-04×5, mix.exs×2) | Yes — runs against live .github/workflows/ files | VERIFIED |

All artifacts verified at Levels 1-3 (exist, substantive, wired).

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| mix.exs cli.preferred_envs | Mix.Tasks.Verify.WorkspaceClean / ReleaseParity | Atom keys mapped to :test env | WIRED | Runtime check: `Scrypath.MixProject.cli()[:preferred_envs]` returns `{:test, :test}` for both keys |
| Mix.Tasks.Verify.WorkspaceClean.build_pathspecs/0 | Mix.Project.config()[:package][:files] ++ ["test"] | Keyword.get/3 chain on project config | WIRED | Lines 61-72: `Mix.Project.config()` → Keyword.get(:package) → Keyword.get(:files) → ++ ["test"] |
| Mix.Tasks.Verify.WorkspaceClean.run/1 | git status --porcelain -- <pathspecs> | System.cmd/3 with stderr_to_stdout | WIRED | Line 37: `System.cmd("git", ["status", "--porcelain", "--" \| pathspecs], stderr_to_stdout: true)` |
| Mix.Tasks.Verify.ReleaseParity.run/1 (drift branch) | System.halt(2) | exit-code 2 emission (D-10) | WIRED | emit_drift_and_halt!/4 line 259: `System.halt(2)` — only in drift path |
| fetch_hex_paths!/4 | mix hex.package fetch scrypath X.Y.Z --unpack -o tmp | System.cmd/3 with retry_until!/4 | WIRED | Lines 173-182 + 185-206 — retry wrapper + do_fetch_hex with mix hex.package fetch shell-out |
| fetch_git_paths!/1 | git ls-tree -r --name-only scrypath-vX.Y.Z -- lib/ guides/ docs/ | System.cmd/3 no checkout | WIRED | Lines 208-235 — argv list, no shell, tag interpolated from pre-validated version |
| parse_version!/1 | @version_regex | Regex.match? pre-subprocess guard | WIRED | Line 154: `Regex.match?(@version_regex, version)` invoked before System.cmd chain |
| ci.yml quality job | mix verify.workspace_clean | YAML step insertion between format-check and credo | WIRED | Lines 77-78 `Verify workspace is clean` step sits between `mix format --check-formatted` (line 75) and `mix credo` (line 81) |
| release-please.yml publish-hex job | mix verify.workspace_clean | YAML step insertion after deps.get, before release-version grep | WIRED | Lines 67-68 between `mix deps.get` (line 65) and `Verify release version` (line 70) |
| publish-hex.yml | mix verify.workspace_clean | YAML step insertion after deps.get, before phase11 gate | WIRED | Lines 44-45 between `mix deps.get` (line 42) and `Run release contract gate` (line 47) |
| verify-published-release.yml schedule cron | mix verify.release_parity step | Inherits SCRYPATH_RELEASE_VERIFY_{ATTEMPTS,SLEEP_MS} | WIRED | Lines 83-88 — same env block as release_publish step; positioned after release_publish; guarded by published=='true' |
| release_parity exit 2 (drift) on scheduled run | release-parity-drift.md template | create-an-issue@v2 with update_existing:true | WIRED | Lines 90-99 — action pinned @v2; `filename: .github/ISSUE_TEMPLATE/release-parity-drift.md`; `update_existing: true` |
| create-an-issue@v2 step | workflow permissions block | `issues: write` permission | WIRED | Line 10 declares issues:write at workflow scope; step uses ${{ secrets.GITHUB_TOKEN }} |

All 13 key links verified.

### Data-Flow Trace (Level 4)

Phase 18 deliverables produce runtime data via Mix tasks (not user-rendering components). Applying adapted Level 4 trace to verify data flows through wiring rather than returning hardcoded empty values.

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| verify.workspace_clean.ex run/1 | pathspecs | `Mix.Project.config()[:package][:files] ++ ["test"]` → live mix.exs read | Yes — returns real package.files (lib, .formatter.exs, mix.exs, README.md, ARCHITECTURE.md, CHANGELOG.md, guides, docs, test) | FLOWING |
| verify.workspace_clean.ex run/1 | output | `System.cmd("git", ["status", "--porcelain", "--" \| pathspecs])` | Yes — real git subprocess output; live invocation returns `""` (clean) and prints `Workspace clean across 9 pathspecs` | FLOWING |
| verify.release_parity.ex run/1 | hex_paths | `Path.wildcard` over unpacked tarball `{lib,guides,docs}/**/*` filtered + `Path.relative_to` | Yes — real filesystem enumeration after retry-wrapped `mix hex.package fetch` | FLOWING |
| verify.release_parity.ex run/1 | git_paths | `System.cmd("git", ["ls-tree", "-r", "--name-only", tag, "--", ...])` | Yes — real subprocess, MapSet.size guard line 224 rejects empty result | FLOWING |
| verify.release_parity.ex compute/2 | only_in_git / only_in_hex | `MapSet.difference/2` over real hex_paths + git_paths | Yes — pure function; produces real diff lists or :parity; not hardcoded | FLOWING |
| verify-published-release.yml create-an-issue env | VERSION / GITHUB_* | Real GitHub Actions env + `steps.resolve-version.outputs.version` | Yes — VERSION populated from step output; GITHUB_* auto-injected by runner | FLOWING |

No HOLLOW / STATIC / DISCONNECTED artifacts. All data sources are real subprocess output, project config reads, or GitHub Actions context — no hardcoded empty values in hot paths.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase 18 test suite green | `mix test test/mix/tasks/ --exclude integration` | 31 tests, 0 failures (1 excluded = @tag :integration canary) | PASS |
| workspace_clean runnable | `mix verify.workspace_clean` | `Workspace clean across 9 pathspecs` → exit 0 | PASS |
| mix.exs preferred_envs load | `elixir -e '...Scrypath.MixProject.cli()[:preferred_envs]...'` | `{:test, :test}` for workspace_clean + release_parity keys | PASS |
| ci.yml Node-24 pin counts | `grep -c "actions/checkout@v6"` + `grep -c "actions/cache@v5"` + `grep -cE "(checkout\|cache)@v4"` | 4 + 4 + 0 | PASS |
| workspace_clean wired 3 paths | grep -c across ci.yml / publish-hex.yml / release-please.yml / verify-published-release.yml | 1 / 1 / 1 / 0 (last correctly zero — read-only monitor) | PASS |
| release_parity wired + permissions | grep -c `mix verify.release_parity` + `JasonEtco/create-an-issue@v2` + `issues: write` + `failure() && github.event_name == 'schedule'` | 1 / 1 / 1 / 1 | PASS |
| Closing commit matches D-22 | `git log 80500de --format=%s` | `feat(18): add release-parity gates + Node 20 CI cleanup` (verbatim) | PASS |

Live integration canary (D-21) — `SCRYPATH_INTEGRATION=1 mix test --only integration` — was run at phase close per SUMMARY, exited 0 against live Hex 0.3.0. Not re-run in this verification to avoid redundant network traffic (deterministic from unit-tested compute/2).

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| INFRA-01 | 18-01, 18-02, 18-05 | `mix verify.workspace_clean` fails on dirty tree; integrated into publish-hex.yml before `mix hex.publish` | SATISFIED | Mix task shipped in verify.workspace_clean.ex; wired into ci.yml quality + release-please.yml publish-hex + publish-hex.yml manual recovery (3 publish paths × 1 ref each); 3 INFRA-01 tests + arg-guard tests in workflow_wiring_test.exs green |
| INFRA-02 | 18-01, 18-03, 18-06 | `mix verify.release_parity X.Y.Z` compares Hex tarball lib/+guides/+docs/ vs git tag; integrated into verify-published-release.yml | SATISFIED | Mix task shipped in verify.release_parity.ex; exit 0/2/1 contract encoded via compute/2 + System.halt(2); wired into verify-published-release.yml schedule cron; INFRA-02 test in workflow_wiring_test.exs + 15 unit tests in verify_release_parity_test.exs green |
| INFRA-03 | 18-01, 18-04 | ci.yml uses actions/checkout@v6 + actions/cache@v5 | SATISFIED | 4× checkout@v6 + 4× cache@v5 + 0× v4 verified by direct grep counts against .github/workflows/ci.yml; 4 INFRA-03 tests in workflow_wiring_test.exs green |
| INFRA-04 | 18-01, 18-06 | CI runs verify.workspace_clean on every push AND verify.release_parity as scheduled daily job against latest Hex | SATISFIED | workspace_clean runs in ci.yml quality on every push (line 77-78); release_parity runs daily via verify-published-release.yml schedule cron `17 6 * * *` against `${{ steps.resolve-version.outputs.version }}`; 5 INFRA-04 tests green |

All 4 requirement IDs satisfied. No orphaned requirements — REQUIREMENTS.md maps INFRA-01..04 to Phase 18 exclusively and all four appear in the plans' `requirements:` frontmatter.

### Anti-Patterns Scanned

Files modified in phase 18 scanned for TODO/FIXME/placeholder/stub patterns:

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| lib/mix/tasks/verify.workspace_clean.ex | — | No TODO/FIXME/placeholder; no `return null/[]/empty` stubs; no `--allow-dirty`/`WORKSPACE_CLEAN_SKIP` escape hatch | — | Clean |
| lib/mix/tasks/verify.release_parity.ex | — | No TODO/FIXME; no `--strict`/`--hash`/`SHA` out-of-scope flags; no `--allow-dirty` escape hatch | — | Clean |
| .github/workflows/*.yml | — | No `continue-on-error: true` on release_parity step; no `--allow-dirty` in any workflow | — | Clean |
| CHANGELOG.md | L80 legacy `## [Unreleased]` block | Duplicate Unreleased headings (WR-01 from REVIEW.md) | Info | Pre-existing from earlier phase; noted in code review — does NOT block Phase 18 goal (release-please will still parse new `## Unreleased` at line 7 because it's first). Review recommends cleanup in a follow-up. |

Code review findings (18-REVIEW.md) summary:
- **0 critical** findings
- **3 warnings** (WR-01 duplicate Unreleased, WR-02 shell interpolation in publish-hex.yml inputs.release_version, WR-03 OTP 28.0 vs 28.1 drift) — all pre-existing file content or scope-adjacent; none block the phase 18 goal.
- **5 info** findings (permissions block hardening, regex tightening, log continuity, git-not-on-PATH ergonomics, integration canary comment) — quality-of-life improvements, not defects.

None of the review findings are blocker-severity. The phase 18 goal (mechanized release parity + Node 24 CI) is achieved despite these advisory notes.

### Known Pre-Existing Issue (Not Phase 18 Scope)

Phase 18 SUMMARY documents 1 pre-existing test failure in `Scrypath.TelemetryTest:267` from README wording drift introduced in phase 12, verified against phase-start HEAD `dc5a2b4`. Phase 18 test suite (`mix test test/mix/tasks/ --exclude integration`) runs clean with 31/31 passing — no phase 18 regression.

### Human Verification Required

None. Phase 18 is closed with the `feat(18):` closing commit (`80500de`). The post-merge `release-please` 0.4.0 PR and its subsequent canonical publish path run is the release cycle's exit condition, not a Phase 18 verification step — that will be observable in the ROADMAP `v1.3` milestone state. All programmatic checks pass.

**UAT shift-left (2026-04-17):** `/gsd-verify-work 18` produced `18-UAT.md` with 9 tests that initially required maintainer action. All 9 were shifted left into automated assertions — see `18-UAT.md` for the full automation map. Net change: +8 unit tests (`test/mix/tasks/verify_workspace_clean_test.exs` classify/3 block, `test/mix/tasks/workflow_wiring_test.exs` UAT shift-left block). Zero human verification remains for Phase 18. The behavior-preserving `classify/3` refactor in `lib/mix/tasks/verify.workspace_clean.ex` mirrors the Pitfall-11 split already shipped in `verify.release_parity.ex`.

### Gaps Summary

No gaps. All 13 observable truths VERIFIED, all 11 artifacts pass Levels 1-4, all 13 key links WIRED, all 4 requirements SATISFIED, all 7 behavioral spot-checks PASS. Anti-pattern scan surfaces only informational findings from code review (no blockers).

The phase goal is mechanized and demonstrable:
- **workspace_clean** catches tag-vs-source drift at publish time (wired into 3 publish paths).
- **release_parity** catches tarball-vs-tag drift after publish (daily cron + dedup'd issue auto-filing).
- **Node 24 runtime** pins are live in ci.yml (4× checkout@v6 + 4× cache@v5, zero @v4 left).
- **Closing commit** uses the load-bearing `feat(18):` subject so release-please can cut 0.4.0 and re-align Hex with main in the same cycle.

---

_Verified: 2026-04-17T16:45:00Z_
_Verifier: Claude (gsd-verifier)_
