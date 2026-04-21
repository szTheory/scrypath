---
status: passed
phase: 48
verified: 2026-04-21
---

# Phase 48 verification

## Automated

- [x] `cd scrypath_ops && mix scrypath_ops.check_nav_contract` — pass (doc fence matches `Nav.primary/0`)
- [x] `cd scrypath_ops && mix test` — pass (29 tests)

## Must-haves (from plans)

### 48-01 — OPSUX-01

- [x] `ScrypathOpsWeb.Nav.primary/0` is the canonical ordered list for ops primary nav.
- [x] `:ops` layout renders nav from `Nav` without duplicating the four label strings.
- [x] `operator_ia_contract_test` asserts order, labels, and `live_session :ops` route parity.

### 48-02 — OPSUX-01 / D-04

- [x] Machine-readable fence exists in `operator-ia.md` between HTML comment markers.
- [x] `mix scrypath_ops.check_nav_contract` exits 0 on match and supports `--write`.
- [x] `mix test` alias runs the nav contract check before database setup and tests.

### 48-03 — OPSUX-02

- [x] Posture shows headline + evidence derived from existing posture assigns.
- [x] `data-testid="posture-next-checks"` present when next checks are non-empty.
- [x] Next checks use `/ops/...` paths consistent with primary nav; external links only to repo guides documented in the plan.

## Human verification

None required for this phase — behavior covered by contract and LiveView tests.
