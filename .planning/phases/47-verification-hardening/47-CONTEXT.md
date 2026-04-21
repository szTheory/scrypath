# Phase 47: Verification & hardening - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Satisfy **OPSUI-10**: maintainer-facing automated verification for **`scrypath_ops/`** in CI (same spirit as **`phoenix-example-integration`**), plus **anti-drift** guards so operator-critical copy, nav/IA, and honesty semantics cannot silently diverge from **`router.ex`**, **`operator-ia.md`**, and prior OPSUI decisions (**phases 44–46**). No new product capabilities—verification, CI wiring, and contract tests only.

</domain>

<decisions>
## Implementation Decisions

### CI entry shape (hybrid, sibling-app idioms)

- **D-01:** Add a **dedicated GitHub Actions job** for OPSUI that **`cd scrypath_ops`**, runs **`mix deps.get`** and **`mix test`** (or the app’s documented test entry), mirroring **`.github/workflows/ci.yml`** → **`phoenix-example-integration`**: separate **`scrypath_ops/deps`** and **`scrypath_ops/_build`** cache paths; cache key **must** include **`hashFiles('scrypath_ops/mix.lock', 'mix.lock')`** so parent library changes invalidate the ops build.
- **D-02:** **Service requirements for that job:** provide **Postgres** (the **`scrypath_ops`** **`test`** alias runs **`ecto.create`** / **`ecto.migrate`**) with the same **wait-for-ready** discipline as the example job; **do not** add a Meilisearch service to the default OPSUI CI job—keep it **stub / operator-injection** only (see D-12..D-14).
- **D-03:** **Path-based gating on pull requests:** run the OPSUI job when **`scrypath_ops/**`**, **`lib/**`**, root **`mix.exs`**, or root **`mix.lock`** / **`scrypath_ops/mix.lock`** change—so library refactors that break the path dependency are caught without running OPSUI on **docs-only** edits. **Always run** the OPSUI job on **`push` to `main`** (and release flows if applicable), even when filters would skip it on a PR—avoids “green PR, red main” surprises from merge interactions.
- **D-04:** Add root **`mix verify.opsui`** (new alias in repo-root **`mix.exs`**, **`preferred_envs: [verify.opsui: :test]`**) that **delegates** to the same commands CI uses (e.g. `Mix.Shell.cmd` with explicit cwd to **`scrypath_ops`** or documented equivalent). Purpose: **contributor DX** and alignment with existing **`mix verify.*`** culture—not a second truth source beyond **`cd scrypath_ops && mix test`**.
- **D-05:** **Formatting / quality:** ensure **`mix format --check-formatted`** covers **`scrypath_ops`** from either the ops app or root formatter config—avoid “CI green at root but ops unformatted” drift (exact mechanism at planner discretion).

### Anti-drift strategy (hybrid: docs spine + LiveView hooks)

- **D-06:** **No full-page HTML golden snapshots** for OPSUI in v1.10—they are brittle, review-hostile, and fight active iteration; defer visual regression tooling (Percy-class) to a **future** optional gate if ever needed.
- **D-07:** **Markdown / IA contracts:** add a **narrow** contract test module colocated with **`scrypath_ops`** (under **`scrypath_ops/test/`**, same discipline as root **`test/scrypath/docs_contract_test.exs`**) that pins **`scrypath_ops/docs/operator-ia.md`**: stable **heading spine**, **primary nav order**, **`/ops/...` routes** aligned with **`scrypath_ops/lib/scrypath_ops_web/router.ex`**, and **required cross-links** where those links are operator promises (keep assertions **substring / ordering**, not prose quality).
- **D-08:** **LiveView tests:** extend existing **`Phoenix.LiveViewTest`** patterns under **`scrypath_ops/test/scrypath_ops_web/live/`**: prefer **`data-testid`** (and **`element/2` + `render_*`**) for structural assertions; use **`html =~`** only for **policy-bearing** copy (limits like **50**, federation honesty lines, partial-success vs hard-error semantics per **46-UI-SPEC**), not decorative microcopy.
- **D-09:** If the **same** legal/semantic line must exist in **both** IA doc and templates, prefer **one** source (module attribute, shared function, or partial) **only when duplication actually appears**—otherwise duplicate is acceptable until friction shows.

### Minimum “critical wiring” slice (OPSUI-10 must-haves)

- **D-10:** **Security / boundary:** tests prove **fail-closed prod** behavior for **`/ops`** per **44 D-14** (unknown/missing auth mode → routes omitted or boot refused—match implemented semantics). Prove **`live_session :ops`** applies a **consistent** halt for **HTTP + LiveView mount** (no “cookie auth on page, naked socket” gap).
- **D-11:** **Allowlist-only targeting:** with explicit **`Application.put_env(:scrypath_ops, :schema_allowlist, ...)`** (restore in **`on_exit`**), assert screens never widen targets beyond config—coherent with **45 D-01** and **46 D-18**.
- **D-12:** **Posture honesty:** at least one injected mix of **`{:ok, %Scrypath.Operator.Status{}}`** and **`{:error, _}`** rows shows **per-row** errors and **no** fleet-level “all healthy” fiction (**45 D-06–D-07**).
- **D-13:** **Failed sync snapshot invariant:** with **`reason_class_counts: true`**, header **`counts`** stay consistent with **`entries`** for a **fixed injected** **`%Scrypath.Operator.FailedSyncWorkInspection{}`** snapshot (**45 D-09–D-12**).
- **D-14:** **Sync/drift separation:** default path does **not** bundle **`include_index_contract_drift: true`** into reconcile; drift section can error without blanking reconcile (**45 D-15–D-17**).
- **D-15:** **Injection path:** critical LiveViews must be exercised through **`Scrypath`** **operator opts** / documented injectors (**45 D-20**)—**no real Meilisearch or Oban** in the default OPSUI CI job.
- **D-16:** **Search / federation (already shipped in phase 46):** keep and extend stub-backed tests for **bounds** (e.g. page size ceiling), **no auto-run `search_many/2` on mount**, and **distinct partial vs hard-error** presentation (**46-UI-SPEC** + **46-CONTEXT** D-02, D-09, D-15–D-16).
- **D-17:** **Nav / router parity:** lightweight check that **primary nav `~p`/routes** in layout or router still match **`operator-ia.md`** table (**44 D-08**)—can be satisfied by the doc contract module in **D-07** if coverage is complete.

### External dependencies in CI (layered, repo-aligned)

- **D-18:** **Default OPSUI CI = deterministic:** stubs, **`Req.Test`**, and **`Scrypath`** operator injection only—aligned with root **`mix test --exclude integration`** philosophy and existing **`scrypath_ops`** tests.
- **D-19:** **Do not** require Dockerized **Meilisearch** for the **`scrypath_ops`** job; wire/API confidence against a real server stays in **existing** jobs (**`phase5-verification`**, **`meilisearch-smoke`**, **`phoenix-example-integration`**, tagged **`:integration`** library tests)—avoid duplicating a second heavy stack for OPSUI.
- **D-20:** If a future regression proves “mocks lied” about a **narrow** Meilisearch edge, add **one** additional tagged test or extend an **existing** integration job—**not** a blanket “real cluster for every LiveView” policy.

### Claude's Discretion

- Exact **`paths:` / `paths-ignore:`** YAML for PR gating; single OTP/Elixir row vs matrix for OPSUI job (bias: **one** row matching **`phoenix-example-integration`** for speed unless policy demands matrix).
- Whether **`verify.opsui`** also runs **`mix format --check-formatted`** inside **`scrypath_ops`**.
- Placement/name of the ops doc contract test module (**`*_contract_test.exs`** naming).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/ROADMAP.md` — Phase 47 goal, **OPSUI-10** success criteria.
- `.planning/REQUIREMENTS.md` — **OPSUI-10** acceptance text; out-of-scope table.
- `.planning/PROJECT.md` — OPSUI outside Hex, operational honesty, least surprise.

### Prior OPSUI context (locked product decisions)

- `.planning/phases/44-opsui-foundations/44-CONTEXT.md` — Packaging, **`live_session :ops`**, prod fail-closed auth, nav order, **`operator-ia.md`** authority.
- `.planning/phases/45-posture-failure-triage/45-CONTEXT.md` — Allowlist, posture/failed-sync/sync-drift honesty, operator opts injection testing (**D-20**).
- `.planning/phases/46-search-federation-honesty/46-CONTEXT.md` — Search bounds, URL mode, federation UI decisions.
- `.planning/phases/46-search-federation-honesty/46-UI-SPEC.md` — Locked UI/copy semantics for search/federation surfaces.

### CI and example patterns (implementation templates)

- `.github/workflows/ci.yml` — **`phoenix-example-integration`** job (Postgres + Meilisearch + dual lockfile cache pattern—**reuse structure for OPSUI minus Meilisearch**); root **`test`** job **`--exclude integration`**.

### OPSUI implementation truth

- `scrypath_ops/mix.exs` — **`test`** alias (**Ecto** setup).
- `scrypath_ops/lib/scrypath_ops_web/router.ex` — **`/ops`** routes.
- `scrypath_ops/docs/operator-ia.md` — JTBD ↔ nav ↔ routes.
- `scrypath_ops/README.md` / `scrypath_ops/docs/SECURITY.md` — Auth env contract.
- `scrypath_ops/test/scrypath_ops_web/live/` — Existing **`LiveViewTest`** patterns.

### Library doc-contract precedent

- `test/scrypath/docs_contract_test.exs` — Spine / ordering / hygiene pattern to mirror narrowly for OPSUI docs.

### Discipline

- `docs/search-backend-sre.md` — Low-cardinality telemetry expectations (reference if adding CI guards on telemetry metadata).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`phoenix-example-integration` CI job** — Template for services, wait loops, and **per-subproject** `deps`/`_build` caching.
- **`test/scrypath/docs_contract_test.exs`** — Pattern for pinned headings and ordered anchors without snapshotting HTML.
- **`scrypath_ops/test/scrypath_ops_web/live/*_test.exs`** — ConnCase + **`Phoenix.LiveViewTest`**, **`async: false`**, env restore in **`on_exit`**, stub adapters (**`SearchPlaygroundStubAdapter`**, etc.).

### Established patterns

- Root **`mix verify.*`** aliases with **`preferred_envs`** — **`verify.opsui`** should join this family.
- Library CI excludes **`:integration`** by default; heavy Meilisearch jobs are **separate workflow jobs**.

### Integration points

- **`.github/workflows/ci.yml`** — Add OPSUI job and (optionally) invoke **`mix verify.opsui`** from a **`quality`** step only if you want a single entry in that job; primary recommendation is a **parallel job** mirroring the example app.

</code_context>

<specifics>
## Specific Ideas

- User requested **all four** verification gray areas be researched (subagents) and resolved in **one coherent package**: hybrid CI + hybrid anti-drift + risk-based critical wiring + **no Meilisearch in default OPSUI CI**, aligned with Scrypath’s **deterministic CI**, **Hex boundary**, and **operator-truth** goals.

</specifics>

<deferred>
## Deferred Ideas

- **Full browser E2E** (Playwright/Cypress) for every OPSUI screen — unnecessary for v1.10 if LiveView + injection covers wiring.
- **Visual regression as default gate** — deferred per **D-06**; revisit only if OPSUI churn drops and visual debt dominates.
- **Real Meilisearch inside `scrypath_ops` CI** — deferred per **D-19**; use existing library/example integration jobs instead.
- **Exhaustive sort/pagination/virtualization matrices** — low priority vs honesty and security regressions.

### Reviewed Todos (not folded)

- None — **`todo.match-phase`** returned no matches for phase 47.

</deferred>

---

*Phase: 47-verification-hardening*
*Context gathered: 2026-04-21*
