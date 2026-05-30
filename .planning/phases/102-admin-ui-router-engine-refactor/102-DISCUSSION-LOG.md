# Phase 102: Admin UI Router Engine Refactor - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 102-Admin UI Router Engine Refactor
**Areas discussed:** Mounting Approach, Configuration Injection, Asset Delivery

---

## Mounting Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Custom Macro | Use `scrypath_ops_routes/2` to inject routes, `live_session`, and hooks. | ✓ |
| Forward | Use standard `forward "/ops", Router`. | |

**User's choice:** Custom Macro (via subagent research recommendation)
**Notes:** Custom macro allows wrapping the routes in a `live_session` and applying `on_mount` hooks seamlessly, matching LiveDashboard/Oban DX.

---

## Configuration Injection

| Option | Description | Selected |
|--------|-------------|----------|
| Runtime Options | Pass config via the macro options to the router assigns. | ✓ |
| Global Config | Read from `Application.get_env/3` globally. | |

**User's choice:** Runtime Options (via subagent research recommendation)
**Notes:** Avoids global state, supports multitenancy (mounting multiple instances), and enables fast validation via `NimbleOptions`.

---

## Asset Delivery

| Option | Description | Selected |
|--------|-------------|----------|
| Built-in Plug | Serve pre-compiled assets from engine's `priv/static` via internal route. | ✓ |
| Host Pipeline | Inject into host's `tailwind.config.js` or build process. | |

**User's choice:** Built-in Plug (via subagent research recommendation)
**Notes:** Provides zero-friction integration and ensures CSS isolation so host styles do not bleed into the engine UI.

---

## Claude's Discretion

Exact internal structure of the macro and location of the internal asset plug.

## Deferred Ideas

None noted.