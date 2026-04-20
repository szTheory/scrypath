# Phase 44: OPSUI foundations - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the **optional operator Phoenix LiveView app** outside the core Hex package: **clone-and-run** (or path-dep) instructions for maintainers and early adopters; **persona/JTBD** documentation that **drives primary navigation order**; a **conventional Phoenix LiveView shell** (layouts, router, flash, components); and an **explicit security model** documented for **development vs non-development** deployments. **No** full posture/triage/search screens (phases **45–46**) and **no** OPSUI CI verification slice (phase **47**) in this phase—only foundations that those phases plug into without rework.

</domain>

<decisions>
## Implementation Decisions

### Repository layout and dependency boundary (OPSUI-09)

- **D-01:** Add a **top-level** Mix/Phoenix application directory **`scrypath_ops/`** at the repository root (sibling to the library’s `mix.exs` / `lib/`), **not** nested under **`examples/`**. Rationale: operator UI is **privileged maintainer tooling**, not a consumer integration sample; **`examples/phoenix_meilisearch`** remains the **adopter-facing** integration reference.
- **D-02:** The ops app depends on the library via **`{:scrypath, path: ".."}`** (adjust relative path if the folder name differs—must resolve from **`scrypath_ops/mix.exs`** to the **published library root**). No dependency from **`scrypath`** → Phoenix/LiveView/OPSUI.
- **D-03:** The core **`scrypath`** **`mix.exs`** **`package.files`** (or equivalent) **must exclude** **`scrypath_ops/`** entirely so OPSUI never ships on Hex. Document **`mix hex.publish`** is run only from the **library** project.
- **D-04:** **Do not** convert the repo to an umbrella for this milestone unless already required elsewhere; a standalone second Mix project keeps the Hex surface obvious.

### Personas, JTBD, and primary navigation (OPSUI-06)

- **D-05:** **Canonical** persona/JTBD and information-architecture contract live under the ops app as **`scrypath_ops/docs/operator-ia.md`** (name may vary slightly but must stay **app-local** and versioned with OPSUI).
- **D-06:** Content style: **2–3 role-based personas** (e.g. on-call, maintainer, search owner)—**not** marketing personas; **5–7 force-ranked jobs** with **trigger → outcome → done-when** testable phrasing; a **single table** mapping **Job → primary persona → top nav label → route → `Scrypath.*` or doc/Mix follow-up**.
- **D-07:** **Primary navigation order** reflects roadmap triage priorities: **(1)** posture/health (phase 45), **(2)** failed sync work, **(3)** sync/drift read-only + links to existing docs/Mix, **(4)** bounded search / federation honesty (phase 46)—**search not co-equal** with triage in the shell.
- **D-08:** Nav items are **real routes** with **thin LiveViews** (stub copy acceptable, e.g. “Data in phase 45”)—**not** dead `href="#"` placeholders outside LiveView. Same PR that changes nav or routes **updates** **`operator-ia.md`**.
- **D-09:** **Discoverability:** add a **short pointer** in root **`README.md`** and/or **`guides/`** linking to **`scrypath_ops/README.md`** and **`docs/operator-ia.md`**; do **not** duplicate long JTBD prose in **`guides/`** (those files remain **library semantics**).

### Phoenix / LiveView shell conventions (OPSUI-07)

- **D-10:** Use **stock Phoenix 1.7+** generator-shaped structure: **`scope "/ops", …`**, dedicated **`ScrypathOpsWeb`** (or one chosen namespace—**never** mix `ScrypathWeb` for operator routes), default **root** + **app** layouts, **`<.flash_group>`**, **`controllers/error_*`**, **`~p`** for internal links.
- **D-11:** Register **one** **`live_session :ops, on_mount: […]`** wrapping **all** operator LiveViews so **HTTP and WebSocket** share the same auth/session boundary.
- **D-12:** Reserve **`on_mount`** for assigns and auth/halting even if phase 44 stubs some hooks; **defer** LiveView streams, LiveDashboard-in-prod, Oban.Web, heavy i18n, OIDC product, and non-default asset pipelines until later phases or adopters need them.
- **D-13:** Align **feel** with **`examples/phoenix_meilisearch`** (scopes, layouts, telemetry presence) for **least surprise**, without placing OPSUI inside **`examples/`**.

### Security model (OPSUI-08)

- **D-14:** Deliver **documentation plus** a **small, testable fail-closed default in production**: if the OPSUI browser surface would be enabled in **`prod`**, **refuse to start** or **omit `/ops` (and related) routes** until an explicit **`OPSUI_AUTH_MODE`** (or equivalent **documented** env) is set to a **known** value (e.g. **`basic`**, **`proxy_headers`**, with room for **`oidc`** later). **Documentation-only** prod defaults are **insufficient** for this phase.
- **D-15:** **Development** may remain permissive **only** under **`MIX_ENV=dev`** and/or a **clearly named** dev-only flag; **never** infer “safe” from **localhost** inside containers without explicit docs.
- **D-16:** Document **WebSocket** (`/live/websocket`), **cookies**, **CSRF**, **`check_origin`**, TLS, and **reverse-proxy** vs **in-app** auth in **`scrypath_ops/README.md`** and/or **`scrypath_ops/docs/SECURITY.md`**.
- **D-17:** OPSUI **telemetry** from the shell stays **low-cardinality** (e.g. screen viewed, coarse outcome)—**no** query text, **no** per-record IDs in event metadata; align with **`docs/search-backend-sre.md`**.

### Claude's Discretion

- Exact **`OPSUI_AUTH_MODE`** enum strings and optional “escape hatch” env name for advanced operators.
- Exact **`ScrypathOpsWeb`** module prefix vs alternative naming.
- Minor layout/styling details that do not change security, nav order, or packaging boundaries.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 44 goal, success criteria, requirement IDs (**OPSUI-06**..**OPSUI-09**).
- `.planning/REQUIREMENTS.md` — Full acceptance text for **OPSUI-06**, **OPSUI-07**, **OPSUI-08**, **OPSUI-09**; out-of-scope table for OPSUI.
- `.planning/PROJECT.md` — Product boundary (Ecto-first, Meilisearch-first v1, operational honesty, optional OPSUI outside Hex).

### Telemetry and operator discipline

- `docs/search-backend-sre.md` — Low-cardinality telemetry and operational expectations relevant to OPSUI instrumentation copy and future screens.

### Consumer integration reference (patterns only)

- `examples/phoenix_meilisearch/README.md` — Clone/run and env expectations for a Phoenix app using Scrypath in-repo.
- `examples/phoenix_meilisearch/lib/scrypath_demo_web/router.ex` — Example of conventional Phoenix routing and layout wiring (mirror idioms, not location).

### Federation and honesty (context for nav copy and phase 46 alignment)

- `guides/multi-index-search.md` — Federation semantics, `:all`, merge behavior—inform stub copy and docs pointers so the shell does not imply a misleading “single merged index.”

### Planning research (optional depth)

- `.planning/research/SUMMARY.md` — v1.10 OPSUI research snapshot if present.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`examples/phoenix_meilisearch/`** — Full Phoenix app demonstrating **`{:scrypath, path: "../../"}`**-style wiring, **`Scrypath`** integration, conventional **`_web`** tree, **`config/runtime.exs`** secrets pattern—reuse **patterns**, not the **`examples/`** path for OPSUI itself.

### Established patterns

- **Single-package library** at repo root with **`examples/*`** excluded from typical Hex packaging—extend the same discipline to **`scrypath_ops/`**.
- **Docs contract style** — Project uses **`docs_contract_test.exs`** for pinned headings; OPSUI docs may later get similar treatment in phase **47**—do not introduce unbounded prose drift in phase 44.

### Integration points

- OPSUI will call **public** **`Scrypath.*`** APIs only (no reaching into private modules); actual data wiring lands in phases **45–46**.
- **`mix`** tasks and **`guides/`** linked from read-only triage views—document URLs or paths in **`operator-ia.md`** as they exist today.

</code_context>

<specifics>
## Specific Ideas

- Subagent research compared **Searchkick**, **Sidekiq Web**, **Laravel Horizon**, **Meilisearch** packaging, and **Kubernetes dashboard** failure modes; synthesis favors **explicit mount + explicit prod auth** and **thin Hex core**.
- User requested **all four** foundation areas (layout, personas/nav, Phoenix shell, security) in one coherent bundle aligned with **least surprise**, **great DX**, and **Scrypath’s** Ecto-first / operational-honesty vision.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 45:** Landing posture, **`failed_sync_work/2`** triage UI, read-only sync/drift screens with links to Mix/docs.
- **Phase 46:** Bounded search playground, **`search_many/2`** / federation inspector with honest partial-failure and weight semantics.
- **Phase 47:** **`LiveViewTest`** (or thin smoke) CI job for **`scrypath_ops`**, critical copy/structure pins.
- **Published Hex package** `scrypath_ops` (Oban Web–style)—only if adoption pressure appears; not phase 44.

</deferred>

---

*Phase: 44-opsui-foundations*
*Context gathered: 2026-04-20*
