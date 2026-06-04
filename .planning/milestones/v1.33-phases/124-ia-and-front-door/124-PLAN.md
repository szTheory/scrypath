# Phase 124 Plan: IA + Control Room front-door (IA-01 + COPY-01)

**Status:** Owner-gated (implemented + verified; NOT committed — awaiting before/after approval)
**Requirements:** IA-01, COPY-01

## Goal

Make the operator nav speak the same task-first language the Control Room already teaches:
rename the nav groups to job language (Recover / Explore), thread the chains in-page, trim the
front door, and sweep the remaining microcopy. Labels and vocabulary only — no LiveView
event/logic/behavior changes; routes, handlers, and the mount path stay identical; the ⌘K palette
keeps working.

## Tasks

- **IA-01 nav rename (lockstep):** group atoms `:triage`→`:recover`, `:probes`→`:explore` in
  `nav.ex`; breadcrumb group labels `"Triage"`→`"Recover"` in `ops_ui.ex` `trail_for/1`
  (Explore was already correct); the layout group-class hook + its CSS rule
  (`ops-nav-group-probes`→`ops-nav-group-explore`); `operator-ia.md` prose group language updated
  to recover-first task framing. The nav-contract JSON fence (route+label+title) is unchanged, so
  `mix scrypath_ops.check_nav_contract` stays green.
- **IA-01 threading:** confirm the in-page "next step" chain (Posture→Failed Sync→Sync Drift→Posture
  via `ops_handoff`; Search↔Playbooks via header link); add the missing Search→Playbooks `ops_handoff`
  ("save it and open playbooks") so the explore loop closes at the page bottom like the recover chain.
- **IA-01 front-door trims (`control_room_live.ex`):** demote the "Jump to" rail (a 3rd copy of
  sidebar+palette links) to a single "Press ⌘K to jump to any surface" hint; add one quiet P1
  orientation link ("New here? See what each surface does" → `operator-ia.md`) that does not compete
  with the intent cards; replace the emoji intent-card icons (🚨🚀🔎) with on-brand monoline
  Heroicons (`hero-wrench-screwdriver` / `hero-arrow-up-tray` / `hero-map`).
- **COPY-01 microcopy sweep:** sentence-case remaining Title-Case per-screen strings; every
  empty/error state names a concrete next action; CTA verbs match the new group labels
  (recover/explore); fix "Open in OPSUI"/"Reload list"/"Run sample searches" vocab drift.

## Verification

1. `mix verify.opsui` green — the nav-contract test must pass (nav.ex ↔ operator-ia.md lockstep).
2. `cd scrypath_ops && mix test` green (update tests asserting old Triage/Probes labels or old copy).
3. `cd examples/scrypath_ecommerce && mix compile --warnings-as-errors` clean.
4. Boot + capture AFTER screenshots into `/tmp/p124-screenshots/` (Control Room 00 + Posture 01,
   light+dark × mobile 390 + desktop 1440); compare against `.tmp/admin-screenshots/` baseline.

## Constraints

- No route/handler/mount changes; presentation + vocabulary only (mirrors 117/121-123's no-behavior contract).
- Owner-gated: leave changes uncommitted; the orchestrator commits after approving the before/after.
