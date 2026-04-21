---
status: passed
phase: 47-verification-hardening
updated: 2026-04-21
---

# Phase 47 verification

## Automated

- `cd scrypath_ops && mix test` — pass (26 tests)
- `mix verify.opsui` (repo root) — pass
- `mix format --check-formatted` (repo root) — pass on phase-touched paths

## Plan checks

- **47-01:** `.github/workflows/ci.yml` includes **`scrypath-ops-path-check`** + **`scrypath-ops`** with Postgres **16-alpine**, **`hashFiles('mix.lock', 'scrypath_ops/mix.lock')`**, no Meilisearch in that job, **`cd scrypath_ops && mix deps.get && mix test`**.
- **47-02:** **`Mix.Tasks.Verify.Opsui`**, **`preferred_envs`** entry, **`.formatter.exs`** **`scrypath_ops`** globs, **`CONTRIBUTING.md`** mentions **`mix verify.opsui`** and documents the new CI jobs.
- **47-03:** **`operator_ia_contract_test.exs`** + **`opsui_auth_boot_contract_test.exs`**; LiveView tests extended per **47-CONTEXT** D-10–D-16; **`SearchPlaygroundStubAdapter`** supports **`:hard_error`**.

## Requirements

- **OPSUI-10** — Maintainer-facing automated verification for **`scrypath_ops/`** in CI plus anti-drift guards (doc/router parity, critical LiveView semantics).

## Human verification

None required (deterministic ExUnit + CI wiring; no new operator product UI).
