# Phase 185: Executable UI quality foundations - Discussion Log

> **Audit trail only.** Do not use as input to planning, research or execution agents. Decisions are captured in CONTEXT.md; this log preserves alternatives and research limits.

**Date:** 2026-10-30
**Phase:** 185-executable-ui-quality-foundations
**Areas considered:** required enforcement, L1 authority and baseline trust, appearance/routes, contrast/focus, DTCG/drift, judge retirement, preview/evidence boundaries.

## Maintainer direction and selection authority

The invocation was `$gsd-discuss-phase 185`. The maintainer then explicitly asked for subagent fan-out over all relevant decisions, reputable primary-source research, ecosystem precedents, pros/cons/tradeoffs and an adversarial pass, with one coherent recommendation set automatically followed. They reiterated a preference for small, flat dependency trees and copying a small helper instead of adding a dependency when practical.

Accordingly, no questionnaire was presented and no individual selection is attributed to the maintainer. The choices below were made under delegated engineering discretion. The delegation does not authorize visible redesign, an expanded phase, paid review, security-risk acceptance, preview mutation, merge/publication or automatic advancement into another lifecycle stage.

Three specialist research agents covered the token ratchet, contrast/DTCG and appearance/route/judge integration. Bounded follow-ups challenged history/bootstrap bypasses, token-format completeness and cross-area consistency. Additional surveys were stopped once they would no longer change the decisions.

## Required enforcement and contributor DX

| Option | Pros / consequences | Disposition |
| --- | --- | --- |
| Extend the canonical root repository-contract path | One contributor command; existing required lane; no optional Phoenix dependency | Selected |
| Run only in optional/path-scoped Ops verification | Local ownership, but a required failure can be skipped | Rejected as sole enforcement |
| Add a separate required quality job/framework | Clear separation, but adds setup, runtime and maintenance | Rejected; existing lanes suffice |

**Selected under delegated discretion:** root executable contracts invoke the existing dependency-free checker and verify actual failure propagation. Preserve the five required jobs and repository-only task/package boundaries.

## L1 scope and authority

| Option | Pros / consequences | Disposition |
| --- | --- | --- |
| Ops plus its first-party ecommerce host, explicit declaration authorities | Covers standalone/mounted source without importing marketing design debt | Selected |
| Ops-only scan | Smaller inventory, but omits host-authored UI/CSS that affects the mounted experience | Rejected |
| Repository-wide raw-text scan | Broad but confuses prose, IDs, vendors and independent brand palettes with UI values | Rejected |

**Selected under delegated discretion:** four scoped rules with bounded language/context handling. No whole-file stylesheet exemption, style-variable loophole, broader RGB ban or mandatory zero-debt cleanup. Existing token-backed arbitrary classes/inline styles may remain precise legacy findings. Named stacking roles are allowed; arbitrary selector/state variants are not mistaken for arbitrary-value utilities. Final review rejected a proposed `z-auto` exception because UIF-01 already bans un-tokenized literal stacking utilities; no requirement was relaxed.

## Shrink-only baseline and history

| Option | Pros / consequences | Disposition |
| --- | --- | --- |
| Violation count | Cheap, but a replacement or duplicate can hide behind the same count | Rejected |
| Candidate-side finding identities only | Good diagnostics, but editing the candidate baseline can bless new findings | Rejected |
| Exact finding multiset plus trusted committed history | Prevents swaps, duplicates, reintroduction and baseline laundering | Selected |

**Selected under delegated discretion:** semantic/path/value identity with multiplicity, not line numbers; actual findings equal the ledger and the ledger only shrinks. Bootstrap from the immutable pre-phase source tree, not the older approximate research counts. Cover first-parent reductions during bootstrap, missing-ledger/history failures, event-specific ref selection and local reproduction. Default-branch or PR-base comparison alone must not resurrect already-committed cleanups.

**Adversarial finding:** there is no pre-existing L1 ledger at the phase-start source. A final-tree-only comparison with that source would allow a violation to be removed and reintroduced during the first multi-commit PR. Planning must make that case executable.

**Final review clarification:** the trusted target branch's first-parent ledger at the recorded ref is the comparison authority. Candidate history cannot supply its own enlarged authority. Candidate first-parent reductions also remain monotonic, and newer target reductions must be reconciled before merge.

## Namespace reset and generator route

| Option | Pros / consequences | Disposition |
| --- | --- | --- |
| Color-only namespace reset with black/white restored | Removes default palette access while preserving spacing/type and daisyUI assumptions | Selected |
| Reset all Tailwind defaults | Stronger restriction, but large unapproved layout/type churn | Rejected |
| Delete generator root route entirely | Least code, but visiting standalone `/` becomes a 404 | Rejected in favor of existing entry convenience |
| Redirect standalone `/` to existing `/ops` | Removes scaffolding and preserves an obvious entry into the real app | Selected |

**Selected under delegated discretion:** remove the generator template and unused PageHTML view; repurpose the existing small controller action for a local redirect. Preserve mounted host and storefront routing. Check both actual asset bundles and matched rendered light/dark output.

**Source correction:** the generator page is actively routed and has a Phoenix-tagline test. It is not dead code until its route/view/controller disposition is reconciled.

## Contrast and focus

| Option | Pros / consequences | Disposition |
| --- | --- | --- |
| Promote existing checker unchanged | Fast, but keeps misclassified text and missing-input skips | Rejected |
| Extend and require the current checker | Reuses maintained math; fixes thresholds/coverage without another dependency | Selected |
| Make browser/AAA checks a new required gate | Broader evidence but greater cost; not approved phase topology | Deferred/out of scope |

**Selected under delegated discretion:** normal text 4.5:1, meaningful non-text/focus 3:1, exact raw comparisons, actual adjacent surfaces and fail-closed inputs. Include real failing process execution through the canonical command, not only an in-memory formula self-test. Keep AAA advisory and rendered/keyboard proof distinct from static token ratios.

**Observed evidence:** the specialist ran the existing checker and self-test using `/private/tmp/scrypath-phase185-contrast` for reports. The checker exited successfully with zero AA failures and 101 AAA advisories. Additional read-only calculations found the examined ordinary text/custom status/focus pairs already clear their correct floors. This supports retaining the palette; it does not prove the unimplemented focus gate, every actual background or Phase 185 acceptance.

## DTCG and token drift

| Option | Pros / consequences | Disposition |
| --- | --- | --- |
| Add typed Ops colors inside otherwise legacy JSON | Small diff, but leaves the document nonconformant and misleading | Rejected |
| Convert the document, preserve brand values, mirror live CSS | Honest interchange plus exact drift proof without changing runtime | Selected |
| Generate CSS from JSON or add a resolver/token platform | Could centralize generation, but changes build authority and adds machinery | Rejected for this phase |

**Selected under delegated discretion:** published DTCG 2025.10, typed existing leaves/metadata, project-conventional `ops.light`/`ops.dark`, all custom properties from the live theme blocks, bounded local validation and mutations of each side. Preserve the unrelated brand palette and correct claims that it mirrors Ops. Include theme dimensions/numbers as well as colors. Encode muted base-content as sRGB color with separate alpha and verify the source expression/reference; do not put a CSS expression in a color `$value`.

**Research disagreement resolved:** one adversarial note suggested replacing the old `$schema` link with a versioned schema. The format specialist and direct primary-source check establish that a report URL is not a published JSON Schema. Remove the misleading schema pointer and link the stable reports as provenance instead. Do not follow the redirect to the preview draft.

**Planner detail:** the existing `shadow.glow.light: "none"` needs an explicit representation that preserves absence of a shadow under the chosen supported DTCG vocabulary. Do not silently delete it, change its visual meaning or claim a generic schema validator. Other existing dimensions, font families/weights, durations, easing and layered shadows have corresponding typed structures. No brandbook rendering value is changed by this discussion.

## Paid/synthetic judge retirement

| Option | Pros / consequences | Disposition |
| --- | --- | --- |
| Delete executable paths and reconcile callers/docs/evidence | Removes paid/mock capability and obsolete switches together | Selected |
| Retain a failing command tombstone | Better legacy error, but retains another obsolete executable surface | Rejected as unnecessary |
| Replace the judge now with an agent skill | Could support later taste review, but belongs to later approved work | Deferred |

**Selected under delegated discretion:** remove npm/script/Makefile paid and synthetic report paths, relevant environment/model/report wiring and current judge-only receipt output. Preserve actual deterministic checks, pending review records and immutable old receipts. Reconcile producer/consumer tests, not just a source-string search.

**Source corrections:** the current mock emits `mock` and `needs_review`, not a literal `pass`; earlier research overstated that behavior. The executable paid request still exists locally. No judge invocation or injected OpenAI key was found in CI/Compose, so do not claim removing nonexistent wiring.

## Preview, review and delivery evidence

| Option | Pros / consequences | Disposition |
| --- | --- | --- |
| Trust retained preview or screenshot manifests as current appearance proof | Convenient, but stale source and inventory-only checks cannot establish parity | Rejected |
| Reconcile named source, use disposable verification and inspect matched captures | Preserves data and keeps evidence tied to actual source/state | Selected for implementation |
| Treat agent agreement or mechanical captures as design approval | Avoids a stop, but fabricates a trust judgment | Rejected |

**Selected under delegated discretion:** existing preflight stop remains until actually resolved. Preserve retained data/checkouts. Follow the complete maintained screen/journey review protocol, batch scoped repairs and confirm once, while distinguishing static, browser, visual and hosted evidence. No preview action occurred during discussion. Phase 184's already-successful external terminal receipt was read and matched the unchanged discussion-base HEAD; no old receipt is extended to the new discussion commits.

## Agent's Discretion

Small helper/file names, bounded parsing mechanics, precise semantic anchors, test fixtures and trusted-ref transport remain engineering choices. The baseline/bootstrap trust behavior, full-document token validity, thresholds, required command, supported appearance and safety stops are constraints. The maintainer's dependency preference is carried into CONTEXT.md rather than adding another instruction authority.

## Deferred Ideas and Next Boundary

v1.46 retains Storybook, fixtures/twins, extraction, L2/copy checks and decisions log. v1.47 retains new visual baselines, calibrated agent review and visible polish. v1.48 retains adopter APIs. Unrelated security debt, merge/publication and speculative redesign remain outside scope. No pending todos matched.

Next: `$gsd-ui-phase 185` to capture preservation constraints, then `$gsd-plan-phase 185`. No implementation, milestone completion, visual approval or new hosted acceptance is claimed.
