# Prep F: review loop, catalog information architecture and UX (2026-11-21)

Read-only research for v1.49 "Catalog foundation". Tags: V = I read or ran it, J = judgment, U = unverified. PSB = phoenix_storybook, read from the 1.5.0 Hex tarball in a scratch directory (nothing in the repo touched except this note).

## Facts that shape the answers

- V: PSB URLs are `<mount>/<path under content_path>` with `?theme=` and `?tab=` params; a variation anchor is `#<id with _ turned into ->` (`lib/phoenix_storybook/live/story/variations.ex:199`, `story_live.ex:169,201`). A single variation can also be selected with `?variation_id=` (`story_live.ex:154`). Bare iframe pages live at `<mount>/iframe/*story` (`router.ex:94`) and visual-test pages at `<mount>/visual_tests/<story>` (`guides/testing.md`).
- V: the sidebar search matches only story `path` and `name` (`live/search.ex:32`), not variation titles or notes. So anything a reviewer should find by typing must be in a file or folder name.
- V: a variation's `description` is its visible title, `note` is Markdown shown below it (`guides/components.md:312`). The generated `welcome.story.exs` is a `:page` story with `navigation/0` tabs, which is the landing-page mechanism. Folder order and labels come from `index.exs` (`folder_name`, `folder_index`; `entries.ex:103-106`).
- V: `themes_strategies` exists in 1.5.0 (`guides/theming.md:20`); the hexdocs config page omits it, so ADR 0001 is fine. `live_storybook` must be mounted in a scope at `/` (`router.ex` docs) and cannot be linked with `patch`/`navigate`, only `href`.
- V: PSB's own shell HTML has almost no aria/role attributes (one `role="switch"` in `lib`; coarse grep, so the shell's accessibility is upstream's and unaudited by us). Shell theming (`theme_path`) arrived in 1.4.0.
- V: the owner's design bar is `OWNER-INTENT.md` and rubric D7 (`RECOMMENDATIONS.md`): machine floors, taste to the maintainer, "never an open-ended UAT round".
- V: the ops UI's documented host contract lets a host override only the accent through `--color-primary` and says "contrast is yours once you override" (`scrypath_ops/README.md:94-133`). That is the one real adopter-theming surface.
- V: **naming conflict.** The glossary and the 2026-10-25 grilling fix the levels as Primitive / Pattern / Area / Surface / Job (`GLOSSARY.md`, `RECOMMENDATIONS.md` "Language"). `MILESTONE-CONTEXT.md` and the playbook say Screen / Flow. The glossary is the recorded owner decision.

## F1. Catalog information architecture

**Recommendation (0.8):** use the glossary's level names as folders, ordered review-first (largest unit first), and keep jobs-first at the top without a second inventory.

```
Start here            welcome.story.exs (page)
Jobs                  one story per JOB: ordered journey variations (the review entry point)
Surfaces              Control room, Search health, Failed sync work, Sync and index, Search, Help
Areas / Patterns / Primitives
Hosting               one story: host accent override
```

- Job story labels are verb-object phrases built from glossary nouns ("Recover failed sync work"); the id lives in the file path (`jobs/job_03_recover_failed_sync.story.exs`) because search reads paths (V above), so typing "job-03" or "failed" finds it. Surface labels are the glossary surface names exactly. No ids in sidebar labels.
- A Job story is an ordered walk across the same production renderers (health shows the problem, pick the failed item, retry accepted, the denied actor), each step a variation. Surface stories own the state coverage per screen. Both are thin shims over the same renderers and the same fixture builders, so there is one inventory of renderers and two views of it (J). The pilot builds one Job (JOB-03) and the Failed sync work and Search health surfaces only.
- **Adopter is a variation dimension, not a folder.** Folders per adopter make adopters x surfaces files and put the same renderer in many places. Variation id and title follow one pattern: id `clinicly_denied_read`, title "Clinicly - Denied - cannot read failed work". Neutral states (ordinary, empty, stale, error) use the adopter whose shape fits; an adopter-specific variation exists only where that adopter is the reason for the state (the brandbook "one unique state each" rule). Split a story by state, never by adopter, if it passes about 12 variations.
- **Finding "the Clinicly denied failed-sync story" in under 10 seconds:** three routes, none needs search to be perfect. (a) The review packet's deep link `/storybook/jobs/job_03_recover_failed_sync#clinicly-denied-read` (zero clicks). (b) "Start here" has a short hand-written table of the seven adopters' unique states with links, checked by a test that every `/storybook/...#anchor` link resolves (about 20 lines, cheap; link rot is the failure of a hand table). (c) Sidebar search by surface or job name, then Ctrl-F "Clinicly" in the one scrolling page.
- **Stable URLs:** the file path is the id; variation ids are never renamed after a review has cited them. A rename is a deliberate edit that fixes the cited note by grep. Feedback rows quote the path, anchor, and the commit shown on the landing page.

Rejected: jobs-only tree (hides the surface-state coverage the maintainer asked for in F3), adopter folders (above), ids in labels (noise), a generated "find a story" index (a second registry).

## F2. Review loop mechanics

- **One stable URL.** The storybook is DB-free (D5), so unlike the Docker preview there is no data to preserve; what must persist is the URL and port. Add a `storybook` block to `UI-PREVIEW.json` (url, fixed loopback port, checkout, branch, base_main). The ecommerce preview at 4002 stays the mounted-behavior surface until the mounted journey exists and is refreshed only when the milestone changed mounted behavior; AGENTS.md already demotes it once the first screen story ships.
- **Refresh = fetch, fast-forward the serving checkout to `origin/main`, restart on the same port, verify.** Verification is executable: the landing page prints `main@<short sha>` and the fixtures clock, and the preflight (extend `npm run ui:preflight` or a 30-line sibling) fails unless the URL answers 200 and the printed sha equals fetched `origin/main`. A stale storybook that looks current is the worst failure of this loop (accrue's stale-CSS finding, `sigra` reply).
- **Feedback note** (one file per review, `research/storybook-catalog/REVIEW-<date>-<milestone>.md`, packet on top, rows below, same table shape as `FEEDBACK-SESSION-2026-11-21.md`): columns `#`, verbatim quote, entry (`path#anchor`, only if known), adopter and state, viewport, theme, kind (product / data / catalog), triage, disposition. Unknown stays the literal word "unknown" (viewport is not in any PSB URL, so it is usually unknown unless stated). Quotes are never paraphrased in the quote column.
- **Triage:** fix now (a shipped claim is wrong or the job cannot be done; small PR or a decimal phase before the next phase starts), next milestone (appended to the `MILESTONE-CONTEXT.md` fold-in section, the existing pattern), later (ROLLING-ROADMAP with a revisit trigger). "Looked at it, keep as is" is a disposition, not a fourth bucket. `data` rows ("this error text is not real") route to the fixtures owner as contrived-data defects.
- **No capture ledger.** A row repeating across two reviews becomes an executable rule (a `copy_rules.json` row, token test, or render-all assertion); otherwise nothing is promoted (the L5 idea without the file).
- Put the procedure (packet checklist, row format, triage) in one short `.planning/reference/CATALOG-REVIEW-LOOP.md` that AGENTS.md links, so an unattended agent reads it (J).

## F3. Milestone-end review in autonomous mode

Agent steps before pausing, in order: (1) confirm all milestone PRs are merged and `main` is green; (2) refresh the storybook per F2 and run the preflight; (3) run the render-all tests on `main` (this is the "nothing broke" evidence, and the only evidence needed for a no-UI milestone); (4) compute what UI changed: `git diff --stat <last-review-sha>..origin/main -- scrypath_ops/lib scrypath_ops/assets scrypath_ops/storybook fixtures`, map changed renderer modules to the stories that render them (a grep, not a tool); (5) write the packet and stop. It does not run audit, complete or cleanup until the feedback is recorded; silence is not approval.

The packet (first message the maintainer reads) is five lines: URL and `main@sha`; "UI changed: ..." or "No UI changed (empty diff over the paths above)"; three to five deep links, each with the one question it answers ("Can the on-call engineer tell which record failed and what to do next?", per accrue's "can support find the October payment" lesson); the standing 60-second tour (the pilot Job in ordinary state, the same job's denial, the narrowest-width link); and "reply 'ok' or give rows; ok is recorded as the answer". A no-UI milestone reuses the standing tour, so the review costs the maintainer one word.

**One extra pause (recommend, needs a maintainer yes):** a review after Phase 197 and before 198. The roadmap already has a cut line there ("if the pilot disappoints"), and sigra's top advice is to put one job in front of the owner before expanding. Cost: a packet, no new code. Evidence against: if the maintainer says they will review only at milestone end, drop it.

## F4. The design bar made checkable

| Bar item | Executable (blocking in existing `ops-ui` ExUnit unless noted) | Owner taste (recorded, never a gate) |
|---|---|---|
| Light, dark, System | Token contrast gate already exists (`contrast-checker.mjs`); render-all renders each story under `data-theme` light and dark. System: Playwright `colorScheme` emulation on about six pages, advisory first | "Not tacky", palette feel |
| Typography | Heading order and one h1 per iframe page (axe rules, advisory lane); font family and size from tokens (existing contracts) | "Intentional, professional" |
| Hierarchy, no redundancy | Not mechanically decidable; a duplicate-text detector stays advisory (D7 row 4) | Whether it reads elegantly |
| Two widths, mobile-first | At 375 and 1280, about 20 pages (Job and Surface ordinary plus denied, two themes): no horizontal overflow, primary action inside the first two viewport heights, meaningful region visible (accrue footgun 4). Advisory until the numbers justify a gate (C32, C33) | Whether the narrow layout feels designed |
| Vocabulary and copy | Run every `copy_rules.json` forbidden row and the glossary `_Avoid_` terms over every story render (the existing rows only run on registered surfaces, so this widens coverage without weakening any row) | Voice |
| Persona and job tags | F6 | Whether personas are the right ones |

Anything else goes into the packet as a question, not a check.

## F5. Accessibility

- Stories: axe (WCAG 2.2 AA tags) on the iframe pages above, light and dark, serious and critical block once the lane is promoted; render-all asserts unique ids within each variation's HTML (threadline's co-rendered duplicate ids and bad `aria-describedby` were real defects); reduced motion via emulation, advisory.
- Keyboard and focus are not claimed by static stories (C7); they belong to mounted tests, and the proof label says so.
- The PSB shell: do not gate, audit or restyle it; state on "Start here" that the shell is upstream's and the catalog tests the stories, not the shell. Keep it native and unbranded (accrue reversed branding it, C32), which also keeps "shell chrome" visibly different from "Scrypath chrome". Footgun: PSB's own color mode and the story theme dropdown are separate controls; configure the theme dropdown as Light / Dark only and say so in the legend. System cannot be toggled inside the sandbox (V: ops System dark keys off `html:not([data-theme=light])` plus the OS media query); say "System follows your OS" and test it with emulation.

## F6. Persona and job tags

Every variation from Area upward starts its `note` with one situation line: `Adopter: Clinicly (fictional) · Persona: On-call (ROLE-OPS) · Job: JOB-03 · Proof: render only`. Primitives and Patterns cite the renderer instead. Render-all parses it with one regex and checks that `ROLE-*` and `JOB-*` exist in the table in `OPERATOR-UI-QUALITY.md`, the adopter is in the fixtures module's own list, and a `Mounted` proof label names a test file that exists. No registry, no manifest (J). Keep the line outside the adopter-themed wrapper (threadline). The glossary's persona handles (Solo Dev, On-call, Platform SRE, Search Owner) apply; its example adopter twins (Langalern, Budgetly, Shoply) are out of date against the six brandbook adopters and should be updated by the fixtures phase.

## F7. Realistic adopters without confusing the chrome

- Scrypath chrome is always Scrypath: no adopter fonts are loaded, no logos (reuse grant is open), so the Bricolage/Hanken overlap and Finanza's Space Grotesk problem both disappear. Adopters show up as data (schema names, documents, tenants, counts).
- Theme per adopter in exactly one place: the Hosting story, which shows the documented `--color-primary` override for three or four adopters plus one deliberately failing-contrast host color labeled "contrast is yours" (Shopadelic's Etoile theme in the brandbook). Executable: an ExUnit check that the wrapper may set only an allowlisted set of `--color-primary*` variables, so adopter color cannot leak into surfaces, sidebar or header.
- Every adopter is labeled "fictional" in the situation line and once on "Start here".

## F8. First 60 seconds

"Start here" (page story, first in the tree): (1) one paragraph, "Screens from ScrypathOps drawn by the same code as the real app, using made-up data from fictional adopters. Use it to check what an operator sees and whether the next step is clear."; (2) "What this is not": static renders, buttons do nothing, nothing reaches a search backend, permissions are shown not enforced, time is frozen at the fixtures clock (print it); (3) the proof legend, two labels only: **Render only** (real component, fixed data, no behavior) and **Mounted** (the same state is also exercised end to end; the story names the test); (4) the adopter link table; (5) the build line `main@sha`; (6) known limits (shell is upstream's, System follows your OS).

## Adversarial pass

- Two views (Jobs and Surfaces) may drift or double the work. Test: after the pilot, count review rows citing Surfaces versus Jobs; if the maintainer only ever opens one, delete the other. Early warning: Surface stories with markup not shared with the Job variations.
- Adopter-as-variation may bury states. Test in the Phase 196 spike: a scripted find ("Clinicly denied failed sync") reaches the variation in at most three interactions from a cold load; if not, split by state into files.
- Hand-written link table rots: the link test covers it. Proof labels may overclaim: the named-test check covers it.
- "Executable checks" can still miss incoherent screens (accrue shipped a green, incoherent catalog, C32). That is why review packets ask a job question per link and why taste stays with the maintainer.
- Unverified: whether PSB's Ctrl-K search is fuzzy, and whether the shell is keyboard-complete; the spike should time and walk both.

## Plan and ordering implications

No new phase. Phase 195 supplies adopter ids and the fixed clock. Phase 196 (spike) adds the tree skeleton (five `index.exs` files), "Start here", the sha line, the link test and the scripted find test (1 plan of the spike's budget). Phase 197 builds the first Job and surfaces and ends with review packet number one; Phase 198 scales and ends with the milestone-end packet. About 2 of the 20 plans go to the loop. No new CI gate; all tests are untagged ExUnit in `ops-ui` (gate budget stays 10 of 12), and the browser checks stay in the path-filtered advisory lane.

## For other areas

- Fixtures: closed adopter list that the persona-tag test reads; a fixed clock printed on "Start here"; update the glossary's twin examples.
- CI and Docker: a fixed storybook port and a `storybook` block in `UI-PREVIEW.json`; preflight compares the printed sha with `origin/main`.
- Spike: confirm `live_storybook` mounts in the dev router scope, the `/iframe/*` and `visual_tests` URLs work for Playwright, and run the timed-find test.
- Docs: fix `MILESTONE-CONTEXT.md` level names to the glossary (Surface, Job) or record the override.
