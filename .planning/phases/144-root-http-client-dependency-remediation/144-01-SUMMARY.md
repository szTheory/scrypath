---
phase: 144-root-http-client-dependency-remediation
plan: "01"
subsystem: dependencies
tags: [elixir, mix, req, dependency-security, lockfiles]
requires:
  - phase: 143
    provides: v1.35 release baseline and green-main release train
provides:
  - Atomic Req 0.6 compatibility handoff across root and checked path consumers
  - Root Plug 1.19.5 test-only floor and causal four-lock resolution
affects: [144-02, 144-03, 145, 146, 147]
tech-stack:
  added: []
  patterns: [bounded Mix dependency unlock, causal cross-graph lock alignment]
key-files:
  created: []
  modified:
    - mix.exs
    - mix.lock
    - scrypath_ops/mix.exs
    - scrypath_ops/mix.lock
    - examples/phoenix_meilisearch/mix.lock
    - examples/scrypath_ecommerce/mix.exs
    - examples/scrypath_ecommerce/mix.lock
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
decisions:
  - Kept web/framework remediation graph-local; only the Req closure and root test Plug floor moved.
metrics:
  duration: 16m
  completed_date: 2026-08-22
status: complete
---

# Phase 144 Plan 01: Shared Req-Floor Handoff Summary

Established one minimal, explained Req 0.6 compatibility handoff across the root library and its three checked-in path-consumer graphs.

## What Changed

- Reconciled the Phase 144 roadmap criterion and EVID-02 to describe the atomic three-manifest/four-lock handoff before later graph-local batches.
- Set direct Req constraints to `~> 0.6.1` in root, ScrypathOps, and ecommerce; retained no direct Req declaration in the legacy example.
- Set root's test-only Plug constraint to `~> 1.19.5`.
- Resolved every checked lock to Req 0.6.3, Finch 0.23.0, Mint 1.9.3, and hpax 1.0.4. The root additionally resolves Plug 1.19.5 and its solver-required Plug Crypto 2.2.0.

## Verification

- Passed `mix deps.get --check-locked` in root, ScrypathOps, legacy Phoenix example, and ecommerce.
- Confirmed exactly three direct Req `~> 0.6.1` declarations, root's test-only Plug `~> 1.19.5`, and no legacy direct Req declaration.
- Passed `git diff --check` and repeated the full tracer verification after the task commit.

## Causal Lock Rows

Req 0.6.3 requires the updated Req closure: Finch 0.23.0, Mint 1.9.3, and hpax 1.0.4 in all four locks. Root Plug 1.19.5 requires Plug Crypto 2.2.0. Legacy, Ops, and ecommerce retain their existing Plug, Phoenix, Bandit, Ecto, Decimal, Postgrex, LiveView, and Swoosh rows for Phases 145-147.

## Decisions Made

- Used targeted `mix deps.unlock` operations before resolution to hold every unrelated graph-local lock row stable.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking issue] Narrowed the resolver update scope
   - **Found during:** Task 1
   - **Issue:** A direct `mix deps.update req` selected unrelated web-stack package heads in consumer locks.
   - **Fix:** Restored the task-owned locks and re-resolved only unlocked Req/Finch/Mint/hpax rows (plus root Plug/Plug Crypto).
   - **Files modified:** Four lockfiles
   - **Commit:** f711521

## Self-Check: PASSED

- Confirmed all nine task-modified artifacts exist.
- Confirmed task commit `f711521` exists in git history.
