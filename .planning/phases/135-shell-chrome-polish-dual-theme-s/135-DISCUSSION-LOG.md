# Phase 135: Shell chrome polish (dual-theme) `[S]` - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-06-26
**Phase:** 135-shell-chrome-polish-dual-theme-s
**Areas discussed:** Light-change boundary, Header/nav and shell wash, Command palette/flash/theme toggle, Verification shape

---

## User Direction

The user selected all gray areas and requested a one-shot, research-backed recommendation set instead of
step-by-step option picking. The requested lens included:

- subagent research for each area;
- pros/cons/tradeoffs and examples for each approach;
- Elixir/Phoenix/LiveView ecosystem idiom;
- lessons from successful tools/design systems in this and adjacent ecosystems;
- developer ergonomics, software architecture, SRE/DevOps, accessibility, UI/UX, graphic design, JTBD,
  user psychology, and project vision;
- use applicable material in `prompts/` and prefer newer `brandbook/` material over older brand prompt
  details when they conflict.

Four `gsd-advisor-researcher` agents were spawned in parallel:

- Light-change boundary
- Header/nav + shell wash
- Command palette, flash, theme toggle
- Verification shape

---

## Light-change Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Strict dark-only / light pixel-identical | Protects the green light baseline and keeps Phase 136 comparison simple, but may block small objective shell fixes. | |
| Limited both-theme shell refinements | Dark-first by default, with narrow shell-only light exceptions for objective AA/state/focus/geometry defects. | X |
| Broad light rework | Maximizes light redesign freedom but conflicts with v1.34/v1.35 anti-thrash decisions and expands verification burden. | |

**User's choice:** User delegated final choice to research-backed recommendation.

**Notes:** The research agent recommended limited both-theme shell refinements with a tight boundary.
This became D-01 through D-03 in CONTEXT.md.

---

## Header/nav and Shell Wash

| Option | Description | Selected |
|--------|-------------|----------|
| Subtle token/CSS dark tune | Preserve current Phoenix shell and tune dark/system-dark chrome with existing tokens and shadow/glow recipes. | X |
| Stronger branded chrome with glow/gradient | More immediately branded, but risks loud chrome, mobile violet blob, and decorative operator UI. | |
| Markup/nav restructuring or shell variants | Could formalize future shell variants, but adds churn without evidence and risks route/a11y regressions. | |

**User's choice:** User delegated final choice to research-backed recommendation.

**Notes:** The research agent recommended subtle token/CSS dark tuning, with only a narrow markup exception
for stale selector alignment around the post-v1.35 inline brand mark. This became D-04 through D-08.

---

## Command Palette, Flash, Theme Toggle

| Option | Description | Selected |
|--------|-------------|----------|
| CSS-only polish | Smallest blast radius, but leaves brittle selectors and potential unverified semantics. | |
| Named `.ops-*` chrome classes + minor semantic attributes | Keeps behavior intact while making shell chrome durable, testable, and more accessible. | X |
| Behavior/API redesign | Could rebuild an APG-grade command palette and flash system, but is too broad for SHELL-DARK-01. | |

**User's choice:** User delegated final choice to research-backed recommendation.

**Notes:** The research agent recommended named shell classes plus small semantic hardening, not a behavior
redesign. This became D-09 through D-13.

---

## Verification Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Static + existing contrast only | Cheap, but misses hidden/interactive shell states and browser media behavior. | |
| Focused shell computed-style/interaction spec | Proves SHELL-DARK-01 directly while keeping final gallery/UAT in Phase 136. | X |
| Full 40-shot/contrast/milestone gate now | Maximum evidence, but duplicates Phase 136 and slows iteration. | |

**User's choice:** User delegated final choice to research-backed recommendation.

**Notes:** The research agent recommended a focused `admin_shell_chrome.spec.ts` style proof plus existing
ops UI/contrast gates, deferring full gallery/UAT to Phase 136. This became D-14 through D-18.

---

## Research Sources Consulted

### Local project sources

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/phases/129-dark-theme-brand-expression-audit-s-r/129-DARK-AUDIT-BACKLOG.md`
- `.planning/phases/132-a11y-contrast-remediation-both-themes-hard-gate-g/132-CONTEXT.md`
- `.planning/phases/133-dark-path-motion-expression-r-g/133-CONTEXT.md`
- `.planning/phases/134-under-iterated-surface-polish-dual-theme-s/134-CONTEXT.md`
- `.planning/phases/134-under-iterated-surface-polish-dual-theme-s/134-03-SUMMARY.md`
- `scrypath_ops/assets/css/DESIGN-TOKENS.md`
- `scrypath_ops/assets/css/app.css`
- `scrypath_ops/lib/scrypath_ops_web/components/layouts.ex`
- `scrypath_ops/lib/scrypath_ops_web/nav.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/ops_ui.ex`
- `scrypath_ops/lib/scrypath_ops_web/components/core_components.ex`
- `scrypath_ops/assets/js/app.js`
- `brandbook/notes/decision-log.md`
- `brandbook/notes/pressure-test.md`
- `brandbook/notes/research.md`
- `brandbook/notes/accessibility-checks.md`
- `prompts/phoenix-best-practices-deep-research.md`
- `prompts/phoenix-live-view-best-practices-deep-research.md`
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- `prompts/scrypath-brand-book.md`

### External sources

- Phoenix LiveView `Phoenix.Component` docs: https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html
- Phoenix LiveView JS interop docs: https://hexdocs.pm/phoenix_live_view/js-interop.html
- Phoenix LiveView JS commands docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.JS.html
- Phoenix LiveViewTest docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html
- daisyUI theme docs: https://daisyui.com/docs/themes/
- Tailwind dark mode docs: https://tailwindcss.com/docs/dark-mode
- W3C WCAG 2.2: https://www.w3.org/TR/WCAG22/
- W3C WCAG contrast minimum: https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum
- W3C WCAG non-text contrast: https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html
- WAI-ARIA modal dialog pattern: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/
- Playwright accessibility testing: https://playwright.dev/docs/accessibility-testing
- Playwright emulation: https://playwright.dev/docs/emulation
- GitHub command palette docs: https://docs.github.com/en/get-started/accessibility/github-command-palette
- Linear docs: https://linear.app/docs/editor
- Atlassian color/design-token dark-mode guidance: https://atlassian.design/foundations/color
- GitHub Primer accessible notifications: https://primer.style/accessibility/patterns/accessible-notifications-and-messages/

## Claude's Discretion

- Exact selector names for new shell classes.
- Exact wash alpha/extent values, as long as the result is quiet and verified.
- Exact split between Playwright assertions and cheap ExUnit/static token tripwires.

## Deferred Ideas

- Broad light-theme shell redesign.
- Full APG-grade command palette redesign or dependency adoption.
- New nav IA/shell variants.
- Full 40-shot gallery, milestone audit, and UAT, which stay in Phase 136.
