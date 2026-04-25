# Phase 65: Playbook run lifecycle (OPSUI) - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **OPS3-01** and **OPS3-02** for **`playbook_format: 1`** in **`scrypath_ops`**: operators can start a run from **catalog** and from **detail/preview** with an explicit **idle → running → success/failure** lifecycle (no ambiguous stuck states on **stubbed** CI adapters); failures show a **structured, copy-friendly** surface with **failure class**, message, and **canonical documentation links** within **two hops**.

**Explicitly not in this phase:** formal **runner–library parity tests** and shared **public** error structs in **`scrypath`** core (**Phase 66**); **`mix verify.opsui` / docs_contract** expansion for execution strings (**Phase 67**); **durable** run records, **Oban**-owned playbook execution, **reconnect reattachment** to in-flight server work, and **streaming multi-step logs** (deferred — see `<deferred>`).

</domain>

<decisions>
## Implementation Decisions

### Run entry points (catalog vs preview/detail)

- **D-01:** Keep **inspect-first** as the default mental model: never imply a run happened from a control that only selects a row. Rename or pair copy so **Load** / **Open** means “stage draft, idle run state” only.
- **D-02:** Add a **second catalog action** with an **unambiguous execution label** (e.g. **Run now** or **Run from catalog**) that (1) reads JSON by basename, (2) **Jason.decode** + **`V1.validate`**, (3) assigns the same **`draft_playbook`** as **Load**, (4) immediately invokes the **same** run pipeline as the preview **Run** button (single code path — no duplicate Runner invocation logic).
- **D-03:** The **preview/detail** path remains: validated **`draft_playbook`** present → **Run** uses that identical pipeline. After Phase 65, catalog and preview must not drift on validation or run semantics.
- **D-04:** Optional **UX polish** (planner discretion): scroll/focus/`phx-mounted` hook to the run panel when arriving from catalog so operators always see **which** playbook is executing.

### LiveView lifecycle (`idle` / `running` / `success` / `failure`)

- **D-05:** Replace boolean soup with **one discriminant** in assigns, e.g. **`%RunUI{id: run_id, phase: :idle | :running | :ok | :error, …}`** (names flexible) where **`run_id`** is a **monotonic** reference (integer counter or **:erlang.unique_integer** / UUID) generated at the start of each user-initiated run attempt.
- **D-06:** Execute **`Runner.run_validated/3`** **outside** the synchronous **`handle_event`** body using **`Phoenix.LiveView.start_async/3`** + **`handle_async/3`** (preferred on current LiveView) **or** the same pattern via **`assign_async/3`** if the work maps cleanly to a single assign — **default choice: `start_async` + `handle_async`** so **`cancel_async/3`** and named ops line up with cancellation and timeouts.
- **D-07:** On **`{:noreply, socket}`** from the run request event: transition to **`:running`**, disable run controls, show **spinner + elapsed** (read **`System.monotonic_time`** or **`DateTime.utc_now`** in assigns). Stubbed CI may resolve in one frame; the **same** state machine must still render for tests.
- **D-08:** On **`handle_async`** success: set **`:ok`**, store **`run_result`**, clear **`run_error`**, version-check **`run_id`** before applying (ignore stale completions).
- **D-09:** On **`handle_async`** failure: set **`:error`**, store structured **`run_failure`** (see below), clear **`run_result`**, same **`run_id`** guard.
- **D-10:** **Do not** put **Oban** or **DB persistence** on the default interactive playbook run path in Phase 65 — keeps **`mix verify.opsui`** and stub adapters simple; aligns with “session-scoped operator loop” in **PROJECT.md**. Document deferred durable runs in **`<deferred>`**.
- **D-11:** **Flash** (`put_flash`) is **supplemental** only (quick toast). **Terminal** success/failure copy lives in **assign-backed** UI so it survives navigation within the same LiveView and does not rely on flash-only debugging.

### Timeouts, cancel, disconnect (minimal honest bundle)

- **D-12:** **Wall-clock timeout** for one playbook run: start **`Process.send_after(self(), {:playbook_run_timeout, run_id}, ms)`** when entering **`:running`**; in **`handle_info`**, transition to **`:error`** with a **dedicated reason** (e.g. `:timed_out`) **only if** **`run_id` matches** the active run. Default timeout **60_000 ms** unless planner documents a different constant with rationale (search calls should finish well under this on stubs).
- **D-13:** **Cancel** (soft): expose **Cancel run** while **`:running`**; call **`cancel_async/3`** for the async key used for runs. Document in UI that cancel is **best-effort** (Runner is synchronous inside the task — cancel prevents **applying** the result, not interrupting Meilisearch mid-request, unless the task is killed before completion).
- **D-14:** **New load / import / catalog pick** while **`:running`**: either **disable** file-changing actions with helper copy, or **auto-cancel** the active async + reset to **idle** — pick **one** policy in implementation and test it; **recommended: cancel async + bump `run_id` + reset run UI** so operators never see two concurrent runs from one view.
- **D-15:** **Disconnect / tab close**: do **not** claim the remote search finished or failed; on remount, **idle** with no fabricated history is acceptable for Phase 65. Optional **info** flash on reconnect: short honest line that in-flight UI state may have been lost (no fake **success**). **Deferred:** reconnect to **server-owned** run id (**`<deferred>`**).
- **D-16:** **Double-submit**: run button disabled whenever **`phase == :running`**; server ignores duplicate **`run`** events for the same **`run_id`** if any slip through.

### Structured errors and documentation (“two hops”)

- **D-17:** Introduce a **single enrichment boundary** in **`scrypath_ops`** (module name planner-chosen, e.g. **`ScrypathOps.Playbook.RunError`**) that maps **`Runner` / dispatch `{:error, reason}`** (and **`{:ok, _}`** is not an error) into a **serializable map** with **stable keys**: **`failure_class`**, **`reason`** (inspect of tuple or normalized string per registry row), **`message`**, **`copy`** (allowlisted small map — schema name, basename, page size, **no secrets**), **`doc`** (`%{primary: url, related: [url]}` with **0–2** related max).
- **D-18:** Maintain a **central registry** (keyword map or `@reasons` module attribute table): **`reason` → `{failure_class, message_template_or_fn, doc_ref, copy_allowlist}`**. **`DocResolver`** maps **`doc_ref`** (atom) to **absolute** URL strings using a **configurable base** (e.g. application env for Hex vs self-hosted) + **stable path + fragment** under repo docs / ExDoc extras — **no** raw scattered URLs in LiveView templates.
- **D-19:** **“Two hops”** means: **Hop 1 —** primary doc link lands on a section that states **symptom → cause → fix** for that **`reason`**. **Hop 2 —** at most **one** “deep” link from that page (or the **`related`** list) to API/reference (e.g. **`@moduledoc`** anchor, **`Runner`** ops doc). **Anti-pattern:** primary link is a generic hub with no actionable subsection — fix the doc or choose a deeper primary.
- **D-20:** UI: show **failure class + message** prominently; **Copy JSON** (or “Copy diagnostics”) button encodes the **allowlisted** map for tickets. Replace **only** `search_many` special-casing in templates with **registry-driven** links so **`search`** and **config** failures get first-class docs too.
- **D-21:** **Phase 66 alignment:** keep **`reason`** atoms/tuples produced by **`Runner`** as the **stable contract key**; Phase 66 adds **`scrypath`** tests — **do not** rename **`Runner`** error tags in Phase 65 without a compatibility note in planning.

### Telemetry and testing hooks

- **D-22:** Emit **`telemetry` events** (or reuse existing patterns in **`SearchPlayground`**) for **`playbook_run_start`**, **`playbook_run_stop`** with **`result: :ok | :error | :cancelled | :timeout`**, **`run_id`**, duration — supports future ops dashboards without new UI.
- **D-23:** **`LiveViewTest`**: use **`render_async`** (or documented async test helper) so async run tests are deterministic; add fixtures for **forced failure** (non-empty class/message + **working** `primary` URL per roadmap success criterion).

### Claude's Discretion

- Exact **assign field names** (`run_ui` vs extending **`run_result`/`run_error`**), **button labels**, **timeout constant** within **30_000–120_000 ms** if 60 s proves tight in review, and **minor CSS** for the run panel — provided acceptance criteria and the state machine above are preserved.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 65 goal, success criteria, **OPS3-01** / **OPS3-02** traceability.
- `.planning/REQUIREMENTS.md` — v1.16 operator execution requirements (verbatim acceptance).
- `.planning/PROJECT.md` — v1.16 vision, stub-first OPSUI CI, operational honesty.

### Operator docs and schema

- `scrypath_ops/docs/operator-ia.md` — IA and nav expectations for OPSUI.
- `scrypath_ops/docs/playbook-schema-v1.md` — **`playbook_format: 1`** shape and validation authority.
- `scrypath_ops/docs/team-playbook-persistence.md` — workspace / persistence context for catalog files.

### Implementation anchors

- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` — current catalog, preview, sync **`run`** handler, **`format_run_flash`**, alerts.
- `scrypath_ops/lib/scrypath_ops/playbook/runner.ex` — **`run_validated/3`** result and **`{:error, reason}`** tags.
- `guides/multi-index-search.md` — federation / **`search_many`** operator background (already referenced from OPSUI).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`PlaybookLive`**: **`apply_decoded/3`**, **`Runner.run_validated/3`**, **`format_run_flash/1`**, **`run_result_summary/1`**, catalog row builders — extend rather than parallel new LiveViews unless IA demands it.
- **`Runner`**: tagged **`{:error, term}`** already suitable as registry keys; keep as single execution entry.

### Established patterns

- **DaisyUI / Tailwind** alerts for success/error — evolve into state-machine-driven panels, not one-off flash-only flows.
- **Stub-first** CI: **`SearchPlayground`** dispatch — tests should continue using the same adapter seams as today.

### Integration points

- **`mount/3`** assigns: extend with **`run_ui`** (or equivalent) and async keys; ensure **`connected?/1`** guards if any subscribe/timer setup is added for timeouts.

</code_context>

<specifics>
## Specific Ideas

- **Postman / GitHub Actions** lesson: primary run action should always show **what will execute** (playbook title/basename + mode) adjacent to **Run** / **Run now**.
- **Stripe-like errors**: stable **`reason`** + human **`message`** + optional **`doc`** URL — operators paste JSON into issues.
- **CI lesson**: closing the tab must **not** be interpreted as cancel in Phase 65; true **cancel** is an explicit control (matches user trust for server-side truth later).

</specifics>

<deferred>
## Deferred Ideas

- **Durable runs + reconnect:** persist **`run_id`** (DB or Oban job) and **PubSub** so a refreshed browser **reattaches** to the same terminal state; **sweeper** for stuck **`running`** rows — **new capability**, not Phase 65.
- **Streaming / multi-step progress** inside one **`Runner.run_validated`** (beyond spinner + elapsed) — defer until playbook execution has real multi-step semantics.
- **i18n** for operator strings — English-first registry messages are enough for v1.16; wrap Gettext later if needed.

### Reviewed Todos (not folded)

- None — **`todo.match-phase`** returned no matches.

</deferred>

---

*Phase: 65-playbook-run-lifecycle-opsui*  
*Context gathered: 2026-04-22*
