# Phase 192: Docs truth and README - Discussion Log

> Audit trail for humans. No downstream agent reads this file.

**Date:** 2026-11-20
**Mode:** autonomous (smart discuss), decisions taken from the milestone requirements and the v1.48 prep notes (A to D, including the adversarial pass), per the AGENTS.md phase workflow default (synthesize one recommended set and follow it unless a choice changes scope, authority, risk or cost).

## Why nothing was asked

Every hard-to-reverse choice (replacing the `verify.adopter` pins, the contract wording, removing README sections, the word cap) is already fixed by TRUTH-01 to README-03 in REQUIREMENTS.md and by the maintainer-approved milestone opening. No choice here changes scope, authority, risk or cost: the Hex release and any website claim stay outside this phase and keep their explicit-yes gate.

## Decisions and their sources

| Decision | Source |
|---|---|
| Invariant derives repo-only tasks from `dev/mix/tasks/`, allowlist, planted cases | REQUIREMENTS TRUTH-01 |
| Inventory every pin before changing any | REQUIREMENTS TRUTH-01; prep D risk 3 (contract churn done to green) |
| `PROJECT.md` contract text changes in the same commit | REQUIREMENTS TRUTH-02; prep D section 2 (A, contract risk) |
| Built-docs self-link and unresolved-extras scan | REQUIREMENTS TRUTH-03; prep D fact 2 |
| README one job, word cap, at most three onward links, no route block | REQUIREMENTS README-01 |
| Quick path ends in `Scrypath.search/3`; prerequisite and eventual consistency first | REQUIREMENTS README-02 |
| Owner map note | REQUIREMENTS README-03 |
| Absolute HexDocs guide links | prep A section 1 (Oban, Ecto, Ash READMEs) |

## Decided autonomously

[auto] [Invariant] — Q: "Where does the repo-only task list come from?" → Selected: "derived from dev/mix/tasks/ minus lib/mix/tasks/" (reversible technical — decided autonomously: it recomputes on every run)
[auto] [Invariant] — Q: "Which files are scanned?" → Selected: "every path in package.files" (reversible technical — decided autonomously: one data source shared with package_contents_test)
[auto] [Invariant] — Q: "Where do the planted cases live?" → Selected: "inline strings in the test" (reversible technical — decided autonomously: no shipped file is edited)
[auto] [README] — Q: "Where do the README tests live?" → Selected: "one small test file, no network" (reversible technical — decided autonomously: a plain file read)
[auto] [README] — Q: "Link style for guides" → Selected: "absolute HexDocs URLs" (reversible technical — decided autonomously: one find-and-replace to change)
[auto] [Scan] — Q: "Docs scan placement" → Selected: "sibling of package_metadata_test" (reversible technical — decided autonomously: test layout only)
[auto] [Owner map] — Q: "Note location and name" → Selected: ".planning/reference/CLAIM-OWNER-MAP.md" (reversible technical — decided autonomously: a planning note)
