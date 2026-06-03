---
gsd_state_version: 1.0
milestone: v1.33
milestone_name: Admin UI Insane Polish
status: Active — Phases 121 (TOKEN-01) + 122 (COMP-01) + 123 (MOTION-01) complete; Phase 124 next (owner gate before nav rename)
last_updated: "2026-06-03"
last_activity: 2026-06-03 — Phase 123 (micro-animation layer, MOTION-01) complete: A1 exit easing on flash/modal/palette close, A2 signature verdict tone-settle, A4 row press/hover timing; A3 skipped on restraint; DESIGN-TOKENS.md in lockstep; all gates green incl. reduced-motion proof
progress:
  total_phases: 9
  completed_phases: 5
  total_plans: 5
  completed_plans: 5
  percent: 56
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** v1.33 Admin UI Insane Polish — Phase 124 (IA nav rename + front-door + microcopy) — owner gate before the nav rename

## Current Position

Phase: 124 — IA + Control Room front-door (next, owner gate before nav rename)
Plan: —
Status: Active — Phases 121 (TOKEN-01) + 122 (COMP-01) + 123 (MOTION-01) complete; Phase 124 not yet planned
Last activity: 2026-06-03 — Phase 123 (micro-animation layer) complete: the motion half of "elevate within reserved" — A1 exit easing, A2 signature verdict tone-settle, A4 row press/hover timing

## Current Milestone

**v1.33 Admin UI Insane Polish** (phases 119-127) — owner-initiated, screenshot-backed UI/UX + design-system iteration of the `scrypath_ops` admin console, building on the v1.32 foundation. Deliberately overrides the idle/maintenance posture as an explicit polish wedge. See `milestones/v1.33-{ROADMAP,REQUIREMENTS}.md`.

**Locked decisions:** task-first IA restructure (we commit, no external gate) · elevate brand within "reserved" (one signature verdict tone-settle) · scaffold + run autonomously, checkpoint at gate phases (121,122,123,127) + IA before/after (124).

## Accumulated Context

### Key Decisions

- v1.31 maintainer UAT passed; the realistic demo worked locally.
- v1.32 uses the System + Screens scope and Quiet Ops Console visual direction.
- OPSUI cleanup must preserve posture-first IA: posture, failed sync, sync/drift, search/federation, saved playbooks.
- `phase105-e2e` remains advisory; UI cleanup does not promote browser proof to a required merge gate.
- The admin UI is a mounted, host-owned operator surface, not a new hosted/productized admin product.
- Phase 118 verification passed with focused ScrypathOps LiveView tests, root `mix verify.opsui`, and mounted ecommerce admin route tests.
- Mounted `/admin/search/*` host tests must explicitly prove ScrypathOps asset hooks and avoid storefront bleed.
- OPSUI token cleanup removes Tailwind utility-prefix residue and keeps unprefixed daisyUI usage an explicit contract.
- OPSUI shared primitives stay as small Phoenix function components; no LiveComponent state boundary was needed for Phase 117.
- Schema selectors and swap actions must compare against configured allowlists and reject unknown strings without atom creation.
- (Phase 119) Four named operational seed scenarios (all_green/degraded/incident/empty) live in BOTH seeding paths; `incident` stays default so `make dev`/E2E behavior is unchanged. The admin UI computes posture live from the live index + Oban jobs, so scenarios differ only in sync state + injected signals, not in the catalog fixtures.
- (Phase 119) Screenshot baseline = `admin_screenshot_matrix.spec.ts`: 6 screens × {light,dark} × {mobile 390, desktop 1440} grouped by scenario → 40 deterministic shots in `.tmp/admin-screenshots/`. Theme set via `addInitScript` localStorage `phx:theme` on a fresh context.
- (Phase 120) Per-touchpoint audit produced 47 findings (6 blocker / 9 structural / 32 polish); 11 promoted to systemic token/component fixes. All 10 plan design-system hypotheses confirmed (none refuted; `shadow-ops-mid` already correct). Top systemic anchors: tone-set gap (`ops_ui.ex:259,475,1176-1179`), `ops_code_block` `rounded-md` (`:941`), notice/status duplication (`:203-254`), no `ops_loading` primitive, missing `--ease-ops-exit` (`app.css:167-169`), no row hover/press parity (`app.css:615,845`), preflight 1→4-col jump (`app.css:722-726`). Biggest screen issues: Posture 11-col table overflows mobile, Sync/Drift renders narrow (`:default` not `:wide`), verdict label forks across screens (SHELL-01), nav vocab still Triage/Probes.
- (Phase 123, MOTION-01) Added the micro-animation layer — the motion half of "elevate within reserved", CSS + existing JS-transition hooks only, no behavior change. **A1 exit easing:** flash/banner via `core_components` `show/hide` (raw `ease-out`/`ease-in` → `ease-ops-out`/`ease-ops-exit`, enter ~240ms / exit ~120ms — also cleans a raw-step leak); modal via `ops_modal` `phx-remove` (`ease-ops-exit`, 120ms); command palette + cheat sheet via a `.ops-cmdk--closing` class the JS hook adds for ~160ms before `[hidden]`, playing new `ops-modal-out`/`ops-fade-out` keyframes (re-open cancels the pending close → interruptible). **A2 signature verdict tone-settle:** `.ops-verdict` surface + `.ops-verdict__dot` (dot gained a transition, it snapped before) + every `.ops-metric` border share ONE `--duration-ops-status` + `--ease-ops-standard` beat, so a posture flip reads as "the answer just moved", not 6 flickers — pure CSS, no JS/stagger (a stagger would read as a dashboard toy). **A4 row press/hover:** `.ops-result-row`/`.ops-object-item` press transform at `--duration-ops-instant` (button parity), hover settle at `--duration-ops-fast`. **A3 staggered reveal SKIPPED** on restraint: a CSS-only stagger re-fires on every LiveView DOM patch of the result list → flicker; first-reveal gating needs a forbidden JS hook. emilkowalski principles applied: enter/exit asymmetry, ease-out enter, <300ms, interruptibility, origin-aware exit, transform/opacity only, reduced-motion respect; rejected: spring/bounce, count-up tickers, decorative default stagger. `DESIGN-TOKENS.md` in lockstep (keyframe table + A1/A2/A4 rules + A3 rationale). Gates: verify.opsui 129/0, LiveView 129/0, ecommerce compile clean, 40-shot matrix re-captured (booted :4002, seeded incident, ops assets built) no regressions, reduced-motion neutralization (`.ops-verdict` transition → 0.01ms) + functional integrity (palette/sheet open-close-reopen, disclosure toggle) confirmed via Playwright `reducedMotion: reduce`.
- (Phases 121+122, one owner-approved pass) Landed the systemic design-system dividend, presentation/semantics only (no behavior change). **Tokens (121, `15d77e4`):** `--ease-ops-exit` defined (ease-in; wiring is 123); status-tone set completed — `metric_tone_class/1` maps info/partial/running + `.ops-metric-{info,partial,running}` classes + widened `ops_metric`/`ops_intent_card` enums; raw-step leaks routed to `-ops-` tokens (skip-link ring-2 dropped, theme-toggle brightness-200 dropped, empty-state/upload/checkbox/data-card/modal/object-item); preflight gains `sm:` 2-col (4-col only at lg). **Components (122, `d90fa04`):** `.ops-notice-surface` (+`--raised`) consolidates notice/status; `ops_code_block`→`rounded-ops-md`+`p-ops-*`; new `ops_loading` skeleton/pulse primitive (opacity-only, reduced-motion-safe, available — screen wiring is 125/126); hover/press parity on `ops_result_row`/`ops_object_item`; shared `ops_config_empty` copy sentence-cased; `.ops-table-scroll` scroll-shadow affordance. `DESIGN-TOKENS.md` kept in lockstep. Decision: consolidate via a shared CSS class, not a HEEx partial, so both notice/status APIs + DOM stay distinct. Deferred per scope: motion wiring (123), per-screen Title-Case copy (124), Posture table responsive collapse + Sync/Drift `:wide` width (125). Gates: verify.opsui 129/0, LiveView 129/0, ecommerce compile clean, 40-shot matrix re-captured (booted :4002 on seeded incident DB) with no regressions (search-page height grew only because the live index now returns 15 hits vs the baseline's 2 — data, not CSS).

### Active Blockers

- None.

### Todos

- Keep future runtime breadth closed unless concrete production bug evidence, reviewed outside-adopter evidence, or an explicit strategic decision justifies it.

## Operator Next Steps

- Owner gate: Phase 124 (IA + Control Room front-door `[S]`) — nav group rename Recover/Explore (`nav.ex` + the `ops_ui.ex` trail group labels + `operator-ia.md` nav contract in lockstep), in-page "next step" threading links, front-door trims (demote the "Jump to" rail to a single ⌘K hint, add a P1 orientation link), and the COPY-01 sentence-case sweep (Title-Case empty/error titles, page-title casing forks, "Open in OPSUI"/"Reload list" vocab). The owner wants to review the nav rename before commit (surface before/after). Backlog anchors: P1/P2/P4/P12/P13/P14/P24/P26 in `120-AUDIT-BACKLOG.md`.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 117 P117 | 33min | 6 tasks | 9 files |
| Phase 121 P121 | one pass | TOKEN-01 | 4 files (app.css, DESIGN-TOKENS.md, ops_ui.ex, layouts.ex) |
| Phase 122 P122 | one pass | COMP-01 | 4 files (app.css, DESIGN-TOKENS.md, ops_ui.ex, + 1 test) |
| Phase 123 P123 | one pass | MOTION-01 | 5 files (app.css, DESIGN-TOKENS.md, app.js, core_components.ex, ops_ui.ex) |
