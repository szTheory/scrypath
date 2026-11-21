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


## Amendment: measured go/no-go (Phase 195, 2026-11-21)

**Decision: continue with phoenix_storybook, as the maintainer's choice against a tripped cold sample, not as a pass.** One of two hosted cold samples is over its line, so the cold trigger counts as tripped; the maintainer selected "Continue (Recommended)" in an interactive dialog on 2026-11-21 (relayed to the executor by the orchestrating agent). The warm line held. The full record, including run ids and the method, is [GO-NO-GO.md](../phases/195-mount-and-prove/GO-NO-GO.md). The phase PR (#171) was the timing run: its first hosted run is the first cold sample, a rerun of the `ops-ui` job on the same commit is the warm sample, and the main push run that the merge started is a second cold sample. #171 merged on the first cold sample, before the second existed.

Numbers, from `gh run view <id> --json jobs`, against the locked baseline of 368 s:

- **Cold `ops-ui`: 517 s** on the PR run (run 44955813968, attempt 1), under the 548 s line (368 + 180) by 31 s, and **620 s** on the post-merge main run (run 44958204651, attempt 1), 72 s over. Evidence only: the 14-run main median is 409.5 s and the spread is 360 to 579 s; over the previous 38 main runs the median is 410 s, the maximum 590 s, and 5 runs exceeded 548 s, none after a lock change. Same-day controls (the pre-merge main job rerun) took 342 s at 22:32 UTC and 417 s at 22:57 UTC, so identical work varied by 75 s inside 25 minutes; the cold excess is +175 s and +203 s against them.
- **Warm `ops-ui`: 378 s** (run 44955813968, attempt 2), under the 428 s line (368 + 60). Against the same-day control the storybook's own marginal cost is +36 s (one paired sample). The cold excess is mostly the root-graph BEAM cache miss that every lock change pays (about 135 s in `verify.ops_ui`; earlier Dependabot ops-lock runs took 424 to 555 s with no storybook).
- **Rust NIF fetch:** 0.40 s and 0.66 s on hosted `x86_64-unknown-linux-gnu` (Elixir logger timestamps in the Docker builds, `asset_builder` and `runtime_test`); it is not separable inside the `ops-ui` job. Zero NIF failures.
- **Lock growth:** `scrypath_ops/mix.lock` 56 to 65 lines, nine packages added, no existing entry changed; the root and example locks are unchanged.
- **Advisories:** none open on a resolved version. phoenix_storybook's three (patched in 1.1.0), mdex's (patched in 0.13.2 and 0.12.3) and mdex_native's (patched in 0.2.3) all predate the resolved versions 1.5.0, 0.14.7 and 0.3.2. The audit shows only the existing sigra, cloak and cloak_ecto baseline.
- **Docker `asset_builder`:** +33 s (the `Bake and load checked mounted images` step took 292 s against a main median of 259 s; a hosted proxy that includes the stage, so an upper bound), under the 60 s line.

Triggers, one verdict each: advisory open over 14 days, not tripped; cold `ops-ui` over baseline plus 180 s, **tripped** (one sample at 620 s; the maintainer chose to continue); isolation work over a day, not tripped (0.1 h); Docker `asset_builder` over plus 60 s, not tripped; NIF failure twice, not tripped. The warm line (a Phase 195 exit criterion, not a trigger) is within.

Corrections recorded by this phase: the route flag has to be read with `Application.get_env` at expansion, because `Macro.expand` of `Application.compile_env(...)` returns a call AST that is always truthy (the existing `dashboard_routes/1` guard has this latent defect; it is handed to the maintainer, not fixed here); and `data-phx-error` is never emitted by the server, so render-all relies on crash, empty-sandbox and unknown-variation signals. The fidelity probe is deferred to Phase 197.
