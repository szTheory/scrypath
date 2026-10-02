# Phase 168 Plan 04 Summary

## Objective

Add a repository-only dependency audit for all four maintained Mix graphs, make its verdict fail closed on incomplete or ignored evidence, and route the existing advisory deep-quality lane through it without repeating the root audit.

## Completed

- Added `Scrypath.Repository.DependencyAudit` and a thin `elixir scripts/ci/dependency_audit.exs` CLI. The explicit inventory is root, Phoenix, ecommerce, and standalone Ops. The runner checks the exact tracked `mix.lock` set, tries every valid graph after failures, records source and lock identities, separate fetch/audit durations, selected Hex ignore state, and redacted child output.
- The worker pins the reviewed Hex 2.5.1 output contract. It keeps Hex's official advisory matcher, reports both ignore keys and their source, and rejects active or ignored findings, configured ignores, warnings, unsupported or malformed output, missing clean markers, nonzero children, fetch failures, unavailable tools, and lock drift.
- First live audit exposed EEF-CVE-2026-92106 in ecommerce and Ops through `lazy_html 0.1.12`. Updated only those two generated lock tuples to `lazy_html 0.1.13`, the release OSV marks fixed. The complete old and new Hex tuples and refreshed graph hashes are in [168-02-GRAPHS.md](168-02-GRAPHS.md). [OSV advisory](https://osv.dev/vulnerability/EEF-CVE-2026-92106).
- Extracted shared deep-quality sequencing with an internal no-audit seam. Standalone `mix verify.deep_quality` still runs one current-project audit; CI's inventory owns all four fetch/audit operations, then invokes the no-audit seam for optional-dependency verification, namespace fencing, and Dialyzer.
- Changed only the existing `deep-quality` advisory job. It pins Hex 2.5.1 and keeps its job identity, advisory posture, Elixir/OTP, and root deps/build/PLT cache. No graph cache was added; measured cold/reused costs remain Plan 05 work. The scripts remain outside the Hex package whitelist.

## Source commits

Source work is on the task-owned branch `fix/phase168-dependency-security`, based on the Plan 02 clean public-main source. Plan 04 commits:

| Commit | Change |
|---|---|
| `a2359acd57ce1af7af6be44c94cbb4d91cb661b3` | Upgrade vulnerable `lazy_html` entries in ecommerce and Ops only |
| `092148cfab0ef29592ba3ee8837f80774f5cc0b6` | Add strict four-graph audit CLI and failure-path fixtures |
| `94b0b7a47b176e0058c1610248b61309ee05ac20` | Route the advisory job through the audit and shared no-audit quality seam |

Plan 02 source base: `d4976944e8049699f31dc6769cd68d719bc4a814`. Plan 03 source commits are recorded in [168-03-SUMMARY.md](168-03-SUMMARY.md). The local combined candidate still requires Plan 05 review, hosted evidence, and protected delivery.

## Verification

- Audit fixtures and CLI: `mix test test/mix/tasks/dependency_audit_test.exs --warnings-as-errors` — **15 tests, 0 failures**. Cases include inventory omission/duplication and unexpected tracked locks, missing tools, runner exceptions, child failures, ignored and active results, unused-ignore warnings, unsupported/malformed contracts, ANSI output, secret redaction, lock changes, all-graph attempts, CLI exit behavior, and the package whitelist.
- Combined focused verification: `mix test test/mix/tasks/dependency_audit_test.exs test/mix/tasks/verify_capability_test.exs test/mix/tasks/workflow_wiring_test.exs --warnings-as-errors` — **67 tests, 0 failures**. Tests prove one audit on the standalone sequence, zero audits on the CI seam, retained checks, and scoped workflow wiring.
- Exact no-audit CI command: `MIX_ENV=test mix run --no-start -e 'Mix.Tasks.Verify.Capability.run_deep_quality_without_audit()'` — **PASS**. Optional-dependency compile, namespace fence, PLT check, and Dialyzer passed; Dialyzer reported 0 errors.
- Live inventory on source `94b0b7a47b176e0058c1610248b61309ee05ac20`: `elixir scripts/ci/dependency_audit.exs` — **exit 0**, four complete clean graph rows, Hex 2.5.1, default empty ignore values, one audit per graph, and identical before/after lock hashes. Total command wall time was 15.7 s. Exact row timings and hashes are in [168-02-GRAPHS.md](168-02-GRAPHS.md).
- After the lock update, ecommerce `mix test` passed **33 tests, 0 failures**; `mix verify.ops_ui` passed **2 doctests and 154 tests, 0 failures** with task-owned PostgreSQL. Both task-owned containers were removed. The ecommerce run logged nonfatal Req connection-refused retry messages; Ops printed existing database startup messages before the test task created its database.
- `mix format` and `git diff --check` passed for changed source/tests.

## Limits and follow-up

This plan establishes local behavior and recurring audit wiring. It does not yet establish cold-versus-reused cache cost, the actual Phoenix path/package resolved graphs, candidate required/hosted jobs, PR review/merge, or green public-main evidence. Plan 05 owns those delivery gates. No Hex publication, adopter lock change, or release identity is claimed.
