---
phase: 146-scrypathops-web-client-remediation
plan: 03
subsystem: dependency-security-evidence
tags: [elixir, mix, hex, postgrex, plug, audit]
requires:
  - phase: 146-scrypathops-web-client-remediation
    plan: 02
    provides: exact-SHA deterministic candidate gates
provides:
  - fresh detached resolution and unsuppressed audit evidence for the Ops candidate
  - validated cleanup and one-commit topology handoff
affects: [147-ecommerce-mounted-ops-remediation-and-closure-evidence]
tech-stack:
  added: []
  patterns: [lock-only Mix proof, exact-release Hex predicate, validated disposable-worktree cleanup]
key-files:
  created: [.planning/phases/146-scrypathops-web-client-remediation/146-03-SUMMARY.md]
  modified: []
key-decisions:
  - "Fresh proof accepts the solver-owned Plug 1.x selection under amended D-05 while retaining the reviewed primary lock."
requirements-completed: [SEC-03, EVID-03]
coverage:
  - id: D1
    description: "Exact candidate resolved within all approved D-05 dependency ranges and passed an unsuppressed Hex audit."
    requirement: SEC-03
    verification:
      - kind: other
        ref: "detached lock-only matrix and mix hex.audit"
        status: pass
    human_judgment: false
  - id: D2
    description: "Postgrex fixed-release status was rechecked through live Hex and EEF CNA authorities."
    requirement: EVID-03
    verification:
      - kind: other
        ref: "live Hex and EEF CNA jq predicates"
        status: pass
    human_judgment: false
duration: 0min
completed: 2026-08-24
status: complete
---

# Phase 146 Plan 03: Detached Fresh Resolution and Audit Summary

**Exact ScrypathOps candidate `59d2e6a` fresh-resolved within the approved cohort, proved its live Plug release, and passed the unsuppressed Hex audit.**

## Evidence

- UTC evidence window: `2026-08-24T21:29:29Z`.
- Live Postgrex authorities: Hex stable/unretired `0.22.4` PASS; EEF CNA affected range (`0.19.3` before `0.22.4`) PASS.
- Candidate: `59d2e6a`; detached worktree at that exact SHA with isolated Mix dependency and build paths.
- `elixir -e` lock-only D-05 matrix PASS:
  - Phoenix `1.8.12` (`>= 1.8.9 and < 1.9.0`)
  - LiveView `1.1.33` (`>= 1.1.33 and < 1.2.0`)
  - Bandit `1.12.5` (`>= 1.12.1 and < 1.13.0`)
  - Swoosh `1.26.3` (`>= 1.26.3 and < 1.27.0`)
  - Postgrex `0.22.4` (`>= 0.22.4 and < 0.23.0`)
  - Req `0.6.3` (`>= 0.6.1 and < 0.7.0`)
  - Plug `1.20.3` (`>= 1.19.5 and < 2.0.0`)
  - Mint `1.9.3` (`>= 1.9.3`)
  - hpax `1.0.4` (`>= 1.0.4`)
- Plug selected: 1.20.3; Hex exact-release predicate: PASS
- `mix hex.audit`: exit `0` (unsuppressed).

## Finalization

- Raw receipt validation: PASS — the owned, non-symlink probe parent and exact `worktree` child satisfied the required temporary-prefix and exact-child checks before cleanup and again immediately before cleanup.
- Canonical registration validation: PASS — macOS canonicalization mapped the validated temporary directory and exactly one existing registered worktree to the same canonical path.
- Disposable worktree, isolated build/dependency state, probe parent, receipt state, and locator: removed and absence-checked.
- Primary lock hash equality: PASS.
- Primary dirty-baseline equality (excluding this task-owned summary): PASS.
- Phase 145 ancestry and exactly-one implementation commit (`59d2e6a`) touching the owned Ops manifest, lock, and focused Swoosh contract: PASS before and after cleanup.
- Scope preservation: PASS — the implementation commit changes only the approved manifest, lock, and focused Swoosh contract test; no ecommerce, UI, route, schema, provider, CI, or public API surface changed.

Final handoff: PASS

## Deviations from Plan

### Execution Deviations

**1. [Bounded execution deviation] Canonicalized the validated macOS temporary worktree path for registration comparison**
- **Found during:** Task 2
- **Issue:** The receipt used macOS's `/var/...` spelling while `git worktree list` reported the equivalent `/private/var/...` canonical spelling, so a raw-string match was insufficient.
- **Fix:** After explicit authorization, canonicalized only existing, owned, non-symlink directories; required the same temporary-prefix and exact-child relationships; and removed only the uniquely canonical-matched registered worktree.
- **Verification:** One canonical registration match; cleanup absence checks; primary lock and dirty-baseline equality; ancestry, one-implementation-commit, and scope assertions all passed after cleanup.
- **Files modified:** This summary only.

**Total deviations:** 1 bounded execution deviation.
**Impact on plan:** No ownership, symlink, prefix, exact-child, or deletion-scope guard was weakened; no implementation files changed.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed the disposable worktree, probe parent, state receipt, and locator are absent.
- Confirmed primary `scrypath_ops/mix.lock` and the recorded dirty baseline remain unchanged.
- Confirmed the Phase 145 handoff remains an ancestor of `59d2e6a` and that the candidate is the sole owned implementation commit.
