# Requirements: Scrypath — Milestone v1.18

**Defined:** 2026-04-25
**Core value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.

## v1.18 Requirements

### Optional integration foundation

- [ ] **SIGRA-01**: `scrypath_ops` recognizes `OPSUI_AUTH_MODE=sigra` as a supported auth mode and adds `{:sigra, "~> 0.2", optional: true}` to `scrypath_ops/mix.exs`. Hosts that do not opt in (any other `OPSUI_AUTH_MODE` value or absent `:sigra` dep) compile and run unchanged; the published `scrypath` hex package contains zero Sigra references.

- [ ] **SIGRA-02**: Every Sigra reference in `scrypath_ops/lib/` and `scrypath_ops/test/` is wrapped at the `defmodule` level by `if Code.ensure_loaded?(Sigra.Session) do ... end`. `mix compile` in `scrypath_ops` succeeds with `:sigra` absent from the dep tree, verified by an explicit CI step that compiles `scrypath_ops` after removing `:sigra`.

### Operator context contract

- [ ] **SIGRA-03**: Provide `%ScrypathOps.Integrations.Sigra.OperatorContext{}` as an IDs-only struct with exactly four fields: `:user_id`, `:active_org_id`, `:impersonator_user_id`, `:sudo_at`. The builder reads `:user_id` and `:active_org_id` from `socket.assigns.current_scope` (and `current_scope.active_organization.id`), reads `:impersonator_user_id` from the same scope, and reads `:sudo_at` from the Plug session via the `%Sigra.Session{}` struct. Unit tests assert no PII keys (`:ip`, `:user_agent`, `:geo_city`, `:geo_country_code`, `:email`, `:name`) are present in the built struct.

### LiveView mount integration

- [ ] **SIGRA-04**: Provide `ScrypathOps.Integrations.Sigra.OnMount` as a sibling hook to the existing `ScrypathOpsWeb.Live.OnMount`. Hosts wire it manually as a second entry in the router's `live_session :ops, on_mount: [...]` list. The hook assigns `:operator_context` to the socket from `current_scope` + Plug session when both are present; assigns `nil` (or no-ops cleanly) when scope is absent or Sigra is not loaded. The integration **does not** modify the existing `ScrypathOpsWeb.Live.OnMount` and **does not** auto-install router wiring. The integration guide ships a copy-pasteable host-side plug snippet that copies `sudo_at` from `%Sigra.Session{}` into the Plug session before LiveView mount.

### Sensitive-action funnel

- [ ] **SIGRA-05**: Provide `ScrypathOps.Integrations.Sigra.Gating.gate_sensitive_action(socket, action_atom, fun)` that, in order: (1) reads `:operator_context` from socket assigns and executes `fun` directly when nil (no-op mode); (2) blocks with a flash error and `{:noreply, socket}` when `impersonator_user_id` is set; (3) navigates to a host-configured sudo confirm path with a `return_to` parameter when `sudo_at` is older than the configured `:sudo_window` (default 300s, matching Sigra); (4) executes `fun`; (5) emits `Sigra.Audit.log_safe("scrypath.ops.<action>", nil, audit_opts)`. Boot validation raises a clear error when `OPSUI_AUTH_MODE=sigra` is set without `:sudo_confirm_path` configured.

- [ ] **SIGRA-06**: Existing OPSUI sensitive mutating handlers route through `gate_sensitive_action/3` when `OPSUI_AUTH_MODE=sigra`. v1.18 wires exactly **four** LiveView handlers: `playbook_live.ex` `confirm_delete`, `failed_sync_live.ex` `retry` (new handler), `posture_live.ex` `swap_live` (new handler), and `sync_drift_live.ex` `swap_live` (new handler). Playbook `run` / `run_now` (which use `start_async/3`) are explicitly **not** gated in v1.18; the integration guide documents this limitation. Each wired handler has a LiveView test that asserts the gate fires under `OPSUI_AUTH_MODE=sigra`.

### Audit taxonomy

- [ ] **SIGRA-07**: `Gating` declares a private `@action_config` map at compile time that defines stable `scrypath.ops.*` audit prefixes for all sensitive actions. v1.18 wires four (`scrypath.ops.playbook_delete`, `scrypath.ops.failed_work_retry`, `scrypath.ops.swap_live` from posture, and `scrypath.ops.swap_live` from sync drift sharing the same prefix), and reserves prefixes for three future actions (`scrypath.ops.reindex`, `scrypath.ops.delete_documents`, `scrypath.ops.hot_apply`). The audit metadata map carries operation context only — never `OperatorContext` PII fields or `%Sigra.Session{}` PII fields. A contract test asserts `scrypath.ops.*` does not collide with Sigra's default reserved prefixes.

### Boundary discipline

- [ ] **SIGRA-08**: CI fails the `quality` job in `.github/workflows/ci.yml` when (a) any `Sigra.` reference appears under `lib/scrypath/`, or (b) any `Sigra.` reference appears under `scrypath_ops/lib/` or `scrypath_ops/test/` outside `scrypath_ops/lib/scrypath_ops/integrations/sigra/` and `scrypath_ops/test/scrypath_ops/integrations/sigra/`. The fence runs unconditionally on every push and PR. A planted-violation test (CI dry run with a deliberate offending line) confirms the fence triggers.

### Adopter proof

- [ ] **SIGRA-09**: Publish `guides/integrations/sigra.md` covering: optional-integration framing ("this guide is for hosts already using Sigra"), router pipeline wiring (`Sigra.Plug.FetchSession`, the host-side sudo-into-session snippet, stacked `on_mount` list), `Gating.gate_sensitive_action/3` usage for custom handlers, the host-owned sudo confirm route contract with `return_to`, the copy-pasteable telemetry handler snippet, the `scrypath.ops.*` audit taxonomy, and explicit caveats covering process-dict attribution limits across `Task` / `start_async` / Oban, sudo-window mismatch behavior, impersonation read visibility, and PII metadata responsibility.

- [ ] **SIGRA-10**: Ship `examples/phoenix_sigra_ops/` as a standalone Phoenix app (`mix phx.new --no-mailer` baseline) using `ecto_sqlite3` for Sigra's session/audit schemas, no Meilisearch dependency, and a stub Scrypath backend. The example demonstrates: login → navigate to `/ops` → attempt a Tier-1 action without sudo → redirect to sudo confirm with `return_to` → confirm → action executes → audit row written with `operator_id` and `active_org_id`; plus an impersonation scenario where a Tier-1 action is blocked. A dedicated CI smoke job runs `mix deps.get && mix compile --warnings-as-errors && mix test` inside the example, gated by path filter to `scrypath_ops/` and `examples/phoenix_sigra_ops/`. Sigra version constraint in the example's `mix.exs` matches `scrypath_ops/mix.exs` exactly.

## Future requirements (deferred)

### Core surface expansion (deferred to v2+)

- **SIGRA-FUT-01** — Org scoping inside `scrypath` core search/sync APIs (needs schema/index design — separate conversation, possibly v2).
- **SIGRA-FUT-02** — Public `scrypath_sigra` hex package extraction (defer until 3+ public modules in the integration namespace or a second ops-side integration appears).
- **SIGRA-FUT-03** — `:operator` keyword option on core `Scrypath.search/3`, `reindex`, and `sync` APIs (telemetry-handler approach is sufficient for v1; revisit when adopters request tighter coupling).

### UX depth (deferred)

- **SIGRA-FUT-04** — In-place sudo confirmation modal (couples to host UI/component choices; v1 uses `push_navigate` to host route).
- **SIGRA-FUT-05** — Plug re-export wrappers around `Sigra.Plug.RequireSudo` / `Sigra.Plug.ForbidDuringImpersonation` (pure surface-area tax; host wires Sigra plugs directly per the guide).
- **SIGRA-FUT-06** — Async-safe attribution for playbook `run` / `run_now` (closure-based propagation across `start_async`).

### Heavy CI / Tier C

- Browser E2E for the worked example, visual regression, or Postgres-backed example smoke remain Tier C unless v1.18 surfaces a real coverage gap.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Any change under `lib/scrypath/` | Core stays auth-agnostic; published hex package must contain zero Sigra references. |
| Any change inside the Sigra source tree | Sigra remains unaware of Scrypath. Boundary maintained by convention + Sigra-side CI. |
| Automatic router or plug installation | Host wires explicitly so the security boundary stays visible. |
| New `scrypath_sigra` hex package | Premature for one integration namespace; revisit at SIGRA-FUT-02 trigger. |
| In-place sudo confirmation modal | Couples to host component library; v1 uses `push_navigate`. |
| Gating playbook `run` / `run_now` | Async attribution unsolved in v1; documented limitation. |
| Org scoping in core search/sync/reindex APIs | Separate product surface; out of scope for an ops-attribution milestone. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SIGRA-01 | Phase 71 | Pending |
| SIGRA-02 | Phase 71 | Pending |
| SIGRA-03 | Phase 71 | Pending |
| SIGRA-04 | Phase 71 | Pending |
| SIGRA-05 | Phase 71 | Pending |
| SIGRA-06 | Phase 72 | Pending |
| SIGRA-07 | Phase 71 | Pending |
| SIGRA-08 | Phase 71 | Pending |
| SIGRA-09 | Phase 73 | Pending |
| SIGRA-10 | Phase 73 | Pending |

**Coverage:**

- v1.18 requirements: **10** total
- Mapped to phases: **10**
- Unmapped: **0** ✓

---

*Requirements defined: 2026-04-25*
*Last updated: 2026-04-25 after `/gsd-new-milestone` resume — v1.18 opened*
