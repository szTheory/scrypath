# Sibling storybook scan (2026-11-21)

**Provenance.** Five read-only Sonnet subagents scanned `~/projects/accrue`, `threadline`, `mailglass`, `exifcleaner` and `fablebook` on 2026-11-21 after the maintainer asked for a storybook "with realistic adopters and the lessons from my other libs". (The maintainer named GPT-6 Luna for delegation; this session's agent tool offers only Claude models, so Sonnet was used.) Nothing was run and nothing in those repos was changed. Each claim below was read by a subagent and **not re-verified by the lead agent** unless it matches a rule that the 2026-11-18 survey already recorded in [BRAND-ADOPTION-PLAYBOOK](../../reference/BRAND-ADOPTION-PLAYBOOK.md) (then the playbook ID is cited). Tags: V = subagent read it, I = inference. The replies that the maintainer pastes back from each project's own session go in `replies/` beside this file and outrank these scans where they differ.

**Headline.** The 2026-11-18 survey already covers most of this (playbook C1 to C30). What the scan adds: (1) all four Phoenix siblings already ship a catalog, so mailglass is not "behind"; (2) hard cost numbers that argue for a small, capped first version; (3) fablebook's six fictional adopters as ready realistic-data sources; (4) one accrue finding that a complete green catalog still shipped incoherent screens. New rules went into the playbook as C31 to C34.

## accrue (the real storybook)

- V: tiers Primitive / Pattern / Area / Screen / Flow as folders `components/ groups/ areas/ pages/ flows/`, sidebar order from `folder_index` in each `index.exs`; stories are thin shims over compiled support modules (`accrue_admin/storybook/_support/*.ex`, `mix.exs:46-47`). Matches C1, C4, C12.
- V: ordinary data comes from one deterministic scenario module with a fixed clock (`dev_support/ui_scenarios/cadence_subscriptions.exs`); stress and long-text states are separate named variations. Matches C6, C15.
- V: **a complete catalog with green checks still shipped incoherent screens** that the owner found (`milestones/v1.69-phases/256.1-.../256.1-LEARNINGS.md`): raw predicate strings, a default story dominated by test-flavored data ("Storybook Customer Billing", UUID ids), duplicate "All/Organization" filters, wrapper CSS leaking into previews, a screenshot clipped by its parent so the DOM said content existed and the image did not; 136 of 142 visual cases never assessed. New rule C32.
- V: review loop (`AGENTS.md:34,57-60`): a stable seeded server on one port, refreshed and re-verified at every milestone close; feedback captured verbatim in dated notes, each row mapped to catalog entry id, state, viewport, theme and source file, then batched by shared source. Adopted into this session's process (C32).
- V: cost: `phase254-budget.json` has browser-uat at 900 to 1,230 s and the phase-200 axe lane at 1,050 to 1,740 s on success, about a dozen red PR runs while iterating, about 55k lines of test and e2e code, and an estimate of about 78M diff characters of JSON receipts (`notes/2026-11-11-admin-review-iteration-efficiency.md`). Avoid (C8, C16, C20, C25).
- V: smells to avoid: duplicate `*.index.exs` siblings; a coverage manifest with 5 entries beside a separate catalog; branding PSB's own shell (reversed after owner correction; keep the shell native, brand only product specimens).
- V: a 2026-11-21 accrue note proposes fablebook's Logistify, Shopadelic, Chatly and Clinicly as more fictional hosts for realistic billing scenarios (`.planning/notes/2026-11-21-admin-storybook-realistic-billing-scenarios.md`), the same idea this milestone uses.

## threadline

- V: a mature catalog, about 58 story and index files under `examples/threadline_phoenix/storybook/` (foundations, primitives, components, forms, states, overlays, data_display, groups, patterns, operations), phoenix_storybook pinned at 1.2.0 dev/test only; standing rule in `AGENTS.md:188-200` (one anchored variation per meaningful state, notes outside the themed wrapper, no parallel registry). Matches C12, C13.
- V: a fixtures module with 14 named "ugly cases" (long_id, long_string, non_ascii, null_fields, mixed_severity, permission_denied, stale, reconnecting, pagination_boundary, timezone_boundary, disabled, error, empty, zero_count; `lib/threadline_phoenix_web/storybook/fixtures.ex:9-24`), kept apart from ordinary seed data. Matches C15.
- V: `DESIGN-SYSTEM.md` is a table generated from a JSON ledger, about 77 rows that are mostly placeholder boilerplate; its scores are labeled historical. Avoid a generated ledger that no one acts on.
- V: a paid LLM UI critic whose verdict cache was keyed without the screenshot silently faked before/after results; it was parked and retired. Only deterministic checks gate (`RETROSPECTIVE.md:1110-1120`).
- V: stories are static; routing, auth, params and DB reads stay in mounted tests. Threadline reports that phoenix_storybook 1.2.0 `:example` stories are child LiveViews that cannot implement `handle_params`. Scrypath targets 1.5; the spike must verify this on 1.5 (C7, C23).
- V: threadline rejected healthcare and finance demos because they would imply compliance claims (`.planning/research/2026-11-10-brand-admin/storybook-journeys.md:7`). Relevant to Clinicly and Finanza: see C31.

## mailglass (not behind: it has two catalogs)

- V: a dev-only phoenix_storybook in the demo app (`reference/demo_app/mix.exs:55`, 15 story files) plus a 1,684-line hand-built gallery (`mailglass_admin/lib/mailglass_admin/gallery_live.ex`), with Playwright matrices at 320/390/768/1440 times light, dark, system and an axe lane with an approved-findings ledger.
- V: cost is the lesson. v2.10 "Faithful Storybook" took 76 plans and about 12 runner minutes over budget; the roadmap now lists "full Storybook catalogue" below the diminishing-returns line (`.planning/ROLLING-ROADMAP.md`, `RETROSPECTIVE.md` v2.10). Phase 184 sits at 52 inventoried plans, 27 of them evidence closure. Avoid a parallel gallery plus storybook (duplicate inventories, about 80 test-id dependencies).
- V: one declarative persona spec (`reference/persona_spec/personas.ex`, three tenants: high-count errors, one long-id non-ASCII record, zero data by absence) feeds seed, e2e and gallery, held by a drift test; about 40 scenarios in a manifest that drives both stories and axe selection. Matches C17.
- V: gaps: no flow-level stories; one industry only; monolithic LiveViews (2,710 lines) blocked screen stories until render functions were extracted (the problem D2 in the UI engine recommendations already addresses).

## exifcleaner (React; framework-independent lessons)

- V: about 200 stories; a closed list of 12 state classes (happy, empty, one, many, boundary, loading, error, denied, stale, long, intl, huge) with one primary class per scenario; a computed subject-by-class grid of 252 cells (93 covered, 159 waived with a reason and a `path#symbol` anchor, 0 gaps); every story must map to a scenario; planted-mutant stories prove each gate fails. Matches C22. New caution C34: "0 gaps" means every cell has a recorded disposition, not that tests ran; 159 hand-written waivers have a real authoring and review cost.
- V: cost control: a cap of 5 plans per phase gave 35 plans for v5.0 against 129 for v4.12; the Storybook CI job is path-filtered, advisory, 10 minute timeout, measured 340 s for 189 stories against a 470 s budget; visual regression is a separate advisory job capped at 40 baselines at two widths (580 and 960) because the maintainer asked for two widths, not five. C16, C25.
- V: fixtures fold the real reducer so only reachable states exist (C21); hostile text is stored as escaped code points, never raw (Trojan Source safety): a Hebrew name inside a Latin name, an RLO override, a 180-character name, a ZWJ emoji, a long German compound, long Japanese.
- V: the restyle needed 13 test-only prerequisite PRs before the palette PR; visual review at 580 px still found a filename truncation after green checks.
- I: does not translate: CSF args, `play` functions, addon-vitest, toolbar globals. Interaction proof goes in LiveViewTest or Playwright.

## fablebook (realistic-data source)

- V: only **six** fictional adopters exist (not a dozen), each a separate pinned GitHub repo cached at `.cache/brand_sources/<name>-brand/`, pinned in `brand_sources.lock.json:4-10`; each ships `records/<b>/<b>-records.json` (10 to 44 rows per collection), `brand.json`, `tokens.json` (DTCG subset) and a validator with a self-test. Table in C31.
- V: **reuse license is undecided**: logos, tokens and records have no stated terms and redistribution "is not granted" (mapping guide section 8); the cached repos have no LICENSE file; the names are uncleared and real products exist. Fonts are OFL 1.1. Plan: copy a small trimmed subset with provenance after the maintainer confirms terms; do not depend on the repos; do not ship logos in Hex or docs.
- V: lessons: `null`, never `""` or `0`, for missing values; never key a record on a display name (two brands reuse the case id `case-offline`; use brand plus sourceId); hand-drawn pictures drifted from the records, so the records are the data; scenarios are equivalence classes, not permutations (`OWNER-DNA.md:116`).
- V: Finanza's guide says outright that its numbers are not claimed realistic; the records are UI-state-sized, so "huge count" states need our own generators.

## Questions that remain for the maintainer's sessions

The ten-point prompt in [PASTE-PROMPTS](PASTE-PROMPTS.md) asks each project's own session for measured costs, regrets and what to skip. The scans' most useful unanswered questions: what accrue's catalog cost end to end against defects it caught that axe and route tests would not; which exifcleaner waivers were ever worth writing; whether mailglass would drop the gallery or the storybook; whether mdex/rustler ever broke an Apple-silicon or release-parity build; and the fablebook records license.
