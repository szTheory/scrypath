# Discovery and onboarding journey (maintainer intent, 2026-11-20)

Status: **standing direction, not yet a plan.** The maintainer asked that this intent be woven into every milestone and phase that touches the README, the website, HexDocs, the guides or onboarding, and followed through. Read this before changing any of those surfaces. Numbers and surface roles below marked HYPOTHESIS are starting points for a discuss step, not decisions.

## The intent, in the maintainer's terms

- The README, the website and HexDocs overlap too much and the README is too long. Link lists everywhere ("Choose a route" in the README is seven bullets of four or five links each) make readers' eyes glaze over, which defeats the purpose of routing them.
- People meet Scrypath in different places. The maintainer's guess (not measured): most land on GitHub and read the README, then maybe click through to the website; some hit the website first; a lot find it through HexDocs.
- There must be one coherent journey for three groups, every angle considered:
  1. **First encounter:** someone finding out about Scrypath for the first time (what is it, is it for me, can I trust it).
  2. **Starting to use it:** someone adopting it (the onboarding of the library itself is a product surface: install, first working search, sync mode, verifying it works).
  3. **Coming back:** someone troubleshooting an issue, looking something up, or digging deeper into how to use it in particular ways.
- Decide what is most important for each, give each surface one job, and avoid duplicating content across surfaces.
- The website also has to help earn GitHub stars and work as a portfolio piece (see SEED-004).

## Entry points (unmeasured; the maintainer's estimate)

| Entry | Who arrives | First question |
|-------|-------------|----------------|
| GitHub repo and README | Most newcomers (maintainer's estimate) | What is this, is it for me, how do I start |
| hex.pm package page | People searching Hex; shows the README | Same as README; also the version and docs link |
| HexDocs | Many first-timers and most returning users | How do I do X; what does this function do |
| Website | Some newcomers, link shares, portfolio viewers | What is Scrypath, should I trust it |
| Search engines, Elixir Forum, newsletters, blog posts | Mixed | Lands on any of the above |

Nothing is measured. GitHub traffic insights, hex.pm download counts and HexDocs analytics could confirm the estimate without adding tracking to the site; treat any claim about proportions as a guess until then.

## Journey stages and the job at each

| Stage | Reader state | What they need within the first minute | What must not happen |
|-------|--------------|----------------------------------------|----------------------|
| First encounter | Cold, skeptical, short on time | One plain sentence on what Scrypath is and is not; who it fits and who it does not; proof it works; honest limits; the one next click | A wall of links, vague claims, vanity metrics, repeated text |
| Starting to use | Committed, wants a working result | Install line; one schema; first indexed and searchable record; which sync mode and why; how to verify it | Being sent through six guides before seeing it work; repo-only commands in adopter instructions |
| Coming back | Stuck or digging deeper | Task-based how-tos and reference by name; troubleshooting and recovery; operations; what changed between versions | Having to re-read the landing material; search that finds the marketing page instead of the answer |

## HYPOTHESIS: one job per surface

| Surface | Proposed single job | Not its job |
|---------|---------------------|-------------|
| README (GitHub and hex.pm) | First encounter and a fast start: what it is, fit and non-fit, install, quick path, three links onward | Restating guides; operations detail; every guide index |
| Website | First encounter with proof and trust: what it is, see it working, honest limits, comparison, star ask, portfolio quality | Reference docs; a second copy of the README |
| HexDocs | Canonical docs: guides by task, API reference, operations and recovery, changelog; the home of returning users | Marketing |
| Guides | Task-based how-tos and explanations, one owner per claim | Duplicating the README |
| ScrypathOps docs | Operator UI usage | Library onboarding |

Rule to settle in discuss: one owner per claim; other surfaces link or quote it once and never restate. The repo already has contract tests that pin README and website sentences (`docs_contract_test`, `readiness_contract_test`, `phase98/99/110/112`, `backfill_contract_docs_test`, `telemetry_contract_test`); a restructure changes those tests in the same commit and never drops a contract-pinned claim silently.

## Constraints to respect

- Honesty (AGENTS.md, PROJECT.md): no overclaiming, Meilisearch-first, eventual consistency explicit; adopter instructions never name repo-only tasks (the website and two guides currently name `mix verify.adopter`, which is not in the Hex package).
- Brand voice, the glossary and the GOV.UK-style copy rules recorded for the operator UI (`research/ui-quality-engine/RESEARCH-PERSONAS-FIXTURES-COPY.md`), applied with the `ux-writing` skill; design with the Impeccable skill.
- The README ships in the Hex package and shows on hex.pm only after a release (a release is the maintainer's yes). HexDocs structure lives in `mix.exs` (`main: "readme"`, `extras`, `groups_for_extras`).
- Upkeep is permanent: version, install line and snippets come from code CI runs; guards keep copy and claims from drifting.

## Where this is woven

- `seeds/SEED-004-website-refresh.md` (the website refresh; widened to the whole journey)
- `todos/pending/2026-11-20-trim-readme-and-choose-a-route.md` (README trim)
- `reference/ROLLING-ROADMAP.md` ("Discovery and onboarding journey" proposal)
- `PROJECT.md` ("Discovery and onboarding direction")
- Memory: website-refresh-and-upkeep
- v1.47 Phase 189 stays identity-only plus the SITE-06 accuracy fix and must not add link sprawl; it does not decide surface roles.

## Open questions only the maintainer can answer

- Sequence: one "Discovery and onboarding" milestone covering README, website, HexDocs and the guide structure together (recommended), or separate small pieces?
- Is the README-first journey right, or should hex.pm and HexDocs lead because of how Elixir developers search?
- How many guides are too many (26 today)? Merge, prune, or restructure the HexDocs sidebar?
- Does the website keep a Docs page at all, or hand off to HexDocs?
- Where do we get real signal on entry points (traffic insights, download counts, a "how did you find us" in an issue template) without adding analytics?
