---
phase: 144-root-http-client-dependency-remediation
plan: 02
subsystem: testing
tags: [elixir, req, req-test, telemetry, meilisearch, compatibility]
requires:
  - phase: 144-01
    provides: Req 0.6.3 and the shared checked dependency floor
provides:
  - Causal Req.Test coverage for transport errors, default/caller headers, and task filters
  - Request-error telemetry privacy coverage that excludes API keys and payload data
affects: [144-03, 145-legacy-phoenix-and-ecto-decimal-remediation]
tech-stack:
  added: []
  patterns: [Req.Test plug boundary, public tagged error tuples, telemetry metadata redaction]
key-files:
  created: []
  modified:
    - test/scrypath/meilisearch/client_test.exs
    - test/scrypath/telemetry_test.exs
decisions:
  - Kept the Req 0.6 compatibility proof at Scrypath public boundaries; no private client change was needed.
  - Reserved configured Swoosh Req-client runtime proof for Phase 146.
metrics:
  duration: 5m
  completed_date: 2026-08-22
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 144 Plan 02: Req Client Compatibility Boundaries Summary

Focused Req.Test and telemetry coverage proves the Req 0.6 client boundary preserves transport, header, filter, and privacy contracts without changing production source.

## Completed Tasks

1. **Close the causal Req.Test and telemetry compatibility gaps** — Added four focused regression cases for retry-disabled transport errors, additive API-key/caller headers, single comma-separated task filters, and error-span metadata privacy.

## Verification

- `mix format --check-formatted test/scrypath/meilisearch/client_test.exs test/scrypath/telemetry_test.exs` — passed.
- `mix test test/scrypath/meilisearch/client_test.exs test/scrypath/telemetry_test.exs --exclude integration --exclude docs_contract` — passed (13 tests, 0 failures).
- `git diff -- lib/scrypath/meilisearch/client.ex` — empty; the checked Req 0.6.3 seam already met all focused public-boundary cases.

## Decisions Made

- Keep the existing private request construction, normalization, and telemetry seam unchanged because the added causal cases passed on Req 0.6.3.
- Do not add Swoosh, compression, multipart, retry-default, redirect-default, timeout-default, or public transport coverage; those are out of this plan's contract.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Test assertion] Corrected the expected transport-error metadata identity**
   - **Found during:** Task 1
   - **Issue:** The first telemetry assertion expected a lowercase `transport_error` string, but the existing boundary emits the inspected `%Req.TransportError{}` identity.
   - **Fix:** Assert the stable `Req.TransportError` identity while retaining explicit secret and payload exclusion checks.
   - **Files modified:** `test/scrypath/telemetry_test.exs`
   - **Verification:** Focused Req.Test/telemetry command passed with 13 tests.
   - **Commit:** aebfb8d

**Total deviations:** 1 auto-fixed (Rule 1 test assertion). **Impact:** No production behavior changed.

## Known Stubs

None.

## Self-Check: PASSED

- Both modified test files exist.
- Task commit `aebfb8d` exists and contains the focused regression coverage.
