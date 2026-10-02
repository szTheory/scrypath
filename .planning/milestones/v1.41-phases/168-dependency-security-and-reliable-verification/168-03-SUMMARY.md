# Phase 168 Plan 03 Summary

## Objective

Make the existing Phoenix package and path proof modes report and enforce their actual dependency graph while preserving the distinction between a locally staged Scrypath artifact and a published Hex package.

## Completed

- Added `Mix.Tasks.Verify.PhoenixExample.LockGraph`, a literal-only Mix lock parser and comparator. It normalizes atom/string package keys, rejects executable or malformed lock syntax and duplicate normalized keys, verifies required Mint/HPAX identities, compares full graph entries, checks byte preservation, and reports a safe SHA-256 plus sorted package/version identities.
- Tightened the staged package proof to compare the complete resolved graph before compile or tests. Its success fixture retains the consumer's Hex entries and substitutes only the expected Scrypath artifact entry.
- Added `Mix.Tasks.Verify.Adopter.run_live!/1` as an internal injected-runner seam. Path mode now gets the source checkout SHA, runs `mix deps.get --check-locked`, verifies the source lock bytes, reports the resolved graph, then runs tests and checks the lock again, including command-failure paths. Output redacts endpoint credentials; the fast path and CLI remain intact.
- Added adversarial parser, package-runner, path-runner, lock-drift, command-failure, preflight, identity and redaction coverage.

## Source commits

Executed on the Plan 02 task-owned security branch from public-main base `ad73b92d5883b4136fa961e134c987a95939fac2`:

- `bf0856238d2bd3de750dd8c618b868ffd3d7ea31` — package graph regression tests (RED)
- `d2cc3748406488084755d024216eb66df08d1d58` — package graph parser and proof (GREEN)
- `31ec9df14dc8713ac1a49638a800a84968a9acae` — path graph regression tests (RED)
- `7c79706c72ea0dc1de16d86bd9aa72564446a502` — Phoenix path proof (GREEN)

## Verification

- Focused command: `mix test test/mix/tasks/verify_adopter_test.exs test/mix/tasks/verify_lock_graph_test.exs test/mix/tasks/verify_phoenix_example_package_test.exs`
- Result: 30 tests, 0 failures, 1.6 seconds elapsed (measured in the task-owned clone, Elixir 1.19.5 / OTP 28.1).
- `mix format --check-formatted` and `git diff --check` passed.
- The tests confirm changed path lock bytes stop tests; failed fetches stop later stages; failed tests still check bytes; malformed or missing locks stop resolver dispatch; graph output is sorted and includes Mint/HPAX; and subprocess endpoint credentials are redacted.

## Limits and follow-up

This is service-free orchestration and parser evidence. The real Phoenix path/package service runs, combined four-graph audit, candidate PR, hosted checks, merge and post-merge evidence remain Plan 05 obligations. No Hex publication or adopter package release is claimed. The Plan 03 source commits are on the task-owned branch pending the Plan 05 integration manifest.
