# Phase 48: IA and JTBD alignment - Context

**Gathered:** 2026-04-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **OPSUX-01** and **OPSUX-02** for **v1.11**: provable alignment between **`scrypath_ops/docs/operator-ia.md`**, **`/ops`** routes in **`router.ex`**, primary nav in **`layouts.ex`**, and maintainer **contract tests**; plus a **posture / health** landing where a new on-call operator can answer **“what do I check next?”** using explicit, ordered next steps and links—**without** new write-side recovery semantics beyond existing **Scrypath** / Mix / guide contracts.

**In scope (requirements):**

- **OPSUX-01:** Nav labels, order, and **`/ops`** route set stay consistent with **`operator-ia.md`** (with a maintainer guard such as extended **`operator_ia_contract_test`** and/or **`mix … --check`**).
- **OPSUX-02:** Posture surfaces **healthy / degraded / broken** (or equivalent) with **explicit next checks** (docs, Mix pointers, in-shell links) aligned with **JTBD 1** in **`operator-ia.md`**.

**Out of scope for this phase:** Visual hierarchy polish, full theming pass, deep a11y work, and broad new LiveView features—those are **phases 49–50** and **REQUIREMENTS.md** **OPSUX-03**..**OPSUX-07**.

</domain>

<decisions>
## Implementation Decisions

### IA contract scope (nav, routes, labels)

- **D-01:** Lock **ordered** primary nav as **`{path, label}`** tuples: **route order** must match **JTBD 7** triage story (posture → failed sync → sync/drift → search), and **labels** must match the **Top nav label** column intent in **`operator-ia.md`**. Extend beyond **routes-only** parity; do **not** assert broad shell chrome (classes, flash markup, theme toggle)—that is **phase 49** noise for CI.
- **D-02:** Keep **router** as authority for **what Live routes exist** under the **`/ops`** `live_session`; **nav** is the **curated subset** shown in chrome. Tests must fail if a **new `live` under that session** is not reflected in the **nav contract** and doc (or an explicit, reviewed “not in nav” escape hatch—default **none** for current four surfaces).

### Source of truth and drift prevention

- **D-03:** Treat **Elixir as the source of truth** for the ordered nav list: a dedicated module (e.g. **`ScrypathOpsWeb.Nav`**) exposing **`primary/0`** (or equivalent) with **`~p`** paths and **labels**. **`layouts.ex`** (`shell: :ops`) **renders nav only from this module**—no duplicated string literals for those four items.
- **D-04:** **`operator-ia.md`** keeps **Personas**, **JTBD**, and narrative **hand-written**. The **navigation table** (or a **clearly delimited** machine-owned block inside the same file) is **kept in sync mechanically**: prefer a **`mix … --check`** (or **`--write`**) task that **regenerates or verifies** only the delimited section from **`Nav.primary/0`**, so CI fails on drift **without** fragile regex over the entire markdown file.
- **D-05:** If a **machine fence** (YAML/JSON) is used instead of full table regen, it must still be the **single** structured nav list compared to **`Nav.primary/0`**; avoid maintaining **three** independent copies (doc table, HEEx, test strings).

### Posture landing (“explicit next checks”, OPSUX-02)

- **D-06:** Posture shows **one evidence-backed headline** state (Healthy / Degraded / Broken or equivalent) plus a **short evidence line** tied to existing signals (e.g. **`Scrypath.sync_status/2`**, aggregate error count, missing backend / empty allowlist)—**no** new recovery verbs or implied guarantees the library does not support.
- **D-07:** **“Next checks”** are a **fixed small ordered list** (target **≤ 5** items). Each item: **imperative + object + single primary egress**—either another **`/ops`** LiveView, an **anchored guide** link, or a **`mix scrypath.*`** pointer consistent with **`operator-ia.md`** follow-up column—**not** a wall of equal-weight links.
- **D-08:** Optional **`<details>`** (or equivalent) **collapsed runbook**: **links only** to guides / docs / sections; **do not** paste long **`guides/*.md`** prose into LiveView (avoids doc drift).
- **D-09:** **No** primary **Fix / Repair / Sync now** actions unless they are thin, honest affordances already backed by documented operator flows; default posture toward **read-only + “copy command” + doc link** over mutation in this shell.

### Sequencing (within phase 48)

- **D-10:** **Implementation order:** (1) **`Nav` module + wire `layouts.ex`** with parity tests, (2) **doc mechanical sync** (`mix --check` or fence validation), (3) **posture skeleton** (headline + next-checks **region** + stable **`data-testid` / landmark** hooks), (4) **structural LiveView tests** (presence, order, max count—not full copy equality), (5) **copy and runbook polish**.

### Claude's Discretion

- Exact **Mix task** strings and **guide anchors** named in next-check rows (as long as they match **`operator-ia.md`** and existing guides).
- Markdown fence **syntax** (JSON vs YAML vs HTML comment markers) and **Mix task module name** (`ScrypathOps.Mix.Tasks.*` vs umbrella task naming).
- Precise **Broken vs Degraded** thresholds where the library already leaves judgment to operators—surface **rules of thumb** in copy without inventing new metrics APIs in this phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **OPSUX-01**, **OPSUX-02**; out-of-scope table for v1.11.
- `.planning/ROADMAP.md` — Phase **48** success criteria and milestone placement.

### Operator IA and routing

- `scrypath_ops/docs/operator-ia.md` — Personas, **JTBD 1–7**, navigation table, triage ordering intent.
- `scrypath_ops/lib/scrypath_ops_web/router.ex` — **`live_session :ops`** and **`/ops`** `live` routes.
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex` — **`:ops`** shell and primary nav (to be driven from **`Nav`** per **D-03**).

### Current implementation and tests

- `scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs` — Existing **operator-ia** / **router** contract baseline to extend.
- `scrypath_ops/lib/scrypath_ops_web/live/posture_live.ex` — Posture / health LiveView (**OPSUX-02** target surface).

### Follow-up docs cited from IA (non-exhaustive; align links with table)

- `guides/meilisearch-operations.md` — Operator Meilisearch expectations (see **`operator-ia.md`** nav table).
- `guides/operator-mix-tasks.md` — Mix task index for operators.
- `guides/drift-recovery.md`, `guides/sync-modes-and-visibility.md` — Sync/drift context.
- `guides/multi-index-search.md` — Federation semantics for search job.
- `docs/search-backend-sre.md` — SRE-style expectations where cited.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`OperatorIaContractTest`:** Already reads **`operator-ia.md`** and **`router.ex`** at compile time; asserts doc spine order, **`| Route |`** column, and presence of all **`/ops/...`** paths. Extend toward **label + order + `Nav`** invariants rather than replacing with heavy **`LiveViewTest`** snapshotting.
- **`Layouts.app/1` (`shell: :ops`):** Four top-nav **`~p`** links with labels matching **`operator-ia.md`** today—candidate to replace with a **`for`** over **`Nav.primary/0`**.
- **`PostureLive`:** Assigns **`page_title`**, **`aggregate_error_count`**, telemetry **`:ok` / `:degraded`** on refresh; empty allowlist and missing-backend copy already point to **`scrypath_ops/README.md`**—extend with **next-checks** block without changing sync APIs.

### Established patterns

- **Read-only ops shell:** No write-side recovery beyond documented library and Mix paths (consistent with v1.10 OPSUI boundary).
- **Verified routes:** Prefer **`~p"/ops/..."`** in nav and tests aligned with Phoenix 1.7+ conventions.

### Integration points

- **`router.ex`** `live_session :ops` ↔ **`Nav`** curated list ↔ **`layouts.ex`** chrome ↔ **`operator-ia.md`** machine block ↔ **contract test** + optional **`mix`** check.

</code_context>

<specifics>
## Specific Ideas

- Cohesive **nav-as-data** pattern: industry operators (Sidekiq-style boring UIs, structural nav tests in large SaaS) converge on **data + structural CI**, not full-template string equality.
- On-call UX: **AWS Health**-style **headline → evidence → ordered actions**; avoid **marketing** reassurance strings.
- Discussion and research thread (2026-04-21): subagent research on contract depth, doc vs code SOT, posture next-checks, and delivery sequencing—captured above as **D-01**..**D-10**.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 49:** Page chrome, scan-friendly panels, **light/dark/system** polish, Phoenix layout/component inconsistencies (**OPSUX-03**..**OPSUX-05**).
- **Phase 50:** Heading order, landmarks, control labels, extended **LiveView** / contract CI (**OPSUX-06**, **OPSUX-07**).
- **ROADMAP tooling:** Adding **`### Phase 48:`** (and **49**, **50`) detail sections for GSD **`roadmap.analyze`** / **`init.phase-op`** compatibility—meta maintenance, not product scope.

**Reviewed todos (not folded):** None.

</deferred>

---

*Phase: 48-ia-and-jtbd-alignment*
*Context gathered: 2026-04-21*
