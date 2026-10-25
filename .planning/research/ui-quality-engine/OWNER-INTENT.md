# UI quality engine: owner intent (2026-10-25)

The maintainer named this as **the next major opportunity to raise ScrypathOps UI quality**. Treat it as durable direction. The full methodology is in [METHODOLOGY-PROMPT.txt](METHODOLOGY-PROMPT.txt); recorded owner decisions outrank it where they conflict.

## What the maintainer asked for

- **A fractal storybook:** primitives → small groups of components → areas within a section → whole sections → whole pages per job. The tree follows the product's sections and jobs. Today there are no stories at all.
- **Cover every state that really happens, and only those:**
  - happy paths, error cases and boundary conditions, for every job and section;
  - aggressively prune scenarios the app can never render.
  - Stories are a fast lens for inspecting each scenario closely, much faster than full browser journeys.
- **Realistic fixtures:** seed and fixture data should feel like a digital twin of real adopters, spanning industries, B2B and B2C, and hosted and self-hosted products. Examples given: a Slack clone, a language-learning app, a personal finance tool. Fixture realism is checked, not assumed.
- **Composable, data-driven LiveViews:** pages render from plain data instead of hardcoded markup, so screens can be storied without a database.
- **A standing design bar, applied on every pass:**
  - both light and dark mode look good, and the colors aren't tacky;
  - typography looks professionally designed and intentional, never accidental;
  - information hierarchy is easy to follow and elegant, not ham-fisted;
  - nothing is redundant;
  - every job's happy path is great, and power users are served too;
  - an "iPhone-designed", award-winning feel, never AI slop.
- **Microcopy:** consistent, user-facing domain language, never internal vocabulary.
- **Personas, jobs and the journey:** personas and jobs-to-be-done are curated continuously, and the journey is coherent across the whole UI and within each section. Navigation feels natural and a joy to use.
- **Mobile first:** responsive across all realistic viewport widths.
- **Design system dividends:** the design system and component library should pay off, with principle of least surprise and clear affordances.
- **Dependencies:** "another copy and paste is better than another dep". Keep the tree small and flat.

## Sequencing request

Weave this into [the rolling roadmap](../../reference/ROLLING-ROADMAP.md) in a logical, efficient order. Don't drop the approved sync and foundation work if it matters.
