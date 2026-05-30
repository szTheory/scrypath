# Phase 102: Admin UI Router Engine Refactor - Context

**Gathered:** 2026-05-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 102 refactors `scrypath_ops` into a pure mountable router engine that can be embedded in host Phoenix apps, deprecating its standalone Endpoint and Repo. It establishes the "plug-and-play" foundation for integrating the operator UI into real applications (like the upcoming demo app).

</domain>

<decisions>
## Implementation Decisions

### Mounting Approach
- **D-01:** Implement a custom macro `scrypath_ops_routes(path, opts \\ [])` to mount the engine's routes, rather than relying on `forward`.
- **D-02:** Use the macro to wrap the ops UI in a `live_session` and `on_mount` hooks, mirroring the DX of `Phoenix.LiveDashboard` and Oban Web.

### Configuration Injection
- **D-03:** Pass all required engine configuration (e.g., `repo`, adapter) explicitly as runtime options to the `scrypath_ops_routes` macro.
- **D-04:** Inject these options into the LiveView socket via an `on_mount` hook, strictly avoiding `Application.get_env/3` for the engine's primary interface to enable multitenancy and explicit APIs.

### Asset Delivery
- **D-05:** Serve pre-compiled static assets (CSS, JS) directly from the engine via an internal plug/controller isolated from the host app's asset pipeline.
- **D-06:** Ensure CSS isolation (e.g., via Tailwind prefix or scoped classes) so the engine renders perfectly regardless of host application styling, eliminating integration friction.

### Claude's Discretion
- Exact naming and location of the internal asset controller/plug and exact shape of `NimbleOptions` schema for the macro, provided the macro DX and explicit configuration principles hold.
- Exact internal routing structure (e.g., grouping `live` macros inside the `scrypath_ops_routes`), provided the host app only needs to call the one macro.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Authority and Scope
- `.planning/ROADMAP.md` — Phase 102 goal, requirements mapping, and success criteria.
- `.planning/REQUIREMENTS.md` — OPS-01 and OPS-02 requirements.
- `.planning/PROJECT.md` — Core value of making search indexing feel native and ergonomic.

### Ecosystem Best Practices (Architecture & DX)
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` — Explicit configuration, avoidance of `Application.get_env`, and macro ergonomics.
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — Encapsulation, context boundaries, and mountable engine design.
- `prompts/phoenix-best-practices-deep-research.md` — LiveView routing, `live_session` boundaries, and isolated asset serving (LiveDashboard precedent).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ScrypathOpsWeb.Router`: Contains the existing `live_session :ops` and routes that need to be packaged inside the macro.
- `ScrypathOpsWeb.Live.OnMount`: Existing mount hooks can be adapted to extract options passed from the macro.

### Established Patterns
- `ScrypathOps.Application` currently supervises `ScrypathOpsWeb.Endpoint` and `ScrypathOps.Repo` — these need to be deprecated or conditionally started only in standalone dev mode.

### Integration Points
- A new `ScrypathOpsWeb.scrypath_ops_routes/2` macro (or similar) will become the primary integration point for host applications.
- A new internal asset route and controller/plug will need to be added to serve `priv/static/assets/*`.

</code_context>

<specifics>
## Specific Ideas

- The implementation should closely mirror the DX of `Phoenix.LiveDashboard` (`live_dashboard "/dashboard"`) and Oban Web (`oban_dashboard "/oban"`), representing the "gold standard" for Phoenix UI drop-ins.
- Ensure `NimbleOptions` is used to validate the runtime configuration passed to the macro, failing fast with clear errors if the host app misconfigures the mount.

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope.

</deferred>

---

*Phase: 102-Admin UI Router Engine Refactor*
*Context gathered: 2026-05-30*