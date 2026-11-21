# UI feedback session after v1.46 and v1.47 (2026-11-21)

Context: the milestone-end review that AGENTS.md requires, run before opening the next milestone. Recorded verbatim in substance, triaged as **fix now**, **next milestone** or **later**. Milestone input is folded into [MILESTONE-CONTEXT](../../MILESTONE-CONTEXT.md). Status as of this note: the maintainer has given direction on the catalog; feedback on individual screens has not arrived yet and is appended below as it comes.

## Preview state

The retained preview was refreshed from the Phase 187 commit to main (9b6ec911): the preview checkout `ui/next` now matches `origin/main`; the old head is kept as branch `backup/ui-next-3bc565c3`. Only the web service was recreated with the seed-disabled override: 19 products, 3 tenants, 3 saved searches and 3 migrations were intact afterwards, and `my-search.json` kept its hash (3c8de6b4...). The ops CSS watcher had failed because the `scrypath_ops` deps volume was behind the lockfile; `mix deps.get` in that volume fixed it. `npm run ui:preflight` passes (source match, main included, remote main current). URL: http://127.0.0.1:4002 (ops UI at `/admin/search`).

## Feedback log

| # | Feedback (maintainer, 2026-11-21) | Triage | Disposition |
|---|---|---|---|
| F1 | "Do we have a storybook I can view? I'm more interested in that than a demo app right now." There is none. The closest thing is the e2e fixture page `/admin/search/ui-fixtures`. | **next milestone (lead)** | The catalog becomes the lead of the next milestone. ADR 0001 (2026-10) had adopted phoenix_storybook; v1.49 prep note A deferred it anyway. |
| F2 | "That's a huge miss, we want to get a storybook going." The maintainer's 2026-10-25 decision (UI engine D1) was overridden by a prep note's own judgment. | **fix now** | Recorded as a standing correction in AGENTS.md ("Recorded owner decisions") and in memory. Prep notes must not defer a recorded owner decision without asking. |
| F3 | Catalog the way the sibling libraries do: individual components, control groups, screen areas, screens and user flows, with happy paths, errors and boundary conditions. | **next milestone** | Tier ladder and state vocabulary: playbook C1, C22, C31 to C34; shape in MILESTONE-CONTEXT. |
| F4 | Use realistic data from realistic adopters in different industries, not contrived test data; it exposes blind spots and makes the maintainer's feedback more on point. | **next milestone** | Fixtures phase builds on ADR 0002 and the fablebook twins (playbook C31). License question open (below). |
| F5 | Scan accrue, threadline, mailglass, scrypath, exifcleaner (and fablebook) for lessons; use GPT-6 Luna subagents. | **fix now (done)** | [SIBLING-SCAN-2026-11-21](SIBLING-SCAN-2026-11-21.md). Luna is not available in this session's agent tool; Sonnet was used and the scans are read-only and unverified. |
| F6 | Give paste-in prompts for each sibling session and for the brandbook session. | **fix now (done)** | [PASTE-PROMPTS](PASTE-PROMPTS.md). Replies go in `replies/`. |
| F7 | Record all high-signal discoveries in the `.planning` second brain with provenance, discoverably. | **fix now (done)** | Playbook C31 to C34 and change log; `reference/README.md` and `research/storybook-catalog/` indexed; superseded notes carry a pointer. |
| F8 | The milestone-end review must be the storybook once it exists (and be offered even before digging into a milestone). | **fix now** | AGENTS.md "Milestone-end review" updated: the catalog replaces the preview as the review surface once its first screen story ships; until then the preview. |
| F9 | Screen-level feedback on the ops UI and storefront from v1.46 and v1.47. | **pending** | Not yet received. Append rows here; triage each one. Where possible map each row to the catalog entry id, state, viewport and theme (accrue practice, playbook C32). |

## Replies received (2026-11-21)

Brandbook, fablebook, threadline and accrue replied (`replies/`); mailglass and exifcleaner are outstanding. Outcome: all four converge on starting thin (scenario facts plus stories bound to real renderers plus one mounted journey; no coverage manifest, baselines or full matrix at first). The fablebook and brandbook replies disagree on reuse rights; recorded as contested (playbook C31). Corrections to earlier notes: threadline is mid-migration, fablebook collections are not all small. Milestone shape revised accordingly in `MILESTONE-CONTEXT.md`.

## Open questions for the maintainer

1. **Reuse grant for the six brand repos.** No LICENSE exists; the brandbook session reports a general-reuse statement, the fablebook session finds only a narrow Logistify authorization. You own the repos. Recommendation: add CC BY 4.0 for records, text and token data (images, fonts and marks separate). Until then the fixtures phase authors its own data in the adopters' shapes and copies nothing, so nothing is blocked.
2. **Sequence.** Catalog first, with the small readiness PR separately, and "Adopter-ready" moved to v1.50 (recommended, see MILESTONE-CONTEXT), or keep Adopter-ready first.
3. **Two missing adopters.** Commission a help-center SaaS and an industrial parts distributor from the brandbook session (optional; does not block the fixtures phase).
