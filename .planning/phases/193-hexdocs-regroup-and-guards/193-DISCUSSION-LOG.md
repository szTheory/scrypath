# Phase 193: HexDocs regroup and guards - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-11-21
**Phase:** 193-hexdocs-regroup-and-guards
**Areas discussed:** Sidebar grouping, overview.md fate, link check, install line, duplicated blocks and banned wording, shipping

Run unattended under the standing maintainer instruction (AGENTS.md, "Phase workflow defaults"): decide from the requirement text, the v1.48 prep notes and the code, and ask only when scope, authority, risk or cost changes. No choice here changes any of those, so no question was asked.

---

## guides/overview.md fate

| Option | Description | Selected |
|--------|-------------|----------|
| Shrink and keep in extras | Half-page reading order plus example links; URL and every inbound link stay live | ✓ |
| Drop from extras | Sidebar is the index; ends `overview.html` in future versions; README, moduledoc, owner map and 11 assertions need rework | |

**Choice:** shrink. Dropping is the harder-to-reverse option and buys nothing the shrink does not.

## Link check

| Option | Description | Selected |
|--------|-------------|----------|
| Extend the TRUTH-03 scan | Reuses the one docs build; no new gate | ✓ |
| New mix task or test with its own docs build | Second docs build, possibly a new gate | |

## Banned wording source

| Option | Description | Selected |
|--------|-------------|----------|
| Copy a small table from brand, glossary and copy_rules.json | No cross-project dependency | ✓ |
| Read copy_rules.json across projects | Couples the root suite to `scrypath_ops/` | |

## Decided autonomously

[auto] [Sidebar] — Q: "Where does ARCHITECTURE.md go?" → Selected: "Operate and recover" (reversible technical — decided autonomously: one-line edit to undo)
[auto] [Sidebar] — Q: "Keep Phoenix as its own group?" → Selected: "Yes" (reversible technical — decided autonomously: one edit in mix.exs)
[auto] [Sidebar] — Q: "Which fifth item fills the first group?" → Selected: "meilisearch-concepts" (reversible technical — decided autonomously: one edit and one test line)
[auto] [Link check] — Q: "New test file or extend the TRUTH-03 scan?" → Selected: "Extend the scan" (reversible technical — decided autonomously: moving a test is cheap)
[auto] [Guards] — Q: "Where does the scanner code live?" → Selected: "test/support/release/" (reversible technical — decided autonomously: test-only code)
[auto] [Guards] — Q: "Forbidden-phrase table format?" → Selected: "small data file read by one test" (reversible technical — decided autonomously: test-only, edit in place)
[auto] [Install line] — Q: "Exact version or series?" → Selected: "series prefix plus satisfies check" (reversible technical — decided autonomously: a test assertion only)

## Claude's Discretion

Exact wording of the shrunk overview, the CONTRIBUTING rule and the banned-phrase list; test and module names.

## Deferred Ideas

Website install line and snippet parity (Phase 194); guide merges or renames; the Hex release.
