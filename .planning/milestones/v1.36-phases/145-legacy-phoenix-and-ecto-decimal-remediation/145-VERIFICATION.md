---
phase: 145-legacy-phoenix-and-ecto-decimal-remediation
verified: 2026-08-22T21:20:41Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 145: Legacy Phoenix and Ecto/Decimal Remediation Verification Report

**Phase Goal:** Maintainers can run the legacy Phoenix example on a coordinated fixed-compatible Phoenix, Bandit, Ecto, Ecto SQL, and Decimal dependency set.
**Verified:** 2026-08-22T21:20:41Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A fresh legacy-example resolution selects the fixed-compatible Phoenix/Bandit/Ecto/Ecto SQL/Decimal cohort without recorded advisories. | ✓ VERIFIED | Detached, lockless resolution at `4e2abed` compiled with warnings-as-errors and selected Phoenix 1.8.12, Bandit 1.12.5, Ecto 3.14.2, Ecto SQL 3.14.0, Postgrex 0.22.4, Decimal 3.1.1, Plug 1.19.5, Req 0.6.3, Mint 1.9.3, and hpax 1.0.4—all within the required ranges. Fresh `mix hex.audit` exited 0 with no retired or advisory packages. |
| 2 | The manifest owns the necessary bounds: Phoenix `~> 1.8.9`, Bandit `~> 1.12.1`, Ecto SQL `~> 3.14.0`, Postgrex `~> 0.22.4`, and recovery Plug `~> 1.19.5`; Ecto and Decimal remain transitive. | ✓ VERIFIED | Current `mix.exs` has exactly those five direct cohort rows, no direct Ecto/Decimal row, and no override. Fresh check proved 1.19.5 is accepted and 1.20.3 is rejected by the direct Plug constraint. |
| 3 | The example's deterministic tests and required root fast regression pass with the local Scrypath path dependency. | ✓ VERIFIED | Fresh checks: `mix deps.get --check-locked`; focused compatibility suite (4 tests, 0 failures); full example `mix test` (6 tests, 0 failures); `MIX_ENV=test mix ecto.migrate --quiet`; `mix precommit`; and root `mix test --exclude integration --exclude docs_contract` (537 tests and 2 properties, 0 failures). `mix.exs` retains `{:scrypath, path: "../.."}`. |
| 4 | Existing database, migration, fixture, cast, association, timestamp, endpoint, malformed-cookie, and Bandit loopback behavior remains usable under the cohort. | ✓ VERIFIED | Freshly executed `EctoCompatibilityTest` inserts and reloads Author/Post rows through the SQL Sandbox, checks changeset errors, values, association, and timestamps. Fresh `EndpointCompatibilityTest` exercises JSON 404 and malformed cookie behavior plus a supervised loopback Bandit request and `[:bandit, :request, :stop]` telemetry (4 focused tests passed). |
| 5 | Manifest/lock changes are isolated across the completed cohort and Plug recovery commits, without Decimal override or package-head churn. | ✓ VERIFIED | `e50fbd5` changes the four declared graph/test files; immutable recovery `4e2abed` changes only `examples/phoenix_meilisearch/mix.exs`, adding one direct Plug row. `mix.lock` remains at its existing 1.19.5 resolution. Both commits are ancestors of `HEAD`; no history rewrite is present. |
| 6 | The live Postgres/Meilisearch evidence is supplemental rather than substituted for deterministic or audit proof. | ✓ VERIFIED | `145-02-SUMMARY.md` classifies the CI-shaped service run separately. This verifier independently passed deterministic and detached-audit gates before considering that narrative; no status relies on service smoke. |
| 7 | Verification cleanup preserves the primary candidate and unrelated user state. | ✓ VERIFIED | This verifier's detached probe used isolated deps/build paths, removed and pruned its validated temporary worktree, and left the only pre-existing untracked file, `.planning/v1.36-v1.36-MILESTONE-AUDIT.md`, intact. The working tree still shows no tracked modifications. |

**Score:** 7/7 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/phoenix_meilisearch/mix.exs` | Fixed-compatible direct cohort including Plug recovery bound | ✓ VERIFIED | Substantive dependency manifest; Mix reads it for both checked and fresh resolution. |
| `examples/phoenix_meilisearch/mix.lock` | Deterministic reviewed legacy resolution | ✓ VERIFIED | Checked lock accepted by `mix deps.get --check-locked`; detached lockless solver result was independently range-checked. |
| `test/scrypath_demo/ecto_compatibility_test.exs` | Real Postgres changeset/persistence contract | ✓ VERIFIED | Uses `ScrypathDemo.DataCase`, real `Repo`, fixtures, query/preload, and ran successfully. |
| `test/scrypath_demo_web/endpoint_compatibility_test.exs` | Real endpoint and Bandit listener contract | ✓ VERIFIED | Uses `ConnCase`, real endpoint, supervised loopback Bandit and Req; ran successfully. |
| `145-02-SUMMARY.md` | Compact recovery provenance | ✓ VERIFIED | Substantive record identifying both commits, deterministic versus supplemental evidence, and cleanup. It was corroborated rather than trusted. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `mix.exs` | fresh detached resolution | Direct constraints plus `Version.match?/2` assertions | ✓ WIRED | Fresh resolver selected all ten asserted packages in-range; direct Plug excludes 1.20.x. |
| `mix.exs` | `mix.lock` | `mix deps.get --check-locked` | ✓ WIRED | Command exited 0 against the current tracked lock. |
| Ecto compatibility test | Repo, schemas, migrations | `DataCase` SQL Sandbox and real `Repo.insert!/get!/preload` | ✓ WIRED | The focused test passed against the configured test Postgres database. |
| Endpoint compatibility test | Endpoint and Bandit telemetry | `ConnCase`, `start_supervised!`, Req loopback request | ✓ WIRED | Focused test received the expected 404 and telemetry event. |
| Recovery commit | deterministic and fresh-resolution proof | Exact detached SHA `4e2abed` | ✓ WIRED | The probe checked its detached `HEAD` before resolution and compilation. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Ecto compatibility test | `persisted_post` | Postgres `Repo.insert!` then `Repo.get!/preload` | Author/Post rows and migration-backed timestamps | ✓ FLOWING |
| Endpoint compatibility test | Req response and telemetry message | Loopback Bandit → `ScrypathDemoWeb.Endpoint` → Router | Actual HTTP 404 JSON response and `Plug.Conn` metadata | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Dependency cohort and checked lock | `mix deps.get --check-locked` plus Mix range assertion | All ten packages in range | ✓ PASS |
| Ecto and endpoint contracts | Focused `mix test` for both compatibility modules | 4 tests, 0 failures | ✓ PASS |
| Full deterministic example path | `mix test`, test-env migration no-op, `mix precommit` | 6 tests, 0 failures; migration exited 0 | ✓ PASS |
| Root regression | `mix test --exclude integration --exclude docs_contract` | 537 tests and 2 properties, 0 failures | ✓ PASS |
| Fresh resolver and audit | Detached `mix deps.get`, compile, assertions, `mix hex.audit` | Compile and audit exited 0 | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| Detached exact-SHA resolution | Disposable worktree at `4e2abed`; lock removed; isolated `MIX_DEPS_PATH`/`MIX_BUILD_PATH` | Resolver, compile, all ten assertions, and audit succeeded; worktree removed | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- |
| SEC-02 | 145-01, 145-02 | Resolve recorded legacy example advisories through coordinated Phoenix/Bandit and Ecto/Ecto SQL/Decimal upgrades. | ✓ SATISFIED | Verified fixed-compatible checked and fresh graph, no-advisory audit, actual persistence/endpoint behavior, and passing deterministic/root regression. |

No orphaned Phase 145 requirements were found: both plans declare SEC-02, the sole roadmap requirement for this phase.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `145-02-PLAN.md` | deterministic verification command | Bare `mix ecto.migrate --quiet` defaults to the unavailable development database in this workspace. | ℹ️ Info | The completed evidence correctly uses `MIX_ENV=test mix ecto.migrate --quiet`, after the test alias, and this verifier freshly confirmed that command. It is a plan-command precision defect, not a phase-goal gap. |
| `145-REVIEW.md` | WR-01 | Advises keeping Plug transitive. | ℹ️ Resolved | The review predates the approved recovery. Detached current-registry evidence supplied the contrary fact: without direct ownership the registry selected Plug 1.20.3, outside the `< 1.20.0` contract. Direct `~> 1.19.5` is therefore necessary, narrow, and validated—not an unresolved ownership warning. |

### Human Verification Required

None. Every behavior-dependent truth was exercised by a focused test or deterministic command in this verification.

### Gaps Summary

No blocking gaps found. The only untracked file is the user-owned milestone audit named in the phase notes; it was preserved and not modified.

---

_Verified: 2026-08-22T21:20:41Z_
_Verifier: the agent (gsd-verifier)_
