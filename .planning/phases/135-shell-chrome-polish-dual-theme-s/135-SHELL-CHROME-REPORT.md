# Phase 135 Shell Chrome Report

**Requirement:** SHELL-DARK-01
**Plan:** 135-04
**Evidence date:** 2026-06-26

SHELL-DARK-01 is verified for the shared ScrypathOps shell chrome: header/nav, command
palette, shortcut sheet, theme toggle, flash, the live inline brand mark, and the `.ops-shell`
violet wash. The proof is focused on Phase 135 scope and does not replace Phase 136's full
milestone verification, screenshot gallery, audit, or human UAT.

## Automated Gate Results

| Gate | Command | Result |
| --- | --- | --- |
| Ops UI focused/static gate | `cd scrypath_ops && mix verify.opsui` | PASS: 2 doctests, 146 tests, 0 failures |
| Ops UI precommit gate | `cd scrypath_ops && mix precommit` | PASS: 2 doctests, 146 tests, 0 failures |
| Fast contrast gate | `cd examples/scrypath_ecommerce && make contrast` | PASS: AA failures 0, AAA advisory 19 |
| Focused shell browser proof | `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-shell -- --reporter=line` | PASS: 30/30 |
| Browser contrast matrix | `cd examples/scrypath_ecommerce && PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 npm run test:e2e:admin-contrast -- --reporter=line` | PASS: 3/3 |

The browser gates reused the already-running source ecommerce stack at `http://127.0.0.1:4002`.

## Six-Screen Coverage

The focused shell browser proof visits all six operator surfaces through `SHELL_SURFACES` in
`examples/scrypath_ecommerce/e2e/admin_shell_chrome.spec.ts`:

| Screen | Covered Shell Assertions |
| --- | --- |
| Control Room | Header separation, no duplicate active primary nav item, `.ops-shell` wash, theme toggle, palette/sheet, flash |
| Posture | Header/nav active fill and glow, `.ops-shell` wash, theme toggle, palette/sheet, flash |
| Failed Sync | Header/nav active fill and glow, `.ops-shell` wash, theme toggle, palette/sheet, flash |
| Sync/Drift | Header/nav active fill and glow, `.ops-shell` wash, theme toggle, palette/sheet, flash |
| Search | Header/nav active fill and glow, `.ops-shell` wash, theme toggle, palette/sheet, flash save flow |
| Playbooks | Header/nav active fill and glow, `.ops-shell` wash, theme toggle, palette/sheet, flash |

## Theme-Mode Coverage

The shell proof runs the full shell suite across explicit light, explicit dark, and system dark,
and across mobile 390px and desktop 1440px viewports. System dark uses Playwright `colorScheme:
"dark"` without forcing `localStorage["phx:theme"]`, so it exercises the separate system-dark
CSS path rather than only `[data-theme="dark"]`.

## Command Palette `aria-modal` Resolution

`aria-modal="true"` stayed on both `#ops-cmdk` and `#ops-cheatsheet`. Plan 135-03 hardened the
existing `CommandPalette` hook instead of downgrading semantics, and Plan 135-04 reran the proof.
The browser assertion `expectAriaModalTruth/3` verifies:

- `role="dialog"` remains present when `aria-modal="true"` is present.
- Initial focus is inside the open palette or shortcut sheet.
- `Tab` keeps focus bounded inside the open modal surface.
- `Escape` closes the surface.
- Focus returns to the opener.

The command palette also proves one active option through `aria-selected="true"` and mirrors that
option id to the input's `aria-activedescendant`. The no-results branch removes the active option
and clears `aria-activedescendant`.

## Flash Role, Icon, Text, And Chrome Proof

Flash proof is covered by both static component contracts and browser interaction:

- `ScrypathOpsWeb.OpsShellContractTest` proves `CoreComponents.flash/1` keeps `role="alert"`,
  durable `.ops-flash`, `.ops-flash--info`, `.ops-flash--error`, icon output, text, close label,
  and `lv:clear-flash` dismissal.
- The browser proof triggers a real visible flash by saving a Search playbook, then asserts
  the saved-playbook text, `role="alert"`, `.ops-flash`, `.ops-flash--info`, SVG icon, and
  `Close notification` button.
- CSS gives `.ops-flash` the overlay recipe in light and composes
  `--shadow-ops-overlay, --shadow-ops-panel-dark` in explicit dark and system dark.

## `.ops-shell` Wash Boundedness

The `.ops-shell` wash remains one quiet top-left radial plus one linear page floor:

- Static contract: `ShellChromeTokenContractTest` scans every `.ops-shell` rule and requires
  exactly one `radial-gradient`, exactly one `linear-gradient`, and `circle at top left`.
- Browser proof: `expectShellWash/1` reads computed `background-image` and requires one radial
  layer plus the structural linear floor.
- Token documentation records base/light 14% / 34rem, dark 10% / 30rem, and dark mobile
  8% / 24rem. No extra gradient layers, orbs, bokeh, texture, or decorative loops were added.

## Header/Nav AA Status

Header/nav chrome is covered by static CSS contracts, browser computed-style checks, and the AA
matrix:

- `.ops-header` has a measurable divider and non-none box shadow in browser proof.
- `.ops-nav-item-active` uses `--color-primary-strong` for the text-bearing selected fill.
- Explicit dark and system-dark paths compose `--shadow-ops-surface` with `--shadow-ops-glow`
  for the active nav item.
- The shell browser proof runs axe `color-contrast` on `.ops-header`, `.ops-shell`,
  `#theme-toggle`, and `.ops-nav-item-active` across every screen/theme/viewport.
- The full admin contrast matrix passed all three scenarios with zero AA failures.

## Theme Toggle State Proof

Theme toggle proof covers root state, selected button state, and visual movement:

- Root `html` state updates `data-theme-preference`, `data-theme`, and `data-theme-effective`
  for system/light/dark.
- The selected button exposes a visible indicator and, when present, truthy `aria-pressed` or
  `aria-current`.
- `data-theme-selected` and `aria-pressed` are statically asserted in `OpsShellContractTest`.
- The pill moves when switching explicit light to explicit dark.
- `.ops-theme-toggle`, `.ops-theme-toggle__pill`, and `.ops-theme-toggle__button` have durable
  CSS contracts and mirrored explicit/system dark treatments.

## D-03 Light-Change Gate

No D-03 light-theme exception was recorded in `135-02-SUMMARY.md` or `135-03-SUMMARY.md`.
Because no recorded light exception exists, the conditional `node e2e/light-pixel-diff.mjs`
gate was not run for Plan 135-04.
Audit verdict: no light exception.

Plan 135 did add shell semantic/state classes and dark-only chrome treatments, but no report from
Plans 02 or 03 recorded a D-03 light pixel exception requiring a Phase 135 light-pixel recapture.

## Generated Artifact Hygiene

Generated proof artifacts stayed out of git staging:

- `.tmp/` remains untracked.
- `examples/scrypath_ecommerce/test-results/` remains ignored/untracked from git status.
- `scrypath_ops/priv/static/**` remains untracked.

`mix precommit` produced formatter-only diffs in three unrelated LiveView files during the gate run.
Those files were clean before the command, were not part of Plan 135-04, and were restored by explicit
path after inspection so the evidence commit stays scoped to this report.

## Dependency And Schema Push Status

- No package install, package upgrade, or lockfile change exists in Plan 135-04.
- Schema push detection found no Payload CMS, Prisma, Drizzle, Supabase, or TypeORM schema paths in
  Phase 135 sources. The detection command returned no matches for `payload.config.*`,
  `schema.prisma`, `drizzle.config.*`, `supabase`, `typeorm.config.*`, `data-source.ts`, or
  `data-source.js` after pruning deps, node_modules, generated outputs, and `.tmp`.
- No schema push task was added.

## Decision Coverage

| Decision | Coverage |
| --- | --- |
| D-01 | Dark-first and shell-only boundary held; no D-03 light exception was recorded. |
| D-02 | No broad light-theme shell redesign was opened. |
| D-03 | Light-change audit is recorded above; conditional pixel-diff skipped because no exception existed. |
| D-04 | `Layouts.app/1` and `Nav.primary/1` structure stayed intact. |
| D-05 | Active nav keeps `aria-current="page"`, `--color-primary-strong`, and restrained dark glow. |
| D-06 | `.ops-header` uses the dark ambient-shadow-plus-border recipe in both dark paths. |
| D-07 | `.ops-shell` remains one quiet top-left radial wash plus one linear floor. |
| D-08 | Proof targets the live `.ops-brand-mark` inline SVG selector, not only stale `.ops-route-mark`. |
| D-09 | Palette, flash, and theme behavior remain on existing hook/component/root theme mechanisms. |
| D-10 | Durable `.ops-*` shell selectors exist for theme toggle and flash chrome. |
| D-11 | Theme selected state, active command option, close labels, and focus return were hardened/proven. |
| D-12 | `aria-modal` stayed and is browser-proven by bounded focus and focus return. |
| D-13 | Flash keeps passive alert semantics, icon/text pairing, and non-color-only status signal. |
| D-14 | Focused browser proof exists as `admin_shell_chrome.spec.ts`. |
| D-15 | Proof covers explicit light, explicit dark, system dark, mobile, desktop, and all six surfaces. |
| D-16 | Hidden/interactive chrome is exercised: palette, shortcut sheet, theme toggle, and flash. |
| D-17 | Computed-style shell checks and existing contrast harnesses both passed. |
| D-18 | Phase 136 still owns full 40-shot recapture, gallery, milestone audit, and human UAT. |
| D-19 | Chrome remains an orientation layer around operator evidence, not a new workflow/product surface. |
| D-20 | Screen names and task language remain concrete: Control Room, Posture, Failed Sync, Sync/Drift, Search, Playbooks. |
| D-21 | Accessibility, clarity, consistency, resilience, maintainability, restraint, and DX are covered by the gate bundle and static tripwires. |

## Multi-Source Audit

| SOURCE | ID | Feature/Requirement | Status | Evidence |
| --- | --- | --- | --- | --- |
| GOAL | - | Header/nav, command palette, theme toggle, flash, and `.ops-shell` wash are brand-expressive and AA-clean across all 6 screens | COVERED | Browser shell 30/30, contrast matrix 3/3, `mix verify.opsui` green |
| REQ | SHELL-DARK-01 | Shell chrome is brand-expressive and AA-clean in both themes; weak header-nav dark contrast fixed; palette/flash adopt dark ambient-shadow-plus-border recipe | COVERED | `make contrast` AA failures 0; shell browser proof explicit light, explicit dark, system dark |
| RESEARCH | - | Use existing `Layouts.app/1`, `Nav.primary/1`, `ops_command_palette/1`, `CoreComponents.flash/1`, `CommandPalette`, and `app.css` shell selectors | COVERED | Plans 02-03 modified existing shell surfaces; Plan 04 verified without new public API |
| RESEARCH | - | Add focused `admin_shell_chrome.spec.ts` and `test:e2e:admin-shell` | COVERED | Spec exists and passed 30/30 |
| RESEARCH | - | Mirror custom dark shell rules in explicit dark and system-dark paths | COVERED | `ShellChromeTokenContractTest` plus browser system-dark rows |
| RESEARCH | - | Resolve `aria-modal` question through proof or semantic downgrade | COVERED | `aria-modal` stayed with focus-bound/focus-return proof |
| RESEARCH | - | No new package installs or upgrades | COVERED | No package or lockfile changes; Plan 04 docs-only source diff |
| CONTEXT | D-01 | Dark-first and shell-only; keep light pixel-identical by default | COVERED | No recorded D-03 light exception |
| CONTEXT | D-02 | Do not open broad light-theme chrome redesign | COVERED | No broad light CSS or screenshot recapture in Plan 04 |
| CONTEXT | D-03 | Any light pixel movement is explicit with selector/rationale/gate | COVERED | D-03 audit recorded; conditional gate not required |
| CONTEXT | D-04 | Preserve `Layouts.app/1` and `Nav.primary/1` structure | COVERED | Existing structure and nav routes remained the source of truth |
| CONTEXT | D-05 | Active nav stays conventional and accessible | COVERED | Active nav `aria-current`, `--color-primary-strong`, and glow verified |
| CONTEXT | D-06 | Header reads as seated operator surface using dark recipe | COVERED | Header computed shadow/divider and static dark mirrors verified |
| CONTEXT | D-07 | `.ops-shell` wash remains one quiet top-left radial | COVERED | Static and browser checks require one radial layer |
| CONTEXT | D-08 | Reconcile stale route-mark CSS with live inline brand mark | COVERED | `.ops-brand-mark` selector is statically asserted |
| CONTEXT | D-09 | Keep palette, flash, and theme behavior mostly intact | COVERED | Existing hook/component/root theme script preserved |
| CONTEXT | D-10 | Promote durable `.ops-*` shell selectors | COVERED | `.ops-theme-toggle*` and `.ops-flash*` contracts present |
| CONTEXT | D-11 | Minor semantic hardening for truthful states | COVERED | Theme selected state, active option, and close labels proven |
| CONTEXT | D-12 | Prove or downgrade command-palette modal semantics | COVERED | Proved; no downgrade needed |
| CONTEXT | D-13 | Flash adopts recipe while preserving alert semantics | COVERED | `.ops-flash` overlay composition plus `role="alert"`/icon/text proof |
| CONTEXT | D-14 | Add focused browser proof | COVERED | `admin_shell_chrome.spec.ts` passed |
| CONTEXT | D-15 | Cover theme modes and mobile/desktop across six surfaces | COVERED | 30-test shell matrix covers three theme modes x two viewports x five groups |
| CONTEXT | D-16 | Exercise hidden/interactive chrome | COVERED | Palette, sheet, theme toggle, and flash flows exercised |
| CONTEXT | D-17 | Use computed-style visual contracts and contrast harness | COVERED | Computed-style browser checks, static token tests, `make contrast`, and axe matrix green |
| CONTEXT | D-18 | Preserve Phase 136 ownership of full gallery/audit/UAT | COVERED | No Phase 136 artifacts generated or committed |
| CONTEXT | D-19 | Shell chrome orients Phoenix/Ecto operator | COVERED | Report and proof stay on wayfinding chrome, not runtime/product expansion |
| CONTEXT | D-20 | Keep JTBD language concrete and task-first | COVERED | Six concrete screen names and existing nav vocabulary retained |
| CONTEXT | D-21 | Preserve accessibility, clarity, consistency, performance, resilience, maintainability, restraint, DX | COVERED | Gate bundle and static tripwires are green |

## Phase 136 Boundary

Phase 135 does not claim milestone closure. Phase 136 remains responsible for:

- full 40-shot screenshot recapture,
- v1.33 to v1.34 before/after gallery,
- milestone audit,
- human UAT,
- final dual-theme milestone verification.

Plan 135-04 only records the focused SHELL-DARK-01 evidence and source audit needed to hand off to
that final milestone verification phase.
