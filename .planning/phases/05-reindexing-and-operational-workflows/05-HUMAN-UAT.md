---
status: partial
phase: 05-reindexing-and-operational-workflows
source:
  - 05-VERIFICATION.md
started: 2026-04-16T13:15:53Z
updated: 2026-04-16T13:15:53Z
---

## Current Test

awaiting human testing

## Tests

### 1. Real Meilisearch rebuild
expected: `Scrypath.reindex/2` creates the target index, applies settings, backfills batches, and leaves the live index untouched when `cutover?: false`.
result: pending

### 2. Operator docs readability
expected: README and ARCHITECTURE clearly distinguish backfill vs reindex, accepted work vs search-visible completion, drift signals, cutover behavior, and recovery steps.
result: pending

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
