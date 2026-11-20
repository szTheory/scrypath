---
slug: website-refresh
title: Full goal-first refresh of the public website and the discovery and onboarding journey, with permanent upkeep guards
status: planted
created: 2026-11-20
updated: 2026-11-20
trigger_when: v1.47 Phase 189 (website identity re-skin) has merged, or when planning the next milestone after v1.47, or when the maintainer wants a stronger first impression for GitHub stars and portfolio use
planted_during: v1.47 Brand completion
---

# Seed: Website refresh (goal first, then look and copy), plus upkeep

## Trigger

Surface this when v1.47 Phase 189 has merged and the next milestone is being chosen, when the maintainer asks about GitHub stars, adoption or a portfolio-quality first impression, or when library, API, version or brand changes mean the site's claims need checking.

## Why it exists

The maintainer (2026-11-20, after rediscovering the site): the website "looks pretty bad and could be way better". It was a starting point. Sanity-check it from the ground up, not only re-skin it: what is its goal, who does it serve, what is in scope versus the HexDocs, README and ScrypathOps docs, and how should it look and feel under the brand book. Goals named: help people understand what Scrypath is, build trust, help earn GitHub stars, and work as a portfolio piece.

Two standing requirements from the same conversation:

1. **Tools:** use the Impeccable skill (installed, v4.10.0, modes Persuade, Operate, Read, Experience) for design and the `ux-writing` skill for copy, both checked against the brand book (voice, imagery, typography, color, microcopy).
2. **Upkeep is permanent.** All user-facing domain language on the site follows the glossary, brand voice and the GOV.UK-style copy rules already recorded for the operator UI. The site must be updated whenever the library, API, version, docs or brand change, and automated guards must stop it from drifting, breaking or becoming inaccurate or generic.

## Wider frame (maintainer, 2026-11-20): the discovery and onboarding journey

The website is one surface of a journey, not the whole problem. The README, website, HexDocs and guides overlap, link lists spam the reader, and people arrive from GitHub, hex.pm, HexDocs or the website. The refresh must start from the journey for first-time visitors, people starting to use Scrypath and returning users, give each surface one job and stop duplicating content. The full intent, journey stages, a hypothesis for surface roles and the open questions are in `reference/DISCOVERY-AND-ONBOARDING-JOURNEY.md`: read it first. The recommended shape is one milestone covering README, website, HexDocs structure and guides together, with the README trim (`todos/pending/2026-11-20-trim-readme-and-choose-a-route.md`) inside it.

## Relationship to v1.47

Phase 189 (SITE-01..05) is identity only: palette, fonts, lockups, favicons, theme picker, deploy safety. It stays that way and does not become the refresh. What survives into a refresh: the token-derived build pipeline, the deny-set, the static contract, the browser check and the deploy smoke step. What a refresh redoes: page content, information architecture and layout. Avoid polishing page-specific CSS in Phase 189 that the refresh will replace.

## Scope notes from the scoping pass (2026-11-20; notes in `.planning/research/website-refresh/`)

- **Current state** ([03 inventory](../research/website-refresh/03-current-site-inventory.md)): four pages (index, docs, evaluate, operators), about 330 to 450 words each, one 641-line hand-written dark-only CSS file, system fonts, no JS, one diagram, old violet and copper palette. The nav label "Operations" points to a page titled "operator support".
- **Weaknesses** ([01 goals and scope](../research/website-refresh/01-goals-audience-scope.md)): "Docs" is a link farm to GitHub blob markdown (HexDocs only in the footer); no logo; nothing shows Scrypath working (no Mix output, no Search health drawing, no queued-then-searchable path); copy breaks the brand voice ("folklore", "wedged", "boring", "hydration", "accepted work" instead of "queued" or "searchable"); evaluate's meta promises a comparison the page does not contain.
- **Honesty bug, independent of the refresh:** the site tells Hex adopters to run `mix verify.adopter` (home status strip, install callout, operators step 2). That task is repo-only since Phase 183 and is not in the Hex package. Replace it with `mix scrypath.status`, `failed`, `retry` and `reconcile`. Tracked as SITE-06 in v1.47 Phase 189.
- **Proposed primary goal:** a Phoenix or Ecto developer can say in 30 seconds what Scrypath is and is not, see it working, and reach the golden path in one click. Secondary: trust through exactness, routing without duplicating, honest stars, portfolio, contributors. One job per page (Home, Evaluate, Operate; Docs goes to HexDocs).
- **Single-source rule:** one owner per claim (support guide, sync-modes guide, scope policy, `brand/BRAND.md`, `mix.exs`); the site links or quotes, never restates.
- **Benchmarks** ([02](../research/website-refresh/02-benchmarks-patterns.md), 14 sites): what works is a plain one-sentence hero, real code and a pinned install line above the fold, code next to its result, honest limits and gotchas, a sourced comparison page (Typesense), a short nav that sends readers to HexDocs, and a zero-install try link. Anti-patterns: unsourced benchmarks, vague feature-card grids, placeholder counters ("0", "NaN"), hero sections with no code, empty alt text. The repo has 0 stars, so no counters and no invented proof.
- **Recommendations to start from:** (1) hero with one sentence, one snippet generated from code CI runs, and the pinned dependency line; (2) a "how sync really works" diagram plus honest limits and compatibility; (3) a "when not to use" and comparison page with every fact linked to its source; (4) only checkable social proof and one plain star ask; (5) a CI-gated technical floor (light/dark/auto theme, no-JS complete, contrast tests, Lighthouse CI, OG card with `og:image:alt`, sitemap).

## Upkeep guards to design into the refresh

- Site copy rules ride the v1.47 `copy_rules.json` table (forbidden and required text per surface) or a sibling table; no second copy of strings.
- The version, install line and snippet come from `mix.exs` and code CI runs, never typed by hand.
- Claim and link parity checks: every GitHub blob link resolves, every claim has one named source, banned-claim phrases stay in the existing contract tests (phase110 and phase112 read website sources; page merges or renames edit those tests in the same commit).
- A CONTRIBUTING or AGENTS rule: a change to the library's public surface, docs or brand updates the site in the same PR or records why not.

## Open questions only the maintainer can answer

- Scope and sequencing: its own milestone right after v1.47 (recommended below) or after the catalog?
- Does "Docs" leave the site and defer entirely to HexDocs?
- Version badge: the book says none, Phase 189 keeps the existing one.
- Real screenshots or drawings for the product proof?
- A named-competitor comparison page, and its tone?
- Portfolio framing and where the star ask sits.
- GOV.UK-style plain content design versus more personality, given the stars and portfolio goals.
- Budget: stay no-analytics and no-new-dependency?

## Recommended slot (confidence medium; the maintainer chooses)

A small milestone immediately after v1.47 ("Website refresh", about 2 to 3 phases: goal and information architecture; copy and design with Impeccable and `ux-writing`; upkeep guards and launch), ahead of the catalog. Reason: the brand work, the pinned tokens and the deploy safety net are fresh, the first impression affects every later adopter, and the catalog work does not depend on it. What would change this: a preference to ship the catalog first (then run it after v1.48), or wanting a smaller step (fold only the honesty fix and Home page into a v1.47 Phase 189 plan).

## Breadcrumbs

- `.planning/reference/DISCOVERY-AND-ONBOARDING-JOURNEY.md` (the intent; read first)
- `.planning/research/website-refresh/` (01 goals, audience and scope; 02 benchmarks and patterns; 03 current-site inventory)
- `.planning/research/v1.47-prep/B-website-reskin.md`, `.planning/research/v1.47-gap-pass/G-website-risk.md`
- `.planning/research/ui-quality-engine/RESEARCH-PERSONAS-FIXTURES-COPY.md` (GOV.UK-style copy rules), `.planning/reference/OPERATOR-UI-QUALITY.md`, `guides/jtbd-and-user-flows.md`
- `brand/BRAND.md` ("Applications: the website"), `brand/brand.json`
- `website/`, `.github/workflows/website.yml`, `test/scrypath/phase110_*`, `phase112_*` contract tests
- Memory: website-refresh-and-upkeep
