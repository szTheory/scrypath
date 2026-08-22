---
title: Remediate reproduced dependency security advisories
status: pending
priority: high
category: security-dependency
created: 2026-08-16
resolves_phase: 147
---

# Remediate reproduced dependency security advisories

## Problem

`mix deps.get` reproduced dependency security advisories in root Scrypath, ScrypathOps, the legacy Phoenix example, and the ecommerce example. Triage is complete, but remediation is pending. The authoritative evidence is [the locked research](../../quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-RESEARCH.md) and [the advisory ledger](../../quick/260816-tzr-triage-dependency-security-advisories-re/260816-tzr-ADVISORY-TRIAGE.md); neither states that vulnerabilities are fixed.

## Solution

Execute four separate commits in this order. Before each constraint change, consult upstream migration and release notes. Stop immediately on any failed gate; do not stack batches or opportunistically advance to package heads.

1. **Root core client:** change the root Req constraint to `~> 0.6.1`; resolve Req `0.6.1+`, Mint `1.9.3`, hpax `1.0.4`, and Plug `1.19.5`.
2. **Legacy Phoenix example:** separately resolve Bandit `1.12.1`, Phoenix `1.8.9`, Plug `1.19.5`, Postgrex `0.22.4`, Mint `1.9.3`, hpax `1.0.4`, Req `0.6.x`, and align Ecto/Ecto SQL to `3.14.x` so Decimal resolves to `3.0.0+`.
3. **ScrypathOps web/client graph:** resolve Bandit `1.12.1`, Phoenix `1.8.9`, Phoenix LiveView `1.1.33`, Plug `1.19.5`, Postgrex `0.22.4`, Mint `1.9.3`, hpax `1.0.4`, Swoosh `1.26.3`, and Req `~> 0.6.1`.
4. **Ecommerce web/client graph:** independently repeat the Ops-compatible web/client resolution because the browser E2E app mounts ScrypathOps through a path dependency.

## Acceptance

- Each batch is a separate commit and passes its gate before the next begins.
- Root: `mix deps.get`, `mix compile --warnings-as-errors`, `mix test --exclude integration --exclude docs_contract`, `mix verify --exclude integration`, `mix verify.phase11`, and `mix verify.phase99` pass.
- Legacy example: `cd examples/phoenix_meilisearch && mix deps.get && mix test`, then root `mix test --exclude integration --exclude docs_contract` pass.
- Ops: `mix verify.opsui` and the root required gates pass.
- Ecommerce: `mix deps.get`; `cd examples/scrypath_ecommerce && mix deps.get && mix e2e.prepare`; the advisory `phase105-e2e` CI lane/documented browser checks run when services are available.
- The todo remains open until `mix deps.get` no longer reports the recorded advisories in all four Mix projects and the relevant gates pass.
