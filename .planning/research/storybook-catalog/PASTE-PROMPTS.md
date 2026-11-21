# Paste prompts for the storybook catalog context pass (2026-11-21)

Why: the maintainer wants a Phoenix Storybook catalog for ScrypathOps, built from realistic adopter data, and wants sibling projects' lessons and the brandbook session's fake-company scenarios brought in as provenance-tagged context. Owner decision D1 (2026-10-25) already adopted `phoenix_storybook`; see [OWNER-INTENT](../ui-quality-engine/OWNER-INTENT.md) and [RECOMMENDATIONS](../ui-quality-engine/RECOMMENDATIONS.md). Replies come back into `.planning/research/storybook-catalog/replies/` with the source project named.

## Prompt 1: sibling project sessions (accrue, threadline, mailglass, exifcleaner)

Paste the core block, then add the one-line extra for that project.

```
I'm preparing a systematic UI catalog (Phoenix Storybook) for another Elixir library, Scrypath, whose ScrypathOps embedded LiveView admin UI has ~7 screens (control room, health/posture, failed sync, sync & index drift, search playbooks/saved searches, help). The catalog will cover atoms -> control groups -> screen areas -> screens -> user flows, with happy paths, error cases and boundary conditions, using realistic data from realistic fake adopters. This project is further along (or has relevant lessons). Please answer from what is actually in THIS repo and its history, not from general knowledge, and reply as ONE markdown document I can paste back verbatim. For every claim give provenance (file:line, commit, phase or PR) and mark it VERIFIED (you read it) or RECALLED (from session memory only). No padding.

1. Taxonomy: how do you name and nest granularity levels (atom, group, area, screen, flow)? Show the real directory tree and 3 real story names per level. What rule decides which level a piece of UI belongs to?
2. State coverage: how do you enumerate happy / error / empty / loading / boundary / long-text / non-Latin / huge-count / permission states per component? Is there a closed list or a coverage manifest? What enforces that nothing is missing and nothing unreachable is storied?
3. Realistic data: where do fixtures come from, who owns them, how do you keep them from drifting from production shapes, and how do you check realism? What fake companies/personas/industries do you use? Paste the persona list.
4. Verification gates: every test/CI check that runs against the catalog (render-all, axe, contrast, visual regression, copy lint, manifest staleness, theme parity). For each: what it caught, cost in CI minutes if known, flakiness history, and whether you would keep it.
5. Dependencies and supply chain: exact packages added, lockfile growth, native/NIF concerns, how the catalog route is kept dev-only/loopback, advisories you hit.
6. Brand/tokens: how brandbook tokens reach the catalog, how light/dark are rendered in stories (iframe? data-theme?), what drifted anyway.
7. Process: the phase-by-phase path you took, what you built first, what you would build first next time, rework you did, and the top 5 anti-patterns/footguns with the incident that taught each.
8. Review loop: how the maintainer reviews the catalog and how feedback is recorded and triaged.
9. Numbers: story count by level, states per component (median/max), time to add a story, CI delta.
10. If you were advising a small project with ONE UI package and a demo host app, what is the smallest version of this that still pays off, and what would you skip?
```

Extras (append one line):

- accrue: `Also cover storybook/phase252-manifest.json (what it records, what enforces it), accrue_admin vs accrue_portal story sharing, brandbook vs brandbook-v2, and why that migration happened.`
- threadline: `Also cover DESIGN-SYSTEM.md: what it prescribes, what tests enforce it, and whether you planned or rejected a component catalog and why.`
- mailglass: `You are the least advanced here, which is valuable: say plainly what exists, what you tried and cut, what blocked a catalog (email preview fixtures? theming? demo realism?), and what you would do differently.`
- exifcleaner (React): `This is React, not Phoenix: separate what is framework-independent (taxonomy, state enumeration, realistic fixtures, gates, review loop) from what is Storybook/React specific, and say which ideas you think transfer to phoenix_storybook .story.exs files.`

## Prompt 2: brandbook session (fablebook, chatly, logistic and the other fake companies)

```
I am building a systematic UI catalog (Phoenix Storybook) for Scrypath, an Elixir library that keeps Meilisearch indexes in sync with Ecto data. Its operator UI shows: sync health, failed sync work, index drift, reindex/promotion, saved searches (playbooks) and help. To catch blind spots I want every story to use REALISTIC data from realistic fake adopters, never contrived test data. Please turn the fake-company brandbooks you have made (chatly, logistic, and all the others) into a "scenario pack", one markdown file I can paste back verbatim. For EACH company (up to 15, say how many exist):

A. Identity: name, one-line product, industry, B2B/B2C, hosting model (SaaS / self-hosted), team size and who the search-ops person is (their role and what pages them).
B. Brand: palette as hex with token names, fonts, voice in one line, logo description. (So a story can be themed per adopter.)
C. Searchable data: 2-4 indexed entities with 8 realistic records each as compact JSON (ids, names, descriptions, prices/dates/locales as the domain would have). Include on purpose: very long names, non-Latin and right-to-left text, emoji, near-duplicates, archived/deleted/soft-deleted rows, missing optional fields, huge counts, tenant ids, and values that break UI layouts. No lorem ipsum, no real people's PII.
D. Search behavior: 10 realistic queries real users type (typos, partial words, SKUs/order numbers, questions), plus 5 that should return nothing and why.
E. Operational reality: how this product's data changes (bulk imports, nightly jobs, user edits), which sync mode fits (inline / Oban async / manual), and 6 plausible search-sync failures in this domain expressed in plain words (for example a bulk import enqueues 40k updates and 312 fail on a malformed field; a deleted tenant leaves orphaned documents; an index swap is half done), each with a realistic numeric scale.
F. Edge cases the domain naturally produces that a generic ecommerce demo would never show.

Then add:
G. A ranking of the 5 companies best suited to exercise a search-ops admin UI, and the single state each one uniquely stresses, so no two overlap.
H. Which brandbook files/assets (paths) a developer should copy, plus any license caveats. House rule: copy-paste over adding dependencies.
I. Anything you learned while making these brands about what makes fake data feel real vs contrived.
```
