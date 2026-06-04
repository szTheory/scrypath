# Phase 126 Plan: Explore screens polish (EXPLORE-01)

**Phase:** 126-explore-screens
**Requirement:** EXPLORE-01
**Branch:** `gsd/v1.33-admin-ui-insane-polish`
**Source backlog:** `.planning/milestones/v1.33-phases/120-per-touchpoint-audit/120-AUDIT-BACKLOG.md`

## Goal
Polish Search/Federation and Playbooks for single/multi-mode parity, a loading state during a
bounded run, a zero-results state that names the next action, meaningful result titles, and clear
read-only-vs-workspace separation.

## Backlog items mapped to 126
- **S2 (structural)** — Search has no loading state between "Run bounded search" and results.
- **P29** — Search results show generic "Hit 1 / Hit 2" titles; lead with the human field.
- Zero-results state must name a concrete next action (COPY-01 spirit on the Explore surface).
- **P28** — Playbooks action row is dense; the destructive Delete sits among neutrals.
- Playbooks: empty-workspace state + read-only(`:examples`)-vs-workspace clarity (verify already served).

## Approach
- S2: wire `ops_loading` — `handle_event("search", …)` sets `:searching`, clears prior results, and
  defers the bounded read to `handle_info({:run_search, params}, …)`. The results panel renders an
  `ops_loading` skeleton while `@searching`; the Run button gets `phx-disable-with`. Event name and
  dispatch path unchanged; `base_socket` clears `:searching` on every terminal branch.
- P29: `hit_title/2` leads with name/title/sku/id; falls back to the ordinal when no human field.
- Zero-results: replace the `ops_data_card` with an `ops_empty_state` whose copy names the next
  action (widen/simplify query, raise page size, pick another schema, run again).
- Result-status badge gains a `:running` "Running…" state via `search_status_badge_{kind,label}/1`.
- P28: split the Playbooks Delete into its own `ops_action_group tone={:danger}`, separating the
  destructive action from the advanced Duplicate/Rename group.

## Verification gate
1. `mix verify.opsui` green.
2. `cd scrypath_ops && mix test` green (update the four search assertions the S2 deferral touches).
3. `cd examples/scrypath_ecommerce && mix compile --warnings-as-errors` clean.
4. Boot + re-shoot the 40-shot matrix both themes; confirm meaningful titles, zero-results next
   action, and the separated Playbooks danger action.
