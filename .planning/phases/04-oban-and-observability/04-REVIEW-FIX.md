---
phase: 04-oban-and-observability
fixed_at: 2026-04-16T02:17:26Z
review_path: .planning/phases/04-oban-and-observability/04-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 04: Code Review Fix Report

**Fixed at:** 2026-04-16T02:17:26Z
**Source review:** `.planning/phases/04-oban-and-observability/04-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 2
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: `Scrypath.Oban` calls the wrong insert signature for real named Oban modules

**Files modified:** `lib/scrypath/oban.ex`, `test/scrypath/oban_test.exs`
**Commit:** `7829893`
**Applied fix:** `Scrypath.Oban.insert_multi_job/4` now distinguishes the raw `Oban` module from named modules created with `use Oban`, and the focused test file now covers the named-module multi insert signature with a real `use Oban` test module.
**Verification run:** `mix test test/scrypath/oban_test.exs`

### WR-02: The optional Oban dependency is not actually optional at compile time

**Files modified:** `lib/scrypath/config.ex`, `lib/scrypath/oban.ex`, `lib/scrypath/oban/enqueue.ex`, `lib/scrypath/oban/upsert_worker.ex`, `lib/scrypath/oban/delete_worker.ex`, `test/scrypath/oban_test.exs`
**Commit:** `33a4d58`
**Applied fix:** Added compile-time guards around the worker modules, removed the hard `Oban.Job` type dependency from enqueue code, enforced Oban readiness before building or enqueueing jobs, and added a fresh-process compile check that excludes Oban from the code path.
**Verification run:** `mix test test/scrypath/oban_test.exs test/scrypath/oban/enqueue_test.exs test/scrypath/oban/worker_test.exs test/scrypath/sync_test.exs`

---

_Fixed: 2026-04-16T02:17:26Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
