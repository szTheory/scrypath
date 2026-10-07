# Phase 174 source coverage audit

This is a plan-time coverage map, not implementation or verification evidence. The approved `174-UI-SPEC.md` supplies concrete acceptance for all 30 UI considerations. The spec-less edge probe classified four requirements as `unclassified/unresolved`; they remain flagged below rather than being silently recast as probe-resolved.

| Source | ID | Required outcome or constraint | Plan | Status |
| --- | --- | --- | --- | --- |
| GOAL | Phase 174 | Enter an incident, identify affected schema/work and next safe action, retain chosen allowed schema | 01–08 | COVERED |
| REQ | OPUX-16 | Control Room state/scope/one safe next step | 01, 04, 06, 08 | COVERED |
| REQ | OPUX-17 | Worst-first readable Search health diagnostics | 01, 04, 06, 08 | COVERED |
| REQ | OPUX-18 | Failed-work identity/cause/eligibility/retained history | 01, 03, 05, 06, 08 | COVERED |
| REQ | OPUX-19 | Canonical selected schema across rendered recovery and safe return | 01–03, 05–08 | COVERED |
| RESEARCH | Stack | Existing locked Phoenix LiveView 1.1.33, OpsUi, ExUnit and Playwright; no new dependency | 01–08 | COVERED |
| RESEARCH | URL authority | Current allowlist resolution, absent versus invalid, encoded mounted paths | 01–03, 06–08 | COVERED |
| RESEARCH | Work identity | Ops-local schema/source/full-ID key across row/action/receipt/confirmation | 05, 06, 08 | COVERED |
| RESEARCH | Fleet context | Fleet ranking and chosen target separate; row handoffs explicitly select | 01, 02, 04 | COVERED |
| RESEARCH | Palette | Ignored DOM subtree requires actual patch-updated href bridge | 07, 08 | COVERED |
| RESEARCH | Authorization | Preserve only validated schema in local sudo return; host auth unchanged | 03, 06, 08 | COVERED |
| RESEARCH | Observation | Retained/partial/unknown distinct; acceptance distinct from terminal observation | 01, 03–06, 08 | COVERED |
| RESEARCH | Browser infrastructure | Scoped dual-entrypoint disposable runner, no retained preview mutation | 08 | COVERED |
| RESEARCH | ASVS | Revalidate query/event identities and keep existing action gate | 01–03, 05–08 | COVERED |
| RESEARCH | Validation | Focused LiveView, Ops precommit, mix verify.ops_ui, contrast and final-source browser proof | 01–08 | COVERED |
| CONTEXT | D-01 | Bounded specialist synthesis governs approved contract | 01 | COVERED |
| CONTEXT | D-02 | Small owned code/no new dependency | 01, 02 | COVERED |
| CONTEXT | D-03 | Delivered Phase173 visual system and approved UI contract | 01, 02, 04 | COVERED |
| CONTEXT | D-04 | Control Room current state/scope/one read-only step | 01, 04 | COVERED |
| CONTEXT | D-05 | Bounded allowlist/source health claims | 01, 04 | COVERED |
| CONTEXT | D-06 | Fleet evidence versus selected target | 01, 02, 04 | COVERED |
| CONTEXT | D-07 | Worst-first neutral rich records | 04 | COVERED |
| CONTEXT | D-08 | Local source state/time and zero/unknown distinctions | 04 | COVERED |
| CONTEXT | D-09 | Schema-specific checks with explicit target | 01, 02, 04 | COVERED |
| CONTEXT | D-10 | Stable focus and responsive complete identities | 02, 04, 08 | COVERED |
| CONTEXT | D-11 | Source-named failure facts before diagnostics | 05 | COVERED |
| CONTEXT | D-12 | Standard supported retry and honest unavailable reason | 05 | COVERED |
| CONTEXT | D-13 | Existing RecoveryAction/current server rules determine replay | 05 | COVERED |
| CONTEXT | D-14 | Host auth, allowlist, server checks, exact delete confirmation | 01, 03, 05 | COVERED |
| CONTEXT | D-15 | Accepted replacement, original history, unknown observation | 01, 03, 05 | COVERED |
| CONTEXT | D-16 | Source-qualified UI identities; public IDs unchanged | 05, 06, 08 | COVERED |
| CONTEXT | D-17 | Canonical validated query authority, no sticky state/atom creation | 01–03 | COVERED |
| CONTEXT | D-18 | Explicit allowed wins; invalid/empty never fallback | 01–03 | COVERED |
| CONTEXT | D-19 | Fleet-wide context and all recovery navigation | 01, 02, 07 | COVERED |
| CONTEXT | D-20 | URL/history, generation invalidation and stale results | 01–03, 06–08 | COVERED |
| CONTEXT | D-21 | Actual palette links after selector patch | 07, 08 | COVERED |
| CONTEXT | D-22 | Validated schema through safe sudo interruption/return | 03, 06, 08 | COVERED |
| CONTEXT | D-23 | Slice-owned tests, visual/contrast/browser proof | 01–08 | COVERED |
| CONTEXT | D-24 | A/B, invalid, equal-ID, stale, reordered and auth-return matrix | 01–08 | COVERED |

## Approved UI consideration coverage

| UI surface | Categories | Must-have location | Browser/state evidence plan | Status |
| --- | --- | --- | --- | --- |
| E1 Control Room | empty, loading, error, populated, partial, overflow, zero-one-many, long-text (8) | 174-04 truths | 174-04, 174-06, 174-08 | COVERED |
| E2 Search health | empty, loading, error, populated, partial, overflow, zero-one-many, long-text (8) | 174-04 truths | 174-04, 174-06, 174-08 | COVERED |
| E3 Failed sync work | empty, loading, error, populated, partial, overflow, zero-one-many, long-text (8) | 174-05 truths | 174-05, 174-06, 174-08 | COVERED |
| E4 Schema/navigation | empty, loading, error, partial, overflow, long-text (6) | 174-02 and 174-07 truths | 174-02, 174-03, 174-07, 174-08 | COVERED |

## Explicitly flagged assumptions from spec-less edge fallback

| ID | Probe result | Planning treatment |
| --- | --- | --- |
| OPUX-16 | unclassified, unresolved | Flagged assumption: the heuristic did not classify Control Room edge shape. Concrete E1 and requirement acceptance govern implementation; verifier must not claim probe resolution. |
| OPUX-17 | unclassified, unresolved | Flagged assumption: the heuristic did not classify Search health edge shape. Concrete E2 and requirement acceptance govern implementation; verifier must not claim probe resolution. |
| OPUX-18 | unclassified, unresolved | Flagged assumption: the heuristic did not classify Failed-work edge shape. Concrete E3 and requirement acceptance govern implementation; verifier must not claim probe resolution. |
| OPUX-19 | unclassified, unresolved | Flagged assumption: the heuristic did not classify selected-schema edge shape. Concrete E4 and requirement acceptance govern implementation; verifier must not claim probe resolution. |

No item from the four mandatory source types is missing. Deferred Phase175 repair/promotion presentation, Phase176 Search/Playbooks propagation and Phase177 consolidation are excluded by their approved phase boundaries. The fallback prohibition recall retained four project-specific constraints in the relevant plans' descriptor-less `must_haves.prohibitions`; they remain flagged-unverified at verify time until independently established. Canonical injection/path/auth defects remain owned by the security threat registers and existing server gates, rather than duplicate minted prohibitions.
