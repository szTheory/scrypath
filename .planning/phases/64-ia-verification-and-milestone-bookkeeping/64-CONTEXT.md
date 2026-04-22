# Phase 64: IA, verification, and milestone bookkeeping - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **OPS2-05**, **OPS2-06**, and **OPS2-08** for **v1.15**: keep **`operator-ia.md`**, **`router.ex`**, **`ScrypathOpsWeb.Nav.primary/0`**, **`mix scrypath_ops.check_nav_contract`**, and **`operator_ia_contract_test`** aligned; ensure **`mix verify.opsui`** remains the honest contributor gate for **new** operator surfaces (stub-first, no mandatory live Meilisearch); and complete **milestone-close traceability** (rolling planning truth + frozen milestone bundle where applicable) consistent with **SHIP-01** and prior **v1.14** precedent.

No new product capabilities—only truth alignment, tests, contracts, and planning artifacts.

</domain>

<decisions>
## Implementation Decisions

### Coherent principles (all areas)

These decisions intentionally reinforce each other:

- **Structural IA truth in code + machine-checked doc** — `Nav.primary/0` is authoritative for primary nav order, labels, and routes; `operator-ia.md` nav table + `scrypath:nav-contract-*` JSON stay mechanically aligned via **`mix scrypath_ops.check_nav_contract`** (and **`--write`** when code leads).
- **Normative procedures live in guides** — recovery, drift, GitOps, and playbook wire semantics stay in **`guides/*.md`**, **`playbook-schema-v1.md`**, **`docs/team-playbook-persistence.md`**, etc. IA links *out*; it does not duplicate runbooks (operational honesty, least surprise).
- **Contributor gate = default `mix verify.opsui`** — full **`scrypath_ops` `mix test`** (already includes Postgres/Ecto); extend with **stub-backed** LiveView coverage for **primary operator actions** shipped in **62–63**; never require live Meilisearch on this path (use existing root **`mix verify.meilisearch_smoke`** or tagged jobs for that tier).
- **Ship boundary vs release artifact** — Milestone bookkeeping (**OPS2-08**) synchronizes **`.planning/`** truth and frozen **`milestones/v1.15-*`** evidence; **Hex version + changelog** stay on the **release PR / Release Please** spine unless the milestone is explicitly declared “tagged drop in same merge.”
- **Doc contracts = stable anchors only** — Extend **`docs_contract_test.exs`** when phases introduce **adoption-critical** strings (new **`mix scrypath_*`** tasks, verify-matrix wording, README/CONTRIBUTING/CI step ordering); avoid README-wide golden snapshots or prose-level locks.

### IA depth vs minimal sync (OPS2-05)

- **D-01 (baseline — always):** On every nav-affecting change: update **`ScrypathOpsWeb.Nav`**, run **`mix scrypath_ops.check_nav_contract`** ( **`--write`** when the fence should follow code ), keep **`operator_ia_contract_test`** green, and ensure the **Navigation** table lists every **primary** `/ops` route with correct label and follow-up pointer column.
- **D-02 (milestone-targeted “deep” pass):** When **62–63** (or future work) changes **what jobs exist** or **which canonical doc answers a follow-up**, do a **limited** refresh of **JTBD** / persona-adjacent copy: short edits, **follow-up column = links** into the single canonical guide—**not** pasted procedures. Do **not** expand IA into a second runbook or tie JTBD lines to volatile “phase N” promises unless rewritten to stable shipped language.
- **D-03:** New surfaces (e.g. team GitOps, **`mix scrypath_ops.playbooks.validate`**) get **at most** one extra nav/JTBD row + link into the **golden** doc path—same pattern as **Securing `/ops`**: host-owned auth stays documented once, linked from IA.

### `mix verify.opsui` coverage (OPS2-06)

- **D-04:** **Definition of done** for this milestone: for each **primary action** or **new route** reflected in **`operator-ia.md`**, either **(a)** existing contract tests already enforce presence/alignment, or **(b)** add **one stub-backed `Phoenix.LiveViewTest` vertical** that completes the **happy path** (event → visible outcome and, where relevant, filesystem side effect under temp workspace)—mirroring **OPS-PB-05** discipline extended to **62–63** flows (capture → preview → save, catalog rename/duplicate/metadata, etc.) as gaps are found in audit.
- **D-05:** Prefer **unit / `V1` / Store / Mix task tests** for branch-heavy validation; use **LiveViewTest** where **events, forms, flash, or wiring** matter—test pyramid, least surprise for contributors.
- **D-06:** **Reject** adding default-suite tests that start **Meilisearch**, hit **real HTTP** to a search backend, or depend on **browser** drivers; point heavy integration to **existing or new explicit** verify tasks / tags documented in **CONTRIBUTING**.
- **D-07:** If the suite grows painful, introduce a **documented** second tier (**tag** + `mix test --exclude …`) **only after** measured need; until then **do not** widen the gap between “local quick path” and CI without an explicit decision in a later phase.

### Milestone close and SHIP bookkeeping (OPS2-08)

- **D-08:** At **v1.15** milestone close, produce the **same class of frozen bundle** as **v1.14**: **`.planning/milestones/v1.15-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`** capturing intent, shipped outcomes, and explicit deferrals—then update **rolling** canon (**`MILESTONES.md`**, **`ROADMAP.md`**, **`REQUIREMENTS.md`** traceability table, **`PROJECT.md`** current milestone / Hex narrative, **`STATE.md`** as needed).
- **D-09:** Treat frozen milestone files as **immutable evidence** after close (typos only with rationale)—do not “continue editing” them as living docs.
- **D-10:** **Hex line / `mix.exs` version** and **CHANGELOG** assembly stay on the **release automation path** (Release Please release PR or equivalent). **OPS2-08** work may **record** the published version and link planning → changelog, but **does not** silently bundle an unrelated feature merge + version bump unless explicitly scoped as a single release merge.
- **D-11:** **`REQUIREMENTS.md`** traceability rows for **OPS2-01..08** move to **Complete** only when verification evidence and docs agree (no traceability theater).

### `docs_contract_test` expansion

- **D-12:** When **62–63** introduced **operator- or contributor-facing** commands, paths, or verify-matrix promises, add **minimal anchors** to **`test/scrypath/docs_contract_test.exs`**: exact **`mix …`** strings where copy-paste safety matters, **ordered** step lists where README/CONTRIBUTING/CI must agree, headings or env vars that encode policy—**not** full paragraphs or marketing copy.
- **D-13:** Prefer **regex alternates** only where the project already tolerates equivalent wording; avoid locking internal module names into published README (existing hygiene continues).
- **D-14:** Keep **ExDoc `mix docs --warnings-as-errors`** (or equivalent) in the broader verify story where already present; contract tests complement link/compile hygiene—they do not replace it.

### Claude's Discretion

- Exact list of **which** `LiveViewTest` files receive new cases once gap-audit runs during execute-phase.
- Minor wording in **JTBD** rows as long as D-02’s “link out, don’t duplicate runbooks” rule holds.
- Whether **`docs_contract_test`** splits into submodules in a future hygiene phase if file size becomes a maintainer burden—**not** required in **64** unless trivially opportunistic.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/REQUIREMENTS.md` — **OPS2-05**, **OPS2-06**, **OPS2-08**; traceability table.
- `.planning/ROADMAP.md` — Phase **64** goal and success criteria.
- `.planning/PROJECT.md` — v1.15 vision, OPSUI boundaries, Hex narrative conventions.

### Prior phase context (adjacent shipped work)

- `.planning/phases/62-playground-capture-and-playbook-catalog/62-CONTEXT.md` — capture, catalog, metadata; IA deferral note for **OPS2-05**.
- `.planning/phases/63-bounded-team-persistence-and-security-posture/63-CONTEXT.md` — team GitOps doc, validation task, security posture; **OPS2-06** formalization deferred here.

### Frozen precedent (milestone close pattern)

- `.planning/milestones/v1.14-ROADMAP.md` — archive shape reference.
- `.planning/milestones/v1.14-REQUIREMENTS.md` — traceability + evidence pattern.
- `.planning/milestones/v1.14-MILESTONE-AUDIT.md` — audit depth reference for **v1.15** audit file.

### Operator IA + nav authority (code + doc)

- `scrypath_ops/docs/operator-ia.md` — personas, JTBD, navigation table, nav-contract fence, securing `/ops`.
- `scrypath_ops/lib/scrypath_ops_web/nav.ex` — **`Nav.primary/0`** source of truth.
- `scrypath_ops/lib/scrypath_ops_web/router.ex` — live routes under `/ops`.
- `scrypath_ops/lib/mix/tasks/scrypath_ops/check_nav_contract.ex` — doc ↔ nav sync.
- `scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs` — contract tests.

### Contributor verify + doc contracts

- `lib/mix/tasks/verify.opsui.ex` — root contributor gate ( **`cd scrypath_ops && mix test`**, **`CI=true`**, no Meilisearch).
- `scrypath_ops/mix.exs` — **`test`** alias (`check_nav_contract`, Ecto, `test`).
- `test/scrypath/docs_contract_test.exs` — README / CONTRIBUTING / CI / guide anchors.
- `CONTRIBUTING.md` — verify matrix, **`scrypath-ops`** job expectations.

### Normative operator docs (linked from IA, not duplicated)

- `scrypath_ops/docs/playbook-schema-v1.md`
- `scrypath_ops/docs/team-playbook-persistence.md` (or path shipped in **63**)
- `guides/operator-mix-tasks.md`, `guides/drift-recovery.md`, `guides/sync-modes-and-visibility.md` — as linked from IA table.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`ScrypathOpsWeb.Nav.primary/0`** + **`mix scrypath_ops.check_nav_contract`** — established mechanical alignment between code and **`operator-ia.md`** JSON fence.
- **`operator_ia_contract_test.exs`** — enforces doc structure, nav JSON parseability, and route coverage expectations.
- **`Phoenix.LiveViewTest`** suites under **`scrypath_ops/test/scrypath_ops_web/live/`** with **`SearchPlaygroundStubAdapter`** / **`async: false`** where `Application` env is mutated — pattern for new stub verticals.
- **`Mix.Tasks.Verify.Opsui`** — single documented contributor entry from repo root.

### Established patterns

- **Test pyramid:** **`Playbook.V1`** / **`Store`** unit tests for JSON and FS; LiveView for wiring; static contracts for IA drift.
- **Stub-first OSS gate:** default **`verify.opsui`** matches **CONTRIBUTING** / task **moduledoc** — Postgres allowed, Meilisearch not on this path.

### Integration points

- **`layouts.ex`** consumes **`Nav.primary/0`** for chrome—any nav change touches **Layout + IA doc + contract task + tests**.
- Root **`docs_contract_test`** cross-checks contributor-facing strings against **README**, **CONTRIBUTING**, and **CI** workflows.

</code_context>

<specifics>
## Specific Ideas

- Research synthesis (**2026-04-22**): **Minimal IA + machine checks** as the always-on spine matches **LiveDashboard-style “registry drives chrome”** and avoids **Grafana/K8s-style nav + prose drift**; **Sidekiq-style** lesson is thin web UI tests + strong library docs. **Milestone frozen trio** matches existing **v1.14 SHIP** evidence habit. **Doc contracts** follow Scrypath’s existing **substring / ordering / hygiene** style—not snapshot READMEs.

</specifics>

<deferred>
## Deferred Ideas

- **Browser E2E** (Playwright) and **live Meilisearch-in-CI** for OPSUI — remain deferred per **`.planning/REQUIREMENTS.md`** Tier C / project candidates; not part of **OPS2-06** default gate.
- **Split `docs_contract_test`** into multiple modules — optional hygiene if file size becomes painful; not a **64** requirement.

</deferred>

---

*Phase: 64-ia-verification-and-milestone-bookkeeping*  
*Context gathered: 2026-04-22*
