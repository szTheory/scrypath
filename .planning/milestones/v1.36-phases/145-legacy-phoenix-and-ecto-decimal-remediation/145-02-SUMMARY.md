---
phase: 145-legacy-phoenix-and-ecto-decimal-remediation
plan: 02
subsystem: dependency security
tags: [elixir, phoenix, ecto, plug, hex, audit]
requires:
  - phase: 145-01
    provides: fixed-compatible legacy Phoenix/Ecto graph and compatibility contracts
provides:
  - Direct Plug 1.19.x manifest ownership for the legacy Phoenix example
  - Exact-candidate deterministic, detached audit, and live-stack evidence
affects: [phase-146, phase-147, dependency-remediation]
tech-stack:
  added: []
  patterns: [direct dependency boundary, detached lockless resolution, compact audit evidence]
key-files:
  created:
    - .planning/phases/145-legacy-phoenix-and-ecto-decimal-remediation/145-02-SUMMARY.md
  modified:
    - examples/phoenix_meilisearch/mix.exs
key-decisions:
  - "Directly bound Plug at ~> 1.19.5 so fresh legacy resolutions cannot select Plug 1.20.x."
  - "Kept the reviewed lock unchanged because it already selected Plug 1.19.5."
requirements-completed: [SEC-02]
coverage:
  - id: D1
    description: "Legacy manifest directly owns Plug 1.19.x without direct Ecto or Decimal ownership."
    requirement: SEC-02
    verification:
      - kind: integration
        ref: "examples/phoenix_meilisearch: mix deps.get --check-locked, manifest/lock assertion, mix precommit"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exact recovery candidate passes deterministic, fresh-resolution, unsuppressed audit, and supplemental live-stack proof."
    requirement: SEC-02
    verification:
      - kind: integration
        ref: "recovery SHA 4e2abed: legacy deterministic gates, detached mix deps.get/compile/hex.audit, CI-shaped live test"
        status: pass
    human_judgment: false
duration: 2m 25s
completed: 2026-08-22
status: complete
---

# Phase 145 Plan 02: Direct Plug Boundary Recovery Summary

**The legacy Phoenix manifest now directly bounds Plug to the reviewed 1.19.x line, with exact-SHA deterministic, fresh-resolution audit, and live-stack evidence all passing.**

## Performance

- **Duration:** 2m 25s
- **Started:** 2026-08-22T21:07:55Z
- **Completed:** 2026-08-22T21:10:20Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added the approved direct `{:plug, "~> 1.19.5"}` requirement while leaving Phoenix, Bandit, Ecto SQL, Postgrex, Ecto, Decimal, and the reviewed lock disposition intact.
- Re-ran the full deterministic sequence at recovery SHA `4e2abed28feaef10a1f1d9b3be0fe0d236c9e478`, including a clean test database, test-environment migration no-op, legacy precommit, and root fast suite.
- Performed a detached lockless exact-SHA resolution: all ten bounded packages selected compatible versions, compilation passed, the direct Plug path was present, and unsuppressed `mix hex.audit` reported no advisories.
- Ran the documented CI-shaped Postgres + Meilisearch smoke separately; all 10 tests passed.

## Recovery History and Lock Disposition

| Commit | Role |
| --- | --- |
| `e50fbd5694c75ff5f25c2a07046185f35c107dd9` | Immutable Plan 145-01 fixed-compatible legacy graph implementation. |
| `4e2abed28feaef10a1f1d9b3be0fe0d236c9e478` | Recovery commit adding direct Plug `~> 1.19.5` ownership. |

The recovery diff is one `mix.exs` requirement. `mix.lock` stayed byte-identical at `3bd129e6b7128a34dae48c5ca3691f71a0166cb41a7d09919765d9c4487095d6`, because the checked lock already selected Plug `1.19.5`.

## Verification Evidence

### Environment

| Item | Value |
| --- | --- |
| UTC evidence window | 2026-08-22T21:07:55Z to 2026-08-22T21:10:20Z |
| Host | MacBook-Pro.local |
| Elixir / OTP | Elixir 1.19.5 / OTP 28.4.1 |
| Mix / Hex | 1.19.5 / 2.5.1 |

### Deterministic Recovery Gates

| Command | Exit | Classification |
| --- | --- | --- |
| `mix deps.get --check-locked` | 0 | deterministic checked lock |
| direct Plug manifest and checked-lock preflight | 0 | deterministic boundary ownership |
| `mix test` | 0 | deterministic clean test database, 6 tests passed |
| `MIX_ENV=test mix ecto.migrate --quiet` | 0 | deterministic already-migrated no-op |
| `mix precommit` | 0 | deterministic legacy precommit, 6 tests passed |
| root `mix test --exclude integration --exclude docs_contract` | 0 | deterministic root regression, 537 tests and 2 properties passed |
| `Version.match?/2` explicit boundary matrix | 0 | deterministic floors, in-range neighbors, and finite ceilings |

The first bare migration attempt selected the absent development database and exited nonzero. This was corrected without any source change by explicitly using the test environment required by the preceding `mix test` alias; the successful no-op above is the binding D-17 evidence.

### Detached Current-Registry and Audit Proof

The detached worktree was created at recovery SHA `4e2abed`, removed only its disposable example lock, and used isolated `MIX_DEPS_PATH` and `MIX_BUILD_PATH` directories. `mix deps.get`, `mix compile --warnings-as-errors`, all ten actual-version assertions, compact dependency-tree inspection, and unsuppressed `mix hex.audit` each exited 0.

| Package | Fresh version | Required bound | Compact path |
| --- | --- | --- | --- |
| Phoenix | 1.8.12 | `>= 1.8.9 and < 1.9.0` | direct |
| Bandit | 1.12.5 | `>= 1.12.1 and < 1.13.0` | direct |
| Ecto | 3.14.2 | `>= 3.14.0 and < 3.15.0` | `ecto_sql` |
| Ecto SQL | 3.14.0 | `>= 3.14.0 and < 3.15.0` | direct |
| Postgrex | 0.22.4 | `>= 0.22.4 and < 0.23.0` | direct |
| Decimal | 3.1.1 | `>= 3.0.0` | `ecto_sql` / `postgrex` |
| Plug | 1.19.5 | `>= 1.19.5 and < 1.20.0` | direct |
| Req | 0.6.3 | `>= 0.6.1 and < 0.7.0` | `scrypath` |
| Mint | 1.9.3 | `>= 1.9.3` | `scrypath -> req -> finch` |
| hpax | 1.0.4 | `>= 1.0.4` | `scrypath -> req -> finch -> mint` |

`mix hex.audit` result: `No retired or security advisory packages found` (exit 0, no ignore or suppression option). Decimal behavior remains deliberately delimited to dependency selection: the example has no Decimal-valued application field.

### Supplemental Live Smoke

| Prerequisites | Command | Exit | Classification |
| --- | --- | --- | --- |
| Postgres `127.0.0.1:5433` reachable; Meilisearch `127.0.0.1:7700/health` healthy | `SCRYPATH_EXAMPLE_INTEGRATION=1 PGPORT=5433 SCRYPATH_MEILISEARCH_URL=http://127.0.0.1:7700 mix deps.get && mix test` | 0 | supplemental passed; 10 tests passed |

## Cleanup and Preservation

- The detached worktree, its lock, and isolated build/dependency paths were removed; `git worktree prune` completed.
- Primary `examples/phoenix_meilisearch/mix.lock` hash was unchanged before and after probing: `3bd129e6b7128a34dae48c5ca3691f71a0166cb41a7d09919765d9c4487095d6`.
- The unrelated untracked `.planning/v1.36-v1.36-MILESTONE-AUDIT.md` remained present with the same SHA-256 before and after: `dd220c2263c182b834edd5b60b16fa7a07456c1f07adaa991de2ac7206cffcf1`.
- Tracked state was clean before writing this summary; no raw logs, detached locks, dependency trees, advisory snapshots, service artifacts, or disposable paths were retained.

## Task Commits

1. **Task 1: Commit the direct Plug boundary as the atomic recovery candidate** — `4e2abed` (`fix`)
2. **Task 2: Rerun deterministic proof, then exact-SHA audit and supplemental smoke** — this summary records the completed evidence.

## Decisions Made

- Added direct Plug ownership as the approved narrow D-01 recovery amendment; no override, direct Ecto/Decimal dependency, compatibility source change, policy layer, CI topology, route, schema, or API change was introduced.
- Kept the checked lock because the existing selected Plug `1.19.5` already satisfied the new direct bound.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Bound the no-op migration to the test database**
- **Found during:** Task 2
- **Issue:** A bare `mix ecto.migrate --quiet` selected the absent development database after the test alias had migrated the test database.
- **Fix:** Re-ran the no-op as `MIX_ENV=test mix ecto.migrate --quiet`, matching the database created by the required preceding test alias.
- **Files modified:** None
- **Verification:** The test-environment migration exited 0 before precommit and root regression gates.
- **Committed in:** Not applicable; execution-only correction.

**Total deviations:** 1 auto-fixed (Rule 3).
**Impact on plan:** The correction preserved the intended D-17 ordering and required no source or dependency change.

## Known Stubs

None.

## Self-Check: PASSED

- Recovery manifest exists and contains the direct Plug requirement.
- Recovery commit `4e2abed` exists in history.
- Summary exists at the planned phase path.

## Next Phase Readiness

Phase 145 is complete with a fixed-compatible, audited legacy graph and separate live-stack evidence. Phase 146 can proceed without reopening the immutable Plan 145-01 history.

---
*Phase: 145-legacy-phoenix-and-ecto-decimal-remediation*
*Completed: 2026-08-22*
