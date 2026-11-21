# Use phoenix_storybook for ScrypathOps stories, not a hand-rolled harness

ScrypathOps stories run on phoenix_storybook. It is a dev/test-only dependency of `scrypath_ops`, which is not a Hex package, so adopters never get its packages (`makeup_eex`, `makeup_html`, and `mdex`, a precompiled Rust NIF). We accepted that despite the project's "copy-paste over a dep" rule, because the browsable tree, docs, playground and search are the review surface the maintainer wants.

Fidelity comes from three choices:
- **Themes:** the `themes_strategies: [data_attribute: "theme"]` strategy. Ops dark CSS is keyed on `[data-theme="dark"]` descendant selectors, which work from any ancestor.
- **Iframes:** surface- and job-level stories render in `container: :iframe`, which covers System mode and gives real viewport widths.
- **Stylesheet:** `storybook.css` just `@import`s `app.css`.

On top of it, our own ExUnit gates check that every story renders, every story cites a twin, a persona and a job, every component is covered, and no two variations render identically.

## Considered options

- **A hand-rolled story LiveView, 450–650 lines with no dependencies.** It was recommended by research at first, but the maintainer rejected it on 2026-10-25 in favour of the established tool. It remains the fallback if a fidelity gap appears that an iframe can't solve.

## Amendments (2026-11-21, factual corrections; the decision to adopt phoenix_storybook stands)

Verified against the 1.5.0 source and by a measured spike-style compile (`.planning/research/catalog-prep/C-storybook-technical-shape.md`, `H-adversarial-pass.md`):

- **Iframe story types.** Only `:component` and `:example` stories render in `container: :iframe`; `:page` stories render inline (`story_live.ex:428-455`). Surface and job stories use `:component` or `:example`.
- **Themes.** `themes_strategies: [data_attribute: "theme"]` puts the attribute on `<body>`, not `<html>` (`root_iframe.html.heex:72-75`); the ops System-mode rules key on `html:not([data-theme="light"])`, so a small `storybook.js` sets the html attribute and registers the same hooks as `app.js`.
- **Stylesheet.** No separate `storybook.css`: `css_path` points at the production `/assets/css/app.css` (tracked at `scrypath_ops/priv/static/assets/css/app.css`).
- **Playground.** It cannot be disabled; the route stays loopback-only and dev/test-only.
- **Advisories.** mdex and mdex_native have two advisories published 2026-06-29, patched in the resolved versions.
- **Added trigger.** The Docker `asset_builder` stage growing by more than 60 s revisits the decision, alongside the existing triggers.
- **Build order.** The spike is Phase 195 and runs before the fixtures project (ADR 0002).

