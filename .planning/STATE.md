---
gsd_state_version: 1.0
milestone: v1.34
milestone_name: Both-Themes Perfection — Dark Signature + AA Gate
status: planning
last_updated: "2026-06-04T19:33:58.197Z"
last_activity: 2026-06-04 -- Phase 132 UI-SPEC approved
progress:
  total_phases: 9
  completed_phases: 4
  total_plans: 12
  completed_plans: 12
  percent: 44
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** Phase 132 — a11y-contrast-remediation-both-themes-hard-gate-g (context gathered)

## Current Position

Phase: 132 — CONTEXT GATHERED (Phase 131 COMPLETE)
Plan: 0 of ? (not yet planned)
Status: Phase 132 context gathered — ready to plan
Resume: .planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTEXT.md
Last activity: 2026-06-04 -- Phase 132 context gathered

## Current Milestone

v1.34 Both-Themes Perfection — Dark Signature + AA Gate (phases 128–136). Make the existing dark/light/system theming of the `scrypath_ops` admin UI genuinely perfect and brand-expressive — dark as the signature look, light at parity — per `prompts/scrypath-brand-book.md`, backed by a formal automated WCAG AA contrast gate (AAA body text), plus continued design-system/IA polish on v1.33's under-touched surfaces. Owner-initiated polish wedge overriding the idle posture; UI polish only (Phase 97 scope guard holds). Locked: comprehensive both-themes scope, system-follows-OS default preserved, AA hard gate / AAA-body, keep Tailwind v4 + daisyUI + `.ops-*`. Central fix: the dark surface ramp drops the brand's `#1B2230` surface-2 step, so "raised" surfaces flatten in dark — repaired via theme-scoped elevation tokens that leave light pixel-identical. Source plan: `~/.claude/plans/v1-33-admin-ui-deep-tower.md`.

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

- (Phase 124, IA-01/COPY-01, `9ca6510`) Task-first IA: nav groups renamed Triage→Recover / Probes→Explore in lockstep across `nav.ex` + the `ops_ui.ex` breadcrumb labels + `operator-ia.md` (nav-contract test gates it); CTAs match the new vocabulary; front-door trimmed (Jump-to rail → single ⌘K hint + quiet orientation link; emoji intent icons → violet monoline Heroicons); Search→Playbooks handoff threads the explore loop; sentence-case titles + concrete-next-action empty/error states. Labels/copy/icons only — no route/handler/mount change. (Roadmap/state status advanced retroactively at the start of the 125/126 pass.)
- (Phase 128 Plan 01) @axe-core/playwright devDep installed + test:e2e:admin-contrast wired; contrast-pairs.mjs muted-alpha manifest (D-11) created with 13 entries — 12 contrast-gated + 1 decorative (.ops-trail__sep). D-10: token names only (no hex). D-12: sRGB compositing matches axe-core. D-15 lockstep guard input ready for Plan 02. CONTRAST-HARNESS-01 closed.
- (Phase 128 Plans 02+03) Full contrast gate harness complete (Wave 0). 108 AA violations measured across 3 scenarios (incident 22 / all_green 60 / empty 26). Top systemic: `.leading-4` at 1.08:1 in dark — the `#1B2230` surface-2 ramp collapse (DARKAUDIT-01 finding #1); dark form inputs at 1.19:1 (`#1f2933`/`#141923`); `.bg-primary` at 4.3:1 near-miss. Fast checker found 3 light-theme muted-text AA fails at 3.9:1 (.ops-text-meta etc.). All AA failures at mobile only; desktop passes. system-dark parity confirmed (D-08 invariants working). 128-CONTRAST-REPORT.md committed as baseline evidence for phases 129/132.

- (Phases 125 + 126, RECOVER-01 `e1b9330` / EXPLORE-01 `4f0d6f4`) The per-screen polish passes; presentation + finding-driven minimal behavior only. **125 Recover:** Posture per-schema table sorts **worst-first** by default (`posture_rows_worst_first/1`: fetch error → backend failures → queue not observed/failing → clean) with a `sm:hidden` "swipe sideways" cue over the `ops-table-scroll` affordance (B1 — usable at 390px); Sync/Drift now `ops_main_width={:wide}` matching every other screen, showcasing the 4-step preflight + drift tables (B6); contract-drift read wired to `ops_loading` by deferring it to a `:run_drift` message (S3, event name unchanged); Failed Sync triage-guidance `ops_disclosure` `open={total == 0}` (expanded on the quiet first-visit, collapsed for a busy operator), stacked code blocks → `space-y-ops-2` (P22), inline `<code>` → `ops_inline_code` (P25); `ops_disclosure` gained an `open` attr. **126 Explore:** Search wired to `ops_loading` by deferring the bounded read to a `:run_search` message + `phx-disable-with` + a state-aware "Run a probe/Running…/Last run loaded" badge (S2); single-index result rows lead with the hit's human field name (P29, `hit_title/2`) not "Hit 1/2"; zero-results is an `ops_empty_state` naming the next action; Playbooks destructive Delete split into its own `ops_action_group tone={:danger}` (P28). The S2/S3 deferred-read loading states are the only behavior change (the loading findings require it); the worst-first sort is the other (B1 requirement). Tests updated for the deferred renders (2 sync-drift, 4 search). Matrix gotcha: the ecommerce dev server does NOT live-reload the `scrypath_ops` path-dep beams mid-run — restart `mix phx.server` to pick up ops LiveView edits before re-shooting. Gates both phases: verify.opsui 129/0, LiveView 129/0, ecommerce compile clean, 40-shot matrix re-captured both themes; B1 (Posture mobile 390) + B6 (Sync/Drift width) visually confirmed; baseline at `.tmp/admin-screenshots/` updated.

### Active Blockers

- None.

### Todos

- Keep future runtime breadth closed unless concrete production bug evidence, reviewed outside-adopter evidence, or an explicit strategic decision justifies it.

## Operator Next Steps

- Phase 127 (Shell coherence + milestone verification & UAT `[S] [G]`) — the final gate/UAT stop (SHELL-01, VERIFY-01). Shell coherence: unify the per-screen **trust verdict** so it reads identically on Control Room / Posture / Sync-Drift (P5 — labels currently fork: "Can I trust search right now?" / "Fleet posture" / "Promotion readiness"; unify label + dot + tone "as a unit"); collapse the **header nav** to a menu/hidden on small screens so it stops duplicating the sidebar at mobile (P6, `layouts.ex`); confirm the chrome (header, nav, palette, theme toggle, flash, trail) is consistent across every screen. VERIFY-01: produce a v1.32→v1.33 before/after gallery, run the milestone audit against intent, and pass human UAT. Note for 127: the matrix spec's per-screen heading assertions were already aligned to the 124 rename; the ops path-dep needs a server restart (not live-reload) before re-shooting. Backlog anchors: P5/P6 in `120-AUDIT-BACKLOG.md`.

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
| Phase 117 P117 | 33min | 6 tasks | 9 files |
| Phase 121 P121 | one pass | TOKEN-01 | 4 files (app.css, DESIGN-TOKENS.md, ops_ui.ex, layouts.ex) |
| Phase 122 P122 | one pass | COMP-01 | 4 files (app.css, DESIGN-TOKENS.md, ops_ui.ex, + 1 test) |
| Phase 123 P123 | one pass | MOTION-01 | 5 files (app.css, DESIGN-TOKENS.md, app.js, core_components.ex, ops_ui.ex) |
| Phase 125 P125 | one pass | RECOVER-01 | 6 files (posture/sync_drift/failed_sync live, ops_ui.ex, 1 test, matrix spec) |
| Phase 126 P126 | one pass | EXPLORE-01 | 3 files (search/playbook live, 1 test) |
| Phase 128 P01 | 4min | CONTRAST-HARNESS-01 | 3 files (package.json, package-lock.json, contrast-pairs.mjs) |
| Phase 128 P02 | 8min | 2 tasks | 3 files |
| Phase 128 P03 | 15min | 3 tasks | 3 files (admin_contrast_matrix.spec.ts, 128-CONTRAST-REPORT.md, VALIDATION.md) |
| Phase 130 P01 | 5min | 2 tasks | 4 files |
| Phase 130 P02 | 5min | 1 tasks | 1 files |
| Phase 130 P03 | 10min | 2 tasks | 2 files |
| Phase 130 P130-04 | ~3hrs | 3 tasks | 4 files |
| Phase 131 P01 | 15min | 3 tasks | 1 files |
| Phase 131 P02 | 25min | 3 tasks | 1 files |
| Phase 131 P03 | ~10min | 2 tasks | 2 files |
| Phase 131 P04 | 20min | 3 tasks | 1 files |

## Decisions

- [Phase ?]: #767676 vs white is 4.54:1 (not 4.48:1) — #777777 is the actual known-fail pair for AA at 4.48:1
- [Phase ?]: D-15 Guard 2 selector extraction uses whitespace-aware regex to handle indented CSS rules inside @layer blocks
- [Phase ?]: Wave 0 FRESH_DIR convention
- [Phase ?]: light-pixel-diff SKIP behavior
- [Phase ?]: Elevation tokens declared in @plugin blocks (not @theme) for automatic both-path dark coverage via daisyUI plugin pass-through (D-02)
- [Phase ?]: 9 recipe inner tokens swapped to --ops-surface-1/--ops-surface-2 inside color-mix wrappers; .ops-data-card + .ops-result-row get D-05 dark-scoped overrides; D-10 shadow dual-path rgba ladder; ops_code_block :default rerouted to bg-ops-surface-2
- [Phase ?]: Option B approved: defer residual Cluster 3 primary-violet 4.3:1 violations to Phase 132; --color-primary unchanged; dark ramp visually confirmed correct
- [Phase ?]: (Phase 131 Plan 03) ops_page_header eyebrow swapped from four inline utilities to .ops-copper-eyebrow; DESIGN-TOKENS.md lockstep sections added
- [Phase ?]: D-11 gate condition for Phase 131 is Cluster 1 = 0 (not matrix exit 0); Cluster 3 primary-violet deferred to Phase 132 (A11Y-TOKEN-01)
