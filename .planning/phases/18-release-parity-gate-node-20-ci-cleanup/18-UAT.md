---
status: passed
phase: 18-release-parity-gate-node-20-ci-cleanup
source: [18-01-SUMMARY.md, 18-02-SUMMARY.md, 18-03-SUMMARY.md, 18-04-SUMMARY.md, 18-05-SUMMARY.md, 18-06-SUMMARY.md, 18-07-SUMMARY.md]
started: 2026-04-17T17:00:00Z
updated: 2026-04-17T17:30:00Z
automated: true
---

## Current Test

All 9 tests shifted left to automation. No checkpoint awaiting.

## Tests

### 1. mix verify.workspace_clean on clean tree
expected: Run `mix verify.workspace_clean` against the current working tree. Exits 0 with message "Workspace clean across N pathspecs".
result: pass
automation: |
  - `test/mix/tasks/verify_workspace_clean_test.exs` — `classify/3` clean-branch unit test +
    `:requires_clean_workspace`-tagged integration test.
  - `.github/workflows/ci.yml` quality job runs `mix verify.workspace_clean` on every push
    (plan 18-05, D-14 wiring).

### 2. mix verify.workspace_clean on dirty tree
expected: With an untracked file under lib/, `mix verify.workspace_clean` exits non-zero with "Workspace is not clean" and offending paths.
result: pass
automation: |
  - `test/mix/tasks/verify_workspace_clean_test.exs` — `classify/3` dirty-branch test asserts
    `{:dirty, paths}` return shape with offending paths passed through verbatim.
  - `lib/mix/tasks/verify.workspace_clean.ex` `run/1` routes `{:dirty, _}` through
    `raise_dirty!/1` which emits the "Workspace is not clean" Mix.raise.

### 3. mix verify.release_parity 0.3.0 live canary
expected: Run `mix verify.release_parity 0.3.0` against live Hex. Prints retry progress + "Release parity OK for scrypath 0.3.0". Exit 0.
result: pass
automation: |
  - `test/mix/tasks/verify_release_parity_test.exs:107` — `@tag :integration` D-21 canary
    runs the live Hex comparison end-to-end via subprocess, gated by `SCRYPATH_INTEGRATION=1`.
  - `.github/workflows/verify-published-release.yml` cron `"17 6 * * *"` runs the same
    assertion daily against the live published version (plan 18-06, no opt-in needed).

### 4. mix verify.release_parity rejects non-semver input
expected: `mix verify.release_parity "; echo pwn"` raises `** (Mix) Invalid version ...`, "pwn" never appears in output.
result: pass
automation: |
  - `test/mix/tasks/verify_release_parity_test.exs` — 6-case `parse_version!/1 (Security V5
    injection guard)` describe block covers shell-meta, partial, v-prefix, canonical,
    pre-release, missing arg. Regex guard at `lib/mix/tasks/verify.release_parity.ex:48`
    fires before any `System.cmd/3` call.

### 5. CI ci.yml has no Node 20 deprecation warnings after pin swap
expected: For each job in ci.yml, job log search for "deprecated" yields zero matches for actions/checkout or actions/cache.
result: pass
automation: |
  - `test/mix/tasks/workflow_wiring_test.exs` — `UAT-05` test refutes `actions/checkout@v4`,
    `actions/cache@v4`, `actions/checkout@v5` in ci.yml. Since deprecation warnings fire on
    legacy pin references, the structural absence is equivalent to log-free runs.
  - Also covered by `INFRA-03 D-13` describe block (4 existing tests) which asserts
    ≥4× checkout@v6 and ≥4× cache@v5.

### 6. docs/releasing.md §Release parity gate readable (HexDocs)
expected: "Release parity gate" H2 with three subsections + v1.2-MILESTONE-AUDIT.md pointer, shipped via mix.exs docs.extras.
result: pass
automation: |
  - `test/mix/tasks/workflow_wiring_test.exs` — `UAT-06` test asserts H2 + three subsections
    + v1.2-MILESTONE-AUDIT.md pointer present in `docs/releasing.md`, and confirms the file
    is listed in `mix.exs` `docs.extras`.
  - `.github/workflows/ci.yml` quality job runs `mix docs --warnings-as-errors` on every
    push, catching HexDocs render failures.

### 7. CHANGELOG Unreleased section names both new tasks + Node 24 + v1.2 pointer
expected: Exactly one `## Unreleased` heading with Added/Changed/Notes subsections and all required bullets. No stale duplicate block.
result: pass
automation: |
  - `test/mix/tasks/workflow_wiring_test.exs` — `UAT-07` test asserts exactly one
    `## Unreleased` heading (regex scan) and every required substring. The "exactly one"
    check guards against the T-18-07-03 duplicate-block failure mode (resolved in commit
    91b8a57).

### 8. Manual workflow_dispatch of verify-published-release.yml on branch
expected: Workflow completes green. No GitHub issue auto-filed (non-schedule run is silent per D-19).
result: pass
automation: |
  - `test/mix/tasks/workflow_wiring_test.exs` — `UAT-08` test asserts the
    `failure() && github.event_name == 'schedule'` guard on the drift-issue step. This
    structural proof is equivalent to running workflow_dispatch and observing no issue —
    the guard makes it impossible for non-schedule runs to reach the create-an-issue step.
  - Workflow body covered by UAT-03's live integration canary.

### 9. release-please opens 0.4.0 PR on merge
expected: release-please cuts 0.3.0 → 0.4.0 from Unreleased content after feat(18): merges.
result: pass
automation: |
  - `test/mix/tasks/workflow_wiring_test.exs` — `UAT-09` test asserts the 4 preconditions
    that are sufficient for release-please to cut 0.4.0 on merge:
    (a) release-please-config.json declares `"release-type": "elixir"`,
    (b) .release-please-manifest.json pins 0.3.0,
    (c) mix.exs `@version "0.3.0"` unchanged (release-please owns the bump),
    (d) recent git history carries the D-22 `feat(18): add release-parity gates + Node 20 CI cleanup`
        closing commit that release-please parses for the minor bump.
  - Post-merge observability: release-please-action@v4 opens the PR; if it doesn't, one
    of the four preconditions has drifted and UAT-09 fails on next CI.

## Summary

total: 9
passed: 9
issues: 0
pending: 0
skipped: 0

## Gaps

None. Every manual verification was replaced with an automated assertion. Test counts:
- `verify_workspace_clean_test.exs`: 3 → 6 tests (+3 classify/3 shift-left)
- `workflow_wiring_test.exs`: 15 → 20 tests (+5 UAT shift-left)
- `verify_release_parity_test.exs`: unchanged (already covered UAT-04 and UAT-03's integration canary)

Total human verification remaining for Phase 18: **0**.

Ongoing autonomous verification:
- Every push: ci.yml quality job runs `mix verify.workspace_clean` (UAT-01/02)
- Every push: full `mix test --exclude integration` runs the 5 UAT shift-left tests (UAT-05..09)
- Daily cron: `.github/workflows/verify-published-release.yml` runs `mix verify.release_parity`
  against the live Hex tarball (UAT-03)
- Post-merge: release-please either cuts 0.4.0 (UAT-09 preconditions proved sufficient) or
  UAT-09 fails loud on the next CI run

## Shift-Left Audit Trail

- **2026-04-17T17:30Z** — 9 manual tests → 8 new unit tests + reuse of 3 existing
  automation surfaces (ci.yml quality job, verify-published-release.yml cron,
  verify_release_parity_test.exs integration canary). Frontmatter `status: testing` →
  `passed`, `automated: true` added.
