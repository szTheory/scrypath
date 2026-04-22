# Phase 62: Playground capture and playbook catalog - Context

**Gathered:** 2026-04-22  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **OPS2-01–OPS2-03**: capture bounded Search playground state into **`playbook_format: 1`** JSON (preview → save to workspace), **rename** and **duplicate** with safe basename handling and explicit error paths, and **operator-facing metadata** (title/description, optional tags per requirements) so catalog list/detail stay legible without raw JSON as the primary interface. **Backward compatibility** for legacy workspace files without metadata is required.

Team persistence (**OPS2-04**), security posture depth (**OPS2-07** beyond what schema/UI already imply), and IA/verify bookkeeping (**OPS2-05/06/08**) are **out of scope** for this phase (later phases **63–64**).

</domain>

<decisions>
## Implementation Decisions

### Wire format for catalog metadata (OPS2-03)

- **D-01:** Extend **`playbook_format: 1`** with **optional flat top-level string keys** on both modes: **`title`**, **`description`**, and **`tags`** (see D-02 for UI scope). Do **not** introduce a nested `meta` object for Phase 62 — only three optional fields are planned; flat keys keep hand-edited JSON and diffs obvious and match strict allow-list style in `ScrypathOps.Playbook.V1`.
- **D-02:** Do **not** bump **`playbook_format`** for metadata alone; reserve integer bumps for **breaking** changes to `search` / `search_many` executable shape. Update **`scrypath_ops/docs/playbook-schema-v1.md`** normatively whenever the codec allow-list changes.
- **D-03:** **No sidecar** metadata files as the primary model — single artifact per playbook stays portable for git and matches v1.14 persistence story.
- **D-04:** Validation remains **strict**: unknown top-level keys still error; optional keys when present must pass shape checks (**strings** for title/description; **`tags`** when present = JSON array of strings with bounded count and per-tag length — exact numeric caps left to implementation but must be enforced and documented).
- **D-05:** Legacy files missing metadata: treat missing keys as **empty** for UI; list primary line uses **`Untitled playbook`** (or equivalent per **62-UI-SPEC.md**) when title absent/blank.

### Tags: JSON vs UI in Phase 62

- **D-06:** **Codec + disk** accept optional **`tags`** when present (validated array of strings per D-04) so power users and imports do not hit `unknown_top_level_keys`. **LiveView Phase 62** ships **title + description** in capture and catalog surfaces; **do not** add tag entry, chips, filters, or list-row tag UI in Phase 62 — defer tag **authoring and display** to a follow-up when catalog volume justifies normalization policy.
- **D-07:** Rationale: least surprise for internal ops at low catalog sizes; avoids tag normalization/i18n/facet footguns under the same milestone as capture + rename/duplicate. Forward shape avoids a second JSON migration.

### Capture source semantics (Search playground → playbook)

- **D-08:** **Source of truth** for “Save search as playbook” is the **latest successful** playground run **for the current `mode` (`single` vs `multi`)** stored in **LiveView assigns** after `SearchPlayground` dispatch succeeds for that run.
- **D-09:** **Survive** `push_patch` and ordinary events **within the same mode** (e.g. tweak `q` and re-run — capture reflects latest success). **Clear** the stored capture source when the operator **switches mode** (`single` ↔ `multi`) so serialized shape never drifts from the mode that produced the run.
- **D-10:** **Clear on mount** (new LiveView session: full reload, reconnect) — no server-side session persistence of capture payload in Phase 62. Operators who need continuity after reload **re-run** once; this matches “playground” ephemerality and avoids multi-tab/session races.
- **D-11:** If the codebase can detect **material configuration changes** (e.g. playground adapter module change, schema allowlist identity change), **clear** capture source; if detection is noisy, **minimum** is mode switch + mount clear.
- **D-12:** Do **not** add a separate **“Pin snapshot”** control in Phase 62; the explicit **preview → save** flow is the deliberate commit step. (Optional pinned/workbench persistence is a **deferred** idea if product pressure appears.)

### Rename, duplicate, collisions (OPS2-02)

- **D-13:** **Rename:** if target basename exists → **hard error** with operator copy (no silent overwrite, no replace-by-rename in Phase 62). Replacement workflow is **duplicate to new name** or **delete** then save — keeps one destructive pattern (delete) and avoids teaching a second “type to confirm” for rename-target-clobber.
- **D-14:** **Duplicate:** default new basename pattern **`{stem}-{n}.json`** with monotonic **`n ≥ 1`** (or next free integer), not verbose `copy-of-…` prefixes — cleaner listings and less “which file is canonical?” confusion. Align row UX with **62-UI-SPEC.md** (editable field before commit).
- **D-15:** File operations stay aligned with **`PlaybookLive`** patterns: `Store.safe_basename?/1`, explicit modals for destructive paths, no single-click destructive actions.

### Research synthesis (cross-cutting)

- **D-16:** Prefer **explicit, fail-fast** validation and **string keys** through JSON decode (existing **`Playbook.V1`** culture); never introduce atom keys from untrusted JSON.
- **D-17:** Analogues (Postman/GitHub Actions–style strict envelopes, `mv` clobber footguns) reinforce: **strict allow-list**, **cluster metadata in a few optional keys**, and **never implicit overwrite** on rename.

### Claude's Discretion

- Exact **max lengths** for title/description/tags and max tag count (within reasonable bounds) if not already implied by store/import limits.
- Minor UX ordering inside **SearchLive** (assign names, optional `data-testid` hooks) as long as **62-UI-SPEC.md** hierarchy and copy stay satisfied.
- Whether material “adapter change” detection for D-11 is a simple reference equality check or deferred if flaky on stub CI.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements

- `.planning/REQUIREMENTS.md` — **OPS2-01**, **OPS2-02**, **OPS2-03** acceptance and v1.15 scope.
- `.planning/ROADMAP.md` — Phase 62 goal, success criteria, traceability.
- `.planning/PROJECT.md` — v1.15 vision, OPSUI boundaries (**OPSUI-FUT-02** out of scope).

### UI and operator docs

- `.planning/phases/62-playground-capture-and-playbook-catalog/62-UI-SPEC.md` — LiveView/Tailwind/daisyUI contract, CTAs, empty/error copy, capture and catalog layout, destructive patterns.
- `scrypath_ops/docs/playbook-schema-v1.md` — normative **`playbook_format: 1`** wire shape; must stay aligned with **`ScrypathOps.Playbook.V1`**.
- `scrypath_ops/docs/operator-ia.md` — IA for any new primary routes or nav labels (coordinate with **OPS2-05** in phase 64 if scope bleeds).

### Prior milestone (playbook MVP)

- `milestones/v1.14-REQUIREMENTS.md` — **OPS-PB-*** decisions superseded by v1.15 for second slice; persistence MVP context.

### Implementation anchors (code)

- `scrypath_ops/lib/scrypath_ops/playbook/v1.ex` — strict top-level allow-list and validation extension point.
- `scrypath_ops/lib/scrypath_ops_web/live/search_live.ex` — Search playground UI and assigns.
- `scrypath_ops/lib/scrypath_ops_web/live/playbook_live.ex` — catalog, import, delete confirmation, save patterns.
- `scrypath_ops/lib/scrypath_ops/search_playground.ex` — caps and validation aligned with playbook docs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`ScrypathOps.Playbook.V1`**: `validate_top_level_keys/1` is mode-specific allow-lists (`@search_top`, `@search_many_top`); extend both lists plus optional per-key validators for metadata strings and `tags` array.
- **`ScrypathOpsWeb.PlaybookLive`**: `Store.safe_basename?/1`, typed delete confirmation, preview/`max-h-96` JSON presentation — mirror for rename/duplicate and capture preview.
- **`ScrypathOpsWeb.SearchLive`** + **`ScrypathOps.SearchPlayground`**: single source for successful `dispatch_search` / `dispatch_search_many` and page/schema caps — capture must serialize **inputs** only (per schema doc federation note), not hit payloads.

### Established Patterns

- Strict JSON codec with **`unknown_top_level_keys`** errors — metadata must be allow-listed, not permissive maps.
- **Jason** string-key maps through validation boundary; security notes on banned opt keys already in codec and doc.

### Integration Points

- Router and **`operator-ia.md`** when adding or renaming **LiveView** routes for capture flow (if any).
- **`mix verify.opsui`** / stub adapter: new paths should follow existing stub-first testing discipline (**OPS2-06** formally in phase 64, but do not introduce live Meilisearch dependency in default verify).

</code_context>

<specifics>
## Specific Ideas

- Subagent research consensus: **flat optional metadata** on format 1, **defer tag UX** not tag key acceptance, **LiveView-local capture** with **clear on mode change and mount**, **rename collision = error**, **duplicate = stem-n suffix**, align duplicate naming with small adjustment from verbose `copy-of-` if UI-SPEC examples used that phrase — **implementation follows D-14** for filenames.
- Treat **Postman / strict workflow schema** lessons as reinforcement: versioned envelope, explicit fields, no silent drops.

</specifics>

<deferred>
## Deferred Ideas

- **Pin snapshot** / cross-navigation durable capture (server session draft) if operators ask for reload-safe capture without re-run.
- **Replace-on-rename** with typed confirmation (parity with delete) if rename-in-place becomes a documented operator need.
- **Tag chips, filters, and normalization policy** when catalog size or multi-operator ownership warrants it.
- **Sidecar or export-only metadata** if a future pipeline requires split artifacts.

### Reviewed Todos (not folded)

- None (`todo.match-phase` returned no matches).

</deferred>

---

*Phase: 62-playground-capture-and-playbook-catalog*  
*Context gathered: 2026-04-22*
