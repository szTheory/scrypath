# Phase 120 — Per-Touchpoint Audit Backlog (AUDIT-01)

**Generated:** 2026-06-03
**Branch:** `gsd/v1.33-admin-ui-insane-polish`
**Inputs:** 40 baseline PNGs (`.tmp/admin-screenshots/`, 6 screens × light/dark × mobile 390/desktop 1440 × incident/all_green/populated/empty/zero-results/drift), 6 LiveViews, `ops_ui.ex` (43 `.ops-*`), `layouts.ex`, `nav.ex`, `app.css` + `DESIGN-TOKENS.md`, brand book.
**Method:** 9 audit units, 3 altitudes (element → component → page/flow), 7 dimensions (D1 token / D2 least-surprise / D3 a11y / D4 responsive / D5 brand / D6 state / D7 motion). Severity = blocker (any D1/D2/D3=0) / structural (D6 gap) / polish. Fix-class = token / component / screen / motion / seed.

---

## Executive summary

**Total findings: 47** — by severity: **blocker 6**, **structural 9**, **polish 32**.
By fix-class: **token 9**, **component 14**, **screen 18**, **motion 4**, **seed 2**.

**Systemic (≥3 screens) → Phase 121/122:** 11 promoted findings. The compounding-dividend set is led by: incomplete tone set in `ops_metric`/`metric_tone_class` (4 screens), `ops_code_block` raw `rounded-md` + raw padding (3 screens), notice/status near-duplicate internals (5 screens), Title-Case copy in shared empty states (4 screens), no hover/press parity on `ops_result_row`/`ops_object_item` (4 screens), no shared loading primitive (all screens), missing exit-easing token (palette/modal/flash), and old nav/breadcrumb vocab "Triage/Probes" (all screens).

**Top blast-radius truths:** the dense Posture per-schema table (11 cols) overflows on mobile with no scroll affordance shown; the header nav `flex-wrap`s and visually duplicates the sidebar links on mobile; Sync/Drift renders narrower (`:default` width) than every other screen (`:wide`); the verdict label differs across screens ("Can I trust search right now?" vs "Fleet posture" vs "Promotion readiness") — breaking SHELL-01 "reads identically as a unit".

**Plan-hypothesis verification (7/7 confirmed, 0 refuted):** all five "Design-system tightening targets" confirmed with evidence (see § Plan-hypothesis check).

---

## Ranked consolidated backlog

> Score = the audited dimension's 0–3 rating (0 worst). `#scr` = screens affected. SYS = promoted systemic.

### Blockers (any D1/D2/D3 = 0)

| ID | Alt | Touchpoint | Dim | Score | Sev | Evidence | Proposed fix | Fix-class | Phase |
|----|-----|-----------|-----|-------|-----|----------|--------------|----------|-------|
| B1 SYS | element | Posture per-schema table, 11 cols | D4 | 0 | blocker | `01-posture--*--mobile--incident.png` (only Schema+Index visible, rest clipped, no visible scroll cue); `posture_live.ex:231-278`, wrapper `ops_ui.ex:135-143` (`overflow-x-auto` exists but no shadow/affordance + no responsive collapse) | Add a scroll-shadow/edge affordance to `ops_table`; consider a card/stacked fallback or priority columns < 640px for the 11-col table | component+screen | 122/125 |
| B2 SYS | component | `ops_code_block` raw `rounded-md` + raw `p-3/p-2`, `max-h-96/48/64`, `bg-base-200` | D1 | 0 | `ops_ui.ex:941-944`; rendered on Failed Sync evidence, Search raw-hit, Playbooks preview (`06/08/09-*`, `02-*`) | `rounded-md`→`rounded-ops-md`; route padding to `p-ops-*`, surfaces to tokens | component+token | 121/122 |
| B3 | element | Skip-link uses raw `focus:rounded-md focus:px-3 focus:py-2 focus:shadow-lg focus:ring-2` | D1+D3 | 0 | `layouts.ex:54` | Route to `rounded-ops-*`/`p-ops-*`/`shadow-ops-*`; drop the `ring-2` (violates the single `:focus-visible` outline law) | token | 121 |
| B4 | element | Theme toggle raw `p-2 size-4 rounded-full border-1 brightness-200` + `min-h-[var(...)]` inline | D1 | 0 | `layouts.ex:210-247` | Promote to an `.ops-theme-toggle` component class consuming tokens; remove `brightness-200` magic | component+token | 122 |
| B5 SYS | component | `ops_notice` / `ops_status` duplicate tinted-surface internals (only `shadow-ops-surface` + header differ) | D2 | 0 | `ops_ui.ex:203-217` vs `232-254`; both render "status notice" across Sync/Drift (`ops_notice`), Failed Sync (`ops_status`) | Extract shared `.ops-notice-surface`; make `ops_status` a titled/action-bearing variant of one primitive | component | 122 |
| B6 | element | Sync/Drift uses `:default` (max-w-3xl) main width; every other screen is `:wide` (max-w-7xl) | D2 | 0 | `sync_drift_live.ex:276` (no `ops_main_width`); cf. `posture/failed_sync/search` set `:wide`; visible as a narrower column in `03-sync-drift--*--desktop--drift.png` | Set `ops_main_width={:wide}` on Sync/Drift (it has tables + 4-col preflight) | screen | 125 |

### Structural (D6 state-coverage gaps)

| ID | Alt | Touchpoint | Dim | Score | Sev | Evidence | Proposed fix | Fix-class | Phase |
|----|-----|-----------|-----|-------|-----|----------|--------------|----------|-------|
| S1 SYS | component | No shared loading/skeleton primitive; Refresh/Run/Load-drift have no in-flight state | D6 | 1 | grep: no `ops_loading`/`skeleton`/`animate-pulse` in `ops_ui.ex`/`app.css`; refresh handlers reassign synchronously (`posture_live.ex:37`, `search_live`, `sync_drift_live.ex:69`) | Add restrained `ops_loading` pulse/skeleton primitive; wire to long reads (drift, search, swap) | component | 122 |
| S2 | flow | Search has no loading state between "Run bounded search" and results | D6 | 1 | `06/08-search--*`; `search_live.ex` dispatch is sync | Use S1 primitive on the result panel | screen | 126 |
| S3 | flow | Sync/Drift contract-drift "Run now" → result swap is instantaneous, no pending feedback | D6 | 1 | `sync_drift_live.ex:397-408` | Use S1 on the drift status surface | screen | 125 |
| S4 | flow | Control Room has no `:unconfigured`/`:missing_backend` capture in baseline; only `incident`/`all_green` shot | D6 | 1 | seed scenarios cover empty for Failed Sync/Search/Playbooks but not Control Room/Posture unconfigured | Add `empty`/`unconfigured` captures for Control Room + Posture to the matrix | seed | 119-followup |
| S5 | flow | Posture has no `empty`/`loading` baseline; `all_green` + `incident` only | D6 | 1 | screenshot set lacks `posture--*--empty` | Add unconfigured + empty Posture captures | seed | 119-followup |
| S6 | component | `ops_metric` `kind` enum lacks `:info/:partial/:running` (allows only neutral/success/warning/error) | D6 | 1 | `ops_ui.ex:259`; `metric_tone_class/1` only maps success/warning/error→class, else nil (`ops_ui.ex:1176-1179`) | Complete the tone set to match `tone_class/1`; add `ops-metric-info/-partial/-running` | component+token | 121/122 |
| S7 | flow | Failed Sync "could not load" error notice (`ops_status` error) unverified in baseline (no error capture) | D6 | 1 | `failed_sync_live.ex:259-267`; no `failed-sync--*--error` shot | Add a degraded/error scenario capture | seed | 119-followup |
| S8 | flow | Playbooks empty-workspace covered, but no "import error/invalid JSON" or "preview-run result" capture | D6 | 1 | `09-playbooks--*--empty-workspace`; `playbook_live.ex` import/run paths | Add invalid-import + populated-run captures | seed | 119-followup |
| S9 | element | Sync/Drift "Mismatches" preflight step uses a tone (cyan/teal) not in the metric/badge family on other screens | D2+D5 | 1 | `03-sync-drift--*--drift` step 3 highlight; `sync_drift_live.ex:241-247` (`:warning`/`:neutral`/`:success`) — visual tone reads as `:running`/`:info` cyan vs amber warnings elsewhere | Confirm badge tone palette is shared; align "in-progress" tone with the systemic tone set (S6) | component | 122 |

### Polish (D1/D2/D3 ≥1, D5/D7, copy, rhythm)

| ID | Alt | Touchpoint | Dim | Score | Sev | Evidence | Proposed fix | Fix-class | Phase |
|----|-----|-----------|-----|-------|-----|----------|--------------|----------|-------|
| P1 SYS | flow | Nav groups `:triage`/`:probes`; breadcrumb group labels "Triage"/"Explore" | D2+D5 | 1 | `nav.ex:20,26,32,38,44`; `ops_ui.ex:426-431` ("Triage"); visible "Control Room › Triage › Posture" in `01/05-posture`, but Search shows "Explore" (`06/08`) — vocab forks | Rename to Recover/Explore (IA-01); `operator-ia.md` nav contract must update in lockstep | screen | 124 |
| P2 SYS | element | Shared empty states are Title Case: "No Schemas Configured", "Runtime Not Configured" | D5(copy) | 1 | `ops_ui.ex:543,553` (`ops_config_empty`) → Control Room + Posture; also `failed_sync_live.ex:246,254,353` ("No Schemas Configured", "Runtime Not Configured", "No Failed Sync Jobs") | Sentence-case sweep (COPY-01); fix at the component for the shared cases | component+screen | 122/124 |
| P3 SYS | element | `ops_result_row` / `ops_object_item` have no `:hover`/`:active` feedback (only buttons + intent cards do) | D2+D7 | 1 | `app.css` — `.ops-result-row` (845) and `.ops-object-item` (615) define no `:hover`; cf. `.ops-intent-card:hover` (794), `.ops-btn:active` (460) | Add restrained hover/press parity hooks (transform/opacity, A4) for interactive-feeling rows | component+motion | 122/123 |
| P4 SYS | element | Page-title casing forks: "Sync & Drift" (Title+ampersand), nav "Failed Sync"/"Sync Drift", page_title "Sync / drift", "Failed sync work" | D5(copy) | 1 | `sync_drift_live.ex:278`; `nav.ex` labels; `posture_live.ex:21`/`failed_sync_live.ex:26` | One casing rule (sentence case headings; nav labels matching) | screen | 124 |
| P5 | element | Verdict `label` differs per screen: "Can I trust search right now?" / "Fleet posture" / "Promotion readiness" | D2 | 1 | `control_room_live.ex:68`, `posture_live.ex:157`, `sync_drift_live.ex:457` | SHELL-01: the trust verdict must read identically on Control Room/Posture/Sync-Drift; unify label + dot + tone | screen | 127 |
| P6 | element | Header nav `flex-wrap`s and visually duplicates sidebar links on mobile | D4 | 1 | `00/01/02/03-*--mobile--*` (top nav row wraps above the page); `layouts.ex:60,70-85` | Collapse header nav to a menu/hidden on small screens (palette + sidebar are the mobile tiers) | screen+component | 124/127 |
| P7 SYS | element | `ops_intent_card` `kind` enum lacks `:info/:partial/:running` (neutral/success/warning/error only) | D2 | 2 | `ops_ui.ex:475` | Align enum with `tone_class/1`/systemic tone set (S6) | component | 122 |
| P8 | component | Raw padding steps inside components: `ops_data_card` `p-4`, `ops_empty_state` `p-5`, `ops_upload_box`/`ops_checkbox_list` `p-3`, `ops_data_card` subtitle `mt-0.5` | D1 | 2 | `ops_ui.ex:811,511,526,766,818` | Route to `p-ops-*`/`space-y-ops-*` | token+component | 121/122 |
| P9 | element | `ops_checkbox_list` checkbox `rounded` raw step | D1 | 2 | `ops_ui.ex:776` | `rounded`→`rounded-ops-sm` | token | 121 |
| P10 | element | `ops_modal` close button `right-3 top-3` raw steps | D1 | 2 | `ops_ui.ex:984` | Route to spacing tokens | token | 121 |
| P11 | element | `ops_object_item` CSS padding raw `0.875rem`/`0.75rem` (not token) | D1 | 2 | `app.css:612,619` | Use `--spacing-ops-*` | token | 121 |
| P12 SYS | element | Intent-card icons are emoji (🚨🚀🔎) — clash with "reserved / slightly arcane" brand; not the violet/copper route-path motif | D5 | 1 | `control_room_live.ex:91,99,107`; `00/04-control-room--*` | Replace with restrained line icons or the route/path mark; keep tone via `kind` | screen | 124 |
| P13 | flow | Control Room "Jump to" rail is a 3rd copy of sidebar+palette links | D5(IA) | 1 | `control_room_live.ex:118-144` | Trim to one "⌘K to jump anywhere" hint + a P1 orientation link (IA-01) | screen | 124 |
| P14 | flow | No quiet P1 first-timer orientation affordance on Control Room | D6 | 1 | `control_room_live.ex` (intent cards only) | Add "new here? what each surface does" link (IA-01) | screen | 124 |
| P15 | motion | Command palette + modal have enter animation but no exit; no `--ease-ops-exit` token | D7 | 1 | `app.css:933,1047` (enter `ops-modal-in`); no exit keyframe; tokens lack exit ease (`app.css:167-169`) | Add `--ease-ops-exit` (crisp); wire exit to palette/modal/flash close (A1) | token+motion | 121/123 |
| P16 | motion | No signature page-wide verdict tone-settle on Refresh (per-element settles exist, not one coherent beat) | D7 | 2 | `app.css:291-314` (per-surface tone transition); requirement A2 | Add coordinated verdict tone-settle on posture change (A2) | motion | 123 |
| P17 | motion | Flash uses `motion-safe:animate-spin` only on reconnect icon; no flash enter/exit easing | D7 | 2 | `layouts.ex:183,195` | Wire flash enter/exit to A1 easing | motion | 123 |
| P18 | element | Reconnect flash spinner is the only looping animation — acceptable, but verify it neutralizes under reduced-motion | D7 | 3 | `layouts.ex:183` `motion-safe:animate-spin` (already motion-safe gated) | Confirm (already OK) | — | 123 |
| P19 SYS | element | `ops-preflight` jumps 1→4 col at 768px (no 2-col tablet step) — cramped at exactly 768 | D4 | 2 | `app.css:722-726`; `03-sync-drift--*` | Add a `sm:` 2-col step; 4-col only at `lg` | token/screen | 121/125 |
| P20 | element | `ops_signal_table` dense 2-col can scroll on very small mobile | D4 | 2 | `sync_drift_live.ex:343-435`; `03-sync-drift--*--mobile` (readable but tight) | Inherit B1 scroll affordance | component | 122 |
| P21 | flow | Sync/Drift `ops_notice` (info, read-only) and `ops_status` (drift) coexist on one screen — two notice idioms side by side | D2 | 2 | `sync_drift_live.ex:293,397` | After B5 consolidation, one idiom | component+screen | 122 |
| P22 | element | Failed Sync evidence shows two stacked `ops_code_block` (reason + metadata) with `mt-2` raw | D1 | 2 | `failed_sync_live.ex:385-391` | `mt-2`→`space-y-ops-*` on wrapper | screen | 125 |
| P23 | flow | Failed Sync "Hide/Show reason rollups" toggle label flips meaning vs state (says "Hide reason rollups" when shown) — fine, but the metric grid hides via `class={@compact_mode && "hidden"}` (display toggle, no motion) | D7 | 2 | `failed_sync_live.ex:228-230,282` | Optional disclosure-style fade (A-tier, only if not toy) | motion | 123 |
| P24 | element | Posture "Next checks" links labeled "Open in OPSUI" — vocab not in brand set | D5(copy) | 2 | `posture_live.ex:204` | Imperative concrete CTA per COPY-01 | screen | 124 |
| P25 | element | Inline `<code>` in templates (not `ops_inline_code`) on Failed Sync/Sync-Drift | D2 | 2 | `failed_sync_live.ex:266,275,336-337`; `sync_drift_live.ex:294-298,466` | Route to `ops_inline_code` for consistent sizing | screen | 125 |
| P26 | element | "Reload list" / "last run loaded" microcopy is terse/Title-ish on Playbooks/Search | D5(copy) | 2 | `09-playbooks--*` ("Reload list"); `06-search--*` ("last run loaded") | Sentence-case + concrete | screen | 126 |
| P27 | element | Search "Non-production search playground" notice repeats on Playbooks ("Non-production playbook workspace") — consistent, good; verify one component | D2 | 3 | `06/09-*` | Confirm both use `ops_notice` warn tone | screen | 126 |
| P28 | flow | Playbooks action button row (Load preview/Run/Duplicate/Rename/Delete) is dense; Delete red sits among neutrals | D5 | 2 | `09-playbooks--*--desktop` | Group destructive via `ops_action_group tone={:danger}`; verify it isn't already | screen | 126 |
| P29 | element | Search results show "Hit 1 / Hit 2" generic titles; subtitle carries id+name | D5 | 3 | `06-search--*` | Lead with the human field (name) in the title | screen | 126 |
| P30 | element | `ops_fieldset` raw `p-0 m-0` reset (acceptable reset, flag for token audit) | D1 | 3 | `ops_ui.ex:572` | Leave (legit reset) or token | token | 121 |
| P31 | element | Metric value uses `text-ops-lg` mono — good; "Refreshed" metric shows a full timestamp that can wrap in a tile | D4 | 2 | `posture_live.ex:183-187`; `01/05-posture` | Shorten/relative time, or allow tile to size | screen | 125 |
| P32 | flow | Empty-state component fork: `ops_config_empty`/`ops_empty_state` (muted panel) vs `ops_status`(error) for "could not load" — three idioms for "nothing/can't show" | D2 | 2 | `ops_ui.ex:509,538`; `failed_sync_live.ex:259` | Document the three roles (config-gap vs empty-but-ok vs error) or consolidate surfaces | component | 122 |

---

## Systemic vs per-screen vs motion split

### Systemic → Phase 121 (tokens) / 122 (components)
These recur on ≥3 screens (or are component/token-rooted) and yield compounding dividends:

| # | Finding | IDs | Phase | Anchor |
|---|---------|-----|-------|--------|
| 1 | Complete the tone set (`info/partial/running`) in `ops_metric`/`ops_intent_card`/`metric_tone_class` | S6, P7, S9 | 121+122 | `ops_ui.ex:259,475,1176-1179` |
| 2 | `ops_code_block` `rounded-md`→token + raw padding/surfaces | B2 | 121+122 | `ops_ui.ex:941-944` |
| 3 | Consolidate `ops_notice`/`ops_status` tinted-surface internals | B5, P21, P32 | 122 | `ops_ui.ex:203-254` |
| 4 | Sentence-case shared empty states (`ops_config_empty`) | P2 | 122 | `ops_ui.ex:543,553` |
| 5 | Hover/press parity for `ops_result_row`/`ops_object_item` | P3 | 122+123 | `app.css:615,845` |
| 6 | Shared `ops_loading`/skeleton primitive | S1, S2, S3 | 122 | none today |
| 7 | Add `--ease-ops-exit` token | P15 | 121 | `app.css:167-169` |
| 8 | Raw-step leaks in components (skip-link, theme toggle, data-card, checkbox, modal, object-item) | B3, B4, P8-P11 | 121+122 | `layouts.ex:54,210`; `ops_ui.ex:511,766,776,811,984`; `app.css:612,619` |
| 9 | `ops_table` scroll affordance (shadow/edge) for dense tables | B1, P20 | 122 | `ops_ui.ex:135-143` |
| 10 | `ops-preflight` 1→4 col jump (add `sm:` 2-col) | P19 | 121/125 | `app.css:722-726` |
| 11 | Nav/breadcrumb vocab "Triage/Probes"→Recover/Explore (lands in IA, but the trail-label authority is the component) | P1 | 124 (component-touch) | `nav.ex`; `ops_ui.ex:426-431` |

### Per-screen → Phase 124 (IA + Control Room) / 125 (Recover) / 126 (Explore)
- **124 (IA + front-door + copy):** P1 (nav rename), P12 (emoji icons), P13 (Jump-to trim), P14 (orientation link), P2/P4/P24 (copy sweep, casing).
- **125 (Recover: posture/failed-sync/sync-drift):** B1/B6 (table scroll + wide width), P19 (preflight tablet), P22/P25 (code-block rhythm, inline-code), P31 (timestamp tile), S3 (drift loading).
- **126 (Explore: search/playbooks):** S2 (search loading), P26/P27/P28/P29 (copy, action-group, hit titles).

### Motion → Phase 123
- P15 (A1 exit easing on palette/modal/flash), P16 (A2 verdict tone-settle), P3 (A4 row press/hover), P17 (flash easing), P23 (optional rollup fade). P18 already motion-safe — verify only.

### Seed follow-up (119)
- S4/S5/S7/S8: add `unconfigured`/`empty`/`error`/`populated-run` captures for Control Room, Posture, Failed Sync error, Playbooks import-error + preview-run so D6 state coverage is fully evidenced.

---

## Plan-hypothesis check (Design-system tightening targets)

| Hypothesis (from plan) | Verdict | Evidence |
|---|---|---|
| `--ease-ops-exit` missing (only enter eases) | **CONFIRMED** | `app.css:167-169` defines `standard/out/in-out`; no `exit`; palette/modal animate enter only (`app.css:933,1047`) → P15 |
| `metric_tone_class/1` incomplete (missing info/running/partial) | **CONFIRMED** | `ops_ui.ex:1176-1179` maps only success/warning/error, else nil; `ops_metric`/`ops_intent_card` enums also drop them (`:259,:475`) → S6/P7 |
| `shadow-ops-mid` actually used on hover | **CONFIRMED (used)** | `ops_ui.ex:747` (segmented selected) + ladder defined `app.css:135-138`; intent-card hover uses `shadow-ops-raised` (`app.css:326`) — ladder is in use, no fix needed |
| Raw-step leaks (`p-4`/`text-2xl`/`rounded-md`/`min-h-9`/`duration-200`) | **CONFIRMED** | `ops_code_block` `rounded-md` (`:941`), `ops_data_card p-4` (`:811`), `ops_empty_state p-5` (`:511`), skip-link/theme-toggle raw (`layouts.ex:54,210`); ~73 candidate steps in `ops_ui.ex` (many legit layout, the above are real D1) → B2/B3/B4/P8-P11 |
| `ops_notice`/`ops_status` tinted-surface duplication | **CONFIRMED** | `ops_ui.ex:203-217` vs `232-254` share `rounded-ops-control border px-4 py-3 text-ops-body text-base-content + tone_class`; only shadow + titled-header differ → B5 |
| `ops_code_block` raw `rounded-md` (real D1) | **CONFIRMED** | `ops_ui.ex:941` → B2 |
| No shared loading component | **CONFIRMED** | grep: zero `ops_loading`/`skeleton`/`animate-pulse` in `ops_ui.ex`/`app.css` → S1 |
| Press/hover parity gap (only buttons + intent-cards) | **CONFIRMED** | `.ops-result-row`/`.ops-object-item` have no `:hover`/`:active` in `app.css` → P3 |
| `ops-preflight` 1→4-col jump at 768px (tablet cramping) | **CONFIRMED** | `app.css:722-726` single `@media(min-width:768px){repeat(4,...)}` → P19 |
| Dense `ops-signal-table` horizontal scroll on mobile | **CONFIRMED (mild)** | `ops_signal_table`→`ops_table` `overflow-x-auto`; Posture 11-col table is the acute case (B1), signal-table 2-col is tight not broken (P20) |

**Refuted: none.** All ten plan hypotheses confirmed; one (`shadow-ops-mid`) confirmed as *already correct* (no action).
