---
created: 2026-11-20T15:30:00Z
title: Trim the README (choose-a-route section and overall length)
area: docs
files:
  - README.md
  - test/scrypath/docs_contract_test.exs
  - test/scrypath/phase110_contract_test.exs
  - test/scrypath/phase112_contract_test.exs
audit_acknowledged:
  milestone: v1.47
  at: 2026-11-20
---

## Problem

The maintainer (2026-11-20): the GitHub README still reads like AI slop. It is overly long (221 lines, about 1,480 words, 15 sections), especially the "Choose a route" section, which makes readers' eyes glaze over, the opposite of its purpose (routing a reader quickly).

## Solution

Treat it as a goal-first edit, not a polish pass: the README's job is to say what Scrypath is and is not, show the install and the quick path, and route to HexDocs and the guides. Everything else (sync modes, backfill and reindex, drift detection, integration smoke, architecture) probably belongs in HexDocs and guides, linked, not restated (single-source rule from SEED-004). Reduce "Choose a route" to a few plainly worded links. Use the `ux-writing` skill and the brand voice, and the glossary. Check which sentences the contract tests pin (`docs_contract_test`, `readiness_contract_test`, `phase98/99/110/112`, `backfill_contract_docs_test`, `telemetry_contract_test` read README.md) and change those in the same commit; do not drop a contract-pinned claim silently. The README header was re-skinned in v1.46 Phase 188 and uses commit-pinned raw URLs for hex.pm; keep that.

Intent and journey: `.planning/reference/DISCOVERY-AND-ONBOARDING-JOURNEY.md` (read first; the README's job is first encounter and a fast start, not a guide index). Relationship: pair with the website refresh (SEED-004) so the README, HexDocs and site split their jobs once. Needs the maintainer's call on scope: a README-only trim could ship on its own as a small `docs` PR at any time (it changes Hex package content, so it shows on hex.pm only after a release, which stays the maintainer's yes).
