---
status: partial
phase: 91-integration-guides-and-verification
source: [91-VERIFICATION.md]
started: 2026-05-25T07:45:00Z
updated: 2026-05-25T07:45:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Live fan-out smoke tests (inline + Oban stacks)

Run both smoke tests in the Phoenix example app against live Postgres + Meilisearch:

```bash
cd examples/phoenix_meilisearch
SCRYPATH_EXAMPLE_INTEGRATION=1 mix test test/smoke/meilisearch_related_inline_stack_test.exs test/smoke/meilisearch_related_oban_stack_test.exs --trace
```

expected: Both suites pass with 0 failures. The inline test verifies `sync_related/3` resolves and re-indexes posts synchronously when `update_author/3` is called. The Oban test verifies the same fan-out via background job enqueue + drain.
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
