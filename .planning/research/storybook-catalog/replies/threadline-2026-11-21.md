# Reply from the threadline session (2026-11-21)

**Provenance.** Pasted by the maintainer from the threadline project's own LLM session (answer to prompt 2). Labels in the source: IMPLEMENTED/VERIFIED (present in the repo and checked), VERIFIED (a checked finding), PROPOSED (advice). Digest, not re-verified by the Scrypath session. Its file:line references are to `~/projects/threadline`.

## Corrections to the Scrypath scan

- **The catalog is mid-migration, not "mature" or finished.** Fifty-eight nested PhoenixStorybook files: older Primitives, Patterns, Groups and Operations sit beside the newer focused Components folders. Phase 260 separates individual production components and named variations; Phase 261 still owns groups, screens/areas, workflows and whole-catalog reconciliation. Do not read today's tree as a finished five-level catalog (`storybook/index.exs:8-17`, `storybook/components/index.exs:9-14`, `260-03-SUMMARY.md:134-136`, `AGENTS.md:188-200`). This corrects `SIBLING-SCAN-2026-11-21.md`.
- Phase 260's nine plans: 01 Actions; 02 Display; 03 exact-value Display and Foundations; 04 Page; 05 Forms; 06 Switch/Combobox and Data; 07 Empty/Error/Loading and semantic states; 08 fallback, Toast and Reconnect; 09 overlays and reconciliation. Only plans 01 to 05 have summaries; 06 to 09 are plans.

## What the browser and contract suites found

- Worth keeping from the 4,588-line Playwright spec and 1,804-line ExUnit contract: exact production-renderer ownership, variation anchors, rendered semantics and responsive checks. Real defects the browser work found: zero-sized Spinner and Avatar, a broken Avatar data URI, a literal `false` in `aria-describedby`, missing disabled-Radio semantics and duplicate ids. No long-string-specific defect was recorded; long-content and narrow-width checks are guards.
- **Fixed demo time exposed a real seed bug**: retention used a wall-clock cutoff and deleted the #4521 fiction after the demo epoch aged past policy; an explicit epoch-based cutoff fixed it (`.planning/audits/198-round4-demo-seed.md:56-66`). No impossible fixture was recorded, but Phase 249 found descriptions claiming more than their linked proof established.
- Static stories render; they do not prove mounted routing, authorization, database reads or mutation. PhoenixStorybook **1.2.0** `:example` stories are child LiveViews that cannot implement `handle_params/3` (`deps/phoenix_storybook/lib/phoenix_storybook/stories/story.ex:93-102`); mounted Playwright tests own those behaviors. The one CSS-boundary issue found was Storybook notes inside `.threadline-ui` (fixed in Phase 259). The root package boundary test has never caught a leak. mdex/rustler appear in the lockfile with no recorded trouble. **The session would not upgrade to 1.5 without a concrete need.**

## The coherent journey and an alignment gap

The ordinary journey is Acme ticket #4521: the mounted path signs in as an admin, follows correlation `walk-acme-4521-close` from Home through Timeline to the transaction and row history (a `ticket_replies` insert and `tickets` update; the internal note redacted); event time fixed, action-recording time distinct (`DEMO-MANIFEST.md:60-73`, `operator-earned-flows.spec.ts:527-590`). Gap: the static transaction story describes a support investigator while the mounted journey uses the admin and the event actor is the Acme closer. Keep viewer and event actor distinct and align story audience and provenance with the chosen journey before claiming one user end to end. The real denial is scoped Acme support seeing Timeline but getting HTTP 403 on export; useful edge states are the redacted note and a future-date filter with no matches.

## Other lessons

- The design-system ledger still generates `DESIGN-SYSTEM.md`, but its scores are historical inventory, not acceptance. The parity test compares System mode to light, a known coverage gap rather than a product mismatch. Brand guidance rejects compliance or certification claims; its fictional help-desk example shows operator tasks without implying regulated-domain support.
- **The paid LLM critic** taught more than the cache-key bug: it could confidently invent page details, compress score scales, and cost more than its measured value. Retired; deterministic checks and mounted journeys are firmer evidence (`RETROSPECTIVE.md:1101-1118`).

## Advice for Scrypath (PROPOSED by the threadline session)

- **Build first:** (1) focused stories bound to real `UI.*` renderers; (2) one realistic sync/index-drift pattern with ordinary, empty, stale and error states; (3) one mounted investigation journey carrying the same operator, index, run and timeline through the real screens, including a denial.
- **Borrow:** direct renderer ownership and deterministic linked examples.
- **Refuse:** copied components, a second drifting coverage registry, a paid critic.
- **Simplify:** one source contract plus focused browser checks, with Playwright reserved for mounted behavior.
