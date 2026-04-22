# Phase 64 — Technical research

**Phase:** 64 — IA, verification, and milestone bookkeeping  
**Question:** What do we need to know to plan alignment of IA, contributor verify, and v1.15 milestone bookkeeping?

## Summary

Implementation is mostly **audit → minimal edits → mechanical checks → frozen planning bundle**. The repo already has strong **nav ↔ router ↔ `Nav.primary/0`** enforcement (`operator_ia_contract_test.exs`, `mix scrypath_ops.check_nav_contract`). **`PlaybookLiveTest`** already covers stub-backed happy paths (paste, preview, save, list, load, run, duplicate, rename collision, delete confirmation, `search_many`). The largest **discovered gap** vs **63-CONTEXT** / **64-CONTEXT** is **IA follow-up prose**: **`operator-ia.md`** does not yet link **`team-playbook-persistence.md`** from the Navigation table, while that doc is the canonical team/GitOps story from Phase 63. Contributor **`docs_contract_test`** reads **`verify.opsui.ex`** but does not yet anchor **`mix scrypath_ops.playbooks.validate`** if we add that string to **CONTRIBUTING** / guides — align with **D-12** in **64-CONTEXT**.

## Findings

### OPS2-05 (IA spine)

- **`scrypath_ops/lib/scrypath_ops_web/router.ex`** defines exactly five **`live_session :ops`** routes: `/posture`, `/failed-sync`, `/sync-drift`, `/search`, `/playbooks`.
- **`Nav.primary/0`** lists the same five paths and labels; **`operator_ia_contract_test`** asserts router paths ⊆ nav, doc mentions every path, and nav JSON fence parses.
- **`operator-ia.md`** nav table row **4b** points to **`playbook-schema-v1.md`** only — add **`team-playbook-persistence.md`** (and optionally **`guides/operator-mix-tasks.md`** if `validate` is documented there) per **structural IA truth** without duplicating runbooks.

### OPS2-06 (`mix verify.opsui`)

- **`lib/mix/tasks/verify.opsui.ex`**: `cd scrypath_ops && CI=true … mix test`; no Meilisearch.
- **`scrypath_ops/mix.exs`** test alias runs **`check_nav_contract`** then tests — contributor path stays honest when IA changes.
- **LiveView tests** under **`scrypath_ops/test/scrypath_ops_web/live/`** use **`SearchPlaygroundStubAdapter`** and **`async: false`** when mutating **`Application`** env — reuse for any new verticals; current **`playbook_live_test.exs`** already exercises primary playbook flows on stub.
- **Gap-closure method:** run **`mix verify.opsui`** from repo root after edits; grep **CONTRIBUTING** for parity with task **moduledoc** if verify matrix text changes.

### OPS2-08 (milestone bookkeeping)

- **Precedent:** **`.planning/milestones/v1.14-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`** — copy structure for **v1.15**; freeze as evidence; do not silently edit after close (**D-09**).
- **Rolling docs:** **`MILESTONES.md`** (new v1.15 section), **`ROADMAP.md`** (mark **62–64** complete, collapse “next milestone”), **`REQUIREMENTS.md`** traceability rows **OPS2-05/06/08** → **Complete** with evidence pointers, **`PROJECT.md`** current milestone, **`STATE.md`** last activity — match **SHIP-01** habit from **v1.14**.
- **Hex / changelog:** record published version in planning if known; do not conflate with Release Please unless explicitly scoped (**D-10**).

### Security / abuse (operator docs)

- Misleading persistence or auth wording could cause operators to expose **`/ops`** or shared JSON workspaces — keep **host-owned auth** and **single authority** language consistent with **63** docs.

## Dependencies & risks

- **`gsd-sdk query milestone.complete`** has historically failed (`version required for phases archive`) — plan explicit **manual** archive steps if automation still broken (**MILESTONES.md** note pattern from v1.14).
- **Nyquist / traceability:** prior milestone audit flagged **SUMMARY** frontmatter gaps — when closing **v1.15**, prefer **VERIFICATION.md** + plan **SUMMARY** evidence for **OPS2-*** rows where feasible.

## Validation Architecture

Phase 64 validation is **ExUnit-heavy** with a **root Mix gate**:

| Dimension | Approach |
|-----------|----------|
| **Automated default** | From repo root: **`mix verify.opsui`** (runs **`scrypath_ops`** deps + **`mix test`** with **`CI=true`**). |
| **IA mechanical sync** | From **`scrypath_ops/`**: **`mix scrypath_ops.check_nav_contract`** (and **`--write`** when code leads the JSON fence). |
| **Root doc contracts** | **`mix test test/scrypath/docs_contract_test.exs`** (or full root **`mix test`** per CI). |
| **Sampling** | After each plan’s tasks: run **`mix verify.opsui`** when **`scrypath_ops/`** or root verify/docs files change; after IA-only markdown: at minimum **`mix test scrypath_ops/test/scrypath_ops_web/operator_ia_contract_test.exs`** from **`scrypath_ops/`** plus **`check_nav_contract`**. |
| **Manual** | Milestone narrative review (frozen **`.planning/milestones/v1.15-*`** reads coherently); no browser E2E required for this phase. |

**Wave 0:** Not required — existing **`scrypath_ops`** test stack and root **`docs_contract_test`** cover infrastructure.

---

## RESEARCH COMPLETE
