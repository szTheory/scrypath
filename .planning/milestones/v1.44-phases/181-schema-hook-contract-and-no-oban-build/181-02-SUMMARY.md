---
phase: 181-schema-hook-contract-and-no-oban-build
plan: 02
subsystem: schema-contract
status: complete
tags: [behaviour, optional-callbacks, compile-check, hexdocs, elixir-1.19]
requires: [181-01]
provides:
  - "Scrypath.Schema callbacks search_document/1, search_document_id/1, search_records/2 (@optional_callbacks, each with @doc)"
  - "@behaviour Scrypath.Schema and @before_compile Scrypath.Schema injected by use Scrypath"
  - "Scrypath.Schema.__before_compile__/1 wrong-arity warning (IO.warn, located at the def line)"
  - "Drift guard tying lib/ function_exported? probes to the callback list"
affects: [every use Scrypath module, Scrypath.Schema HexDocs page]
tech-stack:
  added: []
  patterns: ["@before_compile arity check over Module.definitions_in/2", "Code.with_diagnostics/1 fixture tests", "source-scan drift guard"]
key-files:
  created: []
  modified:
    - lib/scrypath/schema.ex
    - test/scrypath/schema_test.exs
    - .planning/PROJECT.md
decisions:
  - "A1: wrong-arity hooks produce a compiler warning (IO.warn), never a raise, so only --warnings-as-errors builds fail (reversible)"
  - "Hooks live on Scrypath.Schema (the module use Scrypath delegates to); no separate Hooks module; no guide/README edits this phase"
metrics:
  duration: "~20 min"
  completed: 2026-10-26
requirements_completed: [HYG-01]
actuals:
  tokens: 4000
  tasks: 3
  commits: 4
plan_head_before: 906b4a86f2ab4286d77bd837168afa8689870cfb
plan_head_after: bc983d21b3dce41e2272f2ffd560a0ee49f8e54e
---

# Phase 181 Plan 02: Schema Hook Contract Summary

`Scrypath.Schema` now declares `search_document/1`, `search_document_id/1` and `search_records/2` as documented `@optional_callbacks`, so they appear under Callbacks on its HexDocs page. `use Scrypath` injects `@behaviour Scrypath.Schema` and `@before_compile Scrypath.Schema`. A `__before_compile__/1` check emits one `[scrypath] ... defines search_records/1 but Scrypath calls search_records/2; the hook is ignored at runtime` warning per hook name, located at the offending `def` line. Runtime dispatch (`function_exported?` in Identity, Projection, Loader) is unchanged.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | Tracer: optional callbacks, injected behaviour, located wrong-arity warning | addf32cb (test RED), 58a73bcb (GREEN) |
| 2 | Edge cases, drift guard, moduledoc Hooks section | f9e6eee7 |
| 3 | PROJECT.md HYG-01 claim, phase gates | bc983d21 |

## Verification (local, Elixir 1.19.0 / OTP 28.1)

- `mix test test/scrypath/schema_test.exs`: 20 tests, 0 failures
- Task 2 set (schema, identity, projection, loader, sync): 70 tests, 0 failures
- `mix compile --warnings-as-errors --force`: exit 0, 0 `warning:` lines (148 files)
- `mix docs --warnings-as-errors`: exit 0, 0 warnings (the `c:` autolinks resolve)
- `mix verify.core --exclude integration --exclude docs_contract`: exit 0; 948 tests, 0 failures; "Standard Maturity Gate: PASSED"; "Verified optional dependencies absent from isolated build: oban". The only `warning:` lines are the existing runtime `tenant_field` log lines from tests.
- `mix verify.package`: exit 0; 81 tests, 0 failures
- Tracer gate: Task 1 verify re-run end to end after GREEN (tests plus forced strict compile) passed before expansion.
- Still due: exact-SHA hosted CI evidence at the PR (core, package, and the ecommerce-mounted and ops-ui lanes that compile the example and ops apps with the injected behaviour).

## A4 adopter check

`grep -c "@impl"` returns 0 for `examples/scrypath_ecommerce/lib/scrypath_ecommerce/catalog/product.ex`, `variant.ex` and `scrypath_ops/test/support/ops_schemas.ex`. All their hooks use the expected arities (`search_document/1`, `search_records/2`). `category.ex` defines `search_records/2` but does not `use Scrypath`, so it gets no behaviour.

## TDD Gate Compliance

- Task 1: RED commit addf32cb (4 of the 5 new tests failed: no `behaviour_info`, no callback docs, no injected behaviour, no diagnostic; the correct-arity case is a guard and passed), then GREEN in 58a73bcb.
- Task 2: tests and docs in one commit (f9e6eee7). The six cases passed on first run against the Task 1 implementation; they are no-false-positive and drift guards, so no RED phase was possible without breaking working code.

## Deviations from Plan

None. Environment setup only: `mix deps.get` from the existing `mix.lock` (lock unchanged), and commands ran with `ASDF_ELIXIR_VERSION=1.19.0-otp-28 ASDF_ERLANG_VERSION=28.1`. `.planning/PROJECT.md` line 40 was left as is: it is intent-list text and does not contradict the checked item.

## Known Stubs

None.

## Self-Check: PASSED

- `lib/scrypath/schema.ex`, `test/scrypath/schema_test.exs`, `.planning/PROJECT.md` modified and present; commits addf32cb, 58a73bcb, f9e6eee7, bc983d21 are ancestors of HEAD.
