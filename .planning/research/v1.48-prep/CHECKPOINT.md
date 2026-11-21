# v1.48 entry-point checkpoint (SIGNAL-01)

Recorded 2026-11-21, after Phase 193 merged (PR #163). Commands were read-only (`gh api repos/szTheory/scrypath/traffic/*`, `https://hex.pm/api/packages/scrypath`, `curl` on the live HexDocs pages). GitHub keeps only 14 days of traffic, so this note is the only copy of the 2026-11-07 to 2026-11-20 window.

## What was measured

| Signal | Value | Read it as |
|--------|-------|------------|
| GitHub views, 14 days | 7 views, 5 unique visitors (2026-11-07 to 2026-11-20) | Effectively nil. The maintainer's own visits are probably most of it. |
| GitHub referrers | one: `sztheory.github.io`, 1 view, 1 unique | One person reached the repo from the website. Nothing from search, hex.pm or HexDocs (GitHub cannot see hex.pm or HexDocs traffic). |
| GitHub popular paths | the repo root twice, a `v0.3.3` phoenix-walkthrough blob (2 views), and three PR pages | Nobody is reading the README or guides on GitHub. |
| GitHub clones, 14 days | 1,802 clones, 135 unique cloners; flat at 15 to 20 a day, then 290, 399 and 932 on 2026-11-18, 19 and 20 | Not adopters. The jump matches the days of three patch releases, many CI runs and agent work from this machine. Unusable as demand. |
| Stars, forks, watchers | 0, 0, 0 | No signal. |
| hex.pm downloads | 1,845 all time, 956 in the last 90 days (`recent`), 146 last 7 days, 63 yesterday; 20 releases, first published 2026-04-17 | Cannot separate people from CI runs, mirrors and the release bursts of the week (0.3.18, 0.3.19 and 0.3.20 shipped 2026-11-19 to 2026-11-21). The prep notes read 1,782 all time and 89 a week on 2026-11-20; most of the growth is release-week noise. |
| Issues and outside reports | 4 issues in all time (the maintainer's two planning issues and two bot "release parity drift" reports, one open and one closed); no pull request from a person other than the maintainer; no discussion board | No adopter report has ever arrived. |
| Live README behavior | `hexdocs.pm/scrypath/readme.html` redirects to `scrypath.hexdocs.pm/readme.html` (200) and shows the trimmed 0.3.20 README (Meilisearch prerequisite present, no "Choose a route" block) | Phase 192 is live. The Phase 193 regroup is not live until the next Hex release: the live `overview.html` still shows the old page (the "Crash Course" section and the 22-row table; checked with `curl -L`). |
| hex.pm README rendering | not checked (client-rendered; a fetch returns a placeholder) | Left unproven. |

## Decision

**Cut Phase 194.** Close v1.48 as a docs-truth and drift-guard milestone after Phase 193. Rule applied: SIGNAL-01 says that if traffic is effectively nil the default is to cut, and the numbers above are nil on every channel the maintainer can see (5 unique visitors in 14 days, 1 referrer, 0 stars, no outside report in seven months). Nothing here argues for a website rewrite, and the README and HexDocs now carry the journey.

Confidence 0.8. What would change it: a real adopter report or a referrer that sends repeat traffic to the website (then reopen 194, recorded as SITE-07 to SITE-09), or the maintainer wanting the website content for portfolio reasons (a taste call, not a data one).

## What happens to the cut requirements

SITE-07, SITE-08 and SITE-09 are not met and are not claimed. They move to the backlog with this note as the evidence. The website's own install line and its schema snippet therefore stay outside the parity guards, except that the install-line guard already reads `website/scripts/build.mjs`.

## v1.49 and what this does not tell us

The roadmap asked whether v1.49 is the catalog or adopter features if the milestone is cut. This checkpoint cannot decide that: the same "almost no traffic" reading argues against more polish and for features, but 0 outside users also means no feature has evidence behind it. The choice is made at the milestone boundary through the standing upstream preparation (one recommended option with its confidence), not here.

Not proven by this note: who the 1 dependant on hex.pm is, how many downloads are people, and whether the Hex package page renders the README well.
