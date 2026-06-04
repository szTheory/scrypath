---
phase: "131"
plan: "03"
subsystem: scrypath_ops/components + scrypath_ops/assets/css
tags: [copper-accent, design-tokens, ops-ui, documentation, lockstep]
dependency_graph:
  requires: ["131-01"]
  provides: [copper-eyebrow-in-situ, design-tokens-lockstep]
  affects:
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
tech_stack:
  added: []
  patterns: [utility-class-swap, lockstep-mirror-documentation]
key_files:
  created: []
  modified:
    - scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex
    - scrypath_ops/assets/css/DESIGN-TOKENS.md
decisions:
  - "Single utility-class swap on ops_page_header eyebrow <p> — four inline utilities replaced with .ops-copper-eyebrow; propagates to all 6 screens via shared component"
  - "DESIGN-TOKENS.md ## Shadow section gains dark-only-augmentation note (one sentence linking to the new glow section)"
  - "Two new DESIGN-TOKENS.md sections placed between ## Shadow and ## Focus to follow the file's existing section ordering"
  - "Token rgba values in DESIGN-TOKENS.md match app.css exactly (lockstep)"
metrics:
  duration: "~10min"
  completed: "2026-06-04"
  tasks_completed: 2
  files_modified: 2
---

# Phase 131 Plan 03: Eyebrow In-Situ Proof + DESIGN-TOKENS.md Lockstep Summary

One-line eyebrow re-style swapping four inline utility classes to `.ops-copper-eyebrow` on the shared `ops_page_header` component, plus two DESIGN-TOKENS.md sections documenting the glow/dark-depth tokens and copper accent vocabulary in lockstep with app.css.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Re-style the shared eyebrow slot to .ops-copper-eyebrow | b9e2e09 | scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex |
| 2 | Add the two DESIGN-TOKENS.md lockstep sections | 99a4efd | scrypath_ops/assets/css/DESIGN-TOKENS.md |

## What Was Built

### Task 1: Eyebrow re-style (ops_ui.ex)

On the shared `ops_page_header` component's eyebrow `<p>` (line 23), replaced:
```heex
<p class="text-ops-sm font-semibold uppercase tracking-wide text-secondary">
```
with:
```heex
<p class="ops-copper-eyebrow">
```

The string "Operator workspace" and the enclosing `space-y-1` wrapper div are unchanged. Because this is a shared component slot, the single change propagates copper rendering to all 6 operator screens (Control Room, Posture, Sync/Drift, Failed Sync, Search/Federation, Playbooks).

This is the COPPER-01 in-situ proof (D-01) — Phase 131's only per-template copper application; per-screen badge/node copper is deferred to Phase 134 (D-01a).

### Task 2: DESIGN-TOKENS.md additions

Three additions to `scrypath_ops/assets/css/DESIGN-TOKENS.md`:

**1. Note appended to `## Shadow` section:**
> `--shadow-ops-panel-dark` is a dark-only supplement declared in the D-10 dual-path blocks; it is **not** declared in light. Light panels continue to use `--shadow-ops-surface` (vertical lift).

**2. New section `## Glow + dark ambient depth — Phase 131`:**
- 3-row token table: `--shadow-ops-panel-dark` (dark-only, not in @theme/light), `--shadow-ops-glow` (none → violet), `--shadow-ops-glow-copper` (none → copper, reserved for Phase 133/134)
- Exact rgba values matching app.css: `rgba(0,0,0,0.30)`, `rgba(108,92,231,0.30)`, `rgba(193,122,62,0.25)`
- Prose explaining panel-dark ring-plus-lift composition, glow-copper restraint rationale

**3. New section `## Copper accent vocabulary — Phase 131`:**
- Allowed-use table for `.ops-copper-eyebrow` / `.ops-copper-badge` / `.ops-copper-node[--fill]`
- Badge text rule: always `var(--color-base-content)`, never `var(--color-secondary)` as badge label (light AA fails at 4.15:1)
- Eyebrow text rule: `var(--color-secondary)` is AA-safe only as eyebrow text on surface-1
- Hard rule: copper is a brand accent, NEVER a status tone — not in `tone_class/1` / `badge_class/1`
- 6-row AA pairing evidence table (sRGB / D-12 compliant)

## Verification Results

| Check | Result |
|-------|--------|
| `ops-copper-eyebrow` count in ops_ui.ex | 1 (exactly one, on the eyebrow `<p>`) |
| Old inline utilities (`text-ops-sm font-semibold uppercase tracking-wide text-secondary`) removed | Confirmed — grep finds 0 matches on that exact combination at L23 |
| "Operator workspace" string intact | Confirmed at L24 |
| `mix compile` (scrypath_ops) | Clean — no new warnings |
| `mix verify.opsui` | 129 tests, 0 failures |
| `## Glow + dark ambient depth — Phase 131` section present | Confirmed |
| `## Copper accent vocabulary — Phase 131` section present | Confirmed |
| `shadow-ops-panel-dark` in DESIGN-TOKENS.md | Confirmed (dark note + token table) |
| Token rgba values match app.css | Confirmed exactly |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. `.ops-copper-eyebrow` is fully wired at the eyebrow slot. `.ops-copper-badge`, `.ops-copper-node`, `.ops-copper-node--fill` stubs are intentionally deferred (D-01a, Phase 134) and documented in the 131-01-SUMMARY.md.

## Threat Flags

None. Both changes are static non-interactive surfaces: a server-rendered HEEx class-name literal and Markdown documentation. No input, auth, network, or data flow introduced. T-131-03 (static class attribute) and T-131-SC (zero package installs) both accepted per plan threat model.

## Self-Check: PASSED

- [x] `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex` modified
- [x] `scrypath_ops/assets/css/DESIGN-TOKENS.md` modified
- [x] Commit b9e2e09 exists (Task 1)
- [x] Commit 99a4efd exists (Task 2)
- [x] `ops-copper-eyebrow` appears exactly once in ops_ui.ex
- [x] Both DESIGN-TOKENS.md section headers present
- [x] Token values match app.css exactly
- [x] `mix verify.opsui` 129/0
