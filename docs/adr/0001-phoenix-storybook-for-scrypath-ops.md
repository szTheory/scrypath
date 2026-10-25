# Use phoenix_storybook for ScrypathOps stories, not a hand-rolled harness

ScrypathOps stories run on phoenix_storybook. It is a dev/test-only dependency of `scrypath_ops`, which is not a Hex package, so adopters never get its packages (`makeup_eex`, `makeup_html`, and `mdex`, a precompiled Rust NIF). We accepted that despite the project's "copy-paste over a dep" rule, because the browsable tree, docs, playground and search are the review surface the maintainer wants.

Fidelity comes from three choices:
- **Themes:** the `themes_strategies: [data_attribute: "theme"]` strategy. Ops dark CSS is keyed on `[data-theme="dark"]` descendant selectors, which work from any ancestor.
- **Iframes:** surface- and job-level stories render in `container: :iframe`, which covers System mode and gives real viewport widths.
- **Stylesheet:** `storybook.css` just `@import`s `app.css`.

On top of it, our own ExUnit gates check that every story renders, every story cites a twin, a persona and a job, every component is covered, and no two variations render identically.

## Considered options

- **A hand-rolled story LiveView, 450–650 lines with no dependencies.** It was recommended by research at first, but the maintainer rejected it on 2026-10-25 in favour of the established tool. It remains the fallback if a fidelity gap appears that an iframe can't solve.
