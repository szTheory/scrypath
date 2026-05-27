---
slug: scrypath-public-website-launch-surface-2026-05-27
title: Scrypath public website launch surface
status: resolved
created: 2026-05-27
updated: 2026-05-27
---

# Thread: Scrypath public website launch surface

## Goal

Ship a public GitHub Pages front door for Scrypath that complements HexDocs instead of duplicating it.

## Context

This thread records the launch-surface work that followed the v1.27 trust-hardening milestone. The repo was already near-done on runtime scope; the missing leverage was a public homepage that helps evaluators, adopters, and operators orient quickly.

## Decisions

- Use a static site under `website/` rather than a heavier app framework.
- Host on GitHub Pages so the public URL is lightweight and reusable across future OSS libraries.
- Keep the site docs-first and route people into the existing guides and example app.
- Stamp release truth from `mix.exs` during build so the homepage does not drift from the package.
- Keep the site self-contained: no remote font dependency, no custom domain dependency, no HexDocs mirror.
- Use Playwright screenshot checks in CI to keep the homepage, operator page, and mobile layout honest.
- Ignore `website/dist/`, `website/artifacts/`, and `website/node_modules/` locally so only source and lockfile matter.

## Lessons

- Render content tokens before layout injection. A single-pass replacement on the outer template left nested placeholders unresolved.
- Network-dependent font imports make a static launch surface flaky. System fonts are the right default here.
- A website milestone is only worth doing if it routes people to the real docs and example app instead of consuming the docs role itself.

## References

- `website/`
- `README.md`
- `guides/overview.md`
- `guides/support-and-compatibility.md`
- `.planning/milestone-candidates.md`
- `.planning/STATE.md`

