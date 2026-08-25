---
phase: 144-root-http-client-dependency-remediation
plan: "03"
subsystem: dependency-security-evidence
tags: [elixir, mix, hex, dependency-security, release-train]
requires:
  - 144-01-SUMMARY.md
  - 144-02-SUMMARY.md
provides:
  - Deterministic and current-registry proof for the reviewed root candidate
affects:
  - Phase 145 start gate
tech_stack:
  added: []
  patterns:
    - Exact-SHA detached lockless dependency probe with isolated Mix paths
key_files:
  created:
    - .planning/phases/144-root-http-client-dependency-remediation/144-03-SUMMARY.md
  modified: []
decisions:
  - Required service-free release-train gates are deterministic evidence; a local Meilisearch smoke remains supplemental.
  - Fresh registry resolution is proven only from a detached worktree at the reviewed SHA and never changes the tracked root lock.
metrics:
  duration: "~7m"
  tasks_completed: 2
  files_created: 1
completed: 2026-08-22
status: complete
requirements-completed: [SEC-01, COMPAT-02]
---

# Phase 144 Plan 03: Deterministic Gates and Exact-Candidate Audit Summary

The reviewed root candidate passed the complete deterministic release-train bundle and a detached, lockless current-Hex resolution/audit at the same SHA.

## Evidence Record

### Candidate and Environment

- **Candidate SHA:** `23b8b834e8648eb97e76561f933556a4b6b04f96`
- **UTC evidence finalized:** `2026-08-22T16:28:56Z`
- **Host:** Darwin 25.5.0 arm64
- **Elixir / OTP:** Elixir 1.19.5 / OTP 28
- **Mix / Hex:** Mix 1.19.5 / Hex 2.5.1
- **Tracked primary worktree:** clean before and after every required proof; root `mix.lock` SHA-256 remained `97d980f6effe1e6c263a2643c691e0801a7eb70275d7db90c228ae40848cb488`.

### Deterministic Checked-Lock and Root Release-Train Proof

All commands below exited `0` on candidate `23b8b834e8648eb97e76561f933556a4b6b04f96`.

| Command | Exit | Classification |
| --- | --- | --- |
| `mix deps.get --check-locked` | 0 | deterministic |
| `cd scrypath_ops && mix deps.get --check-locked` | 0 | deterministic |
| `cd examples/phoenix_meilisearch && mix deps.get --check-locked` | 0 | deterministic |
| `cd examples/scrypath_ecommerce && mix deps.get --check-locked` | 0 | deterministic |
| `mix deps.get` | 0 | deterministic |
| `mix compile --warnings-as-errors` | 0 | deterministic |
| `mix test --exclude integration --exclude docs_contract` | 0 | deterministic |
| `mix verify --exclude integration` | 0 | deterministic |
| `mix verify.phase11` | 0 | deterministic |
| `mix verify.phase99` | 0 | deterministic |

Plan 01's bounded manifest/lock handoff was also inspected as a clean nine-file, 24-row-pair change. Plan 02's focused Req.Test and telemetry compatibility suite is present in its committed summary. No Swoosh runtime proof is claimed; that remains Phase 146 scope.

### Supplemental Live Smoke

`http://127.0.0.1:7700/health` was unavailable (connection refused), so `mix verify.meilisearch_smoke` was not run. This is recorded as **unavailable**, not a pass, and does not replace the required service-free proof.

### Current-Registry Detached Probe

The network-dependent probe created a disposable `/tmp/scrypath-phase144.*` detached worktree at the candidate SHA, removed only that worktree's root `mix.lock`, and used `.phase144_deps` and `.phase144_build` inside it for every Mix operation. Its detached HEAD matched the recorded SHA. The worktree was removed and pruned after the audit.

| Command | Exit | Classification |
| --- | --- | --- |
| isolated `mix deps.get` after detached root-lock removal | 0 | network-dependent |
| isolated `mix compile --warnings-as-errors` (enables lock inspection in the empty isolated build) | 0 | network-dependent |
| isolated `mix run --no-compile --no-deps-check` version-bound assertion | 0 | network-dependent |
| isolated `mix deps.tree --format plain` path inspection | 0 | network-dependent |
| unsuppressed isolated `mix hex.audit` | 0 | network-dependent |

| Package | Fresh version | Required bound | Compact path |
| --- | --- | --- | --- |
| Req | 0.6.3 | `>= 0.6.1, < 0.7.0` | root → Req |
| Plug | 1.19.5 | `>= 1.19.5, < 1.20.0` | root test dependency → Plug |
| Mint | 1.9.3 | `>= 1.9.3` | root → Req → Finch → Mint |
| hpax | 1.0.4 | `>= 1.0.4` | root → Req → Finch → Mint → hpax |

The detached probe retained no lock, generated tree, raw command log, or advisory snapshot in the repository. The unsuppressed root audit exit was `0`.

## Task Completion

1. **Run deterministic checked-lock and root release-train bundle** — complete; all four graph lock checks and six root gates passed.
2. **Prove exact-candidate fresh resolution and unsuppressed root audit** — complete; all bounds, dependency paths, cleanup, and audit requirements passed.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 3 - Blocking environment state] Rebuilt stale local Mix artifacts before deterministic verification**
   - **Found during:** Task 1
   - **Issue:** The first root compile could not expand the existing `Scrypath.Document` struct despite the source module being present; a clean rebuild succeeded without source changes.
   - **Fix:** Ran `mix clean` and re-ran the entire deterministic bundle from the clean generated build state.
   - **Files modified:** None (generated build artifacts only).
   - **Verification:** The full required bundle subsequently exited 0 with a clean tracked worktree.

2. **[Rule 3 - Probe prerequisite] Compiled only inside the disposable worktree before the prescribed no-compile lock assertion**
   - **Found during:** Task 2
   - **Issue:** A lockless fresh worktree has no `scrypath.app`, so `mix run --no-compile --no-deps-check` cannot start the application before any isolated compilation.
   - **Fix:** Added isolated `mix compile --warnings-as-errors` immediately before the unchanged no-compile assertion; no primary files or locks were touched.
   - **Files modified:** None (disposable worktree only).
   - **Verification:** The bound assertion, dependency-path inspection, and unsuppressed audit all exited 0; the worktree was removed.

**Total deviations:** 2 auto-fixed (2 Rule 3 blockers). **Impact:** No product, dependency, public API, or tracked-lock change.

## Known Stubs

None.

## Self-Check: PASSED

- `144-03-SUMMARY.md` exists at the planned path.
- Candidate SHA and the prior Phase 144 plan commits are present in Git history.
- The disposable worktree has no remaining registration and the tracked primary workspace is clean.
