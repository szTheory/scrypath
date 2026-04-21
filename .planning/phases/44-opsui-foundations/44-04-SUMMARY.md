---
phase: 44
plan: "04"
status: complete
---

# Plan 44-04 — OPSUI security model

## Outcome

- **`config/prod.exs`**: **`validate_opsui_auth_on_start`** → **`true`**; dev/test → **`false`**.
- **`ScrypathOps.Application.start/2`** fails closed in prod when **`OPSUI_AUTH_MODE`** is not **`basic`** or **`proxy_headers`** (message contains **`OPSUI_AUTH_MODE`** and **`must be set`**).
- **`scrypath_ops/docs/SECURITY.md`** with required **`##`** sections including telemetry reference to **`docs/search-backend-sre.md`**.
- **`ScrypathOps.Security`** centralizes allow-list; **`test/scrypath_ops/config_prod_guard_test.exs`** documents the contract.

## Key files

- `scrypath_ops/lib/scrypath_ops/application.ex`
- `scrypath_ops/lib/scrypath_ops/security.ex`
- `scrypath_ops/config/prod.exs`
- `scrypath_ops/config/dev.exs`
- `scrypath_ops/config/test.exs`
- `scrypath_ops/docs/SECURITY.md`
- `scrypath_ops/README.md`
- `scrypath_ops/test/scrypath_ops/config_prod_guard_test.exs`

## Self-Check: PASSED
