---
phase: 181-schema-hook-contract-and-no-oban-build
fixed_at: "2026-10-26T17:13:02Z"
review_path: .planning/phases/181-schema-hook-contract-and-no-oban-build/181-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
source_sha: c47c1216d0ae2e5c491751551f9aa019c619b3c6
---

# Phase 181: Code Review Fix Report

All three warning findings are fixed. The five informational findings remain open
in the disposition ledger; this report does not claim a clean independent review.
Fixes and verification ran inline in the main checkout at
`/Users/jon/projects/scrypath`, branch `planning/v1.44-new-milestone`.
The pre-existing `.planning/config.json` edit was preserved and excluded from commits.

## Fixed Issues

### WR-01: `search_document_id/1` callback doc says enqueue returns an error tuple, but it raises

**Files modified:** `lib/scrypath/schema.ex`, `test/scrypath/oban/enqueue_test.exs`
**Commit:** `ee543836`

The callback now documents that enqueueing an upsert raises `ArgumentError` before
inserting a job when a custom document id has no `search_records/2`. A public
`Scrypath.sync_record/3` test pins the exception and absence of an insert.
Delete jobs do not require this loader, so the wording names upserts explicitly.

### WR-02: Adding `@behaviour Scrypath.Schema` creates new warnings for existing adopters, and no upgrade note mentions it

**Files modified:** `CHANGELOG.md`, `test/scrypath/schema_test.exs`
**Commits:** `1e2193bc`, `66598ccd`

The existing Unreleased section explains missing-`@impl` diagnostics, their effect
under `--warnings-as-errors`, and public hook visibility. Mixed-behaviour fixtures
prove all three unannotated hooks warn and `@impl Scrypath.Schema` resolves them.
The repository contract caught a duplicate Unreleased heading in the first edit;
the follow-up moved the note into the existing section before the full gates ran.

### WR-03: HYG-02 `no_warn_undefined` guard misses the keyword and multi-line `@compile` forms

**File modified:** `test/mix/tasks/workflow_wiring_test.exs`
**Commit:** `c47c1216`

The guard walks parsed source rather than matching a single-line tuple. It checks
literal suppression pairs wherever declared, including `Module.put_attribute/3`,
and rejects unmatched option atoms and dynamic targets. Regression cases cover
tuple, multiline, keyword, list, module, MFA, blanket and dynamic forms. Literal
Oban module/MFA targets pass; other namespaces fail. No source is evaluated.

## Verification

All commands ran on Elixir `1.19.0-otp-28` / OTP `28.1` using
`ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1`.

| Command | Result |
|---------|--------|
| Focused enqueue, schema and workflow-wiring tests, `--warnings-as-errors` | 90 tests, 0 failures |
| `mix verify.core --exclude integration --exclude docs_contract` | 953 tests, 5 properties, 0 failures; format, workspace-clean, compile, Credo and docs pass |
| Isolated no-Oban compile, composed into that core gate | 148 files compiled; `Verified optional dependencies absent from isolated build: oban` |
| `mix verify.package` | 81 tests, 0 failures; workflow contract and unpacked Hex build pass |
| `mix test --warnings-as-errors test/scrypath/docs_contract_test.exs test/release/package_metadata_test.exs --include docs_contract` | 79 tests, 0 failures |

The core run also covers the real Oban Lite uniqueness cases. These are local
results for the source above. Hosted core/backend/mounted checks and milestone
attestation remain shipping work; no hosted or independent-review result is claimed.
