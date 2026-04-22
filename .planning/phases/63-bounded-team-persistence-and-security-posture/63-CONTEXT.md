# Phase 63: Bounded team persistence and security posture - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **OPS2-04** and **OPS2-07** for **v1.15**: **one** explicit team persistence outcome with documented authority (**no ambiguous dual-write**), plus **security posture** for shared playbook flows—documentation, schema/copy alignment, and **tests on stub/default CI paths** where feasible.

**Phase 63 does not** implement **OPS2-05** / **OPS2-06** / **OPS2-08** (phase **64**).

</domain>

<decisions>
## Implementation Decisions

### Team persistence outcome (OPS2-04) — research-synthesized

- **D-01:** Deliver **(A)** only in Phase 63: **filesystem + configured workspace directory + GitOps/file documentation** as the **single** supported team persistence story. **Authoritative store** for operator playbook CRUD in OPSUI remains **`Playbook.Store`** + **`SCRYPATH_OPS_PLAYBOOK_DIR`** / `:playbook_workspace_dir` (see `scrypath_ops/config/runtime.exs`). **Do not** ship an optional **Ecto-backed** playbook catalog in this phase.
- **D-02:** **Defer (B)** to a **future** milestone/phase only with **explicit** product evidence (teams blocked on git/shared volume but accepting app-DB operational cost). If **(B)** ever ships: **exclusive** runtime mode (`:filesystem` **xor** `:ecto`), **boot-time validation**, migrations + Repo owned by host/`scrypath_ops` docs, **import_dir / export_dir**-style explicit crossing—not silent sync or merged catalogs.
- **D-03:** **Rationale (coherent with project vision):** Keeps **`mix verify.opsui`** and contributor paths honest; playbooks stay **diffable, PR-reviewable, portable** JSON—aligned with operational honesty and “declarative inputs, not live search snapshots.” Avoids Terraform-style **dual authority** footguns and SaaS-shaped expectations for a library operator UI.

### Authority, precedence, and config (OPS2-04)

- **D-04:** **Steady-state:** exactly **one** mutating catalog source per deployment—the configured workspace root. **No** union list (files ∪ DB), **no** read-through cache of a second store in v1.15.
- **D-05:** **Document** effective workspace resolution as implemented today: **`SCRYPATH_OPS_PLAYBOOK_DIR`** (trimmed, **`Path.expand/1`**) applied in **`runtime.exs`** sets `:playbook_workspace_dir`; **unset/empty env** leaves no implicit `priv/` writes (comment in `runtime.exs` is normative). **Dev/test** may set `:playbook_workspace_dir` via env-specific config—docs should say **prod should use absolute env paths**; **CI** should set explicit temp/fixture roots (avoid cwd-relative surprises).
- **D-06:** If **(B)** is ever added, filesystem becomes **import-only**, **export-only**, or **deprecated**—never a second live writer; cross-boundary moves are **explicit** operations (validate + scrub policy on boundary only).

### Security posture (OPS2-07)

- **D-07:** **Canonical validation** stays **fail-closed reject** on `ScrypathOps.Playbook.V1` for unknown keys and **banned opt keys** (deep scan)—**no** silent redaction on default save/import/run paths (consistent with “no silent clamping” in schema doc).
- **D-08:** If a **sanitize** path is ever introduced, it is a **separate** named API returning e.g. `{:ok, map, warnings}` and **never** changes `validate/1` semantics silently; persistence requires explicit operator confirmation after preview.
- **D-09:** **Testing (stub-first):** extend coverage where gaps exist—e.g. deep **banned_key** under nested `opts`, unknown top-level keys, **delete confirmation** cannot call `Store.delete_workspace_file` on mismatch; optional small **fixture corpus** of valid/invalid JSON under `test/fixtures/playbooks/` (or equivalent) so CI proves golden files stay valid.
- **D-10:** **Documentation deliverables:** short **threat model** slice in **`playbook-schema-v1.md`** (git history, unstructured secrets in `q`/`title`, host responsibility for `/ops` exposure); **“Securing `/ops`”** pointer in **`operator-ia.md`** or linked host guide (auth is **host** concern—document plugs / `live_session` `on_mount` patterns); reinforce **CI/git secret hygiene** (not only codec deny list). Prefer **single source of truth** for banned-key tables (**module attribute → doc** or tests that fail on drift) if maintenance cost is acceptable in planning.
- **D-11:** **Ecto catalog (future):** if rows store JSON, **re-validate** on read before run (defense in depth); document backup/encryption and **no multi-tenant** guarantees.

### Operational / DX package for (A)

- **D-12:** Ship a **golden operator doc** (single canonical page/section): workspace layout, **`SCRYPATH_OPS_PLAYBOOK_DIR`**, PR workflow for `*.json`, CI validation hook, deploy volume patterns (e.g. mounted checkout vs PVC vs image `COPY`), merge/conflict expectations, **secrets never in JSON**.
- **D-13:** Ship **in-repo example playbooks** (small valid **`playbook_format: 1`** files) under a stable path (e.g. `scrypath_ops/examples/playbooks/` or `docs/examples/…`—planner picks); link from **`scrypath_ops` README** / adoption path / IA as appropriate.
- **D-14:** Ship **optional CI-oriented validation**—prefer a **`mix scrypath_ops.*`** task (or documented invocation of existing validation) that runs **pure `V1` validation** over a directory with **no Meilisearch**; keep default **`mix verify.opsui`** discipline intact (phase 64 formalizes OPS2-06; do not introduce live Meilisearch dependency here).
- **D-15:** Update **`playbook-schema-v1.md` § Persistence** to describe **v1.15** team/GitOps authority (supersede stale “no Ecto this milestone” wording where it conflicts—Ecto remains **out of scope for Phase 63**, not “impossible forever”).

### Claude's Discretion

- Exact doc filenames and section titles; placement of examples directory vs `docs/` only if one keeps contracts simpler.
- Fixture corpus size and which edge-case rows belong in default `mix test` vs tagged integration.
- Whether banned-key doc table is generated from `@banned_opt_keys` in this phase or a follow-up hygiene task.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and scope

- `.planning/REQUIREMENTS.md` — **OPS2-04**, **OPS2-07**; traceability table.
- `.planning/ROADMAP.md` — Phase 63 goal and success criteria.
- `.planning/PROJECT.md` — v1.15 vision, OPSUI boundaries.

### Prior phase (adjacent UX — persistence out of scope there)

- `.planning/phases/62-playground-capture-and-playbook-catalog/62-CONTEXT.md` — file workspace, `V1` strictness, capture semantics; team persistence deferred to 63.

### Normative operator + wire docs

- `scrypath_ops/docs/playbook-schema-v1.md` — `playbook_format: 1`, caps, banned keys, persistence narrative (must align with Phase 63 decisions).
- `scrypath_ops/docs/operator-ia.md` — IA; add or link **securing `/ops`** guidance per D-10.

### Config authority (precedence in code)

- `scrypath_ops/config/runtime.exs` — `SCRYPATH_OPS_PLAYBOOK_DIR` → `:playbook_workspace_dir` expansion rules.

### Shipped persistence MVP context

- `milestones/v1.14-REQUIREMENTS.md` — **OPS-PB-03** file-first MVP rationale.

### Implementation anchors

- `scrypath_ops/lib/scrypath_ops/playbook/store.ex` — workspace filesystem API.
- `scrypath_ops/lib/scrypath_ops/playbook/v1.ex` — validation and banned keys.
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` — catalog UX, destructive confirmations.
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` — workspace-not-configured copy.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`ScrypathOps.Playbook.Store`**: basename-only JSON under absolute root; all mutating catalog operations should continue to funnel here for **(A)**.
- **`ScrypathOps.Playbook.V1`**: single semantic gate for wire JSON; extend tests/docs, not parallel validation layers.
- **`PlaybookLive` / `SearchLive`**: patterns for explicit errors, modals, workspace missing messaging—reuse for doc examples and any new validation UX.

### Established Patterns

- **Runtime env** in `runtime.exs` for playbook dir; **no silent default** in release.
- **Strict allow-list + deep banned-key rejection** for playbook JSON.

### Integration Points

- **Docs + README + optional Mix task** for CI validation; **no new LiveView routes required** for core **(A)** story unless UX gaps emerge in planning.

</code_context>

<specifics>
## Specific Ideas

- User requested **parallel subagent research** across all gray areas and a **single coherent recommendation set**; convergent recommendation: **(A) file/GitOps-first** for Phase 63, **exclusive authority**, **reject-first security**, **docs + examples + optional mix validate** as the shipped bundle.
- External patterns repeatedly cited as instructive: **Postman/GitHub Actions–style strict JSON artifacts**, **Terraform single-backend authority**, **Grafana/Argo gitops declarative** models—favor **diffable, reviewable** playbooks over implicit DB catalogs at this stage.

</specifics>

<deferred>
## Deferred Ideas

- **Optional Ecto playbook catalog ((B))** — future phase with exclusive mode, import/export tasks, migration story, expanded verify coverage; not Phase 63.
- **Optional “sanitize and save as…” repair tool** — only if separate from canonical `validate/1`.
- **Union / merged catalog views** (file + DB)—out of scope unless requirements explicitly allow derived read-only indexes with zero ambiguous writes (not v1.15).

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches.

</deferred>

---

*Phase: 63-bounded-team-persistence-and-security-posture*  
*Context gathered: 2026-04-22*
