# Feature Research — v1.18 Sigra integration

**Domain:** Optional Sigra integration for `scrypath_ops` operator attribution, sudo gating, and audit logging
**Researched:** 2026-04-25
**Confidence:** HIGH — based on the approved v1.18 plan plus existing STACK / ARCHITECTURE / PITFALLS research.

## Feature goal

v1.18 should let a Phoenix host that already uses Sigra enable `OPSUI_AUTH_MODE=sigra`, wire one LiveView hook manually, and get a credible answer to: **who ran sensitive Scrypath operator actions, under which org/session context, and was the action sudo-confirmed?**

This is an optional `scrypath_ops` integration, not a new auth layer for `scrypath` core.

## Table stakes

| Feature | Why expected | Complexity | Requirement candidates | Notes |
|---|---|---:|---|---|
| Optional Sigra mode | Sigra hosts need an explicit supported auth mode; non-Sigra hosts must be unaffected | Med | `SIGRA-01`, `SIGRA-02` | `{:sigra, "~> 0.2", optional: true}`, `OPSUI_AUTH_MODE=sigra`, compile guards |
| IDs-only `OperatorContext` | Stable contract between Sigra session/scope and ops UI; avoids PII leakage | Med | `SIGRA-03` | Fields only: `user_id`, `active_org_id`, `impersonator_user_id`, `sudo_at` |
| Sigra `OnMount` hook | Host needs one documented way to assign operator context into ops sockets | Med | `SIGRA-04` | Host stacks it manually with existing `ScrypathOpsWeb.Live.OnMount` |
| Sensitive-action gate | Mutating ops actions need one sudo + impersonation + audit funnel | High | `SIGRA-05` | `gate_sensitive_action/3`; stale sudo navigates to host-owned confirm route |
| Built-in sensitive-action wiring | Existing OPSUI actions must actually use the gate, not just expose helpers | High | `SIGRA-06` | Playbook delete, failed retry, swap-live actions; no direct `Sigra.*` in LiveViews |
| Audit taxonomy | Operators need predictable audit queries and incident trails | Med | `SIGRA-07` | Prefix: `scrypath.ops.*`; include operation metadata, not session PII |
| Boundary enforcement | Optional integration must not leak into core or become mandatory | Med | `SIGRA-08` | CI grep fence; compile-without-Sigra verification |
| Integration guide + worked example | Adopters need copy-paste wiring and a maintained proof app | High | `SIGRA-09`, `SIGRA-10` | `guides/integrations/sigra.md`; `examples/phoenix_sigra_ops/` CI smoke |

## Differentiators

| Feature | Value proposition | Complexity | Notes |
|---|---|---:|---|
| Core stays auth-agnostic while ops gains real attribution | Strong library boundary: Scrypath stays search-focused, `scrypath_ops` becomes host-auth friendly | Med | Key trust signal for OSS adopters |
| Host-owned sudo route instead of hidden modal | Fits real Phoenix apps without coupling to a component system | Med | Preserve `return_to` so triage state survives re-auth |
| Telemetry/audit attribution without core API churn | Uses existing telemetry metadata path; no `:operator` option in core v1.18 | Med | Document process-boundary limits |
| Compile-without-Sigra proof | Makes optional dependency promise falsifiable | Low-Med | Prevents `optional: true` from becoming cosmetic |
| Tiny Sigra example with no Meilisearch noise | Makes the auth/audit wiring legible and CI-maintained | High | Stub backend is preferable for this milestone |

## Anti-features

| Anti-feature | Why avoid | What to do instead |
|---|---|---|
| New `scrypath_sigra` hex package | Premature packaging surface for one integration namespace | Keep in `scrypath_ops` under `ScrypathOps.Integrations.Sigra.*` |
| Any `Sigra.*` reference in `lib/scrypath/` | Violates auth-agnostic core boundary | Keep all Sigra-aware code in guarded `scrypath_ops` modules |
| Any Scrypath reference inside Sigra | Makes Sigra aware of Scrypath | Sigra remains unchanged; host app composes both |
| Automatic router / plug installation | Hides the security boundary and surprises host apps | Guide explicit host-owned router wiring |
| In-place sudo modal | Couples to host UI/component choices | `push_navigate` to host-owned sudo confirm route |
| Plug re-export wrappers | Adds surface area without value | Document direct use of Sigra plugs |
| Core org scoping / authz in search or sync APIs | Separate product/API design problem, likely v2 | Keep v1.18 to ops attribution and mutation gating |
| Mandatory Sigra dependency for all ops users | Breaks optional integration promise | Optional dep + compile guards + absent-Sigra verification |

## Feature dependencies

```text
SIGRA-01 Optional dep + auth mode allowlist
  ├─> SIGRA-02 Compile guards + namespace fence
  ├─> SIGRA-03 OperatorContext
  │     └─> SIGRA-04 OnMount assigns :operator_context
  │           └─> SIGRA-05 Gating funnel
  │                 ├─> SIGRA-06 Built-in sensitive-action wiring
  │                 └─> SIGRA-07 Audit taxonomy / telemetry attribution
  └─> SIGRA-08 Boundary verification

SIGRA-06 + SIGRA-07
  └─> SIGRA-09 Sigra integration guide
        └─> SIGRA-10 phoenix_sigra_ops worked example + CI smoke
```

## SIGRA-* requirement candidates

| ID | Candidate requirement | Acceptance sketch |
|---|---|---|
| `SIGRA-01` | `scrypath_ops` recognizes optional Sigra mode | Add optional Sigra dep; `OPSUI_AUTH_MODE=sigra` passes boot validation; non-Sigra modes unchanged |
| `SIGRA-02` | Sigra references compile only when Sigra is present | Every `Sigra.*` reference is guarded at module boundary; `scrypath_ops` compiles with Sigra absent |
| `SIGRA-03` | Provide IDs-only `OperatorContext` | Builder extracts only allowed fields; tests prove no PII keys are present |
| `SIGRA-04` | Provide host-wired `OnMount` hook | Assigns `:operator_context` when Sigra scope/session exists; assigns `nil` / no-ops otherwise |
| `SIGRA-05` | Provide `Gating.gate_sensitive_action/3` | Fresh sudo executes and audits; impersonation blocks; stale sudo navigates to configured confirm path with `return_to` |
| `SIGRA-06` | Wire OPSUI sensitive mutations through the gate | Playbook delete, failed retry, and swap-live actions use the funnel under Sigra mode |
| `SIGRA-07` | Define stable audit event taxonomy | `scrypath.ops.*` action map is documented and tested; metadata excludes session PII |
| `SIGRA-08` | Enforce boundary discipline in CI | CI fails on `Sigra.` in `lib/scrypath/` or outside the integration namespace |
| `SIGRA-09` | Publish canonical Sigra integration guide | Documents router plugs, stacked `on_mount`, sudo route, telemetry snippet, impersonation/read caveats, optional nature |
| `SIGRA-10` | Ship maintained worked example | `examples/phoenix_sigra_ops/` demonstrates login → sudo → gated action → audit path and runs in CI |

## MVP recommendation

Prioritize this milestone as three product slices:

1. **Foundation:** optional dependency, auth-mode allowlist, compile guards, namespace fence, `OperatorContext`, `OnMount`, and `Gating`.
2. **User-facing enforcement:** wire current OPSUI sensitive actions through `gate_sensitive_action/3` with clear sudo/impersonation behavior.
3. **Adopter proof:** guide + tiny Sigra example + CI smoke so the integration remains usable.

Defer public package extraction, core auth/org scoping, in-place sudo UX, automatic router installation, and core `:operator` API options.

## Notable risks

- `sudo_at` / active org propagation depends on host Sigra scope/session wiring; the guide must be explicit.
- Process-dictionary attribution does not cross async/task boundaries; gate synchronous decision points only.
- Silent attribution drift is the long-term risk; the audit funnel, action taxonomy, tests, and grep fence are the mitigation.

## Sources

- `~/.claude/plans/so-i-m-considering-rippling-ladybug.md` — approved v1.18 architecture and scope
- `.planning/PROJECT.md` / `.planning/STATE.md` — active milestone goal and boundary constraints
- `.planning/research/STACK.md` — optional dependency, version, compile-guard, and CI decisions
- `.planning/research/ARCHITECTURE.md` — module boundaries, data flow, phase decomposition
- `.planning/research/PITFALLS.md` — attribution, PII, sudo, async, and example-rot risks

---
*Feature research for **v1.18 Sigra integration***
