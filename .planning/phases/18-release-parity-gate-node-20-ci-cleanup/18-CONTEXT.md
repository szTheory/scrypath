# Phase 18: Release-Parity Gate + Node 20 CI Cleanup - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Mechanize divergence prevention between `main` and published Hex tarballs so v1.3 releases cannot recur the v1.2-era tag-vs-source drift. Ship two new Mix tasks (`verify.workspace_clean`, `verify.release_parity`), wire them into canonical publish + manual recovery + per-push CI + scheduled daily monitor, and clear the `actions/checkout@v4` + `actions/cache@v4` Node 20 deprecation from `ci.yml`. No new public library API surface, no new user-facing verbs beyond the `mix verify.*` namespace; every later v1.3 feature phase inherits this gate.

</domain>

<decisions>
## Implementation Decisions

### workspace_clean Mix task

- **D-01:** `mix verify.workspace_clean` derives its pathspecs from `mix.exs` `files:` list + `test/**`. At Phase 18 scope that resolves to: `lib/**`, `.formatter.exs`, `mix.exs`, `README.md`, `ARCHITECTURE.md`, `CHANGELOG.md`, `guides/**`, `docs/**`, `test/**`. Self-maintaining — adding a new packaged path to `files:` automatically extends the gate.
- **D-02:** Implementation uses `System.cmd("git", ["status", "--porcelain", "--"] ++ pathspecs, stderr_to_stdout: true)`. Empty stdout + exit 0 = clean. Non-empty output = `Mix.raise/1` with the offending paths and next-step copy (`git add`, `git stash -u`, `git checkout --`). Pattern mirrors the prior art in `expublish`'s `Expublish.Git.validate/1`.
- **D-03:** No HEAD-behind-origin/main check. `release_parity` catches post-publish tarball drift; layering a network-requiring `git fetch` inside a Mix verify task adds friction without closing a drift class that isn't already covered.
- **D-04:** No escape-hatch flag or env var. v1.2 proved emergency bypasses become routine (see the `cargo publish --allow-dirty` anti-pattern — rust-lang/cargo#9398). If a true emergency requires a dirty publish, the maintainer comments out the workflow step in a PR; the friction is the feature.
- **D-05:** `test/**` is included despite test files not shipping in the tarball — uncommitted tests mean "the lib/ state being published was not tested as it will ship," which maps directly to Scrypath's operational-honesty posture.

### release_parity Mix task

- **D-06:** `mix verify.release_parity X.Y.Z` acquires the Hex side via `System.cmd("mix", ["hex.package", "fetch", "scrypath", version, "--unpack", "-o", tmp_dir], stderr_to_stdout: true)` — the canonical Hex CLI handles auth-free download, checksum verify, and unpack in one step. No new HTTP client code; no `Req` dep reach; parallel pattern to existing `verify.phase11`'s shell-out idiom.
- **D-07:** Git side uses `git ls-tree -r --name-only scrypath-vX.Y.Z -- lib/ guides/ docs/`. No checkout needed, respects the actual tagged tree, fast.
- **D-08:** Comparison depth is path-set equality via `MapSet.difference/2` on `lib/ + guides/ + docs/` only (INFRA-02 literal scope). SHA-256 hash comparison is deliberately deferred — `git archive` at a tag and `mix hex.build` from the same commit produce byte-equal contents because they read the same locked git tree, so hash drift would require post-tag file mutation (orthogonal to the v1.2 incident class). Ship path-only; upgrade to path+hash is a ~20-line additive change if ever needed.
- **D-09:** Scope stays restricted to `lib/ + guides/ + docs/` even though `mix.exs` `files:` is broader. Rationale: `mix.exs`, `.formatter.exs`, `README.md`, `ARCHITECTURE.md`, `CHANGELOG.md` are touched in the release PR itself; silent drift there would break the release loudly, not hide inside it. The risk surface INFRA-02 names is the many-file subtree where a missing file slips past review.
- **D-10:** Exit codes: `0` = parity, `2` = drift (POSIX "intentional failure"), `1` = runtime error (network failure, missing tag, tarball fetch failure). CI treats any non-zero as failure; humans and downstream automation can distinguish drift from infra hiccups.
- **D-11:** Output is human-readable by default with a machine-readable `--json` flag. Human output shows BOTH directions of the diff (`Only in git tag (missing from Hex tarball): …` and `Only in Hex tarball (not in git tag): …`) plus a file count summary on success. JSON shape: `{"version": "X.Y.Z", "status": "ok" | "drift", "only_in_git": [...], "only_in_hex": [...]}`.
- **D-12:** CDN propagation race: inherit `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` / `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` env-var retry pattern from `verify.release_publish` so daily runs don't false-fail on freshly-cut releases.

### Node 20 CI cleanup (INFRA-03)

- **D-13:** Only `.github/workflows/ci.yml` needs edits. Two surgical swaps in both `test` matrix jobs and the `quality` + `phase5-verification` + `phase13-verification` jobs: `actions/checkout@v4` → `actions/checkout@v6`, `actions/cache@v4` → `actions/cache@v5`. No other workflow changes — `publish-hex.yml`, `release-please.yml`, `verify-published-release.yml` already run on `@v6`; `erlef/setup-beam@v1` and `googleapis/release-please-action@v4` are already Node 24-ready.

### Workflow wiring (INFRA-01 + INFRA-04)

- **D-14:** Symmetric gate coverage across BOTH publish paths. INFRA-01's literal "`publish-hex.yml`" phrasing is treated as paperwork-era scope; gating only the manual-recovery workflow would leave the canonical `release-please.yml` publish job less guarded than the emergency lane — exactly the v1.2 failure shape.
- **D-15:** `ci.yml`'s `quality` job gets a new `workspace_clean` step, positioned after `mix format --check-formatted` and before `mix credo`. Self-consistent with where `mix deps.get --check-locked`-class lint steps live in reference repos (Req, Oban).
- **D-16:** `release-please.yml`'s `publish-hex` job gets a new `workspace_clean` step, positioned immediately after tag checkout and before `mix verify.phase11`. In this context the check is belt-and-suspenders (fresh tag checkout on a clean runner should be empty) but it's a cheap, load-bearing invariant assertion.
- **D-17:** `publish-hex.yml` (manual recovery) gets the same `workspace_clean` step at the same position as the canonical path. Manual recovery inherits the same protection level as canonical release.
- **D-18:** `verify-published-release.yml` is EXTENDED — not forked — with a new `mix verify.release_parity "${{ steps.resolve-version.outputs.version }}"` step running after the existing `mix verify.release_publish` step in the same job. Honors Phase 11's "ongoing verification lives in one read-only workflow" decision; reuses the existing `checkout@v6` + `setup-beam` + `deps.get` scaffolding.
- **D-19:** Daily-cron drift surfacing: default GitHub workflow-failure email to maintainer, plus `JasonEtco/create-an-issue@v2` with a deduplicating title like `"Release parity drift detected: scrypath X.Y.Z"` — reuses an already-open issue instead of filing a fresh one per run. Auto-file ONLY on `event_name == 'schedule'` + drift exit code 2; manual `workflow_dispatch` runs stay silent beyond the red check.
- **D-20:** No new workflow files. Four existing workflows get one step each.

### Known-divergence transition (0.3.0 → 0.4.0)

- **D-21:** No bootstrap allowlist, no `MIN_VERSION` env var, no hardcoded skip list for 0.3.0. Empirical finding: `git ls-tree scrypath-v0.3.0 -- lib/ guides/ docs/` and the live Hex 0.3.0 tarball both resolve from commit `d642036` and agree on file paths. The v1.2 divergence was tag-vs-`main`, not tag-vs-Hex — so `mix verify.release_parity 0.3.0` passes today with exit 0 and no special-casing.
- **D-22:** Phase 18 closes with a `feat(18): add release-parity gates + Node 20 CI cleanup` Conventional Commit on `main`. Release-please opens a release PR; merging promotes `mix.exs` `@version` `0.3.0 → 0.4.0`, cuts tag `scrypath-v0.4.0`, triggers `publish-hex` job, publishes to Hex. This automatically re-aligns Hex with `main` in the same cycle — Phase 18's raison d'être. No separate milestone-close action needed.
- **D-23:** `docs/releasing.md` gets a new "Release parity gate" section explaining: what `workspace_clean` catches (tag-vs-source drift at publish time), what `release_parity` catches (tarball-vs-tag drift after publish), and the v1.2 backstory as a historical note. Documentation lives in the published surface (HexDocs-visible) so adopters reading the maintainer-facing docs see the invariants.
- **D-24:** `CHANGELOG.md` unreleased entry names both new Mix tasks and carries one `### Notes` bullet pointing to `.planning/milestones/v1.2-MILESTONE-AUDIT.md` for traceability.

### Claude's Discretion

- Exact Mix.raise/1 copy phrasing (D-02) — match existing Scrypath error-message tone from `lib/scrypath/options.ex` precedent
- Tmp-dir naming for `hex.package fetch --unpack` output (D-06) — use `System.tmp_dir!/0` + unique suffix + `File.rm_rf!/1` cleanup
- JSON field ordering in `--json` output (D-11) — stable ordering, fields as named above
- `create-an-issue` labels/assignees (D-19) — add `area:release`, `severity:drift`, assign to repo maintainers
- Test-file layout for the new tasks — `test/mix/tasks/verify_workspace_clean_test.exs`, `test/mix/tasks/verify_release_parity_test.exs`

### Folded Todos

None. `gsd-tools todo match-phase 18` returned zero matches; nothing in the project todo backlog intersects Phase 18 scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 18 requirements and roadmap

- `.planning/ROADMAP.md` §"Phase 18: Release-Parity Gate + Node 20 CI Cleanup" — goal statement, 4 success criteria, dependency declaration (blocks phases 19-23)
- `.planning/REQUIREMENTS.md` §"Release Parity & CI Hygiene" (INFRA-01 through INFRA-04) — canonical acceptance criteria; note that INFRA-01's literal "publish-hex.yml" is treated as paperwork-era scope per D-14
- `.planning/PROJECT.md` §"Requirements > Active" — explicitly names "GitHub Actions Node 20 deprecation warnings and VALIDATION.md closure" as the debt retirement this phase delivers
- `.planning/STATE.md` — current milestone position, prior-phase decisions log

### v1.2 divergence incident (root cause for this phase)

- `.planning/milestones/v1.2-MILESTONE-AUDIT.md` — full divergence narrative; `passed_with_divergence` header + tech_debt block + corrective-commit list. Read this BEFORE writing any parity check logic so the planner understands what release_parity does NOT catch (tag-vs-main; that's workspace_clean's job).

### Deep research synthesis

- `.planning/research/SUMMARY.md` §"Phase 1 (A): Release-Parity Gate + Node 20 CI Cleanup" — phase-ordering rationale, PITFALLS P1 mitigation strategy, STACK Node 20 deadline anchor
- `.planning/research/SUMMARY.md` §"Critical Pitfalls" P1 — "v1.2 on-disk ↔ Hex divergence recurrence" — canonical mitigation language

### Existing Mix task prior art (copy patterns, do not recreate)

- `lib/mix/tasks/verify.phase11.ex` — shell-out-to-System.cmd pattern with `Mix.raise/1` error surfacing; `ensure_no_args!/1` argument guard; `run_system_command!/3` helper shape. Copy this architecture for `verify.workspace_clean` and `verify.release_parity`.
- `lib/mix/tasks/verify.release_publish.ex` (exists; referenced from `publish-hex.yml` L57) — inspect for the `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` / `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` retry pattern that `verify.release_parity` must inherit (D-12)
- `mix.exs` `@version`, `@source_ref`, `package.files`, `cli.preferred_envs` — the `package.files` list is the source of truth for D-01's pathspec derivation; `preferred_envs` gets two new entries (`verify.workspace_clean: :test`, `verify.release_parity: :test`)

### Workflows to edit (Phase 18 surface)

- `.github/workflows/ci.yml` — INFRA-03 Node 20 cleanup (5 step replacements across 4 jobs); D-15 new `workspace_clean` step in `quality` job
- `.github/workflows/release-please.yml` — D-16 new `workspace_clean` step in `publish-hex` job
- `.github/workflows/publish-hex.yml` — D-17 new `workspace_clean` step (manual recovery path parity with canonical)
- `.github/workflows/verify-published-release.yml` — D-18 new `release_parity` step extending existing daily-cron job; D-19 `create-an-issue` step guarded on `failure() && event_name == 'schedule'`

### Maintainer-facing docs to update

- `docs/releasing.md` — add "Release parity gate" section (D-23) explaining workspace_clean + release_parity invariants and v1.2 historical note. This file ships to HexDocs via `mix.exs` `extras:`.
- `CHANGELOG.md` — D-24 unreleased entry naming both new tasks plus traceability note

### External references (non-project, read for idiom calibration)

- **expublish** (Hex package) — Elixir-native release-guard prior art; `Expublish.Git.validate/1` shape. Copy the `System.cmd("git", ["status", "--porcelain"])` pattern; reject the `--allow-untracked` escape hatch.
- **check-manifest** (Python) — cross-ecosystem prior art for sdist-vs-VCS parity checking. Copy the "missing from tarball / extra in tarball" output shape; its `-u` auto-suggest is not applicable.
- **mix hex.package** — Hex CLI canonical primitive for auth-free tarball fetch + unpack (`HexDocs.pm/hex/Mix.Tasks.Hex.Package.html`); what D-06 uses directly.
- **rust-lang/cargo#9398** — `cargo publish --allow-dirty` sensitive-file-leak incident, cited as anti-pattern justifying D-04's no-escape-hatch stance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`verify.phase11.ex` Mix task shape** (`lib/mix/tasks/verify.phase11.ex`): `System.cmd("grep", args, stderr_to_stdout: true)` + `Mix.shell().info/1` for progress + `Mix.raise/1` on non-zero. Directly reusable for both new tasks. Includes `ensure_no_args!/1` and `run_system_command!/3` private helpers that should be copied (or extracted to a shared `Mix.Tasks.Verify.Helpers` module if a third task lands this phase — deferred unless scope grows).
- **`verify.release_publish` retry idiom**: `SCRYPATH_RELEASE_VERIFY_ATTEMPTS` + `SCRYPATH_RELEASE_VERIFY_SLEEP_MS` env-driven retry loop (already referenced in `publish-hex.yml` L54-56 and `verify-published-release.yml` L78-79). `verify.release_parity` reuses the same env names so maintainers learn one retry model.
- **`mix.exs` `cli.preferred_envs`**: existing list at `mix.exs:38-48` — two new entries slot in cleanly for the new tasks.
- **`mix.exs` `package.files`**: `~w(lib .formatter.exs mix.exs README.md ARCHITECTURE.md CHANGELOG.md guides docs)` — source of truth for D-01's workspace_clean pathspec derivation.
- **Existing CI matrix structure** (`ci.yml:17-27, 52-97`): `quality` job already hosts `verify.phase11`, `verify.phase13 --skip-integration`, `verify.phase14` in sequence — `verify.workspace_clean` slots in as a similar lint-tier check without adding a separate job.

### Established Patterns

- **Mix verify task naming:** `Mix.Tasks.Verify.*` module under `lib/mix/tasks/verify.*.ex`. Both new tasks follow this convention: `Mix.Tasks.Verify.WorkspaceClean` and `Mix.Tasks.Verify.ReleaseParity`.
- **Workflow `checkout@v6`**: `release-please.yml`, `publish-hex.yml`, `verify-published-release.yml` already pinned to `@v6`. Only `ci.yml` remains on `@v4` — confirms INFRA-03's single-file scope.
- **Verification workflow separation (Phase 11 decision):** ongoing verification lives in `verify-published-release.yml`, never inline with publish workflows. D-18 honors this by extending that workflow rather than forking a sibling.
- **Exit code discipline:** existing `verify.release_publish` uses `Mix.raise/1` → `{:shutdown, 1}`. New `release_parity` introduces `{:shutdown, 2}` for the distinct "drift detected" semantic (D-10) while preserving `1` for runtime errors.
- **Test-location convention:** `test/` mirrors `lib/` — Mix task tests belong at `test/mix/tasks/`. Existing precedent: `test/scrypath/mix_tasks/operator_tasks_test.exs`.

### Integration Points

- `mix.exs` L36-49 `cli.preferred_envs` — add `"verify.workspace_clean": :test`, `"verify.release_parity": :test`
- `lib/mix/tasks/verify.release_parity.ex` NEW — shelling to `mix hex.package fetch --unpack` + `git ls-tree`
- `lib/mix/tasks/verify.workspace_clean.ex` NEW — shelling to `git status --porcelain --` with package-files pathspecs
- `.github/workflows/ci.yml` — 5 `checkout/cache` pin swaps across 4 jobs + 1 new `workspace_clean` step in `quality`
- `.github/workflows/release-please.yml` L47-58 `publish-hex` job — 1 new `workspace_clean` step between L51 (checkout) and L70 (run verify.phase11)
- `.github/workflows/publish-hex.yml` L22-31 — 1 new `workspace_clean` step between L26 (checkout) and L44 (run verify.phase11)
- `.github/workflows/verify-published-release.yml` — 1 new `release_parity` step after L80 (existing verify.release_publish), plus 1 new drift-surfacing step guarded on `failure() && event_name == 'schedule'` using `JasonEtco/create-an-issue@v2`
- `docs/releasing.md` — new "Release parity gate" section
- `CHANGELOG.md` — new unreleased entry
- `test/mix/tasks/verify_workspace_clean_test.exs` NEW — unit tests for pathspec derivation, clean/dirty detection, error message shape
- `test/mix/tasks/verify_release_parity_test.exs` NEW — unit tests for path-set diff, exit codes 0/1/2, `--json` output shape, CDN-retry behavior

</code_context>

<specifics>
## Specific Ideas

- "One-shot perfect recommendation" posture from the user: every gray area resolved with a single coherent pick across the four decisions; no options held in limbo for "we'll decide at planning time."
- Output shape reference for `release_parity`: check-manifest (Python)'s "missing from sdist / extra in sdist" human-readable diff — concise, unambiguous, copy-the-shape-not-the-exact-words.
- Prior art touchstones the planner should hold close: `expublish` (Elixir-native), `cargo publish --allow-dirty` (cautionary), `mix hex.package` (Hex-native primitive), `check-manifest` (cross-ecosystem sdist-parity precedent), Bandit/Req/Oban CI workflows (Elixir OSS release idioms).
- "No new workflow files" is a hard constraint — every new step extends an existing workflow, honoring Phase 11's separation-of-concerns decision.
- Phase 18 closing commit MUST be a `feat(18):` Conventional Commit so release-please auto-cuts `0.4.0` and the v1.2 gap closes in the same cycle (D-22). This is a planning-level requirement, not an implementation detail.

</specifics>

<deferred>
## Deferred Ideas

- **SHA-256 hash comparison for release_parity (belt-and-suspenders mode)** — defer to a future phase if a real post-tag mutation incident ever occurs; current path-only approach covers the v1.2 incident class and extends to hash-depth with ~20 LOC if needed.
- **Emergency-publish escape hatch for workspace_clean** (`SCRYPATH_WORKSPACE_CLEAN_SKIP=1`) — deliberately rejected per D-04; revisit only if a real emergency-publish scenario arises AND a structural mechanism to prevent normalization-of-bypass (e.g. auto-fail after N uses, loud Slack posting) is designed.
- **Extracting a shared `Mix.Tasks.Verify.Helpers` module** — defer until a third `verify.*` task lands this phase needing the same `run_system_command!/3` shell-out helper. Two tasks isn't enough to pull an abstraction.
- **Per-phase SUMMARY manifest convention for release_parity** (mentioned in research SUMMARY.md) — not adopted; path-list diff against `git ls-tree` at tag supersedes the need for a per-phase manifest file.

### Reviewed Todos (not folded)

None. `gsd-tools todo match-phase 18` returned zero matches.

</deferred>

---

*Phase: 18-release-parity-gate-node-20-ci-cleanup*
*Context gathered: 2026-04-17*
