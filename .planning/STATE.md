---
gsd_state_version: 1.0
milestone: v1.36
milestone_name: Dependency Security Remediation
current_phase: 144
current_phase_name: root-http-client-dependency-remediation
status: executing
stopped_at: Completed 144-02-PLAN.md
last_updated: "2026-08-22T16:23:59.792Z"
last_activity: 2026-08-22
last_activity_desc: Phase 144 execution started
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 3
  completed_plans: 2
---

# Project State

## Project Reference

**Core Value:** Make search indexing feel native to Ecto and ergonomic for Phoenix teams without hiding the operational realities of keeping search in sync.
**Current Focus:** Phase 144 — root-http-client-dependency-remediation

## Current Position

Phase: 144 (root-http-client-dependency-remediation) — EXECUTING
Plan: 3 of 3
Status: Ready to execute
Last activity: 2026-08-22 — Phase 144 execution started

## Completed Milestones

**v1.35 Brand System & Logo Identity** (phases 137-143) - COMPLETE 2026-06-24, committed `fcb8fc7`, archived 2026-07-11. Built directly, not through GSD plan/execute artifacts; phase dirs 138-143 and PLAN/SUMMARY files do not exist on disk by design. `roadmap.analyze` may show v1.35 at 0%; that is a known bookkeeping artifact, not incomplete work. Delivered: logo direction C = **scry/path with a copper `/` separator** (routed-S killed); full transparent/no-cage SVG family in `brandbook/assets/`; self-contained HTML brand book with subset woff2 fonts and tokens; adoption across ScrypathOps, website, and root README. Archive files: `.planning/milestones/v1.35-ROADMAP.md`, `.planning/milestones/v1.35-REQUIREMENTS.md`, `.planning/milestones/v1.35-MILESTONE-AUDIT.md`.

**v1.34 Both-Themes Perfection - Dark Signature + AA Gate** (phases 128-136) - COMPLETE 2026-06-29, archived 2026-07-11. 9/9 phases and 27/27 plans completed; DUALVERIFY-01 passed with approved Human UAT. Archive files: `.planning/milestones/v1.34-ROADMAP.md`, `.planning/milestones/v1.34-REQUIREMENTS.md`, `.planning/milestones/v1.34-MILESTONE-AUDIT.md`.

## Current Milestone

v1.36 Dependency Security Remediation is planned across Phases 144-147: root, legacy Phoenix, ScrypathOps, then ecommerce mounted Ops. Execute one graph-local commit per ordered batch and stop on any failed required gate; distinguish required deterministic proof from advisory service/browser evidence. Postgrex changes remain blocked until live advisory and Hex registry evidence confirm a stable published fixed release.

## v1.35 Brand Milestone Context (archived)

**v1.35 Brand System & Logo Identity** (phases 137-143) - see "Completed Milestones" above. Source plan: `~/.claude/plans/brand-book-pressure-test-scalable-alpaca.md`. Direct-completion archive supersedes stale in-progress phase context.

## v1.35 Accumulated Context

### Key Decisions

- **Sequencing:** v1.35 began at phase 137; v1.34 paused during brand work, then resumed and completed.
- **Adoption:** the `brandbook/` package and chosen identity were wired into ops UI, website, favicon, OG image, and README.
- **Palette/type:** product palette stayed stable; final display face is Familjen Grotesk for the brand wordmark, with Inter and IBM Plex Mono retained in the brand package.
- **Fonts:** subset woff2 fonts and OFL license files ship inside `brandbook/assets/fonts/`.
- **Logo decision:** final direction is the copper `/` `scry/path` wordmark plus `s/p` monogram; routed-S concepts are rejected historical exploration.
- **Direct-completion guard:** do not synthesize phase dirs or PLAN/SUMMARY files for phases 138-143.

### Active Blockers

- None.

---

## Accumulated Context (archived v1.34)

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

### Quick Tasks Completed

| # | Description | Date | Commit | Status | Directory |
|---|-------------|------|--------|--------|-----------|
| 260816-thg | Rewrite Ops UI microcopy around operator JTBD | 2026-08-16 | 9c94458 |  | [260816-thg-rewrite-ops-ui-microcopy-around-operator](./quick/260816-thg-rewrite-ops-ui-microcopy-around-operator/) |
| 260816-tzr | Triage dependency security advisories reported by mix deps.get | 2026-08-16 | docs-only | Verified | [260816-tzr-triage-dependency-security-advisories-re](./quick/260816-tzr-triage-dependency-security-advisories-re/) |

### Todos

- Pending security maintenance: remediate the reproduced dependency advisories in four isolated batches; triage is complete, remediation remains pending (`.planning/todos/pending/2026-08-16-remediate-dependency-security-advisories.md`).
- Keep future runtime breadth closed unless concrete production bug evidence, reviewed outside-adopter evidence, or an explicit strategic decision justifies it.
- Completed follow-up: Rewrite Ops UI microcopy around operator JTBD (`.planning/todos/completed/2026-07-01-rewrite-ops-ui-microcopy-around-operator-jtbd.md`).
- Completed follow-up: Restructure Search playground workflow (`.planning/todos/completed/2026-07-01-restructure-search-playground-workflow.md`).
- Completed follow-up: Normalize Playbooks row action styling (`.planning/todos/completed/2026-07-01-normalize-playbooks-row-action-styling.md`).

## Deferred Items

Items acknowledged and deferred at v1.34 milestone close on 2026-07-11:

| Category | Item | Status |
|----------|------|--------|
| todo | 2026-07-01-rewrite-ops-ui-microcopy-around-operator-jtbd.md | completed by quick task 260816-thg |
| uat-audit-noise | Phase 134 `134-UAT.md` | passed; 0 pending scenarios |
| uat-audit-noise | Phase 136 `136-UAT.md` | passed; 0 pending scenarios |

## Performance Metrics

| Phase | Plan | Duration | Notes |
|-------|------|----------|-------|
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
| Phase 132 P01 | ~6min | 3 tasks | 4 files |
| Phase 132 P02 | ~10min | 2 tasks | 2 files |
| Phase 133 P01 | ~12min | 3 tasks | 4 files |
| Phase 133 P02 | ~2min | 1 tasks | 1 files |
| Phase 133 P03 | ~30min | 1 tasks | 1 files |
| Phase 135 P01 | 5 min | 2 tasks | 2 files |
| Phase 135 P02 | 23m27s | 3 tasks | 8 files |
| Phase 135 P03 | 25min | 3 tasks | 9 files |
| Phase 135 P04 | 1h 2m | 2 tasks | 2 files |
| Phase 136 P01 | 33m 18s | 3 tasks | 6 files |
| Phase 136 P03 | 5 min | 3 tasks | 5 files |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 144 P01 | 16m | 1 tasks | 9 files |
| Phase 144 P02 | 5m | 1 tasks | 2 files |

## Decisions

- [Phase 133 Plan 03]: DARKMOTION-01 browser proof shipped — `admin_path_motion.spec.ts` (7 tests, dark+light+system-dark) green against a booted seeded ops server. Patch-refire proof (A3) counts ONLY running `CSSAnimation` (`@keyframes`), EXCLUDING `CSSTransition`: a running transition is the intended state-driven glow/line-draw settle, so only a re-firing keyframe reveal is the failure mode worth catching; probe scoped to the anchor itself (incl. `::after`), not the descendant subtree where intended Phase-123 `ops-fade-in` reveals run. Reduced-motion proof asserts computed duration ≤ ~0.02ms via the global rule + active end state still visible (functional integrity). Shimmer coverage ships the shippable half (evidence code blocks asserted shimmer-OFF) since no live template sets `shimmer={true}`. Targeted 9-shot screenshot set produced; full 40-shot recapture/gallery/UAT deferred to Phase 136 (D-05c). Booted via compose dev lane with free host lanes `PG_PORT=5455 MEILI_PORT=7755` (sibling containers held 5432/7700). Phase 133 now ready for verification.
- [Phase 133 Plan 01]: DARKMOTION-01 `.ops-path-*` vocabulary shipped — line-draw via `.ops-path-trace::after` as a `transition` (NOT `@keyframes`-on-mount, A3 patch-safety), active-path node glow via `.ops-path-node[--copper]` reusing `--shadow-ops-glow[-copper]`, opt-in `.ops-code-block--shimmer` hover glint. Only new component API is `attr(:shimmer, :boolean, default: false)` on `ops_code_block/1`; default-false keeps evidence calm. Anchors (merge-trace, active Playbook item, recommended card) wired via existing server-state classes — no new state attrs, no new JS hooks, no new tokens. Active-item glow hand-authored in both dark paths. `mix compile --warnings-as-errors` green; verify.opsui static-CSS contract is Plan 02, browser proof is Plan 03.
- [Phase 133 Plan 01]: 4 pre-existing `OpsShellContractTest` failures (logo.svg → inline-SVG drift from v1.35 brand adoption `fcb8fc7`) are out of Phase 133 scope — logged to `deferred-items.md`; this plan's 4 files don't touch the header/logo/layouts.
- [Phase ?]: #767676 vs white is 4.54:1 (not 4.48:1) — #777777 is the actual known-fail pair for AA at 4.48:1
- [Phase ?]: D-15 Guard 2 selector extraction uses whitespace-aware regex to handle indented CSS rules inside @layer blocks
- [Phase ?]: Wave 0 FRESH_DIR convention
- [Phase ?]: light-pixel-diff SKIP behavior
- [Phase ?]: Elevation tokens declared in @plugin blocks (not @theme) for automatic both-path dark coverage via daisyUI plugin pass-through (D-02)
- [Phase ?]: 9 recipe inner tokens swapped to --ops-surface-1/--ops-surface-2 inside color-mix wrappers; .ops-data-card + .ops-result-row get D-05 dark-scoped overrides; D-10 shadow dual-path rgba ladder; ops_code_block :default rerouted to bg-ops-surface-2
- [Phase ?]: Option B approved: defer residual Cluster 3 primary-violet 4.3:1 violations to Phase 132; --color-primary unchanged; dark ramp visually confirmed correct
- [Phase ?]: (Phase 131 Plan 03) ops_page_header eyebrow swapped from four inline utilities to .ops-copper-eyebrow; DESIGN-TOKENS.md lockstep sections added
- [Phase ?]: D-11 gate condition for Phase 131 is Cluster 1 = 0 (not matrix exit 0); Cluster 3 primary-violet deferred to Phase 132 (A11Y-TOKEN-01)
- [Phase 132 Plan 01]: A11Y-TOKEN-01 source remediation uses named --ops-text-muted at 64% and scoped --color-primary-strong (#5b4ad1) for text-bearing selected fills only; AA is hard gate and AAA remains advisory/report-only.
- [Phase 132 Plan 02]: Hard-gate evidence is attached in `132-CONTRAST-REPORT.md`: rebuilt assets, `mix verify.opsui`, fast token checker, Playwright matrix, and light baseline recapture all passed; AA failures are zero for light, dark, and system-dark.
- [Phase 132 Plan 02]: AAA body/long-form findings remain advisory/report-only. The browser proof recorded 12 empty-scenario advisory findings at 6.76:1 vs target 7, and those findings did not affect exit status.
- [Phase 132 Plan 02]: The intentional light-token visual change is accepted by recapturing the local light baseline; generated `test-results/`, `.tmp/`, and untracked `scrypath_ops/priv/static/**` evidence artifacts stay out of git.
- [Phase ?]: (Phase 133-02) Motion-discipline self-enforcing: ScrypathOpsWeb.MotionContractTest statically asserts transform/opacity/box-shadow-only + tokenized <300ms + dual-dark-path over .ops-path-*, inside mix verify.opsui; inset is the sanctioned static alternative to banned width/height/top/left.
- [Phase 135]: Plan 01 uses existing theme-grid helpers for the shell browser proof instead of creating a parallel harness. — Matches D-14/D-15 and keeps explicit-light, explicit-dark, and system-dark semantics aligned with existing E2E proofs.
- [Phase 135]: Plan 01 performs no package install or upgrade; package-lock.json remains unchanged. — Research flagged no new dependency need and required preserving the existing Playwright and axe versions.
- [Phase 135]: Plan 02 keeps shell chrome proof selectors on the live inline brand mark and existing theme-toggle DOM rather than adding a new shell abstraction. — Matches the phase goal of polishing shared shell chrome without nav IA churn.
- [Phase 135]: Plan 02 mirrors custom shell chrome dark CSS in both explicit dark and system-dark paths. — Preserves system-follows-OS parity while keeping light theme unchanged by default.
- [Phase 135]: Plan 02 extends the ecommerce demo's existing theme provider so mounted ScrypathOps routes expose the same selected-state semantics as standalone ops root. — The browser proof showed mounted routes use the host bundle, so the mounted integration must mirror aria/data selected state too.
- [Phase 135]: Plan 03 keeps aria-modal=true and makes the existing CommandPalette hook defend bounded focus and focus return instead of downgrading semantics. — Browser proof now verifies bounded focus, focus return, active option state, and Escape close behavior across required themes/viewports.
- [Phase 135]: Plan 03 mirrors command palette hook hardening into the ecommerce host bundle because mounted ops routes use the host LiveSocket. — The mounted browser proof loads /assets/js/app.js from the ecommerce host, so standalone ops hook changes alone do not exercise real mounted behavior.
- [Phase 135]: Plan 03 uses durable ops-flash classes on the passive alert wrapper while preserving Phoenix.Flash lookup and lv:clear-flash dismissal. — This gives palette/flash static CSS tripwires and browser-proofed chrome without adding focus steal, loops, dependencies, or public API changes.
- [Phase 135]: No D-03 light-theme exception was recorded in Plans 02 or 03, so the conditional light-pixel-diff gate was not run for Plan 135-04. — Plan 135-04 made the light pixel diff conditional on a recorded D-03 light exception; the final report documents that none existed.
- [Phase 135]: aria-modal stayed on the command palette and shortcut sheet because browser proof verifies bounded focus and focus return. — The final evidence report records modal focus containment and focus-return behavior across the shell browser gate.
- [Phase 135]: Phase 136 retains full 40-shot recapture, v1.33 to v1.34 gallery, milestone audit, and human UAT. — Plan 135-04 closes the shell evidence slice and explicitly leaves broad milestone verification to Phase 136.
- [Phase 136]: Phase 136 Plan 01 used a source-backed Phoenix server on port 4012 for automated UAT proof instead of the existing containerized 4002 server. — Avoids stale-server false positives while the working tree contains active UI/demo changes.
- [Phase 136]: Phase 136 Plan 01 records generated screenshot evidence as checksums in the artifact manifest rather than committing browser PNGs or traces. — Keeps generated browser evidence out of git while preserving auditability for DUALVERIFY-01.
- [Phase 136]: Human UAT approval passed DUALVERIFY-01 with no D-18 must-fix blocker. — 136-UAT.md records `approved`, one passed UAT test, zero pending items, and zero blockers.
- [Phase 136]: No UAT-created accepted follow-ups were recorded. — Existing D-19 categories remain nonblocking policy/evidence options only, not hidden closeout defects.
- [Phase 136]: Manifest committed-artifact checksums use file-content SHA-256 except the manifest self-entry. — The self-entry uses canonical JSON with its own `sha256` field nulled to avoid an impossible self-referential hash.
- [Phase 144 Plan 01]: Used targeted Mix dependency unlocks to preserve graph-local remediation ownership while aligning the shared Req closure.
- [Phase ?]: [Phase 144 Plan 02]: Req 0.6.3 passes causal public-boundary transport, header merge, task-filter, and telemetry privacy coverage without a private client change; Swoosh runtime proof remains Phase 146 scope.

## Session

**Last session:** 2026-08-22T16:23:59.784Z
**Stopped at:** Completed 144-02-PLAN.md
**Resume file:** None
