# Search health metric explanations — 2026-10-09

The maintainer could not tell what “queues observed” measured or why that number mattered to an operator. The implementation counted schemas with readable queue observations, not distinct queues. Search health now uses that fourth tile for failed queue jobs, which exposes actionable stopped work alongside failed backend tasks. Unavailable checks and source-specific observations remain visible; this change does not alter health classification or claim that zero failures establishes index freshness.

The fleet labels are “Schemas in scope,” “Incomplete checks,” “Failed backend tasks,” and “Failed queue jobs.” Optional information buttons explain the configured schema scope, incomplete source checks, indexing inside the search engine, and background synchronization jobs. Backend tasks and Queue jobs keep their existing names across recovery workflows; each schema group's help introduces those terms and distinguishes queue completion from finished indexing. The footer action says “Review failed sync work” rather than introducing another ambiguous “queue.”

The shared `ops_help` component uses the native Popover API and the existing icon, typography, and surface tokens. Its small local hook adds hover/focus discovery and viewport placement. Tap or activation pins an explanation; a second activation, outside click, or Escape closes it. The pointer can move into the explanation to read it. Required states and actions remain outside help. No dependencies were added. Implementation references: [MDN Popover API](https://developer.mozilla.org/en-US/docs/Web/API/Popover_API/Using) and [W3C content on hover or focus](https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html).

Validation:

- App `mix precommit`: 278 tests + 2 doctests, zero failures, including compilation, formatting, navigation and component catalog contracts. The new regression checks failed queue-job rollups and a refresh to unavailable queue observations without fabricated per-schema zero counts.
- Canonical root `mix verify.ops_ui`: 278 tests + 2 doctests, zero failures.
- Native Chromium: 8/8 passed, zero failures/errors/skips and no retries. Mounted and standalone entry points at 1440px and 390px in light and dark cover hover persistence, touch toggle, outside dismissal, keyboard focus, Escape, Enter, Tab, viewport placement, LiveView refresh, and drill-in cleanup. The companion XML is the unchanged native report, with screenshot attachment paths pointing to external run artifacts.
- Desktop/mobile light/dark screenshots inspected together. Six runtime source files matched both preview images by SHA-256. The preview stayed on its existing all-green demo data; no seed or recovery mutation was run.

The initial browser invocation started before the rebuilt servers listened: six cases reported connection refused and two passed. That native report and traces remain in `/private/tmp/scrypath-phase173-20261006-155750/ui-health-help-browser/`; the companion report is the complete run after both services were healthy. The first precommit run caught the missing new-component catalog entry, which was added before the passing run.

This is a focused maintainer UI follow-up on draft PR95, stacked on PR94. Phase175 remains unstarted. Prior phase and exact-SHA hosted evidence remain historical to their respective source revisions.
