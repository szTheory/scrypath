---
phase: 177-shared-patterns-and-delivery-proof
plan: 01
subsystem: operator-ui
tags: [phoenix-live-view, design-system, playwright, accessibility, visual-baseline]
requires: []
provides:
  - Source-bound root DESIGN.md in the established eight-section format.
  - Current six-surface OpsUi/token catalog examples and explicit retired rules.
  - Dynamic export-to-catalog coverage without a literal component count.
  - 90 retained direct images and a six-surface source/visual audit.
  - 60 selected Search/Playbooks interaction screenshots, separately labelled as supplementary.
affects: [phase-177-plan-02, phase-177-plan-03, phase-177-plan-04, phase-177-plan-05]
actuals:
  tasks: 3
  commits: 3
tech-stack:
  added: []
  patterns:
    - Test System-dark in a fresh browser context with OS dark preference and no explicit theme override.
    - Keep scenario, theme, viewport width, and state identity in each screenshot filename.
    - Derive the component inventory from current OpsUi exports and check catalog coverage dynamically.
key-decisions:
  - Correct the plan's Control Room `ops_section/1` assumption to the rendered labelled native section and actual OpsUi children.
  - Preserve six task-specific scan paths and use the existing Phoenix, CSS token, and Playwright seams without dependencies.
  - Give the direct Playbooks empty-state capture an isolated empty workspace; leave repository example fixtures untouched.
  - Carry all 48 UI-SPEC truths into the audit as acceptance criteria, not as completed implementation findings.
requirements-completed: []
coverage:
  - id: P177-01-A
    description: Document the current shared operator UI vocabulary and make export coverage dynamic.
    requirement: OPUX-26
    verification:
      - kind: integration
        ref: `mix verify.ops_ui` — 2 doctests and 301 tests, 0 failures; task-local Hex cache.
        status: pass
      - kind: unit
        ref: `test/scrypath_ops_web/design_tokens_contract_test.exs` — 8 tests, 0 failures.
        status: pass
    status: partial
  - id: P177-01-B
    description: Capture and inspect the source-bound theme and viewport baseline, then prove selected Search/Playbooks interactions.
    requirement: OPUX-27
    verification:
      - kind: browser
        ref: `screenshots-matrix` — 3 scenario groups, 90 retained images, all nine combinations per capture.
        status: pass
      - kind: browser
        ref: `admin_surface_depth.spec.ts` — 38 tests, 0 failures; 60 selected supplementary images.
        status: pass
      - kind: other
        ref: `make -C examples/scrypath_ecommerce contrast` — 0 AA failures; 43 AAA advisory findings.
        status: pass
    status: partial
completed: 2026-10-12
status: complete
---

# Phase 177 Plan 01: Source-bound design baseline and screenshot matrix

**The six operator surfaces now have a source-accurate design guide and a retained 90-image baseline across Light, Dark, System-dark, and three widths; exported component coverage remains dynamic.**

## Accomplishments

- Created the root [`DESIGN.md`](../../../DESIGN.md) in the official section order and grounded its colors, typography, layout, elevation, components, and interaction rules in the current implementation.
- Updated [`DESIGN-TOKENS.md`](../../../scrypath_ops/assets/css/DESIGN-TOKENS.md) with a mount-path-accurate description, six real surface examples, neutral verdict semantics, and concrete retired shell/spacing treatments.
- Removed the literal `49` assertion while retaining runtime discovery of exported OpsUi components and export-to-catalog coverage.
- Extended the existing admin screenshot matrix to 390×844, 768×900, and 1440×900 in explicit Light/Dark and unoverridden System-dark. The existing three scenario groups passed and produced 90 direct images.
- Created [`177-UI-AUDIT.md`](177-UI-AUDIT.md), containing the six source/route scan paths, actual repeated vocabulary, direct-image findings, all 48 UI-SPEC acceptance criteria, and the 90 direct plus 60 supplemental screenshot paths.
- Inspected every nine-image capture contact sheet. The final Playbooks empty-state images show a genuinely empty workspace; three tracked repository fixtures remained unchanged.

## Task commits

- `9f97199` — `docs(177-01): add source-bound operator design tracer`
- `cc53498` — `test(177-01): cover the full admin screenshot matrix`
- Final plan documentation commit records the completed audit and summary.

## Deviations and environment corrections

- The plan said Control Room called `ops_section/1`; source inspection found a labelled native `<section>` with actual OpsUi notice, empty-state, verdict, and intent-card functions. Documentation follows source rather than adding a fictitious call.
- Compose retained its named Playbooks volume at the application's normal path. A temporary path-specific bind was used for host/server interaction tests; a separate empty task-local workspace was used only for the empty-state matrix. No compose file, package, or tracked fixture was changed.
- The existing Search page-title assertion matched the empty-state heading; it now requests an exact accessible heading name.
- Playwright clears its default `test-results` directory on each run. The final direct matrix and depth images were restored after the last browser run, then all 150 links were checked against the retained files.
- An initial Hex cache write to `/Users/jon/.hex` was denied by the workspace boundary; the passing Elixir gates used `/private/tmp/scrypath-phase177-hex`. Initial browser attempts made before the cold Compose app was healthy and while the Playbooks directories differed were discarded; the final prescribed suites passed against the task-owned project.

## Verification

- `HEX_HOME=/private/tmp/scrypath-phase177-hex ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.5 mix verify.ops_ui` — 2 doctests, 301 tests, 0 failures.
- `mix test test/scrypath_ops_web/design_tokens_contract_test.exs` — 8 tests, 0 failures.
- `COMPOSE_PROJECT_NAME=phase177-baseline WEB_PORT=4002 ADMIN_SCREENSHOT_DIR=test-results/phase177-before make screenshots-matrix` — 3 scenario groups passed; 90 PNGs retained.
- `PLAYWRIGHT_BASE_URL=http://127.0.0.1:4002 PHASE176_VISUAL_EVIDENCE_DIR=test-results/phase177-before-depth npm run test:e2e:admin-depth` — 38 tests passed; 60 selected Search/Playbooks images retained as supplemental evidence.
- `make -C examples/scrypath_ecommerce contrast` — 0 AA failures; 43 AAA findings remained advisory.
- `git diff --check` and audit validation — passed; all 48 criteria, 90 direct image links, and 60 supplementary links are present and resolve.
- Stopped only `phase177-baseline`; zero containers remain and `phase177-baseline_e2e_playbooks` remains. Port 4012 was not contacted.

## Remaining phase scope

The audit carries the 48 UI-SPEC truths forward but does not claim exhaustive implementation proof. OPUX-26 and OPUX-27 remain pending at phase level until subsequent plans complete their shared-pattern and per-slice evidence. Continue with Plan 177-02, which may correct only drift the audit establishes.
