# Phase 92: Guide and Schema Declaration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 92-Guide and Schema Declaration
**Areas discussed:** tenant_field: + fields: interaction, search_document/1 edge case, Filter footgun examples without tenant_scope:

---

## tenant_field: + fields: interaction

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-add to fields: silently | `:tenant_id` merged into `fields:` at compile time if not present. Truly "declare once." | |
| Require it in fields: — raise if missing | `tenant_field:` only wires into `filterable:`. User must separately list in `fields:`. | |
| Auto-add AND emit IO.warn | Auto-add `:tenant_id` to `fields:` + emit `IO.warn/2` compile-time advisory. Developer sees what happened and how to silence it. | ✓ |

**User's choice:** Requested deep research via subagents before deciding. Research covered Elixir/Ecto idioms (Ecto `timestamps()` precedent), ecosystem comparison (searchkick, Hibernate Search), local research files (`prompts/elixir-search-lib-deep-research.md`, `prompts/ecto-best-practices-deep-research.md`). Research recommended Option 3. User confirmed: "lock all three."

**Notes:** `IO.warn/2` (not `IO.puts`) is the correct Elixir mechanism for compile-time advisories with stacktrace context. The merge must be idempotent — if `:tenant_id` already in `fields:`, no-op and no warning. Same dedup helper already in `options.ex` handles this. Also auto-adds to `filterable:` (idempotent).

---

## search_document/1 edge case

| Option | Description | Selected |
|--------|-------------|----------|
| Guarantee via post-hook merge in Projection | After custom hook returns, Scrypath merges tenant field from source record into `Document.data` if missing. Library owns the guarantee. | ✓ |
| Guide-only warning | `tenant_field:` only affects `filterable:` when custom hook present. Guide warns developers to include it manually. | |

**User's choice:** Research confirmed Option A (post-hook merge). User confirmed: "lock all three."

**Notes:** Missing tenant field in indexed document returns empty results for the entire tenant — silent data-leak, not an error. Cannot leave to a guide warning. The post-hook merge is a no-op if custom hook already included the field. Projection must check `__scrypath__(:tenant_field)` (nil if undeclared) to decide whether to inject.

---

## Filter footgun examples without tenant_scope:

| Option | Description | Selected |
|--------|-------------|----------|
| Show context-layer pattern + note Phase 93 is coming | Correct pattern now + mention `tenant_scope:` as upcoming. | |
| Pre-announce tenant_scope: prominently | Show current workaround but frame `tenant_scope:` as the "right" solution coming soon. | |
| Show context-layer pattern only, no forward reference | Guide is accurate at ship time. Phase 93 additions documented when Phase 93 lands. | ✓ |

**User's choice:** Research confirmed Option C. User confirmed: "lock all three."

**Notes:** Elixir ecosystem convention (Ecto, Phoenix, Oban) — guides don't pre-announce unshipped features. The wrong pattern must be labeled prominently (❌ WRONG), the `Keyword.merge` last-key-wins behavior explained inline, and the correct explicit filter composition shown. The footgun section must be prominent, not buried in a callout.

---

## Claude's Discretion

- Exact wording of `IO.warn` message (follow existing advisory tone in `options.ex`)
- Placement of `guides/multitenancy.md` within Getting Started group (after `related-data-and-reindexing.md`)
- Internal dedup helper naming/reuse
- Whether `__scrypath__(:tenant_field)` or `__scrypath__(:config).tenant_field` — use consistent pattern

## Deferred Ideas

- `schema_capabilities/1` reflection — Phase 93 (TNNT-03)
- `tenant_scope:` runtime enforcement — Phase 93 (TNNT-04)
- `mix verify.phase94` hermetic gate — Phase 94 (TNNT-05)
- Joken tenant token helpers in library core — TNNT-FUT-02, out of scope
- Per-tenant Meilisearch index routing — TNNT-FUT-01, out of scope
