# Research Summary — v1.18 Sigra integration

**Milestone:** v1.18 — optional Sigra integration in `scrypath_ops`
**Synthesized:** 2026-04-25
**Sources:** STACK.md, ARCHITECTURE.md, FEATURES.md, PITFALLS.md (all 2026-04-25, all HIGH confidence)

---

## 1. Milestone framing

v1.18 ships an **optional, in-repo** Sigra integration that lets a Phoenix host running Sigra answer "who ran which sensitive Scrypath operator action, in which org/session, with sudo confirmed?" — without changing `scrypath` core or making Sigra aware of Scrypath. All Sigra-aware code lives in `scrypath_ops` under one new namespace, behind `optional: true` deps and `Code.ensure_loaded?` compile guards. **Hard boundaries:** (a) `scrypath` core stays auth-agnostic — zero changes under `lib/scrypath/`; (b) Sigra remains unaware of Scrypath — no `Scrypath.*` references inside `lib/sigra/`; (c) integration is opt-in via `OPSUI_AUTH_MODE=sigra` and is purely a `scrypath_ops` concern; (d) **no new hex package** — the integration ships as `ScrypathOps.Integrations.Sigra.*` in the existing in-repo `scrypath_ops` app; (e) no automatic router/plug installation, no in-place sudo modal, no plug re-export wrappers, no core `:operator` API.

---

## 2. Stack additions (binding decisions)

| Area | Decision |
|---|---|
| New runtime dep | `{:sigra, "~> 0.2", optional: true}` in `scrypath_ops/mix.exs` (pessimistic minor — patch-floor wrong while Sigra iterates at 0.2.x; do not adopt `~> 0.3`) |
| Compile guard | `if Code.ensure_loaded?(Sigra.Session) do ... end` wrapping the **entire `defmodule` block** (not just function bodies; not `Code.ensure_compiled?/1` which is deprecated) |
| Allowlist update | Add `"sigra"` to `@allowed_opsui_auth_modes` in `scrypath_ops/lib/scrypath_ops/security.ex:4` |
| Boundary enforcement | Plain CI grep step in existing `quality` job (no `Boundary` hex lib) — fails on `Sigra.` outside `scrypath_ops/lib/scrypath_ops/integrations/sigra/` or anywhere under `lib/scrypath/` |
| Worked example deps | Standalone Phoenix app at `examples/phoenix_sigra_ops/` using `{:scrypath_ops, path: "../.."}`, `{:sigra, "~> 0.2"}` (non-optional in example), `{:ecto_sqlite3, "~> 0.22"}` (SQLite avoids Postgres CI service) |
| No new test deps | ExUnit + `Phoenix.LiveViewTest` + `Phoenix.ConnTest` cover the example; no `bypass`, `mox`, `plug_cowboy` |
| Anti-deps | Do NOT direct-depend on `argon2_elixir`, `cloak_ecto`, `wax_`, `assent`, `joken`, `hammer`, `oban`, `bcrypt_elixir`, `eqrcode`, `nimble_totp` — these are Sigra-internal transitive concerns |
| Existing stack untouched | Elixir `~> 1.17`, Phoenix `~> 1.8.5`, LiveView `~> 1.1.0`, Ecto SQL `~> 3.13`, Bandit `~> 1.5` — no version churn |
| `scrypath` core mix.exs | Untouched. Hex `scrypath 0.3.4` not republished. |

---

## 3. Module shape

**New namespace (all in `scrypath_ops/lib/scrypath_ops/integrations/sigra/`):**

| Module | Responsibility |
|---|---|
| `ScrypathOps.Integrations.Sigra.OperatorContext` | IDs-only struct: `user_id`, `active_org_id`, `impersonator_user_id`, `sudo_at` — single translation point from Sigra scope/session into the internal contract. No PII fields (no `ip`, `user_agent`, `geo_*`, `email`, `name`). |
| `ScrypathOps.Integrations.Sigra.OnMount` | LiveView `on_mount/4` hook reading `socket.assigns[:current_scope]` (and serialized `sudo_at`); assigns `:operator_context` and `:impersonation_active?`. Sibling to existing `ScrypathOpsWeb.Live.OnMount`, **never** replaces it. |
| `ScrypathOps.Integrations.Sigra.Gating` | `gate_sensitive_action(socket, action_atom, fn)` funnel: impersonation check → sudo freshness check → `Process.put` attribution → run fn → `Sigra.Audit.log_safe("scrypath.ops.#{action}", nil, opts)` → `Process.delete`. Holds private `@action_config` map (compile-time, not a registry process). Stale sudo `push_navigate` to host-configured `:sudo_confirm_path` with `return_to`. |

Three peer modules, no umbrella parent. Each is wrapped in its own `Code.ensure_loaded?(Sigra.Session)` guard. Tests co-located at `scrypath_ops/test/scrypath_ops/integrations/sigra/`.

**Reused existing extension points (no new abstractions):**
- `ScrypathOpsWeb.Live.OnMount` — host stacks Sigra OnMount as a second entry in the router's `live_session :ops, on_mount: [...]` list; existing hook unchanged.
- `ScrypathOps.Security.allowed_opsui_auth_modes/0` — existing allowlist gets `"sigra"` appended.
- `Scrypath.Telemetry.common_metadata/3:18` — host-owned telemetry handler reads `Process.get(:scrypath_ops_operator_context)` and enriches via the existing `extra` keyword; no core API change.
- `Sigra.Audit.log_safe/3`, `Sigra.Plug.{RequireSudo, ForbidDuringImpersonation, RequireAdminAccess}`, `Sigra.Admin.Policy` — used directly; no wrappers.
- `.github/workflows/ci.yml` `quality` job — gets one new grep step.

---

## 4. Build order (Phases 71 / 72 / 73)

| Phase | Scope (one-liner) |
|---|---|
| **Phase 71 — Foundation** | Optional Sigra dep + auth-mode allowlist + three integration modules (`OperatorContext`, `OnMount`, `Gating`) + their unit tests + namespace-fence CI grep. Establishes boundary on day one; ships independently of LiveView wiring. |
| **Phase 72 — Sensitive-action wiring** | Wire the four OPSUI LiveView handlers through `Gating.gate_sensitive_action/3`: `playbook_live` `confirm_delete` (existing, line 269), and **new** handlers `failed_sync_live "retry"`, `posture_live "swap_live"`, `sync_drift_live "swap_live"`. Includes `return_to` round-trip and per-LiveView gate tests. Depends on Phase 71. |
| **Phase 73 — Adopter proof** | `guides/integrations/sigra.md` (router wiring, stacked on_mount, sudo route contract, telemetry snippet, impersonation/read caveats, optional-nature framing) + `examples/phoenix_sigra_ops/` standalone Phoenix app with stub backend + `phoenix-sigra-ops-smoke` CI job (SQLite, no Meilisearch service). Depends on Phase 72. |

Phase numbering continues from v1.17's Phase 70.

---

## 5. SIGRA-* requirement candidates

Carried through directly from FEATURES.md for REQUIREMENTS.md to consume:

| ID | One-line summary |
|---|---|
| **SIGRA-01** | `scrypath_ops` recognizes optional Sigra mode — `{:sigra, "~> 0.2", optional: true}`, `OPSUI_AUTH_MODE=sigra` passes boot validation, non-Sigra modes unchanged. |
| **SIGRA-02** | Sigra references compile only when Sigra is present — every `Sigra.*` reference module-guarded; `scrypath_ops` compiles cleanly with Sigra absent (verified in CI). |
| **SIGRA-03** | IDs-only `OperatorContext` struct — exactly four fields (`user_id`, `active_org_id`, `impersonator_user_id`, `sudo_at`); test asserts no PII keys. |
| **SIGRA-04** | Host-wired `OnMount` hook — assigns `:operator_context` when Sigra scope/session present; assigns `nil` / no-ops otherwise; sibling to existing OnMount. |
| **SIGRA-05** | `Gating.gate_sensitive_action/3` funnel — fresh sudo executes + audits; impersonation blocks with flash; stale sudo `push_navigate` to host-configured confirm path with `return_to`. |
| **SIGRA-06** | OPSUI sensitive mutations wired through the gate — playbook delete, failed retry, posture swap-live, sync-drift swap-live; no direct `Sigra.*` in any LiveView. |
| **SIGRA-07** | Stable audit taxonomy — `scrypath.ops.*` action map documented and tested; metadata is operation context only, never session PII. |
| **SIGRA-08** | Boundary discipline enforced in CI — grep fails on `Sigra.` in `lib/scrypath/` or outside the integration namespace. |
| **SIGRA-09** | Canonical `guides/integrations/sigra.md` — router plugs, stacked `on_mount`, sudo route contract, telemetry snippet, impersonation/read caveats, opt-in framing. |
| **SIGRA-10** | Maintained `examples/phoenix_sigra_ops/` worked example — login → sudo → gated action → audit path; runs in CI as `phoenix-sigra-ops-smoke`. |

Dependency chain: `SIGRA-01 → {02, 03, 08}`; `03 → 04 → 05 → {06, 07}`; `{06, 07} → 09 → 10`.

---

## 6. Top risks and mitigations

| Risk | Mitigation | Phase |
|---|---|---|
| **Silent attribution drift** — new `handle_event` ships without going through `gate_sensitive_action/3`; audit silently misses rows | Sensitive-action registry module attribute + CI grep matching handler names against the registry; telemetry assertion in worked-example test that `[:sigra, :audit, :log]` fires for each Tier-1 action | 71 (registry + grep), 72 (telemetry test) |
| **PII leakage** through `OperatorContext` or audit metadata (`Sigra.Audit` blocks credentials, NOT `ip`/`email`/`geo_*`) | `OperatorContext` typespec restricts to four ID fields; unit test asserts no PII keys in built struct; `Gating` documents permitted metadata per action; guide flags that `log_safe/3` does not sanitize PII | 71 (struct + tests), 73 (guide callout) |
| **Compile-guard mistakes** — top-level `alias Sigra.X`, `@spec` referencing Sigra types, or function-only guards leak compile-time references | Wrap **entire `defmodule`** in `if Code.ensure_loaded?(Sigra.Session) do`; no top-level Sigra alias; no Sigra types in `@spec`; CI step compiles `scrypath_ops` with `:sigra` removed | 71 (pattern + CI verification) |
| **Async attribution drop** — `Process.put` context invisible across `start_async`, `Task.async_stream`, Oban (real call sites: `playbook_live.ex:751`, `posture_live.ex:72`) | Gate the synchronous decision point only; capture `operator_context` in closure as a local variable when crossing process boundary; audit emits at the decision, not in the async work; guide documents the limit | 71 (pattern), 72 (LiveView discipline), 73 (guide warning) |
| **Sudo-window confusion / missing confirm route** — host's `RequireSudo` window mismatches gate's; host hasn't defined sudo confirm route; re-auth wipes triage state | Boot validation: if `OPSUI_AUTH_MODE=sigra`, require `:sudo_confirm_path` in `:scrypath_ops` config (else raise); gate uses Sigra default 300s but accepts override; `push_navigate` always carries `return_to`; smoke test asserts round-trip | 71 (boot check), 72 (return_to), 73 (guide contract) |
| **Audit prefix collision** — Sigra adds `ops.` to reserved prefixes in a future minor and `log_safe/3` silently no-ops on changeset failure | Contract test asserts `scrypath.ops.*` is not in Sigra's default reserved prefixes; `~> 0.2` minor pin (not `>= 0.2`); guide telemetry handler attaches to `[:sigra, :audit, :log_safe_error]` to surface silent failures as warnings | 71 (contract test + version pin), 73 (telemetry handler) |
| **Worked-example rot** — `examples/phoenix_sigra_ops/` drifts from `scrypath_ops` API and adopters hit a broken example | Dedicated `phoenix-sigra-ops-smoke` CI job runs `mix compile --warnings-as-errors && mix test`; path-gated to `examples/phoenix_sigra_ops/` and `scrypath_ops/`; example pins Sigra dep to the exact same constraint as `scrypath_ops/mix.exs` | 73 |

Lower-priority risks tracked in PITFALLS.md: impersonation-and-reads (guide clarification only); Scrypath leakage into Sigra (out-of-repo CI concern); "optional becomes mandatory" doc trap (README framing).

---

## 7. Files touched (deduplicated)

**New files (10):**
```
scrypath_ops/lib/scrypath_ops/integrations/sigra/operator_context.ex
scrypath_ops/lib/scrypath_ops/integrations/sigra/on_mount.ex
scrypath_ops/lib/scrypath_ops/integrations/sigra/gating.ex
scrypath_ops/test/scrypath_ops/integrations/sigra/operator_context_test.exs
scrypath_ops/test/scrypath_ops/integrations/sigra/on_mount_test.exs
scrypath_ops/test/scrypath_ops/integrations/sigra/gating_test.exs
scrypath_ops/test/scrypath_ops/integrations/sigra/audit_contract_test.exs
guides/integrations/sigra.md
examples/phoenix_sigra_ops/                       (whole new Phoenix app)
.github/workflows/ci.yml                          (modified — see below)
```

**Modified files (6):**
```
scrypath_ops/mix.exs                                       (add {:sigra, "~> 0.2", optional: true})
scrypath_ops/lib/scrypath_ops/security.ex                  (add "sigra" to @allowed_opsui_auth_modes)
scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex    (gate confirm_delete at line 269)
scrypath_ops/lib/scrypath_ops_web/live/failed_sync_live.ex (add gated "retry" handler)
scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex     (add gated "swap_live" handler)
scrypath_ops/lib/scrypath_ops_web/live/sync_drift_live.ex  (add gated "swap_live" handler)
.github/workflows/ci.yml                                   (namespace-fence grep + phoenix-sigra-ops-smoke job)
```

**Files explicitly NOT touched:** anything under `lib/scrypath/` (core stays auth-agnostic — zero diff in the published `scrypath 0.3.4` hex package); `scrypath/mix.exs`; anything under `/Users/jon/projects/sigra/`.

---

## 8. Sources

- `.planning/research/STACK.md` — version constraints, optional-dep semantics, compile-guard pattern, anti-deps, namespace-fence decision
- `.planning/research/ARCHITECTURE.md` — module shape, OnMount stacking, gating funnel order, async attribution audit of all four LiveViews, phase decomposition, worked-example design
- `.planning/research/FEATURES.md` — SIGRA-01..10 candidates, table stakes vs. anti-features, dependency graph, MVP slicing
- `.planning/research/PITFALLS.md` — ten ranked pitfalls (4 critical, 5 moderate, 1 minor) with phase-specific mitigations
- `~/.claude/plans/so-i-m-considering-rippling-ladybug.md` — approved architectural plan (upstream of all four research files)
- `.planning/PROJECT.md` v1.18 milestone goal & boundary constraints; `.planning/STATE.md` (status: defining_requirements)

---
*Research synthesis for v1.18 Sigra integration — ready for REQUIREMENTS.md and ROADMAP.md.*
