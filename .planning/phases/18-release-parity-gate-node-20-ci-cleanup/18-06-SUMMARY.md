---
phase: 18-release-parity-gate-node-20-ci-cleanup
plan: 06
subsystem: infra
tags: [ci, github-actions, release-parity, cron, issue-template, create-an-issue]

# Dependency graph
requires:
  - phase: 18-03
    provides: mix verify.release_parity task (the Mix task that this workflow step invokes)
provides:
  - Daily cron-triggered release_parity check in verify-published-release.yml (INFRA-02 scheduled-monitor integration)
  - Automatic drift-issue filing via JasonEtco/create-an-issue@v2 on scheduled-run failures (INFRA-04)
  - Per-version dedup via `update_existing: true` + `{{ env.VERSION }}` in issue title (D-19)
  - `issues: write` permission on verify-published-release.yml (Security V4)
  - `.github/ISSUE_TEMPLATE/release-parity-drift.md` template consumed by create-an-issue@v2
affects: [18-07, 19, 20, 21, 22, 23, v1.3-milestone]

# Tech tracking
tech-stack:
  added:
    - JasonEtco/create-an-issue@v2 (GitHub Action for auto-filing issues from templates)
  patterns:
    - Reuse existing step's `if:` guard and `env:` block when adding a sibling step (verify.release_parity inherits from verify.release_publish scaffolding)
    - Scheduled-only side effects via `failure() && github.event_name == 'schedule'` composite guard
    - Per-version issue dedup via mustache interpolation in title + `update_existing: true`
    - Principle-of-least-privilege workflow permissions (only `contents: read` + `issues: write`)

key-files:
  created:
    - .github/ISSUE_TEMPLATE/release-parity-drift.md
  modified:
    - .github/workflows/verify-published-release.yml

key-decisions:
  - "Extend existing verify-published-release.yml rather than create a new workflow (D-20 prohibits new workflow files)"
  - "Reuse SCRYPATH_RELEASE_VERIFY_ATTEMPTS/SLEEP_MS env-var names from verify.release_publish step (D-12 — no drift in retry conventions)"
  - "Guard drift-issue step on `failure() && github.event_name == 'schedule' && published == 'true'` — manual workflow_dispatch runs stay silent (D-19)"
  - "Scope permissions to `contents: read` + `issues: write` only; no pull-requests/packages/deployments (T-18-06-02 least privilege)"
  - "Issue body contains only public info: version string, public workflow run URL, pointer to already-public milestone audit doc (T-18-06-03)"
  - "No `continue-on-error: true` on release_parity step — drift MUST fail the workflow so `failure()` guard fires (T-18-06-05)"

patterns-established:
  - "Pattern: Sibling-step composition — a new step that shares the prior step's guard and env block can be inserted immediately after, preserving step granularity for per-step failure reporting"
  - "Pattern: Composite `if:` guard for scheduled-only side effects — `failure() && github.event_name == 'schedule'` cannot be forged by workflow_dispatch (T-18-06-07)"
  - "Pattern: Per-version issue dedup — `{{ env.VERSION }}` in title + `update_existing: true` + `search_existing: open` collapses repeated-run drift into one open issue per version"

requirements-completed: [INFRA-02, INFRA-04]

# Metrics
duration: 2min
completed: 2026-04-17
---

# Phase 18 Plan 06: CI Release-Parity Wire-Up Summary

**Daily cron monitor in verify-published-release.yml now runs `mix verify.release_parity` after verify.release_publish and auto-files a dedup'd GitHub issue via JasonEtco/create-an-issue@v2 on scheduled-run drift.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-17T14:05:50Z
- **Completed:** 2026-04-17T14:08:08Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- Extended `.github/workflows/verify-published-release.yml` with a `release_parity` step that runs after `verify.release_publish`, inheriting the published=true guard and SCRYPATH_RELEASE_VERIFY_ATTEMPTS/SLEEP_MS env scaffolding (D-18, D-12).
- Added drift-surfacing step using `JasonEtco/create-an-issue@v2` guarded on `failure() && github.event_name == 'schedule' && steps.resolve-version.outputs.published == 'true'` (D-19).
- Upgraded top-level workflow `permissions:` block to include `issues: write` alongside the existing `contents: read` (Security V4 / T-18-06-02).
- Created `.github/ISSUE_TEMPLATE/release-parity-drift.md` with frontmatter (title interpolating `{{ env.VERSION }}`, labels `area:release`/`severity:drift`, assignee `szTheory`) and body containing only public data.
- Turned 6 red tests GREEN in `test/mix/tasks/workflow_wiring_test.exs`: INFRA-02 (1 test — release_parity in verify-published-release.yml) and INFRA-04 (5 tests — guard, action ref, dedup, permissions, cron).

## Task Commits

Each task was committed atomically:

1. **Task 1: Create .github/ISSUE_TEMPLATE/release-parity-drift.md** — `0a26266` (feat)
2. **Task 2: Extend verify-published-release.yml with release_parity + drift-issue + issues:write** — `68c15ee` (feat)

_Note: Both tasks are TDD `tdd="true"` tasks. The RED state was the pre-existing INFRA-02 + INFRA-04 failing tests in `workflow_wiring_test.exs` authored in Plan 18-01. Task 2's commit moves those 6 tests from RED to GREEN; no separate test-scaffolding commits were needed because the tests already existed._

## Files Created/Modified
- `.github/ISSUE_TEMPLATE/release-parity-drift.md` — New issue template consumed by create-an-issue@v2 on scheduled-run drift; frontmatter uses `{{ env.VERSION }}` interpolation for per-version dedup.
- `.github/workflows/verify-published-release.yml` — Added `issues: write` to permissions, `Verify release-parity against latest published version` step, and `Open drift issue (scheduled runs only)` step (using JasonEtco/create-an-issue@v2). Existing `verify.release_publish` step, cron trigger, and all prior steps unchanged.

## Decisions Made

- **Sibling-step composition:** The new `release_parity` step is a sibling to `verify.release_publish` (not a subcommand or a merged step), so drift vs. publish failures surface as distinct workflow steps in the GitHub UI. Both share identical `if:` and `env:` scaffolding — intentional per D-18.
- **Guard composition:** The drift-issue step's `if:` combines three predicates joined by `&&`: `failure()` (parity step failed), `github.event_name == 'schedule'` (only daily cron runs file issues — manual workflow_dispatch is silent), and `steps.resolve-version.outputs.published == 'true'` (don't try to file an issue if the package isn't published yet). This matches D-19 and defends against T-18-06-07 (actor impersonation — `github.event_name == 'schedule'` is set by GitHub's scheduler, not the YAML).
- **Least-privilege permissions:** `issues: write` is added explicitly; no `pull-requests: write`, `packages: write`, or `deployments: write`. The existing `contents: read` is preserved.
- **Issue body scoped to public data:** Template body contains only the published version string, the public workflow run URL, and a pointer to the already-public milestone audit doc. No file contents, no secrets, no internal paths (T-18-06-03).

## Deviations from Plan

None — plan executed exactly as written.

Verification pipeline:
- `grep -c "mix verify.release_parity"` returns `1` ✓
- `grep -c "JasonEtco/create-an-issue@v2"` returns `1` ✓
- `grep -c "issues: write"` returns `1` ✓
- `grep -c "contents: read"` returns `1` ✓ (preserved)
- `grep -qF "failure() && github.event_name == 'schedule'"` matches ✓
- `grep -q "update_existing: true"` matches ✓
- `grep -qE -- "- cron:"` matches ✓ (cron trigger preserved)
- Line ordering check (awk): verify.release_publish (L81) < verify.release_parity (L88) < JasonEtco/create-an-issue (L92) ✓
- No `continue-on-error: true` on release_parity step ✓ (T-18-06-05)
- `mix test test/mix/tasks/workflow_wiring_test.exs`: INFRA-02 (1 test) + INFRA-04 (5 tests) all GREEN ✓

## Issues Encountered

### Out-of-scope pre-existing failures in workflow_wiring_test.exs (not caused by this plan)

`mix test test/mix/tasks/workflow_wiring_test.exs` reports **3 remaining failures**, all in the INFRA-01 `describe` block (`workspace_clean` gate):
- `ci.yml quality job runs mix verify.workspace_clean`
- `publish-hex.yml runs mix verify.workspace_clean`
- `release-please.yml publish-hex job runs mix verify.workspace_clean`

These are **out of scope** for Plan 18-06. They fail because `mix verify.workspace_clean` has not yet been wired into the three CI workflow files — that is the responsibility of a sibling plan (Plan 18-02 or similar INFRA-01-owning plan). The worktree base `b215693` (post-wave-2) does not include that wiring. These failures were present before this plan's changes and remain unchanged by this plan's commits. Per the execute-plan scope boundary, we do not auto-fix issues outside the current plan's changes.

Verified scope of this plan: Plan 06's scoped test count is `1 (INFRA-02) + 5 (INFRA-04) = 6 tests` — all 6 turn GREEN (8 failures pre-plan → 3 failures post-plan, delta = 5 INFRA-04 + 1 INFRA-02 = 6 tests fixed).

## User Setup Required

None — no external service configuration required. The `create-an-issue@v2` action uses the automatically-provisioned `${{ secrets.GITHUB_TOKEN }}` (no separate PAT needed), and the new `issues: write` permission is scoped to the workflow-level permissions block.

## Threat Flags

None — no new security-relevant surface beyond what the plan's `<threat_model>` already covered (T-18-06-01 through T-18-06-07). All threats are `mitigate` disposition and implemented as described in the plan.

## Known Stubs

None — no placeholder values, no TODO/FIXME markers, no data-source gaps. The issue template body uses mustache interpolations (`{{ env.X }}`) that are intentionally resolved by `create-an-issue@v2` at issue-filing time using standard GitHub Actions env vars (`GITHUB_SERVER_URL`, `GITHUB_REPOSITORY`, `GITHUB_RUN_ID`) plus the `VERSION` env set by the workflow step.

## TDD Gate Compliance

Plan type is `execute` (not `tdd`), so the plan-level RED/GREEN/REFACTOR commit gate does not apply. However, both tasks declare `tdd="true"`:
- **RED phase:** Pre-existing failing tests in `test/mix/tasks/workflow_wiring_test.exs` (INFRA-02 + INFRA-04 describes authored by Plan 18-01) — no new test commits required.
- **GREEN phase:** `feat(18-06): add release-parity drift issue template` (0a26266) and `feat(18-06): wire release_parity + drift-issue steps into published-release monitor` (68c15ee) — both GREEN commits flip the 6 scoped red tests to green.
- **REFACTOR phase:** Not needed — implementations are minimal and idiomatic.

## Self-Check

**Files claimed:**
- `.github/ISSUE_TEMPLATE/release-parity-drift.md` — FOUND
- `.github/workflows/verify-published-release.yml` (modified) — FOUND (now 100 lines with release_parity + drift-issue steps)

**Commits claimed:**
- `0a26266` (Task 1) — FOUND
- `68c15ee` (Task 2) — FOUND

**Test state claimed:**
- INFRA-02 (1 test) + INFRA-04 (5 tests) GREEN — VERIFIED (pre-plan: 8 failures; post-plan: 3 failures; the 3 remaining are INFRA-01 out-of-scope)

## Self-Check: PASSED

## Next Phase Readiness

- INFRA-02 scheduled-monitor integration fully wired — the daily 06:17 UTC cron now mechanically detects tag-vs-Hex drift on the latest published `scrypath` version.
- INFRA-04 fully closed — cron trigger + release_parity step + drift-issue filing + issues:write permission all in place.
- Plan 18-07 can now close the phase with confidence that the load-bearing parity gate is live end-to-end.
- Once Plan 18-02 (or its equivalent) wires `mix verify.workspace_clean` into the three CI workflow files, the full `workflow_wiring_test.exs` suite will be 15/15 green.
- No blockers for downstream feature phases (19–23); the release-parity gate is operational for every future publish.

---
*Phase: 18-release-parity-gate-node-20-ci-cleanup*
*Plan: 06*
*Completed: 2026-04-17*
